// lib/screens/users/edit_personal_info_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  // =========================
  // 1. BIẾN QUẢN LÝ FORM
  // =========================
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _avatarUrlController;

  String? _selectedGender;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Lấy thông tin user hiện tại để đổ dữ liệu vào form.
    final user = Provider.of<UserProvider>(context, listen: false).me;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _avatarUrlController = TextEditingController(text: user?.avatarUrl ?? '');
    _selectedGender = user?.gender;

    // Cập nhật preview avatar mỗi khi người dùng nhập URL ảnh mới.
    _avatarUrlController.addListener(() {
      if (mounted) setState(() {});
    });

    // Parse ngày sinh từ backend. Hỗ trợ cả yyyy-MM-dd và dd/MM/yyyy.
    final birthday = user?.birthday;
    if (birthday != null && birthday.isNotEmpty) {
      try {
        _selectedBirthDate = DateTime.parse(birthday);
      } catch (_) {
        try {
          _selectedBirthDate = DateFormat('dd/MM/yyyy').parse(birthday);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  // =========================
  // 4. HELPER XỬ LÝ AVATAR URL
  // =========================
  bool _isValidAvatarUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return false;

    final uri = Uri.tryParse(text);
    return uri != null &&
        uri.isAbsolute &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String? _validateAvatarUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    return _isValidAvatarUrl(text)
        ? null
        : 'Avatar URL phải bắt đầu bằng http:// hoặc https://';
  }

  String? _currentAvatarPreviewUrl(dynamic currentUser) {
    final typedUrl = _avatarUrlController.text.trim();
    if (_isValidAvatarUrl(typedUrl)) return typedUrl;

    try {
      final oldUrl = currentUser?.avatarUrl;
      if (oldUrl is String && _isValidAvatarUrl(oldUrl)) {
        return oldUrl.trim();
      }
    } catch (_) {}

    return null;
  }

  // =========================
  // 5. CHỌN NGÀY SINH
  // =========================
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primaryPink,
            onPrimary: Colors.white,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  // =========================
  // 6. LƯU THÔNG TIN ĐÃ CHỈNH SỬA
  // =========================
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final originalUser = userProvider.me;

      final Map<String, dynamic> updates = {};

      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();
      final newAvatarUrl = _avatarUrlController.text.trim();

      // Chỉ gửi field nào thật sự thay đổi để tránh update thừa.
      if (newName.isNotEmpty && newName != originalUser?.name) {
        updates['name'] = newName;
      }

      if (newPhone != originalUser?.phone) {
        updates['phone'] = newPhone.isEmpty ? null : newPhone;
      }

      if (_selectedGender != originalUser?.gender) {
        updates['gender'] = _selectedGender;
      }

      if (_selectedBirthDate != null) {
        final formatted = DateFormat('yyyy-MM-dd').format(_selectedBirthDate!);
        if (formatted != originalUser?.birthday) {
          updates['birthday'] = formatted;
        }
      }

      // BE hiện tại chỉ nhận avatarUrl, không nhận File ảnh trực tiếp.
      if (newAvatarUrl != (originalUser?.avatarUrl ?? '')) {
        updates['avatarUrl'] = newAvatarUrl.isEmpty ? null : newAvatarUrl;
      }

      if (updates.isNotEmpty) {
        await userProvider.updateProfile(updates);
        await userProvider.fetchMe(force: true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thành công!'),
            backgroundColor: AppColors.primaryPink,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =========================
  // 7. AVATAR BÊN TRÁI THEO FORMAT ẢNH MẪU
  // =========================
  Widget _buildAvatarPicker(dynamic currentUser) {
    final String name = currentUser?.name ?? 'Người dùng';
    final String? avatarUrl = _currentAvatarPreviewUrl(currentUser);

    return SizedBox(
      width: 160,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.lightPink,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: AppColors.primaryPink,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              onBackgroundImageError: avatarUrl != null ? (_, __) {} : null,
              child: avatarUrl == null
                  ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              )
                  : null,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Ảnh đại diện',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'BE hiện nhận avatarUrl, không nhận File ảnh trực tiếp.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // 8. INPUT TEXT CÓ ICON VÀ LABEL
  // =========================
  Widget _buildTextFieldRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textGrey, size: 20),
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            color: AppColors.textGrey,
            fontWeight: FontWeight.w700,
          ),
          hintStyle: const TextStyle(color: AppColors.textLight),
          filled: true,
          fillColor: AppColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
            borderSide: BorderSide(color: AppColors.primaryPink.withOpacity(0.16)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
            borderSide: BorderSide(color: AppColors.primaryPink.withOpacity(0.16)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
            borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  // =========================
  // 9. FIELD CHỌN NGÀY SINH
  // =========================
  Widget _buildBirthdayField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.textGrey,
              size: 20,
            ),
            labelText: 'Ngày sinh',
            labelStyle: const TextStyle(
              color: AppColors.textGrey,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: AppColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.large),
              borderSide: BorderSide(color: AppColors.primaryPink.withOpacity(0.16)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.large),
              borderSide: BorderSide(color: AppColors.primaryPink.withOpacity(0.16)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedBirthDate == null
                    ? 'dd/mm/yyyy'
                    : DateFormat('dd/MM/yyyy').format(_selectedBirthDate!),
                style: TextStyle(
                  fontSize: 14,
                  color: _selectedBirthDate == null ? AppColors.textLight : AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // 10. NÚT CHỌN GIỚI TÍNH
  // =========================
  Widget _buildGenderOption(String value, String label) {
    final bool isSelected = _selectedGender == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPink : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: isSelected ? AppColors.primaryPink : AppColors.primaryPink.withOpacity(0.18),
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: AppColors.primaryPink.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // 11. CỤM FORM CHỈNH SỬA Ở GIỮA
  // =========================
  Widget _buildFormPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin cá nhân',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),

        // Avatar URL. BE hiện tại nhận URL ảnh qua field avatarUrl.
        _buildTextFieldRow(
          icon: Icons.image_outlined,
          label: 'Avatar URL',
          controller: _avatarUrlController,
          hint: 'https://domain.com/avatar.jpg',
          keyboardType: TextInputType.url,
          validator: _validateAvatarUrl,
        ),

        // Họ và tên.
        _buildTextFieldRow(
          icon: Icons.person_outline,
          label: 'Họ và tên',
          controller: _nameController,
          hint: 'Nhập họ tên của bạn',
          validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
        ),

        // Số điện thoại.
        _buildTextFieldRow(
          icon: Icons.phone_outlined,
          label: 'Số điện thoại',
          controller: _phoneController,
          hint: 'Nhập số điện thoại',
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(v)
                ? null
                : 'SĐT không hợp lệ. Có thể nhập 0..., +84...';
          },
        ),

        // Ngày sinh.
        _buildBirthdayField(),

        // Giới tính.
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Giới tính',
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Row(
          children: [
            _buildGenderOption('MALE', 'Nam'),
            const SizedBox(width: 10),
            _buildGenderOption('FEMALE', 'Nữ'),
            const SizedBox(width: 10),
            _buildGenderOption('OTHER', 'Khác'),
          ],
        ),
      ],
    );
  }



  // =========================
  // 13. CARD FORM THEO FORMAT ẢNH MẪU
  // =========================
  Widget _buildEditCard(dynamic currentUser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: AppColors.primaryPink.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.06),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Giao diện rộng: avatar trái - form giữa - hình trang trí phải.
          if (constraints.maxWidth >= 760) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatarPicker(currentUser),
                const SizedBox(width: 32),
                Expanded(child: _buildFormPanel()),
                const SizedBox(width: 22),

              ],
            );
          }

          // Giao diện điện thoại: xếp dọc để không bị tràn màn hình.
          return Column(
            children: [
              _buildAvatarPicker(currentUser),
              const SizedBox(height: 26),
              _buildFormPanel(),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // 14. NÚT LƯU THAY ĐỔI
  // =========================
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPink,
          disabledBackgroundColor: AppColors.textLight.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.circle),
          ),
          elevation: 0,
          shadowColor: AppColors.primaryPink.withOpacity(0.25),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          'Lưu thay đổi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // =========================
  // 15. BUILD GIAO DIỆN CHÍNH
  // =========================
  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).me;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa thông tin',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Card chỉnh sửa thông tin theo layout ảnh mẫu.
              _buildEditCard(currentUser),

              const SizedBox(height: 22),

              // Nút lưu thay đổi.
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }
}
