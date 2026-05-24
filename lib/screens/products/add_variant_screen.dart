// lib/screens/products/add_variant_screen.dart
import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'package:mini_e_fe_app/models/product_model.dart';
import 'package:mini_e_fe_app/providers/product_provider.dart';
import 'edit_product_screen.dart';

class AddVariantScreen extends StatefulWidget {
  final int productId;
  final ProductModel? currentProduct;

  const AddVariantScreen({
    super.key,
    required this.productId,
    this.currentProduct,
  });

  @override
  State<AddVariantScreen> createState() => _AddVariantScreenState();
}

class _AddVariantScreenState extends State<AddVariantScreen> {
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

  final List<_OptionDraft> _options = [];
  String _mode = 'replace';
  bool _isSubmitting = false;

  int get _estimatedVariantCount {
    if (_options.isEmpty) return 0;
    int result = 1;
    for (final option in _options) {
      final count = option.values.length;
      if (count == 0) return 0;
      result *= count;
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadExistingOptions();
  }

  @override
  void dispose() {
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  // =========================
  // Load optionSchema cũ nếu seller đang chỉnh biến thể.
  // =========================
  void _loadExistingOptions() {
    final schema = widget.currentProduct?.optionSchema ?? [];
    if (schema.isEmpty) return;

    for (final item in schema) {
      _options.add(_OptionDraft(
        name: item.name,
        values: List<String>.from(item.values),
      ));
    }
  }

  void _addOption() {
    if (_options.length >= 5) {
      _showSnack('Tối đa 5 nhóm thuộc tính', isError: true);
      return;
    }
    setState(() => _options.add(_OptionDraft()));
  }

  void _removeOption(int index) {
    setState(() {
      _options[index].dispose();
      _options.removeAt(index);
    });
  }

  void _addValueToOption(int index) {
    final option = _options[index];
    final value = option.tempValueController.text.trim();
    if (value.isEmpty) return;

    final exists = option.values.any((item) => item.toLowerCase() == value.toLowerCase());
    if (exists) {
      option.tempValueController.clear();
      _showSnack('Giá trị "$value" đã tồn tại', isError: true);
      return;
    }

    if (option.values.length >= 20) {
      _showSnack('Mỗi nhóm chỉ nên có tối đa 20 giá trị', isError: true);
      return;
    }

    setState(() {
      option.values.add(value);
      option.tempValueController.clear();
    });
  }

  void _removeValueFromOption(int optionIndex, String value) {
    setState(() => _options[optionIndex].values.remove(value));
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

  List<Map<String, dynamic>> _buildOptionsPayload() {
    return _options
        .map((option) => {
      'name': option.nameController.text.trim(),
      'values': option.values.map((value) => value.trim()).where((value) => value.isNotEmpty).toList(),
    })
        .toList();
  }

  String? _validateOptions(List<Map<String, dynamic>> options) {
    if (options.isEmpty) return 'Vui lòng thêm ít nhất 1 nhóm thuộc tính';

    final names = <String>{};
    for (final option in options) {
      final name = option['name'].toString().trim();
      final values = (option['values'] as List).cast<String>();

      if (name.isEmpty) return 'Tên thuộc tính không được để trống';
      if (values.isEmpty) return 'Mỗi thuộc tính phải có ít nhất 1 giá trị';

      final nameKey = name.toLowerCase();
      if (names.contains(nameKey)) return 'Tên thuộc tính "$name" bị trùng';
      names.add(nameKey);

      final valueKeys = <String>{};
      for (final value in values) {
        final key = value.toLowerCase();
        if (valueKeys.contains(key)) return 'Giá trị "$value" trong $name bị trùng';
        valueKeys.add(key);
      }
    }

    if (_estimatedVariantCount > 300) {
      return 'Số biến thể dự kiến quá nhiều ($_estimatedVariantCount). Hãy giảm bớt giá trị.';
    }

    return null;
  }

  // =========================
  // Submit: gọi API generate variants, sau đó load lại product mới nhất.
  // =========================
  Future<void> _submitVariants() async {
    if (_isSubmitting) return;

    final options = _buildOptionsPayload();
    final error = _validateOptions(options);
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<ProductProvider>();

    try {
      final result = await provider.generateVariants(
        widget.productId,
        options,
        mode: _mode,
      );

      if (!mounted) return;
      if (result == null) {
        _showSnack(provider.error ?? 'Cập nhật biến thể thất bại', isError: true);
        return;
      }

      final updatedProduct = await provider.fetchProductDetail(widget.productId);
      if (!mounted) return;
      _showSnack('Cập nhật biến thể thành công');

      if (updatedProduct != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => EditProductScreen(product: updatedProduct)),
        );
      } else {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lighterPink,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        title: const Text(
          'Cấu hình biến thể',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  _buildGuideCard(),
                  const SizedBox(height: 14),
                  _buildModeCard(),
                  const SizedBox(height: 14),
                  if (_options.isEmpty) _buildEmptyState(),
                  ...List.generate(_options.length, _buildOptionCard),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _addOption,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Thêm nhóm thuộc tính'),
                      style: _outlineButtonStyle(),
                    ),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.tune_rounded, color: _primaryPink),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo phân loại cho sản phẩm',
                  style: TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ví dụ: Màu sắc = Đỏ, Xanh; Size = S, M, L. Hệ thống sẽ tự sinh tổ hợp biến thể.',
                  style: TextStyle(color: _textGrey, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chế độ cập nhật',
                  style: TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _mode == 'replace'
                      ? 'Thay thế toàn bộ biến thể cũ bằng cấu hình mới.'
                      : 'Giữ biến thể cũ và chỉ thêm tổ hợp mới.',
                  style: const TextStyle(color: _textGrey, height: 1.3),
                ),
                const SizedBox(height: 10),
                _buildEstimateChip(),
              ],
            ),
          ),
          Switch(
            value: _mode == 'replace',
            activeColor: _primaryPink,
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _mode = value ? 'replace' : 'add'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _softPink,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'Dự kiến: $_estimatedVariantCount biến thể',
        style: const TextStyle(
          color: _primaryPink,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(Icons.category_outlined, size: 58, color: _borderPink),
          SizedBox(height: 12),
          Text(
            'Chưa có nhóm thuộc tính',
            style: TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Nhấn nút bên dưới để thêm Size, Màu sắc hoặc kiểu dáng.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index) {
    final option = _options[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _softPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: _primaryPink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: option.nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Tên thuộc tính',
                    hint: 'Ví dụ: Màu sắc, Size',
                    icon: Icons.label_outline_rounded,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                tooltip: 'Xóa nhóm',
                onPressed: _isSubmitting ? null : () => _removeOption(index),
                icon: const Icon(Icons.delete_outline_rounded, color: _dangerRed),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (option.values.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: option.values.map((value) {
                return Chip(
                  label: Text(value),
                  backgroundColor: _softPink,
                  deleteIconColor: _dangerRed,
                  side: const BorderSide(color: _borderPink),
                  onDeleted: _isSubmitting ? null : () => _removeValueFromOption(index, value),
                );
              }).toList(),
            )
          else
            const Text(
              'Chưa có giá trị nào',
              style: TextStyle(color: _textGrey, fontSize: 13),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: option.tempValueController,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    label: 'Giá trị mới',
                    hint: 'Ví dụ: Đỏ',
                    icon: Icons.add_circle_outline_rounded,
                  ),
                  onSubmitted: (_) => _addValueToOption(index),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _addValueToOption(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitVariants,
          icon: _isSubmitting
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
          )
              : const Icon(Icons.check_rounded),
          label: Text(_isSubmitting ? 'Đang cập nhật...' : 'Cập nhật biến thể'),
          style: _primaryButtonStyle(),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _borderPink.withOpacity(0.75)),
      boxShadow: [
        BoxShadow(
          color: _primaryPink.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: _primaryPink),
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

class _OptionDraft {
  final TextEditingController nameController;
  final TextEditingController tempValueController;
  final List<String> values;

  _OptionDraft({String name = '', List<String>? values})
      : nameController = TextEditingController(text: name),
        tempValueController = TextEditingController(),
        values = values ?? <String>[];

  void dispose() {
    nameController.dispose();
    tempValueController.dispose();
  }
}
