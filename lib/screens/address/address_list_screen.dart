import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/address_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/address_provider.dart';
import '../../theme/app_theme.dart';
import 'add_address_screen.dart';

class AddressListScreen extends StatefulWidget {
  final bool selectMode; // Chế độ chọn địa chỉ khi đặt hàng
  final int? initialSelectedId; // ID địa chỉ đang được chọn ban đầu

  const AddressListScreen({
    super.key,
    this.selectMode = false,
    this.initialSelectedId,
  });

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;

    // Sau khi màn hình dựng xong thì gọi API lấy danh sách địa chỉ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshList();
    });
  }

  // =========================
  // Load lại danh sách địa chỉ
  // =========================
  Future<void> _refreshList() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.accessToken != null) {
      await Provider.of<AddressProvider>(context, listen: false)
          .fetchAddresses(auth.accessToken!);
    }
  }

  // =========================
  // Điều hướng sang màn hình thêm địa chỉ mới
  // =========================
  Future<void> _openAddAddressScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    );
    _refreshList();
  }

  // =========================
  // Điều hướng sang màn hình sửa địa chỉ
  // =========================
  Future<void> _openEditAddressScreen(AddressModel address) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAddressScreen(address: address),
      ),
    );
    _refreshList();
  }

  // =========================
  // Xóa địa chỉ: giữ nguyên logic cũ, chỉ chỉnh giao diện dialog/snackbar
  // =========================
  Future<void> _deleteAddress(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xóa địa chỉ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Bạn có chắc chắn muốn xóa địa chỉ này không?'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      try {
        await Provider.of<AddressProvider>(context, listen: false)
            .deleteAddress(auth.accessToken!, id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa địa chỉ thành công')),
        );

        // Nếu địa chỉ đang được chọn bị xóa thì bỏ trạng thái chọn
        if (_selectedId == id) setState(() => _selectedId = null);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // =========================
  // Đặt địa chỉ mặc định
  // closeSheet = true khi gọi từ bottom sheet chi tiết
  // =========================
  Future<void> _setAsDefault(int id, {bool closeSheet = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<AddressProvider>(context, listen: false);

    try {
      await provider.updateAddress(auth.accessToken!, id, {'isDefault': true});
      await _refreshList();

      if (!mounted) return;
      if (closeSheet) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đặt làm địa chỉ mặc định')),
      );
    } catch (e) {
      if (!mounted) return;
      if (closeSheet) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // =========================
  // Hiển thị bottom sheet chi tiết địa chỉ
  // =========================
  void _showAddressDetail(AddressModel addr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                top: 18,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.borderPink,
                        borderRadius: BorderRadius.circular(AppRadius.circle),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tiêu đề bottom sheet
                  Row(
                    children: [
                      _buildCircleIcon(
                        icon: Icons.location_on_rounded,
                        size: 46,
                        iconSize: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Thông tin địa chỉ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (addr.isDefault) _buildDefaultBadge(),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _buildDetailRow(Icons.person_rounded, 'Người nhận', addr.fullName),
                  _buildDetailRow(Icons.phone_rounded, 'Số điện thoại', addr.phone),
                  _buildDetailRow(
                    Icons.place_rounded,
                    'Địa chỉ',
                    addr.formattedAddress,
                  ),
                  if (addr.lat != null && addr.lng != null)
                    _buildDetailRow(
                      Icons.my_location_rounded,
                      'Tọa độ',
                      '${addr.lat!.toStringAsFixed(6)}, ${addr.lng!.toStringAsFixed(6)}',
                    ),

                  const SizedBox(height: 22),

                  // Nút đặt mặc định trong phần chi tiết
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: addr.isDefault ? AppColors.borderGrey : AppColors.primaryPink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.large),
                        ),
                      ),
                      onPressed: addr.isDefault
                          ? null
                          : () => _setAsDefault(addr.id, closeSheet: true),
                      icon: Icon(
                        addr.isDefault
                            ? Icons.check_circle_rounded
                            : Icons.star_border_rounded,
                      ),
                      label: Text(addr.isDefault ? 'Đã là mặc định' : 'Đặt làm mặc định'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.large),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================
  // Header giống format hình mẫu
  // =========================
  Widget _buildHeader(String title) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderPink),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.primaryPink,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          _buildCircleIcon(
            icon: Icons.location_on_rounded,
            size: 54,
            iconSize: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.selectMode
                      ? 'Chọn địa chỉ giao hàng của bạn 💗'
                      : 'Quản lý địa chỉ giao hàng của bạn 💗',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _openAddAddressScreen,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Thêm',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Card địa chỉ giống style hình mẫu
  // =========================
  Widget _buildAddressCard(AddressModel addr, bool isPicked) {
    final hasCoordinates = addr.lat != null && addr.lng != null;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      onTap: () {
        if (widget.selectMode) {
          setState(() => _selectedId = addr.id);
          Navigator.pop(context, addr); // Trả địa chỉ đã chọn về màn hình trước
        } else {
          _showAddressDetail(addr);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
          border: Border.all(
            color: isPicked || addr.isDefault ? AppColors.primaryPink.withOpacity(0.45) : AppColors.borderPink,
            width: isPicked ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPink.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nhãn mặc định nằm trên card như hình mẫu
            if (addr.isDefault)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDefaultBadge(),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.selectMode) ...[
                  Icon(
                    isPicked
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isPicked ? AppColors.primaryPink : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 10),
                ],

                // Icon tròn bên trái giống hình mẫu
                _buildCircleIcon(
                  icon: addr.isDefault
                      ? Icons.home_rounded
                      : Icons.location_city_rounded,
                  size: 58,
                  iconSize: 30,
                ),
                const SizedBox(width: 14),

                // Nội dung địa chỉ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              addr.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (addr.isDefault)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Text(
                                'Mặc định',
                                style: TextStyle(
                                  color: AppColors.primaryPink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildInfoLine(Icons.phone_rounded, addr.phone),
                      const SizedBox(height: 7),
                      _buildInfoLine(
                        Icons.place_outlined,
                        addr.formattedAddress,
                        maxLines: 2,
                      ),
                      if (hasCoordinates) ...[
                        const SizedBox(height: 7),
                        Text(
                          'Tọa độ: ${addr.lat!.toStringAsFixed(6)}, ${addr.lng!.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: AppColors.primaryPink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Chế độ chọn địa chỉ thì ẩn sửa/xóa để giao diện gọn hơn
            if (!widget.selectMode) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: AppColors.borderPink.withOpacity(0.8)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  _buildCardActionButton(
                    icon: addr.isDefault
                        ? Icons.check_circle_outline_rounded
                        : Icons.star_border_rounded,
                    label: addr.isDefault ? 'Mặc định' : 'Đặt mặc định',
                    color: AppColors.primaryPink,
                    isDisabled: addr.isDefault,
                    onTap: () => _setAsDefault(addr.id),
                  ),
                  _buildCardActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Sửa',
                    color: AppColors.textDark,
                    onTap: () => _openEditAddressScreen(addr),
                  ),
                  _buildCardActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Xóa',
                    color: AppColors.error,
                    onTap: () => _deleteAddress(addr.id),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================
  // Dòng thông tin nhỏ trong card
  // =========================
  Widget _buildInfoLine(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // Nút thao tác nhỏ: đặt mặc định, sửa, xóa
  // =========================
  Widget _buildCardActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDisabled ? AppColors.textGrey : color,
        side: BorderSide(
          color: isDisabled ? AppColors.borderPink : color.withOpacity(0.28),
        ),
        backgroundColor: isDisabled ? AppColors.background : Colors.white,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      onPressed: isDisabled ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  // =========================
  // Icon tròn màu hồng dùng ở header và card
  // =========================
  Widget _buildCircleIcon({
    required IconData icon,
    required double size,
    required double iconSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.lightPink,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primaryPink, size: iconSize),
    );
  }

  // =========================
  // Badge mặc định
  // =========================
  Widget _buildDefaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryPink,
        borderRadius: BorderRadius.circular(AppRadius.circle),
      ),
      child: const Text(
        'Mặc định',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // =========================
  // Dòng thông tin trong bottom sheet
  // =========================
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderPink),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryPink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: AppColors.textDark,
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
  // Giao diện khi đang load dữ liệu
  // =========================
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryPink),
    );
  }

  // =========================
  // Giao diện khi chưa có địa chỉ nào
  // =========================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCircleIcon(
              icon: Icons.location_off_rounded,
              size: 74,
              iconSize: 36,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có địa chỉ nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thêm địa chỉ giao hàng để đặt hàng nhanh hơn nhé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
              ),
              onPressed: _openAddAddressScreen,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm địa chỉ mới'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.selectMode ? 'Chọn địa chỉ' : 'Địa chỉ của tôi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(title),
            Expanded(
              child: Consumer<AddressProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.addresses.isEmpty) {
                    return _buildLoadingState();
                  }

                  if (provider.addresses.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    color: AppColors.primaryPink,
                    onRefresh: _refreshList,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: provider.addresses.length,
                      itemBuilder: (ctx, i) {
                        final addr = provider.addresses[i];
                        final isPicked = _selectedId == addr.id;

                        return _buildAddressCard(addr, isPicked);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
