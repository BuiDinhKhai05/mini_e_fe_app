import 'package:flutter/material.dart';
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
  Future<void> _reloadSellerProducts({bool showLoading = true}) async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final shopProvider = context.read<ShopProvider>();
    final productProvider = context.read<ProductProvider>();

    if (authProvider.accessToken == null || authProvider.accessToken!.isEmpty) {
      productProvider.clearProductsCache(notify: false);
      shopProvider.clearShopData(notify: false);
      return;
    }

    // Bắt buộc đồng bộ lại shop hiện tại
    await shopProvider.loadMyShop();

    if (!mounted) return;

    // Nếu account này không có shop thì xóa list để tránh dính sản phẩm cũ
    if (shopProvider.shop == null) {
      productProvider.clearProductsCache();
      return;
    }

    // Xóa cache cũ trước khi tải lại
    productProvider.clearProductsCache(notify: false);

    // Tải tất cả sản phẩm seller hiện tại
    await productProvider.fetchAllProductsForSeller(showLoading: showLoading);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _reloadSellerProducts(showLoading: true);
    });
  }

  int _calculateTotalStock(ProductModel product) {
    if (product.variants != null && product.variants!.isNotEmpty) {
      return product.variants!.fold(0, (sum, variant) => sum + variant.stock);
    }
    return product.stock ?? 0;
  }

  Future<void> _toggleStatus(BuildContext context, ProductModel product) async {
    final provider = context.read<ProductProvider>();
    final success = await provider.toggleProductStatus(product.id);

    if (success && mounted) {
      final newStatus = product.status == 'ACTIVE' ? 'DRAFT' : 'ACTIVE';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chuyển trạng thái sản phẩm thành $newStatus'),
          backgroundColor: newStatus == 'ACTIVE' ? Colors.green : Colors.orange,
        ),
      );

      await _reloadSellerProducts(showLoading: false);
    }
  }

  void _confirmDeleteProduct(BuildContext context, int productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm?'),
        content: const Text('Sản phẩm này sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final shopProvider = context.watch<ShopProvider>();

    final currentShop = shopProvider.shop;
    final currentShopId = currentShop?.id;

    // CHỈ HIỂN THỊ SẢN PHẨM THUỘC SHOP HIỆN TẠI
    final products = currentShopId == null
        ? <ProductModel>[]
        : productProvider.products
        .where((p) => p.shopId == currentShopId)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text(
          'Sản phẩm của tôi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _reloadSellerProducts(showLoading: true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              );

              if (!mounted) return;
              await _reloadSellerProducts(showLoading: false);
            },
          ),
        ],
      ),
      body: currentShop == null
          ? const Center(
        child: Text(
          'Tài khoản này chưa có shop',
          style: TextStyle(color: Colors.grey),
        ),
      )
          : productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Shop này chưa có sản phẩm nào',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddProductScreen(),
                  ),
                );

                if (!mounted) return;
                await _reloadSellerProducts(showLoading: false);
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async {
          await _reloadSellerProducts(showLoading: false);
        },
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, index) =>
              _buildProductItem(context, products[index]),
        ),
      ),
      floatingActionButton: currentShop == null
          ? null
          : FloatingActionButton(
        backgroundColor: const Color(0xFF0D6EFD),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );

          if (!mounted) return;
          await _reloadSellerProducts(showLoading: false);
        },
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, ProductModel product) {
    final String? image =
    (product.imageUrl.isNotEmpty) ? product.imageUrl : null;

    final int totalStock = _calculateTotalStock(product);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: product,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[100],
                child: image != null
                    ? Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image, color: Colors.grey),
                )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(0)} đ',
                    style: const TextStyle(
                      color: Color(0xFF0D6EFD),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Kho: $totalStock',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.status ?? 'N/A',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    product.status == 'ACTIVE'
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: product.status == 'ACTIVE'
                        ? Colors.green
                        : Colors.grey,
                  ),
                  tooltip: product.status == 'ACTIVE'
                      ? 'Ẩn sản phẩm'
                      : 'Hiển thị sản phẩm',
                  onPressed: () => _toggleStatus(context, product),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProductScreen(product: product),
                        ),
                      );

                      if (!mounted) return;
                      await _reloadSellerProducts(showLoading: false);
                    } else if (value == 'delete') {
                      _confirmDeleteProduct(context, product.id);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}