// lib/screens/home_screen.dart
// ================================================================
// GHI CHÚ TỔNG QUAN
// File này là màn hình Trang chủ của app Flutter.
// Chức năng chính được giữ nguyên:
// - Load sản phẩm, giỏ hàng, danh mục từ Provider.
// - Tìm kiếm sản phẩm theo tên.
// - Lọc sản phẩm theo danh mục cha/con.
// - Hiển thị sản phẩm dạng grid.
// - Mở chi tiết sản phẩm.
// - Thêm sản phẩm vào giỏ hàng thông qua popup chọn biến thể.
// Phần được chỉnh chủ yếu là giao diện mobile theo phong cách cute/pink.
// ================================================================

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/category_provider.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

const String _kMochiLogoAsset = 'assets/images/mochi/bunny_bear_original.png';
const String _kHomeHeroAsset = 'assets/images/mochi/basket_chick.png';

// ================================================================
// WIDGET CHÍNH: HomeScreen
// Đây là màn hình trang chủ, dùng StatefulWidget vì màn hình có trạng thái:
// keyword tìm kiếm, danh mục đang chọn, cache tồn kho...
// ================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ================================================================
// STATE CỦA HOME SCREEN
// Toàn bộ biến trạng thái, hàm xử lý logic và hàm dựng giao diện nằm ở đây.
// ================================================================
class _HomeScreenState extends State<HomeScreen> {
  // Cache tồn kho thật của từng sản phẩm.
  // Key là product.id, value là tổng stock lấy từ variant hoặc stock mặc định.
  // Dùng cache để tránh gọi API lấy variant quá nhiều lần khi render sản phẩm.
  final Map<int, int> _stockCache = {};
  // Controller của ô tìm kiếm trên header.
  final TextEditingController _searchCtrl = TextEditingController();

  // ID danh mục cha đang chọn.
  // Khi null nghĩa là chưa chọn danh mục cha nào.
  int? _selectedRootId;
  // ID danh mục đang lọc sản phẩm.
  // Có thể là danh mục cha hoặc danh mục con.
  int? _selectedCategoryId;
  // Từ khóa tìm kiếm sản phẩm.
  String _keyword = '';

  // ================================================================
  // KHỞI TẠO DỮ LIỆU KHI VÀO TRANG
  // Sau khi widget build xong frame đầu tiên, gọi Provider để lấy:
  // - danh sách sản phẩm public
  // - giỏ hàng hiện tại
  // - cây danh mục
  // ================================================================
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchPublicProducts();
      Provider.of<CartProvider>(context, listen: false).fetchCart();
      Provider.of<CategoryProvider>(context, listen: false).fetchTree(); // ✅
    });
  }

  // ================================================================
  // GIẢI PHÓNG CONTROLLER
  // Khi thoát màn hình thì dispose controller để tránh memory leak.
  // ================================================================
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ================================================================
  // LẤY CATEGORY ID TỪ PRODUCT
  // Dùng dynamic để đọc được nhiều kiểu dữ liệu khác nhau từ ProductModel:
  // - categoryId
  // - category_id
  // - category.id
  // - toJson()['categoryId'] hoặc toJson()['category_id']
  // Mục đích: tránh lỗi nếu backend/model đặt tên field khác nhau.
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

      // nếu có toJson()
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
  // TÌM DANH MỤC THEO ID TRONG CÂY DANH MỤC
  // Hàm này duyệt đệ quy qua danh mục cha và các danh mục con.
  // ================================================================
  CategoryModel? _findNodeById(List<CategoryModel> nodes, int id) {
    for (final n in nodes) {
      if (n.id == id) return n;
      final child = _findNodeById(n.children, id);
      if (child != null) return child;
    }
    return null;
  }

  // ================================================================
  // LẤY TOÀN BỘ ID DANH MỤC CON CỦA MỘT DANH MỤC
  // Khi chọn danh mục cha, hàm này lấy cả ID của cha và các con bên trong.
  // Nhờ vậy sản phẩm thuộc danh mục con vẫn hiện khi chọn danh mục cha.
  // ================================================================
  List<int> _collectSubtreeIds(List<CategoryModel> tree, int rootId) {
    final node = _findNodeById(tree, rootId);
    if (node == null) return [rootId];

    final ids = <int>[];
    void dfs(CategoryModel n) {
      ids.add(n.id);
      for (final c in n.children) dfs(c);
    }

    dfs(node);
    return ids;
  }

  // ================================================================
  // LỌC SẢN PHẨM
  // Áp dụng 2 bộ lọc:
  // 1. Lọc theo danh mục đang chọn.
  // 2. Lọc theo keyword tìm kiếm.
  // ================================================================
  List<ProductModel> _applyFilters(List<ProductModel> products, List<CategoryModel> tree) {
    List<int>? allowedCategoryIds;
    if (_selectedCategoryId != null) {
      allowedCategoryIds = _collectSubtreeIds(tree, _selectedCategoryId!);
    }

    return products.where((p) {
      // filter category
      if (allowedCategoryIds != null) {
        final catId = _tryGetCategoryId(p);
        if (catId == null) return false;
        if (!allowedCategoryIds.contains(catId)) return false;
      }

      // filter keyword
      if (_keyword.trim().isNotEmpty) {
        final kw = _keyword.trim().toLowerCase();
        if (!p.title.toLowerCase().contains(kw)) return false;
      }

      return true;
    }).toList();
  }

  // ================================================================
  // LẤY TỒN KHO THẬT CỦA SẢN PHẨM
  // Nếu sản phẩm có variant thì cộng stock của các variant.
  // Nếu không có variant thì dùng product.stock.
  // Kết quả được lưu vào _stockCache để tối ưu hiệu năng.
  // ================================================================
  Future<int> _getRealStock(ProductModel product) async {
    if (_stockCache.containsKey(product.id)) return _stockCache[product.id]!;
    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      final variants = await provider.getVariants(product.id);

      int total = 0;
      if (variants.isNotEmpty) {
        for (var v in variants) {
          total += v.stock;
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

  // ================================================================
  // FORMAT GIÁ TIỀN
  // Chuyển giá từ String/number sang dạng có dấu chấm.
  // Ví dụ: 150000 -> 150.000
  // ================================================================
  String _formatPrice(dynamic price) {
    double value = 0.0;
    if (price is String) value = double.tryParse(price) ?? 0.0;
    else if (price is num) value = price.toDouble();
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  // ================================================================
  // CHỌN TẤT CẢ SẢN PHẨM
  // Reset bộ lọc danh mục về null.
  // ================================================================
  void _selectAll() {
    setState(() {
      _selectedRootId = null;
      _selectedCategoryId = null;
    });
  }

  // ================================================================
  // CHỌN DANH MỤC CHA
  // Khi chọn danh mục cha, sản phẩm sẽ lọc theo danh mục cha đó
  // và toàn bộ danh mục con bên trong.
  // ================================================================
  void _selectRoot(CategoryModel root) {
    setState(() {
      _selectedRootId = root.id;
      _selectedCategoryId = root.id;
    });
  }

  // ================================================================
  // CHỌN DANH MỤC CON
  // Khi chọn danh mục con, chỉ lọc theo danh mục con đó.
  // ================================================================
  void _selectChild(CategoryModel child) {
    setState(() {
      _selectedCategoryId = child.id;
    });
  }

  // ================================================================
  // BOTTOM SHEET CHỌN DANH MỤC
  // Mở bảng chọn danh mục từ dưới màn hình lên.
  // Người dùng có thể chọn 'Tất cả sản phẩm' hoặc từng danh mục cụ thể.
  // ================================================================
  void _openCategoryPicker(CategoryProvider cp) {
    final options = cp.flattenTree();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.72),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3C7D4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEAF1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.widgets_outlined, color: Color(0xFFE84D7A)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Chọn danh mục',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF49313A)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  children: [
                    _categoryPickerTile(
                      title: 'Tất cả sản phẩm',
                      icon: Icons.home_rounded,
                      selected: _selectedCategoryId == null,
                      onTap: () {
                        Navigator.pop(context);
                        _selectAll();
                      },
                    ),
                    ...options.map((c) {
                      final selected = _selectedCategoryId == c.id;
                      return _categoryPickerTile(
                        title: c.name,
                        icon: _categoryIconData(c.name),
                        selected: selected,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() => _selectedCategoryId = c.id);
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // ITEM TRONG BOTTOM SHEET DANH MỤC
  // Dùng để hiển thị từng dòng danh mục trong popup chọn danh mục.
  // ================================================================
  Widget _categoryPickerTile({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFEAF1) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? const Color(0xFFE84D7A) : const Color(0xFFF6DDE5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE84D7A).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE84D7A) : const Color(0xFFFFF3F7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: selected ? Colors.white : const Color(0xFFE84D7A)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFFE84D7A) : const Color(0xFF49313A),
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFFE84D7A))
            : const Icon(Icons.chevron_right_rounded, color: Color(0xFFC8A6B0)),
        onTap: onTap,
      ),
    );
  }

  // ================================================================
  // POPUP THÊM SẢN PHẨM VÀO GIỎ
  // Khi bấm icon giỏ hàng trên card sản phẩm, popup này sẽ mở ra.
  // Bên trong có:
  // - ảnh sản phẩm
  // - tên sản phẩm
  // - giá
  // - tồn kho
  // - danh sách variant/phân loại
  // - chọn số lượng
  // - nút thêm vào giỏ hoặc mua ngay
  // ================================================================
  void _showProductCartDialog(ProductModel product, {bool isBuyNow = false}) async {
    int quantity = 1;

    int? selectedVariantId;
    final Map<String, String> selectedOptions = {};
    List<VariantItem> variants = [];

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    try {
      variants = await productProvider.getVariants(product.id);
    } catch (_) {
      variants = [];
    }

    if (!mounted) return;

    // Kiểm tra sản phẩm có optionSchema hay không.
    // Nếu có, popup sẽ tách phân loại thành từng nhóm riêng:
    // Ví dụ: màu sắc: đỏ/trắng/đen và size: S/XL/XXL.
    // Nếu không có optionSchema, vẫn giữ cách chọn variant dạng chip như cũ.
    final bool hasOptionSchema = product.optionSchema != null && product.optionSchema!.isNotEmpty;

    String norm(String value) => value.trim().toLowerCase();

    // Chuyển options của variant thành Map để dễ so khớp.
    // Ví dụ variant.options = [
    //   {'option': 'màu sắc', 'value': 'đỏ'},
    //   {'option': 'size', 'value': 'S'},
    // ];
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
        return selectedOptions[name] != null && selectedOptions[name]!.trim().isNotEmpty;
      });
    }

    // Tìm đúng variant theo từng option người dùng đã chọn.
    // Không dùng name dạng "đỏ / S" nữa để tránh dồn tất cả biến thể vào một hàng.
    VariantItem? findVariantBySelectedOptions() {
      if (!hasOptionSchema || !isFullSelection() || variants.isEmpty) return null;

      for (final variant in variants) {
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

    // Kiểm tra một giá trị option có còn hàng và còn phù hợp với các option khác đã chọn không.
    // Ví dụ đã chọn màu đỏ, thì size nào không có variant đỏ + size đó hoặc hết hàng sẽ bị làm mờ.
    bool isOptionValueAvailable(String optionName, String value) {
      if (variants.isEmpty) return false;

      for (final variant in variants) {
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

    bool didInitDefault = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          if (!didInitDefault) {
            didInitDefault = true;
            if (variants.isNotEmpty) {
              final firstInStock = variants.firstWhere(
                    (v) => v.stock > 0,
                orElse: () => variants.first,
              );

              if (firstInStock.stock > 0) {
                if (hasOptionSchema) {
                  for (final opt in firstInStock.options) {
                    final optionName = (opt['option'] ?? '').toString();
                    final optionValue = (opt['value'] ?? '').toString();
                    if (optionName.trim().isNotEmpty && optionValue.trim().isNotEmpty) {
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
              selectedVariant = variants.firstWhere((v) => v.id == selectedVariantId);
            } catch (_) {
              selectedVariant = null;
            }
          }

          int maxStock = _stockCache[product.id] ?? (product.stock ?? 0);
          if (selectedVariant != null) {
            maxStock = selectedVariant.stock;
          } else if (variants.isNotEmpty) {
            maxStock = 0;
          }

          final displayPrice = (selectedVariant != null && selectedVariant.price > 0)
              ? _formatPrice(selectedVariant.price)
              : _formatPrice(product.price);

          final selectedText = hasOptionSchema
              ? product.optionSchema!
              .map((schema) {
            final name = schema.name.toString();
            final value = selectedOptions[name];
            if (value == null || value.trim().isEmpty) return null;
            return '$name: $value';
          })
              .whereType<String>()
              .join(', ')
              : (selectedVariant?.name ?? '');

          return Dialog(
            backgroundColor: const Color(0xFFFFF7FA),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 690),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF9B8B93)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: product.imageUrl.isNotEmpty
                                ? product.imageUrl
                                : 'https://via.placeholder.com/150',
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.white,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white,
                              child: const Icon(Icons.image_not_supported, color: Color(0xFFC8A6B0), size: 40),
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
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2D2327),
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

                              if (variants.isNotEmpty)
                                Text(
                                  selectedVariant != null ? 'Kho: ${selectedVariant.stock}' : 'Kho: ...',
                                  style: const TextStyle(color: Color(0xFF9B8B93), fontWeight: FontWeight.w600),
                                )
                              else
                                FutureBuilder<int>(
                                  future: _getRealStock(product),
                                  builder: (context, snapshot) {
                                    final stock = snapshot.data ?? 0;
                                    return Text(
                                      'Kho: $stock',
                                      style: const TextStyle(color: Color(0xFF9B8B93), fontWeight: FontWeight.w600),
                                    );
                                  },
                                ),

                              if (variants.isNotEmpty && selectedText.isNotEmpty)
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

                    if (variants.isNotEmpty && hasOptionSchema) ...[
                      const Text(
                        'Phân loại:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2D2327)),
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
                                style: const TextStyle(
                                  color: Color(0xFF8B6672),
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
                                  final isAvailable = isOptionValueAvailable(optionName, optionValue);

                                  return InkWell(
                                    onTap: !isAvailable
                                        ? null
                                        : () {
                                      setStateDialog(() {
                                        selectedOptions[optionName] = optionValue;
                                        final found = findVariantBySelectedOptions();
                                        selectedVariantId = found?.id;
                                        quantity = 1;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(999),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFFFF0F5) : Colors.white,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFE84D7A)
                                              : const Color(0xFFFFC9D8),
                                          width: isSelected ? 1.8 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                          BoxShadow(
                                            color: const Color(0xFFE84D7A).withOpacity(0.12),
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
                                              ? const Color(0xFFE84D7A)
                                              : const Color(0xFF4B343D),
                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
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
                    ] else if (variants.isNotEmpty) ...[
                      const Text('Phân loại:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: variants.map((v) {
                          final isSelected = selectedVariantId == v.id;
                          final stock = v.stock;

                          return ChoiceChip(
                            label: Text('${v.name} ($stock)'),
                            selected: isSelected,
                            onSelected: stock <= 0
                                ? null
                                : (val) {
                              setStateDialog(() {
                                selectedVariantId = val ? v.id : null;
                                quantity = 1;
                              });
                            },
                            selectedColor: const Color(0xFFE84D7A),
                            labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF4B343D)),
                            backgroundColor: Colors.white,
                            disabledColor: const Color(0xFFF4EEF1),
                            side: BorderSide(color: isSelected ? const Color(0xFFE84D7A) : const Color(0xFFFFC9D8)),
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
                          border: Border.all(color: Colors.orange.withOpacity(0.25)),
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
                        const Text(
                          'Số lượng:',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF2D2327)),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: quantity <= 1 ? null : () => setStateDialog(() => quantity--),
                              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF9B8B93)),
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2D2327)),
                            ),
                            IconButton(
                              onPressed: (maxStock <= 0 || quantity >= maxStock)
                                  ? null
                                  : () => setStateDialog(() => quantity++),
                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE84D7A)),
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
                          if (variants.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sản phẩm chưa có biến thể để mua')),
                            );
                            return;
                          }

                          if (hasOptionSchema && !isFullSelection()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng chọn đầy đủ phân loại')),
                            );
                            return;
                          }

                          if (selectedVariantId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vui lòng chọn phân loại hợp lệ')),
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
                            Navigator.pop(context);

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
                            final msg = e.toString().replaceAll('Exception: ', '');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg), backgroundColor: Colors.red),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE84D7A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          isBuyNow ? 'MUA NGAY' : 'THÊM VÀO GIỎ',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
  // HEADER TRANG HOME
  // Gồm logo/tên shop, nút giỏ hàng, nút tài khoản và ô tìm kiếm.
  // Đây là phần được thiết kế lại theo style mobile cute/pink.
  // ================================================================
  Widget _header(BuildContext context, CategoryProvider cp) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7FA),
        border: Border(bottom: BorderSide(color: Color(0xFFFFE0E9))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFD5E1)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE84D7A).withOpacity(0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        _kMochiLogoAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.favorite_rounded, color: Color(0xFFE84D7A), size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mochi Shop',
                          style: TextStyle(
                            color: Color(0xFFE84D7A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Cute things for you ♡',
                          style: TextStyle(color: Color(0xFF9B7380), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Consumer<CartProvider>(
                    builder: (_, provider, __) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _roundHeaderButton(
                          icon: Icons.shopping_cart_outlined,
                          onTap: () => Navigator.pushNamed(context, '/cart'),
                        ),
                        if ((provider.cartData?.itemsCount ?? 0) > 0)
                          Positioned(
                            right: -3,
                            top: -5,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: Color(0xFFE84D7A), shape: BoxShape.circle),
                              child: Text(
                                '${provider.cartData!.itemsCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _roundHeaderButton(
                    icon: Icons.person_outline_rounded,
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFDCE7)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE84D7A).withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (v) => setState(() => _keyword = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Bạn tìm gì hôm nay?',
                    hintStyle: const TextStyle(color: Color(0xFFC5A6B0), fontWeight: FontWeight.w600),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE84D7A)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Chọn danh mục',
                          icon: const Icon(Icons.tune_rounded, color: Color(0xFFE84D7A)),
                          onPressed: () => _openCategoryPicker(cp),
                        ),
                        if (_searchCtrl.text.isNotEmpty || _keyword.isNotEmpty)
                          IconButton(
                            tooltip: 'Xoá tìm kiếm',
                            icon: const Icon(Icons.clear_rounded, color: Color(0xFF9B7380)),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _keyword = '');
                            },
                          ),
                      ],
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
  // NÚT TRÒN TRÊN HEADER
  // Dùng lại cho icon giỏ hàng, tài khoản...
  // ================================================================
  Widget _roundHeaderButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFD5E1)),
        ),
        child: Icon(icon, color: const Color(0xFF49313A), size: 22),
      ),
    );
  }

  // ================================================================
  // BANNER CHÍNH
  // Khu vực banner lớn phía trên giống giao diện mẫu web,
  // nhưng đã chuyển sang kích thước phù hợp với mobile.
  // ================================================================
  Widget _heroBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        height: 184,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF0F5), Color(0xFFFFF8E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Color(0xFFFFDCE7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE84D7A).withOpacity(0.08),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -18,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.52),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 26,
              bottom: 24,
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.82),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: const Color(0xFFFFD5E1), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Image.asset(
                    _kHomeHeroAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.shopping_basket_outlined, size: 50, color: Color(0xFFE84D7A)),
                  ),
                ),
              ),
            ),
            const Positioned(
              right: 92,
              top: 24,
              child: Icon(Icons.star_rounded, color: Color(0xFFFFC55A), size: 24),
            ),
            const Positioned(
              right: 20,
              top: 38,
              child: Icon(Icons.favorite_rounded, color: Color(0xFFE84D7A), size: 20),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 150, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sưu tập đồ cute',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFFE84D7A), height: 1.08),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cho ngày thêm vui! ✨',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF6F3C4B), height: 1.15),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Thế giới đồ dễ thương dành riêng cho bạn',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF9B7380), fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE84D7A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Mua ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFD5E1)),
                        ),
                        child: const Text('Collection', style: TextStyle(color: Color(0xFF6F3C4B), fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // KHU VỰC ƯU ĐÃI / CAM KẾT DỊCH VỤ
  // Hiển thị các box nhỏ như freeship, đổi trả, thanh toán an toàn, hỗ trợ.
  // Trên mobile dùng GridView 2 cột để không bị quá ngang.
  // ================================================================
  Widget _serviceHighlights() {
    final items = [
      _SupportItem(Icons.local_shipping_outlined, 'Miễn phí ship', 'Đơn từ 300k', const Color(0xFFE84D7A)),
      _SupportItem(Icons.replay_rounded, 'Đổi trả dễ dàng', 'Trong 7 ngày', const Color(0xFF37B26C)),
      _SupportItem(Icons.lock_outline_rounded, 'Thanh toán an toàn', 'Bảo mật tuyệt đối', const Color(0xFF4C9BE8)),
      _SupportItem(Icons.support_agent_rounded, 'Hỗ trợ 24/7', 'Luôn sẵn sàng', const Color(0xFF8E5BE8)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.7,
        ),
        itemBuilder: (_, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFEDF3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color, size: 21),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.2, color: Color(0xFF49313A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10.8, color: Color(0xFF9B7380)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // KHU VỰC DANH MỤC NỔI BẬT
  // Hiển thị danh mục cha dạng card ngang.
  // Nếu danh mục cha có danh mục con thì hiển thị thêm chip bên dưới.
  // ================================================================
  Widget _categoryHighlights(CategoryProvider cp) {
    final roots = cp.tree;

    CategoryModel? selectedRoot;
    if (_selectedRootId != null) {
      selectedRoot = _findNodeById(roots, _selectedRootId!);
    }
    final children = selectedRoot?.children ?? const <CategoryModel>[];

    if (cp.loadingTree) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator(color: Color(0xFFE84D7A))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Danh mục nổi bật 💗', onViewAll: () => _openCategoryPicker(cp)),
        SizedBox(
          height: 104,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: roots.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              if (index == 0) {
                return _categoryCard(
                  label: 'Tất cả',
                  icon: Icons.home_rounded,
                  selected: _selectedCategoryId == null,
                  color: const Color(0xFFFFE8EF),
                  onTap: _selectAll,
                );
              }
              final c = roots[index - 1];
              return _categoryCard(
                label: c.name,
                icon: _categoryIconData(c.name),
                selected: _selectedRootId == c.id,
                color: _categoryColor(index),
                onTap: () => _selectRoot(c),
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
                ...children.map((c) => _CategoryChip(
                  label: c.name,
                  selected: _selectedCategoryId == c.id,
                  onTap: () => _selectChild(c),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ================================================================
  // CARD DANH MỤC
  // Mỗi card gồm icon + tên danh mục.
  // Card được highlight nếu đang được chọn.
  // ================================================================
  Widget _categoryCard({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 118,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? const Color(0xFFE84D7A) : Colors.white, width: selected ? 1.6 : 1),
          boxShadow: selected
              ? [
            BoxShadow(
              color: const Color(0xFFE84D7A).withOpacity(0.14),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.80),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: selected ? const Color(0xFFE84D7A) : const Color(0xFF6F3C4B)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: selected ? const Color(0xFFE84D7A) : const Color(0xFF49313A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // MÀU NỀN CHO CARD DANH MỤC
  // Lấy màu theo index để các danh mục có màu pastel khác nhau.
  // ================================================================
  Color _categoryColor(int index) {
    const colors = [
      Color(0xFFFFE8EF),
      Color(0xFFFFF3CC),
      Color(0xFFE9F8EF),
      Color(0xFFEAF5FF),
      Color(0xFFF1EAFE),
      Color(0xFFFFECE2),
    ];
    return colors[index % colors.length];
  }

  // ================================================================
  // CHỌN ICON THEO TÊN DANH MỤC
  // Dựa vào keyword trong tên danh mục để gán icon phù hợp.
  // Ví dụ: gấu/bông -> icon thú cưng, quà -> icon gift.
  // ================================================================
  IconData _categoryIconData(String name) {
    final n = name.toLowerCase();
    if (n.contains('gấu') || n.contains('bông')) return Icons.pets_rounded;
    if (n.contains('văn') || n.contains('phòng') || n.contains('bút')) return Icons.edit_outlined;
    if (n.contains('phụ') || n.contains('kiện')) return Icons.auto_awesome_rounded;
    if (n.contains('đồ') || n.contains('dùng')) return Icons.coffee_outlined;
    if (n.contains('quà')) return Icons.card_giftcard_rounded;
    if (n.contains('sticker')) return Icons.collections_bookmark_outlined;
    return Icons.widgets_outlined;
  }

  // ================================================================
  // TIÊU ĐỀ MỖI SECTION
  // Dùng chung cho 'Danh mục nổi bật', 'Sản phẩm bán chạy'...
  // Có thể có nút 'Xem tất cả' bên phải.
  // ================================================================
  Widget _sectionHeader(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF49313A)),
            ),
          ),
          if (onViewAll != null)
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(999),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Text('Xem tất cả', style: TextStyle(color: Color(0xFFE84D7A), fontWeight: FontWeight.w900, fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: Color(0xFFE84D7A), size: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // CARD SẢN PHẨM
  // Hiển thị ảnh, nhãn Hot, icon yêu thích, tên, giá, tồn kho,
  // nút chi tiết và nút thêm vào giỏ.
  // Chức năng bấm card vẫn đi đến trang chi tiết sản phẩm.
  // ================================================================
  Widget _productCard(ProductModel product) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/product-detail', arguments: product),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFEDF3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE84D7A).withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl.isNotEmpty ? product.imageUrl : 'https://via.placeholder.com/300',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFFFFF3F7),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE84D7A))),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFFFFF3F7),
                        child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 38, color: Color(0xFFC8A6B0))),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE84D7A),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE84D7A).withOpacity(0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text('Hot', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_border_rounded, color: Color(0xFFE84D7A), size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF49313A), height: 1.15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${_formatPrice(product.price)} VNĐ',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFFE84D7A)),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<int>(
                      future: _getRealStock(product),
                      builder: (_, snapshot) {
                        final stock = snapshot.data ?? 0;
                        return Text(
                          stock > 0 ? 'Còn $stock sản phẩm' : 'Hết hàng',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: stock > 0 ? const Color(0xFF9B7380) : Colors.red,
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
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Chi tiết',
                              style: TextStyle(color: Color(0xFF9B7380), fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showProductCartDialog(product),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 38,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE84D7A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 19),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // BUILD GIAO DIỆN CHÍNH
  // Scaffold gồm:
  // - background màu hồng rất nhạt
  // - body dùng Consumer2 để nghe ProductProvider và CategoryProvider
  // - CustomScrollView để cuộn toàn màn hình
  // - bottomNavigationBar cho 4 tab chính
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAFC),
      body: Consumer2<ProductProvider, CategoryProvider>(
        builder: (context, productProvider, categoryProvider, child) {
          // Danh sách sản phẩm sau khi lọc theo keyword và danh mục.
          final filtered = _applyFilters(productProvider.products, categoryProvider.tree);

          return Column(
            children: [
              _header(context, categoryProvider),
              Expanded(
                child: Builder(
                  builder: (_) {
                    if (productProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFE84D7A)));
                    }

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Banner lớn đầu trang.
                        SliverToBoxAdapter(child: _heroBanner()),
                        // Các box dịch vụ: freeship, đổi trả, thanh toán, hỗ trợ.
                        SliverToBoxAdapter(child: _serviceHighlights()),
                        // Danh mục nổi bật lấy từ CategoryProvider.
                        SliverToBoxAdapter(child: _categoryHighlights(categoryProvider)),
                        if (productProvider.products.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Không tải được sản phẩm.\nVui lòng kiểm tra kết nối mạng.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF9B7380), fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          )
                        else if (filtered.isEmpty)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Không có sản phẩm trong bộ lọc hiện tại.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF9B7380), fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          )
                        else ...[
                            SliverToBoxAdapter(
                              child: _sectionHeader('Sản phẩm bán chạy 🧸', onViewAll: () {}),
                            ),
                            // Grid sản phẩm 2 cột phù hợp với màn hình mobile.
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                      (context, index) => _productCard(filtered[index]),
                                  childCount: filtered.length,
                                ),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 14,
                                  childAspectRatio: 0.66,
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 10)),
                          ],
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      // Thanh điều hướng dưới cùng gồm: Trang chủ, Danh mục, Giỏ hàng, Tôi.
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFFFE0E9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE84D7A).withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 0,
            elevation: 0,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFFE84D7A),
            unselectedItemColor: const Color(0xFFC8A6B0),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            onTap: (index) {
              if (index == 3) Navigator.pushNamed(context, '/personal-info');
              if (index == 2) Navigator.pushNamed(context, '/cart');
              if (index == 1) {
                final cp = Provider.of<CategoryProvider>(context, listen: false);
                _openCategoryPicker(cp);
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Danh mục'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Giỏ hàng'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Tôi'),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// MODEL NHỎ CHO BOX ƯU ĐÃI
// Chỉ dùng trong UI để chứa icon, title, subtitle và màu của từng item.
// ================================================================
class _SupportItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SupportItem(this.icon, this.title, this.subtitle, this.color);
}


// ================================================================
// CHIP DANH MỤC CON
// Hiển thị danh mục con dưới danh mục cha.
// Khi chọn chip thì giao diện đổi màu và sản phẩm được lọc theo danh mục con.
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
            color: selected ? const Color(0xFFE84D7A) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? const Color(0xFFE84D7A) : const Color(0xFFFFD5E1)),
            boxShadow: selected
                ? [
              BoxShadow(
                color: const Color(0xFFE84D7A).withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF9B7380),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
