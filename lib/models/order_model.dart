// lib/models/order_model.dart

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
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      shippingFee: double.tryParse(json['shippingFee']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }
}

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
    final values = [value1, value2, value3, value4, value5]
        .where((value) => value != null && value!.trim().isNotEmpty)
        .map((value) => value!.trim())
        .toList();
    return values.join(' / ');
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: (json['id'] ?? '').toString(),
      productId: int.tryParse((json['productId'] ?? json['product_id'] ?? '').toString()),
      productVariantId: int.tryParse(
        (json['productVariantId'] ?? json['product_variant_id'] ?? '').toString(),
      ),
      nameSnapshot: (json['nameSnapshot'] ?? json['name_snapshot'] ?? 'Sản phẩm').toString(),
      imageSnapshot: (json['imageSnapshot'] ?? json['image_snapshot'])?.toString(),
      price: double.tryParse((json['price'] ?? '0').toString()) ?? 0.0,
      quantity: int.tryParse((json['quantity'] ?? '1').toString()) ?? 1,
      totalLine: double.tryParse((json['totalLine'] ?? json['total_line'] ?? '0').toString()) ?? 0.0,
      value1: json['value1']?.toString(),
      value2: json['value2']?.toString(),
      value3: json['value3']?.toString(),
      value4: json['value4']?.toString(),
      value5: json['value5']?.toString(),
    );
  }
}

class OrderModel {
  final String id;
  final String code;
  final String status; // PENDING, PAID, PROCESSING, SHIPPED, COMPLETED, CANCELLED
  final String paymentStatus; // UNPAID, PAID, REFUNDED
  final String paymentMethod; // COD, VNPAY
  final String shippingStatus; // PENDING, PICKED, IN_TRANSIT, DELIVERED, RETURNED, CANCELED
  final double total;
  final DateTime createdAt;
  final dynamic paymentMeta;
  final List<OrderItemModel>? items;

  OrderModel({
    required this.id,
    required this.code,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.shippingStatus,
    required this.total,
    required this.createdAt,
    this.paymentMeta,
    this.items,
  });

  String? get sessionCode {
    final meta = paymentMeta;
    if (meta is Map && meta['sessionCode'] != null) return meta['sessionCode'].toString();
    return null;
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'] ?? json['createdAt'];
    final rawItems = json['items'];

    return OrderModel(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      status: (json['status'] ?? 'PENDING').toString(),
      paymentStatus: (json['payment_status'] ?? json['paymentStatus'] ?? 'UNPAID').toString(),
      paymentMethod: (json['payment_method'] ?? json['paymentMethod'] ?? 'COD').toString(),
      shippingStatus: (json['shipping_status'] ?? json['shippingStatus'] ?? 'PENDING').toString(),
      total: double.tryParse((json['total'] ?? '0').toString()) ?? 0.0,
      createdAt: createdRaw != null ? DateTime.parse(createdRaw.toString()) : DateTime.now(),
      paymentMeta: json['payment_meta'] ?? json['paymentMeta'],
      items: rawItems is List
          ? rawItems
          .whereType<Map>()
          .map((item) => OrderItemModel.fromJson(Map<String, dynamic>.from(item)))
          .toList()
          : null,
    );
  }
}
