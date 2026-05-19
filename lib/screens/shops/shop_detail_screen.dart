// lib/screens/shops/shop_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/shop_model.dart';
import '../../widgets/osm_location_picker.dart';

class ShopDetailScreen extends StatelessWidget {
  final ShopModel shop;

  const ShopDetailScreen({Key? key, required this.shop}) : super(key: key);

  // =========================
  // Màu dùng chung theo format Soft Pink Card UI
  // =========================
  static const Color _primaryPink = Color(0xFFFF5C8A);
  static const Color _softPink = Color(0xFFFFEEF4);
  static const Color _lighterPink = Color(0xFFFFF7FA);
  static const Color _borderPink = Color(0xFFFFD8E4);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF707070);

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
                _buildCircleIcon(Icons.location_on_rounded, size: 48, iconSize: 25),
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
          // =========================
          SliverAppBar(
            expandedHeight: 210,
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
                    icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
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
                  shop.coverUrl != null
                      ? Image.network(
                    shop.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                  )
                      : _buildCoverPlaceholder(),

                  // Lớp phủ gradient để chữ/nút trên ảnh dễ nhìn hơn
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _primaryPink.withOpacity(0.75),
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
          // =========================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Transform.translate(
                offset: const Offset(0, -22),
                child: Column(
                  children: [
                    _buildMainInfoCard(),
                    const SizedBox(height: 16),
                    _buildAboutAndContactCard(context),
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
        child: Icon(Icons.storefront_rounded, size: 70, color: _primaryPink),
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
                          label: '${shop.stats.ratingAvg.toStringAsFixed(1)} (${shop.stats.reviewCount} đánh giá)',
                          bg: const Color(0xFFFFF7E6),
                          color: Colors.orange,
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
              Expanded(child: _buildStatItem('Sản phẩm', '${shop.stats.productCount}')),
              _buildVerticalDivider(),
              Expanded(child: _buildStatItem('Đơn hàng', _formatKNumber(shop.stats.orderCount))),
              _buildVerticalDivider(),
              Expanded(child: _buildStatItem('Tham gia', '${shop.createdAt.year}')),
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
          if (shop.phone != null) _buildContactRow(Icons.phone_outlined, 'Hotline', shop.phone!),
          if (shop.email != null) _buildContactRow(Icons.email_outlined, 'Email', shop.email!),
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
                  style: const TextStyle(fontSize: 12, color: _textGrey),
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
          const Icon(Icons.place_outlined, size: 24, color: _primaryPink),
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
                child: const Icon(Icons.map_outlined, color: Colors.white, size: 22),
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
        image: shop.logoUrl != null
            ? DecorationImage(
          image: NetworkImage(shop.logoUrl!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: shop.logoUrl == null
          ? const Icon(Icons.storefront_rounded, color: _primaryPink, size: 30)
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
        bg = const Color(0xFFEAF8EF);
        text = Colors.green;
        label = 'Đang hoạt động';
        break;
      case 'PENDING':
        bg = const Color(0xFFFFF4E5);
        text = Colors.orange;
        label = 'Chờ duyệt';
        break;
      case 'SUSPENDED':
        bg = const Color(0xFFFFECEF);
        text = Colors.redAccent;
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
  static Widget _buildCircleIcon(IconData icon, {double size = 54, double iconSize = 26}) {
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
