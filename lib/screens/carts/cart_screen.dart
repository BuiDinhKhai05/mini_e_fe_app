import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/cart_model.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../products/product_detail_screen.dart';

// -----------------------------------------------------------------------------
// Bảng màu dùng chung theo format Soft Pink Card UI của phần product.
// -----------------------------------------------------------------------------
class AppColors {
  static const Color background = Color(0xFFFFF5F8);
  static const Color primaryPink = Color(0xFFE84B82);
  static const Color accentPink = Color(0xFFFF6FA5);
  static const Color softPink = Color(0xFFFFEEF4);
  static const Color lighterPink = Color(0xFFFFF8FB);
  static const Color borderPink = Color(0xFFFFD6E3);
  static const Color textDark = Color(0xFF4A2C36);
  static const Color textGrey = Color(0xFF8A6F78);
  static const Color dangerRed = Color(0xFFFF4D5E);
  static const Color successGreen = Color(0xFF20B26B);
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();

    // Sau khi màn hình render xong mới gọi API để tránh lỗi context.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }

  // ---------------------------------------------------------------------------
  // Helper format tiền theo VND.
  // ---------------------------------------------------------------------------
  String formatCurrency(double amount) {
    final format = NumberFormat('#,###', 'vi_VN');
    return '${format.format(amount)} VND';
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.dangerRed : AppColors.successGreen,
      ),
    );
  }

  Future<void> _reloadCart(CartProvider provider) async {
    await provider.fetchCart(notifyOnStart: false);
  }

  Future<void> _confirmClearCart(BuildContext context, CartProvider provider) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xóa giỏ hàng',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark),
        ),
        content: const Text(
          'Bạn có chắc muốn xóa tất cả sản phẩm khỏi giỏ hàng không?',
          style: TextStyle(color: AppColors.textGrey, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa hết', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (shouldClear != true) return;

    try {
      await provider.clearCart();
      _showSnack('Đã xóa toàn bộ giỏ hàng');
    } catch (e) {
      _showSnack('Không thể xóa giỏ hàng: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Consumer<CartProvider>(
          builder: (_, provider, __) => Column(
            children: [
              const Text(
                'Giỏ hàng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              if (provider.items.isNotEmpty)
                Text(
                  // Hiển thị số dòng sản phẩm trong giỏ, không cộng dồn theo quantity.
                  '${provider.cartLinesCount} sản phẩm',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, provider, child) {
              if (provider.items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Xóa tất cả',
                onPressed: () => _confirmClearCart(context, provider),
                icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.dangerRed),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading && cartProvider.items.isEmpty) {
            return _buildLoadingState();
          }

          if (cartProvider.errorMessage != null && cartProvider.items.isEmpty) {
            return _buildErrorState(cartProvider);
          }

          if (cartProvider.items.isEmpty) {
            return _buildEmptyState(cartProvider);
          }

          return RefreshIndicator(
            color: AppColors.primaryPink,
            onRefresh: () => _reloadCart(cartProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
              itemCount: cartProvider.items.length + 1,
              separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 14 : 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildSelectSummaryCard(cartProvider);
                }

                final item = cartProvider.items[index - 1];
                return CartItemWidget(
                  item: item,
                  provider: cartProvider,
                  formatCurrency: formatCurrency,
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) return const SizedBox.shrink();
          return _buildCheckoutBar(cartProvider);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Card chọn tất cả + thống kê nhanh.
  // ---------------------------------------------------------------------------
  Widget _buildSelectSummaryCard(CartProvider provider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderPink),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.07),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          _PinkCheckbox(
            value: provider.isAllSelected,
            onChanged: (value) => provider.toggleSelectAll(value ?? false),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn sản phẩm thanh toán',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Bạn có thể bỏ chọn sản phẩm chưa muốn mua.',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.softPink,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${provider.selectedCount}/${provider.items.length}',
              style: const TextStyle(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar(CartProvider provider) {
    final hasSelectedItem = provider.selectedCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -6),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _PinkCheckbox(
                  value: provider.isAllSelected,
                  onChanged: (value) => provider.toggleSelectAll(value ?? false),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Text(
                  'Đã chọn ${provider.selectedCount} sản phẩm',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Text(
                    'Tổng thanh toán',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    formatCurrency(provider.selectedSubtotal),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryPink,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: hasSelectedItem
                    ? () {
                  Navigator.pushNamed(context, '/checkout');
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primaryPink,
                  disabledBackgroundColor: AppColors.borderPink,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  hasSelectedItem ? 'Mua hàng (${provider.selectedCount})' : 'Chọn sản phẩm để mua',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryPink),
    );
  }

  Widget _buildErrorState(CartProvider provider) {
    return RefreshIndicator(
      color: AppColors.primaryPink,
      onRefresh: () => _reloadCart(provider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: const BoxDecoration(
                      color: AppColors.softPink,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.primaryPink),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Không thể tải giỏ hàng',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage ?? 'Vui lòng thử lại sau.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textGrey, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => provider.fetchCart(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(CartProvider provider) {
    return RefreshIndicator(
      color: AppColors.primaryPink,
      onRefresh: () => _reloadCart(provider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withOpacity(0.10),
                          offset: const Offset(0, 10),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 52,
                      color: AppColors.primaryPink,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Giỏ hàng đang trống',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy chọn sản phẩm yêu thích và thêm vào giỏ hàng nhé.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// Bottom sheet chọn lại phân loại sản phẩm trong giỏ hàng.
// -----------------------------------------------------------------------------
class _VariantPickerSheet extends StatefulWidget {
  final String title;
  final int? currentVariantId;
  final List<VariantItem> variants;
  final String Function(double) formatCurrency;

  const _VariantPickerSheet({
    required this.title,
    required this.currentVariantId,
    required this.variants,
    required this.formatCurrency,
  });

  @override
  State<_VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<_VariantPickerSheet> {
  int? _selectedVariantId;

  @override
  void initState() {
    super.initState();
    _selectedVariantId = widget.currentVariantId;
  }

  VariantItem? get _selectedVariant {
    for (final variant in widget.variants) {
      if (variant.id == _selectedVariantId) return variant;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.borderPink,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đổi phân loại',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textGrey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.variants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final variant = widget.variants[index];
                  final isSelected = variant.id == _selectedVariantId;
                  final isCurrent = variant.id == widget.currentVariantId;
                  final isOutOfStock = variant.stock <= 0;

                  return InkWell(
                    onTap: isOutOfStock
                        ? null
                        : () {
                      setState(() => _selectedVariantId = variant.id);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.softPink : AppColors.lighterPink,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryPink : AppColors.borderPink,
                          width: isSelected ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? AppColors.primaryPink : Colors.white,
                              border: Border.all(
                                color: isSelected ? AppColors.primaryPink : AppColors.borderPink,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        variant.name.isNotEmpty ? variant.name : 'Phân loại ${index + 1}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w900,
                                          color: isOutOfStock ? AppColors.textGrey : AppColors.textDark,
                                        ),
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(color: AppColors.borderPink),
                                        ),
                                        child: const Text(
                                          'Đang chọn',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.primaryPink,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      widget.formatCurrency(variant.price),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryPink,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      isOutOfStock ? 'Hết hàng' : 'Kho: ${variant.stock}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isOutOfStock ? AppColors.dangerRed : AppColors.textGrey,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (variant.sku.trim().isNotEmpty)
                                      Text(
                                        'SKU: ${variant.sku.trim()}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textGrey,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                },
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedVariant == null
                    ? null
                    : () => Navigator.pop(context, _selectedVariant),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.primaryPink,
                  disabledBackgroundColor: AppColors.borderPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Xác nhận đổi phân loại',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Checkbox pink dùng lại ở nhiều vị trí để đồng bộ format product.
// -----------------------------------------------------------------------------
class _PinkCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _PinkCheckbox({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryPink,
      checkColor: Colors.white,
      visualDensity: VisualDensity.compact,
      side: const BorderSide(color: AppColors.borderPink, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );
  }
}

// -----------------------------------------------------------------------------
// ITEM WIDGET - card sản phẩm trong giỏ hàng.
// -----------------------------------------------------------------------------
class CartItemWidget extends StatefulWidget {
  final CartItemModel item;
  final CartProvider provider;
  final String Function(double) formatCurrency;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.provider,
    required this.formatCurrency,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late final TextEditingController _qtyController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void didUpdateWidget(covariant CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newText = widget.item.quantity.toString();
    if (_qtyController.text != newText) {
      _qtyController.text = newText;
      _qtyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _qtyController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  String get _imageUrl {
    final url = widget.item.imageUrl?.trim();
    if (url != null && url.isNotEmpty) return url;
    return 'https://placehold.co/180x180.png?text=No+Image';
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.dangerRed : AppColors.successGreen,
      ),
    );
  }

  Future<void> _updateQuantity(int newQuantity) async {
    if (_isUpdating) return;

    if (newQuantity <= 0) {
      await _confirmRemoveItem();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isUpdating = true);

    try {
      await widget.provider.updateQuantity(widget.item.id, newQuantity);
    } catch (e) {
      _qtyController.text = widget.item.quantity.toString();
      _showSnack('Không thể cập nhật số lượng: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _submitQuantity(String value) async {
    final newQty = int.tryParse(value.trim());
    if (newQty == null) {
      _qtyController.text = widget.item.quantity.toString();
      FocusScope.of(context).unfocus();
      return;
    }

    await _updateQuantity(newQty);
  }

  Future<void> _confirmRemoveItem() async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xóa sản phẩm',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
        ),
        content: const Text(
          'Bạn muốn xóa sản phẩm này khỏi giỏ hàng?',
          style: TextStyle(color: AppColors.textGrey, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );

    if (shouldRemove != true) {
      _qtyController.text = widget.item.quantity.toString();
      return;
    }

    await _removeItem();
  }

  Future<void> _removeItem() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      await widget.provider.removeItem(widget.item.id);
      _showSnack('Đã xóa sản phẩm khỏi giỏ hàng');
    } catch (e) {
      _showSnack('Không thể xóa sản phẩm: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Bấm vào ảnh/tên sản phẩm trong giỏ hàng để mở trang chi tiết sản phẩm.
  // Dùng dữ liệu tạm từ cart item, sau đó ProductDetailScreen sẽ tự gọi lại
  // API GET /products/:id để lấy đủ ảnh, optionSchema và thông tin mới nhất.
  // ---------------------------------------------------------------------------
  Future<void> _openProductDetail() async {
    if (_isUpdating) return;

    final product = ProductModel(
      id: widget.item.productId,
      title: widget.item.title,
      description: null,
      price: widget.item.price,
      imageUrl: _imageUrl,
      stock: 0,
      status: 'ACTIVE',
      shopId: 0,
      variants: const [],
      optionSchema: const [],
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );

    // Khi quay lại từ chi tiết, reload cart để đồng bộ nếu user vừa thêm/mua sản phẩm.
    if (!mounted) return;
    try {
      await widget.provider.fetchCart(notifyOnStart: false);
    } catch (_) {
      // Không chặn UI nếu reload lỗi, vì cart hiện tại vẫn đang hiển thị dữ liệu cũ.
    }
  }

  // ---------------------------------------------------------------------------
  // Đổi phân loại ngay trong giỏ hàng.
  // BE hiện tại chưa có API update variant riêng cho cart item, nên FE dùng cách an toàn:
  // 1. Thêm variant mới vào giỏ với đúng số lượng hiện tại.
  // 2. Xóa cart item cũ.
  // Nếu bước thêm variant mới lỗi thì item cũ vẫn được giữ nguyên.
  // ---------------------------------------------------------------------------
  Future<void> _showChangeVariantSheet() async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final variants = await productProvider.getVariants(widget.item.productId);

      if (!mounted) return;
      setState(() => _isUpdating = false);

      if (variants.isEmpty) {
        _showSnack('Sản phẩm này chưa có phân loại để thay đổi', isError: true);
        return;
      }

      final selectedVariant = await showModalBottomSheet<VariantItem>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _VariantPickerSheet(
          title: widget.item.title,
          currentVariantId: widget.item.variantId,
          variants: variants,
          formatCurrency: widget.formatCurrency,
        ),
      );

      if (selectedVariant == null || !mounted) return;

      if (selectedVariant.id == widget.item.variantId) {
        _showSnack('Bạn đang chọn phân loại này rồi');
        return;
      }

      await _changeVariant(selectedVariant);
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        _showSnack('Không thể tải phân loại sản phẩm: $e', isError: true);
      }
    }
  }

  Future<void> _changeVariant(VariantItem newVariant) async {
    if (newVariant.stock <= 0) {
      _showSnack('Phân loại này đã hết hàng', isError: true);
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await widget.provider.addToCart(
        widget.item.productId,
        variantId: newVariant.id,
        quantity: widget.item.quantity,
      );

      await widget.provider.removeItem(widget.item.id);
      await widget.provider.fetchCart(notifyOnStart: false);

      _showSnack('Đã đổi phân loại sản phẩm');
    } catch (e) {
      try {
        await widget.provider.fetchCart(notifyOnStart: false);
      } catch (_) {}
      _showSnack('Không thể đổi phân loại: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isUpdating ? 0.68 : 1,
      duration: const Duration(milliseconds: 160),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.item.isSelected ? AppColors.borderPink : AppColors.borderPink.withOpacity(0.55),
            width: widget.item.isSelected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPink.withOpacity(widget.item.isSelected ? 0.08 : 0.04),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _PinkCheckbox(
                    value: widget.item.isSelected,
                    onChanged: (_) => widget.provider.toggleSelection(widget.item.id),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _openProductDetail,
                  borderRadius: BorderRadius.circular(16),
                  child: _buildProductImage(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _openProductDetail,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildItemInfo(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.formatCurrency(widget.item.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryPink,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildQuantityStepper(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: _imageUrl,
        width: 86,
        height: 86,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 86,
          height: 86,
          color: AppColors.lighterPink,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 86,
          height: 86,
          color: AppColors.lighterPink,
          child: const Icon(Icons.image_not_supported_rounded, color: AppColors.textGrey),
        ),
      ),
    );
  }

  Widget _buildItemInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: _isUpdating ? null : _confirmRemoveItem,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.lighterPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: AppColors.dangerRed, size: 19),
              ),
            ),
          ],
        ),
        if ((widget.item.variantName ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: _isUpdating ? null : _showChangeVariantSheet,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.softPink,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderPink),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.item.variantName!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primaryPink),
                ],
              ),
            ),
          ),
        ],
        if ((widget.item.sku ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            'SKU: ${widget.item.sku!.trim()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderPink, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepperButton(
            icon: Icons.remove_rounded,
            onTap: _isUpdating
                ? null
                : () {
              if (widget.item.quantity > 1) {
                _updateQuantity(widget.item.quantity - 1);
              } else {
                _confirmRemoveItem();
              }
            },
          ),
          Container(width: 1, height: 20, color: AppColors.borderPink),
          SizedBox(
            width: 42,
            child: TextField(
              enabled: !_isUpdating,
              controller: _qtyController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: AppColors.textDark,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
              ),
              onSubmitted: _submitQuantity,
              textInputAction: TextInputAction.done,
            ),
          ),
          Container(width: 1, height: 20, color: AppColors.borderPink),
          _buildStepperButton(
            icon: Icons.add_rounded,
            onTap: _isUpdating ? null : () => _updateQuantity(widget.item.quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 34,
          height: 36,
          child: _isUpdating
              ? const Center(
            child: SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryPink),
            ),
          )
              : Icon(icon, size: 18, color: AppColors.textDark),
        ),
      ),
    );
  }
}
