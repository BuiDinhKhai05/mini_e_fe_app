import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

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
          bottom: TabBar(
            labelColor: _primaryPink,
            unselectedLabelColor: _textMuted,
            indicatorColor: _primaryPink,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
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
                  _buildOrderList(pendingOrders, 'Chưa có đơn hàng chờ xử lý'),
                  _buildOrderList(shippingOrders, 'Chưa có đơn hàng đang giao'),
                  _buildOrderList(completedOrders, 'Chưa có đơn hàng hoàn thành'),
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

  Widget _buildOrderList(List<OrderModel> orders, String emptyMessage) {
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
      itemBuilder: (context, index) => _buildOrderItem(orders[index]),
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

  Widget _buildOrderItem(OrderModel order) {
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
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _showOrderInfo(order),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryPink,
                side: BorderSide(color: _primaryPink.withOpacity(0.35)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Xem chi tiết', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
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

  void _showOrderInfo(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  '#${order.code}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _textDark),
                ),
                const SizedBox(height: 14),
                _buildInfoRow('Ngày đặt', _formatDate(order.createdAt)),
                const SizedBox(height: 10),
                _buildInfoRow('Trạng thái', _getStatusLabel(order.status, order.shippingStatus)),
                const SizedBox(height: 10),
                _buildInfoRow('Thanh toán', '${order.paymentMethod} • ${_paymentLabel(order.paymentStatus)}'),
                const SizedBox(height: 10),
                _buildInfoRow('Vận chuyển', _shippingLabel(order.shippingStatus)),
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
                        currencyFormat.format(order.total),
                        style: const TextStyle(color: _primaryPink, fontWeight: FontWeight.w900, fontSize: 17),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
