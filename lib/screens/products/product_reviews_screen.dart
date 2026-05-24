// lib/screens/products/product_reviews_screen.dart

import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../models/review_model.dart';
import '../../providers/review_provider.dart';
import '../../widgets/review_card.dart';

// =======================================================
// PRODUCT REVIEWS SCREEN
// Màn hình riêng để xem tất cả đánh giá của sản phẩm.
// Được mở từ ProductReviewSection trong ProductDetailScreen.
// =======================================================
class ProductReviewsScreen extends StatefulWidget {
  final int productId;
  final String productTitle;

  const ProductReviewsScreen({
    super.key,
    required this.productId,
    required this.productTitle,
  });

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _bgColor = AppColors.background;
  static const Color _borderPink = AppColors.borderPink;
  static const Color _textDark = AppColors.textDark;
  static const Color _textGrey = AppColors.textGrey;
  static const Color _starColor = AppColors.warning;

  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();

    // Sau khi màn hình render xong, gọi provider để load review.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReviewProvider>();

      if (provider.currentProductId != widget.productId ||
          provider.reviews.isEmpty) {
        provider.loadProductReviews(widget.productId, refresh: true);
      }
    });
  }

  // =======================================================
  // Lọc review phía FE.
  //
  // BE hiện tại chưa hỗ trợ query:
  // ?rating=5, ?hasImage=true, ?hasComment=true
  //
  // Nên phần lọc này chỉ lọc trên danh sách đã tải.
  // =======================================================
  List<ProductReviewItem> _getFilteredReviews(
      List<ProductReviewItem> reviews,
      ) {
    switch (_selectedFilter) {
      case '5':
        return reviews.where((item) => item.rating == 5).toList();
      case '4':
        return reviews.where((item) => item.rating == 4).toList();
      case 'COMMENT':
        return reviews.where((item) => item.hasComment).toList();
      case 'IMAGE':
        return reviews.where((item) => item.hasImages).toList();
      default:
        return reviews;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Tất cả đánh giá',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, provider, _) {
          final filteredReviews = _getFilteredReviews(provider.reviews);

          if (provider.isInitialLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryPink),
            );
          }

          if (provider.errorMessage != null && provider.reviews.isEmpty) {
            return _buildError(provider);
          }

          return RefreshIndicator(
            color: _primaryPink,
            onRefresh: () {
              return provider.refreshProductReviews(widget.productId);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                _buildSummary(provider.summary),
                const SizedBox(height: 12),
                _buildFilterBar(),
                const SizedBox(height: 12),
                if (provider.reviews.isEmpty)
                  _buildEmpty()
                else if (filteredReviews.isEmpty)
                  _buildEmptyFilter()
                else
                  _buildReviewList(filteredReviews),
                if (provider.hasMore) ...[
                  const SizedBox(height: 10),
                  _buildLoadMoreButton(provider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // =======================================================
  // Tổng quan rating: điểm trung bình + tổng số đánh giá.
  // =======================================================
  Widget _buildSummary(ProductReviewSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: summary.avg.toStringAsFixed(1),
                      style: const TextStyle(
                        color: _primaryPink,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const TextSpan(
                      text: '/5',
                      style: TextStyle(
                        color: _textGrey,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              _buildStars(summary.avg),
            ],
          ),
          const Spacer(),
          Text(
            '${summary.count} đánh giá',
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // Thanh lọc đánh giá.
  // Hiện tại lọc local trên danh sách đã tải.
  // =======================================================
  Widget _buildFilterBar() {
    final filters = [
      {'key': 'ALL', 'label': 'Tất cả'},
      {'key': '5', 'label': '5 sao'},
      {'key': '4', 'label': '4 sao'},
      {'key': 'COMMENT', 'label': 'Có bình luận'},
      {'key': 'IMAGE', 'label': 'Có hình ảnh'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final key = filter['key']!;
          final selected = _selectedFilter == key;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text(filter['label']!),
              selectedColor: _primaryPink,
              backgroundColor: _softPink,
              labelStyle: TextStyle(
                color: selected ? Colors.white : _textDark,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              side: BorderSide(
                color: selected ? _primaryPink : _borderPink,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = key;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // =======================================================
  // Danh sách review.
  // =======================================================
  Widget _buildReviewList(List<ProductReviewItem> reviews) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: reviews.map((review) {
          return ReviewCard(review: review);
        }).toList(),
      ),
    );
  }

  // =======================================================
  // Nút xem thêm review.
  // =======================================================
  Widget _buildLoadMoreButton(ReviewProvider provider) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: provider.isLoadingMore
            ? null
            : () {
          provider.loadProductReviews(widget.productId);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryPink,
          side: const BorderSide(color: _primaryPink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: provider.isLoadingMore
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _primaryPink,
          ),
        )
            : const Text(
          'Xem thêm đánh giá',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildError(ReviewProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: _primaryPink,
              size: 58,
            ),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? 'Không thể tải đánh giá',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                provider.refreshProductReviews(widget.productId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: _primaryPink,
            size: 58,
          ),
          SizedBox(height: 10),
          Text(
            'Sản phẩm chưa có đánh giá',
            style: TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: const Text(
        'Không có đánh giá phù hợp với bộ lọc này.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _textGrey,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round()
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          size: 18,
          color: _starColor,
        );
      }),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _borderPink),
      boxShadow: [
        BoxShadow(
          color: _primaryPink.withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}