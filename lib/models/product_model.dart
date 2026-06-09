// lib/models/product_model.dart

class ProductStatusValue {
  static const String active = 'ACTIVE';
  static const String outOfStock = 'OUT_OF_STOCK';
  static const String locked = 'LOCKED';
}

class ProductSortValue {
  static const String latest = 'latest';
  static const String bestSelling = 'best_selling';
}

class ProductModel {
  final int id;
  final String title;
  final String? description;
  final double price;

  /// URL ảnh đại diện đã xử lý ưu tiên:
  /// images.isMain -> images[0] -> mainImageUrl -> imageUrl -> thumbnailUrl.
  final String imageUrl;

  /// Danh sách tất cả ảnh từ server.
  final List<ProductImage> images;

  /// Tổng tồn kho product. BE hiện đồng bộ từ variants.
  final int stock;

  /// BE hiện tại dùng: ACTIVE / OUT_OF_STOCK / LOCKED.
  final String status;

  /// Có thể null/0 nếu response cũ chưa trả shopId.
  final int? shopId;
  final String? slug;
  final int? categoryId;

  /// Số lượng đã bán. Dùng cho sort/display bán chạy.
  final int sold;

  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? publishedAt;

  /// Cấu trúc thuộc tính, ví dụ: Màu, Size.
  final List<OptionSchema>? optionSchema;

  /// Danh sách biến thể nếu API detail có trả kèm.
  final List<VariantItem>? variants;

  ProductModel({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.imageUrl,
    this.images = const [],
    this.stock = 0,
    this.status = ProductStatusValue.active,
    this.shopId,
    this.slug,
    this.categoryId,
    this.sold = 0,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.optionSchema,
    this.variants,
  });

  /// Giữ getter này để các màn cũ đang dùng product.mainImageUrl không bị lỗi.
  String? get mainImageUrl => imageUrl.trim().isEmpty ? null : imageUrl;

  String get normalizedStatus => status.toUpperCase().trim();

  bool get isActive => normalizedStatus == ProductStatusValue.active;

  bool get isOutOfStock =>
      normalizedStatus == ProductStatusValue.outOfStock || stock <= 0;

  bool get isLocked => normalizedStatus == ProductStatusValue.locked;

  bool get isDeleted => deletedAt != null && deletedAt!.trim().isNotEmpty;

  bool get canBuy => isActive && !isOutOfStock && !isLocked && !isDeleted;

  String get statusLabel {
    switch (normalizedStatus) {
      case ProductStatusValue.active:
        return stock <= 0 ? 'Hết hàng' : 'Đang bán';
      case ProductStatusValue.outOfStock:
        return 'Hết hàng';
      case ProductStatusValue.locked:
        return 'Đã khóa';
      default:
        return status;
    }
  }

  ProductModel copyWith({
    int? id,
    String? title,
    String? description,
    double? price,
    String? imageUrl,
    List<ProductImage>? images,
    int? stock,
    String? status,
    int? shopId,
    String? slug,
    int? categoryId,
    int? sold,
    String? deletedAt,
    String? createdAt,
    String? updatedAt,
    String? publishedAt,
    List<OptionSchema>? optionSchema,
    List<VariantItem>? variants,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      shopId: shopId ?? this.shopId,
      slug: slug ?? this.slug,
      categoryId: categoryId ?? this.categoryId,
      sold: sold ?? this.sold,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      optionSchema: optionSchema ?? this.optionSchema,
      variants: variants ?? this.variants,
    );
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double _parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static String? _parseNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.trim().isEmpty ? null : text;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final parsedImages = <ProductImage>[];

    if (json['images'] is List) {
      parsedImages.addAll(
        (json['images'] as List)
            .whereType<Map>()
            .map((item) => ProductImage.fromJson(Map<String, dynamic>.from(item)))
            .where((image) => image.url.trim().isNotEmpty)
            .toList(),
      );

      parsedImages.sort((a, b) {
        final byPosition = a.position.compareTo(b.position);
        if (byPosition != 0) return byPosition;
        return a.id.compareTo(b.id);
      });
    }

    String finalUrl = '';

    if (parsedImages.isNotEmpty) {
      final mainImg = parsedImages.firstWhere(
            (img) => img.isMain,
        orElse: () => parsedImages.first,
      );
      finalUrl = mainImg.url;
    } else if ((json['mainImageUrl'] ?? '').toString().trim().isNotEmpty) {
      finalUrl = json['mainImageUrl'].toString();
    } else if ((json['imageUrl'] ?? '').toString().trim().isNotEmpty) {
      finalUrl = json['imageUrl'].toString();
    } else if ((json['thumbnailUrl'] ?? '').toString().trim().isNotEmpty) {
      finalUrl = json['thumbnailUrl'].toString();
    } else if ((json['thumbnail'] ?? '').toString().trim().isNotEmpty) {
      finalUrl = json['thumbnail'].toString();
    }

    final dynamic rawShopId = json['shopId'] ??
        json['shop_id'] ??
        (json['shop'] is Map ? (json['shop'] as Map)['id'] : null);

    final dynamic rawCategoryId = json['categoryId'] ??
        json['category_id'] ??
        (json['category'] is Map ? (json['category'] as Map)['id'] : null);

    final optionSchema = <OptionSchema>[];
    if (json['optionSchema'] is List) {
      optionSchema.addAll(
        (json['optionSchema'] as List)
            .whereType<Map>()
            .map((item) => OptionSchema.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.name.trim().isNotEmpty && item.values.isNotEmpty)
            .toList(),
      );
    }

    final variants = <VariantItem>[];
    if (json['variants'] is List) {
      variants.addAll(
        (json['variants'] as List)
            .whereType<Map>()
            .map((item) => VariantItem.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
    }

    return ProductModel(
      id: _parseInt(json['id'] ?? json['productId'] ?? json['product_id']),
      title: (json['title'] ?? json['name'] ?? 'Không tên').toString(),
      description: _parseNullableString(json['description']),
      price: _parseDouble(json['price']),
      imageUrl: finalUrl,
      images: parsedImages,
      stock: _parseInt(json['stock']),
      status: (json['status'] ?? ProductStatusValue.active).toString(),
      shopId: _parseNullableInt(rawShopId),
      slug: _parseNullableString(json['slug']),
      categoryId: _parseNullableInt(rawCategoryId),
      sold: _parseInt(json['sold']),
      deletedAt: _parseNullableString(json['deletedAt'] ?? json['deleted_at']),
      createdAt: _parseNullableString(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseNullableString(json['updatedAt'] ?? json['updated_at']),
      publishedAt: _parseNullableString(json['publishedAt'] ?? json['published_at']),
      optionSchema: optionSchema,
      variants: variants,
    );
  }
}

class ProductImage {
  final int id;
  final int? productId;
  final String url;
  final bool isMain;
  final int position;
  final String? alt;

  ProductImage({
    required this.id,
    this.productId,
    required this.url,
    required this.isMain,
    required this.position,
    this.alt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: ProductModel._parseInt(json['id']),
      productId: ProductModel._parseNullableInt(json['productId'] ?? json['product_id']),
      url: (json['url'] ?? json['imageUrl'] ?? json['image_url'] ?? '').toString(),
      isMain: json['isMain'] == true ||
          json['isMain'] == 1 ||
          json['is_main'] == true ||
          json['is_main'] == 1,
      position: ProductModel._parseInt(json['position']),
      alt: ProductModel._parseNullableString(json['alt']),
    );
  }
}

class OptionSchema {
  final String name;
  final List<String> values;

  OptionSchema({required this.name, required this.values});

  factory OptionSchema.fromJson(Map<String, dynamic> json) {
    return OptionSchema(
      name: json['name']?.toString() ?? '',
      values: (json['values'] as List?)
          ?.map((e) => e.toString())
          .where((value) => value.trim().isNotEmpty)
          .toList() ??
          [],
    );
  }
}

class VariantItem {
  final int id;
  final String name;
  final String sku;
  final double price;
  final int stock;
  final int? imageId;
  final List<Map<String, String>> options;

  VariantItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    this.imageId,
    this.options = const [],
  });

  bool get isOutOfStock => stock <= 0;

  factory VariantItem.fromJson(Map<String, dynamic> json) {
    final parsedOptions = <Map<String, String>>[];

    if (json['options'] is List) {
      parsedOptions.addAll(
        (json['options'] as List).whereType<Map>().map((opt) {
          return {
            'option': opt['option']?.toString() ?? '',
            'value': opt['value']?.toString() ?? '',
          };
        }).where((opt) {
          return (opt['option'] ?? '').trim().isNotEmpty ||
              (opt['value'] ?? '').trim().isNotEmpty;
        }).toList(),
      );
    } else {
      for (int i = 1; i <= 5; i++) {
        final val = json['value$i'];
        if (val != null && val.toString().trim().isNotEmpty) {
          parsedOptions.add({
            'option': 'Thuộc tính $i',
            'value': val.toString(),
          });
        }
      }
    }

    return VariantItem(
      id: ProductModel._parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      price: ProductModel._parseDouble(json['price']),
      stock: ProductModel._parseInt(json['stock']),
      imageId: ProductModel._parseNullableInt(json['imageId'] ?? json['image_id']),
      options: parsedOptions,
    );
  }
}
