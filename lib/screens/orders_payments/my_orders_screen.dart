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
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

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
        appBar: AppBar(
          title: const Text('Đơn hàng của tôi'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Chờ thanh toán'),
              Tab(text: 'Đang vận chuyển'),
              Tab(text: 'Đã nhận'),
            ],
          ),
        ),
        body: Consumer<OrderProvider>(
          builder: (context, orderProvider, child) {
            if (orderProvider.isLoading && orderProvider.myOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final allOrders = orderProvider.myOrders;

            final pendingOrders = allOrders.where((o) {
              // VNPAY chờ thanh toán: order chỉ xuất hiện sau PAID,
              // nên tab này chủ yếu dùng cho (nếu sau này bạn tạo order UNPAID) hoặc COD pending
              return o.paymentStatus == 'UNPAID' || o.status == 'PENDING';
            }).toList();

            final shippingOrders = allOrders.where((o) {
              return o.status == 'PAID' ||
                  o.status == 'PROCESSING' ||
                  o.status == 'SHIPPED' ||
                  (o.shippingStatus == 'PENDING' || o.shippingStatus == 'PICKED' || o.shippingStatus == 'IN_TRANSIT');
            }).toList();

            final completedOrders = allOrders.where((o) {
              return o.status == 'COMPLETED' ||
                  o.status == 'CANCELLED' ||
                  o.shippingStatus == 'DELIVERED' ||
                  o.shippingStatus == 'RETURNED' ||
                  o.shippingStatus == 'CANCELED';
            }).toList();

            return TabBarView(
              children: [
                _buildOrderList(pendingOrders, 'Chưa có đơn hàng chờ thanh toán'),
                _buildOrderList(shippingOrders, 'Chưa có đơn hàng đang vận chuyển'),
                _buildOrderList(completedOrders, 'Chưa có đơn hàng hoàn thành'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildOrderItem(orders[index]),
    );
  }

  Widget _buildOrderItem(OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${order.code}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    color: _getStatusColor(order.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng thanh toán:'),
              Text(
                currencyFormat.format(order.total),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text('Thanh toán: ${order.paymentMethod} • ${order.paymentStatus}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text('Vận chuyển: ${order.shippingStatus}', style: const TextStyle(color: Colors.grey, fontSize: 12)),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  // TODO: Order detail screen
                },
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300)),
                child: const Text('Xem chi tiết', style: TextStyle(color: Colors.black)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'PAID':
      case 'PROCESSING':
      case 'SHIPPED':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
