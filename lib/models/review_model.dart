// lib/models/review_model.dart

// =======================================================
// MODEL RESPONSE DANH SÁCH REVIEW THEO SẢN PHẨM
// Dùng cho API:
// GET /products/:productId/reviews?page=1&limit=20
// =======================================================
class ProductReviewResponse {
  final ProductReviewSummary summary;
  final List<ProductReviewItem> items;
  final int page;
  final int limit;
  final int total;

  ProductReviewResponse({
    required this.summary,
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory ProductReviewResponse.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['summary'];
    final rawItems = json['items'];

    return ProductReviewResponse(
      summary: rawSummary is Map
          ? ProductReviewSummary.fromJson(
        Map<String, dynamic>.from(rawSummary),
      )
          : ProductReviewSummary.empty(),
      items: rawItems is List
          ? rawItems
          .whereType<Map>()
          .map(
            (item) => ProductReviewItem.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList()
          : [],
      page: _toInt(json['page'], defaultValue: 1),
      limit: _toInt(json['limit'], defaultValue: 20),
      total: _toInt(json['total']),
    );
  }
}

// =======================================================
// MODEL TỔNG QUAN ĐÁNH GIÁ
// BE trả về:
// summary: {
//   count,
//   avg
// }
// =======================================================
class ProductReviewSummary {
  final int count;
  final double avg;

  ProductReviewSummary({
    required this.count,
    required this.avg,
  });

  factory ProductReviewSummary.empty() {
    return ProductReviewSummary(
      count: 0,
      avg: 0,
    );
  }

  factory ProductReviewSummary.fromJson(Map<String, dynamic> json) {
    return ProductReviewSummary(
      count: _toInt(json['count']),
      avg: _toDouble(json['avg']),
    );
  }
}

// =======================================================
// MODEL USER TRONG REVIEW
// BE trả về:
// user: {
//   id,
//   name,
//   avatarUrl
// }
// =======================================================
class ProductReviewUser {
  final int id;
  final String name;
  final String? avatarUrl;

  ProductReviewUser({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory ProductReviewUser.fromJson(Map<String, dynamic> json) {
    return ProductReviewUser(
      id: _toInt(json['id']),
      name: (json['name'] ?? 'Người dùng').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

// =======================================================
// MODEL MỘT ĐÁNH GIÁ SẢN PHẨM
// BE trả về:
// id, orderId, userId, productId, rating, comment,
// images, createdAt, updatedAt, user
// =======================================================
class ProductReviewItem {
  final String id;
  final String orderId;
  final int userId;
  final int productId;
  final int rating;
  final String? comment;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProductReviewUser? user;

  ProductReviewItem({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.productId,
    required this.rating,
    this.comment,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  // Dùng để kiểm tra review có bình luận hay không.
  bool get hasComment => comment != null && comment!.trim().isNotEmpty;

  // Dùng để kiểm tra review có hình ảnh hay không.
  bool get hasImages => images.isNotEmpty;

  // Tên user hiển thị trên giao diện.
  String get userName => user?.name ?? 'Người dùng';

  // Avatar user hiển thị trên giao diện.
  String? get userAvatarUrl => user?.avatarUrl;

  factory ProductReviewItem.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final rawUser = json['user'];

    return ProductReviewItem(
      id: (json['id'] ?? '').toString(),
      orderId: (json['orderId'] ?? json['order_id'] ?? '').toString(),
      userId: _toInt(json['userId'] ?? json['user_id']),
      productId: _toInt(json['productId'] ?? json['product_id']),
      rating: _toInt(json['rating']),
      comment: json['comment']?.toString(),
      images: rawImages is List
          ? rawImages.map((item) => item.toString()).toList()
          : [],
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
      user: rawUser is Map
          ? ProductReviewUser.fromJson(
        Map<String, dynamic>.from(rawUser),
      )
          : null,
    );
  }
}

// =======================================================
// HELPER PARSE DATA
// Giúp tránh lỗi khi BE trả number dạng string hoặc null.
// =======================================================
int _toInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? defaultValue;
}

double _toDouble(dynamic value, {double defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? defaultValue;
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}