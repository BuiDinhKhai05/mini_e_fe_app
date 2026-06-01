import 'package:flutter/foundation.dart' show kIsWeb;

// ================================================================
// APP CONSTANTS
// ----------------------------------------------------------------
// File này gom baseUrl và toàn bộ endpoint API để các service/provider dùng chung.
// ================================================================
class AppConstants {
  // Local dev:
  // - Flutter Web: http://localhost:3000/api
  // - Android Emulator: http://10.0.2.2:3000/api
  // - Điện thoại thật: đổi thành IP LAN máy tính.
  static const String baseUrl = kIsWeb
      ? 'http://localhost:3000/api'
      : 'http://10.0.2.2:3000/api';

  // AUTH API
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshEndpoint = '/auth/refresh';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String requestVerifyEndpoint = '/auth/request-verify';
  static const String verifyAccountEndpoint = '/auth/verify-account';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String changePasswordEndpoint = '/auth/change-password';
}

// ================================================================
// USERS API
// ================================================================
class UsersApi {
  static const String users = '/users';
  static const String me = '/users/me';
  static const String deletedAll = '/users/deleted/all';

  static const String requestChangePasswordOtp =
      '/users/me/change-password/request-otp';
  static const String changePassword = '/users/me/change-password';

  static String byId(String id) => '/users/$id';
  static String restore(String id) => '/users/$id/restore';
  static String hardDelete(String id) => '/users/$id/hard';
}

// ================================================================
// SHOPS API
// ================================================================
class ShopsApi {
  static const String shops = '/shops';
  static const String adminAll = '/shops/admin/all';
  static const String checkName = '/shops/check-name';

  static const String register = '/shops/register';
  static const String myShop = '/shops/me';

  static const String uploadLogo = '/shops/me/logo';
  static const String uploadCover = '/shops/me/cover';

  static const String myShopOrders = '/shops/me/orders';

  static String myShopOrderDetail(String id) => '/shops/me/orders/$id';
  static String myShopOrderShippingStatus(String id) =>
      '/shops/me/orders/$id/shipping-status';

  static String byId(String id) => '/shops/$id';
}

// ================================================================
// PRODUCT API
// ================================================================
class ProductApi {
  // Public
  static const String products = '/products';
  static const String search = '/products/search';

  // Seller
  static const String myShopProducts = '/products/my-shop';

  // Admin
  static const String adminAll = '/products/admin/all';

  static String byId(int id) => '/products/$id';
  static String manageDetail(int id) => '/products/$id/manage';
  static String byShop(int shopId) => '/products/by-shop/$shopId';

  static String variants(int productId) => '/products/$productId/variants';
  static String generateVariants(int productId) =>
      '/products/$productId/variants/generate';
  static String variant(int productId, int variantId) =>
      '/products/$productId/variants/$variantId';
}

// ================================================================
// CATEGORY API
// ================================================================
class CategoryApi {
  static const String categories = '/categories';
  static const String tree = '/categories/tree';

  static String byId(int id) => '/categories/$id';
}

// ================================================================
// CART API
// ================================================================
class CartApi {
  static const String myCart = '/cart';
  static const String items = '/cart/items';
}

// ================================================================
// ADDRESS API
// ================================================================
class AddressApi {
  static const String base = '/addresses';
  static const String list = '/addresses';

  static String byId(int id) => '/addresses/$id';
  static String setDefault(int id) => '/addresses/$id/set-default';
}

// ================================================================
// ORDER API
// ================================================================
class OrderApi {
  static const String preview = '/orders/preview';
  static const String create = '/orders';
  static const String mine = '/orders';

  static String detail(String id) => '/orders/$id';
  static String cancel(String id) => '/orders/$id/cancel';
  static String confirmReceived(String id) => '/orders/$id/confirm-received';
  static String requestReturn(String id) => '/orders/$id/request-return';
}

// ================================================================
// PAYMENT API
// ================================================================
class PaymentApi {}

// ================================================================
// REVIEW API
// ================================================================
class ReviewApi {
  static String shopReviews(int shopId) => '/reviews/shop/$shopId';
  static const String myShopReviews = '/reviews/shop/me';

  static String productReviews(int productId) => '/products/$productId/reviews';
  static String createOrderReview(String orderId) => '/orders/$orderId/review';
  static String orderReview(String orderId) => '/orders/$orderId/review';

  static const String productReviewsV2 = '/product-reviews';
  static String productReviewByOrder(String orderId) =>
      '/product-reviews/by-order/$orderId';
}
