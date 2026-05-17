import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import './address/address_list_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _hasFetched = false;

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _menuTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4F4F4F)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _loadProfile(AuthProvider auth, UserProvider userProvider) async {
    if (_hasFetched) return;
    _hasFetched = true;

    if (auth.accessToken != null && userProvider.me == null && !userProvider.isLoading) {
      try {
        await userProvider.fetchMe();
      } catch (e) {
        if (mounted) {
          _showSnackBar(context, 'Không tải được hồ sơ: $e', isError: true);
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // ✅ Gọi sau khi widget build xong để tránh lỗi “markNeedsBuild during build”
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile(auth, userProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Consumer2<AuthProvider, UserProvider>(
          builder: (context, auth, userProvider, child) {
            final currentUser = userProvider.me ?? auth.user;

            if (auth.accessToken == null) {
              Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
              return const Center(child: CircularProgressIndicator());
            }

            if (userProvider.isLoading && currentUser == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (currentUser == null) {
              return const Center(child: Text('Không tải được thông tin người dùng'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // AVATAR
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: const Color(0xFF0872FF),
                        child: Text(
                          currentUser.name?.isNotEmpty == true
                              ? currentUser.name![0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentUser.name ?? 'Người dùng',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.email ?? 'email@example.com',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // MENU
                  _menuTile(
                    context,
                    icon: Icons.home_outlined,
                    title: 'Trang chủ',
                    onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                  ),

                  _menuTile(
                    context,
                    icon: Icons.person_outline,
                    title: 'Thông tin cá nhân',
                    onTap: () => Navigator.pushNamed(context, '/personal-info'),
                  ),
                  _menuTile(
                    context,
                    icon: Icons.store_mall_directory_outlined,
                    title: 'Quản lý shop',
                    onTap: () => Navigator.pushNamed(context, '/shop-management'),
                  ),
                  _menuTile(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    title: 'Đơn mua',
                    onTap: () {
                      // Chuyển sang màn hình MyOrdersScreen
                      Navigator.pushNamed(context, '/orders');
                    },
                  ),
                  _menuTile(
                    context,
                    icon: Icons.account_balance,
                    title: 'Ngân hàng',
                    onTap: () => _showSnackBar(context, 'Chức năng Ngân hàng sắp có!'),
                  ),
                  _menuTile(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Địa chỉ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddressListScreen()),
                      );
                    },
                  ),
                  _menuTile(
                    context,
                    icon: Icons.lock_outline,
                    title: 'Đổi mật khẩu',
                    onTap: () => Navigator.pushNamed(context, '/change-password'),
                  ),
                  _menuTile(
                    context,
                    icon: Icons.notifications_outlined,
                    title: 'Cài đặt thông báo',
                    onTap: () => _showSnackBar(context, 'Chức năng Cài đặt thông báo sắp có!'),
                  ),


                  const SizedBox(height: 16),

                  // ĐĂNG XUẤT
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      await auth.logout();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
