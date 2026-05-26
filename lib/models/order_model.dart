// lib/models/order_model.dart

// Model dùng cho màn hình checkout preview.
// BE trả về data.summary gồm: subtotal, shippingFee, total.
class OrderPreview {
  final double subtotal;
  final double shippingFee;
  final double total;

  OrderPreview({
    required this.subtotal,
    required this.shippingFee,
    required this.total,
  });

  factory OrderPreview.fromJson(Map<String, dynamic> json) {
    return OrderPreview(
      subtotal: _toDouble(json['subtotal']),
      shippingFee: _toDouble(json['shippingFee'] ?? json['shipping_fee']),
      total: _toDouble(json['total']),
    );
  }
}

// Model sản phẩm nằm trong đơn hàng.
// BE lưu snapshot để dù sản phẩm bị xóa mềm thì đơn cũ vẫn xem được.
class OrderItemModel {
  final String id;
  final int? productId;
  final int? productVariantId;

  final String nameSnapshot;
  final String? imageSnapshot;

  final double price;
  final int quantity;
  final double totalLine;

  final String? value1;
  final String? value2;
  final String? value3;
  final String? value4;
  final String? value5;

  OrderItemModel({
    required this.id,
    this.productId,
    this.productVariantId,
    required this.nameSnapshot,
    this.imageSnapshot,
    required this.price,
    required this.quantity,
    required this.totalLine,
    this.value1,
    this.value2,
    this.value3,
    this.value4,
    this.value5,
  });

  // Ghép các giá trị biến thể để FE hiển thị rõ ràng trên card đơn hàng.
  // Ví dụ: "Đỏ / Size M" hoặc "Hộp 6 cái".
  String get variantText {
    final values = [
      value1,
      value2,
      value3,
      value4,
      value5,
    ]
        .where((item) => item != null && item.toString().trim().isNotEmpty)
        .map((item) => item.toString().trim())
        .toList();

    return values.join(' / ');
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final product = _asMap(
      json['product'] ?? json['productSnapshot'] ?? json['product_snapshot'],
    );
    final variant = _asMap(
      json['variant'] ??
          json['productVariant'] ??
          json['product_variant'] ??
          json['variantSnapshot'] ??
          json['variant_snapshot'],
    );

    final image = _firstNonEmpty([
      json['imageSnapshot'],
      json['image_snapshot'],
      json['imageUrl'],
      json['image_url'],
      json['productImage'],
      json['product_image'],
    ]) ??
        _imageFromMap(variant) ??
        _imageFromMap(product);

    final variantName = _firstNonEmpty([
      json['variantName'],
      json['variant_name'],
      json['optionName'],
      json['option_name'],
      variant?['name'],
      variant?['label'],
      variant?['title'],
    ]);

    return OrderItemModel(
      id: (json['id'] ?? '').toString(),
      productId: _toIntNullable(
        json['productId'] ?? json['product_id'] ?? product?['id'],
      ),
      productVariantId: _toIntNullable(
        json['productVariantId'] ??
            json['product_variant_id'] ??
            json['variantId'] ??
            json['variant_id'] ??
            variant?['id'],
      ),
      nameSnapshot: _firstNonEmpty([
        json['nameSnapshot'],
        json['name_snapshot'],
        json['productName'],
        json['product_name'],
        json['name'],
        product?['name'],
        product?['title'],
      ]) ??
          'Sản phẩm',
      imageSnapshot: image,
      price: _toDouble(json['price'] ?? json['unitPrice'] ?? json['unit_price']),
      quantity: _toInt(json['quantity']),
      totalLine: _toDouble(
        json['totalLine'] ?? json['total_line'] ?? json['lineTotal'] ?? json['line_total'],
      ),
      value1: _firstNonEmpty([
        json['value1'],
        json['option1'],
        json['attribute1'],
        json['variantValue1'],
        json['variant_value_1'],
        variant?['value1'],
        variant?['option1'],
        variant?['attribute1'],
      ]) ??
          variantName,
      value2: _firstNonEmpty([
        json['value2'],
        json['option2'],
        json['attribute2'],
        json['variantValue2'],
        json['variant_value_2'],
        variant?['value2'],
        variant?['option2'],
        variant?['attribute2'],
      ]),
      value3: _firstNonEmpty([
        json['value3'],
        json['option3'],
        json['attribute3'],
        json['variantValue3'],
        json['variant_value_3'],
        variant?['value3'],
        variant?['option3'],
        variant?['attribute3'],
      ]),
      value4: _firstNonEmpty([
        json['value4'],
        json['option4'],
        json['attribute4'],
        json['variantValue4'],
        json['variant_value_4'],
        variant?['value4'],
        variant?['option4'],
        variant?['attribute4'],
      ]),
      value5: _firstNonEmpty([
        json['value5'],
        json['option5'],
        json['attribute5'],
        json['variantValue5'],
        json['variant_value_5'],
        variant?['value5'],
        variant?['option5'],
        variant?['attribute5'],
      ]),
    );
  }
}

// Model đơn hàng chính.
// Dùng cho cả customer order và seller/shop order.
class OrderModel {
  final String id;
  final String code;

  // PENDING, PROCESSING, PAID, SHIPPED, COMPLETED, CANCELLED...
  final String status;

  // UNPAID, PAID, REFUNDED
  final String paymentStatus;

  // COD, VNPAY
  final String paymentMethod;

  // PENDING, PICKED, IN_TRANSIT, DELIVERED, RETURNED, CANCELED
  final String shippingStatus;

  final double subtotal;
  final double discount;
  final double shippingFee;
  final double total;

  final String? note;
  final DateTime createdAt;
  final dynamic paymentMeta;
  final Map<String, dynamic>? addressSnapshot;
  final List<OrderItemModel>? items;

  OrderModel({
    required this.id,
    required this.code,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.shippingStatus,
    required this.subtotal,
    required this.discount,
    required this.shippingFee,
    required this.total,
    this.note,
    required this.createdAt,
    this.paymentMeta,
    this.addressSnapshot,
    this.items,
  });

  String? get sessionCode {
    final meta = paymentMeta;

    if (meta is Map && meta['sessionCode'] != null) {
      return meta['sessionCode'].toString();
    }

    return null;
  }

  String get receiverName {
    return addressSnapshot?['fullName']?.toString() ?? '';
  }

  String get receiverPhone {
    return addressSnapshot?['phone']?.toString() ?? '';
  }

  String get receiverAddress {
    return addressSnapshot?['formattedAddress']?.toString() ?? '';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'] ?? json['createdAt'];

    final rawAddress = json['address_snapshot'] ?? json['addressSnapshot'];
    Map<String, dynamic>? address;

    if (rawAddress is Map<String, dynamic>) {
      address = rawAddress;
    } else if (rawAddress is Map) {
      address = Map<String, dynamic>.from(rawAddress);
    }

    final rawItems = json['items'] ?? json['orderItems'] ?? json['order_items'];

    return OrderModel(
      id: (json['id'] ?? '').toString(),
      code: _firstNonEmpty([
        json['code'],
        json['orderCode'],
        json['order_code'],
        json['orderNumber'],
        json['order_number'],
      ]) ??
          '',
      status: (json['status'] ?? 'PENDING').toString(),
      paymentStatus: (
          json['payment_status'] ?? json['paymentStatus'] ?? 'UNPAID'
      ).toString(),
      paymentMethod: (
          json['payment_method'] ?? json['paymentMethod'] ?? 'COD'
      ).toString(),
      shippingStatus: (
          json['shipping_status'] ?? json['shippingStatus'] ?? 'PENDING'
      ).toString(),
      subtotal: _toDouble(json['subtotal']),
      discount: _toDouble(json['discount']),
      shippingFee: _toDouble(json['shipping_fee'] ?? json['shippingFee']),
      total: _toDouble(json['total'] ?? json['totalAmount'] ?? json['total_amount']),
      note: json['note']?.toString(),
      createdAt: createdRaw != null
          ? DateTime.tryParse(createdRaw.toString()) ?? DateTime.now()
          : DateTime.now(),
      paymentMeta: json['payment_meta'] ?? json['paymentMeta'],
      addressSnapshot: address,
      items: rawItems is List
          ? rawItems
          .whereType<Map>()
          .map(
            (item) => OrderItemModel.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList()
          : null,
    );
  }
}

// ==================== HELPER PARSE DATA ====================

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();

  return double.tryParse(value.toString()) ?? 0.0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;

  return int.tryParse(value.toString()) ?? 0;
}

int? _toIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;

  return int.tryParse(value.toString());
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    if (value == null) continue;

    final text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }

  return null;
}

String? _imageFromMap(Map<String, dynamic>? map) {
  if (map == null) return null;

  final directImage = _firstNonEmpty([
    map['imageSnapshot'],
    map['image_snapshot'],
    map['imageUrl'],
    map['image_url'],
    map['thumbnail'],
    map['thumbnailUrl'],
    map['thumbnail_url'],
    map['cover'],
    map['url'],
  ]);

  if (directImage != null) return directImage;

  final images = map['images'];
  if (images is List && images.isNotEmpty) {
    final firstImage = images.first;
    if (firstImage is String) return _firstNonEmpty([firstImage]);
    if (firstImage is Map) {
      return _imageFromMap(Map<String, dynamic>.from(firstImage));
    }
  }

  return null;
}
