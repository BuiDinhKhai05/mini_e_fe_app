import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

// ================================================================
// WEB CONFIG
// ----------------------------------------------------------------
// Khi chạy Flutter Web, browser chỉ gửi/nhận cookie cross-origin nếu bật
// withCredentials=true.
//
// Đây chỉ là hỗ trợ lúc bạn dev bằng Chrome. Mục tiêu chính của app vẫn là
// mobile, và mobile sẽ dùng CookieManager trong api_client.dart.
// ================================================================
void configureDioForPlatform(Dio dio) {
  (dio.httpClientAdapter as BrowserHttpClientAdapter).withCredentials = true;
}
