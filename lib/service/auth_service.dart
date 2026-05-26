import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';

class AuthService {
  // ==============================================================
  // 1. DIO DÙNG CHUNG
  // --------------------------------------------------------------
  // Dùng ApiClient().dio để mọi request auth đi qua cùng CookieManager
  // và cùng cấu hình interceptor của toàn app.
  // ==============================================================
  final Dio _dio = ApiClient().dio;

  // ==============================================================
  // 2. LƯU ACCESS TOKEN
  // --------------------------------------------------------------
  // Refresh token không lưu ở đây vì BE đang set refresh token bằng
  // httpOnly cookie. FE chỉ lưu access_token để gắn Authorization header.
  // ==============================================================
  Future<void> _saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);

    // Cập nhật ngay header mặc định của Dio để request tiếp theo dùng token mới.
    ApiClient().setAccessToken(accessToken);
  }

  // ==============================================================
  // 3. ĐĂNG KÝ
  // ==============================================================
  Future<UserModel> register(
      String name,
      String email,
      String password,
      String confirmPassword,
      ) async {
    final response = await _dio.post(
      AppConstants.registerEndpoint,
      data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );

    if (response.statusCode == 201) {
      return UserModel.fromJson(response.data['data']);
    }

    throw Exception(response.data['message'] ?? 'Đăng ký thất bại');
  }

  // ==============================================================
  // 4. ĐĂNG NHẬP
  // --------------------------------------------------------------
  // BE trả access_token trong body và refresh token trong Set-Cookie.
  // CookieManager trong ApiClient sẽ tự lưu cookie refresh token cho mobile.
  // ==============================================================
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      AppConstants.loginEndpoint,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data['data'];
      final accessToken = data['access_token'];

      if (accessToken is! String || accessToken.isEmpty) {
        throw Exception('BE không trả về access_token');
      }

      await _saveAccessToken(accessToken);

      return {
        'user': UserModel.fromJson(data['user']),
        'access_token': accessToken,
      };
    }

    throw Exception(response.data['message'] ?? 'Đăng nhập thất bại');
  }

  // ==============================================================
  // 5. GỬI LẠI OTP XÁC THỰC TÀI KHOẢN
  // --------------------------------------------------------------
  // API này cần Bearer token, kể cả khi user chưa verify.
  // ApiClient sẽ tự gắn access_token cho endpoint này.
  // ==============================================================
  Future<void> requestVerify() async {
    final response = await _dio.post(AppConstants.requestVerifyEndpoint);

    if (response.statusCode != 200) {
      throw Exception(response.data['message'] ?? 'Gửi OTP thất bại');
    }
  }

  // ==============================================================
  // 6. XÁC THỰC TÀI KHOẢN BẰNG OTP
  // --------------------------------------------------------------
  // BE của bạn trả format:
  // data: { verified: true, access_token: '...', user: {...} }
  // Vì vậy cần lấy data['user'], không parse trực tiếp data.
  // ==============================================================
  Future<UserModel> verifyAccount(String otp) async {
    final response = await _dio.post(
      AppConstants.verifyAccountEndpoint,
      data: {'otp': otp.trim()},
    );

    if (response.statusCode == 200) {
      final data = response.data['data'];

      final accessToken = data['access_token'];
      if (accessToken is String && accessToken.isNotEmpty) {
        await _saveAccessToken(accessToken);
      }

      return UserModel.fromJson(data['user']);
    }

    throw Exception(response.data['message'] ?? 'OTP không đúng');
  }

  // ==============================================================
  // 7. QUÊN MẬT KHẨU
  // ==============================================================
  Future<String> forgotPassword(String email) async {
    final response = await _dio.post(
      AppConstants.forgotPasswordEndpoint,
      data: {'email': email.trim().toLowerCase()},
    );

    if (response.statusCode == 200) {
      final targetEmail = response.data['data']?['email'] ?? email;
      return 'Mã OTP đã được gửi đến $targetEmail!';
    }

    throw Exception(response.data['message'] ?? 'Không tìm thấy email');
  }

  // ==============================================================
  // 8. RESET PASSWORD BẰNG OTP
  // ==============================================================
  Future<String> resetPassword(
      String email,
      String otp,
      String newPassword,
      String confirmPassword,
      ) async {
    final response = await _dio.post(
      AppConstants.resetPasswordEndpoint,
      data: {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
        'password': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    if (response.statusCode == 200) {
      return 'Đặt lại mật khẩu thành công!';
    }

    throw Exception(response.data['message'] ?? 'OTP không hợp lệ');
  }

  // ==============================================================
  // 9. ĐỔI MẬT KHẨU
  // --------------------------------------------------------------
  // Theo BE bạn gửi hiện tại chưa có /auth/change-password chuẩn.
  // Vì vậy FE vẫn đổi mật khẩu qua PATCH /users/:id với field password.
  // Lưu ý: currentPassword hiện chỉ được validate ở UI, chưa được BE kiểm tra.
  // ==============================================================
  Future<UserModel> changePassword({
    required int userId,
    required String newPassword,
  }) async {
    final response = await _dio.patch(
      UsersApi.byId(userId.toString()),
      data: {
        'password': newPassword,
      },
    );

    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      final body = response.data;

      // Hỗ trợ nhiều kiểu response để tránh lỗi parse nếu BE trả khác nhẹ:
      // 1. { data: user }
      // 2. user trực tiếp
      final dynamic rawUser = body is Map<String, dynamic>
          ? (body['data'] ?? body)
          : null;

      if (rawUser is Map<String, dynamic>) {
        return UserModel.fromJson(rawUser);
      }

      throw Exception('Dữ liệu trả về khi đổi mật khẩu không hợp lệ');
    }

    throw Exception(response.data['message'] ?? 'Đổi mật khẩu thất bại');
  }

  // ==============================================================
  // 10. LOGOUT
  // --------------------------------------------------------------
  // Gọi BE để clear refresh token cookie, sau đó xóa token/cookie local.
  // Không điều hướng trong service; AuthProvider sẽ điều hướng UI.
  // ==============================================================
  Future<void> logout() async {
    try {
      await _dio.post(AppConstants.logoutEndpoint);
    } catch (e) {
      // Nếu BE logout lỗi thì vẫn logout local để tránh user bị kẹt phiên.
      debugPrint('DEBUG: Logout API error: $e');
    } finally {
      await ApiClient().clearAuthStorage();
    }
  }
}
