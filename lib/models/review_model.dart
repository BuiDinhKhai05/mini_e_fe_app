// lib/models/review_model.dart

import 'dart:convert';

// =======================================================
// REVIEW MODEL
// Chỉ xử lý parse dữ liệu FE theo format BE hiện tại:
// - BE bọc response bằng { success: true, data: ... }
// - GET /products/:productId/reviews trả data.summary + data.items
// - GET /orders/:id/review có thể trả data = null/object/list
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

  factory ProductReviewResponse.empty() {
    return ProductReviewResponse(
      summary: ProductReviewSummary.empty(),
      items: const [],
      page: 1,
      limit: 20,
      total: 0,
    );
  }

  factory ProductReviewResponse.fromJson(Map<String, dynamic> json) {
    // BE hiện tại trả:
    // {
    //   success: true,
    //   data: {
    //     summary: { count, avg },
    //     items: [...],
    //     page, limit, total
    //   }
    // }
    final rawData = json['data'];
    final Map<String, dynamic> data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : Map<String, dynamic>.from(json);

    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
        .whereType<Map>()
        .map((item) => ProductReviewItem.fromJson(
      Map<String, dynamic>.from(item),
    ))
        .where((item) => item.id.isNotEmpty)
        .toList()
        : <ProductReviewItem>[];

    final summary = ProductReviewSummary.fromJson(
      data['summary'] is Map
          ? Map<String, dynamic>.from(data['summary'])
          : const <String, dynamic>{},
    );

    return ProductReviewResponse(
      summary: summary,
      items: items,
      page: _toInt(data['page']) ?? 1,
      limit: _toInt(data['limit']) ?? 20,
      // BE trả total riêng, còn summary.count là tổng review thực tế.
      total: _toInt(data['total']) ?? summary.count,
    );
  }
}

class ProductReviewSummary {
  final int count;
  final double avg;

  const ProductReviewSummary({
    required this.count,
    required this.avg,
  });

  factory ProductReviewSummary.empty() {
    return const ProductReviewSummary(count: 0, avg: 0);
  }

  factory ProductReviewSummary.fromJson(Map<String, dynamic> json) {
    return ProductReviewSummary(
      count: _toInt(
        json['count'] ??
            json['reviewCount'] ??
            json['total'] ??
            json['totalReviews'],
      ) ??
          0,
      avg: _toDouble(
        json['avg'] ??
            json['ratingAvg'] ??
            json['average'] ??
            json['averageRating'],
      ) ??
          0,
    );
  }
}

class ProductReviewItem {
  final String id;
  final String? orderId;
  final int? userId;
  final int productId;
  final int rating;
  final String? comment;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  // FE hiển thị từ user object hoặc snapshot BE lưu lại.
  final String userName;
  final String? userAvatarUrl;
  final bool isDeletedUser;

  // Dùng khi hiển thị review shop.
  // Vì BE review shop trả thêm product: { id, title, slug }.
  final String? productTitle;
  final String? productSlug;

  const ProductReviewItem({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.userName,
    required this.userAvatarUrl,
    required this.isDeletedUser,
    this.productTitle,
    this.productSlug,
  });

  bool get hasComment => comment != null && comment!.trim().isNotEmpty;
  bool get hasImages => images.isNotEmpty;
  bool get hasProductTitle =>
      productTitle != null && productTitle!.trim().isNotEmpty;

  factory ProductReviewItem.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final Map<String, dynamic> user = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : const <String, dynamic>{};

    final rawProduct = json['product'];
    final Map<String, dynamic> product = rawProduct is Map
        ? Map<String, dynamic>.from(rawProduct)
        : const <String, dynamic>{};

    final rawName = user['name'] ??
        json['userNameSnapshot'] ??
        json['user_name_snapshot'] ??
        json['userName'] ??
        json['user_name'] ??
        'Người dùng Mochi';

    final safeUserName = rawName.toString().trim().isEmpty
        ? 'Người dùng Mochi'
        : rawName.toString().trim();

    final avatar = user['avatarUrl'] ??
        user['avatar_url'] ??
        json['userAvatarSnapshot'] ??
        json['user_avatar_snapshot'] ??
        json['userAvatarUrl'] ??
        json['user_avatar_url'];

    final parsedUserId = _toInt(json['userId'] ?? json['user_id'] ?? user['id']);

    final parsedProductId = _toInt(
      json['productId'] ??
          json['product_id'] ??
          product['id'],
    ) ??
        0;

    final productTitle = _emptyToNull(
      product['title'] ??
          product['name'] ??
          json['productTitle'] ??
          json['product_title'] ??
          json['productName'] ??
          json['product_name'],
    );

    final productSlug = _emptyToNull(
      product['slug'] ??
          json['productSlug'] ??
          json['product_slug'],
    );

    final hasUsefulName =
        safeUserName.isNotEmpty && safeUserName != 'Người dùng đã xóa';

    return ProductReviewItem(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString(),
      userId: parsedUserId,
      productId: parsedProductId,
      rating: (_toInt(json['rating']) ?? 0).clamp(0, 5).toInt(),
      comment: _emptyToNull(json['comment'] ?? json['content']),
      images: _toStringList(json['images']),
      createdAt: _toDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _toDateTime(
        json['updatedAt'] ??
            json['updated_at'] ??
            json['createdAt'] ??
            json['created_at'],
      ),
      userName: safeUserName,
      userAvatarUrl: _emptyToNull(avatar),
      isDeletedUser: user['isDeleted'] == true ||
          user['is_deleted'] == true ||
          (parsedUserId == null && !hasUsefulName),
      productTitle: productTitle,
      productSlug: productSlug,
    );
  }
}

class CreateReviewRequest {
  final String orderId;
  final int productId;
  final int rating;
  final String? comment;
  final List<String> images;

  CreateReviewRequest({
    required this.orderId,
    required this.productId,
    required this.rating,
    this.comment,
    this.images = const [],
  });

  // Dùng cho POST /product-reviews
  Map<String, dynamic> toProductReviewsJson() {
    return {
      'orderId': orderId,
      'productId': productId,
      'rating': rating.clamp(1, 5).toInt(),
      if (comment != null && comment!.trim().isNotEmpty) 'comment': comment!.trim(),
      if (images.isNotEmpty)
        'images': images.where((url) => url.trim().isNotEmpty).take(6).toList(),
    };
  }

  // Dùng cho POST /orders/:id/review
  Map<String, dynamic> toOrderReviewJson() {
    return {
      'productId': productId,
      'rating': rating.clamp(1, 5).toInt(),
      if (comment != null && comment!.trim().isNotEmpty) 'comment': comment!.trim(),
      if (images.isNotEmpty)
        'images': images.where((url) => url.trim().isNotEmpty).take(6).toList(),
    };
  }
}

class OrderReviewResult {
  final List<ProductReviewItem> items;

  const OrderReviewResult({required this.items});

  factory OrderReviewResult.fromJson(Map<String, dynamic> json) {
    // BE hiện tại:
    // { success: true, data: null }
    // { success: true, data: {...} }
    // { success: true, data: [...] }
    final rawData = json.containsKey('data') ? json['data'] : json;

    if (rawData == null) {
      return const OrderReviewResult(items: []);
    }

    if (rawData is List) {
      return OrderReviewResult(
        items: rawData
            .whereType<Map>()
            .map((item) => ProductReviewItem.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id.isNotEmpty)
            .toList(),
      );
    }

    if (rawData is Map) {
      final item = ProductReviewItem.fromJson(Map<String, dynamic>.from(rawData));
      return OrderReviewResult(items: item.id.isNotEmpty ? [item] : []);
    }

    return const OrderReviewResult(items: []);
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _emptyToNull(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

List<String> _toStringList(dynamic value) {
  if (value == null) return [];

  if (value is List) {
    return value
        .where((item) => item != null)
        .map((item) => item.toString().trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  // Phòng trường hợp DB/BE cũ trả images là chuỗi JSON: '["url1", "url2"]'.
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return [];

    try {
      final decoded = jsonDecode(text);
      if (decoded is List) {
        return decoded
            .where((item) => item != null)
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {
      return [text];
    }

    return [text];
  }

  return [];
}

DateTime _toDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}
