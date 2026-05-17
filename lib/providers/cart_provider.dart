
import 'package:flutter/material.dart';

import '../models/cart_model.dart';
import '../service/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  CartData? _cartData;
  bool _isLoading = false;
  String? _errorMessage;

  CartData? get cartData => _cartData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalItems => _cartData?.itemsQuantity ?? 0;
  double get subtotal => _cartData?.subtotal ?? 0.0;
  List<CartItemModel> get items => _cartData?.items ?? [];

  int get selectedCount {
    if (_cartData == null) return 0;
    return _cartData!.items.where((e) => e.isSelected).length;
  }

  bool get isAllSelected {
    if (_cartData == null || _cartData!.items.isEmpty) return false;
    return _cartData!.items.every((e) => e.isSelected);
  }

  double get selectedSubtotal => _cartData?.selectedSubtotal ?? 0.0;

  List<int> get selectedCartItemIds {
    if (_cartData == null) return [];
    return _cartData!.items
        .where((e) => e.isSelected)
        .map((e) => e.id)
        .toList();
  }

  CartData _emptyCart() {
    return CartData(
      id: 0,
      currency: 'VND',
      itemsCount: 0,
      itemsQuantity: 0,
      subtotal: 0.0,
      items: [],
    );
  }

  CartData _mergeSelection(CartData newData) {
    final oldSelected = <int, bool>{};

    if (_cartData != null) {
      for (final item in _cartData!.items) {
        oldSelected[item.id] = item.isSelected;
      }
    }

    for (final item in newData.items) {
      item.isSelected = oldSelected[item.id] ?? true;
    }

    return newData;
  }

  void clearCartLocal({bool notify = true}) {
    _cartData = _emptyCart();
    _isLoading = false;
    _errorMessage = null;

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> fetchCart({bool notifyOnStart = true}) async {
    _isLoading = true;
    _errorMessage = null;

    if (notifyOnStart) {
      notifyListeners();
    }

    try {
      final data = await _cartService.getCart();

      if (data != null) {
        _cartData = _mergeSelection(data);
      } else {
        _cartData = _emptyCart();
      }
    } catch (e) {
      final message = e.toString();

      if (message.contains('404') ||
          message.toLowerCase().contains('cart not found')) {
        _cartData = _emptyCart();
        _errorMessage = null;
      } else {
        _errorMessage = message;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(
      int productId, {
        required int? variantId,
        int quantity = 1,
      }) async {
    if (variantId == null) {
      throw Exception('Vui lòng chọn biến thể trước khi thêm vào giỏ');
    }

    final newData = await _cartService.addToCart(
      productId: productId,
      variantId: variantId,
      quantity: quantity,
    );

    if (newData != null) {
      _cartData = _mergeSelection(newData);
      notifyListeners();
    }
  }

  Future<void> updateQuantity(int itemId, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      final idx = _cartData?.items.indexWhere((e) => e.id == itemId);

      if (idx != null && idx >= 0) {
        _cartData!.items[idx].quantity = newQuantity;
        notifyListeners();
      }

      final newData = await _cartService.updateItemQuantity(itemId, newQuantity);

      if (newData != null) {
        _cartData = _mergeSelection(newData);
        notifyListeners();
      }
    } catch (e) {
      await fetchCart();
      rethrow;
    }
  }

  Future<void> removeItem(int itemId) async {
    try {
      final newData = await _cartService.removeItem(itemId);

      if (newData != null) {
        _cartData = _mergeSelection(newData);
      } else {
        _cartData ??= _emptyCart();
        _cartData!.items.removeWhere((it) => it.id == itemId);
      }

      notifyListeners();
    } catch (e) {
      await fetchCart();
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      final newData = await _cartService.clearCart();

      if (newData != null) {
        _cartData = _mergeSelection(newData);
      } else {
        _cartData = _emptyCart();
      }

      notifyListeners();
    } catch (e) {
      await fetchCart();
      rethrow;
    }
  }

  void toggleSelection(int itemId) {
    final target = _cartData?.items.firstWhere(
          (e) => e.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );

    if (target != null) {
      target.isSelected = !target.isSelected;
      notifyListeners();
    }
  }

  void toggleSelectAll(bool value) {
    if (_cartData == null) return;

    for (final item in _cartData!.items) {
      item.isSelected = value;
    }

    notifyListeners();
  }
}