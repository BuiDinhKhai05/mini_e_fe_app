// lib/screens/admins/admin_users_screen.dart
import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';

import '../../service/api_client.dart';
import '../../utils/app_constants.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> allUsers = []; // dữ liệu gốc trả về từ API cho trang hiện tại
  List<dynamic> users = []; // dữ liệu hiển thị (sau lọc client-side)
  bool isLoading = true;
  bool showDeleted = false;
  String searchQuery = '';

  // phân trang
  int page = 1;
  int limit = 20;
  int total = 0;
  int pageCount = 1;

  // bộ lọc role (client-side)
  String selectedRole = 'ALL'; // ALL / ADMIN / SELLER / USER

  // trạng thái đang thao tác trên 1 user (để disable nút khi thao tác)
  Set<int> busyUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final api = ApiClient();
      final endpoint = showDeleted ? UsersApi.deletedAll : UsersApi.users;

      final response = await api.get(
        endpoint,
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (searchQuery.isNotEmpty) 'search': searchQuery,
          // NOTE: chúng ta không gửi role => lọc client-side
        },
      );

      final data = response.data['data'];
      final items = data['items'] as List<dynamic>? ?? [];
      final meta = data['meta'] as Map<String, dynamic>? ?? {};

      setState(() {
        allUsers = items;
        total = meta['total'] ?? 0;
        pageCount = meta['pageCount'] ?? 1;
        // áp dụng lọc client-side theo role
        _applyRoleFilter();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh sách: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _applyRoleFilter() {
    if (selectedRole == 'ALL') {
      users = List.from(allUsers);
    } else {
      users = allUsers
          .where((u) => (u['role'] ?? '').toString() == selectedRole)
          .toList();
    }
  }

  Future<void> _changeRole(int userId, String newRole) async {
    setState(() => busyUserIds.add(userId));

    try {
      await ApiClient().patch(
        UsersApi.byId(userId.toString()),
        data: {'role': newRole},
      );

      // cập nhật local (nếu user có trong allUsers)
      final idx = allUsers.indexWhere((e) => e['id'] == userId);

      if (idx != -1) {
        allUsers[idx]['role'] = newRole;
        _applyRoleFilter();
      } else {
        // reload nếu không tìm thấy
        await _loadUsers();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đổi vai trò thành $newRole'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đổi vai trò: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => busyUserIds.remove(userId));
    }
  }

  Future<void> _toggleBlock(int userId, bool currentlyDeleted) async {
    setState(() => busyUserIds.add(userId));

    try {
      if (currentlyDeleted) {
        await ApiClient().post(UsersApi.restore(userId.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã mở khóa tài khoản'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        await ApiClient().delete(UsersApi.byId(userId.toString()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã khóa tài khoản'),
            backgroundColor: AppColors.warning,
          ),
        );
      }

      // refresh lại trang hiện tại
      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => busyUserIds.remove(userId));
    }
  }

  void _onSearchSubmitted(String value) {
    searchQuery = value.trim();
    page = 1;
    _loadUsers();
  }

  void _onRoleChanged(String? newRole) {
    if (newRole == null) return;

    setState(() {
      selectedRole = newRole;
      _applyRoleFilter();
    });
  }

  void _goToDetail(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserDetailScreen(userId: userId),
      ),
    ).then((_) {
      // khi quay về có thể refresh
      _loadUsers();
    });
  }

  void _prevPage() {
    if (page > 1) {
      setState(() => page -= 1);
      _loadUsers();
    }
  }

  void _nextPage() {
    if (page < pageCount) {
      setState(() => page += 1);
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý Người dùng'),
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(showDeleted ? Icons.lock_open : Icons.lock),
            color: Colors.white,
            tooltip: showDeleted
                ? 'Đang xem tài khoản đã khóa'
                : 'Xem tài khoản đã khóa',
            onPressed: () {
              setState(() {
                showDeleted = !showDeleted;
                page = 1;
              });
              _loadUsers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPink,
              ),
            )
                : users.isEmpty
                ? Center(
              child: Text(
                showDeleted
                    ? 'Không có tài khoản nào bị khóa'
                    : 'Chưa có người dùng nào',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                final int uid = u['id'] as int;
                final bool isDeleted = u['deletedAt'] != null;
                final busy = busyUserIds.contains(uid);

                return _buildUserCard(
                  user: u,
                  userId: uid,
                  isDeleted: isDeleted,
                  busy: busy,
                );
              },
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm tên, email, số điện thoại...',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: _onSearchSubmitted,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'USER', child: Text('USER')),
                  DropdownMenuItem(value: 'SELLER', child: Text('SELLER')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                ],
                onChanged: _onRoleChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard({
    required dynamic user,
    required int userId,
    required bool isDeleted,
    required bool busy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDeleted ? AppColors.borderGrey.withOpacity(0.45) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: AppShadows.softShadow,
      ),
      child: ListTile(
        onTap: () => _goToDetail(userId),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: CircleAvatar(
          backgroundColor: AppColors.lightPink,
          child: Text(
            _initial(user['name']),
            style: const TextStyle(
              color: AppColors.primaryPink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user['name'] ?? '---',
          style: AppTextStyles.titleSmall,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user['email'] ?? '', style: AppTextStyles.bodyGrey),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _roleChip(user['role']),
                  if (isDeleted)
                    _statusChip(
                      label: 'ĐÃ KHÓA',
                      color: AppColors.error,
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: busy
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryPink,
                  ),
                )
                    : Icon(isDeleted ? Icons.lock_open : Icons.lock),
                color: isDeleted ? AppColors.success : AppColors.error,
                tooltip: isDeleted ? 'Mở khóa' : 'Khóa',
                onPressed: busy ? null : () => _toggleBlock(userId, isDeleted),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textGrey,
                ),
                onSelected: (value) async {
                  if (value == 'DETAIL') {
                    _goToDetail(userId);
                  } else if (value == 'ADMIN' ||
                      value == 'SELLER' ||
                      value == 'USER') {
                    await _changeRole(userId, value);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'DETAIL', child: Text('Xem chi tiết')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'ADMIN', child: Text('Đặt làm ADMIN')),
                  PopupMenuItem(value: 'SELLER', child: Text('Đặt làm SELLER')),
                  PopupMenuItem(value: 'USER', child: Text('Đặt làm USER')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderGrey),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Tổng: $total',
            style: AppTextStyles.bodyGrey.copyWith(fontSize: 14),
          ),
          const Spacer(),
          IconButton(
            onPressed: page > 1 && !isLoading ? _prevPage : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            'Trang $page / $pageCount',
            style: AppTextStyles.body,
          ),
          IconButton(
            onPressed: page < pageCount && !isLoading ? _nextPage : null,
            icon: const Icon(Icons.chevron_right),
          ),
          const SizedBox(width: AppSpacing.sm),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: limit,
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 20, child: Text('20')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  limit = v;
                  page = 1;
                });
                _loadUsers();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(dynamic role) {
    final roleText = (role ?? '').toString();
    return _statusChip(
      label: roleText.isEmpty ? 'UNKNOWN' : roleText,
      color: _roleColor(roleText),
    );
  }

  Widget _statusChip({
    required String label,
    required Color color,
  }) {
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
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
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
