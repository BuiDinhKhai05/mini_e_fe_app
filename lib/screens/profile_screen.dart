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
  // =========================
  // 1. MÀU CHỦ ĐẠO CỦA GIAO DIỆN
  // =========================
  static const Color _primaryPink = Color(0xFFE84D7A);
  static const Color _unselectedPink = Color(0xFFC8A6B0);
  static const Color _textDark = Color(0xFF333333);
  static const Color _softPink = Color(0xFFFFF4F7);

  // Tránh gọi API fetchMe nhiều lần.
  bool _hasFetched = false;

  // Lưu menu đang được nhấn.
  // Chỉ dùng để đổi nền hồng trong lúc người dùng đang bấm giữ.
  String? _pressedMenu;

  // =========================
  // 2. HIỂN THỊ THÔNG BÁO
  // =========================
  void _showSnackBar(
      BuildContext context,
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _primaryPink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // =========================
  // 3. GỌI API LẤY THÔNG TIN USER HIỆN TẠI
  // =========================
  Future<void> _loadProfile(
      AuthProvider auth,
      UserProvider userProvider,
      ) async {
    if (_hasFetched) return;
    _hasFetched = true;

    if (auth.accessToken != null &&
        userProvider.me == null &&
        !userProvider.isLoading) {
      try {
        await userProvider.fetchMe();
      } catch (e) {
        if (mounted) {
          _showSnackBar(
            context,
            'Không tải được hồ sơ: $e',
            isError: true,
          );
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Gọi sau khi widget build xong để tránh lỗi setState trong lúc build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile(auth, userProvider);
    });
  }

  // =========================
  // 4. THẺ THÔNG TIN NGƯỜI DÙNG
  // =========================
  Widget _userInfoCard(dynamic currentUser) {
    final String name = currentUser.name ?? 'Người dùng';
    final String email = currentUser.email ?? 'email@example.com';

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softPink,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _primaryPink.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          // Avatar chữ cái đầu của tên user.
          CircleAvatar(
            radius: 28,
            backgroundColor: _primaryPink,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Tên và email của user.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _unselectedPink,
                    fontSize: 14,
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

  // =========================
  // 5. ITEM MENU DÙNG CHUNG
  // =========================
  Widget _menuTile({
    required String menuKey,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    // active chỉ true trong lúc người dùng đang nhấn giữ vào nút.
    final bool active = !isLogout && _pressedMenu == menuKey;

    final Color iconColor = isLogout
        ? Colors.red
        : active
        ? _primaryPink
        : _unselectedPink;

    final Color textColor = isLogout
        ? Colors.red
        : active
        ? _primaryPink
        : _textDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),

        // Khi bắt đầu nhấn thì hiện nền hồng.
        onTapDown: (_) {
          if (!isLogout) {
            setState(() {
              _pressedMenu = menuKey;
            });
          }
        },

        // Khi thả tay thì xóa nền hồng.
        onTapUp: (_) {
          if (!isLogout) {
            setState(() {
              _pressedMenu = null;
            });
          }
        },

        // Khi hủy thao tác nhấn thì cũng xóa nền hồng.
        onTapCancel: () {
          if (!isLogout) {
            setState(() {
              _pressedMenu = null;
            });
          }
        },

        // Khi bấm vào thì chạy chức năng cũ.
        onTap: () {
          if (!isLogout) {
            setState(() {
              _pressedMenu = null;
            });
          }

          onTap();
        },

        child: Container(
          height: 52,
          decoration: BoxDecoration(
            // Bình thường là trắng.
            // Chỉ trong lúc đang nhấn mới có nền hồng nhạt.
            color: active
                ? const Color(0xFFE84D7A).withOpacity(0.18)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              // Vạch hồng bên trái chỉ hiện trong lúc đang nhấn.
              Container(
                width: 4,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFE84D7A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(width: 14),

              // Icon menu.
              Icon(
                icon,
                size: 22,
                color: iconColor,
              ),

              const SizedBox(width: 16),

              // Tên menu.
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // 6. HÌNH TRANG TRÍ CUỐI MENU
  // =========================
  Widget _bottomDecoration() {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 18),
      child: Center(
        child: Image.asset(
          'assets/images/mochi/bunny_bear_original.png',
          height: 112,
          fit: BoxFit.contain,

          // Nếu chưa có ảnh trong assets thì hiện emoji tạm.
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 150,
              height: 112,
              decoration: BoxDecoration(
                color: _softPink,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text(
                  '🐰  🧸',
                  style: TextStyle(fontSize: 42),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================
  // 7. KHUNG MENU CHÍNH
  // =========================
  Widget _profileMenuCard(
      BuildContext context,
      AuthProvider auth,
      dynamic currentUser,
      ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _primaryPink.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Thông tin user.
          // Phần tiêu đề "Tài khoản của tôi" đã được xóa theo yêu cầu.
          _userInfoCard(currentUser),

          // trang chủ - giữ chức năng cũ là về Home.
          _menuTile(
            menuKey: 'overview',
            icon: Icons.grid_view_rounded,
            title: 'Trang chủ',
            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
          ),

          // Thông tin cá nhân.
          _menuTile(
            menuKey: 'personal-info',
            icon: Icons.person_outline,
            title: 'Thông tin cá nhân',
            onTap: () => Navigator.pushNamed(context, '/personal-info'),
          ),

          // Địa chỉ của tôi.
          _menuTile(
            menuKey: 'address',
            icon: Icons.location_on_outlined,
            title: 'Địa chỉ của tôi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressListScreen(),
                ),
              );
            },
          ),

          // Đơn hàng của tôi.
          _menuTile(
            menuKey: 'orders',
            icon: Icons.shopping_bag_outlined,
            title: 'Đơn hàng của tôi',
            onTap: () => Navigator.pushNamed(context, '/orders'),
          ),

          // Quản lý shop.
          _menuTile(
            menuKey: 'shop-management',
            icon: Icons.store_mall_directory_outlined,
            title: 'Quản lý shop',
            onTap: () => Navigator.pushNamed(context, '/shop-management'),
          ),

          // Ngân hàng.
          _menuTile(
            menuKey: 'bank',
            icon: Icons.account_balance_outlined,
            title: 'Ngân hàng',
            onTap: () {
              _showSnackBar(
                context,
                'Chức năng Ngân hàng sắp có!',
              );
            },
          ),

          // Cài đặt thông báo.
          _menuTile(
            menuKey: 'notification-setting',
            icon: Icons.notifications_outlined,
            title: 'Cài đặt thông báo',
            onTap: () {
              _showSnackBar(
                context,
                'Chức năng Cài đặt thông báo sắp có!',
              );
            },
          ),

          // Đổi mật khẩu.
          _menuTile(
            menuKey: 'change-password',
            icon: Icons.lock_outline,
            title: 'Đổi mật khẩu',
            onTap: () => Navigator.pushNamed(context, '/change-password'),
          ),

          // Đăng xuất.
          _menuTile(
            menuKey: 'logout',
            icon: Icons.logout,
            title: 'Đăng xuất',
            isLogout: true,
            onTap: () async {
              await auth.logout();

              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),

          // Hình trang trí phía dưới.
          _bottomDecoration(),
        ],
      ),
    );
  }

  // =========================
  // 8. BUILD GIAO DIỆN CHÍNH
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Màu nền chính vẫn là trắng.
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Consumer2<AuthProvider, UserProvider>(
          builder: (context, auth, userProvider, child) {
            final currentUser = userProvider.me ?? auth.user;

            // Nếu chưa đăng nhập thì chuyển về trang login.
            if (auth.accessToken == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              });

              return const Center(
                child: CircularProgressIndicator(
                  color: _primaryPink,
                ),
              );
            }

            // Loading khi đang lấy thông tin user.
            if (userProvider.isLoading && currentUser == null) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _primaryPink,
                ),
              );
            }

            // Trường hợp không có dữ liệu user.
            if (currentUser == null) {
              return const Center(
                child: Text(
                  'Không tải được thông tin người dùng',
                  style: TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            // Nội dung chính của màn hình profile.
            return SingleChildScrollView(
              child: _profileMenuCard(
                context,
                auth,
                currentUser,
              ),
            );
          },
        ),
      ),
    );
  }
}