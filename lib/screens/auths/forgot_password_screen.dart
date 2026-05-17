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
const String _kScreenIllustrationAsset = 'assets/images/mochi/forgot_password_search.png';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _kMochiPinkSoft,
      body: _MochiAuthScaffold(
        title: 'Quên mật khẩu',
        subtitle: 'Nhập email để Mochi gửi mã OTP cho bạn 💌',
        illustrationAsset: _kScreenIllustrationAsset,
        footer: const _InfoBox(
          icon: Icons.mark_email_read_outlined,
          title: 'Kiểm tra hộp thư của bạn',
          subtitle: 'Mã OTP sẽ được gửi đến email đã đăng ký.',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MochiInput(
              controller: _emailController,
              label: 'Email',
              hintText: 'Nhập email của bạn',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 22),
            _MochiPrimaryButton(
              text: 'Gửi mã OTP',
              isLoading: authProvider.isLoading,
              onPressed: () {
                final email = _emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập email')),
                  );
                  return;
                }
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email không hợp lệ')),
                  );
                  return;
                }
                authProvider.forgotPassword(email);
              },
            ),
            const SizedBox(height: 18),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/login'),
                child: const Text(
                  'Đã nhớ mật khẩu? Đăng nhập ngay',
                  style: TextStyle(color: _kMochiPink, fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

class _MochiAuthScaffold extends StatelessWidget {
  const _MochiAuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.illustrationAsset,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String illustrationAsset;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          const Positioned(top: -70, right: -50, child: _SoftCircle(size: 190)),
          const Positioned(bottom: -80, left: -45, child: _SoftCircle(size: 210)),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Quay về trang chủ'),
                    style: TextButton.styleFrom(
                      foregroundColor: _kMochiText,
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const _MochiLogo(),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.9)),
                    boxShadow: [
                      BoxShadow(color: _kMochiPink.withOpacity(0.09), blurRadius: 26, offset: const Offset(0, 16)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: _kMochiPink,
                                    fontSize: 27,
                                    fontFamily: 'Quicksand',
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subtitle,
                                  style: const TextStyle(color: _kMochiText, fontSize: 14, height: 1.35, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          _CuteIllustration(assetPath: illustrationAsset),
                        ],
                      ),
                      const SizedBox(height: 26),
                      child,
                    ],
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 22),
                  footer!,
                ],
              ],
            ),
          ),
        ],
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

class _MochiInput extends StatelessWidget {
  const _MochiInput({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.suffixIcon,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLength: maxLength,
      style: const TextStyle(color: _kMochiText, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        counterText: maxLength == null ? null : '',
        prefixIcon: Icon(icon, color: _kMochiMuted),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: _kMochiText, fontSize: 13, fontWeight: FontWeight.w700),
        hintStyle: TextStyle(color: _kMochiMuted.withOpacity(0.72), fontSize: 13, fontWeight: FontWeight.w600),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kMochiBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kMochiPink, width: 1.4)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kMochiPink)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kMochiPink, width: 1.4)),
      ),
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

class _CuteIllustration extends StatelessWidget {
  const _CuteIllustration({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: _kMochiPinkLight,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image_not_supported_outlined,
                  color: _kMochiPink,
                  size: 34,
                ),
              ),
            ),
          ),
          const Positioned(right: 8, top: 8, child: Text('✨', style: TextStyle(fontSize: 12))),
          const Positioned(left: 9, bottom: 9, child: Text('💗', style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kMochiPinkLight.withOpacity(0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kMochiBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: _kMochiPink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _kMochiText, fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: _kMochiMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
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
