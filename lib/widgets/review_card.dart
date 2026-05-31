// lib/widgets/review_card.dart

import 'package:flutter/material.dart';

import '../models/review_model.dart';

// =======================================================
// REVIEW CARD
// Widget nhỏ dùng lại để hiển thị 1 đánh giá.
// Có thể dùng ở:
// - ProductDetailScreen
// - ProductReviewsScreen
// - Admin review screen sau này
// =======================================================
class ReviewCard extends StatelessWidget {
  final ProductReviewItem review;

  // true khi card dùng trong màn review shop.
  // Khi đó hiển thị thêm tên sản phẩm được đánh giá.
  final bool showProductInfo;

  const ReviewCard({
    super.key,
    required this.review,
    this.showProductInfo = false,
  });

  static const Color _primaryPink = Color(0xFFE84B82);
  static const Color _softPink = Color(0xFFFFEEF4);
  static const Color _borderPink = Color(0xFFFFD6E4);
  static const Color _textDark = Color(0xFF4A2C36);
  static const Color _textGrey = Color(0xFF8A6F78);
  static const Color _starColor = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _borderPink),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserName(),
                const SizedBox(height: 4),
                _buildStars(review.rating),
                const SizedBox(height: 6),
                _buildDate(),
                if (showProductInfo && review.hasProductTitle) ...[
                  const SizedBox(height: 7),
                  _buildProductInfo(),
                ],
                if (review.hasComment) ...[
                  const SizedBox(height: 8),
                  _buildComment(),
                ],
                if (review.hasImages) ...[
                  const SizedBox(height: 10),
                  _buildImages(),
                ],

              ],
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // Avatar người đánh giá.
  // Nếu không có avatar thì dùng chữ cái đầu của tên.
  // =======================================================
  Widget _buildAvatar() {
    final avatarUrl = review.userAvatarUrl;

    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: _softPink,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }

    final firstLetter = review.userName.trim().isNotEmpty
        ? review.userName.trim()[0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: 20,
      backgroundColor: _softPink,
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: _primaryPink,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // =======================================================
  // Tên người đánh giá.
  // =======================================================
  Widget _buildUserName() {
    return Text(
      review.userName,
      style: const TextStyle(
        color: _textDark,
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
    );
  }

  // =======================================================
  // Hiển thị số sao.
  // =======================================================
  Widget _buildStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: _starColor,
        );
      }),
    );
  }

  // =======================================================
  // Ngày đánh giá.
  // =======================================================
  Widget _buildDate() {
    final localDate = review.createdAt.toLocal();

    final text = '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';

    return Text(
      text,
      style: const TextStyle(
        color: _textGrey,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _softPink,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderPink),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 14,
            color: _primaryPink,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              review.productTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _primaryPink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // =======================================================
  // Nội dung bình luận.
  // =======================================================
  Widget _buildComment() {
    return Text(
      review.comment!,
      style: const TextStyle(
        color: _textDark,
        height: 1.45,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // =======================================================
  // Danh sách hình ảnh trong review.
  // =======================================================
  Widget _buildImages() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: review.images.map((url) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 72,
            height: 72,
            color: _softPink,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.image_not_supported_outlined,
                  color: _textGrey,
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}