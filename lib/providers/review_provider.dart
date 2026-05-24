// lib/providers/review_provider.dart

import 'package:flutter/material.dart';

import '../models/review_model.dart';
import '../service/review_service.dart';

// =======================================================
// REVIEW PROVIDER
// Quản lý state cho phần đánh giá sản phẩm:
// - loading
// - error
// - danh sách review
// - phân trang
// - summary rating
// =======================================================
class ReviewProvider extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  int? _currentProductId;

  ProductReviewSummary _summary = ProductReviewSummary.empty();
  final List<ProductReviewItem> _reviews = [];

  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _page = 0;
  final int _limit = 20;
  int _total = 0;

  // Product hiện tại đang load review.
  int? get currentProductId => _currentProductId;

  // Tổng quan rating.
  ProductReviewSummary get summary => _summary;

  // Danh sách review đã tải.
  List<ProductReviewItem> get reviews => List.unmodifiable(_reviews);

  // Loading lần đầu.
  bool get isInitialLoading => _isInitialLoading;

  // Loading khi bấm xem thêm.
  bool get isLoadingMore => _isLoadingMore;

  // Thông báo lỗi.
  String? get errorMessage => _errorMessage;

  // Kiểm tra còn review để load thêm không.
  bool get hasMore => _reviews.length < _total;

  // Tổng số review theo BE.
  int get total => _total;

  // =======================================================
  // Load review theo productId.
  //
  // refresh = true:
  // - Xóa dữ liệu cũ
  // - Load lại từ page 1
  //
  // refresh = false:
  // - Load page tiếp theo
  // =======================================================
  Future<void> loadProductReviews(
      int productId, {
        bool refresh = false,
      }) async {
    final bool isNewProduct = _currentProductId != productId;

    if (_isInitialLoading || _isLoadingMore) return;

    if (refresh || isNewProduct) {
      _currentProductId = productId;
      _summary = ProductReviewSummary.empty();
      _reviews.clear();
      _page = 0;
      _total = 0;
      _errorMessage = null;
    }

    if (!refresh && !isNewProduct && _reviews.isNotEmpty && !hasMore) {
      return;
    }

    final int nextPage = _page + 1;
    final bool isFirstLoad = _reviews.isEmpty;

    if (isFirstLoad) {
      _isInitialLoading = true;
    } else {
      _isLoadingMore = true;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.fetchProductReviews(
        productId: productId,
        page: nextPage,
        limit: _limit,
      );

      _summary = response.summary;
      _page = response.page;
      _total = response.total > 0 ? response.total : response.summary.count;

      // Tránh bị trùng review nếu user bấm tải lại nhanh
      // hoặc BE trả lại item đã có ở trang trước.
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

  // =======================================================
  // Refresh review khi kéo xuống hoặc sau khi user tạo review.
  // =======================================================
  Future<void> refreshProductReviews(int productId) async {
    await loadProductReviews(productId, refresh: true);
  }

  // =======================================================
  // Xóa state review.
  // Dùng khi cần reset thủ công.
  // =======================================================
  void clear() {
    _currentProductId = null;
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