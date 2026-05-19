// lib/screens/edit_personal_info_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/user_provider.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  // =========================
  // 1. MÀU CHỦ ĐẠO CỦA GIAO DIỆN
  // =========================
  static const Color _primaryPink = Color(0xFFE84D7A);
  static const Color _softPink = Color(0xFFFFF4F7);
  static const Color _lightPink = Color(0xFFFCE3EC);
  static const Color _unselectedPink = Color(0xFFC8A6B0);
  static const Color _textDark = Color(0xFF333333);
  static const Color _textMuted = Color(0xFF8A7A80);

  // =========================
  // 2. BIẾN QUẢN LÝ FORM
  // =========================
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  String? _selectedGender;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  // =========================
  // 3. BIẾN QUẢN LÝ ẢNH ĐẠI DIỆN
  // =========================
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // Lấy thông tin user hiện tại để đổ dữ liệu vào form.
    final user = Provider.of<UserProvider>(context, listen: false).me;

    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedGender = user?.gender;

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
    super.dispose();
  }

  // =========================
  // 4. CHỌN ẢNH ĐẠI DIỆN TỪ THƯ VIỆN
  // =========================
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
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
            primary: _primaryPink,
            onPrimary: Colors.white,
            onSurface: _textDark,
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

      if (_selectedImageFile != null) {
        updates['avatar'] = _selectedImageFile;
      }

      if (updates.isNotEmpty) {
        await userProvider.updateProfile(updates);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thành công!'),
            backgroundColor: _primaryPink,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
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

    return SizedBox(
      width: 160,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: _lightPink,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: _primaryPink,
                  backgroundImage: _selectedImageFile != null
                      ? FileImage(_selectedImageFile!)
                      : null,
                  child: _selectedImageFile == null
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

              // Nút camera nhỏ để chọn ảnh.
              Positioned(
                right: 2,
                bottom: 4,
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: _primaryPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: _pickImage,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryPink,
                side: BorderSide(color: _primaryPink.withOpacity(0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text(
                'Đổi ảnh đại diện',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'JPG, PNG tối đa 2MB',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
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
          color: _textDark,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _textMuted, size: 20),
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            color: _textMuted,
            fontWeight: FontWeight.w700,
          ),
          hintStyle: const TextStyle(color: _unselectedPink),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryPink.withOpacity(0.16)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _primaryPink.withOpacity(0.16)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryPink, width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
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
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.calendar_month_outlined,
              color: _textMuted,
              size: 20,
            ),
            labelText: 'Ngày sinh',
            labelStyle: const TextStyle(
              color: _textMuted,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _primaryPink.withOpacity(0.16)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _primaryPink.withOpacity(0.16)),
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
                  color: _selectedBirthDate == null ? _unselectedPink : _textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _unselectedPink,
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
            color: isSelected ? _primaryPink : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _primaryPink : _primaryPink.withOpacity(0.18),
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: _primaryPink.withOpacity(0.18),
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
              color: isSelected ? Colors.white : _textDark,
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
            color: _textDark,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),

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
            return RegExp(r'^[0-9]{9,11}$').hasMatch(v)
                ? null
                : 'SĐT không hợp lệ';
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
              color: _textMuted,
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
  // 12. HÌNH TRANG TRÍ BÊN PHẢI
  // =========================
  Widget _buildDecorationImage() {
    return SizedBox(
      width: 190,
      child: Center(
        child: Image.asset(
          'assets/brand/bunny_bear_original.png',
          height: 160,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 160,
              height: 140,
              decoration: BoxDecoration(
                color: _softPink,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Center(
                child: Text(
                  '🐰💗',
                  style: TextStyle(fontSize: 54),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================
  // 13. CARD FORM THEO FORMAT ẢNH MẪU
  // =========================
  Widget _buildEditCard(dynamic currentUser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _primaryPink.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.06),
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
                _buildDecorationImage(),
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
              _buildDecorationImage(),
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
          backgroundColor: _primaryPink,
          disabledBackgroundColor: _unselectedPink.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
          shadowColor: _primaryPink.withOpacity(0.25),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa thông tin',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: _textDark,
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
