// lib/service/review_service.dart

import 'package:dio/dio.dart';

import '../models/review_model.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';

// =======================================================
// REVIEW SERVICE
// Chỉ sửa Frontend để thích nghi format BE hiện tại:
// - BE trả wrapper { success: true, data: ... }
// - GET /orders/:id/review có thể trả data = null/object/list
// - POST trả data là review vừa tạo
// =======================================================
class ReviewService {
  final ApiClient _apiClient = ApiClient();

  // =======================================================
  // Lấy danh sách đánh giá của một sản phẩm.
  // BE: GET /products/:productId/reviews?page=1&limit=20
  // Response:
  // { success: true, data: { summary, items, page, limit, total } }
  // =======================================================
  Future<ProductReviewResponse> fetchProductReviews({
    required int productId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final safePage = page < 1 ? 1 : page;
      final safeLimit = limit < 1 ? 20 : (limit > 100 ? 100 : limit);

      final response = await _apiClient.get(
        '${ReviewApi.productReviews(
            productId)}?page=$safePage&limit=$safeLimit',
      );

      final body = response.data;

      if (body is Map) {
        final map = Map<String, dynamic>.from(body);

        if (map['success'] == false) {
          throw Exception(
              _extractMessage(map, 'Không thể tải đánh giá sản phẩm'));
        }

        return ProductReviewResponse.fromJson(map);
      }

      throw Exception('Dữ liệu đánh giá sản phẩm không hợp lệ');
    } catch (e) {
      throw Exception(_formatReviewError(
        e,
        fallback: 'Không thể tải đánh giá sản phẩm',
      ));
    }
  }

  // =======================================================
  // Tạo đánh giá sản phẩm theo đơn hàng.
  // BE: POST /orders/:id/review
  // Body: { productId, rating, comment?, images? }
  // Response: { success: true, data: review }
  // =======================================================
  Future<ProductReviewItem?> createReviewForOrder({
    required String orderId,
    required int productId,
    required int rating,
    String? comment,
    List<String> images = const [],
  }) async {
    try {
      final request = CreateReviewRequest(
        orderId: orderId,
        productId: productId,
        rating: rating.clamp(1, 5).toInt(),
        comment: comment,
        images: images,
      );

      final response = await _apiClient.post(
        ReviewApi.createOrderReview(orderId),
        data: request.toOrderReviewJson(),
      );

      return _parseCreatedReview(response.data);
    } catch (e) {
      throw Exception(_formatReviewError(
        e,
        fallback: 'Gửi đánh giá thất bại',
      ));
    }
  }

  // =======================================================
  // Lấy đánh giá của một đơn hàng.
  // BE: GET /orders/:id/review?productId=
  // Response có thể là:
  // - { success: true, data: null }
  // - { success: true, data: reviewObject }
  // - { success: true, data: [reviewObject] }
  // =======================================================
  Future<List<ProductReviewItem>> fetchOrderReviews({
    required String orderId,
    int? productId,
  }) async {
    try {
      final endpoint = productId == null
          ? ReviewApi.orderReview(orderId)
          : '${ReviewApi.orderReview(orderId)}?productId=$productId';

      final response = await _apiClient.get(endpoint);
      final body = response.data;

      if (body == null) {
        return [];
      }

      if (body is Map) {
        final map = Map<String, dynamic>.from(body);

        if (map['success'] == false) {
          throw Exception(_extractMessage(map, 'Không thể kiểm tra đánh giá'));
        }

        return OrderReviewResult
            .fromJson(map)
            .items;
      }

      if (body is List) {
        return body
            .whereType<Map>()
            .map((item) =>
            ProductReviewItem.fromJson(
              Map<String, dynamic>.from(item),
            ))
            .where((item) => item.id.isNotEmpty)
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception(_formatReviewError(
        e,
        fallback: 'Không thể kiểm tra đánh giá',
      ));
    }
  }

  // =======================================================
  // true nếu sản phẩm này trong đơn hàng đã có review.
  // =======================================================
  Future<bool> hasReviewForOrderProduct({
    required String orderId,
    required int productId,
  }) async {
    final reviews = await fetchOrderReviews(
      orderId: orderId,
      productId: productId,
    );

    return reviews.any((review) => review.productId == productId);
  }

  // =======================================================
  // Route mới nếu muốn dùng POST /product-reviews.
  // BE: POST /product-reviews
  // Body: { orderId, productId, rating, comment?, images? }
  // =======================================================
  Future<ProductReviewItem?> createProductReviewV2({
    required String orderId,
    required int productId,
    required int rating,
    String? comment,
    List<String> images = const [],
  }) async {
    try {
      final request = CreateReviewRequest(
        orderId: orderId,
        productId: productId,
        rating: rating.clamp(1, 5).toInt(),
        comment: comment,
        images: images,
      );

      final response = await _apiClient.post(
        ReviewApi.productReviewsV2,
        data: request.toProductReviewsJson(),
      );

      return _parseCreatedReview(response.data);
    } catch (e) {
      throw Exception(_formatReviewError(
        e,
        fallback: 'Gửi đánh giá thất bại',
      ));
    }
  }

  ProductReviewItem? _parseCreatedReview(dynamic body) {
    if (body is! Map) {
      throw Exception('Dữ liệu phản hồi đánh giá không hợp lệ');
    }

    final map = Map<String, dynamic>.from(body);

    if (map['success'] == false) {
      throw Exception(_extractMessage(map, 'Gửi đánh giá thất bại'));
    }

    final rawData = map.containsKey('data') ? map['data'] : map;

    if (rawData is Map) {
      final review = ProductReviewItem.fromJson(
        Map<String, dynamic>.from(rawData),
      );
      return review.id.isEmpty ? null : review;
    }

    return null;
  }

  // =======================================================
  // Chuẩn hóa lỗi Dio để UI không hiện nguyên DioException dài.
  // =======================================================
  String _formatReviewError(Object error, {
    required String fallback,
  }) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      if (data is Map) {
        return _extractMessage(Map<String, dynamic>.from(data), fallback);
      }

      if (statusCode != null && statusCode >= 500) {
        return '$fallback. Máy chủ đang lỗi ($statusCode), hãy kiểm tra log backend.';
      }

      if (statusCode == 401) {
        return 'Bạn cần đăng nhập để thực hiện chức năng này.';
      }

      if (statusCode == 403) {
        return 'Bạn không có quyền thực hiện thao tác này.';
      }

      if (statusCode == 404) {
        return 'Không tìm thấy dữ liệu đánh giá.';
      }

      return fallback;
    }

    final text = error.toString().replaceFirst('Exception: ', '').trim();
    return text.isEmpty ? fallback : text;
  }

  String _extractMessage(Map<String, dynamic> map, String fallback) {
    final message = map['message'];

    if (message is String && message
        .trim()
        .isNotEmpty) {
      return message.trim();
    }

    // NestJS validation đôi khi trả message dạng List<String>.
    if (message is List && message.isNotEmpty) {
      return message.map((item) => item.toString()).join('\n');
    }

    final error = map['error'];
    if (error is String && error
        .trim()
        .isNotEmpty) {
      return error.trim();
    }

    return fallback;
  }
}