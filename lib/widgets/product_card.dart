// lib/widgets/product_card.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final int stock;
  final String status;
  final int sold;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.stock = 0,
    this.status = ProductStatusValue.active,
    this.sold = 0,
    required this.onTap,
  });

  bool get _isOutOfStock =>
      status.toUpperCase().trim() == ProductStatusValue.outOfStock || stock <= 0;

  bool get _isLocked => status.toUpperCase().trim() == ProductStatusValue.locked;

  String get _statusText {
    if (_isLocked) return 'Đã khóa';
    if (_isOutOfStock) return 'Hết hàng';
    return 'Còn $stock sản phẩm';
  }

  Color get _statusColor {
    if (_isLocked) return Colors.red.shade700;
    if (_isOutOfStock) return Colors.orange.shade800;
    return Colors.grey.shade700;
  }

  String _formatPrice(double value) {
    final text = value.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    );
    return '$text VNĐ';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: _buildProductImage(),
                    ),
                  ),
                  if (_isOutOfStock || _isLocked)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isLocked ? Colors.red.shade600 : Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _isLocked ? 'Khóa' : 'Hết hàng',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatPrice(price),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: _statusColor,
                        fontWeight: (_isOutOfStock || _isLocked)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (sold > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Đã bán $sold',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[100],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) {
        debugPrint('Lỗi tải ảnh product $id: $error | $url');
        return Container(
          color: Colors.red[50],
          child: const Icon(Icons.broken_image, color: Colors.red),
        );
      },
    );
  }
}
