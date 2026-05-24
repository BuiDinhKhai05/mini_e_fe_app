import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/shop_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/app_constants.dart';
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
  // Màu dùng chung lấy từ lib/theme/app_theme.dart
  // =========================
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _lighterPink = AppColors.background;
  static const Color _borderPink = AppColors.borderPink;
  static const Color _textDark = AppColors.textDark;
  static const Color _textGrey = AppColors.textGrey;
  static const Color _dangerRed = AppColors.error;

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

    final previousShopId = shopProvider.shop?.id;

    await shopProvider.loadMyShop();

    if (!mounted) return;

    if (shopProvider.shop != null) {
      // Không xóa cache nếu vẫn là cùng shop để các sản phẩm DRAFT vừa ẩn
      // không biến mất ngay trong phiên hiện tại. Nếu đổi sang shop khác thì
      // mới clear để tránh lẫn dữ liệu.
      if (clearProductsFirst &&
          previousShopId != null &&
          previousShopId != shopProvider.shop!.id) {
        productProvider.clearProductsCache(notify: false);
      }

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

    // BE GET /shops/:id hiện tại chỉ trả thông tin shop + stats,
    // không load relation products. Vì vậy khi xem "Shop của tôi",
    // lấy sản phẩm từ ProductProvider rồi truyền sang ShopDetailScreen.
    final productProvider = context.read<ProductProvider>();
    final shopProducts = productProvider.products
        .where((product) => product.shopId == myShop.id)
        .toList();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShopDetailScreen(
              shop: myShop,
              products: shopProducts,
            ),
          ),
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
    final emailCtrl = TextEditingController(text: shop.email ?? '');
    final descCtrl = TextEditingController(text: shop.description ?? '');
    final phoneCtrl = TextEditingController(text: shop.phone ?? '');

    // Biến cho phần địa chỉ
    final addressCtrl = TextEditingController(text: shop.shopAddress ?? '');
    double? currentLat = shop.shopLat;
    double? currentLng = shop.shopLng;

    // Biến local cho ảnh để cập nhật ngay trong bottom sheet sau khi upload.
    String? currentCoverUrl = shop.coverUrl;
    String? currentLogoUrl = shop.logoUrl;
    bool isUploadingImage = false;

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
                        _buildImageEditArea(
                          context,
                          currentCoverUrl,
                          currentLogoUrl,
                          isUploading: isUploadingImage,
                          onCoverTap: () async {
                            setStateSheet(() => isUploadingImage = true);
                            final success = await _pickAndUploadShopImage(
                              context,
                              provider,
                              isLogo: false,
                            );
                            if (!mounted) return;
                            setStateSheet(() {
                              isUploadingImage = false;
                              if (success) {
                                currentCoverUrl =
                                    provider.shop?.coverUrl ?? currentCoverUrl;
                              }
                            });
                          },
                          onLogoTap: () async {
                            setStateSheet(() => isUploadingImage = true);
                            final success = await _pickAndUploadShopImage(
                              context,
                              provider,
                              isLogo: true,
                            );
                            if (!mounted) return;
                            setStateSheet(() {
                              isUploadingImage = false;
                              if (success) {
                                currentLogoUrl =
                                    provider.shop?.logoUrl ?? currentLogoUrl;
                              }
                            });
                          },
                        ),
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
                          controller: emailCtrl,
                          label: 'Email liên hệ',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
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
                                'email': emailCtrl.text.trim(),
                                'description': descCtrl.text.trim(),

                                // Đồng bộ BE: UpdateShopDto nhận shopPhone,
                                // không nhận phone.
                                'shopPhone': phoneCtrl.text.trim(),
                                'shopAddress': addressCtrl.text.trim(),
                                'shopLat': currentLat,
                                'shopLng': currentLng,
                              };

                              Navigator.pop(ctx);

                              final success = await provider.update(shop.id, updateData);

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Cập nhật thành công!'
                                        : (provider.error ?? 'Cập nhật thất bại.'),
                                  ),
                                  backgroundColor: success ? AppColors.success : _dangerRed,
                                ),
                              );
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
  // Chọn ảnh từ thư viện và upload lên BE
  // BE: PATCH /shops/me/logo hoặc /shops/me/cover, multipart field: file
  // =========================
  Future<bool> _pickAndUploadShopImage(
      BuildContext context,
      ShopProvider provider, {
        required bool isLogo,
      }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (pickedFile == null) {
        return false;
      }

      final token = context.read<AuthProvider>().accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      }

      MultipartFile multipartFile;
      if (kIsWeb) {
        multipartFile = MultipartFile.fromBytes(
          await pickedFile.readAsBytes(),
          filename: pickedFile.name,
        );
      } else {
        multipartFile = await MultipartFile.fromFile(
          pickedFile.path,
          filename: pickedFile.name,
        );
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      await dio.patch(
        isLogo ? ShopsApi.uploadLogo : ShopsApi.uploadCover,
        data: FormData.fromMap({'file': multipartFile}),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Load lại shop để cập nhật logoUrl/coverUrl mới từ BE vào provider.
      await provider.loadMyShop();

      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLogo ? 'Cập nhật logo thành công.' : 'Cập nhật ảnh bìa thành công.',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Upload ảnh thất bại.';

      if (data is Map && data['message'] != null) {
        message = data['message'] is List
            ? (data['message'] as List).join('\n')
            : data['message'].toString();
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: _dangerRed),
        );
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: _dangerRed,
          ),
        );
      }
      return false;
    }
  }

  // =========================
  // Khu vực ảnh bìa và logo trong sheet chỉnh sửa
  // =========================
  Widget _buildImageEditArea(
      BuildContext context,
      String? coverUrl,
      String? logoUrl, {
        required bool isUploading,
        required VoidCallback onCoverTap,
        required VoidCallback onLogoTap,
      }) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Ảnh bìa
        GestureDetector(
          onTap: isUploading ? null : onCoverTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 150,
              width: double.infinity,
              color: _softPink,
              child: coverUrl != null && coverUrl.isNotEmpty
                  ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder('Đổi ảnh bìa'),
              )
                  : _buildImagePlaceholder('Đổi ảnh bìa'),
            ),
          ),
        ),

        // Lớp phủ loading khi đang upload logo hoặc ảnh bìa
        if (isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.58),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: _primaryPink,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),

        // Logo shop đè lên ảnh bìa
        Positioned(
          bottom: -40,
          child: GestureDetector(
            onTap: isUploading ? null : onLogoTap,
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
                image: logoUrl != null && logoUrl.isNotEmpty
                    ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: Stack(
                children: [
                  if (logoUrl == null || logoUrl.isEmpty)
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                          'Đồng bộ theo quyền BE hiện tại.',
                          style: TextStyle(color: _textGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // BE hiện tại không cho owner tự đổi status.
              // Controller sẽ chặn nếu USER/SELLER gửi field status.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _lighterPink,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _borderPink),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      shop.status == 'ACTIVE'
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      color: shop.status == 'ACTIVE' ? AppColors.success : _primaryPink,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trạng thái shop do ADMIN quản lý',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Trạng thái hiện tại: ${_statusText(shop.status)}. '
                                'Theo BE hiện tại, chủ shop chỉ được cập nhật hồ sơ/ảnh, '
                                'không được tự chuyển ACTIVE/SUSPENDED.',
                            style: const TextStyle(
                              color: _textGrey,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.error.withOpacity(0.22)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: _dangerRed),
                  title: const Text(
                    'Xóa cửa hàng',
                    style: TextStyle(color: _dangerRed, fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'BE sẽ xóa shop và xóa cứng toàn bộ sản phẩm thuộc shop.',
                  ),
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
      final success = await shopProvider.delete(shopProvider.shop!.id);

      if (!mounted) return;

      if (success) {
        context.read<ProductProvider>().clearProductsCache(notify: false);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã xóa cửa hàng thành công.'
                : (shopProvider.error ?? 'Xóa cửa hàng thất bại.'),
          ),
          backgroundColor: success ? AppColors.success : _dangerRed,
        ),
      );
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

  String _statusText(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Đang hoạt động';
      case 'PENDING':
        return 'Chờ duyệt';
      case 'SUSPENDED':
        return 'Đang tạm nghỉ';
      default:
        return status;
    }
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
        bg = AppColors.success.withOpacity(0.10);
        text = AppColors.success;
        label = 'Đang hoạt động';
        break;
      case 'SUSPENDED':
        bg = AppColors.error.withOpacity(0.10);
        text = AppColors.error;
        label = 'Đang tạm nghỉ';
        break;
      case 'PENDING':
        bg = AppColors.warning.withOpacity(0.12);
        text = AppColors.warning;
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
