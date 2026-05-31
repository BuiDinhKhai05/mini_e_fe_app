// lib/screens/shops/shop_revenue_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop_model.dart';
import '../../providers/shop_provider.dart';
import '../../theme/app_theme.dart';
import 'seller_order_list_screen.dart';
import 'seller_product_list_screen.dart';

class ShopRevenueScreen extends StatefulWidget {
  const ShopRevenueScreen({super.key});

  @override
  State<ShopRevenueScreen> createState() => _ShopRevenueScreenState();
}

class _ShopRevenueScreenState extends State<ShopRevenueScreen> {
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _lighterPink = AppColors.background;
  static const Color _borderPink = AppColors.borderPink;
  static const Color _textDark = AppColors.textDark;
  static const Color _textGrey = AppColors.textGrey;
  static const Color _dangerRed = AppColors.error;
  static const Color _successGreen = Colors.green;

  ShopOrderRange _selectedRange = ShopOrderRange.sevenDays;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadRevenueData();
    });
  }

  Future<void> _reloadRevenueData() async {
    await context.read<ShopProvider>().loadShopRevenue(
      range: _selectedRange,
      limit: 1000,
    );
  }

  Future<void> _changeRange(ShopOrderRange range) async {
    setState(() {
      _selectedRange = range;
    });

    await context.read<ShopProvider>().loadShopRevenue(
      range: range,
      limit: 1000,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();
    final shop = provider.shop;
    final orders = provider.revenueOrders;
    final loading = provider.isRevenueLoading;
    final error = provider.revenueError;

    final metrics = _RevenueMetrics.fromOrders(orders);

    return Scaffold(
      backgroundColor: _lighterPink,
      appBar: AppBar(
        title: const Text(
          'Doanh thu cửa hàng',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh_rounded, color: _primaryPink),
            onPressed: loading ? null : _reloadRevenueData,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _primaryPink,
        onRefresh: _reloadRevenueData,
        child: loading && shop == null
            ? const Center(
          child: CircularProgressIndicator(color: _primaryPink),
        )
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (error != null && shop == null)
                _buildErrorCard(error)
              else if (shop == null)
                _buildEmptyCard()
              else ...[
                  _buildRangeFilterCard(loading),
                  const SizedBox(height: 14),
                  _buildRevenueMainCard(shop, metrics),
                  const SizedBox(height: 14),
                  _buildRevenueDetailCard(metrics),
                  const SizedBox(height: 14),
                  _buildOrdersCard(orders, loading),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeFilterCard(bool loading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Khoảng thời gian',
            style: TextStyle(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ShopOrderRange>(
            value: _selectedRange,
            decoration: InputDecoration(
              filled: true,
              fillColor: _lighterPink,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _borderPink),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primaryPink, width: 1.5),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: ShopOrderRange.today,
                child: Text('Hôm nay'),
              ),
              DropdownMenuItem(
                value: ShopOrderRange.sevenDays,
                child: Text('7 ngày'),
              ),
              DropdownMenuItem(
                value: ShopOrderRange.thirtyDays,
                child: Text('30 ngày'),
              ),
              DropdownMenuItem(
                value: ShopOrderRange.all,
                child: Text('Tất cả'),
              ),
            ],
            onChanged: loading
                ? null
                : (value) {
              if (value != null) {
                _changeRange(value);
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRevenueMainCard(
      ShopModel shop,
      _RevenueMetrics metrics,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _primaryPink,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doanh thu ${_selectedRange.label.toLowerCase()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            _formatCurrency(metrics.revenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildRevenuePill(
                Icons.shopping_bag_outlined,
                '${metrics.revenueOrderCount} đơn tính doanh thu',
              ),
              _buildRevenuePill(
                Icons.assignment_return_outlined,
                '${metrics.returnedOrCanceledCount} hoàn / hủy',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenuePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueDetailCard(_RevenueMetrics metrics) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCircleIcon(
                Icons.receipt_long_rounded,
                size: 42,
                iconSize: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Chi tiết doanh thu',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRevenueInfoRow(
            label: 'Doanh thu trong kỳ',
            value: _formatCurrency(metrics.revenue),
          ),
          _buildRevenueInfoRow(
            label: 'Tổng đơn trong kỳ',
            value: '${metrics.totalOrders}',
          ),
          _buildRevenueInfoRow(
            label: 'Đơn được tính doanh thu',
            value: '${metrics.revenueOrderCount}',
          ),
          _buildRevenueInfoRow(
            label: 'Hoàn trả / hủy',
            value: '${metrics.returnedOrCanceledCount}',
            valueColor: _dangerRed,
          ),
          _buildRevenueInfoRow(
            label: 'Trung bình / đơn',
            value: _formatCurrency(metrics.averageOrder),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueInfoRow({
    required String label,
    required String value,
    Color valueColor = _primaryPink,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lighterPink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderPink),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: valueColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersCard(List<ShopOrderModel> orders, bool loading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCircleIcon(
                Icons.list_alt_rounded,
                size: 42,
                iconSize: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tất cả đơn hàng trong kỳ',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 14),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: _primaryPink),
              ),
            )
          else if (orders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _lighterPink,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderPink),
              ),
              child: const Text(
                'Chưa có đơn hàng trong khoảng thời gian này.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textGrey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...orders.map(_buildOrderRevenueTile),
        ],
      ),
    );
  }

  Widget _buildOrderRevenueTile(ShopOrderModel order) {
    final countRevenue = order.isRevenueOrder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderPink),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: _primaryPink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.code.isNotEmpty ? order.code : order.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _formatDate(order.createdAt),
                style: const TextStyle(
                  color: _textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(
                label: _orderStatusLabel(order.status),
                color: _orderStatusColor(order.status),
              ),
              _buildStatusChip(
                label:
                '${_paymentMethodLabel(order.paymentMethod)}(${_paymentStatusLabel(order.paymentStatus)})',
                color: _paymentStatusColor(order.paymentStatus),
              ),
              _buildStatusChip(
                label: _shippingStatusLabel(order.shippingStatus),
                color: _shippingStatusColor(order.shippingStatus),
              ),
              _buildStatusChip(
                label: countRevenue ? 'Tính doanh thu' : 'Không tính doanh thu',
                color: countRevenue ? _successGreen : _dangerRed,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng tiền',
                  style: TextStyle(
                    color: _textGrey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatCurrency(order.total),
                style: const TextStyle(
                  color: _primaryPink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }



  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryPink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  void _openSellerOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SellerOrderListScreen(),
      ),
    );
  }

  void _openSellerProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SellerProductListScreen(),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: _dangerRed, size: 38),
          const SizedBox(height: 10),
          const Text(
            'Không thể tải doanh thu',
            style: TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 22),
      child: const Text(
        'Chưa có dữ liệu shop để hiển thị doanh thu.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _textGrey,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildCircleIcon(
      IconData icon, {
        double size = 54,
        double iconSize = 26,
      }) {
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

  String _orderStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ Xử Lý';
      case 'PAID':
        return 'Đã Thanh Toán';
      case 'PROCESSING':
        return 'Đang Xử Lý';
      case 'SHIPPED':
        return 'Đang Giao';
      case 'COMPLETED':
        return 'Hoàn Thành';
      case 'CANCELED':
      case 'CANCELLED':
        return 'Đã Hủy';
      default:
        return status.isEmpty ? 'Chưa Xác Định' : status;
    }
  }

  String _paymentStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'UNPAID':
        return 'Chưa Thanh Toán';
      case 'PAID':
        return 'Đã Thanh Toán';
      case 'REFUNDED':
        return 'Đã Hoàn Tiền';
      default:
        return status.isEmpty ? 'Chưa Xác Định' : status;
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'COD':
        return 'COD';
      case 'VNPAY':
        return 'VNP';
      default:
        return method.isEmpty ? 'N/A' : method;
    }
  }

  String _shippingStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Chờ Lấy Hàng';
      case 'PICKED':
        return 'Đã Lấy Hàng';
      case 'IN_TRANSIT':
        return 'Đang Vận Chuyển';
      case 'DELIVERED':
        return 'Đã Giao Hàng';
      case 'RETURNED':
        return 'Đã Hoàn Trả';
      case 'CANCELED':
      case 'CANCELLED':
        return 'Đã Hủy Giao';
      default:
        return status.isEmpty ? 'Chưa Xác Định' : status;
    }
  }

  Color _orderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'PAID':
        return _successGreen;
      case 'CANCELED':
      case 'CANCELLED':
        return _dangerRed;
      case 'PROCESSING':
      case 'SHIPPED':
        return Colors.orange;
      default:
        return _primaryPink;
    }
  }

  Color _paymentStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return _successGreen;
      case 'REFUNDED':
        return _dangerRed;
      default:
        return _primaryPink;
    }
  }

  Color _shippingStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return _successGreen;
      case 'RETURNED':
      case 'CANCELED':
      case 'CANCELLED':
        return _dangerRed;
      case 'PICKED':
      case 'IN_TRANSIT':
        return Colors.orange;
      default:
        return _primaryPink;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Chưa có';

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    return '$day/$month/$year';
  }

  String _formatCurrency(num value) {
    final raw = value.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()}đ';
  }
}

class _RevenueMetrics {
  final int totalOrders;
  final int revenueOrderCount;
  final int returnedOrCanceledCount;
  final double revenue;
  final double averageOrder;

  _RevenueMetrics({
    required this.totalOrders,
    required this.revenueOrderCount,
    required this.returnedOrCanceledCount,
    required this.revenue,
    required this.averageOrder,
  });

  factory _RevenueMetrics.fromOrders(List<ShopOrderModel> orders) {
    final revenueOrders = orders.where((order) => order.isRevenueOrder)
        .toList();

    final returnedOrCanceledOrders = orders
        .where((order) => order.isReturnedOrCanceled)
        .toList();

    final revenue = revenueOrders.fold<double>(
      0,
          (sum, order) => sum + order.total,
    );

    return _RevenueMetrics(
      totalOrders: orders.length,
      revenueOrderCount: revenueOrders.length,
      returnedOrCanceledCount: returnedOrCanceledOrders.length,
      revenue: revenue,
      averageOrder: revenueOrders.isEmpty ? 0 : revenue / revenueOrders.length,
    );
  }
}