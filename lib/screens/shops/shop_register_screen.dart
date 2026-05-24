// lib/screens/shops/shop_register_screen.dart
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';

// Providers
import '../../providers/shop_provider.dart';

// Widgets chọn địa chỉ và bản đồ
import '../../widgets/vietnam_address_selector.dart';
import '../../widgets/osm_location_picker.dart';

class ShopRegisterScreen extends StatefulWidget {
  const ShopRegisterScreen({super.key});

  @override
  State<ShopRegisterScreen> createState() => _ShopRegisterScreenState();
}

class _ShopRegisterScreenState extends State<ShopRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // =========================
  // Controllers
  // =========================
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Controller chứa chuỗi địa chỉ đầy đủ từ Selector hoặc người dùng nhập thêm
  final _addressCtrl = TextEditingController();

  // Lưu toạ độ shop
  double? _shopLat;
  double? _shopLng;

  bool _isLoading = false;

  // =========================
  // Màu dùng chung lấy từ lib/theme/app_theme.dart
  // =========================
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _lighterPink = AppColors.background;
  static const Color _borderPink = AppColors.borderPink;
  static const Color _textDark = AppColors.textDark;
  static const Color _textGrey = AppColors.textGrey;
  static const Color _dangerRed = AppColors.error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // =========================
  // LOGIC CŨ: xử lý đăng ký shop
  // =========================
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_shopLat == null || _shopLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn vị trí shop trên bản đồ')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<ShopProvider>();

      // Gọi hàm register trong Provider
      await provider.register({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'shopAddress': _addressCtrl.text.trim(),
        'shopLat': _shopLat,
        'shopLng': _shopLng,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng ký shop thành công! Chờ duyệt.')),
        );
        Navigator.pop(context); // Quay lại màn hình trước
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: _dangerRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lighterPink,
      appBar: AppBar(
        title: const Text(
          'Đăng ký mở Shop',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header đầu trang theo format hình mẫu
              _buildHeaderCard(),
              const SizedBox(height: 16),

              // Section thông tin cơ bản
              _buildSectionTitle(Icons.storefront_rounded, 'Thông tin cơ bản'),
              const SizedBox(height: 10),
              _buildCard(
                children: [
                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'Tên Shop',
                    icon: Icons.storefront_rounded,
                    validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng nhập tên shop' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _emailCtrl,
                    label: 'Email liên hệ',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => (val == null || !val.contains('@')) ? 'Email không hợp lệ' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _phoneCtrl,
                    label: 'Số điện thoại',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (val) => (val == null || val.length < 9) ? 'SĐT không hợp lệ' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _descCtrl,
                    label: 'Mô tả ngắn',
                    icon: Icons.description_outlined,
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section địa chỉ và vị trí
              _buildSectionTitle(Icons.location_on_rounded, 'Địa chỉ & Vị trí'),
              const SizedBox(height: 10),
              _buildCard(
                children: [
                  // Widget chọn địa chỉ hành chính
                  VietnamAddressSelector(
                    onAddressChanged: (fullAddress) {
                      // Cập nhật chuỗi địa chỉ đầy đủ vào controller
                      _addressCtrl.text = fullAddress;
                    },
                    onCoordinatesChanged: (lat, lng) {
                      // Nếu chọn địa chỉ có toạ độ thì cập nhật map
                      if (lat != null && lng != null) {
                        setState(() {
                          _shopLat = lat;
                          _shopLng = lng;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _addressCtrl,
                    label: 'Địa chỉ chi tiết',
                    icon: Icons.place_outlined,
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập địa chỉ shop' : null,
                  ),

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.push_pin_outlined, color: _primaryPink, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Ghim vị trí chính xác',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _textDark,
                          ),
                        ),
                      ),
                      if (_shopLat != null && _shopLng != null)
                        _buildSmallBadge('Đã chọn'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Widget bản đồ OSM giữ nguyên chức năng chọn toạ độ
                  SizedBox(
                    height: 310,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: OsmLocationPicker(
                        initLat: _shopLat,
                        initLng: _shopLng,
                        onPicked: (lat, lng) {
                          // Người dùng bấm trên map -> cập nhật toạ độ cuối cùng
                          setState(() {
                            _shopLat = lat;
                            _shopLng = lng;
                          });
                        },
                      ),
                    ),
                  ),

                  // Hiển thị toạ độ đã chọn
                  if (_shopLat != null && _shopLng != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Toạ độ: ${_shopLat!.toStringAsFixed(5)}, ${_shopLng!.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _primaryPink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // Nút đăng ký shop
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _onSubmit,
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.add_business_rounded),
                  label: _isLoading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'ĐĂNG KÝ NGAY',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // Header đầu trang: icon tròn + tiêu đề + mô tả
  // =========================
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Row(
        children: [
          _buildCircleIcon(Icons.add_business_rounded, size: 56, iconSize: 30),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mở cửa hàng của bạn',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Điền thông tin shop và chờ admin duyệt 💗',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textGrey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Tiêu đề section: icon nhỏ + text
  // =========================
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primaryPink),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  // =========================
  // Card dùng chung: nền trắng + viền hồng + bo góc
  // =========================
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // =========================
  // TextFormField đồng bộ style hồng nhẹ
  // =========================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryPink),
        filled: true,
        fillColor: _lighterPink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderPink),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderPink),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryPink, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _dangerRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _dangerRed, width: 1.4),
        ),
      ),
    );
  }

  // =========================
  // Badge nhỏ báo đã chọn vị trí
  // =========================
  Widget _buildSmallBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _softPink,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _primaryPink,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =========================
  // Icon tròn dùng chung theo format mẫu
  // =========================
  Widget _buildCircleIcon(IconData icon, {double size = 54, double iconSize = 26}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: _softPink,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _primaryPink, size: iconSize),
    );
  }

  // =========================
  // Decoration card dùng chung: nền trắng + viền hồng + shadow nhẹ
  // =========================
  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _borderPink),
      boxShadow: [
        BoxShadow(
          color: _primaryPink.withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
