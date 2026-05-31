// lib/models/shop_model.dart

enum ShopOrderRange {
  today,
  sevenDays,
  thirtyDays,
  all,
}

extension ShopOrderRangeX on ShopOrderRange {
  String get queryValue {
    switch (this) {
      case ShopOrderRange.today:
        return '1';
      case ShopOrderRange.sevenDays:
        return '7';
      case ShopOrderRange.thirtyDays:
        return '30';
      case ShopOrderRange.all:
        return 'all';
    }
  }

  String get label {
    switch (this) {
      case ShopOrderRange.today:
        return 'Hôm nay';
      case ShopOrderRange.sevenDays:
        return '7 ngày';
      case ShopOrderRange.thirtyDays:
        return '30 ngày';
      case ShopOrderRange.all:
        return 'Tất cả';
    }
  }
}

class ShopModel {
  final int id;
  final int? userId;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? coverUrl;

  final String? phone;
  final String? email;
  final String? shopAddress;
  final String status;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ShopStatsModel stats;

  final List<dynamic>? products;

  final double? shopLat;
  final double? shopLng;
  final String? shopPlaceId;

  ShopModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.coverUrl,
    this.phone,
    this.email,
    this.shopAddress,
    required this.status,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.stats,
    this.products,
    this.shopLat,
    this.shopLng,
    this.shopPlaceId,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: _toInt(json['id']),
      userId: _extractUserId(json),
      name: (json['name'] ?? json['shopName'] ?? json['storeName'] ?? '')
          .toString(),
      slug: (json['slug'] ?? '').toString(),
      description: _toNullableString(json['description']),
      logoUrl: _toNullableString(
        json['logoUrl'] ?? json['logo'] ?? json['avatarUrl'],
      ),
      coverUrl: _toNullableString(json['coverUrl'] ?? json['coverImageUrl']),
      phone: _toNullableString(json['shopPhone'] ?? json['phone']),
      email: _toNullableString(json['email']),
      shopAddress: _toNullableString(json['shopAddress'] ?? json['address']),
      status: (json['status'] ?? 'PENDING').toString(),
      verifiedAt: _toDateTime(json['verifiedAt']),
      createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDateTime(json['updatedAt']) ?? DateTime.now(),
      stats: ShopStatsModel.fromJson(
        json['stats'] is Map<String, dynamic> ? json['stats'] : json,
      ),
      products: json['products'] is List ? List<dynamic>.from(json['products']) : null,
      shopLat: _toDouble(json['shopLat']),
      shopLng: _toDouble(json['shopLng']),
      shopPlaceId: _toNullableString(json['shopPlaceId']),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'email': email,
      'description': description,
      'shopAddress': shopAddress,
      'shopLat': shopLat,
      'shopLng': shopLng,
      'shopPlaceId': shopPlaceId,
      'shopPhone': phone,
    };
  }

  static int? _extractUserId(Map<String, dynamic> json) {
    final direct =
        json['userId'] ?? json['user_id'] ?? json['ownerId'] ?? json['owner_id'];

    final directId = _toNullableInt(direct);
    if (directId != null) return directId;

    final user = json['user'] ?? json['owner'] ?? json['seller'];

    if (user is Map) {
      return _toNullableInt(user['id']);
    }

    return null;
  }
}

class ShopStatsModel {
  final int productCount;
  final int orderCount;
  final int totalSold;
  final double totalRevenue;
  final double ratingAvg;
  final int reviewCount;

  ShopStatsModel({
    required this.productCount,
    required this.orderCount,
    required this.totalSold,
    required this.totalRevenue,
    required this.ratingAvg,
    required this.reviewCount,
  });

  factory ShopStatsModel.fromJson(Map<String, dynamic> json) {
    return ShopStatsModel(
      productCount: _toInt(json['productCount']),
      orderCount: _toInt(json['totalOrders'] ?? json['orderCount']),
      totalSold: _toInt(json['totalSold']),
      totalRevenue: _toDouble(json['totalRevenue']) ?? 0.0,
      ratingAvg: _toDouble(json['ratingAvg']) ?? 0.0,
      reviewCount: _toInt(json['reviewCount']),
    );
  }
}

class ShopOrdersResult {
  final List<ShopOrderModel> items;
  final int page;
  final int limit;
  final int total;

  ShopOrdersResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory ShopOrdersResult.fromJson(dynamic json) {
    dynamic current = json;

    if (current is Map && current['data'] is Map) {
      current = current['data'];
    }

    if (current is! Map) {
      return ShopOrdersResult(
        items: const [],
        page: 1,
        limit: 20,
        total: 0,
      );
    }

    final map = Map<String, dynamic>.from(current);

    final rawItems = map['items'] ??
        map['orders'] ??
        map['rows'] ??
        map['results'] ??
        map['data'] ??
        [];

    final items = rawItems is List
        ? rawItems
        .whereType<Map>()
        .map((item) => ShopOrderModel.fromJson(
      Map<String, dynamic>.from(item),
    ))
        .toList()
        : <ShopOrderModel>[];

    return ShopOrdersResult(
      items: items,
      page: _toInt(map['page'] ?? 1),
      limit: _toInt(map['limit'] ?? items.length),
      total: _toInt(map['total'] ?? items.length),
    );
  }
}

class ShopOrderModel {
  final String id;
  final String code;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String shippingStatus;
  final double total;
  final DateTime? createdAt;

  ShopOrderModel({
    required this.id,
    required this.code,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.shippingStatus,
    required this.total,
    required this.createdAt,
  });

  factory ShopOrderModel.fromJson(Map<String, dynamic> json) {
    return ShopOrderModel(
      id: _toStringValue(json['id']),
      code: _toStringValue(json['code'] ?? json['orderCode'] ?? json['id']),
      status: _toStringValue(json['status']),
      paymentStatus: _toStringValue(
        json['paymentStatus'] ?? json['payment_status'],
      ),
      paymentMethod: _toStringValue(
        json['paymentMethod'] ?? json['payment_method'],
      ),
      shippingStatus: _toStringValue(
        json['shippingStatus'] ?? json['shipping_status'],
      ),
      total: _toDouble(json['total']) ?? 0.0,
      createdAt: _toDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  bool get isReturnedOrCanceled {
    final orderStatus = status.toUpperCase();
    final shipStatus = shippingStatus.toUpperCase();

    return orderStatus == 'CANCELED' ||
        orderStatus == 'CANCELLED' ||
        shipStatus == 'CANCELED' ||
        shipStatus == 'CANCELLED' ||
        shipStatus == 'RETURNED';
  }

  bool get isRevenueOrder {
    if (isReturnedOrCanceled) return false;

    final orderStatus = status.toUpperCase();
    final payStatus = paymentStatus.toUpperCase();

    return orderStatus == 'COMPLETED' ||
        orderStatus == 'PAID' ||
        payStatus == 'PAID';
  }
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String? _toNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String _toStringValue(dynamic value) {
  return (value ?? '').toString();
}