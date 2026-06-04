import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';

import '../../service/shop_service.dart';

class AdminShopDetailScreen extends StatefulWidget {
  final dynamic shop;

  const AdminShopDetailScreen({
    super.key,
    required this.shop,
  });

  @override
  State<AdminShopDetailScreen> createState() => _AdminShopDetailScreenState();
}

class _AdminShopDetailScreenState extends State<AdminShopDetailScreen> {
  bool _busy = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = _readString(() => widget.shop.status, fallback: '-');
  }

  T? _tryRead<T>(T? Function() getter) {
    try {
      return getter();
    } catch (_) {
      return null;
    }
  }

  String _readString(dynamic Function() getter, {String fallback = '-'}) {
    final value = _tryRead<dynamic>(() => getter());
    if (value == null) return fallback;

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  int? _readId() {
    return _tryRead<int>(() => widget.shop.id);
  }

  Future<void> _updateStatus(String newStatus) async {
    final shopId = _readId();

    if (shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy ID shop'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _busy = true);

    try {
      await ShopService().update(shopId, {
        'status': newStatus,
      });

      setState(() {
        _status = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật trạng thái shop thành $newStatus'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật shop: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'REJECTED':
      case 'BANNED':
        return AppColors.error;
      default:
        return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopId = _readId();
    final name = _readString(() => widget.shop.name, fallback: 'Shop');
    final email = _readString(() => widget.shop.email);
    final phone = _readString(() => widget.shop.phone);
    final address = _readString(() => widget.shop.address);
    final description = _readString(() => widget.shop.description);
    final ownerName = _readString(() => widget.shop.ownerName);
    final createdAt = _readString(() => widget.shop.createdAt);
    final updatedAt = _readString(() => widget.shop.updatedAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết shop'),
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: AppDecorations.card,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.lightPink,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'ID: ${shopId ?? '-'}',
                          style: AppTextStyles.bodyGrey,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(_status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(
                              AppRadius.circle,
                            ),
                          ),
                          child: Text(
                            _status,
                            style: TextStyle(
                              color: _statusColor(_status),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            _infoTile(
              icon: Icons.email_outlined,
              title: 'Email',
              value: email,
            ),
            _infoTile(
              icon: Icons.phone_outlined,
              title: 'Số điện thoại',
              value: phone,
            ),
            _infoTile(
              icon: Icons.location_on_outlined,
              title: 'Địa chỉ',
              value: address,
            ),
            _infoTile(
              icon: Icons.description_outlined,
              title: 'Mô tả',
              value: description,
            ),
            _infoTile(
              icon: Icons.person_outline,
              title: 'Chủ shop',
              value: ownerName,
            ),
            _infoTile(
              icon: Icons.calendar_today_outlined,
              title: 'Ngày tạo',
              value: createdAt,
            ),
            _infoTile(
              icon: Icons.update_outlined,
              title: 'Cập nhật gần nhất',
              value: updatedAt,
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              'Thao tác quản trị',
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),

            if (_busy)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryPink,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus('ACTIVE'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Duyệt / Mở hoạt động'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus('PENDING'),
                    icon: const Icon(Icons.hourglass_empty),
                    label: const Text('Đưa về chờ duyệt'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _updateStatus('BANNED'),
                    icon: const Icon(Icons.block),
                    label: const Text('Khóa shop'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyGrey,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}