// lib/screens/orders/my_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../service/review_service.dart';

class MyOrdersScreen extends StatefulWidget {
  static const routeName = '/orders';
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  static const Color _primaryPink = Color(0xFFFF4F8B);
  static const Color _softPink = Color(0xFFFFEEF5);
  static const Color _pageBg = Color(0xFFFFF7FA);
  static const Color _textDark = Color(0xFF4A2F38);
  static const Color _textMuted = Color(0xFF9A7B86);

  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');

  // Service dùng để gửi đánh giá sản phẩm lên BE.
  // BE: POST /orders/:id/review
  final ReviewService _reviewService = ReviewService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchMyOrders(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          title: const Column(
            children: [
              Text(
                'Đơn hàng của tôi',
                style: TextStyle(color: _textDark, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 2),
              Text(
                'Theo dõi trạng thái mua hàng',
                style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: _textDark,
          bottom: const TabBar(
            labelColor: _primaryPink,
            unselectedLabelColor: _textMuted,
            indicatorColor: _primaryPink,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              Tab(text: 'Chờ xử lý'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Hoàn thành'),
            ],
          ),
        ),
        body: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            if (orderProvider.isLoading && orderProvider.myOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: _primaryPink));
            }

            final allOrders = orderProvider.myOrders;

            // Phân tab theo thứ tự ưu tiên để đơn không bị lặp giữa các tab.
            final completedOrders = allOrders.where(_isCompletedOrder).toList();
            final shippingOrders = allOrders
                .where((order) => !_isCompletedOrder(order) && _isShippingOrder(order))
                .toList();
            final pendingOrders = allOrders
                .where((order) => !_isCompletedOrder(order) && !_isShippingOrder(order))
                .toList();

            return RefreshIndicator(
              color: _primaryPink,
              onRefresh: () => orderProvider.fetchMyOrders(refresh: true),
              child: TabBarView(
                children: [
                  _buildOrderList(orderProvider, pendingOrders, 'Chưa có đơn hàng chờ xử lý'),
                  _buildOrderList(orderProvider, shippingOrders, 'Chưa có đơn hàng đang giao'),
                  _buildOrderList(orderProvider, completedOrders, 'Chưa có đơn hàng hoàn thành'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isCompletedOrder(OrderModel order) {
    return order.status == 'COMPLETED' ||
        order.status == 'CANCELLED' ||
        order.shippingStatus == 'DELIVERED' ||
        order.shippingStatus == 'RETURNED' ||
        order.shippingStatus == 'CANCELED';
  }

  bool _isShippingOrder(OrderModel order) {
    return order.status == 'PAID' ||
        order.status == 'PROCESSING' ||
        order.status == 'SHIPPED' ||
        order.shippingStatus == 'PICKED' ||
        order.shippingStatus == 'IN_TRANSIT';
  }

  bool _canCancel(OrderModel order) {
    return order.status != 'COMPLETED' &&
        order.status != 'CANCELLED' &&
        order.shippingStatus == 'PENDING';
  }

  bool _canConfirmReceived(OrderModel order) {
    return order.status != 'COMPLETED' &&
        order.status != 'CANCELLED' &&
        order.shippingStatus == 'IN_TRANSIT';
  }

  bool _canRequestReturn(OrderModel order) {
    return order.status == 'COMPLETED' && order.shippingStatus == 'DELIVERED';
  }

  // Chỉ cho đánh giá khi đơn hàng đã hoàn thành và đã giao.
  // Rule này khớp với BE trong ReviewsService.createForOrder().
  bool _canReview(OrderModel order) {
    return order.status == 'COMPLETED' && order.shippingStatus == 'DELIVERED';
  }

  Widget _buildOrderList(OrderProvider provider, List<OrderModel> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          _buildEmptyState(emptyMessage),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _buildOrderItem(provider, orders[index]),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(color: _softPink, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_outlined, size: 42, color: _primaryPink),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderProvider provider, OrderModel order) {
    final statusColor = _getStatusColor(order.status, order.shippingStatus);
    final statusLabel = _getStatusLabel(order.status, order.shippingStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryPink.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(color: _softPink, shape: BoxShape.circle),
                child: const Icon(Icons.local_mall_outlined, color: _primaryPink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.code}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.createdAt),
                      style: const TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: _primaryPink.withOpacity(0.12)),
          const SizedBox(height: 14),
          _buildInfoRow('Thanh toán', '${order.paymentMethod} • ${_paymentLabel(order.paymentStatus)}'),
          const SizedBox(height: 8),
          _buildInfoRow('Vận chuyển', _shippingLabel(order.shippingStatus)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng thanh toán',
                  style: TextStyle(color: _textMuted, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                currencyFormat.format(order.total),
                style: const TextStyle(
                  color: _primaryPink,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildOrderActions(provider, order),
        ],
      ),
    );
  }

  Widget _buildOrderActions(OrderProvider provider, OrderModel order) {
    final isActionLoading = provider.isOrderActionLoading(order.id);
    final buttons = <Widget>[
      _buildSmallOutlineButton(
        label: 'Xem chi tiết',
        onPressed: isActionLoading ? null : () => _showOrderInfo(order),
      ),
    ];

    if (_canCancel(order)) {
      buttons.add(
        _buildSmallOutlineButton(
          label: 'Hủy đơn',
          isDanger: true,
          onPressed: isActionLoading ? null : () => _handleCancel(provider, order),
        ),
      );
    }

    if (_canConfirmReceived(order)) {
      buttons.add(
        _buildSmallFilledButton(
          label: 'Đã nhận hàng',
          isLoading: isActionLoading,
          onPressed: isActionLoading ? null : () => _handleConfirmReceived(provider, order),
        ),
      );
    }

    if (_canReview(order)) {
      buttons.add(
        _buildSmallFilledButton(
          label: 'Đánh giá',
          isLoading: isActionLoading,
          onPressed: isActionLoading ? null : () => _handleReviewOrder(provider, order),
        ),
      );
    }

    if (_canRequestReturn(order)) {
      buttons.add(
        _buildSmallOutlineButton(
          label: 'Yêu cầu trả hàng',
          onPressed: isActionLoading ? null : () => _handleRequestReturn(provider, order),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: buttons,
    );
  }

  Widget _buildSmallOutlineButton({
    required String label,
    required VoidCallback? onPressed,
    bool isDanger = false,
  }) {
    final color = isDanger ? const Color(0xFFFF5B5B) : _primaryPink;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildSmallFilledButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        visualDensity: VisualDensity.compact,
      ),
      child: isLoading
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: const TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: _textDark, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCancel(OrderProvider provider, OrderModel order) async {
    final confirmed = await _confirmAction(
      title: 'Hủy đơn hàng?',
      message: 'Bạn chỉ có thể hủy khi shop chưa nhận đơn. Bạn có chắc muốn hủy đơn #${order.code} không?',
      confirmText: 'Hủy đơn',
      isDanger: true,
    );

    if (!confirmed) return;
    final success = await provider.cancelOrder(order.id);
    if (!mounted) return;

    _showSnack(success ? 'Đã hủy đơn hàng' : provider.errorMessage ?? 'Hủy đơn thất bại');
  }

  Future<void> _handleConfirmReceived(OrderProvider provider, OrderModel order) async {
    final confirmed = await _confirmAction(
      title: 'Xác nhận đã nhận hàng?',
      message: 'Sau khi xác nhận, đơn hàng sẽ chuyển sang hoàn thành.',
      confirmText: 'Xác nhận',
    );

    if (!confirmed) return;
    final success = await provider.confirmReceived(order.id);
    if (!mounted) return;

    _showSnack(success ? 'Đã xác nhận nhận hàng' : provider.errorMessage ?? 'Xác nhận thất bại');
  }

  Future<void> _handleRequestReturn(OrderProvider provider, OrderModel order) async {
    final confirmed = await _confirmAction(
      title: 'Yêu cầu trả hàng?',
      message: 'Yêu cầu này chỉ khả dụng sau khi đơn đã hoàn thành và đã giao hàng.',
      confirmText: 'Gửi yêu cầu',
    );

    if (!confirmed) return;
    final success = await provider.requestReturn(order.id);
    if (!mounted) return;

    _showSnack(success ? 'Đã gửi yêu cầu trả hàng' : provider.errorMessage ?? 'Gửi yêu cầu thất bại');
  }


  // Mở chức năng đánh giá cho đơn hàng đã hoàn thành.
  // Nếu đơn có nhiều sản phẩm thì cho user chọn sản phẩm cần đánh giá.
  Future<void> _handleReviewOrder(OrderProvider provider, OrderModel order) async {
    var detail = order;

    // API danh sách đơn hàng có thể chưa trả items,
    // nên cần gọi chi tiết đơn trước khi đánh giá.
    if (order.items == null) {
      final loadedDetail = await provider.fetchOrderDetail(order.id);
      if (!mounted) return;

      if (loadedDetail == null) {
        _showSnack(provider.errorMessage ?? 'Không tải được sản phẩm trong đơn');
        return;
      }

      detail = loadedDetail;
    }

    final items = detail.items ?? [];

    if (items.isEmpty) {
      _showSnack('Đơn hàng này chưa có dữ liệu sản phẩm để đánh giá');
      return;
    }

    if (items.length == 1) {
      await _showReviewDialog(order: detail, item: items.first);
      return;
    }

    await _showReviewProductPicker(order: detail, items: items);
  }

  // Bottom sheet chọn sản phẩm cần đánh giá trong đơn hàng.
  Future<void> _showReviewProductPicker({
    required OrderModel order,
    required List<OrderItemModel> items,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.38,
          maxChildSize: 0.86,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Chọn sản phẩm để đánh giá',
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Đơn hàng #${order.code}',
                    style: const TextStyle(
                      color: _textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final item in items) _buildReviewPickerItem(order, item),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Item sản phẩm trong bottom sheet chọn sản phẩm đánh giá.
  Widget _buildReviewPickerItem(OrderModel order, OrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryPink.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 58,
              height: 58,
              color: _softPink,
              child: item.imageSnapshot != null && item.imageSnapshot!.isNotEmpty
                  ? Image.network(
                item.imageSnapshot!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported_outlined, color: _textMuted),
              )
                  : const Icon(Icons.shopping_bag_outlined, color: _primaryPink),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nameSnapshot,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                if (item.variantText.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.variantText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildSmallFilledButton(
                    label: 'Đánh giá',
                    onPressed: () async {
                      Navigator.pop(context);
                      await _showReviewDialog(order: order, item: item);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dialog nhập số sao và nội dung đánh giá.
  Future<void> _showReviewDialog({
    required OrderModel order,
    required OrderItemModel item,
  }) async {
    if (item.productId == null) {
      _showSnack('Không tìm thấy productId của sản phẩm này');
      return;
    }

    int rating = 5;
    bool isSubmitting = false;
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: const Text(
                'Đánh giá sản phẩm',
                style: TextStyle(color: _textDark, fontWeight: FontWeight.w900),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 52,
                            height: 52,
                            color: _softPink,
                            child: item.imageSnapshot != null && item.imageSnapshot!.isNotEmpty
                                ? Image.network(
                              item.imageSnapshot!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported_outlined,
                                color: _textMuted,
                              ),
                            )
                                : const Icon(Icons.shopping_bag_outlined, color: _primaryPink),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nameSnapshot,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textDark,
                                  fontWeight: FontWeight.w900,
                                  height: 1.25,
                                ),
                              ),
                              if (item.variantText.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.variantText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Bạn đánh giá sản phẩm này thế nào?',
                      style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed: isSubmitting
                              ? null
                              : () {
                            setDialogState(() {
                              rating = starValue;
                            });
                          },
                          icon: Icon(
                            starValue <= rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFFB800),
                            size: 34,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      enabled: !isSubmitting,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Chia sẻ cảm nhận của bạn về sản phẩm...',
                        hintStyle: const TextStyle(color: _textMuted),
                        filled: true,
                        fillColor: const Color(0xFFFFF7FA),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: _primaryPink.withOpacity(0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: _primaryPink.withOpacity(0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: _primaryPink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(color: _textMuted, fontWeight: FontWeight.w700),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                    setDialogState(() {
                      isSubmitting = true;
                    });

                    final success = await _submitReview(
                      orderId: order.id,
                      productId: item.productId!,
                      rating: rating,
                      comment: commentController.text.trim(),
                    );

                    if (!mounted) return;

                    if (success) {
                      Navigator.pop(dialogContext);
                    } else {
                      setDialogState(() {
                        isSubmitting = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Gửi đánh giá',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    commentController.dispose();
  }

  // Gửi đánh giá lên BE.
  Future<bool> _submitReview({
    required String orderId,
    required int productId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _reviewService.createReviewForOrder(
        orderId: orderId,
        productId: productId,
        rating: rating,
        comment: comment.isEmpty ? null : comment,
      );

      if (!mounted) return true;
      _showSnack('Đã gửi đánh giá sản phẩm');
      return true;
    } catch (e) {
      if (!mounted) return false;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    bool isDanger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(title, style: const TextStyle(color: _textDark, fontWeight: FontWeight.w900)),
          content: Text(message, style: const TextStyle(color: _textMuted, height: 1.4)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Đóng', style: TextStyle(color: _textMuted, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDanger ? const Color(0xFFFF5B5B) : _primaryPink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _showOrderInfo(OrderModel order) async {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    var detail = order;

    // API list /orders chưa trả items, nên khi xem chi tiết thì gọi /orders/:id.
    if (order.items == null) {
      final loadedDetail = await provider.fetchOrderDetail(order.id);
      if (!mounted) return;
      if (loadedDetail == null) {
        _showSnack(provider.errorMessage ?? 'Không tải được chi tiết đơn hàng');
        return;
      }
      detail = loadedDetail;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final items = detail.items ?? [];

        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '#${detail.code}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _textDark),
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow('Ngày đặt', _formatDate(detail.createdAt)),
                  const SizedBox(height: 10),
                  _buildInfoRow('Trạng thái', _getStatusLabel(detail.status, detail.shippingStatus)),
                  const SizedBox(height: 10),
                  _buildInfoRow('Thanh toán', '${detail.paymentMethod} • ${_paymentLabel(detail.paymentStatus)}'),
                  const SizedBox(height: 10),
                  _buildInfoRow('Vận chuyển', _shippingLabel(detail.shippingStatus)),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Sản phẩm trong đơn',
                      style: TextStyle(color: _textDark, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    for (final item in items) _buildOrderDetailItem(item),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _softPink,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Tổng thanh toán',
                            style: TextStyle(color: _textDark, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          currencyFormat.format(detail.total),
                          style: const TextStyle(color: _primaryPink, fontWeight: FontWeight.w900, fontSize: 17),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderDetailItem(OrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryPink.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 58,
              height: 58,
              color: _softPink,
              child: item.imageSnapshot != null && item.imageSnapshot!.isNotEmpty
                  ? Image.network(
                item.imageSnapshot!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported_outlined, color: _textMuted),
              )
                  : const Icon(Icons.shopping_bag_outlined, color: _primaryPink),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nameSnapshot,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textDark, fontWeight: FontWeight.w800, height: 1.25),
                ),
                if (item.variantText.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.variantText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currencyFormat.format(item.price),
                        style: const TextStyle(color: _primaryPink, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Color _getStatusColor(String status, String shippingStatus) {
    if (status == 'CANCELLED' || shippingStatus == 'CANCELED' || shippingStatus == 'RETURNED') {
      return const Color(0xFFFF5B5B);
    }
    if (status == 'COMPLETED' || shippingStatus == 'DELIVERED') {
      return const Color(0xFF22B573);
    }
    if (status == 'PAID' || status == 'PROCESSING' || status == 'SHIPPED') {
      return _primaryPink;
    }
    return const Color(0xFFFF8A00);
  }

  String _getStatusLabel(String status, String shippingStatus) {
    if (status == 'CANCELLED' || shippingStatus == 'CANCELED') return 'Đã hủy';
    if (shippingStatus == 'RETURNED') return 'Đã trả hàng';
    if (status == 'COMPLETED' || shippingStatus == 'DELIVERED') return 'Hoàn thành';
    if (status == 'SHIPPED' || shippingStatus == 'IN_TRANSIT') return 'Đang giao';
    if (status == 'PROCESSING' || shippingStatus == 'PICKED') return 'Đang xử lý';
    if (status == 'PAID') return 'Đã thanh toán';
    return 'Chờ xử lý';
  }

  String _paymentLabel(String status) {
    switch (status) {
      case 'PAID':
        return 'Đã thanh toán';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      case 'UNPAID':
      default:
        return 'Chưa thanh toán';
    }
  }

  String _shippingLabel(String status) {
    switch (status) {
      case 'PICKED':
        return 'Đã lấy hàng';
      case 'IN_TRANSIT':
        return 'Đang vận chuyển';
      case 'DELIVERED':
        return 'Đã giao hàng';
      case 'RETURNED':
        return 'Đã trả hàng';
      case 'CANCELED':
        return 'Đã hủy giao';
      case 'PENDING':
      default:
        return 'Chờ xử lý';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
