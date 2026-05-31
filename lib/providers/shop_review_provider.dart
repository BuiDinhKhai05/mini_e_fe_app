// lib/providers/shop_review_provider.dart

import 'package:flutter/material.dart';

import '../models/review_model.dart';
import '../service/review_service.dart';

// =======================================================
// SHOP REVIEW PROVIDER
// Quản lý state riêng cho review shop:
// - Public xem review shop theo shopId
// - Seller xem review shop của mình
// - Có lọc theo số sao
// - Có phân trang
// =======================================================
class ShopReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  int? _currentShopId;
  bool _isMyShopMode = false;
  int? _ratingFilter;

  ProductReviewSummary _summary = ProductReviewSummary.empty();
  final List<ProductReviewItem> _reviews = [];

  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _page = 0;
  final int _limit = 20;
  int _total = 0;

  int? get currentShopId => _currentShopId;
  bool get isMyShopMode => _isMyShopMode;
  int? get ratingFilter => _ratingFilter;

  ProductReviewSummary get summary => _summary;
  List<ProductReviewItem> get reviews => List.unmodifiable(_reviews);

  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  int get total => _total;
  bool get hasMore => _reviews.length < _total;

  Future<void> loadShopReviews(
      int shopId, {
        bool refresh = false,
      }) async {
    await _load(
      shopId: shopId,
      isMyShop: false,
      refresh: refresh,
      resetRatingIfNewContext: true,
    );
  }

  Future<void> loadMyShopReviews({
    bool refresh = false,
  }) async {
    await _load(
      shopId: null,
      isMyShop: true,
      refresh: refresh,
      resetRatingIfNewContext: true,
    );
  }

  Future<void> refreshShopReviews(int shopId) async {
    await loadShopReviews(shopId, refresh: true);
  }

  Future<void> refreshMyShopReviews() async {
    await loadMyShopReviews(refresh: true);
  }

  Future<void> setRatingFilterForShop(int shopId, int? rating) async {
    _ratingFilter = _normalizeRating(rating);

    await _load(
      shopId: shopId,
      isMyShop: false,
      refresh: true,
      resetRatingIfNewContext: false,
    );
  }

  Future<void> setRatingFilterForMyShop(int? rating) async {
    _ratingFilter = _normalizeRating(rating);

    await _load(
      shopId: null,
      isMyShop: true,
      refresh: true,
      resetRatingIfNewContext: false,
    );
  }

  Future<void> _load({
    required int? shopId,
    required bool isMyShop,
    required bool refresh,
    required bool resetRatingIfNewContext,
  }) async {
    if (_isInitialLoading || _isLoadingMore) return;

    final isNewContext =
        _isMyShopMode != isMyShop || (!isMyShop && _currentShopId != shopId);

    if (isNewContext && resetRatingIfNewContext) {
      _ratingFilter = null;
    }

    if (refresh || isNewContext) {
      _currentShopId = shopId;
      _isMyShopMode = isMyShop;
      _summary = ProductReviewSummary.empty();
      _reviews.clear();
      _page = 0;
      _total = 0;
      _errorMessage = null;
    }

    if (!refresh && !isNewContext && _reviews.isNotEmpty && !hasMore) {
      return;
    }

    final nextPage = _page + 1;
    final isFirstLoad = _reviews.isEmpty;

    if (isFirstLoad) {
      _isInitialLoading = true;
    } else {
      _isLoadingMore = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final response = isMyShop
          ? await _service.fetchMyShopReviews(
        page: nextPage,
        limit: _limit,
        rating: _ratingFilter,
      )
          : await _service.fetchShopReviews(
        shopId: shopId!,
        page: nextPage,
        limit: _limit,
        rating: _ratingFilter,
      );

      _summary = response.summary;
      _page = response.page;

      // Khi có filter rating, BE total là số review theo filter.
      // Summary vẫn là tổng toàn shop.
      _total = _ratingFilter != null
          ? response.total
          : (response.total > 0 ? response.total : response.summary.count);

      final existingIds = _reviews.map((item) => item.id).toSet();

      final newItems = response.items
          .where((item) => item.id.isNotEmpty && !existingIds.contains(item.id))
          .toList();

      _reviews.addAll(newItems);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isInitialLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  int? _normalizeRating(int? rating) {
    if (rating == null) return null;
    if (rating < 1 || rating > 5) return null;
    return rating;
  }

  void clear() {
    _currentShopId = null;
    _isMyShopMode = false;
    _ratingFilter = null;
    _summary = ProductReviewSummary.empty();
    _reviews.clear();
    _isInitialLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _page = 0;
    _total = 0;
    notifyListeners();
  }
}