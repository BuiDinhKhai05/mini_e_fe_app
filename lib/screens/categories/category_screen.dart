// lib/screens/categories/category_screen.dart
// ================================================================
// MÀN HÌNH CATEGORY / TÌM KIẾM TỔNG HỢP
// Chức năng chính:
// - Hiển thị và lọc sản phẩm theo danh mục cha/con.
// - Tìm kiếm sản phẩm theo tên.
// - Tìm kiếm cửa hàng thật bằng ShopProvider/ShopService.
// - Hiển thị đồng thời kết quả sản phẩm và cửa hàng khi tìm kiếm.
// - Mở chi tiết sản phẩm/shop.
// - Thêm sản phẩm vào giỏ hàng sau khi chọn biến thể.
// ================================================================

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/shop_provider.dart';
import '../shops/shop_detail_screen.dart';

// Các kiểu sắp xếp sản phẩm trong màn danh mục.
enum _ProductSortType {
  relevant,
  newest,
  priceLowToHigh,
  priceHighToLow,
}

class CategoryScreen extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialCategoryName;
  final String? initialKeyword;

  const CategoryScreen({
    Key? key,
    this.initialCategoryId,
    this.initialCategoryName,
    this.initialKeyword,
  }) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<int, int> _stockCache = {};
  Timer? _shopSearchDebounce;

  int? _selectedCategoryId;
  int? _selectedRootId;
  String _keyword = '';
  _ProductSortType _sortType = _ProductSortType.relevant;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _keyword = widget.initialKeyword?.trim() ?? '';
    _searchCtrl.text = _keyword;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);

      // Nếu Home chưa load dữ liệu thì màn này tự load lại để tránh bị trắng màn.
      if (productProvider.products.isEmpty) {
        productProvider.fetchPublicProducts();
      }
      if (categoryProvider.tree.isEmpty) {
        await categoryProvider.fetchTree();
      }

      // Tải danh sách shop riêng để tìm kiếm cửa hàng thật,
      // không phụ thuộc vào dữ liệu shop nằm trong product.
      shopProvider.fetchShops(
        q: _keyword.isEmpty ? null : _keyword,
        // status: 'ACTIVE',
        limit: 20,
      );

      if (!mounted) return;
      if (_selectedCategoryId != null) {
        setState(() {
          _selectedRootId = _findRootIdForCategory(
            categoryProvider.tree,
            _selectedCategoryId!,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _shopSearchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }


  // ================================================================
  // TÌM KIẾM CHUNG
  // - Product: lọc local trên ProductProvider.products.
  // - Shop: gọi ShopProvider.fetchShops(q: keyword) để lấy cửa hàng thật từ BE.
  // ================================================================
  void _onSearchChanged(String value) {
    setState(() => _keyword = value.trim());
    _scheduleShopSearch();
  }

  void _scheduleShopSearch() {
    _shopSearchDebounce?.cancel();
    _shopSearchDebounce = Timer(const Duration(milliseconds: 450), _runShopSearch);
  }

  Future<void> _runShopSearch() async {
    if (!mounted) return;
    await Provider.of<ShopProvider>(context, listen: false).fetchShops(
      q: _keyword.isEmpty ? null : _keyword,
      // status: 'ACTIVE',
      limit: 20,
    );
  }

  void _clearSearchKeyword() {
    _shopSearchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() => _keyword = '');
    _runShopSearch();
  }

  // ================================================================
  // LẤY CATEGORY ID TỪ PRODUCT
  // Dùng dynamic để tương thích nhiều dạng model/backend:
  // - product.categoryId
  // - product.category_id
  // - product.category.id
  // - product.toJson()['categoryId'] hoặc ['category_id']
  // ================================================================
  int? _tryGetCategoryId(ProductModel product) {
    try {
      final d = product as dynamic;

      final v1 = d.categoryId;
      if (v1 is int) return v1;
      if (v1 is num) return v1.toInt();

      final v2 = d.category_id;
      if (v2 is int) return v2;
      if (v2 is num) return v2.toInt();

      final v3 = d.category?.id;
      if (v3 is int) return v3;
      if (v3 is num) return v3.toInt();

      try {
        final m = d.toJson();
        if (m is Map) {
          final v = m['categoryId'] ?? m['category_id'];
          if (v is int) return v;
          if (v is num) return v.toInt();

          if (m['category'] is Map) {
            final vv = (m['category'] as Map)['id'];
            if (vv is int) return vv;
            if (vv is num) return vv.toInt();
          }
        }
      } catch (_) {}

      return null;
    } catch (_) {
      return null;
    }
  }

  // ================================================================
  // FORMAT GIÁ TIỀN
  // Ví dụ: 150000 -> 150.000
  // ================================================================
  String _formatPrice(dynamic price) {
    double value = 0.0;
    if (price is String) {
      value = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      value = price.toDouble();
    }

    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  double _parsePrice(dynamic price) {
    if (price is num) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  // ================================================================
  // CHUẨN HÓA TỪ KHÓA TÌM KIẾM
  // Giúp tìm được cả khi người dùng gõ không dấu.
  // Ví dụ: "cua hang mochi" vẫn có thể khớp với "Cửa hàng Mochi".
  // ================================================================
  String _normalizeText(String value) {
    var text = value.toLowerCase().trim();

    const from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    for (var i = 0; i < from.length; i++) {
      text = text.replaceAll(from[i], to[i]);
    }

    return text;
  }

  // ================================================================
  // LẤY TÊN SHOP TỪ PRODUCT NẾU BACKEND CÓ TRẢ VỀ
  // Hỗ trợ nhiều dạng response khác nhau:
  // - product.shopName
  // - product.shop_name
  // - product.storeName
  // - product.sellerName
  // - product.shop.name
  // - product.toJson()['shopName'] hoặc product.toJson()['shop']['name']
  //
  // Nếu BE không trả shop trong response sản phẩm thì hàm này trả ''.
  // Khi đó màn category chỉ tìm được theo tên sản phẩm.
  // ================================================================
  String _tryGetShopName(ProductModel product) {
    final d = product as dynamic;

    try {
      final v = d.shopName;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}

    try {
      final v = d.shop_name;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}

    try {
      final v = d.storeName;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}

    try {
      final v = d.sellerName;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}

    try {
      final v = d.shop?.name;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}

    try {
      final m = d.toJson();
      if (m is Map) {
        final direct = m['shopName'] ?? m['shop_name'] ?? m['storeName'] ?? m['sellerName'];
        if (direct is String && direct.trim().isNotEmpty) return direct.trim();

        final shop = m['shop'] ?? m['seller'] ?? m['store'];
        if (shop is Map) {
          final nested = shop['name'] ?? shop['shopName'] ?? shop['storeName'];
          if (nested is String && nested.trim().isNotEmpty) return nested.trim();
        }
      }
    } catch (_) {}

    return '';
  }

  // ================================================================
  // TÌM NODE CATEGORY THEO ID
  // ================================================================
  CategoryModel? _findNodeById(List<CategoryModel> nodes, int id) {
    for (final node in nodes) {
      if (node.id == id) return node;
      final found = _findNodeById(node.children, id);
      if (found != null) return found;
    }
    return null;
  }

  // ================================================================
  // TÌM ROOT CATEGORY CỦA MỘT CATEGORY BẤT KỲ
  // Nếu category đang chọn là con, hàm trả về id của danh mục cha cấp 1.
  // ================================================================
  int? _findRootIdForCategory(List<CategoryModel> roots, int categoryId) {
    bool contains(CategoryModel node, int id) {
      if (node.id == id) return true;
      for (final child in node.children) {
        if (contains(child, id)) return true;
      }
      return false;
    }

    for (final root in roots) {
      if (contains(root, categoryId)) return root.id;
    }
    return null;
  }

  // ================================================================
  // LẤY TẤT CẢ ID TRONG CÂY CON CỦA CATEGORY ĐANG CHỌN
  // Khi chọn category cha, sản phẩm thuộc category con cũng được hiển thị.
  // ================================================================
  List<int> _collectSubtreeIds(List<CategoryModel> tree, int rootId) {
    final node = _findNodeById(tree, rootId);
    if (node == null) return [rootId];

    final ids = <int>[];
    void dfs(CategoryModel current) {
      ids.add(current.id);
      for (final child in current.children) {
        dfs(child);
      }
    }

    dfs(node);
    return ids;
  }

  // ================================================================
  // LỌC + SẮP XẾP SẢN PHẨM
  // ================================================================
  List<ProductModel> _getFilteredProducts({
    required List<ProductModel> products,
    required List<CategoryModel> tree,
  }) {
    List<int>? allowedCategoryIds;
    if (_selectedCategoryId != null) {
      allowedCategoryIds = _collectSubtreeIds(tree, _selectedCategoryId!);
    }

    final kw = _keyword.trim().toLowerCase();
    final filtered = products.where((product) {
      if (allowedCategoryIds != null) {
        final categoryId = _tryGetCategoryId(product);
        if (categoryId == null || !allowedCategoryIds.contains(categoryId)) {
          return false;
        }
      }

      if (kw.isNotEmpty) {
        final normalizedKeyword = _normalizeText(kw);
        final productTitle = _normalizeText(product.title);
        final shopName = _normalizeText(_tryGetShopName(product));

        final matchedProduct = productTitle.contains(normalizedKeyword);
        final matchedShop = shopName.isNotEmpty && shopName.contains(normalizedKeyword);

        if (!matchedProduct && !matchedShop) {
          return false;
        }
      }

      return true;
    }).toList();

    switch (_sortType) {
      case _ProductSortType.priceLowToHigh:
        filtered.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
        break;
      case _ProductSortType.priceHighToLow:
        filtered.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
        break;
      case _ProductSortType.newest:
      // Không chắc ProductModel có createdAt hay không, nên dùng id lớn hơn làm fallback.
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case _ProductSortType.relevant:
        break;
    }

    return filtered;
  }

  // ================================================================
  // LẤY TỒN KHO THẬT CỦA SẢN PHẨM
  // Nếu sản phẩm có variant thì cộng stock của variant.
  // Nếu không có variant thì dùng product.stock.
  // ================================================================
  Future<int> _getRealStock(ProductModel product) async {
    if (_stockCache.containsKey(product.id)) return _stockCache[product.id]!;

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final variants = await provider.getVariants(product.id);

      int total = 0;
      if (variants.isNotEmpty) {
        for (final variant in variants) {
          total += variant.stock;
        }
      } else {
        total = product.stock ?? 0;
      }

      _stockCache[product.id] = total;
      return total;
    } catch (_) {
      final fallback = product.stock ?? 0;
      _stockCache[product.id] = fallback;
      return fallback;
    }
  }

  void _selectAllCategories() {
    setState(() {
      _selectedRootId = null;
      _selectedCategoryId = null;
    });
  }

  void _selectRootCategory(CategoryModel root) {
    setState(() {
      _selectedRootId = root.id;
      _selectedCategoryId = root.id;
    });
  }

  void _selectChildCategory(CategoryModel child) {
    setState(() {
      _selectedCategoryId = child.id;
    });
  }

  void _clearFilters() {
    _shopSearchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() {
      _keyword = '';
      _selectedRootId = null;
      _selectedCategoryId = null;
      _sortType = _ProductSortType.relevant;
    });
    _runShopSearch();
  }

  // ================================================================
  // POPUP CHỌN BIẾN THỂ VÀ THÊM VÀO GIỎ
  // Bản gọn để dùng trong màn category, vẫn gọi đúng CartProvider.addToCart().
  // ================================================================
  void _showProductCartDialog(ProductModel product) async {
    int quantity = 1;
    int? selectedVariantId;
    List<VariantItem> variants = [];

    try {
      variants = await Provider.of<ProductProvider>(context, listen: false)
          .getVariants(product.id);
    } catch (_) {
      variants = [];
    }

    if (!mounted) return;

    if (variants.isNotEmpty) {
      final firstInStock = variants.firstWhere(
            (variant) => variant.stock > 0,
        orElse: () => variants.first,
      );
      if (firstInStock.stock > 0) {
        selectedVariantId = firstInStock.id;
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          VariantItem? selectedVariant;
          if (selectedVariantId != null) {
            try {
              selectedVariant = variants.firstWhere(
                    (variant) => variant.id == selectedVariantId,
              );
            } catch (_) {
              selectedVariant = null;
            }
          }

          final maxStock = selectedVariant?.stock ?? 0;
          final displayPrice = selectedVariant != null && selectedVariant.price > 0
              ? _formatPrice(selectedVariant.price)
              : _formatPrice(product.price);

          return Dialog(
            backgroundColor: AppColors.background,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Chọn phân loại',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textGrey),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl.isNotEmpty
                                ? product.imageUrl
                                : 'https://via.placeholder.com/150',
                            width: 94,
                            height: 94,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.white,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.textLight,
                              ),
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$displayPrice VNĐ',
                                style: const TextStyle(
                                  color: AppColors.darkPink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selectedVariant == null ? 'Kho: ...' : 'Kho: ${selectedVariant.stock}',
                                style: const TextStyle(
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Phân loại',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (variants.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderPink),
                        ),
                        child: const Text(
                          'Sản phẩm chưa có biến thể để mua.',
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: variants.map((variant) {
                          final selected = selectedVariantId == variant.id;
                          final disabled = variant.stock <= 0;

                          return ChoiceChip(
                            label: Text('${variant.name} (${variant.stock})'),
                            selected: selected,
                            onSelected: disabled
                                ? null
                                : (value) {
                              setStateDialog(() {
                                selectedVariantId = value ? variant.id : null;
                                quantity = 1;
                              });
                            },
                            selectedColor: AppColors.darkPink,
                            backgroundColor: Colors.white,
                            disabledColor: AppColors.borderGrey,
                            labelStyle: TextStyle(
                              color: disabled
                                  ? AppColors.textLight
                                  : selected
                                  ? Colors.white
                                  : AppColors.textDark,
                              fontWeight: FontWeight.w800,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? AppColors.darkPink
                                  : AppColors.borderPink,
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Số lượng',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: quantity <= 1
                                  ? null
                                  : () => setStateDialog(() => quantity--),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: AppColors.textGrey,
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            IconButton(
                              onPressed: maxStock <= 0 || quantity >= maxStock
                                  ? null
                                  : () => setStateDialog(() => quantity++),
                              icon: const Icon(Icons.add_circle_outline),
                              color: AppColors.darkPink,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (variants.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sản phẩm chưa có biến thể để mua')),
                            );
                            return;
                          }

                          if (selectedVariantId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng chọn phân loại')),
                            );
                            return;
                          }

                          if (maxStock <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sản phẩm đã hết hàng')),
                            );
                            return;
                          }

                          try {
                            await Provider.of<CartProvider>(context, listen: false).addToCart(
                              product.id,
                              variantId: selectedVariantId!,
                              quantity: quantity,
                            );

                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã thêm vào giỏ hàng'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            final msg = e.toString().replaceAll('Exception: ', '');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg), backgroundColor: AppColors.error),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkPink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'THÊM VÀO GIỎ',
                          style: TextStyle(fontWeight: FontWeight.w900),
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

  // ================================================================
  // HEADER MÀN CATEGORY
  // ================================================================
  Widget _header(CategoryModel? selectedCategory, int productCount, int shopCount) {
    final title = selectedCategory?.name ?? widget.initialCategoryName ?? 'Tất cả danh mục';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.lightPink)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderPink),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tìm thấy $productCount sản phẩm • $shopCount cửa hàng',
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderPink),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: AppColors.darkPink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderPink),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkPink.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Tìm sản phẩm hoặc cửa hàng...',
                    hintStyle: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.darkPink),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    suffixIcon: _keyword.isEmpty
                        ? null
                        : IconButton(
                      tooltip: 'Xóa tìm kiếm',
                      icon: const Icon(Icons.clear_rounded, color: AppColors.textGrey),
                      onPressed: _clearSearchKeyword,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // DANH MỤC CHA + DANH MỤC CON
  // ================================================================
  Widget _categoryFilterBar(CategoryProvider categoryProvider) {
    final roots = categoryProvider.tree;
    final effectiveRootId = _selectedRootId ??
        (_selectedCategoryId == null
            ? null
            : _findRootIdForCategory(roots, _selectedCategoryId!));
    final selectedRoot = effectiveRootId == null ? null : _findNodeById(roots, effectiveRootId);
    final children = selectedRoot?.children ?? const <CategoryModel>[];

    if (categoryProvider.loadingTree) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.darkPink),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            'Lọc theo danh mục',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: roots.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CategoryFilterCard(
                  label: 'Tất cả',
                  icon: Icons.home_rounded,
                  selected: _selectedCategoryId == null,
                  color: AppColors.lightPink,
                  onTap: _selectAllCategories,
                );
              }

              final root = roots[index - 1];
              return _CategoryFilterCard(
                label: root.name,
                icon: _categoryIconData(root.name),
                selected: effectiveRootId == root.id,
                color: _categoryColor(index),
                onTap: () => _selectRootCategory(root),
              );
            },
          ),
        ),
        if (children.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _CategoryChip(
                  label: 'Tất cả ${selectedRoot?.name ?? ''}'.trim(),
                  selected: _selectedCategoryId == effectiveRootId,
                  onTap: selectedRoot == null
                      ? () {}
                      : () => _selectRootCategory(selectedRoot!),
                ),
                ...children.map(
                      (child) => _CategoryChip(
                    label: child.name,
                    selected: _selectedCategoryId == child.id,
                    onTap: () => _selectChildCategory(child),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ================================================================
  // THANH SẮP XẾP VÀ THÔNG TIN BỘ LỌC
  // ================================================================
  Widget _sortAndInfoBar(CategoryModel? selectedCategory, int resultCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _keyword.isEmpty && selectedCategory == null
                      ? 'Tất cả sản phẩm'
                      : 'Kết quả lọc',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_keyword.isNotEmpty || selectedCategory != null || _sortType != _ProductSortType.relevant)
                InkWell(
                  onTap: _clearFilters,
                  borderRadius: BorderRadius.circular(999),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      'Xóa lọc',
                      style: TextStyle(
                        color: AppColors.darkPink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SortChip(
                label: 'Phù hợp',
                selected: _sortType == _ProductSortType.relevant,
                onTap: () => setState(() => _sortType = _ProductSortType.relevant),
              ),
              _SortChip(
                label: 'Mới nhất',
                selected: _sortType == _ProductSortType.newest,
                onTap: () => setState(() => _sortType = _ProductSortType.newest),
              ),
              _SortChip(
                label: 'Giá thấp',
                selected: _sortType == _ProductSortType.priceLowToHigh,
                onTap: () => setState(() => _sortType = _ProductSortType.priceLowToHigh),
              ),
              _SortChip(
                label: 'Giá cao',
                selected: _sortType == _ProductSortType.priceHighToLow,
                onTap: () => setState(() => _sortType = _ProductSortType.priceHighToLow),
              ),
            ],
          ),
          if (_keyword.isNotEmpty || selectedCategory != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (selectedCategory != null) 'Danh mục: ${selectedCategory.name}',
                if (_keyword.isNotEmpty) 'Từ khóa: "$_keyword"',
                '$resultCount sản phẩm',
              ].join(' • '),
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // CARD SẢN PHẨM
  // ================================================================
  Widget _productCard(ProductModel product) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.softPink),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkPink.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl.isNotEmpty
                          ? product.imageUrl
                          : 'https://via.placeholder.com/300',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => Container(
                        color: AppColors.softPink,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.darkPink,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.softPink,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 38,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.darkPink,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Cute',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        height: 1.15,
                      ),
                    ),
                    Builder(
                      builder: (_) {
                        final shopName = _tryGetShopName(product);
                        if (shopName.isEmpty) return const SizedBox(height: 3);

                        return Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                size: 13,
                                color: AppColors.textGrey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  shopName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatPrice(product.price)} VNĐ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkPink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FutureBuilder<int>(
                      future: _getRealStock(product),
                      builder: (_, snapshot) {
                        final stock = snapshot.data ?? 0;
                        return Text(
                          stock > 0 ? 'Còn $stock sản phẩm' : 'Hết hàng',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: stock > 0 ? AppColors.textGrey : AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.softPink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Chi tiết',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showProductCartDialog(product),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 36,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.darkPink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(int index) {
    const colors = [
      AppColors.lightPink,
      Color(0xFFFFF3CC),
      Color(0xFFE9F8EF),
      Color(0xFFEAF5FF),
      Color(0xFFF1EAFE),
      Color(0xFFFFECE2),
    ];
    return colors[index % colors.length];
  }

  IconData _categoryIconData(String name) {
    final n = name.toLowerCase();
    if (n.contains('gấu') || n.contains('bông')) return Icons.pets_rounded;
    if (n.contains('văn') || n.contains('phòng') || n.contains('bút')) return Icons.edit_outlined;
    if (n.contains('phụ') || n.contains('kiện')) return Icons.auto_awesome_rounded;
    if (n.contains('đồ') || n.contains('dùng')) return Icons.coffee_outlined;
    if (n.contains('quà')) return Icons.card_giftcard_rounded;
    if (n.contains('sticker')) return Icons.collections_bookmark_outlined;
    if (n.contains('áo')) return Icons.checkroom_rounded;
    if (n.contains('giày') || n.contains('dép')) return Icons.shopping_bag_outlined;
    return Icons.widgets_outlined;
  }


  // ================================================================
  // KẾT QUẢ TỔNG HỢP: SẢN PHẨM + CỬA HÀNG
  // Không còn tab chọn riêng. Khi nhập từ khóa, màn hình hiển thị
  // đồng thời sản phẩm phù hợp và cửa hàng phù hợp.
  // ================================================================
  Widget _buildCombinedResults({
    required ProductProvider productProvider,
    required CategoryProvider categoryProvider,
    required ShopProvider shopProvider,
    required List<ProductModel> filteredProducts,
    required CategoryModel? selectedCategory,
  }) {
    return RefreshIndicator(
      color: AppColors.darkPink,
      onRefresh: () async {
        _stockCache.clear();
        await Future.wait([
          Provider.of<ProductProvider>(context, listen: false).fetchPublicProducts(),
          Provider.of<CategoryProvider>(context, listen: false).fetchTree(),
          _runShopSearch(),
        ]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _categoryFilterBar(categoryProvider)),

          // Đưa cửa hàng lên trước sản phẩm. Phần cửa hàng chỉ hiển thị
          // dạng một hàng ngang giống danh mục nổi bật, không hiển thị
          // toàn bộ dạng danh sách dọc như trước.
          _shopHorizontalSection(shopProvider),

          SliverToBoxAdapter(
            child: _sortAndInfoBar(selectedCategory, filteredProducts.length),
          ),

          if (productProvider.isLoading && productProvider.products.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 42),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.darkPink),
                ),
              ),
            )
          else if (productProvider.products.isEmpty)
            SliverToBoxAdapter(
              child: _buildEmptyResult(
                icon: Icons.inventory_2_outlined,
                title: 'Không tải được sản phẩm',
                message: 'Vui lòng kiểm tra kết nối mạng rồi thử lại.',
                actionText: 'Thử lại',
                onAction: () async {
                  _stockCache.clear();
                  await Provider.of<ProductProvider>(context, listen: false)
                      .fetchPublicProducts();
                },
              ),
            )
          else if (filteredProducts.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyResult(
                  icon: Icons.search_off_rounded,
                  title: 'Không có sản phẩm phù hợp',
                  message: 'Thử đổi từ khóa hoặc chọn danh mục khác nhé.',
                  actionText: 'Xóa bộ lọc',
                  onAction: _clearFilters,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _productCard(filteredProducts[index]),
                    childCount: filteredProducts.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    // Dùng chiều cao cố định để tránh RenderFlex overflow
                    // trên emulator/màn hình nhỏ.
                    mainAxisExtent: 300,
                  ),
                ),
              ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _shopHorizontalSection(ShopProvider shopProvider) {
    final shops = shopProvider.shops;
    final shouldShowSection = _keyword.trim().isNotEmpty || shops.isNotEmpty;

    if (!shouldShowSection) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 0, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cửa hàng phù hợp',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${shops.length} cửa hàng',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 132,
              child: _buildShopHorizontalContent(shopProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopHorizontalContent(ShopProvider shopProvider) {
    if (shopProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.darkPink),
      );
    }

    if (shopProvider.error != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: _smallHorizontalMessage(
          icon: Icons.storefront_outlined,
          title: 'Chưa tải được cửa hàng',
          actionText: 'Thử lại',
          onAction: _runShopSearch,
        ),
      );
    }

    final shops = shopProvider.shops;
    if (shops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: _smallHorizontalMessage(
          icon: Icons.search_off_rounded,
          title: 'Không tìm thấy cửa hàng',
          actionText: _keyword.isEmpty ? null : 'Xóa tìm kiếm',
          onAction: _keyword.isEmpty ? null : _clearSearchKeyword,
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: shops.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final isLast = index == shops.length - 1;
        return Padding(
          padding: EdgeInsets.only(right: isLast ? 16 : 0),
          child: _shopHorizontalCard(shops[index], index),
        );
      },
    );
  }

  Widget _smallHorizontalMessage({
    required IconData icon,
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.softPink),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.lightPink,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.darkPink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionText),
            ),
        ],
      ),
    );
  }

  Widget _shopHorizontalCard(ShopModel shop, int index) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 126,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _categoryColor(index + 2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.softPink.withOpacity(0.72)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _shopLogoSmall(shop),
                Positioned(
                  right: -5,
                  bottom: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.softPink),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 13,
                      color: AppColors.darkPink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              shop.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    shop.stats.ratingAvg.toStringAsFixed(1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopLogoSmall(ShopModel shop) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        image: shop.logoUrl != null && shop.logoUrl!.trim().isNotEmpty
            ? DecorationImage(image: NetworkImage(shop.logoUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: shop.logoUrl == null || shop.logoUrl!.trim().isEmpty
          ? const Icon(Icons.storefront_rounded, color: AppColors.darkPink, size: 28)
          : null,
    );
  }

  Widget _shopCard(ShopModel shop) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.softPink),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkPink.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SizedBox(
                    height: 118,
                    width: double.infinity,
                    child: shop.coverUrl != null
                        ? Image.network(
                      shop.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _shopCoverPlaceholder(),
                    )
                        : _shopCoverPlaceholder(),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _shopStatusBadge(shop.status),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shopLogo(shop),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.star_rounded,
                              label: '${shop.stats.ratingAvg.toStringAsFixed(1)} | ${shop.stats.reviewCount} đánh giá',
                              iconColor: AppColors.warning,
                            ),
                            if (shop.phone != null && shop.phone!.trim().isNotEmpty)
                              _InfoChip(
                                icon: Icons.phone_outlined,
                                label: shop.phone!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.darkPink),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopCoverPlaceholder() {
    return Container(
      color: AppColors.lightPink,
      child: const Center(
        child: Icon(Icons.storefront_rounded, color: AppColors.darkPink, size: 42),
      ),
    );
  }

  Widget _shopLogo(ShopModel shop) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.lightPink,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkPink.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        image: shop.logoUrl != null
            ? DecorationImage(image: NetworkImage(shop.logoUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: shop.logoUrl == null
          ? const Icon(Icons.storefront_rounded, color: AppColors.darkPink, size: 28)
          : null,
    );
  }

  Widget _shopStatusBadge(String status) {
    final label = status == 'ACTIVE'
        ? 'Hoạt động'
        : status == 'PENDING'
        ? 'Chờ duyệt'
        : status == 'SUSPENDED'
        ? 'Bị khóa'
        : status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderPink),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.darkPink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildEmptyResult({
    required IconData icon,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: const BoxDecoration(
                color: AppColors.lightPink,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.darkPink, size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkPink,
                  side: const BorderSide(color: AppColors.darkPink),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(actionText, style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer3<ProductProvider, CategoryProvider, ShopProvider>(
        builder: (context, productProvider, categoryProvider, shopProvider, child) {
          final filteredProducts = _getFilteredProducts(
            products: productProvider.products,
            tree: categoryProvider.tree,
          );
          final selectedCategory = _selectedCategoryId == null
              ? null
              : _findNodeById(categoryProvider.tree, _selectedCategoryId!);

          return Column(
            children: [
              _header(selectedCategory, filteredProducts.length, shopProvider.shops.length),
              Expanded(
                child: _buildCombinedResults(
                  productProvider: productProvider,
                  categoryProvider: categoryProvider,
                  shopProvider: shopProvider,
                  filteredProducts: filteredProducts,
                  selectedCategory: selectedCategory,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ================================================================
// CHIP THÔNG TIN NHỎ TRONG CARD SHOP
// ================================================================
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.iconColor = AppColors.darkPink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.softPink,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderPink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// CARD CATEGORY TRONG THANH LỌC
// ================================================================
class _CategoryFilterCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryFilterCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 108,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.darkPink : Colors.white,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: AppColors.darkPink.withOpacity(0.14),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.82),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.darkPink : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppColors.darkPink : AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// CHIP CATEGORY CON
// ================================================================
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.darkPink : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.darkPink : AppColors.borderPink,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textGrey,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// CHIP SẮP XẾP
// ================================================================
class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkPink : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.darkPink : AppColors.borderPink,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textGrey,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
