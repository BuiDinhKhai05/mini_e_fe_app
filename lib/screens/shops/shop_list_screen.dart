// lib/screens/shops/shop_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shop_provider.dart';
import '../../models/shop_model.dart';
import 'shop_detail_screen.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({Key? key}) : super(key: key);

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;

  // =========================
  // Màu dùng chung theo format Soft Pink Card UI
  // =========================
  static const Color _primaryPink = Color(0xFFFF5C8A);
  static const Color _softPink = Color(0xFFFFEEF4);
  static const Color _lighterPink = Color(0xFFFFF7FA);
  static const Color _borderPink = Color(0xFFFFD8E4);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF707070);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().fetchShops();
    });
  }

  // =========================
  // LOGIC CŨ: tìm kiếm shop theo keyword và trạng thái
  // =========================
  void _search() {
    context.read<ShopProvider>().fetchShops(
      q: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      status: _selectedStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShopProvider>();

    return Scaffold(
      backgroundColor: _lighterPink,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        title: const Text(
          'Khám phá cửa hàng',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header theo format hình mẫu
            _buildHeaderCard(),
            const SizedBox(height: 14),

            // Thanh tìm kiếm + bộ lọc trạng thái
            _buildSearchAndFilter(),
            const SizedBox(height: 16),

            // Nội dung danh sách shop
            Expanded(
              child: provider.isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: _primaryPink),
              )
                  : provider.error != null
                  ? _buildErrorState(provider.error!)
                  : provider.shops.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                color: _primaryPink,
                onRefresh: () async => _search(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: provider.shops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, index) => _buildShopCard(
                    context,
                    provider.shops[index],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Header đầu trang: icon tròn + tiêu đề + mô tả
  // =========================
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Row(
        children: [
          _buildCircleIcon(Icons.store_mall_directory_rounded, size: 54, iconSize: 28),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danh sách shop',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tìm kiếm và xem thông tin cửa hàng yêu thích 💗',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textGrey,
                    height: 1.35,
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
  // Ô tìm kiếm + dropdown filter
  // =========================
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(radius: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: _inputDecoration(
                hintText: 'Tìm kiếm shop...',
                icon: Icons.search_rounded,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _softPink,
              border: Border.all(color: _borderPink),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                hint: const Icon(Icons.tune_rounded, color: _primaryPink),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primaryPink),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Hoạt động')),
                  DropdownMenuItem(value: 'PENDING', child: Text('Chờ duyệt')),
                  DropdownMenuItem(value: 'SUSPENDED', child: Text('Bị khóa')),
                ],
                onChanged: (val) {
                  setState(() => _selectedStatus = val);
                  _search();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Card shop: giữ nguyên chức năng nhấn để xem chi tiết shop
  // =========================
  Widget _buildShopCard(BuildContext context, ShopModel shop) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: _cardDecoration(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa shop
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SizedBox(
                    height: 122,
                    width: double.infinity,
                    child: shop.coverUrl != null
                        ? Image.network(
                      shop.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                    )
                        : _buildCoverPlaceholder(),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildStatusBadge(shop.status),
                ),
              ],
            ),

            // Thông tin shop
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShopLogo(shop),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: _textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(
                              icon: Icons.star_rounded,
                              label: '${shop.stats.ratingAvg.toStringAsFixed(1)} | ${shop.stats.reviewCount} đánh giá',
                              iconColor: Colors.orange,
                            ),
                            if (shop.phone != null)
                              _buildInfoChip(
                                icon: Icons.phone_outlined,
                                label: shop.phone!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: _primaryPink),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Placeholder ảnh bìa nếu shop chưa có ảnh
  // =========================
  Widget _buildCoverPlaceholder() {
    return Container(
      color: _softPink,
      child: const Center(
        child: Icon(Icons.storefront_rounded, color: _primaryPink, size: 42),
      ),
    );
  }

  // =========================
  // Logo shop dạng tròn
  // =========================
  Widget _buildShopLogo(ShopModel shop) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: _softPink,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
          ? const Icon(Icons.storefront_rounded, color: _primaryPink, size: 28)
          : null,
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
        label = 'Hoạt động';
        break;
      case 'PENDING':
        bg = const Color(0xFFFFF4E5);
        text = Colors.orange;
        label = 'Chờ duyệt';
        break;
      case 'SUSPENDED':
        bg = const Color(0xFFFFECEF);
        text = Colors.redAccent;
        label = 'Bị khóa';
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
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =========================
  // Chip thông tin nhỏ trong card shop
  // =========================
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color iconColor = _primaryPink,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _lighterPink,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _borderPink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Error state khi BE trả lỗi. Lưu ý BE hiện tại chỉ cho ADMIN gọi GET /shops.
  // =========================
  Widget _buildErrorState(String error) {
    final bool isPermissionError = error.contains('403') ||
        error.toLowerCase().contains('forbidden') ||
        error.contains('quyền');

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(radius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircleIcon(Icons.lock_outline_rounded, size: 76, iconSize: 38),
            const SizedBox(height: 16),
            Text(
              isPermissionError
                  ? 'Chỉ ADMIN được xem danh sách shop'
                  : 'Không tải được danh sách shop',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPermissionError
                  ? 'Backend hiện tại đặt GET /shops cho ADMIN. User thường chỉ có thể xem shop qua /shops/:id nếu shop ACTIVE.'
                  : error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textGrey, height: 1.4),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _search,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Empty state khi không tìm thấy shop
  // =========================
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(radius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircleIcon(Icons.store_mall_directory_outlined, size: 76, iconSize: 38),
            const SizedBox(height: 16),
            const Text(
              'Chưa tìm thấy shop nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thử đổi từ khóa tìm kiếm hoặc bộ lọc nhé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textGrey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Input decoration dùng cho ô tìm kiếm
  // =========================
  InputDecoration _inputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: _primaryPink),
      filled: true,
      fillColor: _lighterPink,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
    );
  }

  // =========================
  // Icon tròn dùng chung theo format mẫu
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
