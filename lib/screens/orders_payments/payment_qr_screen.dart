import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/order_provider.dart';

class PaymentQrScreen extends StatefulWidget {
  static const routeName = '/payment-gateway';

  // Giữ nguyên field cũ để khỏi sửa route generator:
  // qrData bây giờ là paymentUrl
  final String qrData;        // paymentUrl (VNPAY)
  final double amount;
  final String sessionCode;
  final String orderIdToCheck; // không dùng nữa (giữ để tương thích)

  const PaymentQrScreen({
    Key? key,
    required this.qrData,
    required this.amount,
    required this.sessionCode,
    required this.orderIdToCheck,
  }) : super(key: key);

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  late Timer _timer;
  late Timer _pollingTimer;

  int _timeLeft = 900; // 15 phút
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer.cancel();
        _pollingTimer.cancel();
        _navigateToResult(false, message: 'Hết thời gian thanh toán');
      }
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final isPaid = await Provider.of<OrderProvider>(context, listen: false)
          .checkPaidBySessionCode(widget.sessionCode);

      if (isPaid) {
        await Provider.of<OrderProvider>(context, listen: false).fetchMyOrders(refresh: true);
        _navigateToResult(true);
      }
    } catch (_) {
      // ignore
    } finally {
      _isChecking = false;
    }
  }

  void _navigateToResult(bool success, {String? message}) {
    _pollingTimer.cancel();
    _timer.cancel();

    Navigator.pushReplacementNamed(context, '/payment-result', arguments: {
      'success': success,
      'message': message ?? (success ? 'Thanh toán thành công!' : 'Thanh toán thất bại'),
      // Không có orderCode ở đây (BE chưa tạo order khi create VNPAY),
      // nên hiển thị mã phiên thanh toán cho chắc
      'orderId': widget.sessionCode,
    });
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    if (_pollingTimer.isActive) _pollingTimer.cancel();
    super.dispose();
  }

  String get _timerString {
    final minutes = (_timeLeft / 60).floor().toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final paymentUrl = widget.qrData;

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Thanh toán VNPAY", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    const Text('VNPAY', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shield, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('Giao dịch bảo mật', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ✅ QR từ paymentUrl
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: QrImageView(
                        data: paymentUrl,
                        size: 220,
                        gapless: false,
                        errorStateBuilder: (cxt, err) {
                          return const SizedBox(
                            width: 220,
                            height: 220,
                            child: Center(child: Text("Không tạo được QR")),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      currencyFormat.format(widget.amount),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text('Mã GD: ${widget.sessionCode}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 12),
                    const Text(
                      'Sử dụng App Ngân hàng hoặc VNPAY để quét mã',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),

                    // hiển thị link (debug)
                    ExpansionTile(
                      title: const Text('Xem link thanh toán', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SelectableText(paymentUrl, style: const TextStyle(fontSize: 12)),
                        )
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Hết hạn sau: $_timerString',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text("Đang chờ xác nhận thanh toán...", style: TextStyle(color: Colors.grey)),
                ],
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () => _navigateToResult(true, message: '(DEV) Giả lập thanh toán thành công'),
                child: const Text("(DEV ONLY) Giả lập: Đã thanh toán", style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
