import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HorizontalSection<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final double height;
  final double itemWidth;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final VoidCallback? onViewAll;
  final String viewAllText;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry listPadding;
  final double spacing;
  final Widget? emptyWidget;
  final bool showWhenEmpty;

  const HorizontalSection({
    super.key,
    required this.title,
    required this.items,
    required this.height,
    required this.itemWidth,
    required this.itemBuilder,
    this.onViewAll,
    this.viewAllText = 'Xem tất cả',
    this.headerPadding = const EdgeInsets.fromLTRB(16, 18, 16, 12),
    this.listPadding = const EdgeInsets.fromLTRB(16, 4, 16, 18),
    this.spacing = 12,
    this.emptyWidget,
    this.showWhenEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !showWhenEmpty) {
      return const SizedBox.shrink();
    }

    if (items.isEmpty && emptyWidget != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(),
          emptyWidget!,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: listPadding,
            itemCount: items.length,
            separatorBuilder: (_, __) => SizedBox(width: spacing),
            itemBuilder: (context, index) {
              return SizedBox(
                width: itemWidth,
                child: itemBuilder(context, items[index], index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader() {
    return Padding(
      padding: headerPadding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewAllText,
                      style: const TextStyle(
                        color: AppColors.darkPink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
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
}