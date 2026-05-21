// lib/service/review_service.dart

import '../models/review_model.dart';
import 'api_client.dart';

// =======================================================
// REVIEW SERVICE
// Chỉ chịu trách nhiệm gọi API review từ BE.
// Không xử lý UI ở đây.
// =======================================================
class ReviewService {
  final ApiClient _apiClient = ApiClient();

  // =======================================================
  // Lấy danh sách đánh giá của một sản phẩm.
  //
  // BE:
  // GET /products/:productId/reviews?page=1&limit=20
  // =======================================================
  Future<ProductReviewResponse> fetchProductReviews({
    required int productId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      '/products/$productId/reviews?page=$page&limit=$limit',
    );

    if (response.data['success'] == true) {
      final data = response.data['data'];

      if (data is Map<String, dynamic>) {
        return ProductReviewResponse.fromJson(data);
      }

      if (data is Map) {
        return ProductReviewResponse.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
    }

    throw Exception(
      response.data['message'] ?? 'Không thể tải đánh giá sản phẩm',
    );
  }

  // =======================================================
  // Tạo đánh giá sản phẩm theo đơn hàng.
  //
  // BE:
  // POST /orders/:id/review
  // Body:
  // {
  //   productId: number,
  //   rating: 1..5,
  //   comment?: string,
  //   images?: string[]
  // }
  // =======================================================
  Future<void> createReviewForOrder({
    required String orderId,
    required int productId,
    required int rating,
    String? comment,
    List<String> images = const [],
  }) async {
    final response = await _apiClient.post(
      '/orders/$orderId/review',
      data: {
        'productId': productId,
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
        if (images.isNotEmpty) 'images': images,
      },
    );

    if (response.data['success'] == true) {
      return;
    }

    throw Exception(response.data['message'] ?? 'Gửi đánh giá thất bại');
  }
}
