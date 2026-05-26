import 'dart:async';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../utils/app_constants.dart';
import 'dio_platform_config.dart';

class ApiClient {
  // ==============================================================
  // 1. SINGLETON
  // --------------------------------------------------------------
  // Toàn bộ app chỉ dùng một instance ApiClient.
  // Nhờ vậy cookie, access token và interceptor được dùng chung
  // cho tất cả service: UserService, CartService, ShopService...
  // ==============================================================
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal();

  late final Dio _dio;
  late final Dio _refreshDio;

  CookieJar? _cookieJar;
  bool _initialized = false;

  // Dùng để chống trường hợp nhiều request cùng hết hạn token một lúc.
  // Nếu 5 request cùng bị 401, app chỉ gọi /auth/refresh 1 lần.
  Future<String?>? _refreshFuture;

  // ==============================================================
  // 2. KHỞI TẠO DIO + COOKIE + INTERCEPTOR
  // --------------------------------------------------------------
  // Hàm này đang được gọi trong main.dart trước runApp().
  // ==============================================================
  Future<void> init() async {
    if (_initialized) return;

    _cookieJar = await _createCookieJar();

    // Dio chính dùng cho toàn bộ API của app.
    _dio = _createDio();

    // Dio riêng chỉ dùng để gọi /auth/refresh.
    // Tách riêng để tránh interceptor refresh bị gọi vòng lặp.
    _refreshDio = _createDio();

    // Web cần withCredentials=true để browser gửi httpOnly cookie.
    // Mobile/Desktop không dùng cấu hình này, mà dùng CookieManager bên dưới.
    configureDioForPlatform(_dio);
    configureDioForPlatform(_refreshDio);

    // Mobile app cần CookieManager để lưu refresh token từ Set-Cookie của BE.
    // Refresh token là httpOnly cookie nên FE không đọc trực tiếp được,
    // nhưng CookieManager vẫn lưu và tự gửi lại khi gọi /auth/refresh.
    if (!kIsWeb) {
      _dio.interceptors.add(CookieManager(_cookieJar!));
      _refreshDio.interceptors.add(CookieManager(_cookieJar!));
    }

    // Nếu app mở lại và SharedPreferences còn access_token,
    // gắn token cũ vào Dio trước. Nếu token cũ hết hạn, interceptor sẽ refresh.
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('access_token');
    if (savedToken != null && savedToken.isNotEmpty) {
      setAccessToken(savedToken);
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        // ----------------------------------------------------------
        // 2.1. Trước mỗi request: gắn Authorization Bearer token
        // ----------------------------------------------------------
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');

          if (token != null &&
              token.isNotEmpty &&
              _shouldAttachAccessToken(options.path)) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          debugPrint('[REQUEST] ${options.method} ${options.uri}');
          handler.next(options);
        },

        // ----------------------------------------------------------
        // 2.2. Khi response trả về
        // ----------------------------------------------------------
        // Project của bạn đang dùng validateStatus < 500.
        // Vì vậy status 401 sẽ đi vào onResponse, không phải onError.
        // Đây chính là lỗi cũ khiến refresh token không chạy.
        onResponse: (response, handler) async {
          final statusCode = response.statusCode;
          final requestOptions = response.requestOptions;

          final alreadyRetried = requestOptions.extra['_retry'] == true;
          final canRefresh = statusCode == 401 &&
              !alreadyRetried &&
              _shouldTryRefresh(requestOptions.path);

          if (!canRefresh) {
            handler.next(response);
            return;
          }

          try {
            debugPrint('401 → Refresh access token...');

            final newAccessToken = await _refreshAccessToken();

            if (newAccessToken == null || newAccessToken.isEmpty) {
              await logoutAndRedirect();
              handler.next(response);
              return;
            }

            // Đánh dấu request này đã retry để tránh vòng lặp vô hạn.
            requestOptions.extra['_retry'] = true;
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            // Gọi lại đúng request ban đầu với access token mới.
            final retryResponse = await _dio.fetch<dynamic>(requestOptions);
            handler.resolve(retryResponse);
          } catch (e) {
            debugPrint('Retry sau refresh thất bại: $e');
            await logoutAndRedirect();
            handler.next(response);
          }
        },

        // ----------------------------------------------------------
        // 2.3. Fallback cho trường hợp Dio ném lỗi vào onError
        // ----------------------------------------------------------
        // Nếu sau này bạn đổi validateStatus, 401 có thể đi vào đây.
        // Giữ nhánh này để cơ chế refresh vẫn hoạt động ổn định.
        onError: (DioException e, handler) async {
          final statusCode = e.response?.statusCode;
          final requestOptions = e.requestOptions;

          final alreadyRetried = requestOptions.extra['_retry'] == true;
          final canRefresh = statusCode == 401 &&
              !alreadyRetried &&
              _shouldTryRefresh(requestOptions.path);

          if (!canRefresh) {
            handler.next(e);
            return;
          }

          try {
            debugPrint('401 error → Refresh access token...');

            final newAccessToken = await _refreshAccessToken();

            if (newAccessToken == null || newAccessToken.isEmpty) {
              await logoutAndRedirect();
              handler.next(e);
              return;
            }

            requestOptions.extra['_retry'] = true;
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await _dio.fetch<dynamic>(requestOptions);
            handler.resolve(retryResponse);
          } catch (err) {
            debugPrint('Refresh token thất bại: $err');
            await logoutAndRedirect();
            handler.next(e);
          }
        },
      ),
    );

    _initialized = true;
  }

  // ==============================================================
  // 3. TẠO DIO MẶC ĐỊNH
  // --------------------------------------------------------------
  // validateStatus < 500 giữ cách xử lý hiện tại của app:
  // - 400/401/403/404 không bị Dio throw ngay
  // - Service vẫn đọc được response.data['message'] để báo lỗi đẹp
  //
  // Lưu ý Flutter Web:
  // Dio trên Web cảnh báo nếu set sendTimeout cho request không có body
  // như GET. Vì vậy mobile giữ sendTimeout, còn Web để null.
  // ==============================================================
  Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: kIsWeb ? null : const Duration(seconds: 20),
        contentType: 'application/json',
        headers: const {
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ==============================================================
  // 4. TẠO COOKIE JAR
  // --------------------------------------------------------------
  // Mobile: PersistCookieJar lưu cookie qua các lần mở app.
  // Web: browser tự quản lý httpOnly cookie, CookieJar ở đây chỉ để đồng bộ kiểu.
  // ==============================================================
  Future<CookieJar> _createCookieJar() async {
    if (kIsWeb) {
      return CookieJar();
    }

    final dir = await getApplicationDocumentsDirectory();
    return PersistCookieJar(
      storage: FileStorage('${dir.path}/.cookies/'),
    );
  }

  // ==============================================================
  // 5. PUBLIC HELPERS
  // --------------------------------------------------------------
  // Các service hiện tại có thể dùng ApiClient().dio hoặc các hàm get/post.
  // Giữ đủ helper để không làm vỡ code cũ.
  // ==============================================================
  Dio get dio => _dio;

  void setAccessToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAccessToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response<T>> get<T>(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> patch<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ==============================================================
  // 6. REFRESH ACCESS TOKEN
  // --------------------------------------------------------------
  // BE của bạn lưu refresh token trong httpOnly cookie.
  // FE không đọc refresh token, chỉ gọi POST /auth/refresh.
  // Nếu cookie hợp lệ, BE trả access_token mới.
  // ==============================================================
  Future<String?> _refreshAccessToken() {
    _refreshFuture ??= _doRefreshAccessToken().whenComplete(() {
      _refreshFuture = null;
    });

    return _refreshFuture!;
  }

  Future<String?> _doRefreshAccessToken() async {
    final response = await _refreshDio.post(AppConstants.refreshEndpoint);

    if (response.statusCode != 200) {
      debugPrint('Refresh thất bại với status ${response.statusCode}');
      return null;
    }

    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : null;
    final accessToken = data is Map<String, dynamic>
        ? data['access_token']
        : null;

    if (accessToken is! String || accessToken.isEmpty) {
      debugPrint('Refresh response không có access_token hợp lệ');
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    setAccessToken(accessToken);

    debugPrint('Refresh access token OK');
    return accessToken;
  }

  // Hàm public giữ lại để tương thích nếu chỗ khác trong app đang gọi.
  Future<bool> refreshToken() async {
    final token = await _refreshAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ==============================================================
  // 7. CLEAR AUTH LOCAL DATA
  // --------------------------------------------------------------
  // Xóa access token + cookie local.
  // Dùng khi logout hoặc khi refresh token thất bại.
  // ==============================================================
  Future<void> clearAuthStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');

    // App cũ từng remove refresh_token trong SharedPreferences.
    // Refresh token hiện tại nằm trong httpOnly cookie, nhưng giữ dòng này
    // để dọn dữ liệu cũ nếu trước đây bạn từng lưu refresh_token local.
    await prefs.remove('refresh_token');

    clearAccessToken();
    await _cookieJar?.deleteAll();
  }

  Future<void> logoutAndRedirect() async {
    await clearAuthStorage();

    AuthProvider.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
    );
  }

  // ==============================================================
  // 8. QUY TẮC GẮN TOKEN / REFRESH TOKEN
  // --------------------------------------------------------------
  // Không gắn access token cho login/register/forgot-password...
  // Vẫn gắn token cho request-verify và verify-account vì BE cần Bearer token.
  // Không refresh cho nhóm /auth/* để tránh vòng lặp vô hạn.
  // ==============================================================
  bool _shouldAttachAccessToken(String path) {
    return !_isPublicAuthEndpoint(path);
  }

  bool _shouldTryRefresh(String path) {
    return !path.startsWith('/auth/');
  }

  bool _isPublicAuthEndpoint(String path) {
    return path.startsWith('/auth/login') ||
        path.startsWith('/auth/register') ||
        path.startsWith('/auth/refresh') ||
        path.startsWith('/auth/logout') ||
        path.startsWith('/auth/forgot-password') ||
        path.startsWith('/auth/reset-password') ||
        path.startsWith('/auth/account/recover/request') ||
        path.startsWith('/auth/account/recover/confirm');
  }
}
