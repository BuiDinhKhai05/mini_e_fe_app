import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';

// Providers & Models
import '../../providers/product_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product_model.dart';

// Screens
import '../products/add_product_screen.dart';
import '../products/edit_product_screen.dart';

class SellerProductListScreen extends StatefulWidget {
  const SellerProductListScreen({Key? key}) : super(key: key);

  @override
  State<SellerProductListScreen> createState() => _SellerProductListScreenState();
}

class _SellerProductListScreenState extends State<SellerProductListScreen> {
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

  // =========================
  // Tải sản phẩm của seller hiện tại
  //
  // LƯU Ý QUAN TRỌNG:
  // Backend hiện tại chưa có API riêng trả về cả ACTIVE + DRAFT cho seller.
  // Vì vậy ở FE ta KHÔNG xóa cache và KHÔNG reload lại API public sau khi ẩn sản phẩm,
  // để sản phẩm DRAFT vẫn còn trong trang quản lý trong phiên app hiện tại.
  // =========================
  Future<void> _reloadSellerProducts({
    bool showLoading = true,
    bool forceServer = false,
  }) async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final shopProvider = context.read<ShopProvider>();
    final productProvider = context.read<ProductProvider>();

    if (authProvider.accessToken == null || authProvider.accessToken!.isEmpty) {
      productProvider.clearProductsCache(notify: false);
      shopProvider.clearShopData(notify: false);
      return;
    }

    // Bắt buộc đồng bộ lại shop hiện tại để tránh lấy nhầm sản phẩm shop cũ
    await shopProvider.loadMyShop();

    if (!mounted) return;

    // Nếu account này không có shop thì xóa list để tránh dính sản phẩm cũ
    if (shopProvider.shop == null) {
      productProvider.clearProductsCache();
      return;
    }

    final currentShopId = shopProvider.shop!.id;

    // Nếu trong Provider đã có sản phẩm của shop này rồi thì dùng luôn cache local.
    // Việc này giúp sản phẩm vừa chuyển ACTIVE -> DRAFT không bị mất khỏi trang quản lý.
    final hasLocalProductsForThisShop = productProvider.products.any(
          (p) => p.shopId == currentShopId,
    );

    if (hasLocalProductsForThisShop && !forceServer) {
      if (mounted) setState(() {});
      return;
    }

    // Chỉ gọi server khi chưa có dữ liệu local hoặc người dùng chủ động ép tải lại.
    // Không clear cache trước khi gọi để tránh xóa mất sản phẩm DRAFT đang được giữ local.
    await productProvider.fetchAllProductsForSeller(showLoading: showLoading);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _reloadSellerProducts(showLoading: true);
    });
  }

  // =========================
  // tính tổng tồn kho từ variant hoặc stock chính
  // =========================
  int _calculateTotalStock(ProductModel product) {
    if (product.variants != null && product.variants!.isNotEmpty) {
      return product.variants!.fold(0, (sum, variant) => sum + variant.stock);
    }
    return product.stock ?? 0;
  }

  // =========================
  // bật/tắt trạng thái sản phẩm
  // =========================
  Future<void> _toggleStatus(BuildContext context, ProductModel product) async {
    final provider = context.read<ProductProvider>();
    final oldStatus = product.status.toUpperCase();
    final newStatus = oldStatus == 'ACTIVE' ? 'DRAFT' : 'ACTIVE';

    final success = await provider.toggleProductStatus(product.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chuyển trạng thái sản phẩm thành $newStatus'),
          backgroundColor: newStatus == 'ACTIVE' ? AppColors.success : AppColors.warning,
        ),
      );

      // KHÔNG gọi _reloadSellerProducts() ở đây.
      // ProductProvider.updateProductStatus đã cập nhật sản phẩm trong local list.
      // Nếu reload lại API public /products, sản phẩm DRAFT sẽ bị mất khỏi trang quản lý.
    }
  }

  // =========================
  // xác nhận xóa sản phẩm, chỉ đổi giao diện dialog
  // =========================
  void _confirmDeleteProduct(BuildContext context, int productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Xóa sản phẩm?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Sản phẩm này sẽ bị xóa vĩnh viễn.'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Xóa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<ProductProvider>().deleteProduct(productId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa sản phẩm.')),
        );
        await _reloadSellerProducts(showLoading: false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thất bại. Vui lòng thử lại.')),
        );
      }
    }
  }

  // =========================
  // Điều hướng sang màn hình thêm sản phẩm
  // =========================
  Future<void> _openAddProductScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );

    if (!mounted) return;
    await _reloadSellerProducts(showLoading: false);
  }

  // =========================
  // Điều hướng sang màn hình chỉnh sửa sản phẩm
  // =========================
  Future<void> _openEditProductScreen(ProductModel product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductScreen(product: product),
      ),
    );

    if (!mounted) return;
    await _reloadSellerProducts(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final shopProvider = context.watch<ShopProvider>();

    final currentShop = shopProvider.shop;
    final currentShopId = currentShop?.id;

    // CHỈ HIỂN THỊ SẢN PHẨM THUỘC SHOP HIỆN TẠI
    final products = currentShopId == null
        ? <ProductModel>[]
        : productProvider.products.where((p) => p.shopId == currentShopId).toList();

    return Scaffold(
      backgroundColor: _lighterPink,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        title: const Text(
          'Sản phẩm của tôi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh_rounded, color: _primaryPink),
            onPressed: () async {
              await _reloadSellerProducts(showLoading: true);
            },
          ),
        ],
      ),
      floatingActionButton: currentShop == null
          ? null
          : FloatingActionButton(
        backgroundColor: _primaryPink,
        elevation: 2,
        onPressed: _openAddProductScreen,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header theo format hình mẫu: icon tròn + tiêu đề + nút hành động
            _buildHeaderCard(productCount: products.length),
            const SizedBox(height: 16),

            // Nội dung chính: loading, empty hoặc danh sách sản phẩm
            Expanded(
              child: currentShop == null
                  ? _buildEmptyState(
                icon: Icons.storefront_rounded,
                title: 'Tài khoản này chưa có shop',
                subtitle: 'Bạn cần có shop trước khi đăng sản phẩm.',
              )
                  : productProvider.isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: _primaryPink),
              )
                  : products.isEmpty
                  ? _buildEmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Shop này chưa có sản phẩm nào',
                subtitle: 'Thêm sản phẩm đầu tiên để bắt đầu bán hàng.',
                buttonText: 'Thêm sản phẩm ngay',
                onPressed: _openAddProductScreen,
              )
                  : RefreshIndicator(
                color: _primaryPink,
                onRefresh: () async {
                  await _reloadSellerProducts(showLoading: false);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, index) => _buildProductItem(
                    context,
                    products[index],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Header đầu trang theo style Soft Pink Card UI
  // =========================
  Widget _buildHeaderCard({required int productCount}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Row(
        children: [
          _buildCircleIcon(Icons.inventory_2_rounded, size: 54, iconSize: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý sản phẩm',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đang có $productCount sản phẩm trong shop 💗',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textGrey,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _openAddProductScreen,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Thêm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Card sản phẩm: giữ nguyên chức năng xem chi tiết/sửa/xóa/ẩn hiện
  // =========================
  Widget _buildProductItem(BuildContext context, ProductModel product) {
    final String? image = product.imageUrl.isNotEmpty ? product.imageUrl : null;
    final int totalStock = _calculateTotalStock(product);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: product,
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(radius: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 86,
                height: 86,
                color: _softPink,
                child: image != null
                    ? Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_outlined,
                    color: _primaryPink,
                    size: 30,
                  ),
                )
                    : const Icon(
                  Icons.image_outlined,
                  color: _primaryPink,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Thông tin sản phẩm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: _textDark,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildActionMenu(product),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${product.price.toStringAsFixed(0)} đ',
                    style: const TextStyle(
                      color: _primaryPink,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        icon: Icons.inventory_2_outlined,
                        label: 'Kho: $totalStock',
                      ),
                      _buildStatusBadge(product.status ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Nút ẩn/hiện sản phẩm
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleStatus(context, product),
                      icon: Icon(
                        product.status == 'ACTIVE'
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 16,
                      ),
                      label: Text(
                        product.status == 'ACTIVE'
                            ? 'Ẩn sản phẩm'
                            : 'Hiển thị sản phẩm',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: product.status == 'ACTIVE'
                            ? AppColors.warning
                            : AppColors.success,
                        side: const BorderSide(color: _borderPink),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Menu popup: sửa hoặc xóa sản phẩm
  // =========================
  Widget _buildActionMenu(ProductModel product) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: _textGrey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) async {
        if (value == 'edit') {
          await _openEditProductScreen(product);
        } else if (value == 'delete') {
          _confirmDeleteProduct(context, product.id);
        }
      },
      itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: _primaryPink),
              SizedBox(width: 8),
              Text('Chỉnh sửa'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: _dangerRed),
              SizedBox(width: 8),
              Text('Xóa', style: TextStyle(color: _dangerRed)),
            ],
          ),
        ),
      ],
    );
  }

  // =========================
  // Trạng thái rỗng dùng chung
  // =========================
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(radius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircleIcon(icon, size: 76, iconSize: 38),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textGrey, height: 1.4),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add_rounded),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================
  // Chip thông tin nhỏ: kho, trạng thái...
  // =========================
  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _softPink,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primaryPink),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Badge trạng thái sản phẩm
  // =========================
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'ACTIVE':
        bg = AppColors.success.withOpacity(0.10);
        text = AppColors.success;
        label = 'Đang bán';
        break;
      case 'DRAFT':
        bg = AppColors.warning.withOpacity(0.12);
        text = AppColors.warning;
        label = 'Đang ẩn';
        break;
      default:
        bg = _softPink;
        text = _primaryPink;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: text,
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
