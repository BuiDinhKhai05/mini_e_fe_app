import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Để gọi UserProvider

import '../service/auth_service.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart'; // THÊM để gọi fetchMe

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
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();



  String _parseErrorMessage(dynamic error) {
    String errorStr = error.toString();
    errorStr = errorStr.replaceFirst('Exception: ', '');
    if (errorStr.contains('Status: ')) {
      errorStr = errorStr.split('Status: ')[1].split(' - ')[1];
    }
    errorStr = errorStr.replaceAll(' - ', ' ');

    if (errorStr.contains('401')) return 'Email hoặc mật khẩu không đúng';
    if (errorStr.contains('400')) return errorStr.contains('Email') ? 'Email không hợp lệ' : 'Dữ liệu không hợp lệ';
    if (errorStr.contains('404')) return 'Không tìm thấy tài khoản';
    if (errorStr.contains('429')) return 'Thử lại quá nhiều lần. Vui lòng đợi.';
    if (errorStr.contains('OTP')) return 'Mã OTP không đúng hoặc đã hết hạn';

    return errorStr.isEmpty ? 'Có lỗi xảy ra' : errorStr;
  }

  Future<void> register(String name, String email, String password, String confirmPassword) async {
    _startLoading();
    try {
      _user = await _authService.register(name, email, password, confirmPassword);
      _isVerified = _user?.isVerified ?? false;
      await login(email, password);
    } catch (e) {
      _setError(e);
    } finally {
      _stopLoading();
    }
  }

  // ==================== LOGIN ====================
  Future<void> login(String email, String password) async {
    _startLoading();
    try {
      final result = await _authService.login(email, password);
      _user = result['user'] as UserModel;
      _accessToken = result['access_token'] as String;

      // LƯU TOKEN
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);

      _isVerified = _user?.isVerified ?? false;

      if (!_isVerified) {
        await requestVerify();
        _navigateTo('/verify-account');
      } else {
        // PHÂN BIỆT ADMIN / USER
        final isAdmin = _user?.role?.toUpperCase() == 'ADMIN';
        if (isAdmin) {
          print('ADMIN LOGIN → /admin-home');
          _navigateTo('/admin-home');
        } else {
          print('USER LOGIN → /home');
          _navigateTo('/home');
        }
        _showSnackBar('Xin chào ${_user!.name}!', Colors.green);
      }
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
      _showSnackBar('Xác thực tài khoản thành công!', Colors.blue);
      _navigateToHomeAndWelcome(delay: 500);
    } catch (e) {
      _setError(e);
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
      _showSnackBar(_errorMessage!, Colors.red);
    } finally {
      _stopLoading();
    }
  }

  Future<void> resetPassword(String otp, String newPassword, String confirmPassword) async {
    _startLoading();
    try {
      if (newPassword != confirmPassword) {
        throw Exception('Mật khẩu xác nhận không khớp');
      }
      final message = await _authService.resetPassword(_resetEmail!, otp, newPassword, confirmPassword);
      _showSnackBar(message, Colors.green);
      _resetEmail = null;
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
      navigatorKey.currentState?.pushReplacementNamed('/login');
    } catch (e) {
      _setError(e);
      _showSnackBar(_errorMessage!, Colors.red);
    } finally {
      _stopLoading();
    }
  }

  Future<void> logout() async {
    _startLoading();
    try {
      await _authService.logout();
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');

      final context = navigatorKey.currentContext;
      if (context != null) {
        Provider.of<UserProvider>(context, listen: false).clearMe();
      }

      _clearUserData();
      _accessToken = null;
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
    print('DEBUG: Error → $_errorMessage');
  }

  void _clearUserData() {
    _user = null;
    _isVerified = false;
    _resetEmail = null;
    notifyListeners();
  }

  void _navigateTo(String route) {
    navigatorKey.currentState?.pushReplacementNamed(route);
  }

  void _navigateToHomeAndWelcome({int delay = 0}) {
    Future.delayed(Duration(milliseconds: delay), () {
      _navigateTo('/home');
      _showSnackBar('Xin chào ${_user!.name ?? 'Người dùng'}!', Colors.green);
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

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');

    if (_accessToken == null || _accessToken!.isEmpty) {
      print('DEBUG: Không có token → yêu cầu đăng nhập.');
      _navigateTo('/login');
      return;
    }

    print('DEBUG: Auto-load token success');

    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        print('DEBUG: Context chưa sẵn sàng, sẽ load user sau.');
        return;
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchMe(force: true);
      _user = userProvider.me;
      _isVerified = _user?.isVerified ?? false;

      if (_user == null) {
        print('DEBUG: Không lấy được user → logout');
        await prefs.remove('access_token');
        _accessToken = null;
        _navigateTo('/login');
        return;
      }

      // ĐIỀU HƯỚNG THEO ROLE – AN TOÀN VỚI POST FRAME
      final isAdmin = _user!.role?.toUpperCase() == 'ADMIN';
      final targetRoute = isAdmin ? '/admin-home' : '/home';

      print('DEBUG: Auto-load user success → ${_user!.email} (Role: ${_user!.role}) → $targetRoute');

      // CHỜ FRAME ĐẦU TIÊN ĐỂ ĐIỀU HƯỚNG
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushReplacementNamed(targetRoute);
      });

    } catch (e) {
      print('DEBUG: Auto-load user failed: $e');
      final err = e.toString().toLowerCase();

      if (err.contains('401') || err.contains('unauthorized')) {
        print('DEBUG: Token invalid → logout bắt buộc.');
        await prefs.remove('access_token');
        _accessToken = null;
        _user = null;
        _navigateTo('/login');
      } else {
        print('DEBUG: Lỗi khác, vẫn giữ token để thử lại sau.');
        // Vẫn điều hướng về login nếu không có user
        _navigateTo('/login');
      }
    }
  }
}