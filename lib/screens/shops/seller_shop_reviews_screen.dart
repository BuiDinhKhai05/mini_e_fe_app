// lib/screens/shops/seller_shop_reviews_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/shop_review_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/review_card.dart';

class SellerShopReviewsScreen extends StatefulWidget {
  const SellerShopReviewsScreen({super.key});

  @override
  State<SellerShopReviewsScreen> createState() =>
      _SellerShopReviewsScreenState();
}

class _SellerShopReviewsScreenState extends State<SellerShopReviewsScreen> {
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _lighterPink = AppColors.background;
  static const Color _borderPink = AppColors.borderPink;
  static const Color _textDark = AppColors.textDark;
  static const Color _textGrey = AppColors.textGrey;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopReviewProvider>().loadMyShopReviews(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lighterPink,
      appBar: AppBar(
        title: const Text(
          'Đánh giá shop',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        elevation: 0,
      ),
      body: Consumer<ShopReviewProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            color: _primaryPink,
            onRefresh: provider.refreshMyShopReviews,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(provider),
                const SizedBox(height: 14),
                _buildFilterChips(provider),
                const SizedBox(height: 14),
                _buildBody(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(ShopReviewProvider provider) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildCircleIcon(Icons.star_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tổng quan đánh giá',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                provider.summary.avg.toStringAsFixed(1),
                style: const TextStyle(
                  color: _primaryPink,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                '/5',
                style: TextStyle(
                  color: _textGrey,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              _buildStars(provider.summary.avg),
              const Spacer(),
              Text(
                '${provider.summary.count} đánh giá',
                style: const TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ShopReviewProvider provider) {
    final filters = <int?>[null, 5, 4, 3, 2, 1];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((rating) {
          final selected = provider.ratingFilter == rating;
          final label = rating == null ? 'Tất cả' : '$rating sao';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text(label),
              selectedColor: _primaryPink,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? _primaryPink : _borderPink,
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : _primaryPink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              onSelected: (_) {
                provider.setRatingFilterForMyShop(rating);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(ShopReviewProvider provider) {
    if (provider.isInitialLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
          child: CircularProgressIndicator(color: _primaryPink),
        ),
      );
    }

    if (provider.errorMessage != null && provider.reviews.isEmpty) {
      return _buildError(provider);
    }

    if (provider.reviews.isEmpty) {
      return _buildEmpty();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          ...provider.reviews.map((review) {
            return ReviewCard(
              review: review,
              showProductInfo: true,
            );
          }),

          if (provider.hasMore)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: provider.isLoadingMore
                    ? null
                    : () {
                  provider.loadMyShopReviews();
                },
                icon: provider.isLoadingMore
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primaryPink,
                  ),
                )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(
                  provider.isLoadingMore ? 'Đang tải...' : 'Tải thêm',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryPink,
                  side: const BorderSide(color: _primaryPink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildError(ShopReviewProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 42,
          ),
          const SizedBox(height: 10),
          const Text(
            'Không thể tải đánh giá shop',
            style: TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            provider.errorMessage ?? 'Vui lòng thử lại sau.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textGrey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: provider.refreshMyShopReviews,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryPink,
              side: const BorderSide(color: _primaryPink),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(radius: 24),
      child: const Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: _primaryPink,
            size: 46,
          ),
          SizedBox(height: 12),
          Text(
            'Shop chưa có đánh giá',
            style: TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Khi khách hàng đánh giá sản phẩm của shop, đánh giá sẽ xuất hiện ở đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textGrey,
              height: 1.4,
            ),
          ),
        ],
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
          color: AppColors.warning,
          size: 18,
        );
      }),
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: _softPink,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: _primaryPink,
        size: 22,
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
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