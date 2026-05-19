// lib/models/cart_model.dart

/// ---------------------------------------------------------------------------
/// 1. CART RESPONSE (Wrapper trả về từ Backend)
/// ---------------------------------------------------------------------------
class CartResponse {
  final bool success;
  final CartData? data;

  CartResponse({required this.success, this.data});

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? CartData.fromJson(json['data']) : null,
    );
  }
}

/// ---------------------------------------------------------------------------
/// 2. CART DATA (Thông tin chung của giỏ hàng)
/// ---------------------------------------------------------------------------
class CartData {
  final int id;
  final String currency;
  final int itemsCount;
  final int itemsQuantity;
  final double subtotal; // tổng tiền server trả về (tất cả item)
  final List<CartItemModel> items;

  CartData({
    required this.id,
    required this.currency,
    required this.itemsCount,
    required this.itemsQuantity,
    required this.subtotal,
    required this.items,
  });

  factory CartData.fromJson(Map<String, dynamic> json) {
    return CartData(
      id: json['id'] ?? 0,
      currency: json['currency'] ?? 'VND',
      itemsCount: json['itemsCount'] ?? 0,
      itemsQuantity: json['itemsQuantity'] ?? 0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => CartItemModel.fromJson(e))
          .toList() ??
          [],
    );
  }

  /// Tổng tiền chỉ tính các item được tick chọn
  double get selectedSubtotal {
    return items
        .where((item) => item.isSelected)
        .fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }
}

/// ---------------------------------------------------------------------------
/// 3. CART ITEM MODEL
/// ---------------------------------------------------------------------------
class CartItemModel {
  final int id;
  final int productId;
  final int? variantId;

  final String title;
  final String? variantName;
  final String? sku;

  final int? imageId;

  /// ✅ NEW: backend đã có imageUrl snapshot cho biến thể
  final String? imageUrl;

  final double price;

  /// phải mutable để provider optimistic update
  int quantity;

  /// chỉ dùng ở FE để tick chọn
  bool isSelected;

  CartItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.title,
    this.variantName,
    this.sku,
    this.imageId,
    this.imageUrl,
    required this.price,
    required this.quantity,
    this.isSelected = true,
  });

  String get name => title;

  /// ✅ dùng cho các màn hình khác nếu cần
  String get image => imageUrl ?? '';

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] ?? 0,
      productId: json['productId'] ?? 0,
      variantId: json['variantId'],
      title: json['title'] ?? json['productName'] ?? 'Sản phẩm',
      variantName: json['variantName'],
      sku: json['sku'],
      imageId: json['imageId'],

      /// ✅ đọc imageUrl từ BE
      imageUrl: json['imageUrl'] ?? json['image'] ?? json['productImage'],

      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      quantity: json['quantity'] ?? 1,
      isSelected: true,
    );
  }
}
