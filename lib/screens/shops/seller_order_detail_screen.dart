import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../service/order_service.dart';

class SellerOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const SellerOrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<SellerOrderDetailScreen> createState() => _SellerOrderDetailScreenState();
}

class _SellerOrderDetailScreenState extends State<SellerOrderDetailScreen> {
  final OrderService _orderService = OrderService();

  static const Color _primaryPink = Color(0xFFFF5C8A);
  static const Color _softPink = Color(0xFFFFEEF4);
  static const Color _lighterPink = Color(0xFFFFF7FA);
  static const Color _borderPink = Color(0xFFFFD8E4);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF707070);
  static const Color _dangerRed = Color(0xFFFF4D5E);

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _orderService.getMyShopOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = detail;
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

  Future<void> _updateShippingStatus(String nextStatus) async {
    final current = _order;
    if (current == null) return;

    setState(() {
      _isActionLoading = true;
    });

    try {
      final updated = await _orderService.updateMyShopOrderShippingStatus(
        orderId: current.id,
        shippingStatus: nextStatus,
      );

      if (!mounted) return;

      setState(() {
        _order = updated;
      });

      await _loadDetail();

      if (!mounted) return;

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
        _isActionLoading = false;
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

  String _paymentText(String status) {
    switch (status) {
      case 'UNPAID':
        return 'Chưa thanh toán';
      case 'PAID':
        return 'Đã thanh toán';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
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
    final order = _order;

    return Scaffold(
      backgroundColor: _lighterPink,
      appBar: AppBar(
        title: const Text(
          'Chi tiết đơn hàng',
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
      body: _buildBody(order),
      bottomNavigationBar: order == null ? null : _buildBottomActions(order),
    );
  }

  Widget _buildBody(OrderModel? order) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryPink),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _dangerRed,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    if (order == null) {
      return const Center(
        child: Text('Không tìm thấy đơn hàng'),
      );
    }

    final items = order.items ?? [];

    return RefreshIndicator(
      color: _primaryPink,
      onRefresh: _loadDetail,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
        children: [
          _buildOrderHeader(order),
          const SizedBox(height: 12),
          _buildCustomerCard(order),
          const SizedBox(height: 12),
          _buildProductList(items),
          const SizedBox(height: 12),
          _buildPaymentCard(order),
          if (order.note != null && order.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNoteCard(order.note!),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel order) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: _primaryPink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.code,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildStatusChip(order.shippingStatus),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.schedule_rounded, 'Ngày đặt', _formatDate(order.createdAt)),
          const SizedBox(height: 8),
          _infoRow(Icons.local_shipping_outlined, 'Vận chuyển', _shippingText(order.shippingStatus)),
          const SizedBox(height: 8),
          _infoRow(Icons.payments_outlined, 'Thanh toán', _paymentText(order.paymentStatus)),
          const SizedBox(height: 8),
          _infoRow(Icons.wallet_outlined, 'Phương thức', order.paymentMethod),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(OrderModel order) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.person_pin_circle_outlined, 'Thông tin nhận hàng'),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline_rounded, 'Người nhận', order.receiverName.isEmpty ? 'Chưa có' : order.receiverName),
          const SizedBox(height: 8),
          _infoRow(Icons.phone_outlined, 'Số điện thoại', order.receiverPhone.isEmpty ? 'Chưa có' : order.receiverPhone),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on_outlined, 'Địa chỉ', order.receiverAddress.isEmpty ? 'Chưa có' : order.receiverAddress),
        ],
      ),
    );
  }

  Widget _buildProductList(List<OrderItemModel> items) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.inventory_2_outlined, 'Sản phẩm trong đơn'),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Chưa có dữ liệu sản phẩm.',
              style: TextStyle(color: _textGrey),
            )
          else
            ...items.map(_buildProductItem).toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(OrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _lighterPink,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderPink),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 64,
              height: 64,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (item.variantText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.variantText,
                    style: const TextStyle(
                      color: _textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${_formatMoney(item.price)} x ${item.quantity}',
                  style: const TextStyle(
                    color: _textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatMoney(item.totalLine),
            style: const TextStyle(
              color: _primaryPink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(OrderModel order) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.receipt_outlined, 'Tổng thanh toán'),
          const SizedBox(height: 12),
          _moneyRow('Tạm tính', order.subtotal),
          const SizedBox(height: 8),
          _moneyRow('Phí vận chuyển', order.shippingFee),
          if (order.discount > 0) ...[
            const SizedBox(height: 8),
            _moneyRow('Giảm giá', -order.discount),
          ],
          const Divider(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng cộng',
                  style: TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                _formatMoney(order.total),
                style: const TextStyle(
                  color: _primaryPink,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(String note) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.sticky_note_2_outlined, 'Ghi chú của khách'),
          const SizedBox(height: 10),
          Text(
            note,
            style: const TextStyle(
              color: _textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomActions(OrderModel order) {
    if (order.shippingStatus != 'PENDING' && order.shippingStatus != 'PICKED') {
      return null;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        12,
        14,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _borderPink),
        ),
      ),
      child: _isActionLoading
          ? const SizedBox(
        height: 48,
        child: Center(
          child: CircularProgressIndicator(color: _primaryPink),
        ),
      )
          : Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateShippingStatus('CANCELED'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _dangerRed,
                side: const BorderSide(color: _dangerRed),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Hủy đơn'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (order.shippingStatus == 'PENDING') {
                  _updateShippingStatus('PICKED');
                } else if (order.shippingStatus == 'PICKED') {
                  _updateShippingStatus('IN_TRANSIT');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPink,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                order.shippingStatus == 'PENDING'
                    ? 'Xác nhận lấy hàng'
                    : 'Giao vận chuyển',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _primaryPink, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _textDark,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _textGrey, size: 18),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: _textGrey,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _moneyRow(String label, double value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _textGrey),
          ),
        ),
        Text(
          _formatMoney(value),
          style: const TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
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
}