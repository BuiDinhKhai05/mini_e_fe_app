// lib/screens/products/widgets/product_review_section.dart

import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../../models/review_model.dart';
import '../../../providers/review_provider.dart';
import '../../../widgets/review_card.dart';
import '../product_reviews_screen.dart';

// =======================================================
// PRODUCT REVIEW SECTION
// Widget này nằm trong ProductDetailScreen,
// dùng để hiển thị nhanh phần đánh giá sản phẩm
// ngay bên dưới phần mô tả sản phẩm.
// =======================================================
class ProductReviewSection extends StatefulWidget {
  final int productId;
  final String productTitle;

  const ProductReviewSection({
    super.key,
    required this.productId,
    required this.productTitle,
  });

  @override
  State<ProductReviewSection> createState() => _ProductReviewSectionState();
}

class _ProductReviewSectionState extends State<ProductReviewSection> {
  static const Color _primaryPink = AppColors.primaryPink;
  static const Color _softPink = AppColors.lightPink;
  static const Color _borderPink = AppColors.borderPink;
  static const Color _textDark = AppColors.textDark;
  static const Color _textGrey = AppColors.textGrey;
  static const Color _starColor = AppColors.warning;

  @override
  void initState() {
    super.initState();

    // Sau khi widget render xong thì gọi API lấy đánh giá sản phẩm.
    // Tránh gọi provider trực tiếp trong initState trước khi context sẵn sàng.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReviewProvider>();

      if (provider.currentProductId != widget.productId ||
          provider.reviews.isEmpty) {
        provider.loadProductReviews(widget.productId, refresh: true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ProductReviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Nếu productId thay đổi, ví dụ màn hình được rebuild với sản phẩm khác,
    // thì load lại đánh giá cho đúng sản phẩm mới.
    if (oldWidget.productId != widget.productId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ReviewProvider>().loadProductReviews(
          widget.productId,
          refresh: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider.summary),
              const SizedBox(height: 14),
              _buildBody(provider),
            ],
          ),
        );
      },
    );
  }

  // =======================================================
  // Header: tiêu đề "Đánh giá sản phẩm" + nút "Tất cả".
  // Nút "Tất cả" mở sang ProductReviewsScreen để xem toàn bộ review.
  // =======================================================
  Widget _buildHeader(ProductReviewSummary summary) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _softPink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.star_rounded,
            color: _primaryPink,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Đánh giá sản phẩm',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _textDark,
            ),
          ),
        ),

        // Nút nhỏ ở góc trên của card để mở màn hình xem tất cả đánh giá.
        _buildHeaderViewAllButton(),
      ],
    );
  }

  // =======================================================
  // Nút "Tất cả" trên header card đánh giá.
  // Để tránh làm vỡ layout trên màn hình nhỏ, nút được bo tròn và dùng padding ngắn.
  // =======================================================
  Widget _buildHeaderViewAllButton() {
    return InkWell(
      onTap: _openProductReviewsScreen,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _borderPink),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tất cả',
              style: TextStyle(
                color: _primaryPink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              color: _primaryPink,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================
  // Body:
  // - Loading khi đang gọi API
  // - Error khi API lỗi
  // - Empty khi chưa có đánh giá
  // - List review khi có dữ liệu
  // =======================================================
  Widget _buildBody(ReviewProvider provider) {
    if (provider.isInitialLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
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

    // Ở trang chi tiết sản phẩm chỉ hiện tối đa 3 đánh giá đầu tiên.
    // Muốn xem đầy đủ thì bấm "Xem tất cả đánh giá".
    final visibleReviews = provider.reviews.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(provider.summary),
        const SizedBox(height: 14),

        // Hiển thị các review đầu tiên.
        ...visibleReviews.map((review) {
          return ReviewCard(review: review);
        }).toList(),

        _buildViewAllButton(provider.summary.count),
      ],
    );
  }

  // =======================================================
  // Tóm tắt rating:
  // điểm trung bình + sao + tổng số đánh giá.
  // =======================================================
  Widget _buildSummaryRow(ProductReviewSummary summary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softPink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            summary.avg.toStringAsFixed(1),
            style: const TextStyle(
              color: _primaryPink,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '/5',
            style: TextStyle(
              color: _textGrey,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          _buildStars(summary.avg),
          const Spacer(),
          Text(
            '${summary.count} đánh giá',
            style: const TextStyle(
              color: _textDark,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // UI khi API review bị lỗi.
  // =======================================================
  Widget _buildError(ReviewProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider.errorMessage ?? 'Không thể tải đánh giá',
          style: const TextStyle(
            color: _textGrey,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            provider.refreshProductReviews(widget.productId);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryPink,
            side: const BorderSide(color: _primaryPink),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Thử lại',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  // =======================================================
  // UI khi sản phẩm chưa có đánh giá.
  // =======================================================
  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: _primaryPink,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sản phẩm chưa có đánh giá.',
              style: TextStyle(
                color: _textGrey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // Điều hướng sang màn hình xem tất cả đánh giá của sản phẩm.
  // Dùng chung cho nút "Tất cả" ở header và nút lớn phía dưới danh sách review.
  // =======================================================
  void _openProductReviewsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductReviewsScreen(
          productId: widget.productId,
          productTitle: widget.productTitle,
        ),
      ),
    );
  }

  // =======================================================
  // Nút mở màn hình riêng xem tất cả đánh giá.
  // =======================================================
  Widget _buildViewAllButton(int count) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: _openProductReviewsScreen,
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryPink,
          side: const BorderSide(color: _primaryPink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          count > 3 ? 'Xem tất cả $count đánh giá' : 'Xem tất cả đánh giá',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  // =======================================================
  // Hiển thị sao theo điểm trung bình.
  // =======================================================
  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round()
              ? Icons.star_rounded
              : Icons.star_border_rounded,
          size: 17,
          color: _starColor,
        );
      }),
    );
  }

  // =======================================================
  // Style card giống format hồng của app.
  // =======================================================
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _borderPink),
      boxShadow: [
        BoxShadow(
          color: _primaryPink.withOpacity(0.08),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}