// lib/models/shop_model.dart

class ShopModel {
  final int id;
  final int? userId;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? coverUrl;

  // FE dùng tên phone cho tiện hiển thị,
  // nhưng BE hiện tại trả/lưu field là shopPhone.
  final String? phone;
  final String? email;
  final String? shopAddress;
  final String status; // PENDING, ACTIVE, SUSPENDED
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ShopStatsModel stats;

  // BE shop detail hiện tại không load relation products.
  // Field này vẫn giữ để không vỡ code nếu sau này BE trả thêm products.
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
      userId: json['userId'] == null ? null : _toInt(json['userId']),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: _toNullableString(json['description']),
      logoUrl: _toNullableString(json['logoUrl']),
      coverUrl: _toNullableString(json['coverUrl']),

      // Đồng bộ BE: entity/DTO dùng shopPhone.
      // Giữ fallback phone để tương thích dữ liệu migration cũ.
      phone: _toNullableString(json['shopPhone'] ?? json['phone']),
      email: _toNullableString(json['email']),
      shopAddress: _toNullableString(json['shopAddress']),
      status: (json['status'] ?? 'PENDING').toString(),
      verifiedAt: _toDateTime(json['verifiedAt']),
      createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDateTime(json['updatedAt']) ?? DateTime.now(),
      stats: ShopStatsModel.fromJson(json['stats'] ?? json),
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

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
