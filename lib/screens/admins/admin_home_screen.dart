// lib/screens/admins/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('TRANG QUẢN TRỊ'),
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
        actions: [
          // Chỉ giữ nút quay về app, bỏ nút đăng xuất để tránh chiếm chỗ trên AppBar.
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Vào app',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                _compactWelcomeCard(context),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        borderRadius: BorderRadius.circular(AppRadius.circle),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      'Chức năng quản trị',
                      style: AppTextStyles.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (isWide)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.lg,
                    mainAxisSpacing: AppSpacing.lg,
                    childAspectRatio: 3.1,
                    children: [
                      _adminActionCard(
                        context,
                        icon: Icons.storefront,
                        color: AppColors.success,
                        title: 'Quản lý Shop',
                        desc: 'Duyệt, khóa và xem chi tiết các shop',
                        route: '/admin/shops',
                      ),
                      _adminActionCard(
                        context,
                        icon: Icons.people,
                        color: AppColors.info,
                        title: 'Quản lý người dùng',
                        desc: 'Xem, sửa role, khóa hoặc mở khóa tài khoản',
                        route: '/admin/users',
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _adminActionCard(
                        context,
                        icon: Icons.storefront,
                        color: AppColors.success,
                        title: 'Quản lý Shop',
                        desc: 'Duyệt, khóa và xem chi tiết các shop',
                        route: '/admin/shops',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _adminActionCard(
                        context,
                        icon: Icons.people,
                        color: AppColors.info,
                        title: 'Quản lý người dùng',
                        desc: 'Xem, sửa role, khóa hoặc mở khóa tài khoản',
                        route: '/admin/users',
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _compactWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: AppColors.borderPink),
        boxShadow: AppShadows.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.lightPink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 34,
              color: AppColors.primaryPink,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng quản trị viên',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Quản lý shop, người dùng và các chức năng hệ thống.',
                  style: AppTextStyles.bodyGrey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminActionCard(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required String desc,
        required String route,
        bool clearStack = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: AppShadows.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.large),
          onTap: () {
            if (clearStack) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                route,
                    (route) => false,
              );
            } else {
              Navigator.pushNamed(context, route);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(color: color),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
