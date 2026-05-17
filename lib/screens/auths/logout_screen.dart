import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

const Color _kMochiPink = Color(0xFFE94D86);
const Color _kMochiPinkLight = Color(0xFFFFEEF5);
const Color _kMochiPinkSoft = Color(0xFFFFF7FA);
const Color _kMochiBorder = Color(0xFFF7DCE7);
const Color _kMochiText = Color(0xFF3F2D33);
const Color _kMochiMuted = Color(0xFF9C7A86);
const String _kMochiLogoAsset = 'assets/images/mochi/bunny_bear_original.png';
const String _kScreenIllustrationAsset = 'assets/images/mochi/restore_bunny_bear.png';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _kMochiPinkSoft,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(top: -70, right: -50, child: _SoftCircle(size: 190)),
            const Positioned(bottom: -80, left: -45, child: _SoftCircle(size: 210)),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _MochiLogo(),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.9)),
                        boxShadow: [
                          BoxShadow(color: _kMochiPink.withOpacity(0.09), blurRadius: 26, offset: const Offset(0, 16)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: _kMochiPinkLight,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(
                                _kScreenIllustrationAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.logout_rounded,
                                  color: _kMochiPink,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Xác nhận đăng xuất',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _kMochiPink,
                              fontSize: 27,
                              fontFamily: 'Quicksand',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Bạn có chắc chắn muốn đăng xuất khỏi Mochi không?',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _kMochiText, fontSize: 14, height: 1.45, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 24),
                          _MochiPrimaryButton(
                            text: 'Đăng xuất',
                            isLoading: authProvider.isLoading,
                            onPressed: () async {
                              await authProvider.logout();
                              if (authProvider.user == null) {
                                Navigator.pushReplacementNamed(context, '/login');
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(authProvider.errorMessage ?? 'Đăng xuất thất bại')),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _kMochiText,
                                side: const BorderSide(color: _kMochiBorder),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              child: const Text('Ở lại'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MochiLogo extends StatelessWidget {
  const _MochiLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kMochiBorder, width: 2),
            boxShadow: [BoxShadow(color: _kMochiPink.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 8))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              _kMochiLogoAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.favorite_rounded, color: _kMochiPink, size: 26),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mochi',
              style: TextStyle(color: _kMochiPink, fontSize: 31, fontFamily: 'Quicksand', fontWeight: FontWeight.w900, height: 1),
            ),
            SizedBox(height: 3),
            Text('Cute things for you ♡', style: TextStyle(color: _kMochiText, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _MochiPrimaryButton extends StatelessWidget {
  const _MochiPrimaryButton({required this.text, required this.onPressed, this.isLoading = false});

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _kMochiPink,
          disabledBackgroundColor: _kMochiPink.withOpacity(0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontFamily: 'Quicksand', fontWeight: FontWeight.w900),
        ),
        child: isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
            : Text(text),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: _kMochiPink.withOpacity(0.08)));
  }
}
