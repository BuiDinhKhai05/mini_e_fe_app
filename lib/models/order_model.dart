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
    return OrderItemModel(
      id: (json['id'] ?? '').toString(),
      productId: _toIntNullable(json['productId'] ?? json['product_id']),
      productVariantId: _toIntNullable(
        json['productVariantId'] ??
            json['product_variant_id'] ??
            json['variantId'],
      ),
      nameSnapshot: (
          json['nameSnapshot'] ??
              json['name_snapshot'] ??
              json['name'] ??
              'Sản phẩm'
      )
          .toString(),
      imageSnapshot: (
          json['imageSnapshot'] ??
              json['image_snapshot'] ??
              json['imageUrl']
      )?.toString(),
      price: _toDouble(json['price']),
      quantity: _toInt(json['quantity']),
      totalLine: _toDouble(json['totalLine'] ?? json['total_line']),
      value1: json['value1']?.toString(),
      value2: json['value2']?.toString(),
      value3: json['value3']?.toString(),
      value4: json['value4']?.toString(),
      value5: json['value5']?.toString(),
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

    final rawItems = json['items'];

    return OrderModel(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      paymentStatus: (
          json['payment_status'] ??
              json['paymentStatus'] ??
              'UNPAID'
      )
          .toString(),
      paymentMethod: (
          json['payment_method'] ??
              json['paymentMethod'] ??
              'COD'
      )
          .toString(),
      shippingStatus: (
          json['shipping_status'] ??
              json['shippingStatus'] ??
              'PENDING'
      )
          .toString(),
      subtotal: _toDouble(json['subtotal']),
      discount: _toDouble(json['discount']),
      shippingFee: _toDouble(json['shipping_fee'] ?? json['shippingFee']),
      total: _toDouble(json['total']),
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