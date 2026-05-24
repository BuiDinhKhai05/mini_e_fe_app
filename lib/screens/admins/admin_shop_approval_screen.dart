// lib/screens/admin_shop_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';

import '../../models/shop_model.dart';
import '../../service/shop_service.dart';

class AdminShopApprovalScreen extends StatefulWidget {
  const AdminShopApprovalScreen({super.key});

  @override
  State<AdminShopApprovalScreen> createState() =>
      _AdminShopApprovalScreenState();
}

class _AdminShopApprovalScreenState extends State<AdminShopApprovalScreen> {
  late Future<List<ShopModel>> _pendingShops;

  @override
  void initState() {
    super.initState();
    _loadPendingShops();
  }

  void _loadPendingShops() {
    _pendingShops = ShopService().getShops(status: 'PENDING');
  }

  Future<void> _approveShop(int shopId) async {
    try {
      await ShopService().update(shopId, {'status': 'ACTIVE'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã duyệt shop!'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() => _loadPendingShops());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Duyệt Shop'),
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ShopModel>>(
        future: _pendingShops,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: AppTextStyles.bodyGrey,
                textAlign: TextAlign.center,
              ),
            );
          }

          final shops = snapshot.data ?? [];

          if (shops.isEmpty) {
            return const Center(
              child: Text(
                'Không có shop nào chờ duyệt',
                style: AppTextStyles.bodyGrey,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: shops.length,
            itemBuilder: (ctx, i) {
              final shop = shops[i];

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: AppDecorations.card,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.lightPink,
                    child: Text(
                      shop.name.isNotEmpty ? shop.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    shop.name,
                    style: AppTextStyles.titleSmall,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      shop.email ?? 'Chưa có email',
                      style: AppTextStyles.bodyGrey,
                    ),
                  ),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Duyệt'),
                    onPressed: () => _approveShop(shop.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
