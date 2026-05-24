// lib/screens/admin/admin_shops_screen.dart
import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';

import '../../models/shop_model.dart';
import '../../service/shop_service.dart';

class AdminShopsScreen extends StatefulWidget {
  const AdminShopsScreen({super.key});

  @override
  State<AdminShopsScreen> createState() => _AdminShopsScreenState();
}

class _AdminShopsScreenState extends State<AdminShopsScreen> {
  String _filterStatus = 'ALL'; // ALL, PENDING, ACTIVE, REJECTED, BANNED
  late Future<List<ShopModel>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  void _loadShops() {
    if (_filterStatus == 'ALL') {
      _shopsFuture = ShopService().getShops(); // lấy tất cả
    } else {
      _shopsFuture = ShopService().getShops(status: _filterStatus);
    }
  }

  Future<void> _updateStatus(int shopId, String newStatus) async {
    try {
      await ShopService().update(shopId, {'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật trạng thái shop!'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() => _loadShops());
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
        title: const Text('Quản lý Shop'),
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: DropdownButtonFormField<String>(
              value: _filterStatus,
              decoration: InputDecoration(
                labelText: 'Lọc theo trạng thái',
                prefixIcon: const Icon(Icons.filter_alt_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
              items: [
                'ALL',
                'PENDING',
                'ACTIVE',
                'REJECTED',
                'BANNED',
              ]
                  .map(
                    (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s == 'ALL' ? 'Tất cả' : s),
                ),
              )
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _filterStatus = val!;
                  _loadShops();
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ShopModel>>(
              future: _shopsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryPink,
                    ),
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
                  return Center(
                    child: Text(
                      _filterStatus == 'ALL'
                          ? 'Chưa có shop nào'
                          : 'Không có shop nào ở trạng thái này',
                      style: AppTextStyles.bodyGrey,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  itemCount: shops.length,
                  itemBuilder: (_, i) {
                    final shop = shops[i];
                    final isPending = shop.status == 'PENDING';

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: AppDecorations.card,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.lightPink,
                          child: Text(
                            shop.name.isNotEmpty
                                ? shop.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primaryPink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(shop.name, style: AppTextStyles.titleSmall),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email: ${shop.email ?? 'Chưa có'}',
                                style: AppTextStyles.bodyGrey,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(shop.status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.circle,
                                  ),
                                ),
                                child: Text(
                                  'Trạng thái: ${shop.status}',
                                  style: TextStyle(
                                    color: _statusColor(shop.status),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: isPending
                            ? Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () =>
                                  _updateStatus(shop.id, 'ACTIVE'),
                              child: const Text('Duyệt'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(
                                  color: AppColors.error,
                                ),
                              ),
                              onPressed: () =>
                                  _updateStatus(shop.id, 'REJECTED'),
                              child: const Text('Từ chối'),
                            ),
                          ],
                        )
                            : PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.textGrey,
                          ),
                          onSelected: (val) =>
                              _updateStatus(shop.id, val),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'ACTIVE',
                              child: Text('Mở hoạt động'),
                            ),
                            PopupMenuItem(
                              value: 'BANNED',
                              child: Text('Khóa shop'),
                            ),
                            PopupMenuItem(
                              value: 'PENDING',
                              child: Text('Đưa về chờ duyệt'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'REJECTED':
        return AppColors.error;
      case 'BANNED':
        return AppColors.textGrey;
      default:
        return AppColors.textLight;
    }
  }
}
