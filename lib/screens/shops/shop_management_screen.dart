import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/shop_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import 'seller_product_list_screen.dart';
import 'shop_register_screen.dart';
import 'shop_detail_screen.dart';

// --- IMPORTS CHO ADDRESS ---
import '../../widgets/vietnam_address_selector.dart';
import '../../widgets/osm_location_picker.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({Key? key}) : super(key: key);

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _reloadManagementData(
        clearProductsFirst: true,
        showLoading: true,
      );
    });
  }

  Future<void> _reloadManagementData({
    bool clearProductsFirst = true,
    bool showLoading = true,
  }) async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final shopProvider = context.read<ShopProvider>();
    final productProvider = context.read<ProductProvider>();

    if (auth.accessToken == null || auth.accessToken!.isEmpty) {
      productProvider.clearProductsCache(notify: false);
      shopProvider.clearShopData(notify: false);
      return;
    }

    if (clearProductsFirst) {
      productProvider.clearProductsCache(notify: false);
    }

    await shopProvider.loadMyShop();

    if (!mounted) return;

    if (shopProvider.shop != null) {
      await productProvider.fetchAllProductsForSeller(showLoading: showLoading);
    } else {
      productProvider.clearProductsCache(notify: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final myShop = shopProvider.shop;

    // 1. Loading
    if (shopProvider.isLoading && myShop == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Chưa có Shop -> Màn hình chào mừng
    if (myShop == null) {
      return _buildWelcomeScreen(context);
    }

    // 3. Dashboard Quản lý
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text('Quản lý shop', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () async {
              await _reloadManagementData(
                clearProductsFirst: true,
                showLoading: true,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _reloadManagementData(
            clearProductsFirst: true,
            showLoading: false,
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // --- CARD THÔNG TIN SHOP (HEADER) ---
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShopDetailScreen(shop: myShop),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0D6EFD), Color(0xFF4B94FF)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(
                            image: myShop.logoUrl != null
                                ? NetworkImage(myShop.logoUrl!)
                                : const NetworkImage('https://via.placeholder.com/150') as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              myShop.name,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                                  child: Text(
                                    myShop.status == 'ACTIVE' ? 'Đang hoạt động' : (myShop.status == 'SUSPENDED' ? 'Đang tạm nghỉ' : 'Chờ duyệt'),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      // Nút Cây Bút: Sửa thông tin
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _showEditShopSheet(context, shopProvider),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- THỐNG KÊ ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kết quả kinh doanh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Toàn thời gian', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDashboardStat('Đơn hàng', '${myShop.stats.orderCount}', Colors.blue),
                        _buildVerticalLine(),
                        _buildDashboardStat('Đánh giá', '${myShop.stats.ratingAvg.toStringAsFixed(1)} ⭐', Colors.orange),
                        _buildVerticalLine(),
                        _buildDashboardStat('Sản phẩm', '${myShop.stats.productCount}', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- MENU CHỨC NĂNG ---
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildMenuItem(
                    Icons.inventory_2_outlined,
                    'Sản phẩm',
                        () async {
                      await _reloadManagementData(
                        clearProductsFirst: true,
                        showLoading: true,
                      );

                      if (!mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SellerProductListScreen(),
                        ),
                      );
                    },
                    badgeCount: myShop.stats.productCount,
                  ),
                  _buildMenuItem(Icons.shopping_bag_outlined, 'Đơn hàng', () {}, badgeCount: myShop.stats.orderCount),
                  _buildMenuItem(Icons.campaign_outlined, 'Marketing', () {}),
                  _buildMenuItem(Icons.account_balance_wallet_outlined, 'Tài chính', () {}),
                  _buildMenuItem(Icons.bar_chart_outlined, 'Phân tích', () {}),

                  // Nút Thiết lập Shop: Chứa chức năng Đóng cửa & Xóa shop
                  _buildMenuItem(Icons.settings_outlined, 'Thiết lập Shop', () {
                    _showSettingsOptions(context, shopProvider);
                  }),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== WIDGETS CON ====================

  Widget _buildWelcomeScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront, size: 100, color: Colors.blue[100]),
            const SizedBox(height: 32),
            const Text('Chào mừng bạn!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Bạn chưa có cửa hàng nào. Hãy đăng ký ngay để bắt đầu kinh doanh.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopRegisterScreen())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Đăng ký Shop ngay'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {int badgeCount = 0}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 30, color: const Color(0xFF0D6EFD)),
                if (badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildVerticalLine() => Container(height: 30, width: 1, color: Colors.grey[200]);

  // ==================== LOGIC & DIALOGS ====================

  // 1. EDIT SHOP SHEET (Cây bút: Sửa thông tin & Chọn ảnh & ĐỊA CHỈ)
  void _showEditShopSheet(BuildContext context, ShopProvider provider) {
    final shop = provider.shop!;
    final nameCtrl = TextEditingController(text: shop.name);
    final descCtrl = TextEditingController(text: shop.description);
    final phoneCtrl = TextEditingController(text: shop.phone);

    // --- Biến cho phần Address ---
    final addressCtrl = TextEditingController(text: shop.shopAddress ?? '');
    double? currentLat = shop.shopLat;
    double? currentLng = shop.shopLng;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        // Dùng StatefulBuilder để update UI Map khi chọn địa chỉ mới
        builder: (context, setStateSheet) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header Sheet
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chỉnh sửa thông tin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- KHU VỰC CHỌN ẢNH ---
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // 1. Ảnh Bìa
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng chọn Ảnh Bìa (Cần tích hợp Upload API)')));
                              },
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: shop.coverUrl != null
                                    ? Image.network(shop.coverUrl!, fit: BoxFit.cover)
                                    : const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.camera_alt), Text('Đổi ảnh bìa')])),
                              ),
                            ),
                            // 2. Logo
                            Positioned(
                              bottom: -40,
                              child: GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng chọn Logo (Cần tích hợp Upload API)')));
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                      image: DecorationImage(
                                          image: shop.logoUrl != null ? NetworkImage(shop.logoUrl!) : const NetworkImage('https://via.placeholder.com/150') as ImageProvider,
                                          fit: BoxFit.cover
                                      )
                                  ),
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Color(0xFF0D6EFD), shape: BoxShape.circle),
                                      child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 50), // Khoảng trống cho Logo đè lên

                        // --- FORM TEXT ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              TextField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(labelText: 'Tên cửa hàng', border: OutlineInputBorder(), prefixIcon: Icon(Icons.store)),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: descCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(labelText: 'Mô tả shop', border: OutlineInputBorder(), prefixIcon: Icon(Icons.info_outline)),
                              ),

                              // --- PHẦN ĐỊA CHỈ & MAP ---
                              const SizedBox(height: 24),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Cập nhật địa chỉ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              const SizedBox(height: 12),

                              // 1. Selector chọn địa chỉ hành chính
                              VietnamAddressSelector(
                                onAddressChanged: (addr) {
                                  addressCtrl.text = addr;
                                },
                                onCoordinatesChanged: (lat, lng) {
                                  if (lat != null && lng != null) {
                                    setStateSheet(() {
                                      currentLat = lat;
                                      currentLng = lng;
                                    });
                                  }
                                },
                              ),

                              const SizedBox(height: 8),
                              TextField(
                                controller: addressCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Địa chỉ chi tiết',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on),
                                ),
                              ),

                              const SizedBox(height: 16),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Ghim vị trí trên bản đồ:', style: TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              const SizedBox(height: 8),

                              // 2. Widget Map -> Tăng height lên 400 để tránh lỗi RenderFlex
                              SizedBox(
                                height: 400, // <--- SỬA LỖI Ở ĐÂY (Cũ là 250)
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: OsmLocationPicker(
                                    initLat: currentLat,
                                    initLng: currentLng,
                                    onPicked: (lat, lng) {
                                      setStateSheet(() {
                                        currentLat = lat;
                                        currentLng = lng;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              if (currentLat != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('Toạ độ: ${currentLat!.toStringAsFixed(5)}, ${currentLng!.toStringAsFixed(5)}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ),

                              // --- NÚT SAVE ---
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final Map<String, dynamic> updateData = {
                                      'name': nameCtrl.text.trim(),
                                      'description': descCtrl.text.trim(),
                                      'phone': phoneCtrl.text.trim(),
                                      'shopAddress': addressCtrl.text.trim(),
                                      'shopLat': currentLat,
                                      'shopLng': currentLng,
                                    };

                                    Navigator.pop(ctx);

                                    try {
                                      await provider.service.update(shop.id, updateData);
                                      await provider.loadMyShop();
                                      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
                                    } catch (e) {
                                      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD)),
                                  child: const Text('Lưu thay đổi'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 2. SETTINGS OPTIONS
  void _showSettingsOptions(BuildContext context, ShopProvider provider) {
    final shop = provider.shop!;
    final bool isShopOpen = shop.status == 'ACTIVE';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
            builder: (context, setStateSheet) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thiết lập Cửa hàng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Quản lý trạng thái hoạt động và tồn tại của shop.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                      child: SwitchListTile(
                        title: Text(isShopOpen ? 'Cửa hàng đang Mở' : 'Cửa hàng đang Đóng'),
                        subtitle: Text(isShopOpen
                            ? 'Khách hàng có thể tìm thấy và mua hàng.'
                            : 'Cửa hàng sẽ bị ẩn khỏi danh sách tìm kiếm (Tạm nghỉ).'),
                        secondary: Icon(isShopOpen ? Icons.store : Icons.store_mall_directory_outlined,
                            color: isShopOpen ? Colors.green : Colors.grey),
                        activeColor: Colors.green,
                        value: isShopOpen,
                        onChanged: (bool value) async {
                          Navigator.pop(ctx);
                          final newStatus = value ? 'ACTIVE' : 'SUSPENDED';

                          try {
                            await provider.service.update(shop.id, {'status': newStatus});
                            await provider.loadMyShop();
                            if(mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(value ? 'Đã mở cửa hàng!' : 'Đã tạm đóng cửa hàng.'))
                              );
                            }
                          } catch(e) {
                            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text('Xóa vĩnh viễn cửa hàng', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Hành động này không thể hoàn tác.'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _confirmDelete(context, provider);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ShopProvider shopProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa?'),
        content: const Text('Toàn bộ sản phẩm, doanh thu và dữ liệu shop sẽ bị xóa vĩnh viễn. Bạn có chắc chắn không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa ngay', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await shopProvider.delete(shopProvider.shop!.id);
      if (shopProvider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(shopProvider.error!)));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa cửa hàng thành công.')));
      }
    }
  }
}