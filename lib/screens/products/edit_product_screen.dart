// lib/screens/products/edit_product_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'package:mini_e_fe_app/models/product_model.dart';
import 'package:mini_e_fe_app/providers/product_provider.dart';
import 'add_variant_screen.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen>
    with SingleTickerProviderStateMixin {
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

  late final TabController _tabController;
  final _formKeyInfo = GlobalKey<FormState>();

  late ProductModel _product;
  late final TextEditingController _titleController;
  late final TextEditingController _slugController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  bool _isSavingProduct = false;
  bool _isLoadingDetail = false;
  bool _isLoadingVariants = false;
  List<VariantItem> _variants = [];

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _tabController = TabController(length: 2, vsync: this);
    _titleController = TextEditingController(text: _product.title);
    _slugController = TextEditingController(text: _product.slug ?? '');
    _descController = TextEditingController(text: _product.description ?? '');
    _priceController = TextEditingController(text: _product.price.toStringAsFixed(0));
    _stockController = TextEditingController(text: _product.stock.toString());
    _loadProductDetail();
    _fetchVariants();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _slugController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  double _parsePrice(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(normalized) ?? 0;
  }

  int _parseStock(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  String? _validateSlug(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final valid = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(text);
    if (!valid) return 'Slug chỉ gồm a-z, 0-9 và dấu -';
    if (text.length > 200) return 'Slug tối đa 200 ký tự';
    return null;
  }

  // Format giá tiền theo kiểu Việt Nam và thêm hậu tố VND để thống nhất toàn app.
  String _formatPrice(num value) {
    final formatted = value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    );
    return '$formatted VND';
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
  // Load lại chi tiết để có ảnh/optionSchema mới nhất.
  // =========================
  Future<void> _loadProductDetail() async {
    if (_isLoadingDetail) return;
    setState(() => _isLoadingDetail = true);

    final provider = context.read<ProductProvider>();
    final fresh = await provider.fetchProductDetail(_product.id);

    if (!mounted) return;
    if (fresh != null) {
      setState(() {
        _product = fresh;
        _titleController.text = fresh.title;
        _slugController.text = fresh.slug ?? '';
        _descController.text = fresh.description ?? '';
        _priceController.text = fresh.price.toStringAsFixed(0);
        _stockController.text = fresh.stock.toString();
      });
    }
    setState(() => _isLoadingDetail = false);
  }

  Future<void> _fetchVariants() async {
    setState(() => _isLoadingVariants = true);
    final provider = context.read<ProductProvider>();
    final results = await provider.getVariants(_product.id);
    if (!mounted) return;
    setState(() {
      _variants = results;
      _isLoadingVariants = false;
    });
  }

  // =========================
  // Lưu thông tin chung của sản phẩm.
  // =========================
  Future<void> _saveProductInfo() async {
    if (_isSavingProduct) return;
    if (!_formKeyInfo.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSavingProduct = true);

    final provider = context.read<ProductProvider>();
    final success = await provider.updateProduct(
      productId: _product.id,
      title: _titleController.text.trim(),
      slug: _slugController.text.trim().isEmpty ? null : _slugController.text.trim(),
      description: _descController.text.trim(),
      price: _parsePrice(_priceController.text),
      // BE hiện tại không nhận stock ở product. Tồn kho được sync từ variants.
    );

    if (!mounted) return;
    setState(() => _isSavingProduct = false);

    if (success) {
      setState(() {
        _product = _product.copyWith(
          title: _titleController.text.trim(),
          slug: _slugController.text.trim().isEmpty ? null : _slugController.text.trim(),
          description: _descController.text.trim(),
          price: _parsePrice(_priceController.text),
        );
      });
      await _loadProductDetail();
      _showSnack('Đã lưu thông tin sản phẩm');
    } else {
      _showSnack(provider.error ?? 'Lưu sản phẩm thất bại', isError: true);
    }
  }

  Future<void> _openVariantConfig() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVariantScreen(
          productId: _product.id,
          currentProduct: _product,
        ),
      ),
    );

    if (!mounted) return;
    if (changed == true || changed == null) {
      await _loadProductDetail();
      await _fetchVariants();
    }
  }

  // =========================
  // Dialog sửa nhanh biến thể: tên, SKU, giá, tồn kho, ảnh đại diện.
  // =========================
  Future<void> _showEditVariantDialog(VariantItem variant) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: variant.name);
    final skuCtrl = TextEditingController(text: variant.sku);
    final priceCtrl = TextEditingController(text: variant.price.toStringAsFixed(0));
    final stockCtrl = TextEditingController(text: variant.stock.toString());
    int? selectedImageId = variant.imageId;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: _primaryPink),
                  SizedBox(width: 8),
                  Text('Sửa biến thể', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                        controller: nameCtrl,
                        label: 'Tên biến thể',
                        icon: Icons.label_outline_rounded,
                        validator: (v) => (v ?? '').trim().isEmpty ? 'Nhập tên biến thể' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: skuCtrl,
                              label: 'SKU',
                              icon: Icons.qr_code_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildTextField(
                              controller: stockCtrl,
                              label: 'Tồn kho',
                              icon: Icons.warehouse_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final value = int.tryParse((v ?? '').trim());
                                if (value == null || value < 0) return 'Không hợp lệ';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: priceCtrl,
                        label: 'Giá bán',
                        icon: Icons.payments_outlined,
                        suffixText: 'VND',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (_parsePrice(v ?? '') <= 0) return 'Giá phải lớn hơn 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: _product.images.any((img) => img.id == selectedImageId) ? selectedImageId : null,
                        decoration: _inputDecoration(
                          label: 'Ảnh đại diện biến thể',
                          icon: Icons.image_outlined,
                        ),
                        items: <DropdownMenuItem<int?>>[
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Không chọn ảnh riêng'),
                          ),
                          ..._product.images.asMap().entries.map((entry) {
                            final index = entry.key;
                            final image = entry.value;
                            return DropdownMenuItem<int?>(
                              value: image.id,
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: image.url,
                                      width: 34,
                                      height: 34,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('Ảnh ${index + 1}'),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) => selectedImageId = value,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Hủy', style: TextStyle(color: _textGrey)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSaving = true);

                    final provider = context.read<ProductProvider>();
                    final success = await provider.updateVariant(
                      _product.id,
                      variant.id,
                      {
                        'name': nameCtrl.text.trim(),
                        'sku': skuCtrl.text.trim(),
                        'price': _parsePrice(priceCtrl.text),
                        'stock': _parseStock(stockCtrl.text),
                        'imageId': selectedImageId,
                      },
                    );

                    if (!mounted) return;
                    if (success) {
                      Navigator.pop(ctx);
                      await _fetchVariants();
                      _showSnack('Đã cập nhật biến thể');
                    } else {
                      setDialogState(() => isSaving = false);
                      _showSnack(provider.error ?? 'Cập nhật biến thể thất bại', isError: true);
                    }
                  },
                  style: _primaryButtonStyle(compact: true),
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    skuCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
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
          'Chỉnh sửa sản phẩm',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _softPink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: _primaryPink,
              unselectedLabelColor: _textGrey,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              tabs: const [
                Tab(text: 'Thông tin'),
                Tab(text: 'Biến thể'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildVariantTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return RefreshIndicator(
      color: _primaryPink,
      onRefresh: _loadProductDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        child: Form(
          key: _formKeyInfo,
          child: Column(
            children: [
              _buildProductSummaryCard(),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'Thông tin sản phẩm',
                icon: Icons.inventory_2_outlined,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Tên sản phẩm',
                    icon: Icons.sell_outlined,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _slugController,
                    label: 'Slug',
                    icon: Icons.link_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _descController,
                    label: 'Mô tả',
                    icon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildSectionCard(
                title: 'Giá và kho',
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
                          validator: (v) => _parsePrice(v ?? '') <= 0 ? 'Giá phải lớn hơn 0' : null,
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
                    'Tồn kho sản phẩm được BE đồng bộ từ tổng tồn kho các biến thể. Hãy chỉnh kho trong tab Biến thể.',
                    style: TextStyle(color: _textGrey, fontSize: 12, height: 1.35),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildImagesCard(),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingProduct ? null : _saveProductInfo,
                  icon: _isSavingProduct
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                  )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSavingProduct ? 'Đang lưu...' : 'Lưu thay đổi'),
                  style: _primaryButtonStyle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariantTab() {
    return RefreshIndicator(
      color: _primaryPink,
      onRefresh: () async {
        await _loadProductDetail();
        await _fetchVariants();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: _buildVariantHeaderCard(),
            ),
          ),
          if (_isLoadingVariants)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _primaryPink)),
            )
          else if (_variants.isEmpty)
            SliverFillRemaining(
              child: _buildVariantEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList.separated(
                itemCount: _variants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _buildVariantItem(_variants[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductSummaryCard() {
    final imageUrl = _product.imageUrl.isNotEmpty
        ? _product.imageUrl
        : (_product.images.isNotEmpty ? _product.images.first.url : '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: imageUrl.isEmpty
                ? Container(
              width: 76,
              height: 76,
              color: _softPink,
              child: const Icon(Icons.image_outlined, color: _primaryPink),
            )
                : CachedNetworkImage(
              imageUrl: imageUrl,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 76,
                height: 76,
                color: _softPink,
                child: const Icon(Icons.broken_image_outlined, color: _primaryPink),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatPrice(_product.price),
                  style: const TextStyle(
                    color: _primaryPink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _miniChip(_product.status),
                    _miniChip('Kho: ${_product.stock}'),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoadingDetail)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: _primaryPink, strokeWidth: 2),
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
      decoration: _cardDecoration(),
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

  Widget _buildImagesCard() {
    return _buildSectionCard(
      title: 'Hình ảnh hiện tại',
      icon: Icons.photo_library_outlined,
      children: [
        if (_product.images.isEmpty)
          const Text('Sản phẩm chưa có ảnh.', style: TextStyle(color: _textGrey))
        else
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _product.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, index) {
                final image = _product.images[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: image.url,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 88,
                          height: 88,
                          color: _softPink,
                          child: const Icon(Icons.broken_image_outlined, color: _primaryPink),
                        ),
                      ),
                    ),
                    if (image.isMain)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _primaryPink,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'Main',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildVariantHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _softPink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.tune_rounded, color: _primaryPink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Biến thể sản phẩm',
                  style: TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_variants.length} biến thể • ${_product.optionSchema?.length ?? 0} nhóm thuộc tính',
                  style: const TextStyle(color: _textGrey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _openVariantConfig,
            style: _primaryButtonStyle(compact: true),
            child: const Text('Cấu hình'),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _borderPink),
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 42, color: _primaryPink),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có biến thể nào',
            style: TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bạn có thể thêm Size, Màu sắc hoặc các phân loại khác để người mua lựa chọn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textGrey, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openVariantConfig,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Thêm biến thể'),
            style: _primaryButtonStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantItem(VariantItem item) {
    final imageUrl = _findImageUrlById(item.imageId);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl == null
                ? Container(
              width: 62,
              height: 62,
              color: _softPink,
              child: const Icon(Icons.image_outlined, color: _primaryPink),
            )
                : CachedNetworkImage(
              imageUrl: imageUrl,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 62,
                height: 62,
                color: _softPink,
                child: const Icon(Icons.broken_image_outlined, color: _primaryPink),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.isEmpty ? 'Biến thể #${item.id}' : item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                if (item.options.isNotEmpty)
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: item.options.map((opt) {
                      return _miniChip((opt['value'] ?? '').toString());
                    }).toList(),
                  ),
                const SizedBox(height: 6),
                Text(
                  'SKU: ${item.sku.isEmpty ? 'Chưa có' : item.sku} • Kho: ${item.stock}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPrice(item.price),
                style: const TextStyle(
                  color: _primaryPink,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              IconButton(
                tooltip: 'Sửa biến thể',
                onPressed: () => _showEditVariantDialog(item),
                icon: const Icon(Icons.edit_outlined, color: _textGrey, size: 21),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _findImageUrlById(int? imageId) {
    if (imageId == null) return null;
    for (final image in _product.images) {
      if (image.id == imageId) return image.url;
    }
    return null;
  }

  Widget _miniChip(String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _softPink,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _borderPink),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _primaryPink,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
      decoration: _inputDecoration(
        label: label,
        icon: icon,
        suffixText: suffixText,
        helperText: helperText,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    String? suffixText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: icon == null ? null : Icon(icon, color: _primaryPink),
      // Hiển thị đơn vị tiền tệ ở cuối ô nhập giá, không làm thay đổi giá trị trong controller.
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

  ButtonStyle _primaryButtonStyle({bool compact = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: _primaryPink,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: compact
          ? const EdgeInsets.symmetric(vertical: 10, horizontal: 14)
          : const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 14 : 18)),
      textStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: compact ? 13 : 15,
      ),
    );
  }
}
