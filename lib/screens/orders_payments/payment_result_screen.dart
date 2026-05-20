// lib/screens/payment/payment_result_screen.dart

import 'package:flutter/material.dart';

class PaymentResultScreen extends StatelessWidget {
  static const routeName = '/payment-result';

  final bool success;
  final String message;
  final String orderId;

  const PaymentResultScreen({
    Key? key,
    required this.success,
    required this.message,
    required this.orderId,
  }) : super(key: key);

  static const Color _primaryPink = Color(0xFFFF4F8B);
  static const Color _pageBg = Color(0xFFFFF7FA);
  static const Color _softPink = Color(0xFFFFEEF5);
  static const Color _textDark = Color(0xFF4A2F38);
  static const Color _textMuted = Color(0xFF9A7B86);

  @override
  Widget build(BuildContext context) {
    final codeLabel = orderId.startsWith('PM') ? 'Mã giao dịch' : 'Mã đơn';

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
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
                      width: 106,
                      height: 106,
                      decoration: BoxDecoration(
                        color: success ? _softPink : const Color(0xFFFFF1F1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        success ? Icons.check_circle_rounded : Icons.error_rounded,
                        size: 76,
                        color: success ? _primaryPink : const Color(0xFFFF5B5B),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      success ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _textMuted, fontSize: 15, height: 1.4),
                    ),
                    if (success && orderId.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _softPink,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$codeLabel: ',
                              style: const TextStyle(
                                color: _textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                orderId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _primaryPink,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/orders',
                          (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text(
                    'Xem đơn hàng của tôi',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryPink,
                    side: BorderSide(color: _primaryPink.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text(
                    'Tiếp tục mua sắm',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
