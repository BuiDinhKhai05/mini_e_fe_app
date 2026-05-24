// lib/screens/products/add_product_screen.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:mini_e_fe_app/models/product_model.dart';
import 'package:mini_e_fe_app/providers/product_provider.dart';
import 'add_variant_screen.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? editProduct;

  const AddProductScreen({super.key, this.editProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // =========================
  // Màu dùng chung theo format Soft Pink Card UI
  // =========================
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _lighterPink = AppColors.background;
  static const Color _borderPink = AppColors.borderPink;
  static const Color _textDark = AppColors.textDark;
  static const Color _textGrey = AppColors.textGrey;
  static const Color _dangerRed = AppColors.error;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _slugController;

  final ImagePicker _picker = ImagePicker();

  // Ảnh mới chọn: Mobile dùng File, Web dùng Uint8List.
  final List<File> _images = [];
  final List<Uint8List> _imageBytes = [];

  bool _isSubmitting = false;

  bool get _isEditMode => widget.editProduct != null;
  int get _selectedImageCount => kIsWeb ? _imageBytes.length : _images.length;
  List<dynamic> get _selectedImages => kIsWeb ? _imageBytes : _images;

  @override
  void initState() {
    super.initState();
    final product = widget.editProduct;
    _titleController = TextEditingController(text: product?.title ?? '');
    _descriptionController = TextEditingController(text: product?.description ?? '');
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(0),
    );
    _stockController = TextEditingController(
      text: product == null ? '' : product.stock.toString(),
    );
    _slugController = TextEditingController(text: product?.slug ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  // =========================
  // Helper: parse tiền/kho an toàn
  // =========================
  double _parsePrice(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(normalized) ?? 0;
  }

  int? _parseStock(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  String _generateSlug(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'đ'), 'd')
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  String? _validateSlug(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final valid = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(text);
    if (!valid) return 'Slug chỉ gồm a-z, 0-9 và dấu -';
    if (text.length > 200) return 'Slug tối đa 200 ký tự';
    return null;
  }

  // =========================
  // Chọn ảnh sản phẩm, giới hạn tối đa 10 ảnh.
  // =========================
  Future<void> _pickImages() async {
    if (_selectedImageCount >= 10) {
      _showSnack('Bạn chỉ được chọn tối đa 10 ảnh', isError: true);
      return;
    }

    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    final remaining = 10 - _selectedImageCount;
    final selected = picked.take(remaining).toList();

    if (kIsWeb) {
      final bytesList = <Uint8List>[];
      for (final xFile in selected) {
        bytesList.add(await xFile.readAsBytes());
      }
      if (!mounted) return;
      setState(() => _imageBytes.addAll(bytesList));
    } else {
      setState(() => _images.addAll(selected.map((xFile) => File(xFile.path))));
    }

    if (picked.length > remaining) {
      _showSnack('Chỉ lấy thêm $remaining ảnh vì giới hạn tối đa là 10 ảnh');
    }
  }

  void _removeImage(dynamic item) {
    setState(() {
      if (kIsWeb) {
        _imageBytes.remove(item);
      } else {
        _images.remove(item);
      }
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _dangerRed : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================
  // Submit form: tạo mới hoặc cập nhật sản phẩm.
  // =========================
  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final provider = context.read<ProductProvider>();
    final price = _parsePrice(_priceController.text);
    // BE hiện tại không nhận stock ở product. Tồn kho sẽ được tính từ variants.
    final slug = _slugController.text.trim();
    final description = _descriptionController.text.trim();

    try {
      if (_isEditMode) {
        final success = await provider.updateProduct(
          productId: widget.editProduct!.id,
          title: _titleController.text.trim(),
          price: price,
          description: description,
          slug: slug.isEmpty ? null : slug,
          // BE hiện tại chưa có FilesInterceptor cho PATCH /products/:id,
          // nên màn chỉnh sửa chỉ gửi text/price/status để tránh lỗi upload ảnh.
          images: null,
        );

        if (!mounted) return;
        if (success) {
          _showSnack('Cập nhật sản phẩm thành công');
          Navigator.pop(context, true);
        } else {
          _showSnack(provider.error ?? 'Cập nhật sản phẩm thất bại', isError: true);
        }
        return;
      }

      final newProduct = await provider.createProduct(
        title: _titleController.text.trim(),
        price: price,
        description: description,
        slug: slug.isEmpty ? null : slug,
        images: _selectedImages,
      );

      if (!mounted) return;
      if (newProduct == null) {
        _showSnack(provider.error ?? 'Tạo sản phẩm thất bại', isError: true);
        return;
      }

      _showSnack('Tạo sản phẩm thành công');
      await _showAfterCreateActions(newProduct);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showAfterCreateActions(ProductModel product) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _borderPink,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Sản phẩm đã được tạo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn có thể cấu hình Size/Màu ngay, hoặc để sau trong trang chỉnh sửa sản phẩm.',
                  style: TextStyle(color: _textGrey, height: 1.35),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, 'variant'),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Thêm biến thể ngay'),
                    style: _primaryButtonStyle(),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, 'done'),
                    style: _outlineButtonStyle(),
                    child: const Text('Để sau'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (result == 'variant') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AddVariantScreen(productId: product.id, currentProduct: product),
        ),
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode ? 'Chỉnh sửa sản phẩm' : 'Thêm sản phẩm mới';

    return Scaffold(
      backgroundColor: _lighterPink,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'Thông tin cơ bản',
                icon: Icons.inventory_2_outlined,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Tên sản phẩm',
                    hint: 'Ví dụ: Áo thun form rộng',
                    icon: Icons.sell_outlined,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Vui lòng nhập tên sản phẩm';
                      if (value.length < 3) return 'Tên sản phẩm nên có ít nhất 3 ký tự';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _slugController,
                    label: 'Slug',
                    hint: 'Để trống tự sinh Slug',
                    icon: Icons.link_rounded,
                    validator: _validateSlug,
                    suffixIcon: IconButton(
                      tooltip: 'Tự tạo slug từ tên sản phẩm',
                      icon: const Icon(Icons.auto_fix_high_rounded, color: _primaryPink),
                      onPressed: () {
                        final raw = _titleController.text.trim();
                        if (raw.isEmpty) {
                          _showSnack('Nhập tên sản phẩm trước khi tạo slug', isError: true);
                          return;
                        }
                        _slugController.text = _generateSlug(raw);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Mô tả',
                    hint: 'Mô tả chất liệu, công dụng, lưu ý...',
                    icon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'Giá và tồn kho',
                icon: Icons.payments_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Giá bán',

                          icon: Icons.attach_money_rounded,
                          suffixText: 'VND',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) return 'Nhập giá';
                            if (_parsePrice(v!) <= 0) return 'Giá phải lớn hơn 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _stockController,
                          label: 'Tồn kho',
                          icon: Icons.warehouse_outlined,
                          keyboardType: TextInputType.number,
                          enabled: false,
                          helperText: 'Tự tính từ biến thể',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lưu ý: BE hiện tại tính tồn kho từ các biến thể. Sau khi tạo sản phẩm, hãy thêm Size/Màu và cập nhật kho từng biến thể.',
                    style: TextStyle(color: _textGrey, fontSize: 12, height: 1.35),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'Hình ảnh sản phẩm',
                icon: Icons.photo_library_outlined,
                children: [
                  if (_isEditMode && widget.editProduct!.images.isNotEmpty)
                    _buildCurrentImages(),
                  if (_isEditMode)
                    const Text(
                      'BE hiện tại chưa hỗ trợ cập nhật ảnh bằng PATCH, nên phần chỉnh sửa chỉ giữ ảnh hiện có.',
                      style: TextStyle(color: _textGrey, fontSize: 12, height: 1.35),
                    )
                  else ...[
                    if (_selectedImageCount > 0) ...[
                      _buildSelectedImages(),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _pickImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text('Chọn ảnh ($_selectedImageCount/10)'),
                        style: _outlineButtonStyle(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ảnh đầu tiên hoặc ảnh main sẽ được dùng làm ảnh đại diện.',
                      style: TextStyle(color: _textGrey, fontSize: 12),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: _primaryButtonStyle(),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                      : Text(_isEditMode ? 'Lưu thay đổi' : 'Tạo sản phẩm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.lightPink, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderPink),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_mall_outlined, color: _primaryPink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditMode ? 'Cập nhật thông tin bán hàng' : 'Đăng bán sản phẩm mới',
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Điền đầy đủ thông tin để sản phẩm hiển thị đẹp hơn trong app.',
                  style: TextStyle(color: _textGrey, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderPink.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.06),
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
              Icon(icon, color: _primaryPink, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    String? suffixText,
    bool enabled = true,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: icon == null ? null : Icon(icon, color: _primaryPink),
        suffixIcon: suffixIcon,
        // Hiển thị đơn vị tiền tệ ở cuối ô nhập giá, chỉ là UI nên không ảnh hưởng dữ liệu gửi lên API.
        suffixText: suffixText,
        suffixStyle: const TextStyle(
          color: _primaryPink,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: _lighterPink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      ),
    );
  }

  Widget _buildCurrentImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh hiện tại',
          style: TextStyle(fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.editProduct!.images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final image = widget.editProduct!.images[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  image.url,
                  width: 82,
                  height: 82,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 82,
                    height: 82,
                    color: _softPink,
                    child: const Icon(Icons.broken_image_outlined, color: _primaryPink),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildSelectedImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ảnh mới đã chọn ($_selectedImageCount/10)',
          style: const TextStyle(fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _selectedImages.map((dynamic item) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: kIsWeb
                      ? Image.memory(
                    item as Uint8List,
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                  )
                      : Image.file(
                    item as File,
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => _removeImage(item),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: _dangerRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _primaryPink,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: _primaryPink,
      side: const BorderSide(color: _borderPink),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );
  }
}
