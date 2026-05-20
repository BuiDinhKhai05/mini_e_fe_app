// lib/models/shop_model.dart
class ShopModel {
  final int id;
  final int userId;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? coverUrl;
  final String? phone;
  final String? email;
  final String? shopAddress;
  final String status; // PENDING, ACTIVE, SUSPENDED
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ShopStatsModel stats;
  final List<dynamic>? products;
  final double? shopLat;
  final double? shopLng;

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
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'],
      logoUrl: json['logoUrl'],
      coverUrl: json['coverUrl'],
      phone: json['phone'],
      email: json['email'],
      shopAddress: json['shopAddress'],
      status: json['status'] as String,
      verifiedAt: json['verifiedAt'] != null ? DateTime.parse(json['verifiedAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      stats: ShopStatsModel.fromJson(json['stats'] ?? {}),
      products: json['products'],
      shopLat: json['shopLat'] != null ? double.tryParse(json['shopLat'].toString()) : null,
      shopLng: json['shopLng'] != null ? double.tryParse(json['shopLng'].toString()) : null,
    );
  }
}

class ShopStatsModel {
  final int productCount;
  final int orderCount;
  final double ratingAvg;
  final int reviewCount;

  ShopStatsModel({
    required this.productCount,
    required this.orderCount,
    required this.ratingAvg,
    required this.reviewCount,
  });

  factory ShopStatsModel.fromJson(Map<String, dynamic> json) {
    return ShopStatsModel(
      productCount: json['productCount'] ?? 0,
      orderCount: json['totalOrders'] ?? json['orderCount'] ?? 0,
      ratingAvg: double.tryParse(json['ratingAvg']?.toString() ?? '0') ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
    );
  }
}