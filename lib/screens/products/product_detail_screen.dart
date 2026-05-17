// lib/screens/products/product_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/cart_provider.dart';

import 'edit_product_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final bool isFromShopManagement;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.isFromShopManagement = false,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductModel _currentProduct;

  bool _isLoadingVariants = false;
  List<VariantItem> _variants = [];

  // gallery
  late final PageController _pageController;
  int _currentImageIndex = 0;

  // variant selection
  final Map<String, String> _selectedOptions = {};
  VariantItem? _selectedVariant;

  bool _isDescriptionExpanded = false;
  bool _isUpdatingStatus = false;

  final Color _primaryColor = const Color(0xFFE84B82);
  final Color _accentColor = const Color(0xFFFF6FA5);
  final Color _bgColor = const Color(0xFFFFF5F8);
  final Color _textTitleColor = const Color(0xFF4A2C36);
  final Color _textBodyColor = const Color(0xFF8A6F78);

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _pageController = PageController(initialPage: 0);

    _loadProductDetail();
    _fetchVariants();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ======== LOAD DETAIL (để có images[]) ========
  Future<void> _loadProductDetail() async {
    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final fresh = await provider.fetchProductDetail(widget.product.id);
      if (!mounted) return;
      if (fresh != null) {
        setState(() {
          _currentProduct = fresh;
          _currentImageIndex = 0;
        });
        _applyVariantSelection();
      }
    } catch (_) {}
  }

  // ======== VARIANTS ========
  Future<void> _fetchVariants() async {
    setState(() => _isLoadingVariants = true);
    try {
      final productProvider =
      Provider.of<ProductProvider>(context, listen: false);
      final result = await productProvider.getVariants(widget.product.id);
      if (!mounted) return;
      setState(() {
        _variants = result;
        _isLoadingVariants = false;
      });
      _applyVariantSelection();
    } catch (_) {
      if (mounted) setState(() => _isLoadingVariants = false);
    }
  }

  bool get _hasOptions =>
      _currentProduct.optionSchema != null &&
          _currentProduct.optionSchema!.isNotEmpty;

  bool get _isFullSelection {
    if (!_hasOptions) return true;
    return _currentProduct.optionSchema!
        .every((opt) => _selectedOptions.containsKey(opt.name));
  }

  String _norm(String s) => s.trim().toLowerCase();

  /// ✅ MATCH VARIANT theo options (không dùng name)
  VariantItem? _findVariantBySelectedOptions() {
    if (!_hasOptions || !_isFullSelection || _variants.isEmpty) return null;

    final selectedNorm = <String, String>{};
    for (final e in _selectedOptions.entries) {
      selectedNorm[_norm(e.key)] = _norm(e.value);
    }

    for (final v in _variants) {
      final vMap = <String, String>{};
      for (final opt in v.options) {
        final k = _norm(opt['option'] ?? '');
        final val = _norm(opt['value'] ?? '');
        if (k.isNotEmpty) vMap[k] = val;
      }

      bool ok = true;
      for (final schema in _currentProduct.optionSchema!) {
        final k = _norm(schema.name);
        final selVal = selectedNorm[k];
        if (selVal == null || selVal.isEmpty) {
          ok = false;
          break;
        }
        if (vMap[k] != selVal) {
          ok = false;
          break;
        }
      }

      if (ok) return v;
    }

    return null;
  }

  void _applyVariantSelection() {
    if (!mounted) return;

    // ❗ Nếu chưa có variants -> không thể chọn variant
    if (_variants.isEmpty) {
      setState(() => _selectedVariant = null);
      return;
    }

    // ✅ Trường hợp KHÔNG có optionSchema nhưng vẫn có variants:
    // chọn mặc định variant đầu tiên (hoặc giữ nếu đang chọn hợp lệ)
    if (!_hasOptions) {
      VariantItem toSelect = _variants.first;

      if (_selectedVariant != null) {
        final idx = _variants.indexWhere((v) => v.id == _selectedVariant!.id);
        if (idx != -1) toSelect = _variants[idx];
      }

      setState(() => _selectedVariant = toSelect);

      if (toSelect.imageId != null && _currentProduct.images.isNotEmpty) {
        final imgIdx = _currentProduct.images
            .indexWhere((img) => img.id == toSelect.imageId);
        if (imgIdx != -1) _jumpToImage(imgIdx);
      }
      return;
    }

    // ✅ Có optionSchema
    if (!_isFullSelection) {
      setState(() => _selectedVariant = null);
      return;
    }

    final found = _findVariantBySelectedOptions();
    setState(() => _selectedVariant = found);

    // đổi ảnh theo imageId của variant
    if (found?.imageId != null && _currentProduct.images.isNotEmpty) {
      final idx =
      _currentProduct.images.indexWhere((img) => img.id == found!.imageId);
      if (idx != -1) _jumpToImage(idx);
    }
  }

  // ======== GALLERY ========
  List<ProductImage> get _images {
    if (_currentProduct.images.isNotEmpty) return _currentProduct.images;
    if (_currentProduct.imageUrl.isNotEmpty) {
      return [
        ProductImage(
            id: 0,
            url: _currentProduct.imageUrl,
            isMain: true,
            position: 0),
      ];
    }
    return [
      ProductImage(
          id: 0,
          url: 'https://placehold.co/600x600.png?text=No+Image',
          isMain: true,
          position: 0),
    ];
  }

  void _jumpToImage(int index) {
    if (index < 0 || index >= _images.length) return;
    setState(() => _currentImageIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  // ======== DISPLAY PRICE/STOCK ========
  String _formatPrice(dynamic price) {
    double value = 0.0;
    if (price is String) value = double.tryParse(price) ?? 0.0;
    else if (price is num) value = price.toDouble();
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  String get _displayPrice {
    if (_selectedVariant != null && _selectedVariant!.price > 0) {
      return _formatPrice(_selectedVariant!.price);
    }
    return _formatPrice(_currentProduct.price);
  }

  int get _displayStock {
    if (_selectedVariant != null) return _selectedVariant!.stock;

    // chưa chọn đủ: show tổng kho variants (cho dễ hiểu)
    if (_variants.isNotEmpty && _hasOptions) {
      return _variants.fold<int>(0, (sum, v) => sum + v.stock);
    }
    return _currentProduct.stock;
  }

  // ======== PERMISSION (seller manage) ========
  bool _canManageProduct() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    if (authProvider.user == null || shopProvider.shop == null) return false;
    final userRole = authProvider.user!.role?.toUpperCase();
    final isSeller = userRole == 'SELLER';
    final isOwnerOfThisShop = shopProvider.shop!.id == widget.product.shopId;
    return isSeller && isOwnerOfThisShop && widget.isFromShopManagement;
  }

  Future<void> _toggleProductStatus() async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final success = await provider.toggleProductStatus(_currentProduct.id);

    if (!mounted) return;
    setState(() => _isUpdatingStatus = false);

    if (success) {
      final updated = provider.products.firstWhere(
            (p) => p.id == _currentProduct.id,
        orElse: () => _currentProduct,
      );
      setState(() => _currentProduct = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updated.status == 'ACTIVE'
              ? 'Đã bật bán'
              : 'Đã ẩn sản phẩm'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final success = await provider.deleteProduct(_currentProduct.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã xóa sản phẩm'),
              backgroundColor: Colors.green),
        );
      }
    }
  }

  // ======== CART ACTION ========
  // Mở popup chọn phân loại giống popup ở Home.
  // Lưu ý: phần phân loại trong màn chi tiết chỉ để xem,
  // còn thao tác chọn phân loại/số lượng sẽ nằm trong popup này.
  Future<void> _showProductCartDialog({required bool isBuyNow}) async {
    int quantity = 1;
    int? selectedVariantId;
    final Map<String, String> selectedOptions = {};

    List<VariantItem> dialogVariants = List<VariantItem>.from(_variants);

    if (dialogVariants.isEmpty) {
      try {
        final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
        dialogVariants = await productProvider.getVariants(_currentProduct.id);
        if (!mounted) return;
        setState(() => _variants = dialogVariants);
      } catch (_) {
        dialogVariants = [];
      }
    }

    if (!mounted) return;

    final product = _currentProduct;
    final bool hasOptionSchema =
        product.optionSchema != null && product.optionSchema!.isNotEmpty;

    String norm(String value) => value.trim().toLowerCase();

    Map<String, String> variantOptionMap(VariantItem variant) {
      final result = <String, String>{};
      for (final opt in variant.options) {
        final key = norm((opt['option'] ?? '').toString());
        final value = norm((opt['value'] ?? '').toString());
        if (key.isNotEmpty) result[key] = value;
      }
      return result;
    }

    bool isFullSelection() {
      if (!hasOptionSchema) return selectedVariantId != null;
      return product.optionSchema!.every((schema) {
        final name = schema.name.toString();
        return selectedOptions[name] != null &&
            selectedOptions[name]!.trim().isNotEmpty;
      });
    }

    VariantItem? findVariantBySelectedOptions() {
      if (!hasOptionSchema || !isFullSelection() || dialogVariants.isEmpty) {
        return null;
      }

      for (final variant in dialogVariants) {
        final vMap = variantOptionMap(variant);
        bool matched = true;

        for (final schema in product.optionSchema!) {
          final optionName = schema.name.toString();
          final selectedValue = selectedOptions[optionName];

          if (selectedValue == null || selectedValue.trim().isEmpty) {
            matched = false;
            break;
          }

          if (vMap[norm(optionName)] != norm(selectedValue)) {
            matched = false;
            break;
          }
        }

        if (matched) return variant;
      }

      return null;
    }

    bool isOptionValueAvailable(String optionName, String value) {
      if (dialogVariants.isEmpty) return false;

      for (final variant in dialogVariants) {
        if (variant.stock <= 0) continue;

        final vMap = variantOptionMap(variant);
        if (vMap[norm(optionName)] != norm(value)) continue;

        bool matchedOtherSelectedOptions = true;
        for (final entry in selectedOptions.entries) {
          if (norm(entry.key) == norm(optionName)) continue;
          if (entry.value.trim().isEmpty) continue;

          if (vMap[norm(entry.key)] != norm(entry.value)) {
            matchedOtherSelectedOptions = false;
            break;
          }
        }

        if (matchedOtherSelectedOptions) return true;
      }

      return false;
    }

    String dialogImageUrl(VariantItem? variant) {
      if (variant?.imageId != null && product.images.isNotEmpty) {
        final idx = product.images.indexWhere((img) => img.id == variant!.imageId);
        if (idx != -1) return product.images[idx].url;
      }
      if (product.imageUrl.isNotEmpty) return product.imageUrl;
      if (product.images.isNotEmpty) return product.images.first.url;
      return 'https://placehold.co/300x300.png?text=No+Image';
    }

    bool didInitDefault = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          if (!didInitDefault) {
            didInitDefault = true;
            if (dialogVariants.isNotEmpty) {
              final firstInStock = dialogVariants.firstWhere(
                    (v) => v.stock > 0,
                orElse: () => dialogVariants.first,
              );

              if (firstInStock.stock > 0) {
                if (hasOptionSchema) {
                  for (final opt in firstInStock.options) {
                    final optionName = (opt['option'] ?? '').toString();
                    final optionValue = (opt['value'] ?? '').toString();
                    if (optionName.trim().isNotEmpty &&
                        optionValue.trim().isNotEmpty) {
                      selectedOptions[optionName] = optionValue;
                    }
                  }
                }
                selectedVariantId = firstInStock.id;
              }
            }
          }

          VariantItem? selectedVariant;
          if (hasOptionSchema) {
            selectedVariant = findVariantBySelectedOptions();
            selectedVariantId = selectedVariant?.id;
          } else if (selectedVariantId != null) {
            try {
              selectedVariant = dialogVariants
                  .firstWhere((v) => v.id == selectedVariantId);
            } catch (_) {
              selectedVariant = null;
            }
          }

          int maxStock = product.stock;
          if (selectedVariant != null) {
            maxStock = selectedVariant.stock;
          } else if (dialogVariants.isNotEmpty) {
            maxStock = 0;
          }

          if (maxStock > 0 && quantity > maxStock) {
            quantity = maxStock;
          }

          final displayPrice =
          (selectedVariant != null && selectedVariant.price > 0)
              ? _formatPrice(selectedVariant.price)
              : _formatPrice(product.price);

          final selectedText = hasOptionSchema
              ? product.optionSchema!
              .map((schema) {
            final name = schema.name.toString();
            final value = selectedOptions[name];
            if (value == null || value.trim().isEmpty) return null;
            return value;
          })
              .whereType<String>()
              .join(' / ')
              : (selectedVariant?.name ?? '');

          return Dialog(
            backgroundColor: const Color(0xFFFFF7FA),
            insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 720),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF9B8B93)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: dialogImageUrl(selectedVariant),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.white,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white,
                              child: const Icon(Icons.image_not_supported,
                                  color: Color(0xFFC8A6B0), size: 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: _textTitleColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$displayPrice VNĐ',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFF3D3D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedVariant != null
                                    ? 'Kho: ${selectedVariant.stock}'
                                    : (dialogVariants.isNotEmpty
                                    ? 'Kho: ...'
                                    : 'Kho: ${product.stock}'),
                                style: const TextStyle(
                                  color: Color(0xFF9B8B93),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (dialogVariants.isNotEmpty &&
                                  selectedText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Đang chọn: $selectedText',
                                    style: const TextStyle(
                                      color: Color(0xFF7A5A65),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (dialogVariants.isNotEmpty && hasOptionSchema) ...[
                      Text(
                        'Phân loại:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _textTitleColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...product.optionSchema!.map((schema) {
                        final optionName = schema.name.toString();
                        final selectedValue = selectedOptions[optionName];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                optionName,
                                style: TextStyle(
                                  color: _textBodyColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: schema.values.map<Widget>((value) {
                                  final optionValue = value.toString();
                                  final isSelected = selectedValue == optionValue;
                                  final isAvailable = isOptionValueAvailable(
                                    optionName,
                                    optionValue,
                                  );

                                  return InkWell(
                                    onTap: !isAvailable
                                        ? null
                                        : () {
                                      setStateDialog(() {
                                        selectedOptions[optionName] =
                                            optionValue;
                                        final found =
                                        findVariantBySelectedOptions();
                                        selectedVariantId = found?.id;
                                        quantity = 1;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(999),
                                    child: AnimatedContainer(
                                      duration:
                                      const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 11,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFFFF0F5)
                                            : Colors.white,
                                        borderRadius:
                                        BorderRadius.circular(999),
                                        border: Border.all(
                                          color: isSelected
                                              ? _primaryColor
                                              : const Color(0xFFFFC9D8),
                                          width: isSelected ? 1.8 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                          BoxShadow(
                                            color: _primaryColor
                                                .withOpacity(0.12),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                            : null,
                                      ),
                                      child: Text(
                                        optionValue,
                                        style: TextStyle(
                                          color: !isAvailable
                                              ? const Color(0xFFC9BBC1)
                                              : isSelected
                                              ? _primaryColor
                                              : _textTitleColor,
                                          fontWeight: isSelected
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ] else if (dialogVariants.isNotEmpty) ...[
                      Text(
                        'Phân loại:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: _textTitleColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: dialogVariants.map((variant) {
                          final isSelected = selectedVariantId == variant.id;
                          final stock = variant.stock;

                          return ChoiceChip(
                            label: Text('${variant.name} ($stock)'),
                            selected: isSelected,
                            onSelected: stock <= 0
                                ? null
                                : (value) {
                              setStateDialog(() {
                                selectedVariantId =
                                value ? variant.id : null;
                                quantity = 1;
                              });
                            },
                            selectedColor: _primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : _textTitleColor,
                              fontWeight: FontWeight.w800,
                            ),
                            backgroundColor: Colors.white,
                            disabledColor: const Color(0xFFF4EEF1),
                            side: BorderSide(
                              color: isSelected
                                  ? _primaryColor
                                  : const Color(0xFFFFC9D8),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.25),
                          ),
                        ),
                        child: const Text(
                          'Sản phẩm này chưa có biến thể để mua (variant).\nVui lòng chọn sản phẩm khác.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Số lượng:',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: _textTitleColor,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: quantity <= 1
                                  ? null
                                  : () => setStateDialog(() => quantity--),
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Color(0xFF9B8B93)),
                            ),
                            Text(
                              '$quantity',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _textTitleColor,
                              ),
                            ),
                            IconButton(
                              onPressed: (maxStock <= 0 || quantity >= maxStock)
                                  ? null
                                  : () => setStateDialog(() => quantity++),
                              icon: Icon(Icons.add_circle_outline,
                                  color: _primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (dialogVariants.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                Text('Sản phẩm chưa có biến thể để mua'),
                              ),
                            );
                            return;
                          }

                          if (hasOptionSchema && !isFullSelection()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng chọn đầy đủ phân loại'),
                              ),
                            );
                            return;
                          }

                          if (selectedVariantId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng chọn phân loại hợp lệ'),
                              ),
                            );
                            return;
                          }

                          if (maxStock <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sản phẩm đã hết hàng'),
                              ),
                            );
                            return;
                          }

                          try {
                            await Provider.of<CartProvider>(context,
                                listen: false)
                                .addToCart(
                              product.id,
                              variantId: selectedVariantId!,
                              quantity: quantity,
                            );

                            if (!mounted) return;
                            Navigator.pop(ctx);

                            if (isBuyNow) {
                              Navigator.pushNamed(context, '/cart');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã thêm vào giỏ hàng'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            final msg = e
                                .toString()
                                .replaceAll('Exception:', '')
                                .trim();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isBuyNow ? 'MUA NGAY' : 'THÊM VÀO GIỎ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionPicker() {
    if (!_hasOptions) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD6E4)),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
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
                  color: const Color(0xFFFFEEF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.tune_rounded, color: _primaryColor, size: 19),
              ),
              const SizedBox(width: 10),
              Text(
                'Phân loại sản phẩm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _textTitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._currentProduct.optionSchema!.map((opt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt.name,
                    style: TextStyle(
                      color: _textBodyColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: opt.values.map((value) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFFFD6E4)),
                          color: const Color(0xFFFFF7FA),
                        ),
                        child: Text(
                          value.toString(),
                          style: TextStyle(
                            color: _textTitleColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD6E4)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 17, color: _primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phân loại chỉ để xem. Bấm Thêm giỏ hoặc Mua ngay để chọn biến thể và số lượng.',
                    style: TextStyle(
                      color: _textBodyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = _canManageProduct();
    final images = _images;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 64,
        leading: Container(
          margin: const EdgeInsets.only(left: 14, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: _primaryColor, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          if (canManage)
            Container(
              margin: const EdgeInsets.only(right: 10, top: 6, bottom: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProductScreen(product: _currentProduct),
                  ),
                ),
                icon: Icon(Icons.edit_rounded, color: _primaryColor, size: 20),
              ),
            ),
          Consumer<CartProvider>(
            builder: (_, cartProvider, __) => Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 6, bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                    icon: Icon(Icons.shopping_bag_outlined,
                        color: _primaryColor),
                  ),
                ),
                if (cartProvider.totalItems > 0)
                  Positioned(
                    right: 12,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '${cartProvider.totalItems}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======== GALLERY STYLE MOCHI ========
                  Container(
                    height: screenWidth + (images.length > 1 ? 148 : 104),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + 66,
                      16,
                      12,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFEAF1),
                          Color(0xFFFFF5F8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: images.length > 1 ? 76 : 8,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: const Color(0xFFFFD6E4)),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.12),
                                  blurRadius: 26,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: images.length,
                                onPageChanged: (idx) =>
                                    setState(() => _currentImageIndex = idx),
                                itemBuilder: (_, index) {
                                  return CachedNetworkImage(
                                    imageUrl: images[index].url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (_, __) => Container(
                                      color: const Color(0xFFFFF5F8),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: const Color(0xFFFFF5F8),
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 66,
                                          color: _primaryColor.withOpacity(0.35),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 90,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length, (i) {
                                final isActive = _currentImageIndex == i;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: isActive ? 20 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? _primaryColor
                                        : Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: isActive
                                          ? _primaryColor
                                          : const Color(0xFFFFD6E4),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: SizedBox(
                              height: 64,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length,
                                itemBuilder: (_, index) {
                                  final isSelected = _currentImageIndex == index;
                                  return GestureDetector(
                                    onTap: () => _jumpToImage(index),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      width: 62,
                                      height: 62,
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: isSelected
                                              ? _primaryColor
                                              : const Color(0xFFFFD6E4),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: CachedNetworkImage(
                                          imageUrl: images[index].url,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            color: const Color(0xFFFFF5F8),
                                          ),
                                          errorWidget: (_, __, ___) => Container(
                                            color: const Color(0xFFFFF5F8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ======== CONTENT STYLE MOCHI ========
                  Container(
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFFFD6E4)),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.08),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEEF4),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.favorite_rounded,
                                              size: 14, color: _primaryColor),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Mochi cute item',
                                            style: TextStyle(
                                              color: _primaryColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8E7),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star_rounded,
                                              size: 15, color: Color(0xFFFFB84D)),
                                          SizedBox(width: 4),
                                          Text(
                                            'New',
                                            style: TextStyle(
                                              color: Color(0xFF9A6A1B),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _currentProduct.title,
                                  style: TextStyle(
                                    fontSize: 21,
                                    height: 1.25,
                                    fontWeight: FontWeight.w900,
                                    color: _textTitleColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      '₫$_displayPrice',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: _primaryColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF5F8),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: const Color(0xFFFFD6E4),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.inventory_2_outlined,
                                              size: 16, color: _primaryColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Kho: $_displayStock',
                                            style: TextStyle(
                                              color: _textBodyColor,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (_isLoadingVariants)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFFFD6E4)),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Đang tải biến thể...',
                                    style: TextStyle(
                                      color: _textBodyColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_hasOptions) ...[
                            if (_isLoadingVariants) const SizedBox(height: 14),
                            _buildOptionPicker(),
                          ],
                          const SizedBox(height: 16),

                          // description
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFFFD6E4)),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.08),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
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
                                        color: const Color(0xFFFFEEF4),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.notes_rounded,
                                          color: _primaryColor, size: 19),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Mô tả sản phẩm',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: _textTitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _currentProduct.description ?? 'Đang cập nhật...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.55,
                                    color: _textBodyColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: _isDescriptionExpanded ? null : 4,
                                  overflow: _isDescriptionExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                ),
                                if ((_currentProduct.description?.length ?? 0) > 100)
                                  InkWell(
                                    onTap: () => setState(
                                          () => _isDescriptionExpanded =
                                      !_isDescriptionExpanded,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        _isDescriptionExpanded
                                            ? 'Thu gọn'
                                            : 'Xem thêm',
                                        style: TextStyle(
                                          color: _primaryColor,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          if (canManage) ...[
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _toggleProductStatus,
                                    icon: Icon(
                                      _currentProduct.status == 'ACTIVE'
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _currentProduct.status == 'ACTIVE'
                                          ? 'Ẩn sản phẩm'
                                          : 'Hiện sản phẩm',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFB84D),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _confirmDelete,
                                    icon: const Icon(Icons.delete_rounded, size: 16),
                                    label: const Text('Xóa'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF5A79),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!canManage)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border.all(color: const Color(0xFFFFD6E4)),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showProductCartDialog(isBuyNow: false),
                        icon: Icon(Icons.shopping_cart_outlined,
                            size: 18, color: _primaryColor),
                        label: Text(
                          'Thêm giỏ',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _primaryColor, width: 1.4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          backgroundColor: const Color(0xFFFFF5F8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showProductCartDialog(isBuyNow: true),
                        icon: const Icon(Icons.favorite_rounded,
                            size: 18, color: Colors.white),
                        label: const Text(
                          'Mua ngay',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
