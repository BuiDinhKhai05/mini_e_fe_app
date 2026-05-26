import 'package:dio/dio.dart';

// ================================================================
// MOBILE / DESKTOP CONFIG
// ----------------------------------------------------------------
// Mobile không cần withCredentials như browser.
// Cookie refresh token được xử lý bằng CookieManager trong api_client.dart.
// ================================================================
void configureDioForPlatform(Dio dio) {
  // Không cần cấu hình thêm cho mobile/desktop.
}
