// ================================================================
// CONDITIONAL EXPORT
// ----------------------------------------------------------------
// File này tự chọn cấu hình Dio theo nền tảng:
// - Mobile/Desktop: dùng dio_platform_config_io.dart
// - Web: dùng dio_platform_config_web.dart
//
// Nhờ vậy app mobile vẫn sạch, nhưng khi bạn tạm chạy Flutter Web để dev
// thì Dio vẫn gửi được httpOnly cookie bằng withCredentials.
// ================================================================
export 'dio_platform_config_io.dart'
if (dart.library.html) 'dio_platform_config_web.dart';
