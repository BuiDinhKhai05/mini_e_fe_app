import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../service/order_service.dart';
import 'seller_order_detail_screen.dart';

class SellerOrderListScreen extends StatefulWidget {
  const SellerOrderListScreen({Key? key}) : super(key: key);

  @override
  State<SellerOrderListScreen> createState() => _SellerOrderListScreenState();
}

class _SellerOrderListScreenState extends State<SellerOrderListScreen> {
  final OrderService _orderService = OrderService();

  static const Color _primaryPink = Color(0xFFFF5C8A);
  static const Color _softPink = Color(0xFFFFEEF4);
  static const Color _lighterPink = Color(0xFFFFF7FA);
  static const Color _borderPink = Color(0xFFFFD8E4);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF707070);
  static const Color _dangerRed = Color(0xFFFF4D5E);

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'ALL';
  List<OrderModel> _orders = [];
  final Set<String> _actionLoadingIds = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _orderService.getMyShopOrders();
      if (!mounted) return;
      setState(() {
        _orders = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<OrderModel> get _filteredOrders {
    if (_selectedFilter == 'ALL') return _orders;

    return _orders.where((order) {
      if (_selectedFilter == 'PENDING') {
        return order.shippingStatus == 'PENDING';
      }
      if (_selectedFilter == 'PICKED') {
        return order.shippingStatus == 'PICKED';
      }
      if (_selectedFilter == 'IN_TRANSIT') {
        return order.shippingStatus == 'IN_TRANSIT';
      }
      if (_selectedFilter == 'DONE') {
        return order.shippingStatus == 'DELIVERED' ||
            order.status == 'COMPLETED';
      }
      if (_selectedFilter == 'CANCELED') {
        return order.shippingStatus == 'CANCELED' ||
            order.status == 'CANCELLED';
      }
      return true;
    }).toList();
  }

  Future<void> _updateShippingStatus(OrderModel order, String nextStatus) async {
    setState(() {
      _actionLoadingIds.add(order.id);
    });

    try {
      final updated = await _orderService.updateMyShopOrderShippingStatus(
        orderId: order.id,
        shippingStatus: nextStatus,
      );

      if (!mounted) return;

      setState(() {
        final index = _orders.indexWhere((item) => item.id == updated.id);
        if (index >= 0) {
          _orders[index] = updated;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_successMessage(nextStatus)),
          backgroundColor: _primaryPink,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _dangerRed,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _actionLoadingIds.remove(order.id);
      });
    }
  }

  String _successMessage(String status) {
    switch (status) {
      case 'PICKED':
        return 'Đã xác nhận lấy hàng.';
      case 'IN_TRANSIT':
        return 'Đã chuyển sang trạng thái đang giao.';
      case 'CANCELED':
        return 'Đã hủy đơn hàng.';
      default:
        return 'Cập nhật đơn hàng thành công.';
    }
  }

  String _formatMoney(double value) {
    final raw = value.toStringAsFixed(0);
    final buffer = StringBuffer();

    for (int i = 0; i < raw.length; i++) {
      final reverseIndex = raw.length - i;
      buffer.write(raw[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} VND';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _shippingText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ shop xác nhận';
      case 'PICKED':
        return 'Đã lấy hàng';
      case 'IN_TRANSIT':
        return 'Đang giao';
      case 'DELIVERED':
        return 'Đã giao';
      case 'RETURNED':
        return 'Đã hoàn hàng';
      case 'CANCELED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'PICKED':
        return Colors.blue;
      case 'IN_TRANSIT':
        return _primaryPink;
      case 'DELIVERED':
        return Colors.green;
      case 'RETURNED':
        return Colors.purple;
      case 'CANCELED':
        return _dangerRed;
      default:
        return _textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;

    return Scaffold(
      backgroundColor: _lighterPink,
      appBar: AppBar(
        title: const Text(
          'Đơn hàng của shop',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              color: _primaryPink,
              onRefresh: _loadOrders,
              child: _buildBody(orders),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<OrderModel> orders) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryPink),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 120),
          Icon(Icons.error_outline_rounded, size: 64, color: _dangerRed),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      );
    }

    if (orders.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 140),
          Icon(Icons.shopping_bag_outlined, size: 74, color: _primaryPink),
          SizedBox(height: 16),
          Text(
            'Chưa có đơn hàng nào',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Khi khách mua sản phẩm của shop, đơn hàng sẽ xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textGrey),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'key': 'ALL', 'label': 'Tất cả'},
      {'key': 'PENDING', 'label': 'Chờ xác nhận'},
      {'key': 'PICKED', 'label': 'Đã lấy'},
      {'key': 'IN_TRANSIT', 'label': 'Đang giao'},
      {'key': 'DONE', 'label': 'Hoàn thành'},
      {'key': 'CANCELED', 'label': 'Đã hủy'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final key = filter['key']!;
            final selected = _selectedFilter == key;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selected,
                label: Text(filter['label']!),
                selectedColor: _primaryPink,
                backgroundColor: _softPink,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: selected ? _primaryPink : _borderPink,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = key;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final loading = _actionLoadingIds.contains(order.id);
    final items = order.items ?? [];

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SellerOrderDetailScreen(orderId: order.id),
          ),
        );

        if (mounted) {
          _loadOrders();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _borderPink),
          boxShadow: [
            BoxShadow(
              color: _primaryPink.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: _primaryPink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                    ),
                  ),
                ),
                _buildStatusChip(order.shippingStatus),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: _textGrey),
                const SizedBox(width: 6),
                Text(
                  _formatDate(order.createdAt),
                  style: const TextStyle(color: _textGrey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isNotEmpty)
              _buildFirstItem(items.first, items.length)
            else
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chưa có dữ liệu sản phẩm',
                  style: TextStyle(color: _textGrey),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Tổng tiền:',
                  style: TextStyle(color: _textGrey),
                ),
                const Spacer(),
                Text(
                  _formatMoney(order.total),
                  style: const TextStyle(
                    color: _primaryPink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionButtons(order, loading),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstItem(OrderItemModel item, int totalItems) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 56,
            height: 56,
            color: _softPink,
            child: item.imageSnapshot != null && item.imageSnapshot!.isNotEmpty
                ? Image.network(
              item.imageSnapshot!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Icon(Icons.image_not_supported_outlined, color: _textGrey);
              },
            )
                : const Icon(Icons.image_outlined, color: _textGrey),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.nameSnapshot,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Số lượng: ${item.quantity}',
                style: const TextStyle(color: _textGrey, fontSize: 12),
              ),
              if (totalItems > 1)
                Text(
                  '+ ${totalItems - 1} sản phẩm khác',
                  style: const TextStyle(color: _primaryPink, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _shippingText(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order, bool loading) {
    if (loading) {
      return const Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: _primaryPink),
        ),
      );
    }

    if (order.shippingStatus == 'PENDING') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateShippingStatus(order, 'CANCELED'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _dangerRed,
                side: const BorderSide(color: _dangerRed),
              ),
              child: const Text('Hủy đơn'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateShippingStatus(order, 'PICKED'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận lấy hàng'),
            ),
          ),
        ],
      );
    }

    if (order.shippingStatus == 'PICKED') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateShippingStatus(order, 'CANCELED'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _dangerRed,
                side: const BorderSide(color: _dangerRed),
              ),
              child: const Text('Hủy đơn'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateShippingStatus(order, 'IN_TRANSIT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Giao vận chuyển'),
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerOrderDetailScreen(orderId: order.id),
            ),
          );

          if (mounted) {
            _loadOrders();
          }
        },
        icon: const Icon(Icons.visibility_outlined),
        label: const Text('Xem chi tiết'),
        style: TextButton.styleFrom(
          foregroundColor: _primaryPink,
        ),
      ),
    );
  }
}