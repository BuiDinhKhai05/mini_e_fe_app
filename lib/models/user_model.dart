import 'dart:convert';

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? birthday;
  final String? gender; // 'MALE' | 'FEMALE' | 'OTHER'
  final String? role; // 'USER' | 'SELLER' | 'ADMIN'
  final bool? isVerified;
  final bool? isSystem;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int shopId;

  UserModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.birthday,
    this.gender,
    this.role,
    this.isVerified,
    this.isSystem,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.shopId = 0,
  });

  // ════════════════════════════════════════════════════════════════════════
  //                          HELPER PARSE DỮ LIỆU TỪ BE
  // ════════════════════════════════════════════════════════════════════════
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().toLowerCase().trim();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static int _parseShopId(Map<String, dynamic> json) {
    // BE hiện tại có thể trả shopId trực tiếp, hoặc trả object shop.
    final directShopId = _parseInt(json['shopId'] ?? json['shop_id']);
    if (directShopId > 0) return directShopId;

    final shop = json['shop'];
    if (shop is Map<String, dynamic>) {
      return _parseInt(shop['id']);
    }

    return 0;
  }

  // ════════════════════════════════════════════════════════════════════════
  //                          FROM JSON
  // ════════════════════════════════════════════════════════════════════════
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseString(json['id']),
      name: _parseString(json['name']),
      email: _parseString(json['email']),
      phone: _parseString(json['phone']),
      avatarUrl: _parseString(json['avatarUrl'] ?? json['avatar_url']),
      birthday: _parseString(json['birthday']),
      gender: _parseString(json['gender']),
      role: _parseString(json['role']),
      isVerified: _parseBool(json['isVerified'] ?? json['is_verified']),
      isSystem: _parseBool(json['isSystem'] ?? json['is_system']),
      lastLoginAt: _parseDate(json['lastLoginAt'] ?? json['last_login_at']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
      deletedAt: _parseDate(json['deletedAt'] ?? json['deleted_at']),
      shopId: _parseShopId(json),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //                          TO JSON
  // ════════════════════════════════════════════════════════════════════════
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'birthday': birthday,
      'gender': gender,
      'role': role,
      'isVerified': isVerified,
      'isSystem': isSystem,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'shopId': shopId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  String toRawJson() => jsonEncode(toJson());

  factory UserModel.fromRawJson(String source) {
    return UserModel.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }

  // ════════════════════════════════════════════════════════════════════════
  //                          STATIC LIST FROM
  // ════════════════════════════════════════════════════════════════════════
  /// Parse List<dynamic> → List<UserModel>
  static List<UserModel> listFrom(dynamic jsonList) {
    if (jsonList is! List) return <UserModel>[];
    return jsonList
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  // ════════════════════════════════════════════════════════════════════════
  //                          COPY WITH
  // ════════════════════════════════════════════════════════════════════════
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? birthday,
    String? gender,
    String? role,
    bool? isVerified,
    bool? isSystem,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    int? shopId,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isSystem: isSystem ?? this.isSystem,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      shopId: shopId ?? this.shopId,
    );
  }
}
