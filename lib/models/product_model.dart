// lib/models/product_model.dart

class ProductModel {
  final int id;
  final String title;
  final String? description;
  final double price;

  // URL ảnh đại diện (đã xử lý logic ưu tiên isMain)
  final String imageUrl;

  // Danh sách tất cả ảnh từ server
  final List<ProductImage> images;

  final int stock;
  final String status;
  final int shopId;
  final String? slug;

  // Cấu trúc thuộc tính (VD: Màu, Size)
  final List<OptionSchema>? optionSchema;

  // Danh sách biến thể
  final List<VariantItem>? variants;

  ProductModel({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.imageUrl,
    this.images = const [],
    this.stock = 0,
    this.status = 'DRAFT',
    required this.shopId,
    this.slug,
    this.optionSchema,
    this.variants,
  });


  /// Tạo bản sao ProductModel khi FE cần cập nhật cục bộ
  /// (ví dụ đổi ACTIVE/DRAFT) mà không phải gọi lại public detail.
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
      optionSchema: optionSchema ?? this.optionSchema,
      variants: variants ?? this.variants,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // 1. Xử lý danh sách ảnh
    List<ProductImage> parsedImages = [];
    if (json['images'] != null && json['images'] is List) {
      parsedImages = (json['images'] as List)
          .map((item) => ProductImage.fromJson(item))
          .toList();

      // Sắp xếp ảnh theo position (quan trọng để hiển thị đúng thứ tự)
      parsedImages.sort((a, b) => a.position.compareTo(b.position));
    }

    // 2. Logic chọn ảnh Thumbnail (imageUrl)
    String finalUrl = '';
    if (parsedImages.isNotEmpty) {
      // Ưu tiên 1: Ảnh có isMain = true
      // Ưu tiên 2: Ảnh đầu tiên trong list
      final mainImg = parsedImages.firstWhere(
            (img) => img.isMain == true,
        orElse: () => parsedImages.first,
      );
      finalUrl = mainImg.url;
    }
    // ✅ LIST API (GET /products) của BE đang trả: mainImageUrl
    else if (json['mainImageUrl'] != null &&
        json['mainImageUrl'].toString().isNotEmpty) {
      finalUrl = json['mainImageUrl'].toString();
    }
    // Fallback: Nếu backend gửi field imageUrl riêng lẻ (ít dùng nhưng cứ để dự phòng)
    else if (json['imageUrl'] != null &&
        json['imageUrl'].toString().isNotEmpty) {
      finalUrl = json['imageUrl'].toString();
    }

    // 3. Xử lý giá tiền (Chuyển đổi an toàn từ String/Number)
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
    }

    return ProductModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Không tên',
      description: json['description'],
      price: parsedPrice,
      imageUrl: finalUrl,
      images: parsedImages,
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'DRAFT',
      shopId: json['shopId'] ?? 0,
      slug: json['slug'],

      // Parse Option Schema
      optionSchema: json['optionSchema'] != null
          ? (json['optionSchema'] as List)
          .map((e) => OptionSchema.fromJson(e))
          .toList()
          : [],

      // Parse Variants
      variants: json['variants'] != null
          ? (json['variants'] as List)
          .map((v) => VariantItem.fromJson(v))
          .toList()
          : [],
    );
  }
}

// Class cho từng ảnh
class ProductImage {
  final int id;
  final String url;
  final bool isMain;
  final int position;
  final String? alt;

  ProductImage({
    required this.id,
    required this.url,
    required this.isMain,
    required this.position,
    this.alt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      // BE của bạn đang dùng field: url
      // Để an toàn, hỗ trợ thêm key imageUrl (một số BE hay đặt vậy)
      url: (json['url'] ?? json['imageUrl'] ?? '').toString(),
      // Lưu ý: BE trả về boolean, nhưng đôi khi là 0/1 (tinyint)
      isMain: (json['isMain'] == true || json['isMain'] == 1),
      position: int.tryParse(json['position']?.toString() ?? '0') ?? 0,
      alt: json['alt'],
    );
  }
}

// Giữ nguyên OptionSchema và VariantItem
class OptionSchema {
  final String name;
  final List<String> values;

  OptionSchema({required this.name, required this.values});

  factory OptionSchema.fromJson(Map<String, dynamic> json) {
    return OptionSchema(
      name: json['name']?.toString() ?? '',
      values:
      (json['values'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// Class đại diện cho biến thể sản phẩm (Variant)
class VariantItem {
  final int id;
  final String name;
  final String sku;
  final double price;
  final int stock;
  final int? imageId;
  // Options: Mapping linh hoạt để UI dễ hiển thị
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

  factory VariantItem.fromJson(Map<String, dynamic> json) {
    // XỬ LÝ OPTIONS TỪ BE (Quan trọng)
    // BE Entity dùng cột: value1, value2, value3...
    // FE UI cần list: [{option: 'Màu', value: 'Đỏ'}]

    List<Map<String, String>> parsedOptions = [];

    // CÁCH 1: Nếu BE đã map sẵn thành mảng 'options' (DTO generated)
    if (json['options'] != null && json['options'] is List) {
      parsedOptions = (json['options'] as List).map((opt) {
        return {
          'option': opt['option']?.toString() ?? '',
          'value': opt['value']?.toString() ?? '',
        };
      }).toList();
    }
    // CÁCH 2: Nếu BE trả về raw entity (value1, value2...)
    else {
      // Chúng ta gom value1 -> value5 vào list để UI hiển thị tạm
      for (int i = 1; i <= 5; i++) {
        String? val = json['value$i'];
        if (val != null && val.isNotEmpty) {
          parsedOptions.add({
            'option': 'Thuộc tính $i',
            'value': val,
          });
        }
      }
    }

    return VariantItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      sku: json['sku'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      imageId: json['imageId'],
      options: parsedOptions,
    );
  }
}
