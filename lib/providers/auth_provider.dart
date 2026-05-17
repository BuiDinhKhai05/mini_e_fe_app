import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/shop_provider.dart';
import '../providers/user_provider.dart';
import '../service/auth_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isVerified = false;
  String? _resetEmail;
  String? _accessToken;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isVerified => _isVerified;
  String? get resetEmail => _resetEmail;
  String? get accessToken => _accessToken;

  final AuthService _authService = AuthService();
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  String _parseErrorMessage(dynamic error) {
    String errorStr = error.toString();
    errorStr = errorStr.replaceFirst('Exception: ', '');

    if (errorStr.contains('Status: ')) {
      final parts = errorStr.split('Status: ');
      if (parts.length > 1) {
        final statusPart = parts[1];
        final dashParts = statusPart.split(' - ');
        if (dashParts.length > 1) {
          errorStr = dashParts.sublist(1).join(' ');
        }
      }
    }

    errorStr = errorStr.replaceAll(' - ', ' ');

    if (errorStr.contains('401')) return 'Email hoặc mật khẩu không đúng';
    if (errorStr.contains('403')) return 'Bạn không có quyền thực hiện thao tác này';
    if (errorStr.contains('400')) {
      return errorStr.contains('Email')
          ? 'Email không hợp lệ'
          : 'Dữ liệu không hợp lệ';
    }
    if (errorStr.contains('404')) return 'Không tìm thấy tài khoản';
    if (errorStr.contains('429')) {
      return 'Thử lại quá nhiều lần. Vui lòng đợi.';
    }
    if (errorStr.toUpperCase().contains('OTP')) {
      return 'Mã OTP không đúng hoặc đã hết hạn';
    }

    return errorStr.isEmpty ? 'Có lỗi xảy ra' : errorStr;
  }

  Future<void> register(
      String name,
      String email,
      String password,
      String confirmPassword,
      ) async {
    _startLoading();
    try {
      _user = await _authService.register(
        name,
        email,
        password,
        confirmPassword,
      );
      _isVerified = _user?.isVerified ?? false;
      await login(email, password);
    } catch (e) {
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  Future<void> login(String email, String password) async {
    _startLoading();
    try {
      final result = await _authService.login(email, password);
      _user = result['user'] as UserModel;
      _accessToken = result['access_token'] as String;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);

      // clear cache session cũ
      await _resetSessionProviders(notify: false);

      _isVerified = _user?.isVerified ?? false;

      if (!_isVerified) {
        await requestVerify();
        _navigateTo('/verify-account');
        return;
      }

      // nạp dữ liệu đúng theo account mới
      await _bootstrapSessionData();

      final isAdmin = _user?.role?.toUpperCase() == 'ADMIN';
      _navigateTo(isAdmin ? '/admin-home' : '/home');

      _showSnackBar(
        'Xin chào ${_user?.name ?? 'Người dùng'}!',
        Colors.green,
      );
    } catch (e) {
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  Future<void> verifyAccount(String otp) async {
    _startLoading();
    try {
      _user = await _authService.verifyAccount(otp);
      _isVerified = true;

      await _bootstrapSessionData();

      _showSnackBar('Xác thực tài khoản thành công!', Colors.blue);
      _navigateToHomeAndWelcome(delay: 500);
    } catch (e) {
      _setError(e);
      if (_errorMessage != null) {
        _showSnackBar(_errorMessage!, Colors.red);
      }
    } finally {
      _stopLoading();
    }
  }

  Future<void> forgotPassword(String email) async {
    _startLoading();
    try {
      _resetEmail = email.trim();
      final message = await _authService.forgotPassword(email);
      _showSnackBar(message, Colors.green);
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateTo('/reset-otp');
    } catch (e) {
      _setError(e);
      if (_errorMessage != null) {
        _showSnackBar(_errorMessage!, Colors.red);
      }
    } finally {
      _stopLoading();
    }
  }

  Future<void> resetPassword(
      String otp,
      String newPassword,
      String confirmPassword,
      ) async {
    _startLoading();
    try {
      if (newPassword != confirmPassword) {
        throw Exception('Mật khẩu xác nhận không khớp');
      }

      final message = await _authService.resetPassword(
        _resetEmail!,
        otp,
        newPassword,
        confirmPassword,
      );

      _showSnackBar(message, Colors.green);
      _resetEmail = null;

      navigatorKey.currentState?.popUntil((route) => route.isFirst);
      navigatorKey.currentState?.pushReplacementNamed('/login');
    } catch (e) {
      _setError(e);
      if (_errorMessage != null) {
        _showSnackBar(_errorMessage!, Colors.red);
      }
    } finally {
      _stopLoading();
    }
  }


  /// ĐỔI MẬT KHẨU
  ///
  /// Luồng xử lý FE:
  /// 1. Kiểm tra người dùng đã đăng nhập chưa.
  /// 2. Kiểm tra mật khẩu mới và xác nhận mật khẩu có trùng nhau không.
  /// 3. Gọi AuthService.changePassword() để gửi request đến backend.
  /// 4. Cập nhật lại _user bằng dữ liệu backend trả về.
  ///
  /// Lưu ý:
  /// - Backend bạn gửi chỉ có đoạn đổi password trong UsersService.update().
  /// - Backend hiện tại chưa thấy kiểm tra currentPassword.
  /// - Vì vậy currentPassword đang dùng để validate phía FE và giữ đúng form giao diện.
  Future<void> changePassword(
      String currentPassword,
      String newPassword,
      String confirmPassword,
      ) async {
    _startLoading();

    try {
      // 1. Kiểm tra user đã đăng nhập chưa
      if (_user == null) {
        throw Exception('Bạn cần đăng nhập để đổi mật khẩu');
      }

      // 2. Kiểm tra mật khẩu hiện tại có nhập không
      // Lưu ý: backend hiện tại chưa kiểm tra currentPassword,
      // nên dòng này chỉ validate ở giao diện FE.
      if (currentPassword.trim().isEmpty) {
        throw Exception('Vui lòng nhập mật khẩu hiện tại');
      }

      // 3. Kiểm tra mật khẩu mới và xác nhận mật khẩu
      if (newPassword != confirmPassword) {
        throw Exception('Mật khẩu xác nhận không khớp');
      }

      // 4. Chuyển userId về int
      final int? userId = int.tryParse(_user!.id.toString());

      // 5. Nếu không ép được sang int thì báo lỗi
      if (userId == null) {
        throw Exception('ID người dùng không hợp lệ');
      }

      // 6. Gọi service để đổi mật khẩu
      // Theo backend hiện tại, FE gửi password mới vào dto.password.
      final updatedUser = await _authService.changePassword(
        userId: userId,
        newPassword: newPassword,
      );

      // 7. Cập nhật lại user trong Provider
      _user = updatedUser;

      // 8. Thông báo thành công
      _showSnackBar('Đổi mật khẩu thành công!', Colors.green);

      // 9. Quay lại màn trước nếu cần
      navigatorKey.currentState?.pop();
    } catch (e) {
      _setError(e);

      if (_errorMessage != null) {
        _showSnackBar(_errorMessage!, Colors.red);
      }
    } finally {
      _stopLoading();
    }
  }

  Future<void> logout() async {
    _startLoading();
    try {
      await _authService.logout();
    } catch (_) {
      // backend logout lỗi vẫn logout local
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');

      await _resetSessionProviders(notify: false);

      _accessToken = null;
      _clearUserData(notify: false);
      notifyListeners();

      _navigateTo('/login');
      _stopLoading();
    }
  }

  Future<void> requestVerify() async {
    _startLoading();
    try {
      await _authService.requestVerify();
      _showSnackBar('Mã OTP đã được gửi lại!', Colors.blue);
    } catch (e) {
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');

    if (_accessToken == null || _accessToken!.isEmpty) {
      await _resetSessionProviders(notify: false);
      _clearUserData(notify: false);
      _navigateTo('/login');
      return;
    }

    try {
      await _resetSessionProviders(notify: false);
      await _bootstrapSessionData();

      if (_user == null) {
        throw Exception('Không lấy được user');
      }

      final isAdmin = _user!.role?.toUpperCase() == 'ADMIN';
      final targetRoute = isAdmin ? '/admin-home' : '/home';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          targetRoute,
              (route) => false,
        );
      });
    } catch (e) {
      await prefs.remove('access_token');
      _accessToken = null;
      await _resetSessionProviders(notify: false);
      _clearUserData(notify: false);
      _navigateTo('/login');
    }
  }

  Future<void> _resetSessionProviders({bool notify = true}) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    Provider.of<UserProvider>(context, listen: false).clearAll(notify: notify);
    Provider.of<ShopProvider>(context, listen: false).clearShopData(notify: notify);
    Provider.of<ProductProvider>(context, listen: false).clearProductsCache(notify: notify);
    Provider.of<CartProvider>(context, listen: false).clearCartLocal(notify: notify);
  }

  Future<void> _bootstrapSessionData() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    await userProvider.fetchMe(force: true);
    _user = userProvider.me;
    _isVerified = _user?.isVerified ?? false;

    if (_user == null) {
      throw Exception('Không lấy được thông tin user');
    }

    final role = _user!.role?.toUpperCase() ?? '';

    if (role == 'ADMIN') {
      productProvider.clearProductsCache(notify: false);
      shopProvider.clearShopData(notify: false);
      cartProvider.clearCartLocal(notify: false);
      notifyListeners();
      return;
    }

    await cartProvider.fetchCart(notifyOnStart: false);

    if (role == 'SELLER') {
      await shopProvider.loadMyShop();
      await productProvider.fetchAllProductsForSeller(showLoading: false);
    } else {
      shopProvider.clearShopData(notify: false);
      await productProvider.fetchPublicProducts(showLoading: false);
    }

    notifyListeners();
  }

  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void _setError(dynamic error) {
    _errorMessage = _parseErrorMessage(error);
    debugPrint('DEBUG: Error → $_errorMessage');
  }

  void _clearUserData({bool notify = true}) {
    _user = null;
    _isVerified = false;
    _resetEmail = null;

    if (notify) {
      notifyListeners();
    }
  }

  void _navigateTo(String route) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      route,
          (route) => false,
    );
  }

  void _navigateToHomeAndWelcome({int delay = 0}) {
    Future.delayed(Duration(milliseconds: delay), () {
      _navigateTo('/home');
      _showSnackBar(
        'Xin chào ${_user?.name ?? 'Người dùng'}!',
        Colors.green,
      );
    });
  }

  void _showSnackBar(String message, Color color) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}