import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class AppHomeHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchSubmitted;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClearSearch;
  final VoidCallback? onCartTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogoTap;
  final String hintText;

  const AppHomeHeader({
    super.key,
    required this.searchController,
    this.onSearchSubmitted,
    this.onSearchChanged,
    this.onFilterTap,
    this.onClearSearch,
    this.onCartTap,
    this.onProfileTap,
    this.onLogoTap,
    this.hintText = 'Bạn tìm gì hôm nay?',
  });

  static const String _logoAsset =
      'assets/images/mochi/bunny_bear_original.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.borderPink),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onLogoTap ??
                              () {
                            final currentRoute = ModalRoute.of(context)?.settings.name;

                            if (currentRoute == '/home') return;

                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/home',
                                  (route) => false,
                            );
                          },
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.large),
                              border: Border.all(color: AppColors.borderPink),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.darkPink.withOpacity(0.10),
                                  blurRadius: 14,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Image.asset(
                                _logoAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.favorite_rounded,
                                  color: AppColors.darkPink,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mochi Shop',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.darkPink,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 1),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Consumer<CartProvider>(
                    builder: (_, provider, __) {
                      final count = provider.cartData?.itemsCount ?? 0;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _RoundHeaderButton(
                            icon: Icons.shopping_cart_outlined,
                            onTap: onCartTap ??
                                    () => Navigator.pushNamed(context, '/cart'),
                          ),
                          if (count > 0)
                            Positioned(
                              right: -2,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.darkPink,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _RoundHeaderButton(
                    icon: Icons.person_outline_rounded,
                    onTap: onProfileTap ??
                            () => Navigator.pushNamed(context, '/profile'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(color: AppColors.borderPink),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkPink.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: onSearchChanged,
                  onSubmitted: onSearchSubmitted,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: AppTextStyles.bodyGrey.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.darkPink,
                      size: 21,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 42,
                      minHeight: 42,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 42,
                      minHeight: 42,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Chọn danh mục',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.darkPink,
                            size: 20,
                          ),
                          onPressed: onFilterTap,
                        ),
                        if (searchController.text.isNotEmpty)
                          IconButton(
                            tooltip: 'Xoá tìm kiếm',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppColors.textGrey,
                              size: 20,
                            ),
                            onPressed: onClearSearch,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundHeaderButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.circle),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderPink),
        ),
        child: Icon(
          icon,
          color: AppColors.textDark,
          size: 20,
        ),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Future<void> Function()? onHomeTap;
  final Future<void> Function()? onCategoryTap;
  final Future<void> Function()? onCartTap;
  final Future<void> Function()? onProfileTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    this.onHomeTap,
    this.onCategoryTap,
    this.onCartTap,
    this.onProfileTap,
  });

  void _go(BuildContext context, String routeName) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
          (route) => false,
    );
  }

  Future<void> _handleTap(BuildContext context, int index) async {
    if (index == currentIndex) return;

    if (index == 0) {
      if (onHomeTap != null) {
        await onHomeTap!();
      } else {
        _go(context, '/home');
      }
      return;
    }

    if (index == 1) {
      if (onCategoryTap != null) {
        await onCategoryTap!();
      } else {
        _go(context, '/categories');
      }
      return;
    }

    if (index == 2) {
      if (onCartTap != null) {
        await onCartTap!();
      } else {
        await Navigator.pushNamed(context, '/cart');
      }
      return;
    }

    if (index == 3) {
      if (onProfileTap != null) {
        await onProfileTap!();
      } else {
        await Navigator.pushNamed(context, '/personal-info');
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderPink),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkPink.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.darkPink,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          onTap: (index) => _handleTap(context, index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Danh mục',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              label: 'Giỏ hàng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Tôi',
            ),
          ],
        ),
      ),
    );
  }
}
