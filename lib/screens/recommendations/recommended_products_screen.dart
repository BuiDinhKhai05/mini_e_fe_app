import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/recommendation_provider.dart';
import '../../theme/app_theme.dart';

class RecommendedProductsScreen extends StatefulWidget {
  const RecommendedProductsScreen({super.key});

  @override
  State<RecommendedProductsScreen> createState() =>
      _RecommendedProductsScreenState();
}

class _RecommendedProductsScreenState extends State<RecommendedProductsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecommendationProvider>();

      provider.fetchRecommendedProducts(
        page: 1,
        limit: 30,
      );

      provider.fetchFavorites(
        page: 1,
        limit: 50,
        silent: true,
      );
    });
  }

  Future<void> _refresh() async {
    final provider = context.read<RecommendationProvider>();

    await Future.wait([
      provider.fetchRecommendedProducts(
        page: 1,
        limit: 30,
      ),
      provider.fetchFavorites(
        page: 1,
        limit: 50,
        silent: true,
      ),
    ]);
  }

  Future<void> _openProductDetail(ProductModel product) async {
    await context.read<RecommendationProvider>().trackClick(
      product.id,
      source: 'recommended_products_screen',
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

  Widget _emptyBox() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Chưa có sản phẩm gợi ý.\nHãy xem thêm sản phẩm để hệ thống hiểu sở thích của bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _productCard(ProductModel product) {
    final imageUrl = product.imageUrl.trim();

    return InkWell(
      onTap: () => _openProductDetail(product),
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
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkPink,
                        borderRadius: BorderRadius.circular(AppRadius.circle),
                      ),
                      child: const Text(
                        'Gợi ý',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softPink,
      appBar: AppBar(
        title: const Text('Gợi ý cho bạn'),
      ),
      body: Consumer<RecommendationProvider>(
        builder: (context, provider, child) {
          final products = provider.recommendedProducts;

          if (provider.isRecommendationLoading && products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.darkPink,
              ),
            );
          }

          if (products.isEmpty) {
            return RefreshIndicator(
              color: AppColors.darkPink,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: _emptyBox(),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.darkPink,
            onRefresh: _refresh,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: 0.60,
              ),
              itemBuilder: (context, index) {
                return _productCard(products[index]);
              },
            ),
          );
        },
      ),
    );
  }
}