// lib/screens/admins/admin_user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';

import '../../service/api_client.dart';
import '../../utils/app_constants.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final int userId;

  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  bool isLoading = true;
  Map<String, dynamic>? user;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => isLoading = true);
    try {
      final res = await ApiClient().get(
        UsersApi.byId(widget.userId.toString()),
      );
      setState(() {
        user = res.data['data'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải thông tin: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleBlock() async {
    if (user == null) return;

    setState(() => busy = true);
    final isDeleted = user!['deletedAt'] != null;

    try {
      if (isDeleted) {
        await ApiClient().post(UsersApi.restore(widget.userId.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã mở khóa'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        await ApiClient().delete(UsersApi.byId(widget.userId.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã khóa'),
            backgroundColor: AppColors.warning,
          ),
        );
      }

      await _loadDetail();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primaryPink),
      )
          : data == null
          ? const Center(
        child: Text(
          'Không tìm thấy người dùng',
          style: AppTextStyles.bodyGrey,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.card,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.lightPink,
                    backgroundImage: data['avatarUrl'] != null
                        ? NetworkImage(data['avatarUrl'].toString())
                        : null,
                    child: data['avatarUrl'] == null
                        ? Text(
                      _initial(data['name']),
                      style: const TextStyle(
                        color: AppColors.primaryPink,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? '',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          data['email'] ?? '',
                          style: AppTextStyles.bodyGrey,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _roleChip(data['role']),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: busy ? null : _toggleBlock,
                    icon: busy
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryPink,
                      ),
                    )
                        : Icon(
                      data['deletedAt'] != null
                          ? Icons.lock_open
                          : Icons.lock,
                    ),
                    color: data['deletedAt'] != null
                        ? AppColors.success
                        : AppColors.error,
                    tooltip: data['deletedAt'] != null
                        ? 'Mở khóa'
                        : 'Khóa',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _infoTile(
              icon: Icons.phone_outlined,
              title: 'Số điện thoại',
              value: data['phone'] ?? '-',
            ),
            _infoTile(
              icon: Icons.cake_outlined,
              title: 'Ngày sinh',
              value: data['birthday'] ?? '-',
            ),
            _infoTile(
              icon: Icons.wc_outlined,
              title: 'Giới tính',
              value: data['gender'] ?? '-',
            ),
            _infoTile(
              icon: Icons.verified_user_outlined,
              title: 'Đã xác thực email',
              value: (data['isVerified'] ?? false) ? 'Có' : 'Chưa',
            ),
            _infoTile(
              icon: Icons.calendar_today_outlined,
              title: 'Ngày tạo',
              value: data['createdAt'] ?? '-',
            ),
            if (data['deletedAt'] != null)
              _infoTile(
                icon: Icons.lock_clock_outlined,
                title: 'Ngày khóa',
                value: data['deletedAt'] ?? '-',
                valueColor: AppColors.error,
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
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: AppDecorations.card,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.lightPink,
          child: Icon(icon, color: AppColors.primaryPink),
        ),
        title: Text(title, style: AppTextStyles.titleSmall),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            value,
            style: AppTextStyles.bodyGrey.copyWith(
              color: valueColor ?? AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(dynamic role) {
    final roleText = (role ?? '').toString();
    final color = _roleColor(roleText);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.circle),
      ),
      child: Text(
        roleText.isEmpty ? 'UNKNOWN' : roleText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _initial(dynamic name) {
    final text = (name ?? 'U').toString().trim();
    return text.isEmpty ? 'U' : text[0].toUpperCase();
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return AppColors.primaryPink;
      case 'SELLER':
        return AppColors.success;
      case 'USER':
        return AppColors.info;
      default:
        return AppColors.textGrey;
    }
  }
}
