import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';
import 'api_client.dart'; // THÊM

class AuthService {
  final Dio _dio = ApiClient().dio;

  // Helper: Lưu access token (refresh cookie tự lưu)
  Future<void> _saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
  }

  Future<UserModel> register(String name, String email, String password, String confirmPassword) async {
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
    } else {
      throw Exception(response.data['message'] ?? 'Đăng ký thất bại');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      AppConstants.loginEndpoint,
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );

    if (response.statusCode == 200) {
      final data = response.data['data'];
      final accessToken = data['access_token'];
      await _saveAccessToken(accessToken);
      return {
        'user': UserModel.fromJson(data['user']),
        'access_token': accessToken,
      };
    } else {
      throw Exception(response.data['message'] ?? 'Đăng nhập thất bại');
    }
  }

  Future<void> requestVerify() async {
    final response = await _dio.post(AppConstants.requestVerifyEndpoint);
    if (response.statusCode != 200) {
      throw Exception(response.data['message'] ?? 'Gửi OTP thất bại');
    }
  }

  Future<UserModel> verifyAccount(String otp) async {
    final response = await _dio.post(
      AppConstants.verifyAccountEndpoint,
      data: {'otp': otp.trim()},
    );
    if (response.statusCode == 200) {
      return UserModel.fromJson(response.data['data']);
    } else {
      throw Exception(response.data['message'] ?? 'OTP không đúng');
    }
  }

  Future<String> forgotPassword(String email) async {
    final response = await _dio.post(
      AppConstants.forgotPasswordEndpoint,
      data: {'email': email.trim().toLowerCase()},
    );
    if (response.statusCode == 200) {
      return 'Mã OTP đã được gửi đến ${response.data['data']['email']}!';
    } else {
      throw Exception(response.data['message'] ?? 'Không tìm thấy email');
    }
  }

  Future<String> resetPassword(String email, String otp, String newPassword, String confirmPassword) async {
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
    } else {
      throw Exception(response.data['message'] ?? 'OTP không hợp lệ');
    }
  }


  /// ĐỔI MẬT KHẨU
  ///
  /// Dựa theo backend bạn gửi:
  /// - Trong UsersService.update(id, dto), backend có đoạn:
  ///   if (dto.password) { user.passwordHash = await bcrypt.hash(...) }
  /// - Nghĩa là backend hiện tại đổi mật khẩu thông qua API cập nhật user.
  /// - FE chỉ cần gọi PATCH /users/:id và gửi field password mới.
  ///
  /// Lưu ý quan trọng:
  /// - Backend hiện tại KHÔNG có field currentPassword trong đoạn code bạn gửi.
  /// - Vì vậy currentPassword chỉ được kiểm tra ở giao diện FE, chưa được backend xác thực.
  /// - Nếu backend controller của bạn đặt route khác /users/:id thì chỉ sửa dòng endpoint bên dưới.
  Future<UserModel> changePassword({
    required int userId,
    required String newPassword,
  }) async {
    final response = await _dio.patch(
      '/users/$userId',
      data: {
        // Field này phải khớp với dto.password trong UsersService.update().
        'password': newPassword,
      },
    );

    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      final body = response.data;

      // Có backend trả về { data: user }, có backend trả trực tiếp user.
      // Đoạn này hỗ trợ cả 2 kiểu response để FE đỡ bị lỗi parse.
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

  Future<void> logout() async {
    try {
      await _dio.post(AppConstants.logoutEndpoint);
    } catch (e) {
      print('DEBUG: Logout API error: $e'); // Optional: Log error nếu backend fail
    } finally {
      await ApiClient().logoutAndRedirect(); // Gọi public method
    }
  }
}