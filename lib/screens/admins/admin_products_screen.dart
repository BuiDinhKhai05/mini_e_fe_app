// lib/screens/admins/admin_products_screen.dart
// Màn Admin quản lý sản phẩm.
// Đồng bộ với BE product hiện tại:
// - GET    /products/admin/all
// - PATCH  /products/:id với status ACTIVE hoặc LOCKED dành cho Admin
// - DELETE /products/:id hiện BE đang xóa cứng, không phải xóa mềm

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/product_provider.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? _selectedStatus;

  @override
  void initState() {
    super.initState();

    // Không gọi Provider ngay trong initState để tránh rebuild sai frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().fetchAdminProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (!mounted) return;

    await context.read<ProductProvider>().fetchAdminProducts(
      q: _searchController.text.trim(),
      status: _selectedStatus,
    );
  }

  Future<void> _confirmLock(ProductModel product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Khóa sản phẩm'),
          content: Text(
            'Bạn có chắc muốn khóa sản phẩm "${product.title}" không?\n\n'
                'Sản phẩm bị khóa sẽ không hiển thị public và seller không thể chỉnh sửa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Khóa'),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;

    final provider = context.read<ProductProvider>();
    final success = await provider.lockProductByAdmin(product.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đã khóa sản phẩm' : provider.adminProductError ?? 'Không thể khóa sản phẩm',
        ),
      ),
    );

    await _reload();
  }

  Future<void> _confirmActivate(ProductModel product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mở khóa sản phẩm'),
          content: Text(
            'Bạn có chắc muốn mở khóa sản phẩm "${product.title}" không?\n\n'
                'BE hiện tại cho Admin chuyển sản phẩm từ LOCKED về ACTIVE.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Mở khóa'),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;

    final provider = context.read<ProductProvider>();
    final success = await provider.activateProductByAdmin(product.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đã mở khóa sản phẩm' : provider.adminProductError ?? 'Không thể mở khóa sản phẩm',
        ),
      ),
    );

    await _reload();
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa sản phẩm'),
          content: Text(
            'Bạn có chắc muốn xóa sản phẩm "${product.title}" không?\n\n'
                'Lưu ý: BE product hiện tại đang dùng delete() nên đây là xóa cứng. '
                'Sản phẩm sẽ biến mất khỏi danh sách sau khi xóa thành công.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;

    final provider = context.read<ProductProvider>();
    final success = await provider.deleteProductByAdmin(product.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Đã xóa sản phẩm' : provider.adminProductError ?? 'Không thể xóa sản phẩm',
        ),
      ),
    );

    await _reload();
  }

  void _showProductQuickView(ProductModel product) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImage(product.imageUrl, size: 72),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _infoRow('ID', product.id.toString()),
                _infoRow('Giá', _money(product.price)),
                _infoRow('Tồn kho', product.stock.toString()),
                _infoRow('Đã bán', product.sold.toString()),
                _infoRow('Trạng thái', _statusText(product)),
                _infoRow('Shop ID', product.shopId?.toString() ?? 'Không có'),
                _infoRow('Category ID', product.categoryId?.toString() ?? 'Không có'),
                _infoRow('Slug', product.slug ?? 'Không có'),
                _infoRow('Ngày tạo', product.createdAt ?? 'Không có'),
                _infoRow('Ngày cập nhật', product.updatedAt ?? 'Không có'),
                if (product.deletedAt != null) _infoRow('DeletedAt', product.deletedAt!),
                const SizedBox(height: 16),
                Text(
                  'Mô tả',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description?.isNotEmpty == true
                      ? product.description!
                      : 'Không có mô tả',
                ),
                if (product.images.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Ảnh sản phẩm',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: product.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        return _buildImage(product.images[index].url, size: 86);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _statusColor(ProductModel product) {
    if (product.isDeleted) return Colors.grey;
    if (product.isLocked) return Colors.red;
    if (product.isOutOfStock) return Colors.orange;
    return Colors.green;
  }

  String _statusText(ProductModel product) {
    if (product.isDeleted) return 'Đã xóa';
    return product.statusLabel;
  }

  String _money(num value) {
    return '${value.toStringAsFixed(0)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingAdminProducts) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.adminProductError != null) {
                  return _ErrorView(
                    message: provider.adminProductError!,
                    onRetry: _reload,
                  );
                }

                final products = provider.adminProducts;

                if (products.isEmpty) {
                  return const Center(
                    child: Text('Không có sản phẩm phù hợp'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildProductCard(products[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc slug sản phẩm',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _reload();
                  },
                  icon: const Icon(Icons.clear),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _reload(),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(
                    label: 'Tất cả',
                    selected: _selectedStatus == null,
                    onTap: () {
                      setState(() => _selectedStatus = null);
                      _reload();
                    },
                  ),
                  _filterChip(
                    label: 'Đang bán',
                    selected: _selectedStatus == ProductStatusValue.active,
                    onTap: () {
                      setState(() => _selectedStatus = ProductStatusValue.active);
                      _reload();
                    },
                  ),
                  _filterChip(
                    label: 'Hết hàng',
                    selected: _selectedStatus == ProductStatusValue.outOfStock,
                    onTap: () {
                      setState(() => _selectedStatus = ProductStatusValue.outOfStock);
                      _reload();
                    },
                  ),
                  _filterChip(
                    label: 'Đã khóa',
                    selected: _selectedStatus == ProductStatusValue.locked,
                    onTap: () {
                      setState(() => _selectedStatus = ProductStatusValue.locked);
                      _reload();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final canLock = !product.isDeleted && !product.isLocked;
    final canActivate = !product.isDeleted && product.isLocked;
    final canDelete = !product.isDeleted;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProductQuickView(product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(product.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _money(product.price),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tồn kho: ${product.stock} • Đã bán: ${product.sold}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    _buildStatusBadge(product),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showProductQuickView(product),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('Xem'),
                        ),
                        if (canLock)
                          OutlinedButton.icon(
                            onPressed: () => _confirmLock(product),
                            icon: const Icon(Icons.lock_outline, size: 18),
                            label: const Text('Khóa'),
                          ),
                        if (canActivate)
                          OutlinedButton.icon(
                            onPressed: () => _confirmActivate(product),
                            icon: const Icon(Icons.lock_open_outlined, size: 18),
                            label: const Text('Mở khóa'),
                          ),
                        if (canDelete)
                          OutlinedButton.icon(
                            onPressed: () => _confirmDelete(product),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Xóa'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ProductModel product) {
    final color = _statusColor(product);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _statusText(product),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl, {double size = 84}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: Colors.grey.shade200,
        child: imageUrl == null || imageUrl.trim().isEmpty
            ? const Icon(Icons.image_not_supported_outlined)
            : Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Icon(Icons.broken_image_outlined);
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Lỗi tải sản phẩm:\n$message',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
