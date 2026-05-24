import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';

class PaymentQrScreen extends StatefulWidget {
  static const routeName = '/payment-gateway';

  // Giữ nguyên field cũ để không cần sửa route generator.
  // qrData hiện được hiểu là paymentUrl VNPAY do backend trả về.
  final String qrData;
  final double amount;
  final String sessionCode;
  final String orderIdToCheck;

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
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _pageBg = AppColors.background;
  static const Color _textDark = AppColors.textDark;
  static const Color _textMuted = AppColors.textGrey;

  late Timer _timer;
  late Timer _pollingTimer;

  int _timeLeft = 900;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer.cancel();
        _pollingTimer.cancel();
        _navigateToResult(false, message: 'Hết thời gian thanh toán');
      }
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final isPaid = await Provider.of<OrderProvider>(context, listen: false)
          .checkPaidBySessionCode(widget.sessionCode);

      if (isPaid && mounted) {
        await Provider.of<OrderProvider>(context, listen: false).fetchMyOrders(refresh: true);
        _navigateToResult(true);
      }
    } catch (_) {
      // Polling lỗi tạm thời thì bỏ qua để tiếp tục kiểm tra ở lượt sau.
    } finally {
      _isChecking = false;
    }
  }

  void _navigateToResult(bool success, {String? message}) {
    if (_timer.isActive) _timer.cancel();
    if (_pollingTimer.isActive) _pollingTimer.cancel();

    Navigator.pushReplacementNamed(context, '/payment-result', arguments: {
      'success': success,
      'message': message ?? (success ? 'Thanh toán thành công!' : 'Thanh toán thất bại'),
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
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
    final paymentUrl = widget.qrData;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'Thanh toán VNPAY',
              style: TextStyle(color: _textDark, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 2),
            Text(
              'Quét QR để hoàn tất đơn hàng',
              style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: _textDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            children: [
              _buildQrCard(currencyFormat, paymentUrl),
              const SizedBox(height: 18),
              _buildTimerChip(),
              const SizedBox(height: 18),
              _buildWaitingBox(),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _navigateToResult(
                    true,
                    message: '(DEV) Giả lập thanh toán thành công',
                  ),
                  child: const Text(
                    '(DEV ONLY) Giả lập: Đã thanh toán',
                    style: TextStyle(color: _textMuted, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCard(NumberFormat currencyFormat, String paymentUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: _primaryPink.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _softPink,
              borderRadius: BorderRadius.circular(AppRadius.circle),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, color: _primaryPink, size: 16),
                SizedBox(width: 6),
                Text(
                  'Giao dịch bảo mật',
                  style: TextStyle(color: _primaryPink, fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'VNPAY',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.extraLarge),
              border: Border.all(color: _primaryPink.withOpacity(0.18)),
            ),
            child: QrImageView(
              data: paymentUrl,
              size: 220,
              gapless: false,
              errorStateBuilder: (context, error) {
                return const SizedBox(
                  width: 220,
                  height: 220,
                  child: Center(child: Text('Không tạo được QR')),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          Text(
            currencyFormat.format(widget.amount),
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: _primaryPink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mã giao dịch: ${widget.sessionCode}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sử dụng ứng dụng ngân hàng hoặc VNPAY để quét mã. Sau khi thanh toán, app sẽ tự cập nhật trạng thái.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              collapsedIconColor: _textMuted,
              iconColor: _primaryPink,
              title: const Text(
                'Xem link thanh toán',
                style: TextStyle(fontSize: 13, color: _textMuted, fontWeight: FontWeight.w700),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _softPink,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: SelectableText(
                    paymentUrl,
                    style: const TextStyle(fontSize: 12, color: _textDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.circle),
        border: Border.all(color: AppColors.warning.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Text(
            'Hết hạn sau: $_timerString',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.warning,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: _primaryPink.withOpacity(0.10)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primaryPink),
          ),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              'Đang chờ xác nhận thanh toán...',
              style: TextStyle(color: _textMuted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
