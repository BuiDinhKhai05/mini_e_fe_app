import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/recommendation_provider.dart';
import '../../theme/app_theme.dart';

class FavoriteProductScreen extends StatefulWidget {
  const FavoriteProductScreen({super.key});

  @override
  State<FavoriteProductScreen> createState() => _FavoriteProductScreenState();
}

class _FavoriteProductScreenState extends State<FavoriteProductScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecommendationProvider>();

      provider.fetchFavorites(
        page: 1,
        limit: 50,
      );

      provider.fetchRecommendedProducts(
        page: 1,
        limit: 12,
      );
    });
  }

  Future<void> _refresh() async {
    final provider = context.read<RecommendationProvider>();

    await Future.wait([
      provider.fetchFavorites(
        page: 1,
        limit: 50,
      ),
      provider.fetchRecommendedProducts(
        page: 1,
        limit: 12,
      ),
    ]);
  }

  Future<void> _openProductDetail(
      ProductModel product, {
        String source = 'favorite_screen',
      }) async {
    await context.read<RecommendationProvider>().trackClick(
      product.id,
      source: source,
    );

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      '/product-detail',
      arguments: product,
    );
  }

  Future<void> _toggleFavorite(ProductModel product) async {
    try {
      await context.read<RecommendationProvider>().toggleFavorite(product.id);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật sản phẩm yêu thích'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatPrice(dynamic price) {
    double value = 0.0;

    if (price is String) {
      value = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      value = price.toDouble();
    }

    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }

  Widget _sectionTitle(
      String title, {
        VoidCallback? onViewAll,
      }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (onViewAll != null)
            InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(AppRadius.circle),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: AppColors.darkPink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.darkPink,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyFavoriteBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: AppColors.borderPink),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkPink.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.favorite_border_rounded,
            color: AppColors.darkPink,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'Bạn chưa có sản phẩm yêu thích',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Hãy bấm vào biểu tượng trái tim để lưu sản phẩm bạn thích.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGrey,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _productImageFallback() {
    return Container(
      color: AppColors.softPink,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 34,
          color: AppColors.textLight,
        ),
      ),
    );
  }

  Widget _productCard(
      ProductModel product, {
        required String source,
      }) {
    final imageUrl = product.imageUrl.trim();

    return InkWell(
      onTap: () => _openProductDetail(product, source: source),
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.extraLarge),
          border: Border.all(color: AppColors.lightPink),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkPink.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.extraLarge),
                    ),
                    child: imageUrl.isEmpty
                        ? _productImageFallback()
                        : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => Container(
                        color: AppColors.softPink,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.darkPink,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _productImageFallback(),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Consumer<RecommendationProvider>(
                      builder: (_, recommendationProvider, __) {
                        final isFavorite =
                        recommendationProvider.isFavorite(product.id);

                        return InkWell(
                          onTap: () => _toggleFavorite(product),
                          borderRadius: BorderRadius.circular(AppRadius.circle),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: AppColors.darkPink,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          height: 1.12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatPrice(product.price)} VNĐ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.6,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkPink,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (product.stock ?? 0) > 0
                          ? 'Còn ${product.stock} sản phẩm'
                          : 'Hết hàng',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.05,
                        color: (product.stock ?? 0) > 0
                            ? AppColors.textGrey
                            : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.softPink,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: const Text(
                        'Chi tiết',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoriteGrid(List<ProductModel> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.60,
      ),
      itemBuilder: (context, index) {
        return _productCard(
          products[index],
          source: 'favorite_products',
        );
      },
    );
  }

  Widget _recommendedHorizontalList(List<ProductModel> products) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 290,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 170,
            child: _productCard(
              products[index],
              source: 'favorite_screen_recommendation',
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softPink,
      appBar: AppBar(
        title: const Text('Sản phẩm yêu thích'),
      ),
      body: Consumer<RecommendationProvider>(
        builder: (context, provider, child) {
          final favoriteProducts = provider.favoriteProducts;
          final recommendedProducts = provider.recommendedProducts;

          final isLoadingFavorites =
              provider.isFavoriteLoading && favoriteProducts.isEmpty;

          if (isLoadingFavorites) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.darkPink,
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.darkPink,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _sectionTitle('Sản phẩm yêu thích 💖'),
                ),

                SliverToBoxAdapter(
                  child: favoriteProducts.isEmpty
                      ? _emptyFavoriteBox()
                      : _favoriteGrid(favoriteProducts),
                ),

                SliverToBoxAdapter(
                  child: _sectionTitle(
                    'Có thể bạn cũng thích ✨',
                    onViewAll: () {
                      Navigator.pushNamed(context, '/recommendations');
                    },
                  ),
                ),

                SliverToBoxAdapter(
                  child: provider.isRecommendationLoading &&
                      recommendedProducts.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.darkPink,
                      ),
                    ),
                  )
                      : _recommendedHorizontalList(recommendedProducts),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}