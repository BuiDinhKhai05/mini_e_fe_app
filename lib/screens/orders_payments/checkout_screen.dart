import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Import các provider và model cần thiết
import '../../providers/order_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart'; // Để lấy token nếu cần fetch lại address
import '../../models/order_model.dart';
import '../../models/address_model.dart';
import '../../models/cart_model.dart';

class CheckoutScreen extends StatefulWidget {
  static const routeName = '/checkout';
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'COD';
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  // Biến lưu ID địa chỉ đang chọn
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    // Khởi tạo dữ liệu sau khi build xong frame đầu tiên
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  // Hàm khởi tạo: Chọn địa chỉ mặc định & Gọi Preview
  void _initData() {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Nếu chưa có địa chỉ, thử load lại
    if (addressProvider.addresses.isEmpty && authProvider.accessToken != null) {
      addressProvider.fetchAddresses(authProvider.accessToken!).then((_) {
        _setDefaultAddress();
      });
    } else {
      _setDefaultAddress();
    }
  }

  // Logic chọn địa chỉ mặc định ban đầu
  void _setDefaultAddress() {
    final addressProvider = Provider.of<AddressProvider>(context, listen: false);
    if (addressProvider.addresses.isNotEmpty) {
      // Tìm địa chỉ mặc định, nếu không có lấy cái đầu tiên
      final defaultAddr = addressProvider.addresses.firstWhere(
            (a) => a.isDefault,
        orElse: () => addressProvider.addresses.first,
      );

      setState(() {
        _selectedAddressId = defaultAddr.id;
      });

      // Sau khi có địa chỉ, gọi API tính phí ship
      _loadPreview();
    }
  }

  // Gọi API Preview để tính phí ship & tổng tiền
  void _loadPreview() {
    if (_selectedAddressId == null) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    // Lấy danh sách ID các sản phẩm ĐANG ĐƯỢC CHỌN (isSelected == true)
    // Lưu ý: Đảm bảo bạn đã thêm getter selectedCartItemIds vào CartProvider như hướng dẫn trước
    final itemIds = cartProvider.items
        .where((item) => item.isSelected)
        .map((item) => item.id)
        .toList();

    if (itemIds.isNotEmpty) {
      Provider.of<OrderProvider>(context, listen: false)
          .previewOrder(_selectedAddressId!, itemIds);
    }
  }

  // Hàm hiển thị Popup chọn địa chỉ khác
  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<AddressProvider>(
          builder: (context, addrProv, _) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Chọn địa chỉ nhận hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Divider(),
                  Expanded(
                    child: addrProv.addresses.isEmpty
                        ? const Center(child: Text("Bạn chưa có địa chỉ nào."))
                        : ListView.builder(
                      itemCount: addrProv.addresses.length,
                      itemBuilder: (context, index) {
                        final addr = addrProv.addresses[index];
                        final isSelected = addr.id == _selectedAddressId;
                        return ListTile(
                          leading: Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                          title: Text("${addr.fullName} | ${addr.phone}"),
                          subtitle: Text(addr.formattedAddress),
                          onTap: () {
                            setState(() {
                              _selectedAddressId = addr.id;
                            });
                            Navigator.pop(context); // Đóng modal
                            _loadPreview(); // Tính lại phí ship cho địa chỉ mới
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Chuyển sang màn hình quản lý địa chỉ để thêm mới
                          // Navigator.pushNamed(context, '/address-list');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Thêm địa chỉ mới"),
                      ),
                    ),
                  )
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

    // 1. Validate
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn địa chỉ nhận hàng'), backgroundColor: Colors.red));
      return;
    }

    final itemIds = cartProvider.items
        .where((item) => item.isSelected)
        .map((item) => item.id)
        .toList();

    if (itemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không có sản phẩm nào được chọn'), backgroundColor: Colors.red));
      return;
    }

    // 2. Gọi API tạo đơn
    final result = await orderProvider.placeOrder(
      addressId: _selectedAddressId!,
      itemIds: itemIds,
      paymentMethod: _paymentMethod,
      note: "Đặt hàng từ Mobile App",
    );

    // 3. Xử lý kết quả
    if (result != null) {
      final List orders = result['orders'] ?? [];
      final firstOrderId = orders.isNotEmpty ? orders[0]['id'] : '';
      final firstOrderCode = orders.isNotEmpty ? orders[0]['code'] : '';

      if (_paymentMethod == 'VNPAY' && result['qrInfo'] != null) {
        Navigator.pushNamed(context, '/payment-gateway', arguments: {
          'qrData': result['paymentQr'],
          'amount': double.tryParse(result['qrInfo']['amount'].toString()) ?? 0.0,
          'sessionCode': result['qrInfo']['code'],
          'orderIdToCheck': firstOrderId,
        });
      } else {
        // COD -> Xoá item đã mua trong cart local
        // cartProvider.clearSelectedItems(); // (Tuỳ chọn: Nếu muốn xoá ngay client)

        Navigator.pushReplacementNamed(context, '/payment-result', arguments: {
          'success': true,
          'message': 'Đặt hàng thành công! Vui lòng chuẩn bị tiền mặt.',
          'orderId': firstOrderCode
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.errorMessage ?? 'Đặt hàng thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Xác nhận đơn hàng", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer2<OrderProvider, CartProvider>(
        builder: (context, orderProv, cartProv, child) {
          final preview = orderProv.orderPreview;
          // Lấy danh sách sản phẩm thật từ CartProvider (chỉ lấy cái isSelected)
          final selectedItems = cartProv.items.where((e) => e.isSelected).toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. ĐỊA CHỈ NHẬN HÀNG (REAL DATA) ---
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text("Địa chỉ nhận hàng", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Consumer<AddressProvider>(
                        builder: (ctx, addrProv, _) {
                          // Tìm model địa chỉ dựa trên ID đang chọn
                          AddressModel? selectedAddress;
                          if (_selectedAddressId != null && addrProv.addresses.isNotEmpty) {
                            try {
                              selectedAddress = addrProv.addresses.firstWhere((a) => a.id == _selectedAddressId);
                            } catch (e) {
                              // Nếu ID không tồn tại (do xoá?), reset về null
                              _selectedAddressId = null;
                            }
                          }

                          if (selectedAddress == null) {
                            return InkWell(
                              onTap: () {
                                // Nếu chưa có địa chỉ thì dẫn đi tạo, nếu có rồi thì mở picker
                                if (addrProv.addresses.isEmpty) {
                                  // Navigator.pushNamed(context, '/address-list');
                                } else {
                                  _showAddressPicker();
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_location_alt, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text("Chọn địa chỉ nhận hàng", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            );
                          }

                          return InkWell(
                            onTap: _showAddressPicker, // Bấm vào để đổi địa chỉ
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3))
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on, color: Colors.red),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(selectedAddress.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            const Text(" | ", style: TextStyle(color: Colors.grey)),
                                            Text(selectedAddress.phone, style: const TextStyle(color: Colors.grey)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(selectedAddress.formattedAddress, style: const TextStyle(height: 1.3)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // --- 2. SẢN PHẨM (REAL DATA) ---
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text("Sản phẩm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: selectedItems.isEmpty
                            ? const Padding(padding: EdgeInsets.all(16), child: Center(child: Text("Chưa chọn sản phẩm nào")))
                            : Column(
                          children: selectedItems.map((item) {
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      // Ảnh sản phẩm
                                      Container(
                                        width: 60, height: 60,
                                        decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.grey.shade200)
                                        ),
                                        child: item.imageId != null
                                            ? Icon(Icons.shopping_bag, color: Colors.grey[400]) // Thay bằng Image.network nếu có URL
                                            : Icon(Icons.shopping_bag, color: Colors.grey[400]),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
                                            if (item.variantName != null)
                                              Text("Phân loại: ${item.variantName}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(currencyFormat.format(item.price), style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Text("x${item.quantity}", style: const TextStyle(fontSize: 13)),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Divider giữa các item, trừ item cuối
                                if (item != selectedItems.last) const Divider(height: 1),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- 3. CHI TIẾT THANH TOÁN (REAL DATA) ---
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text("Chi tiết thanh toán", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: orderProv.isLoading && preview == null
                            ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                            : Column(
                          children: [
                            _buildPriceRow("Tổng tiền hàng", preview?.subtotal ?? 0),
                            _buildPriceRow("Phí vận chuyển", preview?.shippingFee ?? 0),
                            const Divider(),
                            _buildPriceRow("Tổng thanh toán", preview?.total ?? 0, isTotal: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --- 4. PHƯƠNG THỨC THANH TOÁN ---
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text("Phương thức thanh toán", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            RadioListTile(
                              value: 'COD',
                              groupValue: _paymentMethod,
                              activeColor: Colors.blue,
                              onChanged: (v) => setState(() => _paymentMethod = v.toString()),
                              title: const Text("Thanh toán khi nhận hàng (COD)"),
                              secondary: const Icon(Icons.money, color: Colors.green),
                            ),
                            const Divider(height: 1),
                            RadioListTile(
                              value: 'VNPAY',
                              groupValue: _paymentMethod,
                              activeColor: Colors.blue,
                              onChanged: (v) => setState(() => _paymentMethod = v.toString()),
                              title: const Text("VNPAY QR"),
                              secondary: const Icon(Icons.qr_code_2, color: Colors.blue),
                              subtitle: Container(
                                padding: const EdgeInsets.only(top: 4),
                                child: const Text("Quét mã QR qua app ngân hàng", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // --- FOOTER ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Tổng thanh toán", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              preview != null ? currencyFormat.format(preview.total) : '---',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: orderProv.isLoading ? null : _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: orderProv.isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("ĐẶT HÀNG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
          )),
          Text(currencyFormat.format(amount), style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue : Colors.black
          )),
        ],
      ),
    );
  }
}