// lib/screens/shops/shop_detail_screen.dart

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../providers/product_provider.dart';
import '../../widgets/osm_location_picker.dart';

class ShopDetailScreen extends StatefulWidget {
  final ShopModel shop;

  // =========================
  // Danh sách sản phẩm của shop
  // Dùng dynamic để giữ tương thích với dữ liệu được truyền từ màn trước.
  // Nếu màn trước không truyền products thì màn này sẽ tự gọi API theo shopId.
  // =========================
  final List<dynamic> products;

  const ShopDetailScreen({
    Key? key,
    required this.shop,
    this.products = const [],
  }) : super(key: key);

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  List<ProductModel> _loadedProducts = [];
  bool _isLoadingProducts = false;
  String? _productsError;

  ShopModel get shop => widget.shop;
  List<dynamic> get products => widget.products;

  // =========================
  // Danh sách sản phẩm thực sự dùng để hiển thị.
  // Ưu tiên: products truyền từ màn trước -> shop.products -> API theo shopId.
  // =========================
  List<dynamic> get _displayProducts {
    if (products.isNotEmpty) return products;
    if (shop.products != null && shop.products!.isNotEmpty) {
      return shop.products!;
    }
    if (_loadedProducts.isNotEmpty) return _loadedProducts;
    return const [];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductsIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant ShopDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shop.id != widget.shop.id) {
      _loadedProducts = [];
      _productsError = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProductsIfNeeded();
      });
    }
  }

  // =========================
  // Tự tải sản phẩm ACTIVE của shop khi màn trước không truyền products.
  // Cách này sửa lỗi mở từ ShopListScreen nhưng không thấy sản phẩm.
  // =========================
  Future<void> _loadProductsIfNeeded() async {
    if (!mounted) return;
    if (products.isNotEmpty) return;
    if (shop.products != null && shop.products!.isNotEmpty) return;

    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final fetchedProducts =
      await context.read<ProductProvider>().fetchProductsByShopId(shop.id);

      if (!mounted) return;
      setState(() {
        _loadedProducts = fetchedProducts;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productsError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  // =========================
  // Màu dùng chung lấy từ lib/theme/app_theme.dart
  // =========================
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _lighterPink = AppColors.background;
  static const Color _borderPink = AppColors.borderPink;
  static const Color _textDark = AppColors.textDark;
  static const Color _textGrey = AppColors.textGrey;

  // =========================
  // LOGIC CŨ: mở bản đồ xem vị trí shop
  // =========================
  void _openMap(BuildContext context) {
    if (shop.shopLat == null || shop.shopLng == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Thanh kéo nhỏ của bottom sheet
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: _borderPink,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),

            // Header vị trí shop
            Row(
              children: [
                _buildCircleIcon(
                  Icons.location_on_rounded,
                  size: 48,
                  iconSize: 25,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vị trí: ${shop.name}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        shop.shopAddress ?? 'Chưa cập nhật địa chỉ',
                        style: const TextStyle(
                          color: _textGrey,
                          fontSize: 12,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bản đồ OSM giữ nguyên chức năng cũ
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: OsmLocationPicker(
                  initLat: shop.shopLat,
                  initLng: shop.shopLng,
                  onPicked: (lat, lng) {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lighterPink,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // =========================
          // Header ảnh bìa của shop
          // Đã tăng chiều cao và bỏ kéo card âm lên ảnh để tránh bị cắt thông tin
          // =========================
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: _primaryPink,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.28),
                child: const BackButton(color: Colors.white),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.28),
                  child: IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  shop.coverUrl != null && shop.coverUrl!.isNotEmpty
                      ? Image.network(
                    shop.coverUrl!,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                  )
                      : _buildCoverPlaceholder(),

                  // Lớp phủ gradient để nút back/share dễ nhìn hơn
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.08),
                          _primaryPink.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // =========================
          // Nội dung chính của shop
          // Đã bỏ Transform.translate để thông tin không bị ảnh bìa cắt nữa
          // =========================
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: _lighterPink,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: Column(
                  children: [
                    _buildMainInfoCard(),
                    const SizedBox(height: 16),
                    _buildAboutAndContactCard(context),
                    const SizedBox(height: 16),

                    // Sản phẩm của shop hiển thị phía dưới phần giới thiệu
                    _buildShopProductsCard(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Placeholder khi shop chưa có ảnh bìa
  // =========================
  Widget _buildCoverPlaceholder() {
    return Container(
      color: _softPink,
      child: const Center(
        child: Icon(
          Icons.storefront_rounded,
          size: 70,
          color: _primaryPink,
        ),
      ),
    );
  }

  // =========================
  // Card thông tin chính: logo, tên shop, đánh giá, thống kê
  // =========================
  Widget _buildMainInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShopLogo(size: 66),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildSmallBadge(
                          icon: Icons.star_rounded,
                          label:
                          '${shop.stats.ratingAvg.toStringAsFixed(1)} (${shop.stats.reviewCount} đánh giá)',
                          bg: AppColors.warning.withOpacity(0.12),
                          color: AppColors.warning,
                        ),
                        _buildStatusBadge(shop.status),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: _borderPink),
          const SizedBox(height: 16),

          // Ba chỉ số giống format card sạch, gọn
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Sản phẩm',
                  '${shop.stats.productCount}',
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildStatItem(
                  'Đơn hàng',
                  _formatKNumber(shop.stats.orderCount),
                ),
              ),
              _buildVerticalDivider(),
              Expanded(
                child: _buildStatItem(
                  'Tham gia',
                  '${shop.createdAt.year}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // Card giới thiệu, liên hệ và địa chỉ
  // =========================
  Widget _buildAboutAndContactCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shop.description != null && shop.description!.isNotEmpty) ...[
            _buildSectionTitle(Icons.info_outline_rounded, 'Giới thiệu'),
            const SizedBox(height: 10),
            Text(
              shop.description!,
              style: const TextStyle(
                color: _textGrey,
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 22),
          ],

          _buildSectionTitle(Icons.support_agent_rounded, 'Thông tin liên hệ'),
          const SizedBox(height: 14),

          if (shop.phone != null && shop.phone!.isNotEmpty)
            _buildContactRow(Icons.phone_outlined, 'Hotline', shop.phone!),

          if (shop.email != null && shop.email!.isNotEmpty)
            _buildContactRow(Icons.email_outlined, 'Email', shop.email!),

          const SizedBox(height: 10),
          Container(height: 1, color: _borderPink),
          const SizedBox(height: 18),

          _buildSectionTitle(Icons.location_on_outlined, 'Địa chỉ'),
          const SizedBox(height: 12),
          _buildAddressWithMapBtn(context),
        ],
      ),
    );
  }

  // =========================
  // Card hiển thị sản phẩm của shop
  // =========================
  Widget _buildShopProductsCard(BuildContext context) {
    final displayProducts = _displayProducts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionTitle(
                Icons.shopping_bag_outlined,
                'Sản phẩm của shop',
              ),
              const Spacer(),
              Text(
                '${displayProducts.length} sản phẩm',
                style: const TextStyle(
                  fontSize: 12,
                  color: _textGrey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingProducts)
            _buildProductsLoading()
          else if (_productsError != null)
            _buildProductsError(context)
          else if (displayProducts.isEmpty)
              _buildEmptyProducts()
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) {
                  final product = displayProducts[index];
                  return _buildProductItem(product);
                },
              ),
        ],
      ),
    );
  }

  // =========================
  // Loading khi đang tự tải sản phẩm theo shopId
  // =========================
  Widget _buildProductsLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: _lighterPink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderPink),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              color: _primaryPink,
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Đang tải sản phẩm của shop...',
            style: TextStyle(
              fontSize: 13,
              color: _textGrey,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Lỗi khi không tải được sản phẩm theo shopId
  // =========================
  Widget _buildProductsError(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withOpacity(0.22)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 38,
            color: AppColors.error,
          ),
          const SizedBox(height: 10),
          const Text(
            'Không thể tải sản phẩm của shop',
            style: TextStyle(
              fontSize: 14,
              color: _textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _productsError ?? 'Vui lòng thử lại sau.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: _textGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadProductsIfNeeded,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryPink,
              side: const BorderSide(color: _primaryPink),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Trạng thái rỗng khi shop chưa có sản phẩm hoặc chưa truyền products
  // =========================
  Widget _buildEmptyProducts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        color: _lighterPink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderPink),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.inventory_2_outlined,
            size: 42,
            color: _primaryPink,
          ),
          SizedBox(height: 10),
          Text(
            'Shop chưa có sản phẩm hiển thị',
            style: TextStyle(
              fontSize: 14,
              color: _textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Khi có danh sách sản phẩm, chúng sẽ hiển thị tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _textGrey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Item sản phẩm nhỏ trong grid
  // Dùng dynamic để phù hợp nhiều kiểu ProductModel khác nhau
  // =========================
  Widget _buildProductItem(dynamic product) {
    final String name = _getProductName(product);
    final String? imageUrl = _getProductImage(product);
    final String price = _getProductPrice(product);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderPink),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: _softPink,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: _primaryPink,
                      size: 34,
                    ),
                  ),
                )
                    : const Center(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: _primaryPink,
                    size: 34,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: _primaryPink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Lấy tên sản phẩm linh hoạt theo nhiều kiểu model
  // =========================
  String _getProductName(dynamic product) {
    if (product is Map) {
      return '${product['name'] ?? product['productName'] ?? product['title'] ?? 'Sản phẩm'}';
    }

    try {
      final value = product.name;
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final value = product.productName;
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final value = product.title;
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    return 'Sản phẩm';
  }

  // =========================
  // Lấy ảnh sản phẩm linh hoạt
  // Hỗ trợ: imageUrl, thumbnailUrl, mainImageUrl, coverUrl, images[0]
  // =========================
  String? _getProductImage(dynamic product) {
    if (product is Map) {
      final dynamic image = product['imageUrl'] ??
          product['thumbnailUrl'] ??
          product['mainImageUrl'] ??
          product['coverUrl'];

      if (image != null && image.toString().isNotEmpty) {
        return image.toString();
      }

      final dynamic images = product['images'];
      if (images is List && images.isNotEmpty) {
        final firstImage = images.first;

        if (firstImage is String) {
          return firstImage;
        }

        if (firstImage is Map) {
          final dynamic url =
              firstImage['url'] ?? firstImage['imageUrl'] ?? firstImage['path'];
          if (url != null && url.toString().isNotEmpty) {
            return url.toString();
          }
        }
      }

      return null;
    }

    try {
      final value = product.imageUrl;
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final value = product.thumbnailUrl;
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final value = product.mainImageUrl;
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final value = product.coverUrl;
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final images = product.images;
      if (images is List && images.isNotEmpty) {
        final firstImage = images.first;

        if (firstImage is String) {
          return firstImage;
        }

        if (firstImage is Map) {
          final dynamic url =
              firstImage['url'] ?? firstImage['imageUrl'] ?? firstImage['path'];
          if (url != null && url.toString().isNotEmpty) {
            return url.toString();
          }
        }

        try {
          final value = firstImage.url;
          if (value != null && value.toString().isNotEmpty) {
            return value.toString();
          }
        } catch (_) {}

        try {
          final value = firstImage.imageUrl;
          if (value != null && value.toString().isNotEmpty) {
            return value.toString();
          }
        } catch (_) {}
      }
    } catch (_) {}

    return null;
  }

  // =========================
  // Lấy giá sản phẩm linh hoạt và thêm đuôi VND
  // =========================
  String _getProductPrice(dynamic product) {
    dynamic rawPrice;

    if (product is Map) {
      rawPrice = product['price'] ??
          product['minPrice'] ??
          product['basePrice'] ??
          product['salePrice'];
    } else {
      try {
        rawPrice = product.price;
      } catch (_) {}

      try {
        rawPrice ??= product.minPrice;
      } catch (_) {}

      try {
        rawPrice ??= product.basePrice;
      } catch (_) {}

      try {
        rawPrice ??= product.salePrice;
      } catch (_) {}
    }

    if (rawPrice == null) return 'Liên hệ';

    final num? priceNumber = rawPrice is num
        ? rawPrice
        : num.tryParse(rawPrice.toString());

    if (priceNumber == null) return '$rawPrice VND';

    return '${_formatMoney(priceNumber)} VND';
  }

  // =========================
  // Format tiền đơn giản: 1200000 -> 1.200.000
  // =========================
  String _formatMoney(num value) {
    final String text = value.round().toString();
    final RegExp reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return text.replaceAllMapped(reg, (_) => '.');
  }

  String _formatKNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  // =========================
  // Ô thống kê nhỏ trong card shop
  // =========================
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _primaryPink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =========================
  // Dòng liên hệ: icon nhỏ + label + value
  // =========================
  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCircleIcon(icon, size: 42, iconSize: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textGrey,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Địa chỉ + nút mở bản đồ nếu có toạ độ
  // =========================
  Widget _buildAddressWithMapBtn(BuildContext context) {
    final bool hasMap = shop.shopLat != null && shop.shopLng != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lighterPink,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderPink),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.place_outlined,
            size: 24,
            color: _primaryPink,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              shop.shopAddress ?? 'Chưa cập nhật',
              style: const TextStyle(
                fontSize: 14,
                color: _textDark,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hasMap)
            InkWell(
              onTap: () => _openMap(context),
              borderRadius: BorderRadius.circular(99),
              child: Container(
                margin: const EdgeInsets.only(left: 12),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primaryPink,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primaryPink.withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // Logo shop dạng tròn, có viền hồng nhạt
  // =========================
  Widget _buildShopLogo({double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _softPink,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        image: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(shop.logoUrl!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: shop.logoUrl == null || shop.logoUrl!.isEmpty
          ? const Icon(
        Icons.storefront_rounded,
        color: _primaryPink,
        size: 30,
      )
          : null,
    );
  }

  // =========================
  // Tiêu đề section trong card
  // =========================
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primaryPink),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  // =========================
  // Badge nhỏ dùng cho đánh giá
  // =========================
  Widget _buildSmallBadge({
    required IconData icon,
    required String label,
    required Color bg,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Badge trạng thái shop
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
      case 'PENDING':
        bg = AppColors.warning.withOpacity(0.12);
        text = AppColors.warning;
        label = 'Chờ duyệt';
        break;
      case 'SUSPENDED':
        bg = AppColors.error.withOpacity(0.10);
        text = AppColors.error;
        label = 'Đang tạm nghỉ';
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
          fontSize: 12,
          color: text,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =========================
  // Icon tròn dùng chung theo format mẫu
  // =========================
  static Widget _buildCircleIcon(
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
      child: Icon(
        icon,
        color: _primaryPink,
        size: iconSize,
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 32,
      width: 1,
      color: _borderPink,
    );
  }

  // =========================
  // Decoration card dùng chung: nền trắng + viền hồng + shadow nhẹ
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