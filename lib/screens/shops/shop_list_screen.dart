// lib/screens/shops/shop_list_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../models/shop_model.dart';
import '../../providers/shop_provider.dart';
import 'shop_detail_screen.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({Key? key}) : super(key: key);

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  String? _selectedStatus;

  // =========================
  // Màu dùng chung lấy từ lib/theme/app_theme.dart
  // =========================
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _lighterPink = AppColors.background;
  static const Color _borderPink = AppColors.borderPink;
  static const Color _textDark = AppColors.textDark;
  static const Color _textGrey = AppColors.textGrey;

  @override
  void initState() {
    super.initState();

    // Load danh sách shop lần đầu khi mở màn hình.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().fetchShops(limit: 20);
    });
  }

  // =========================
  // TÌM KIẾM SHOP
  // =========================
  String get _keyword => _searchController.text.trim();

  void _search({bool hideKeyboard = false}) {
    if (hideKeyboard) {
      FocusScope.of(context).unfocus();
    }

    context.read<ShopProvider>().searchShops(
      keyword: _keyword,
      status: _selectedStatus,
      limit: 20,
    );
  }

  // Debounce giúp không gọi API liên tục theo từng ký tự.
  // Sau khi người dùng ngừng gõ 450ms thì mới gọi API tìm kiếm.
  void _onKeywordChanged(String value) {
    setState(() {});

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      _search();
    });
  }

  void _clearKeyword() {
    if (_keyword.isEmpty) return;

    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {});
    _search();
  }

  void _clearAllFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _selectedStatus = null);
    context.read<ShopProvider>().clearShopSearch();
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
            // Header theo format hình mẫu.
            _buildHeaderCard(),
            const SizedBox(height: 14),

            // Thanh tìm kiếm + bộ lọc trạng thái.
            _buildSearchAndFilter(provider),
            const SizedBox(height: 16),

            // Nội dung danh sách shop.
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
                onRefresh: provider.refreshShops,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: provider.shops.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 14),
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
          _buildCircleIcon(
            Icons.store_mall_directory_rounded,
            size: 54,
            iconSize: 28,
          ),
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
  Widget _buildSearchAndFilter(ShopProvider provider) {
    final hasKeyword = _keyword.isNotEmpty;
    final hasFilter = hasKeyword || _selectedStatus != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _onKeywordChanged,
                  onSubmitted: (_) => _search(hideKeyboard: true),
                  decoration: _inputDecoration(
                    hintText: 'Tìm cửa hàng theo tên...',
                    icon: Icons.search_rounded,
                    suffixIcon: hasKeyword
                        ? IconButton(
                      onPressed: _clearKeyword,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _textGrey,
                      ),
                    )
                        : null,
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
                  child: DropdownButton<String?>(
                    value: _selectedStatus,
                    hint: const Icon(
                      Icons.tune_rounded,
                      color: _primaryPink,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _primaryPink,
                    ),
                    items: const [
                      DropdownMenuItem<String?>(value: null, child: Text('Tất cả')),
                      DropdownMenuItem<String?>(value: 'ACTIVE', child: Text('Hoạt động')),
                      DropdownMenuItem<String?>(value: 'PENDING', child: Text('Chờ duyệt')),
                      DropdownMenuItem<String?>(value: 'SUSPENDED', child: Text('Bị khóa')),
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

          // Hiển thị trạng thái tìm kiếm hiện tại để người dùng biết đang lọc theo gì.
          if (hasFilter) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (hasKeyword)
                  _buildFilterChip(
                    icon: Icons.search_rounded,
                    label: 'Từ khóa: $_keyword',
                    onDeleted: _clearKeyword,
                  ),
                if (_selectedStatus != null)
                  _buildFilterChip(
                    icon: Icons.tune_rounded,
                    label: 'Trạng thái: ${_statusLabel(_selectedStatus!)}',
                    onDeleted: () {
                      setState(() => _selectedStatus = null);
                      _search();
                    },
                  ),
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Xóa lọc'),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryPink,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],

          if (!provider.isLoading && provider.error == null) ...[
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Tìm thấy ${provider.shops.length} cửa hàng phù hợp'
                  : 'Đang hiển thị ${provider.shops.length} cửa hàng',
              style: const TextStyle(
                color: _textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
            // Ảnh bìa shop.
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
                  child: SizedBox(
                    height: 122,
                    width: double.infinity,
                    child: shop.coverUrl != null
                        ? Image.network(
                      shop.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildCoverPlaceholder(),
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

            // Thông tin shop.
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
                              label:
                              '${shop.stats.ratingAvg.toStringAsFixed(1)} | ${shop.stats.reviewCount} đánh giá',
                              iconColor: AppColors.warning,
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
        bg = AppColors.success.withOpacity(0.10);
        text = AppColors.success;
        label = 'Hoạt động';
        break;
      case 'PENDING':
        bg = AppColors.warning.withOpacity(0.12);
        text = AppColors.warning;
        label = 'Chờ duyệt';
        break;
      case 'SUSPENDED':
        bg = AppColors.error.withOpacity(0.10);
        text = AppColors.error;
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

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: _lighterPink,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _borderPink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primaryPink),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              label,
              style: const TextStyle(
                color: _textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(99),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 14, color: _textGrey),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Error state khi BE trả lỗi.
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
                  ? 'Chưa có quyền xem danh sách shop'
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
                  ? 'Nếu đây là màn cho user xem cửa hàng, backend cần mở API public cho GET /shops hoặc tạo API public search shop.'
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
    final hasKeyword = _keyword.isNotEmpty;

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(radius: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircleIcon(
              Icons.store_mall_directory_outlined,
              size: 76,
              iconSize: 38,
            ),
            const SizedBox(height: 16),
            Text(
              hasKeyword
                  ? 'Không tìm thấy shop phù hợp'
                  : 'Chưa tìm thấy shop nào',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasKeyword
                  ? 'Không có cửa hàng nào khớp với từ khóa "$_keyword".'
                  : 'Thử đổi từ khóa tìm kiếm hoặc bộ lọc nhé.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textGrey, height: 1.4),
            ),
            if (hasKeyword || _selectedStatus != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _clearAllFilters,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Xóa tìm kiếm'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryPink,
                  side: const BorderSide(color: _borderPink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================
  // Input decoration dùng cho ô tìm kiếm
  // =========================
  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: _primaryPink),
      suffixIcon: suffixIcon,
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

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Hoạt động';
      case 'PENDING':
        return 'Chờ duyệt';
      case 'SUSPENDED':
        return 'Bị khóa';
      default:
        return status;
    }
  }

  // =========================
  // Icon tròn dùng chung theo format mẫu
  // =========================
  Widget _buildCircleIcon(
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
