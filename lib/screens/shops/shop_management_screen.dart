import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/shop_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import 'seller_product_list_screen.dart';
import 'shop_register_screen.dart';
import 'shop_detail_screen.dart';
import 'seller_order_list_screen.dart';

// Widgets cho địa chỉ và bản đồ
import '../../widgets/vietnam_address_selector.dart';
import '../../widgets/osm_location_picker.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({Key? key}) : super(key: key);

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  // =========================
  // Màu dùng chung theo format Soft Pink Card UI
  // =========================
  static const Color _primaryPink = Color(0xFFFF5C8A);
  static const Color _softPink = Color(0xFFFFEEF4);
  static const Color _lighterPink = Color(0xFFFFF7FA);
  static const Color _borderPink = Color(0xFFFFD8E4);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF707070);
  static const Color _dangerRed = Color(0xFFFF4D5E);

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

  // =========================
  //tải lại dữ liệu shop + sản phẩm của shop hiện tại
  // =========================
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
      return const Scaffold(
        backgroundColor: _lighterPink,
        body: Center(child: CircularProgressIndicator(color: _primaryPink)),
      );
    }

    // 2. Chưa có Shop -> Màn hình chào mừng
    if (myShop == null) {
      return _buildWelcomeScreen(context);
    }

    // 3. Dashboard Quản lý shop
    return Scaffold(
      backgroundColor: _lighterPink,
      appBar: AppBar(
        title: const Text(
          'Quản lý shop',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh_rounded, color: _primaryPink),
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
        color: _primaryPink,
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
              // Card thông tin shop theo format card hồng nhẹ
              _buildShopHeaderCard(context, shopProvider),
              const SizedBox(height: 16),

              // Card thống kê kinh doanh
              _buildBusinessStatsCard(myShop),
              const SizedBox(height: 16),

              // Menu chức năng quản lý shop
              _buildManagementMenu(shopProvider, myShop.stats.productCount, myShop.stats.orderCount),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // Màn hình chào mừng khi user chưa có shop
  // =========================
  Widget _buildWelcomeScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: _lighterPink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: _cardDecoration(radius: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCircleIcon(Icons.storefront_rounded, size: 86, iconSize: 44),
                  const SizedBox(height: 20),
                  const Text(
                    'Chào mừng bạn!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bạn chưa có cửa hàng nào. Hãy đăng ký ngay để bắt đầu kinh doanh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textGrey,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShopRegisterScreen()),
                      ),
                      icon: const Icon(Icons.add_business_rounded),
                      label: const Text('Đăng ký Shop ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
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

  // =========================
  // Card thông tin chính của shop: logo, tên, trạng thái, nút sửa
  // =========================
  Widget _buildShopHeaderCard(BuildContext context, ShopProvider shopProvider) {
    final myShop = shopProvider.shop!;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: myShop)),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(radius: 24),
        child: Row(
          children: [
            _buildShopLogo(myShop.logoUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shop của tôi',
                    style: TextStyle(
                      color: _primaryPink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    myShop.name,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(myShop.status),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Nút cây bút: mở sheet chỉnh sửa thông tin shop
            InkWell(
              onTap: () => _showEditShopSheet(context, shopProvider),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _softPink,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderPink),
                ),
                child: const Icon(Icons.edit_rounded, color: _primaryPink, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Card thống kê kết quả kinh doanh
  // =========================
  Widget _buildBusinessStatsCard(dynamic myShop) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          Row(
            children: [
              _buildCircleIcon(Icons.insights_rounded, size: 42, iconSize: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Kết quả kinh doanh',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: _textDark,
                  ),
                ),
              ),
              const Text(
                'Toàn thời gian',
                style: TextStyle(color: _textGrey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildDashboardStat('Đơn hàng', '${myShop.stats.orderCount}', Icons.shopping_bag_outlined)),
              _buildVerticalLine(),
              Expanded(child: _buildDashboardStat('Đánh giá', '${myShop.stats.ratingAvg.toStringAsFixed(1)} ⭐', Icons.star_outline_rounded)),
              _buildVerticalLine(),
              Expanded(child: _buildDashboardStat('Sản phẩm', '${myShop.stats.productCount}', Icons.inventory_2_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // Grid menu chức năng quản lý shop
  // =========================
  Widget _buildManagementMenu(ShopProvider shopProvider, int productCount, int orderCount) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.95,
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
              MaterialPageRoute(builder: (_) => const SellerProductListScreen()),
            );
          },
          badgeCount: productCount,
        ),
        _buildMenuItem(
          Icons.shopping_bag_outlined,
          'Đơn hàng',
              () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SellerOrderListScreen(),
              ),
            );
          },
          badgeCount: orderCount,
        ),
        _buildMenuItem(Icons.campaign_outlined, 'Marketing', () {}),
        _buildMenuItem(Icons.account_balance_wallet_outlined, 'Tài chính', () {}),
        _buildMenuItem(Icons.bar_chart_outlined, 'Phân tích', () {}),

        // Thiết lập Shop: chứa chức năng đóng/mở shop và xóa shop
        _buildMenuItem(Icons.settings_outlined, 'Thiết lập', () {
          _showSettingsOptions(context, shopProvider);
        }),
      ],
    );
  }

  // =========================
  // Item menu chức năng: icon tròn + label + badge số lượng
  // =========================
  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {int badgeCount = 0}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _cardDecoration(radius: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildCircleIcon(icon, size: 48, iconSize: 24),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _dangerRed,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Ô thống kê nhỏ trong dashboard
  // =========================
  Widget _buildDashboardStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _primaryPink, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: _primaryPink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _textGrey),
        ),
      ],
    );
  }

  Widget _buildVerticalLine() => Container(height: 42, width: 1, color: _borderPink);

  // =========================
  // BOTTOM SHEET: chỉnh sửa thông tin shop, ảnh, địa chỉ và bản đồ
  // =========================
  void _showEditShopSheet(BuildContext context, ShopProvider provider) {
    final shop = provider.shop!;
    final nameCtrl = TextEditingController(text: shop.name);
    final descCtrl = TextEditingController(text: shop.description);
    final phoneCtrl = TextEditingController(text: shop.phone);

    // Biến cho phần địa chỉ
    final addressCtrl = TextEditingController(text: shop.shopAddress ?? '');
    double? currentLat = shop.shopLat;
    double? currentLng = shop.shopLng;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder để update UI Map khi chọn địa chỉ mới
        builder: (context, setStateSheet) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Header sheet
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: _borderPink,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildCircleIcon(Icons.edit_rounded, size: 44, iconSize: 22),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Chỉnh sửa thông tin',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _textDark,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: _textGrey),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 18,
                      right: 18,
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Khu vực chọn ảnh bìa và logo
                        _buildImageEditArea(context, shop.coverUrl, shop.logoUrl),
                        const SizedBox(height: 54),

                        // Form thông tin cơ bản
                        _buildSheetSectionTitle(Icons.storefront_rounded, 'Thông tin cơ bản'),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: nameCtrl,
                          label: 'Tên cửa hàng',
                          icon: Icons.storefront_rounded,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: phoneCtrl,
                          label: 'Số điện thoại',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: descCtrl,
                          label: 'Mô tả shop',
                          icon: Icons.info_outline_rounded,
                          maxLines: 3,
                        ),

                        // Địa chỉ và bản đồ
                        const SizedBox(height: 24),
                        _buildSheetSectionTitle(Icons.location_on_rounded, 'Cập nhật địa chỉ'),
                        const SizedBox(height: 12),

                        // Selector chọn địa chỉ hành chính
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

                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: addressCtrl,
                          label: 'Địa chỉ chi tiết',
                          icon: Icons.place_outlined,
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Ghim vị trí trên bản đồ:',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Map giữ nguyên chức năng chọn tọa độ
                        SizedBox(
                          height: 360,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
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
                        if (currentLat != null && currentLng != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Toạ độ: ${currentLat!.toStringAsFixed(5)}, ${currentLng!.toStringAsFixed(5)}',
                              style: const TextStyle(fontSize: 12, color: _primaryPink),
                            ),
                          ),

                        // Nút lưu thay đổi
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
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
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Cập nhật thành công!')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Lỗi: $e'),
                                      backgroundColor: _dangerRed,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Lưu thay đổi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryPink,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
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

  // =========================
  // Khu vực ảnh bìa và logo trong sheet chỉnh sửa
  // =========================
  Widget _buildImageEditArea(BuildContext context, String? coverUrl, String? logoUrl) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Ảnh bìa
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chức năng chọn Ảnh Bìa (Cần tích hợp Upload API)')),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 150,
              width: double.infinity,
              color: _softPink,
              child: coverUrl != null
                  ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder('Đổi ảnh bìa'),
              )
                  : _buildImagePlaceholder('Đổi ảnh bìa'),
            ),
          ),
        ),

        // Logo shop đè lên ảnh bìa
        Positioned(
          bottom: -40,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng chọn Logo (Cần tích hợp Upload API)')),
              );
            },
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _softPink,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                image: logoUrl != null
                    ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: Stack(
                children: [
                  if (logoUrl == null)
                    const Center(
                      child: Icon(Icons.storefront_rounded, color: _primaryPink, size: 32),
                    ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: _primaryPink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_alt_rounded, color: _primaryPink),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(color: _primaryPink, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // =========================
  // Bottom sheet thiết lập shop: đóng/mở shop và xóa shop
  // =========================
  void _showSettingsOptions(BuildContext context, ShopProvider provider) {
    final shop = provider.shop!;
    final bool isShopOpen = shop.status == 'ACTIVE';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _borderPink,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _buildCircleIcon(Icons.settings_rounded, size: 46, iconSize: 23),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thiết lập cửa hàng',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _textDark,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Quản lý trạng thái hoạt động của shop.',
                              style: TextStyle(color: _textGrey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  Container(
                    decoration: BoxDecoration(
                      color: _lighterPink,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _borderPink),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        isShopOpen ? 'Cửa hàng đang mở' : 'Cửa hàng đang đóng',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: _textDark),
                      ),
                      subtitle: Text(
                        isShopOpen
                            ? 'Khách hàng có thể tìm thấy và mua hàng.'
                            : 'Cửa hàng sẽ bị ẩn khỏi danh sách tìm kiếm.',
                        style: const TextStyle(color: _textGrey),
                      ),
                      secondary: Icon(
                        isShopOpen ? Icons.storefront_rounded : Icons.store_mall_directory_outlined,
                        color: isShopOpen ? Colors.green : _textGrey,
                      ),
                      activeColor: Colors.green,
                      value: isShopOpen,
                      onChanged: (bool value) async {
                        Navigator.pop(ctx);
                        final newStatus = value ? 'ACTIVE' : 'SUSPENDED';

                        try {
                          await provider.service.update(shop.id, {'status': newStatus});
                          await provider.loadMyShop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(value ? 'Đã mở cửa hàng!' : 'Đã tạm đóng cửa hàng.')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $e'), backgroundColor: _dangerRed),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFCDD6)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: _dangerRed),
                      title: const Text(
                        'Xóa cửa hàng',
                        style: TextStyle(color: _dangerRed, fontWeight: FontWeight.w900),
                      ),
                      subtitle: const Text('Hành động này không thể hoàn tác.'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmDelete(context, provider);
                      },
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

  // =========================
  // LOGIC CŨ: xác nhận xóa shop
  // =========================
  void _confirmDelete(BuildContext context, ShopProvider shopProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Xác nhận xóa?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Toàn bộ sản phẩm, doanh thu và dữ liệu shop sẽ bị xóa vĩnh viễn. Bạn có chắc chắn không?',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Xóa ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    ) ??
        false;

    if (confirm) {
      await shopProvider.delete(shopProvider.shop!.id);
      if (shopProvider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(shopProvider.error!), backgroundColor: _dangerRed),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa cửa hàng thành công.')),
        );
      }
    }
  }

  // =========================
  // Helper: tiêu đề section trong bottom sheet
  // =========================
  Widget _buildSheetSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _primaryPink, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  // =========================
  // Helper: TextField đồng bộ style form hồng nhẹ
  // =========================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryPink),
        filled: true,
        fillColor: _lighterPink,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderPink),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderPink),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryPink, width: 1.4),
        ),
      ),
    );
  }

  // =========================
  // Helper: logo shop trên dashboard
  // =========================
  Widget _buildShopLogo(String? logoUrl) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _softPink,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        image: logoUrl != null
            ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
            : null,
      ),
      child: logoUrl == null
          ? const Icon(Icons.storefront_rounded, color: _primaryPink, size: 32)
          : null,
    );
  }

  // =========================
  // Helper: badge trạng thái shop
  // =========================
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'ACTIVE':
        bg = const Color(0xFFEAF8EF);
        text = Colors.green;
        label = 'Đang hoạt động';
        break;
      case 'SUSPENDED':
        bg = const Color(0xFFFFECEF);
        text = Colors.redAccent;
        label = 'Đang tạm nghỉ';
        break;
      case 'PENDING':
        bg = const Color(0xFFFFF4E5);
        text = Colors.orange;
        label = 'Chờ duyệt';
        break;
      default:
        bg = _softPink;
        text = _primaryPink;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =========================
  // Helper: icon tròn dùng chung
  // =========================
  Widget _buildCircleIcon(IconData icon, {double size = 54, double iconSize = 26}) {
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

  // =========================
  // Helper: decoration card dùng chung
  // =========================
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
}
