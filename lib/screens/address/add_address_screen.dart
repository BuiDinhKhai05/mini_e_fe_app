import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // Dùng để gọi API OpenStreetMap
import 'dart:convert'; // Dùng để decode JSON từ API

import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/vietnam_address_selector.dart';
import '../../widgets/osm_location_picker.dart';

class AddAddressScreen extends StatefulWidget {
  final AddressModel? address;

  const AddAddressScreen({super.key, this.address});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  // Controller cho phần địa chỉ chi tiết.
  // Controller này được truyền vào VietnamAddressSelector để đồng bộ dữ liệu.
  final TextEditingController _detailAddressController = TextEditingController();

  String _finalFormattedAddress = '';
  double? _lat;
  double? _lng;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();

    // Nếu là sửa địa chỉ thì điền sẵn dữ liệu cũ vào form.
    _nameController = TextEditingController(text: widget.address?.fullName ?? '');
    _phoneController = TextEditingController(text: widget.address?.phone ?? '');

    if (widget.address != null) {
      _detailAddressController.text = widget.address!.formattedAddress;
    }

    _finalFormattedAddress = widget.address?.formattedAddress ?? '';
    _lat = widget.address?.lat;
    _lng = widget.address?.lng;
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _detailAddressController.dispose();
    super.dispose();
  }

  // =========================
  // Map -> Address: lấy địa chỉ từ tọa độ bằng OpenStreetMap Nominatim
  // =========================
  Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    // Cập nhật tọa độ để lưu lên server.
    setState(() {
      _lat = lat;
      _lng = lng;
    });

    final url =
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'FlutterApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data['display_name'];

        if (displayName != null) {
          setState(() {
            // Điền địa chỉ lấy được vào ô nhập.
            _detailAddressController.text = displayName;
            _finalFormattedAddress = displayName;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi reverse geocode: $e');
    }
  }

  // =========================
  // Lưu địa chỉ: giữ nguyên logic add/update, chỉ tách ra để code dễ đọc hơn
  // =========================
  Future<void> _handleSave() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    final isEditing = widget.address != null;

    if (!_formKey.currentState!.validate()) return;

    // Nếu người dùng nhập địa chỉ thủ công thì vẫn lấy dữ liệu từ controller.
    if (_finalFormattedAddress.trim().isEmpty &&
        _detailAddressController.text.trim().isNotEmpty) {
      _finalFormattedAddress = _detailAddressController.text.trim();
    }

    if (_finalFormattedAddress.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập hoặc chọn địa chỉ', isError: true);
      return;
    }

    if (auth.accessToken == null) {
      _showSnackBar('Bạn cần đăng nhập để lưu địa chỉ', isError: true);
      return;
    }

    try {
      final data = {
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'formattedAddress': _finalFormattedAddress.trim(),
        'isDefault': _isDefault,
        'lat': _lat,
        'lng': _lng,
      };

      if (isEditing) {
        await addressProvider.updateAddress(
          auth.accessToken!,
          widget.address!.id,
          data,
        );
      } else {
        await addressProvider.addAddress(auth.accessToken!, data);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Lỗi lưu địa chỉ: $e', isError: true);
    }
  }

  // =========================
  // Snackbar thông báo lỗi/thành công
  // =========================
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primaryPink,
      ),
    );
  }

  // =========================
  // Header giống format hồng nhẹ của app
  // =========================
  Widget _buildHeader(bool isEditing) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderPink),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.primaryPink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildCircleIcon(
            icon: isEditing ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
            size: 54,
            iconSize: 29,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Cập nhật địa chỉ' : 'Thêm địa chỉ mới',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing
                      ? 'Chỉnh sửa địa chỉ giao hàng của bạn 💗'
                      : 'Tạo địa chỉ giao hàng cho đơn hàng 💗',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
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
  // Card section để gom từng phần của form
  // =========================
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: AppColors.borderPink),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.lightPink,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(icon, color: AppColors.primaryPink, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // =========================
  // TextFormField style hồng nhẹ
  // =========================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryPink),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          borderSide: const BorderSide(color: AppColors.borderPink),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      validator: validator,
    );
  }

  // =========================
  // Nút lưu ở cuối form
  // =========================
  Widget _buildSaveButton(bool isEditing, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: isLoading ? null : _handleSave,
        icon: isLoading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.save_rounded),
        label: Text(
          isLoading
              ? 'Đang lưu...'
              : isEditing
              ? 'Cập nhật địa chỉ'
              : 'Lưu địa chỉ',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // =========================
  // Icon tròn dùng trong header
  // =========================
  Widget _buildCircleIcon({
    required IconData icon,
    required double size,
    required double iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.lightPink,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primaryPink, size: iconSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);
    final isEditing = widget.address != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isEditing),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =========================
                      // Phần thông tin người nhận
                      // =========================
                      _buildSectionCard(
                        title: 'Thông tin người nhận',
                        icon: Icons.person_rounded,
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Họ và tên',
                              icon: Icons.person_outline_rounded,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Vui lòng nhập tên'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Số điện thoại',
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Vui lòng nhập SĐT'
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      // =========================
                      // Phần chọn địa chỉ Việt Nam
                      // =========================
                      _buildSectionCard(
                        title: 'Địa chỉ giao hàng',
                        icon: Icons.location_on_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VietnamAddressSelector(
                              addressController: _detailAddressController,
                              onAddressChanged: (fullAddr) {
                                setState(() {
                                  _finalFormattedAddress = fullAddr;
                                });
                              },
                              onCoordinatesChanged: (lat, lng) {
                                // Khi chọn tỉnh/huyện/xã thì cập nhật tọa độ cho bản đồ.
                                setState(() {
                                  _lat = lat;
                                  _lng = lng;
                                });
                              },
                            ),
                            if (_finalFormattedAddress.trim().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.borderPink),
                                ),
                                child: Text(
                                  _finalFormattedAddress,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textGrey,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // =========================
                      // Phần ghim vị trí trên bản đồ
                      // =========================
                      _buildSectionCard(
                        title: 'Ghim vị trí trên bản đồ',
                        icon: Icons.map_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: OsmLocationPicker(
                                initLat: _lat,
                                initLng: _lng,
                                onPicked: (lat, lng) {
                                  // Khi nhấn vào bản đồ thì lấy địa chỉ từ tọa độ.
                                  _updateAddressFromCoordinates(lat, lng);
                                },
                              ),
                            ),
                            if (_lat != null && _lng != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.my_location_rounded,
                                    size: 18,
                                    color: AppColors.primaryPink,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tọa độ: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryPink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // =========================
                      // Phần đặt làm mặc định
                      // Nếu địa chỉ hiện tại đã là mặc định thì ẩn công tắc như logic cũ.
                      // =========================
                      if (widget.address?.isDefault != true)
                        _buildSectionCard(
                          title: 'Thiết lập địa chỉ',
                          icon: Icons.star_rounded,
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primaryPink,
                            title: const Text(
                              'Đặt làm địa chỉ mặc định',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            subtitle: const Text(
                              'Địa chỉ này sẽ được ưu tiên khi đặt hàng.',
                              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                            ),
                            value: _isDefault,
                            onChanged: (val) => setState(() => _isDefault = val),
                          ),
                        ),

                      const SizedBox(height: 4),
                      _buildSaveButton(isEditing, addressProvider.isLoading),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
