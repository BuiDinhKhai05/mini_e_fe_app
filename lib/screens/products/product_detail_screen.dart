// lib/screens/products/product_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'package:mini_e_fe_app/models/product_model.dart';
import 'package:mini_e_fe_app/models/shop_model.dart';
import 'package:mini_e_fe_app/providers/product_provider.dart';
import 'package:mini_e_fe_app/providers/auth_provider.dart';
import 'package:mini_e_fe_app/providers/shop_provider.dart';
import 'package:mini_e_fe_app/providers/cart_provider.dart';
import 'package:mini_e_fe_app/providers/recommendation_provider.dart';

import 'edit_product_screen.dart';
import '../shops/shop_detail_screen.dart';
import 'widgets/product_review_section.dart';
import 'widgets/product_cart_action_sheet.dart';

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

  // shop info below review section
  ShopModel? _productShop;
  bool _isLoadingShop = false;
  String? _shopLoadError;
  int? _loadedShopId;

  // gallery
  late final PageController _pageController;
  int _currentImageIndex = 0;

  // variant selection
  final Map<String, String> _selectedOptions = {};
  VariantItem? _selectedVariant;

  bool _isDescriptionExpanded = false;
  bool _isTitleExpanded = false; // Bấm trực tiếp vào tên để xem đầy đủ / thu gọn.
  bool _isOptionPickerExpanded = false; // Thu gọn/mở rộng phân loại khi có quá nhiều giá trị.
  bool _isUpdatingStatus = false;
  bool _hasTrackedViewDetail = false;

  final Color _primaryColor = AppColors.primaryPink;
  final Color _accentColor = AppColors.primaryPink;
  final Color _bgColor = AppColors.background;
  final Color _textTitleColor = AppColors.textDark;
  final Color _textBodyColor = AppColors.textGrey;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _pageController = PageController(initialPage: 0);

    // Gọi các hàm load sau frame đầu tiên để tránh rebuild trong lúc route đang dựng UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadProductDetail();
      _fetchVariants();
      _fetchProductShop();
      _trackViewDetail();

      // Đồng bộ trạng thái yêu thích để nút tim ở card thông tin hiển thị đúng.
      Provider.of<RecommendationProvider>(
        context,
        listen: false,
      ).fetchFavorites(page: 1, limit: 50, silent: true);
    });
  }

  Future<void> _trackViewDetail() async {
    if (_hasTrackedViewDetail) return;
    if (widget.isFromShopManagement) return;

    _hasTrackedViewDetail = true;

    await Provider.of<RecommendationProvider>(
      context,
      listen: false,
    ).trackViewDetail(
      _currentProduct.id,
      source: 'product_detail',
    );
  }

  Future<void> _toggleFavorite() async {
    try {
      await Provider.of<RecommendationProvider>(
        context,
        listen: false,
      ).toggleFavorite(_currentProduct.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật sản phẩm yêu thích'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ======== LOAD DETAIL (để có images[]) ========
  Future<void> _loadProductDetail() async {
    // Public detail chỉ trả ACTIVE / OUT_OF_STOCK.
    // Nếu seller mở sản phẩm LOCKED từ trang quản lý thì giữ dữ liệu local để tránh 404.
    if (widget.isFromShopManagement && _currentProduct.isLocked) {
      return;
    }

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
        _fetchProductShop();
      }
    } catch (_) {}
  }

  // ======== VARIANTS ========
  Future<void> _fetchVariants() async {
    // Public variants chỉ trả ACTIVE / OUT_OF_STOCK.
    // Sản phẩm LOCKED không cho seller chỉnh nên không cần load variants ở màn public detail.
    if (widget.isFromShopManagement && _currentProduct.isLocked) {
      return;
    }

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
  // Format phần số của giá tiền theo kiểu Việt Nam. Đơn vị VND được thêm ở nơi hiển thị để tránh lặp chữ.
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

  bool get _isProductUnavailable =>
      _currentProduct.isLocked ||
          _currentProduct.normalizedStatus == ProductStatusValue.outOfStock ||
          _displayStock <= 0;

  // ======== PERMISSION (seller manage) ========
  bool _canManageProduct() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    if (authProvider.user == null || shopProvider.shop == null) return false;
    final userRole = authProvider.user!.role?.toUpperCase();
    final isSeller = userRole == 'SELLER';
    final isOwnerOfThisShop = shopProvider.shop!.id == _currentProduct.shopId;
    return isSeller && isOwnerOfThisShop && widget.isFromShopManagement;
  }

  Future<void> _toggleProductStatus() async {
    if (_isUpdatingStatus) return;

    final oldStatus = _currentProduct.status.toUpperCase();
    if (oldStatus == ProductStatusValue.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm đã bị admin khóa, không thể đổi trạng thái'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newStatus = oldStatus == ProductStatusValue.active
        ? ProductStatusValue.outOfStock
        : ProductStatusValue.active;

    setState(() => _isUpdatingStatus = true);
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final success = await provider.updateProductStatus(
      productId: _currentProduct.id,
      status: newStatus,
    );

    if (!mounted) return;
    setState(() => _isUpdatingStatus = false);

    if (success) {
      // ACTIVE và OUT_OF_STOCK đều là public status nên có thể cập nhật local ngay.
      setState(() {
        _currentProduct = _currentProduct.copyWith(status: newStatus);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == ProductStatusValue.active ? 'Đã bật bán' : 'Đã chuyển sang hết hàng'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Cập nhật trạng thái thất bại'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: const Text('Sản phẩm sẽ bị xóa khỏi trang quản lý. Hãy chắc chắn trước khi tiếp tục.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
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
              content: Text('Đã xóa sản phẩm khỏi danh sách quản lý'),
              backgroundColor: AppColors.success),
        );
      }
    }
  }

  // ======== CART ACTION ========
  Future<void> _showProductCartDialog({required bool isBuyNow}) {
    return ProductCartActionSheet.show(
      context: context,
      product: _currentProduct,
      isBuyNow: isBuyNow,
      initialVariants: _variants,
      onVariantsLoaded: (loadedVariants) {
        if (!mounted) return;

        setState(() {
          _variants = loadedVariants;
        });
      },
    );
  }

  // ======== SHOP INFO ========
  Future<void> _fetchProductShop({bool force = false}) async {
    final shopId = _currentProduct.shopId;

    if (shopId == null || shopId <= 0) {
      if (!mounted) return;
      setState(() {
        _productShop = null;
        _shopLoadError = 'Sản phẩm chưa có thông tin cửa hàng.';
      });
      return;
    }

    // Tránh gọi lại API nhiều lần khi build/setState.
    if (!force && _loadedShopId == shopId && (_productShop != null || _isLoadingShop)) {
      return;
    }

    _loadedShopId = shopId;

    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    final localShop = shopProvider.shop;
    if (localShop != null && localShop.id == shopId) {
      if (!mounted) return;
      setState(() {
        _productShop = localShop;
        _shopLoadError = null;
        _isLoadingShop = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingShop = true;
        _shopLoadError = null;
      });
    }

    try {
      final shop = await shopProvider.getShopById(shopId);
      if (!mounted) return;
      setState(() {
        _productShop = shop;
        _shopLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productShop = null;
        _shopLoadError = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingShop = false);
      }
    }
  }

  Future<void> _openShopDetail() async {
    if (_productShop != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShopDetailScreen(shop: _productShop!),
        ),
      );
      return;
    }

    await _fetchProductShop(force: true);
    if (!mounted || _productShop == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShopDetailScreen(shop: _productShop!),
      ),
    );
  }

  Widget _buildShopSection() {
    final shopId = _currentProduct.shopId;
    if (shopId == null || shopId <= 0) return const SizedBox.shrink();

    final shop = _productShop;

    // Card thông tin cửa hàng dạng 1 lớp:
    // - Bỏ tiêu đề "Thông tin cửa hàng" và icon ở phía trên.
    // - Bỏ card nhỏ bên trong.
    // - Đưa avatar, tên shop, mô tả, thống kê và nút "Xem shop" trực tiếp vào card lớn.
    if (_isLoadingShop && shop == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderPink),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.055),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Đang tải thông tin cửa hàng...',
              style: TextStyle(
                color: _textBodyColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (shop == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderPink),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.055),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: _primaryColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _shopLoadError == null || _shopLoadError!.isEmpty
                    ? 'Chưa tải được thông tin cửa hàng.'
                    : _shopLoadError!,
                style: TextStyle(
                  color: _textBodyColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: _isLoadingShop ? null : () => _fetchProductShop(force: true),
              child: Text(
                'Thử lại',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _openShopDetail,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderPink),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.055),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 52,
                height: 52,
                color: AppColors.background,
                child: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: shop.logoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryColor,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Icon(
                    Icons.storefront_rounded,
                    color: _primaryColor,
                    size: 26,
                  ),
                )
                    : Icon(
                  Icons.storefront_rounded,
                  color: _primaryColor,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    shop.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _textTitleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.description?.trim().isNotEmpty == true
                        ? shop.description!.trim()
                        : (shop.shopAddress?.trim().isNotEmpty == true
                        ? shop.shopAddress!.trim()
                        : 'Xem thêm sản phẩm từ cửa hàng này'),
                    style: TextStyle(
                      color: _textBodyColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      // Bỏ nhãn số lượng sản phẩm trong shop để card gọn hơn.
                      // Hiển thị đánh giá thật của shop thay cho nhãn "Mới" gắn cứng.
                      _shopMiniStat(
                        Icons.star_rounded,
                        '${shop.stats.ratingAvg.toStringAsFixed(1)}/5',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Text(
                'Xem shop',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopMiniStat(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderPink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: _textTitleColor,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  int get _optionValueCount {
    final schema = _currentProduct.optionSchema;
    if (schema == null || schema.isEmpty) return 0;
    return schema.fold<int>(0, (total, opt) => total + opt.values.length);
  }

  List<String> _visibleOptionValues(OptionSchema opt) {
    final values = opt.values.map((e) => e.toString()).toList();
    if (_isOptionPickerExpanded || _optionValueCount <= 14) return values;

    // Khi thu gọn chỉ hiện vài lựa chọn đầu tiên để card không kéo quá dài.
    // Nếu lựa chọn hiện tại nằm phía sau, vẫn chèn nó vào danh sách để người dùng thấy đang chọn gì.
    final visible = values.take(6).toList();
    final selected = _selectedOptions[opt.name];
    if (selected != null && selected.trim().isNotEmpty && !visible.contains(selected)) {
      visible.add(selected);
    }
    return visible;
  }

  Widget _buildCompactOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? _primaryColor : AppColors.borderPink,
            width: isSelected ? 1.3 : 1,
          ),
          color: isSelected ? AppColors.lightPink : Colors.white,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _primaryColor : _textTitleColor,
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionPicker() {
    if (!_hasOptions) return const SizedBox.shrink();

    final shouldShowToggle = _optionValueCount > 14;
    final selectedSummary = _selectedOptions.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(' • ');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderPink),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: shouldShowToggle
                ? () => setState(
                  () => _isOptionPickerExpanded = !_isOptionPickerExpanded,
            )
                : null,
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.lightPink,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.tune_rounded, color: _primaryColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phân loại sản phẩm',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: _textTitleColor,
                        ),
                      ),
                      if (selectedSummary.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          selectedSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: _textBodyColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (shouldShowToggle)
                  Icon(
                    _isOptionPickerExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _primaryColor,
                    size: 23,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ..._currentProduct.optionSchema!.map((opt) {
            final visibleValues = _visibleOptionValues(opt);
            final hiddenCount = opt.values.length - visibleValues.length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opt.name,
                    style: TextStyle(
                      color: _textBodyColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      ...visibleValues.map((value) {
                        final isSelected = _selectedOptions[opt.name] == value;
                        return _buildCompactOptionChip(
                          label: value,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedOptions[opt.name] = value;
                            });
                            _applyVariantSelection();
                          },
                        );
                      }),
                      if (!_isOptionPickerExpanded && hiddenCount > 0)
                        InkWell(
                          onTap: () => setState(() => _isOptionPickerExpanded = true),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.borderPink),
                            ),
                            child: Text(
                              '+$hiddenCount',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          if (shouldShowToggle)
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () => setState(
                      () => _isOptionPickerExpanded = !_isOptionPickerExpanded,
                ),
                icon: Icon(
                  _isOptionPickerExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                ),
                label: Text(
                  _isOptionPickerExpanded ? 'Thu gọn phân loại' : 'Xem thêm',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
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
    final shouldShowTitleToggle = _currentProduct.title.trim().length > 58;

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
                          AppColors.lightPink,
                          AppColors.background,
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
                              border: Border.all(color: AppColors.borderPink),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.12),
                                  blurRadius: 26,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
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
                                      color: AppColors.background,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.background,
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
                                          : AppColors.borderPink,
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
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected
                                              ? _primaryColor
                                              : AppColors.borderPink,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: CachedNetworkImage(
                                          imageUrl: images[index].url,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                            color: AppColors.background,
                                          ),
                                          errorWidget: (_, __, ___) => Container(
                                            color: AppColors.background,
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
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderPink),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.055),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightPink,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _currentProduct.isLocked
                                                ? Icons.lock_rounded
                                                : (_currentProduct.isOutOfStock
                                                ? Icons.inventory_2_outlined
                                                : Icons.verified_rounded),
                                            size: 13,
                                            color: _primaryColor,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            _currentProduct.statusLabel,
                                            style: TextStyle(
                                              color: _primaryColor,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Consumer<RecommendationProvider>(
                                      builder: (_, recommendationProvider, __) {
                                        final isFavorite = recommendationProvider
                                            .isFavorite(_currentProduct.id);

                                        return InkWell(
                                          onTap: _toggleFavorite,
                                          borderRadius: BorderRadius.circular(999),
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: isFavorite
                                                  ? _primaryColor
                                                  : Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isFavorite
                                                    ? _primaryColor
                                                    : AppColors.borderPink,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _primaryColor
                                                      .withOpacity(0.10),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              isFavorite
                                                  ? Icons.favorite_rounded
                                                  : Icons.favorite_border_rounded,
                                              color: isFavorite
                                                  ? Colors.white
                                                  : _primaryColor,
                                              size: 19,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Bấm trực tiếp vào tên sản phẩm dài để xem đầy đủ.
                                // Bấm lại lần nữa để thu gọn, không cần dòng hướng dẫn riêng.
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: shouldShowTitleToggle
                                      ? () => setState(
                                        () => _isTitleExpanded = !_isTitleExpanded,
                                  )
                                      : null,
                                  child: Text(
                                    _currentProduct.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      height: 1.25,
                                      fontWeight: FontWeight.w900,
                                      color: _textTitleColor,
                                    ),
                                    maxLines: _isTitleExpanded ? null : 2,
                                    overflow: _isTitleExpanded
                                        ? TextOverflow.visible
                                        : TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$_displayPrice VND',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    color: _primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_isLoadingVariants)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderPink),
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
                          const SizedBox(height: 12),

                          // description
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderPink),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryColor.withOpacity(0.055),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: AppColors.lightPink,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.notes_rounded,
                                          color: _primaryColor, size: 17),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Mô tả sản phẩm',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: _textTitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _currentProduct.description ?? 'Đang cập nhật...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: _textBodyColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: _isDescriptionExpanded ? null : 3,
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

                                    child: Align(
                                      alignment: Alignment.center,
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

                          const SizedBox(height: 12),

                          // =======================================================
                          // ĐÁNH GIÁ SẢN PHẨM
                          // =======================================================
                          ProductReviewSection(
                            productId: _currentProduct.id,
                            productTitle: _currentProduct.title,
                          ),

                          const SizedBox(height: 12),

                          // =======================================================
                          // THÔNG TIN SHOP
                          // Bấm vào card shop để chuyển sang màn chi tiết cửa hàng.
                          // =======================================================
                          _buildShopSection(),

                          if (canManage) ...[
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: (_isUpdatingStatus || _currentProduct.isLocked) ? null : _toggleProductStatus,
                                    icon: _isUpdatingStatus
                                        ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : Icon(
                                      _currentProduct.isActive
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _isUpdatingStatus
                                          ? 'Đang lưu...'
                                          : (_currentProduct.isLocked
                                          ? 'Đã bị khóa'
                                          : (_currentProduct.isActive
                                          ? 'Đánh dấu hết hàng'
                                          : 'Bật bán lại')),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.warning,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
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
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
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
                border: Border.all(color: AppColors.borderPink),
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
                        onPressed: _isProductUnavailable
                            ? null
                            : () => _showProductCartDialog(isBuyNow: false),
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
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: AppColors.background,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProductUnavailable
                            ? null
                            : () => _showProductCartDialog(isBuyNow: true),
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
                            borderRadius: BorderRadius.circular(16),
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