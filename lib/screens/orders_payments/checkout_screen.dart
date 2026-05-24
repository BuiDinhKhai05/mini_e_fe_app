// lib/screens/orders/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/address_model.dart';
import '../../models/cart_model.dart';
import '../../models/order_model.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _pageBg = AppColors.background;
  static const Color _textDark = AppColors.textDark;
  static const Color _textMuted = AppColors.textGrey;

  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');

  String _paymentMethod = 'COD';
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  // Load địa chỉ, chọn địa chỉ mặc định và gọi /orders/preview.
  Future<void> _initData() async {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (addressProvider.addresses.isEmpty && authProvider.accessToken != null) {
      await addressProvider.fetchAddresses(authProvider.accessToken!);
    }

    _setDefaultAddress();
  }

  void _setDefaultAddress() {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    if (addressProvider.addresses.isEmpty) return;

    final defaultAddress = addressProvider.addresses.firstWhere(
          (address) => address.isDefault,
      orElse: () => addressProvider.addresses.first,
    );

    setState(() => _selectedAddressId = defaultAddress.id);
    _loadPreview();
  }

  // Gửi đúng itemIds đã tick trong giỏ hàng lên BE preview.
  void _loadPreview() {
    if (_selectedAddressId == null) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final itemIds = cartProvider.items
        .where((item) => item.isSelected)
        .map((item) => item.id)
        .toList();

    if (itemIds.isEmpty) return;

    Provider.of<OrderProvider>(context, listen: false).previewOrder(
      _selectedAddressId!,
      itemIds,
    );
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer<AddressProvider>(
          builder: (context, addressProvider, _) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.extraLarge)),
              ),
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
                        borderRadius: BorderRadius.circular(AppRadius.circle),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Chọn địa chỉ nhận hàng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: addressProvider.addresses.isEmpty
                        ? _buildEmptyAddressBox()
                        : ListView.separated(
                      itemCount: addressProvider.addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final address = addressProvider.addresses[index];
                        final isSelected = address.id == _selectedAddressId;

                        return InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.large),
                          onTap: () {
                            setState(() => _selectedAddressId = address.id);
                            Navigator.pop(context);
                            _loadPreview();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? _softPink : const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(AppRadius.large),
                              border: Border.all(
                                color: isSelected
                                    ? _primaryPink.withOpacity(0.45)
                                    : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: isSelected ? _primaryPink : Colors.black26,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${address.fullName} | ${address.phone}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: _textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        address.formattedAddress,
                                        style: const TextStyle(
                                          color: _textMuted,
                                          height: 1.35,
                                        ),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Nếu app đã có route quản lý địa chỉ thì mở tại đây.
                        // Navigator.pushNamed(context, '/address-list');
                      },
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Thêm địa chỉ mới'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryPink,
                        side: BorderSide(color: _primaryPink.withOpacity(0.35)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
                      ),
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

  Future<void> _placeOrder() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (_selectedAddressId == null) {
      _showSnack('Vui lòng chọn địa chỉ nhận hàng');
      return;
    }

    final itemIds = cartProvider.items
        .where((item) => item.isSelected)
        .map((item) => item.id)
        .toList();

    if (itemIds.isEmpty) {
      _showSnack('Không có sản phẩm nào được chọn');
      return;
    }

    final result = await orderProvider.placeOrder(
      addressId: _selectedAddressId!,
      itemIds: itemIds,
      paymentMethod: _paymentMethod,
      note: 'Đặt hàng từ Mobile App',
    );

    if (!mounted) return;

    if (result == null) {
      _showSnack(orderProvider.errorMessage ?? 'Đặt hàng thất bại');
      return;
    }

    if (_paymentMethod == 'VNPAY') {
      // BE hiện tại trả: { session: { code, amount, status }, paymentUrl }
      final session = result['session'] is Map ? result['session'] as Map : null;
      final paymentUrl = (result['paymentUrl'] ?? '').toString();
      final sessionCode = (session?['code'] ?? '').toString();
      final amount = double.tryParse((session?['amount'] ?? 0).toString()) ?? 0.0;

      if (paymentUrl.isEmpty || sessionCode.isEmpty) {
        _showSnack('Không lấy được link thanh toán VNPAY');
        return;
      }

      Navigator.pushNamed(context, '/payment-gateway', arguments: {
        'qrData': paymentUrl,
        'amount': amount,
        'sessionCode': sessionCode,
        'orderIdToCheck': '',
      });
      return;
    }

    final List orders = result['orders'] is List ? result['orders'] as List : [];
    final firstOrderCode = orders.isNotEmpty ? (orders[0]['code'] ?? '').toString() : '';

    Navigator.pushReplacementNamed(context, '/payment-result', arguments: {
      'success': true,
      'message': 'Đặt hàng thành công! Vui lòng chuẩn bị tiền mặt.',
      'orderId': firstOrderCode,
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: _textDark,
        title: const Column(
          children: [
            Text(
              'Xác nhận đơn hàng',
              style: TextStyle(fontWeight: FontWeight.w800, color: _textDark),
            ),
            SizedBox(height: 2),
            Text(
              'Kiểm tra thông tin trước khi mua',
              style: TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Consumer2<OrderProvider, CartProvider>(
        builder: (context, orderProvider, cartProvider, child) {
          final preview = orderProvider.orderPreview;
          final selectedItems = cartProvider.items.where((item) => item.isSelected).toList();

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: _primaryPink,
                  onRefresh: () async => _loadPreview(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Địa chỉ nhận hàng', Icons.location_on_outlined),
                        Consumer<AddressProvider>(
                          builder: (ctx, addressProvider, _) {
                            AddressModel? selectedAddress;
                            if (_selectedAddressId != null && addressProvider.addresses.isNotEmpty) {
                              try {
                                selectedAddress = addressProvider.addresses.firstWhere(
                                      (address) => address.id == _selectedAddressId,
                                );
                              } catch (_) {
                                selectedAddress = null;
                              }
                            }

                            if (selectedAddress == null) {
                              return _buildChooseAddressCard(addressProvider.addresses.isEmpty);
                            }

                            return _buildAddressCard(selectedAddress);
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Sản phẩm đã chọn', Icons.shopping_bag_outlined),
                        _buildProductsCard(selectedItems),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Chi tiết thanh toán', Icons.receipt_long_outlined),
                        _buildPaymentSummaryCard(orderProvider, preview),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Phương thức thanh toán', Icons.payments_outlined),
                        _buildPaymentMethodsCard(),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomBar(orderProvider, preview),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primaryPink),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: _primaryPink.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildChooseAddressCard(bool hasNoAddress) {
    return InkWell(
      onTap: _showAddressPicker,
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      child: _buildCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_location_alt_outlined, color: _primaryPink),
            const SizedBox(width: 8),
            Text(
              hasNoAddress ? 'Bạn chưa có địa chỉ nhận hàng' : 'Chọn địa chỉ nhận hàng',
              style: const TextStyle(
                color: _primaryPink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    return InkWell(
      onTap: _showAddressPicker,
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      child: _buildCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(color: _softPink, shape: BoxShape.circle),
              child: const Icon(Icons.location_on_rounded, color: _primaryPink),
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
                          address.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        address.phone,
                        style: const TextStyle(color: _textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address.formattedAddress,
                    style: const TextStyle(color: _textMuted, height: 1.35),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard(List<CartItemModel> items) {
    return _buildCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: items.isEmpty
          ? const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('Chưa chọn sản phẩm nào', style: TextStyle(color: _textMuted)),
        ),
      )
          : Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            _buildCheckoutItem(items[index]),
            if (index != items.length - 1)
              Divider(height: 1, color: _primaryPink.withOpacity(0.10)),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckoutItem(CartItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.large),
            child: Container(
              width: 68,
              height: 68,
              color: _softPink,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.image_not_supported_outlined, color: _textMuted),
              )
                  : const Icon(Icons.shopping_bag_outlined, color: _primaryPink),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                    height: 1.25,
                  ),
                ),
                if (item.variantName != null && item.variantName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _softPink,
                      borderRadius: BorderRadius.circular(AppRadius.circle),
                    ),
                    child: Text(
                      item.variantName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _primaryPink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currencyFormat.format(item.price),
                        style: const TextStyle(
                          color: _primaryPink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        color: _textMuted,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildPaymentSummaryCard(OrderProvider provider, OrderPreview? preview) {
    return _buildCard(
      child: provider.isLoading && preview == null
          ? const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator(color: _primaryPink)),
      )
          : Column(
        children: [
          _buildPriceRow('Tổng tiền hàng', preview?.subtotal ?? 0),
          _buildPriceRow('Phí vận chuyển', preview?.shippingFee ?? 0),
          Divider(height: 22, color: _primaryPink.withOpacity(0.14)),
          _buildPriceRow('Tổng thanh toán', preview?.total ?? 0, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return _buildCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _buildPaymentOption(
            value: 'COD',
            title: 'Thanh toán khi nhận hàng',
            subtitle: 'Trả tiền mặt khi đơn được giao đến bạn.',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            value: 'VNPAY',
            title: 'VNPAY QR',
            subtitle: 'Quét QR hoặc mở link thanh toán VNPAY.',
            icon: Icons.qr_code_2_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.large),
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _softPink : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(
            color: isSelected ? _primaryPink.withOpacity(0.55) : Colors.black.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(icon, color: isSelected ? _primaryPink : _textMuted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _textMuted, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? _primaryPink : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(OrderProvider provider, OrderPreview? preview) {
    final isLoading = provider.isLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview != null ? currencyFormat.format(preview.total) : '---',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _primaryPink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPink,
                  disabledBackgroundColor: _primaryPink.withOpacity(0.35),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  'Đặt hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? _textDark : _textMuted,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              color: isTotal ? _primaryPink : _textDark,
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAddressBox() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Bạn chưa có địa chỉ nào.', style: TextStyle(color: _textMuted)),
      ),
    );
  }
}
