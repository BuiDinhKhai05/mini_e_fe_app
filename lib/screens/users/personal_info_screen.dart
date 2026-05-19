// lib/screens/personal_info_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import 'edit_personal_info_screen.dart';

// Import màn hình Shop - giữ nguyên chức năng cũ.
import '../shops/shop_register_screen.dart';
import '../shops/shop_management_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // =========================
  // 1. MÀU CHỦ ĐẠO CỦA GIAO DIỆN
  // =========================
  static const Color _primaryPink = Color(0xFFE84D7A);
  static const Color _softPink = Color(0xFFFFF4F7);
  static const Color _lightPink = Color(0xFFFCE3EC);
  static const Color _unselectedPink = Color(0xFFC8A6B0);
  static const Color _textDark = Color(0xFF333333);
  static const Color _textMuted = Color(0xFF8A7A80);

  // Biến này giúp tránh gọi API fetchMe liên tục khi màn hình build lại.
  bool _hasFetched = false;

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
  // 3. GỌI API LẤY THÔNG TIN USER
  // =========================
  Future<void> _loadProfile(
      AuthProvider auth,
      UserProvider userProvider, {
        bool forceRefresh = false,
      }) async {
    // Nếu không bắt buộc tải lại thì chỉ fetch một lần.
    if (_hasFetched && !forceRefresh) return;
    _hasFetched = true;

    if (auth.accessToken != null) {
      try {
        // Luôn fetch lại thông tin mới nhất để cập nhật profile/shop/role.
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
    } else {
      // Nếu chưa đăng nhập thì chuyển về màn hình login.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
    }
  }

  // =========================
  // 4. CHUYỂN SANG MÀN HÌNH CHỈNH SỬA
  // =========================
  Future<void> _openEditScreen(
      AuthProvider auth,
      UserProvider userProvider,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditPersonalInfoScreen(),
      ),
    );

    // Khi quay lại từ màn chỉnh sửa thì tải lại dữ liệu để hiển thị thông tin mới.
    if (mounted) {
      await _loadProfile(auth, userProvider, forceRefresh: true);
    }
  }

  // =========================
  // 5. FORMAT NGÀY SINH CHO DỄ NHÌN
  // =========================
  String _formatBirthday(String? birthday) {
    if (birthday == null || birthday.trim().isEmpty) {
      return 'Chưa cập nhật';
    }

    try {
      final date = DateTime.parse(birthday);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month/${date.year}';
    } catch (_) {
      // Nếu backend đã trả sẵn dạng dd/MM/yyyy thì giữ nguyên.
      return birthday;
    }
  }

  // =========================
  // 6. ĐỔI GIỚI TÍNH TỪ CODE SANG TEXT TIẾNG VIỆT
  // =========================
  String _formatGender(String? gender) {
    switch (gender) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      case 'OTHER':
        return 'Khác';
      default:
        return 'Chưa cập nhật';
    }
  }

  // =========================
  // 7. AVATAR BÊN TRÁI THEO FORMAT ẢNH MẪU
  // =========================
  Widget _buildAvatarPanel(dynamic currentUser) {
    final String name = currentUser.name ?? 'Người dùng';

    return SizedBox(
      width: 150,
      child: Column(
        children: [
          // Avatar chỉ dùng để hiển thị thông tin người dùng.
          // Nút "Đổi ảnh đại diện" và dòng "JPG, PNG tối đa 2MB" đã được bỏ theo yêu cầu.
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: _lightPink,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: _primaryPink,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // 8. MỘT DÒNG THÔNG TIN CÁ NHÂN
  // =========================
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: _textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),

          // Label của thông tin, ví dụ: Họ và tên, Email...
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Giá trị thông tin của user.
          Expanded(
            child: Text(
              value.isEmpty ? 'Chưa cập nhật' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: value.isEmpty ? _unselectedPink : _textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // 9. CỤM THÔNG TIN Ở GIỮA
  // =========================
  Widget _buildInfoPanel({
    required dynamic currentUser,
    required VoidCallback onEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header thông tin cá nhân.
        Row(
          children: [
            const Expanded(
              child: Text(
                'Thông tin cá nhân',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(
              height: 34,
            ),
          ],
        ),
        const SizedBox(height: 14),

        _buildInfoRow(
          icon: Icons.person_outline,
          label: 'Họ và tên',
          value: currentUser.name ?? '',
        ),
        _buildInfoRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: currentUser.email ?? '',
        ),
        _buildInfoRow(
          icon: Icons.phone_outlined,
          label: 'Số điện thoại',
          value: currentUser.phone ?? '',
        ),
        _buildInfoRow(
          icon: Icons.wc_outlined,
          label: 'Giới tính',
          value: _formatGender(currentUser.gender),
        ),
        _buildInfoRow(
          icon: Icons.calendar_month_outlined,
          label: 'Ngày sinh',
          value: _formatBirthday(currentUser.birthday),
        ),
        _editInfoButton(context),
      ],
    );
  }

  // =========================
  // NÚT CHỈNH SỬA THÔNG TIN
  // =========================
  Widget _editInfoButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Center(
        child: SizedBox(
          width: 210,
          height: 44,
          child: ElevatedButton.icon(
            // Khi bấm nút thì chuyển sang màn hình chỉnh sửa thông tin.
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditPersonalInfoScreen(),
                ),
              );
            },

            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
            ),

            label: const Text(
              'Chỉnh sửa thông tin',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE84D7A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // 10. HÌNH TRANG TRÍ BÊN PHẢI
  // =========================
  Widget _buildDecorationImage() {
    return SizedBox(
      width: 190,
      child: Center(
        child: Image.asset(
          // Bạn có thể thay bằng ảnh thỏ/gấu thật trong assets của app.
          'assets/images/mochi/bunny_bear_original.png',
          height: 160,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback để app không lỗi khi chưa thêm asset.
            return Container(
              width: 160,
              height: 140,
              decoration: BoxDecoration(
                color: _softPink,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Center(
                child: Text(
                  '🐰💗',
                  style: TextStyle(fontSize: 54),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // =========================
  // 11. CARD THÔNG TIN CÁ NHÂN
  // =========================
  Widget _buildPersonalInfoCard({
    required dynamic currentUser,
    required VoidCallback onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _primaryPink.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.06),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Giao diện rộng: avatar trái - thông tin giữa - hình trang trí phải.
          if (constraints.maxWidth >= 720) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatarPanel(currentUser),
                const SizedBox(width: 28),
                Expanded(
                  child: _buildInfoPanel(
                    currentUser: currentUser,
                    onEdit: onEdit,
                  ),
                ),
                const SizedBox(width: 20),
                _buildDecorationImage(),
              ],
            );
          }

          // Giao diện điện thoại: xếp dọc để không bị tràn màn hình.
          return Column(
            children: [
              _buildAvatarPanel(currentUser),
              const SizedBox(height: 26),
              _buildInfoPanel(
                currentUser: currentUser,
                onEdit: onEdit,
              ),
              const SizedBox(height: 24),
              _buildDecorationImage(),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // 12. CARD ĐĂNG KÝ / QUẢN LÝ SHOP
  // =========================
  Widget _buildShopCard({
    required bool hasShop,
    required AuthProvider auth,
    required UserProvider userProvider,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _primaryPink.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withOpacity(0.05),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (hasShop) {
              // Nếu user đã là seller/admin thì đi đến màn quản lý shop.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopManagementScreen(),
                ),
              );
            } else {
              // Nếu user chưa có shop thì đi đến màn đăng ký shop.
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopRegisterScreen(),
                ),
              ).then((_) {
                // Khi quay lại thì fetch lại để cập nhật role/shop.
                _loadProfile(auth, userProvider, forceRefresh: true);
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryPink.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasShop ? Icons.store_mall_directory : Icons.add_business,
                    color: _primaryPink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasShop ? 'Quản lý Shop' : 'Đăng ký Shop',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasShop
                            ? 'Quản lý sản phẩm, đơn hàng và doanh thu'
                            : 'Bắt đầu kinh doanh ngay hôm nay',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _unselectedPink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // 13. BUILD GIAO DIỆN CHÍNH
  // =========================
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, auth, userProvider, child) {
        // Load profile lần đầu sau khi frame hiện tại build xong.
        if (!_hasFetched) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadProfile(auth, userProvider);
          });
        }

        final currentUser = userProvider.me ?? auth.user;

        // Kiểm tra trạng thái shop dựa vào role, giữ logic cũ của bạn.
        bool hasShop = false;
        if (currentUser != null) {
          if (currentUser.role == 'SELLER' || currentUser.role == 'ADMIN') {
            hasShop = true;
          }
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Thông tin cá nhân',
              style: TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: _textDark,
                size: 20,
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/profile');
                }
              },
            ),
          ),
          body: currentUser == null
              ? const Center(
            child: CircularProgressIndicator(color: _primaryPink),
          )
              : RefreshIndicator(
            color: _primaryPink,
            onRefresh: () async {
              await _loadProfile(auth, userProvider, forceRefresh: true);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              child: Column(
                children: [
                  // Card thông tin cá nhân theo layout ảnh mẫu.
                  _buildPersonalInfoCard(
                    currentUser: currentUser,
                    onEdit: () => _openEditScreen(auth, userProvider),
                  ),

                  const SizedBox(height: 18),

                  // Card shop vẫn giữ chức năng cũ.
                  _buildShopCard(
                    hasShop: hasShop,
                    auth: auth,
                    userProvider: userProvider,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
