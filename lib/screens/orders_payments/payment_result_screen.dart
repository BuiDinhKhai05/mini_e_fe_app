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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ICON
              Icon(
                success ? Icons.check_circle : Icons.error,
                size: 100,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 24),

              // TITLE
              Text(
                success ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // MESSAGE & INFO
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (success)
                Text(
                  'Mã đơn: $orderId',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

              const Spacer(),

              // BUTTONS
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate về trang chi tiết đơn hàng (replace để không back lại trang result)
                    Navigator.pushNamedAndRemoveUntil(context, '/orders', (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: success ? Colors.blue : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Xem đơn hàng của tôi'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst); // Về Home
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tiếp tục mua sắm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}