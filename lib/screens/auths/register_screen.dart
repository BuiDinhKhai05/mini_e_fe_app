import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

const Color _kMochiPink = Color(0xFFE94D86);
const Color _kMochiPinkLight = AppColors.lightPink;
const Color _kMochiPinkSoft = AppColors.background;
const Color _kMochiBorder = AppColors.borderPink;
const Color _kMochiText = AppColors.textDark;
const Color _kMochiMuted = AppColors.textGrey;
const String _kMochiLogoAsset = 'assets/images/mochi/bunny_bear_original.png';
const String _kScreenIllustrationAsset = 'assets/images/mochi/register_bunny_gift.png';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreePolicy = true;

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  final _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};:\\|,.<>/?]).{8,}$',
  );

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _kMochiPinkSoft,
      body: _MochiAuthScaffold(
        title: 'Đăng ký tài khoản',
        subtitle: 'Tham gia cùng Mochi ngay hôm nay 💗',
        illustrationAsset: _kScreenIllustrationAsset,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MochiInput(
                controller: _nameController,
                label: 'Họ và tên',
                hintText: 'Nhập họ và tên',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name không được để trống';
                  }
                  if (value.trim().length < 2) {
                    return 'Name phải có ít nhất 2 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _MochiInput(
                controller: _emailController,
                label: 'Email',
                hintText: 'Nhập email của bạn',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email không được để trống';
                  }
                  if (!_emailRegex.hasMatch(value.trim())) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _MochiInput(
                controller: _passwordController,
                label: 'Mật khẩu',
                hintText: 'Tạo mật khẩu',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _kMochiMuted,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password không được để trống';
                  }
                  if (value.length < 8) {
                    return 'Password phải có ít nhất 8 ký tự';
                  }
                  if (!_passwordRegex.hasMatch(value)) {
                    return 'Password phải có ít nhất 8 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _MochiInput(
                controller: _confirmPasswordController,
                label: 'Xác nhận mật khẩu',
                hintText: 'Nhập lại mật khẩu',
                icon: Icons.lock_reset_rounded,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _kMochiMuted,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm Password không được để trống';
                  }
                  if (value.length < 8) {
                    return 'Confirm Password phải có ít nhất 8 ký tự';
                  }
                  if (value != _passwordController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _agreePolicy = !_agreePolicy),
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: _agreePolicy ? _kMochiPink : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _kMochiPink.withOpacity(0.55)),
                      ),
                      child: _agreePolicy
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tôi đồng ý với Điều khoản sử dụng và Chính sách bảo mật',
                      style: TextStyle(color: _kMochiText, fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _MochiPrimaryButton(
                text: 'Đăng ký',
                isLoading: authProvider.isLoading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    authProvider
                        .register(
                      _nameController.text.trim(),
                      _emailController.text.trim(),
                      _passwordController.text,
                      _confirmPasswordController.text,
                    )
                        .then((_) {
                      if (!mounted) return;
                      if (authProvider.user != null) {
                        Navigator.pushNamed(context, '/verify-account');
                      } else if (authProvider.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(authProvider.errorMessage!),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 22),
              const _DividerText(text: 'Hoặc đăng ký với'),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(child: _SocialPill(iconText: 'G', label: 'Google')),
                  SizedBox(width: 10),
                  Expanded(child: _SocialPill(iconText: 'f', label: 'Facebook')),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(color: _kMochiText, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: const Text(
                        'Đăng nhập ngay',
                        style: TextStyle(color: _kMochiPink, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(color: _kMochiMuted, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

class _MochiAuthScaffold extends StatelessWidget {
  const _MochiAuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.illustrationAsset,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String illustrationAsset;

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
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: _kMochiText, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
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

class _DividerText extends StatelessWidget {
  const _DividerText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: _kMochiBorder.withOpacity(0.85))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: const TextStyle(color: _kMochiMuted, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Divider(color: _kMochiBorder.withOpacity(0.85))),
      ],
    );
  }
}

class _SocialPill extends StatelessWidget {
  const _SocialPill({required this.iconText, required this.label});

  final String iconText;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kMochiBorder)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(iconText, style: const TextStyle(color: _kMochiPink, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _kMochiText, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
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

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: _kMochiPink.withOpacity(0.08)));
  }
}
