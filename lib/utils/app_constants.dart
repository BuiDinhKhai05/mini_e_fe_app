// 1. Cần import thư viện này để dùng biến kIsWeb
import 'package:flutter/foundation.dart';

// utils/app_constants.dart
class AppConstants {
  // 2. Sửa đoạn baseUrl thành logic kiểm tra môi trường
  static const String baseUrl = kIsWeb
      ? 'http://localhost:3000/api' // Nếu chạy trên Web (Chrome)
      : 'http://10.0.2.2:3000/api'; // Nếu chạy trên máy ảo Android

  // AUTH
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String requestVerifyEndpoint = '/auth/request-verify';
  static const String verifyAccountEndpoint = '/auth/verify-account';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String changePasswordEndpoint = '/auth/change-password';
}

// USERS API
class UsersApi {
  static const String users = '/users';
  static const String me = '/users/me';
  static const String deletedAll = '/users/deleted/all';

  static String byId(String id) => '/users/$id';
  static String restore(String id) => '/users/$id/restore';
  static String hardDelete(String id) => '/users/$id/hard';
}

class ShopsApi {
  // Public
  static const String shops = '/shops';
  static const String checkName = '/shops/check-name';

  // Authenticated
  static const String register = '/shops/register';
  static const String myShop = '/shops/me';

  // Upload logo / cover shop
  static const String uploadLogo = '/shops/me/logo';
  static const String uploadCover = '/shops/me/cover';

  // Seller / Shop orders
  static const String myShopOrders = '/shops/me/orders';

  static String myShopOrderDetail(String id) => '/shops/me/orders/$id';

  static String myShopOrderShippingStatus(String id) =>
      '/shops/me/orders/$id/shipping-status';

  // Owner / Admin
  static String byId(String id) => '/shops/$id';
}

// PRODUCT API
class ProductApi {
  // Public
  static const String products = '/products';
  static const String search = '/products/search';

  // Authenticated
  static String byId(int id) => '/products/$id';
  static String variants(int productId) => '/products/$productId/variants';
  static String generateVariants(int productId) =>
      '/products/$productId/variants/generate';
  static String variant(int productId, int variantId) =>
      '/products/$productId/variants/$variantId';
}

// ✅ CATEGORY API
class CategoryApi {
  static const String categories = '/categories';
  static const String tree = '/categories/tree';
  static String byId(int id) => '/categories/$id';
}

class CartApi {
  static const String myCart = '/cart';
  static const String items = '/cart/items';
}

// ADDRESS API
class AddressApi {
  static const String base = '/addresses';
  static const String list = '/addresses';

  static String byId(int id) => '/addresses/$id';
  static String setDefault(int id) => '/addresses/$id/set-default';
}

// Order API
class OrderApi {
  static const String preview = '/orders/preview';
  static const String create = '/orders';
  static const String mine = '/orders';

  static String detail(String id) => '/orders/$id';
  static String cancel(String id) => '/orders/$id/cancel';
  static String confirmReceived(String id) => '/orders/$id/confirm-received';
  static String requestReturn(String id) => '/orders/$id/request-return';
}

// Payment API
class PaymentApi {
  // Backend trả về URL để QR...
}

// REVIEW API
// Chứa các endpoint liên quan đến đánh giá sản phẩm.
class ReviewApi {
  // Public: lấy danh sách đánh giá của một sản phẩm.
  // BE: GET /products/:productId/reviews?page=1&limit=20
  static String productReviews(int productId) =>
      '/products/$productId/reviews';

  // User tạo đánh giá theo đơn hàng.
  // BE: POST /orders/:id/review
  static String createOrderReview(String orderId) =>
      '/orders/$orderId/review';

  // User xem đánh giá của một đơn hàng.
  // BE: GET /orders/:id/review
  static String orderReview(String orderId) =>
      '/orders/$orderId/review';

  // API v2 tạo review.
  // BE: POST /product-reviews
  static const String productReviewsV2 = '/product-reviews';

  // API v2 lấy review theo order.
  // BE: GET /product-reviews/by-order/:orderId
  static String productReviewByOrder(String orderId) =>
      '/product-reviews/by-order/$orderId';
}
