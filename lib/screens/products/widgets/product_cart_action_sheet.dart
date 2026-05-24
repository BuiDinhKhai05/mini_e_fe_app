import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mini_e_fe_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'package:mini_e_fe_app/models/product_model.dart';
import 'package:mini_e_fe_app/providers/cart_provider.dart';
import 'package:mini_e_fe_app/providers/product_provider.dart';

class ProductCartActionSheet {
  static const Color _primaryColor = AppColors.darkPink;
  static const Color _titleColor = AppColors.textDark;
  static const Color _bodyColor = AppColors.textGrey;

  static Future<void> show({
    required BuildContext context,
    required ProductModel product,
    required bool isBuyNow,
    List<VariantItem>? initialVariants,
    ValueChanged<List<VariantItem>>? onVariantsLoaded,
  }) async {
    final rootContext = context;

    int quantity = 1;
    int? selectedVariantId;
    final Map<String, String> selectedOptions = {};

    ProductModel dialogProduct = product;
    List<VariantItem> dialogVariants =
    List<VariantItem>.from(initialVariants ?? []);

    final productProvider =
    Provider.of<ProductProvider>(rootContext, listen: false);

    // Sản phẩm truyền từ Home thường chỉ là dữ liệu list nên có thể thiếu images[].
    // Lấy lại detail để popup có đủ ảnh sản phẩm và đổi ảnh đúng theo imageId của variant.
    try {
      final bool needFullProduct = dialogProduct.images.isEmpty ||
          dialogProduct.optionSchema == null ||
          dialogProduct.optionSchema!.isEmpty;

      if (needFullProduct) {
        final freshProduct = await productProvider.fetchProductDetail(product.id);

        if (freshProduct != null) {
          dialogProduct = freshProduct;
        }
      }
    } catch (_) {
      // Nếu không lấy được detail thì vẫn dùng product ban đầu.
    }

    if (dialogVariants.isEmpty) {
      try {
        dialogVariants = await productProvider.getVariants(dialogProduct.id);

        if (onVariantsLoaded != null) {
          onVariantsLoaded(dialogVariants);
        }
      } catch (_) {
        dialogVariants = [];
      }
    }

    if (!rootContext.mounted) return;

    final bool hasOptionSchema = dialogProduct.optionSchema != null &&
        dialogProduct.optionSchema!.isNotEmpty;

    bool didInitDefault = false;

    await showDialog(
      context: rootContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setStateDialog) {
            if (!didInitDefault) {
              didInitDefault = true;

              if (dialogVariants.isNotEmpty) {
                final firstInStock = dialogVariants.firstWhere(
                      (variant) => variant.stock > 0,
                  orElse: () => dialogVariants.first,
                );

                if (firstInStock.stock > 0) {
                  if (hasOptionSchema) {
                    for (final opt in firstInStock.options) {
                      final optionName = (opt['option'] ?? '').toString();
                      final optionValue = (opt['value'] ?? '').toString();

                      if (optionName.trim().isNotEmpty &&
                          optionValue.trim().isNotEmpty) {
                        selectedOptions[optionName] = optionValue;
                      }
                    }
                  }

                  selectedVariantId = firstInStock.id;
                }
              }
            }

            bool isFullSelection() {
              if (!hasOptionSchema) return selectedVariantId != null;

              return dialogProduct.optionSchema!.every((schema) {
                final name = schema.name.toString();
                return selectedOptions[name] != null &&
                    selectedOptions[name]!.trim().isNotEmpty;
              });
            }

            VariantItem? findVariantBySelectedOptions() {
              if (!hasOptionSchema ||
                  !isFullSelection() ||
                  dialogVariants.isEmpty) {
                return null;
              }

              for (final variant in dialogVariants) {
                final vMap = _variantOptionMap(variant);
                bool matched = true;

                for (final schema in dialogProduct.optionSchema!) {
                  final optionName = schema.name.toString();
                  final selectedValue = selectedOptions[optionName];

                  if (selectedValue == null || selectedValue.trim().isEmpty) {
                    matched = false;
                    break;
                  }

                  if (vMap[_norm(optionName)] != _norm(selectedValue)) {
                    matched = false;
                    break;
                  }
                }

                if (matched) return variant;
              }

              return null;
            }

            bool isOptionValueAvailable(String optionName, String value) {
              if (dialogVariants.isEmpty) return false;

              for (final variant in dialogVariants) {
                if (variant.stock <= 0) continue;

                final vMap = _variantOptionMap(variant);
                if (vMap[_norm(optionName)] != _norm(value)) continue;

                bool matchedOtherSelectedOptions = true;

                for (final entry in selectedOptions.entries) {
                  if (_norm(entry.key) == _norm(optionName)) continue;
                  if (entry.value.trim().isEmpty) continue;

                  if (vMap[_norm(entry.key)] != _norm(entry.value)) {
                    matchedOtherSelectedOptions = false;
                    break;
                  }
                }

                if (matchedOtherSelectedOptions) return true;
              }

              return false;
            }

            VariantItem? selectedVariant;

            if (hasOptionSchema) {
              selectedVariant = findVariantBySelectedOptions();
              selectedVariantId = selectedVariant?.id;
            } else if (selectedVariantId != null) {
              try {
                selectedVariant = dialogVariants.firstWhere(
                      (variant) => variant.id == selectedVariantId,
                );
              } catch (_) {
                selectedVariant = null;
              }
            }

            int maxStock = _productStock(dialogProduct);

            if (selectedVariant != null) {
              maxStock = selectedVariant.stock;
            } else if (dialogVariants.isNotEmpty) {
              maxStock = 0;
            }

            if (maxStock > 0 && quantity > maxStock) {
              quantity = maxStock;
            }

            final displayPrice =
            selectedVariant != null && selectedVariant.price > 0
                ? _formatPrice(selectedVariant.price)
                : _formatPrice(dialogProduct.price);

            final selectedText = hasOptionSchema
                ? dialogProduct.optionSchema!
                .map((schema) {
              final name = schema.name.toString();
              final value = selectedOptions[name];

              if (value == null || value.trim().isEmpty) return null;

              return '$name: $value';
            })
                .whereType<String>()
                .join(', ')
                : selectedVariant?.name ?? '';

            return Dialog(
              backgroundColor: AppColors.background,
              insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(dialogContext).size.height * 0.78,
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.78,
                ),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: _bodyColor,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: _dialogImageUrl(
                                dialogProduct,
                                selectedVariant,
                              ),
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              placeholder: (_, __) => Container(
                                color: Colors.white,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.white,
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: AppColors.textLight,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dialogProduct.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: _titleColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  '$displayPrice VNĐ',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.error,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                if (dialogVariants.isNotEmpty)
                                  Text(
                                    selectedVariant != null
                                        ? 'Kho: ${selectedVariant.stock}'
                                        : 'Kho: ...',
                                    style: const TextStyle(
                                      color: _bodyColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                else
                                  Text(
                                    'Kho: ${_productStock(dialogProduct)}',
                                    style: const TextStyle(
                                      color: _bodyColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                if (dialogVariants.isNotEmpty &&
                                    selectedText.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Đang chọn: $selectedText',
                                      style: const TextStyle(
                                        color: AppColors.textGrey,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      if (dialogVariants.isNotEmpty && hasOptionSchema) ...[
                        const Text(
                          'Phân loại:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _titleColor,
                          ),
                        ),

                        const SizedBox(height: 14),

                        ...dialogProduct.optionSchema!.map((schema) {
                          final optionName = schema.name.toString();
                          final selectedValue = selectedOptions[optionName];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  optionName,
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: schema.values.map<Widget>((value) {
                                    final optionValue = value.toString();
                                    final isSelected =
                                        selectedValue == optionValue;
                                    final isAvailable = isOptionValueAvailable(
                                      optionName,
                                      optionValue,
                                    );

                                    return InkWell(
                                      onTap: !isAvailable
                                          ? null
                                          : () {
                                        setStateDialog(() {
                                          selectedOptions[optionName] =
                                              optionValue;

                                          final found =
                                          findVariantBySelectedOptions();

                                          selectedVariantId = found?.id;
                                          quantity = 1;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(999),
                                      child: AnimatedContainer(
                                        duration:
                                        const Duration(milliseconds: 160),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.lightPink
                                              : Colors.white,
                                          borderRadius:
                                          BorderRadius.circular(999),
                                          border: Border.all(
                                            color: isSelected
                                                ? _primaryColor
                                                : AppColors.borderPink,
                                            width: 1.4,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                            BoxShadow(
                                              color: _primaryColor
                                                  .withOpacity(0.12),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                              : null,
                                        ),
                                        child: Text(
                                          optionValue,
                                          style: TextStyle(
                                            color: !isAvailable
                                                ? AppColors.textLight
                                                : isSelected
                                                ? _primaryColor
                                                : AppColors.textDark,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ] else if (dialogVariants.isNotEmpty) ...[
                        const Text(
                          'Phân loại:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _titleColor,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: dialogVariants.map((variant) {
                            final isSelected = selectedVariantId == variant.id;
                            final stock = variant.stock;

                            return ChoiceChip(
                              label: Text('${variant.name} ($stock)'),
                              selected: isSelected,
                              onSelected: stock <= 0
                                  ? null
                                  : (value) {
                                setStateDialog(() {
                                  selectedVariantId =
                                  value ? variant.id : null;
                                  quantity = 1;
                                });
                              },
                              selectedColor: _primaryColor,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : _titleColor,
                                fontWeight: FontWeight.w800,
                              ),
                              backgroundColor: Colors.white,
                              disabledColor: AppColors.borderGrey,
                              side: BorderSide(
                                color: isSelected
                                    ? _primaryColor
                                    : AppColors.borderPink,
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 18),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.25),
                            ),
                          ),
                          child: const Text(
                            'Sản phẩm này chưa có biến thể để mua (variant).\nVui lòng chọn sản phẩm khác.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),

                        const SizedBox(height: 14),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Số lượng:',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: _titleColor,
                            ),
                          ),

                          Row(
                            children: [
                              IconButton(
                                onPressed: quantity <= 1
                                    ? null
                                    : () {
                                  setStateDialog(() {
                                    quantity--;
                                  });
                                },
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: _bodyColor,
                                ),
                              ),

                              Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: _titleColor,
                                ),
                              ),

                              IconButton(
                                onPressed: maxStock <= 0 || quantity >= maxStock
                                    ? null
                                    : () {
                                  setStateDialog(() {
                                    quantity++;
                                  });
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (dialogVariants.isEmpty) {
                              _showSnack(
                                rootContext,
                                'Sản phẩm chưa có biến thể để mua',
                              );
                              return;
                            }

                            if (hasOptionSchema && !isFullSelection()) {
                              _showSnack(
                                rootContext,
                                'Vui lòng chọn đầy đủ phân loại',
                              );
                              return;
                            }

                            if (selectedVariantId == null) {
                              _showSnack(
                                rootContext,
                                'Vui lòng chọn phân loại hợp lệ',
                              );
                              return;
                            }

                            if (maxStock <= 0) {
                              _showSnack(
                                rootContext,
                                'Sản phẩm đã hết hàng',
                              );
                              return;
                            }

                            try {
                              await Provider.of<CartProvider>(
                                rootContext,
                                listen: false,
                              ).addToCart(
                                dialogProduct.id,
                                variantId: selectedVariantId!,
                                quantity: quantity,
                              );

                              if (!rootContext.mounted ||
                                  !dialogContext.mounted) {
                                return;
                              }

                              Navigator.pop(dialogContext);

                              if (isBuyNow) {
                                Navigator.pushNamed(rootContext, '/cart');
                              } else {
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã thêm vào giỏ hàng'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!rootContext.mounted) return;

                              final msg = e
                                  .toString()
                                  .replaceAll('Exception:', '')
                                  .trim();

                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                SnackBar(
                                  content: Text(msg),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isBuyNow ? 'MUA NGAY' : 'THÊM VÀO GIỎ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _norm(String value) {
    return value.trim().toLowerCase();
  }

  static Map<String, String> _variantOptionMap(VariantItem variant) {
    final result = <String, String>{};

    for (final opt in variant.options) {
      final key = _norm((opt['option'] ?? '').toString());
      final value = _norm((opt['value'] ?? '').toString());

      if (key.isNotEmpty) {
        result[key] = value;
      }
    }

    return result;
  }

  static String _dialogImageUrl(
      ProductModel product,
      VariantItem? variant,
      ) {
    if (variant?.imageId != null && product.images.isNotEmpty) {
      final index = product.images.indexWhere(
            (image) => image.id == variant!.imageId,
      );

      if (index != -1) {
        return product.images[index].url;
      }
    }

    if (product.imageUrl.isNotEmpty) {
      return product.imageUrl;
    }

    if (product.images.isNotEmpty) {
      return product.images.first.url;
    }

    return 'https://placehold.co/300x300.png?text=No+Image';
  }

  static int _productStock(ProductModel product) {
    final dynamic value = product.stock;
    if (value is num) return value.toInt();
    return 0;
  }

  static String _formatPrice(dynamic price) {
    double value = 0.0;

    if (price is String) {
      value = double.tryParse(price) ?? 0.0;
    } else if (price is num) {
      value = price.toDouble();
    }

    return value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    );
  }

  static void _showSnack(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
