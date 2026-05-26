import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../models/recommendation_event_type.dart';
import '../service/recommendation_service.dart';

class RecommendationProvider extends ChangeNotifier {
  final RecommendationService _recommendationService;

  RecommendationProvider(this._recommendationService);

  final List<ProductModel> _recommendedProducts = [];
  final List<ProductModel> _favoriteProducts = [];
  final Set<int> _favoriteProductIds = {};

  bool _isRecommendationLoading = false;
  bool _isFavoriteLoading = false;
  String? _error;

  List<ProductModel> get recommendedProducts => List.unmodifiable(_recommendedProducts);
  List<ProductModel> get favoriteProducts => List.unmodifiable(_favoriteProducts);
  Set<int> get favoriteProductIds => Set.unmodifiable(_favoriteProductIds);

  bool get isRecommendationLoading => _isRecommendationLoading;
  bool get isFavoriteLoading => _isFavoriteLoading;

  /// Giữ getter cũ để các màn hình khác nếu đã dùng `isLoading` vẫn không lỗi.
  bool get isLoading => _isRecommendationLoading || _isFavoriteLoading;

  String? get error => _error;

  bool isFavorite(int productId) => _favoriteProductIds.contains(productId);

  Future<void> fetchRecommendedProducts({
    int page = 1,
    int limit = 20,
    bool silent = false,
  }) async {
    try {
      if (!silent) {
        _isRecommendationLoading = true;
        _error = null;
        notifyListeners();
      }

      final products = await _recommendationService.getRecommendedProducts(
        page: page,
        limit: limit,
      );

      if (page == 1) {
        _recommendedProducts
          ..clear()
          ..addAll(products);
      } else {
        _recommendedProducts.addAll(products);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!silent) {
        _isRecommendationLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> fetchFavorites({
    int page = 1,
    int limit = 50,
    bool silent = false,
  }) async {
    try {
      if (!silent) {
        _isFavoriteLoading = true;
        _error = null;
        notifyListeners();
      }

      final products = await _recommendationService.getFavorites(
        page: page,
        limit: limit,
      );

      if (page == 1) {
        _favoriteProducts
          ..clear()
          ..addAll(products);

        _favoriteProductIds
          ..clear()
          ..addAll(products.map((product) => product.id));
      } else {
        _favoriteProducts.addAll(products);
        _favoriteProductIds.addAll(products.map((product) => product.id));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (!silent) {
        _isFavoriteLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> addFavorite(int productId) async {
    final existedBefore = _favoriteProductIds.contains(productId);

    // Optimistic update để icon tim đổi ngay.
    _favoriteProductIds.add(productId);
    notifyListeners();

    try {
      await _recommendationService.addFavorite(productId);
    } catch (e) {
      if (!existedBefore) {
        _favoriteProductIds.remove(productId);
      }
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeFavorite(int productId) async {
    final existedBefore = _favoriteProductIds.contains(productId);

    // Optimistic update để icon tim đổi ngay.
    _favoriteProductIds.remove(productId);
    _favoriteProducts.removeWhere((product) => product.id == productId);
    notifyListeners();

    try {
      await _recommendationService.removeFavorite(productId);
    } catch (e) {
      if (existedBefore) {
        _favoriteProductIds.add(productId);
      }
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleFavorite(int productId) async {
    if (isFavorite(productId)) {
      await removeFavorite(productId);
    } else {
      await addFavorite(productId);
    }
  }

  Future<void> trackEvent({
    required int productId,
    required String eventType,
    String source = 'unknown',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _recommendationService.trackEvent(
        productId: productId,
        eventType: eventType,
        metadata: {
          'source': source,
          ...?metadata,
        },
      );
    } catch (_) {
      // Không để lỗi recommendation làm hỏng luồng mua hàng/xem sản phẩm.
    }
  }

  Future<void> trackClick(int productId, {String source = 'unknown'}) {
    return trackEvent(
      productId: productId,
      eventType: RecommendationEventType.click,
      source: source,
    );
  }

  Future<void> trackViewDetail(int productId, {String source = 'unknown'}) {
    return trackEvent(
      productId: productId,
      eventType: RecommendationEventType.viewDetail,
      source: source,
    );
  }

  Future<void> trackAddToCart(
      int productId, {
        String source = 'unknown',
        int? variantId,
        int? quantity,
      }) {
    return trackEvent(
      productId: productId,
      eventType: RecommendationEventType.addToCart,
      source: source,
      metadata: {
        if (variantId != null) 'variantId': variantId,
        if (quantity != null) 'quantity': quantity,
      },
    );
  }

  Future<void> trackPurchase(
      int productId, {
        String source = 'checkout',
        int? orderId,
        int? quantity,
      }) {
    return trackEvent(
      productId: productId,
      eventType: RecommendationEventType.purchase,
      source: source,
      metadata: {
        if (orderId != null) 'orderId': orderId,
        if (quantity != null) 'quantity': quantity,
      },
    );
  }
}
