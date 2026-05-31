// lib/service/product_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

import '../models/product_model.dart';
import '../service/api_client.dart';
import '../utils/app_constants.dart';

class ProductService {
  final ApiClient _api;

  ProductService(this._api);

  dynamic _unwrapData(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  List<ProductModel> _parseProductList(dynamic responseData) {
    final data = _unwrapData(responseData);
    dynamic rawList;

    if (data is Map) {
      rawList = data['items'] ?? data['data'] ?? [];
    } else if (data is List) {
      rawList = data;
    } else {
      rawList = [];
    }

    if (rawList is! List) return [];

    return rawList
        .whereType<Map>()
        .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  ProductModel _parseProductDetail(dynamic responseData) {
    final data = _unwrapData(responseData);
    if (data is! Map) throw Exception('Dữ liệu sản phẩm trống');
    return ProductModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<ProductModel>> getProducts({
    int page = 1,
    int limit = 20,
    String? q,
    String? search,
    int? shopId,
    int? categoryId,
    String? status,
    String sort = ProductSortValue.latest,
  }) async {
    try {
      final keyword = (q ?? search ?? '').trim();

      final response = await _api.get(
        ProductApi.products,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (keyword.isNotEmpty) 'q': keyword,
          if (shopId != null) 'shopId': shopId,
          if (categoryId != null) 'categoryId': categoryId,
          if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
          'sort': sort,
        },
      );

      return _parseProductList(response.data);
    } catch (e) {
      throw Exception('Lỗi tải sản phẩm: $e');
    }
  }

  Future<List<ProductModel>> getBestSellingProducts({
    int page = 1,
    int limit = 6,
  }) {
    return getProducts(
      page: page,
      limit: limit,
      sort: ProductSortValue.bestSelling,
    );
  }

  Future<List<ProductModel>> getMyShopProducts({
    int page = 1,
    int limit = 100,
    String? q,
    String? status,
    int? categoryId,
  }) async {
    final response = await _api.get(
      ProductApi.myShopProducts,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (categoryId != null) 'categoryId': categoryId,
      },
    );

    return _parseProductList(response.data);
  }

  Future<List<ProductModel>> getAdminProducts({
    int page = 1,
    int limit = 100,
    String? q,
    String? status,
    int? shopId,
    int? categoryId,
  }) async {
    final response = await _api.get(
      ProductApi.adminAll,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (shopId != null) 'shopId': shopId,
        if (categoryId != null) 'categoryId': categoryId,
      },
    );

    return _parseProductList(response.data);
  }

  Future<ProductModel> getProductById(int productId) async {
    try {
      final response = await _api.get(ProductApi.byId(productId));
      return _parseProductDetail(response.data);
    } catch (e) {
      throw Exception('Không tìm thấy sản phẩm: $e');
    }
  }

  Future<List<ProductModel>> getProductsByShop(
      int shopId, {
        int page = 1,
        int limit = 100,
      }) async {
    try {
      final response = await _api.get(
        ProductApi.byShop(shopId),
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      return _parseProductList(response.data);
    } catch (_) {
      return getProducts(page: page, limit: limit, shopId: shopId);
    }
  }

  Future<ProductModel> createProduct({
    int? shopId,
    required String title,
    String? slug,
    String? description,
    required double price,
    double? compareAtPrice,
    int? stock,
    int? categoryId,
    String status = ProductStatusValue.active,
    List<dynamic>? images,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title.trim(),
        'price': price,
        if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (categoryId != null) 'categoryId': categoryId,
      });

      if (images != null && images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final item = images[i];
          MultipartFile multipartFile;

          if (kIsWeb && item is Uint8List) {
            multipartFile = MultipartFile.fromBytes(
              item,
              filename: 'image_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            );
          } else if (!kIsWeb && item is File) {
            multipartFile = await MultipartFile.fromFile(
              item.path,
              filename: item.path.split('/').last,
            );
          } else {
            continue;
          }

          formData.files.add(MapEntry('images', multipartFile));
        }
      }

      final response = await _api.post(
        ProductApi.products,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return _parseProductDetail(response.data);
    } catch (e) {
      throw Exception('Tạo sản phẩm thất bại: $e');
    }
  }

  Future<ProductModel> updateProduct(
      int productId, {
        String? title,
        String? slug,
        String? description,
        double? price,
        double? compareAtPrice,
        int? stock,
        int? categoryId,
        String? status,
        List<File>? newImages,
      }) async {
    try {
      final body = <String, dynamic>{};

      if (title != null) body['title'] = title.trim();
      if (slug != null) body['slug'] = slug.trim();
      if (description != null) body['description'] = description.trim();
      if (price != null) body['price'] = price;
      if (categoryId != null) body['categoryId'] = categoryId;
      if (status != null) body['status'] = status.toUpperCase().trim();

      final response = await _api.patch(
        ProductApi.byId(productId),
        data: body,
        options: Options(contentType: 'application/json'),
      );

      return _parseProductDetail(response.data);
    } catch (e) {
      throw Exception('Cập nhật thất bại: $e');
    }
  }

  Future<List<VariantItem>> getVariants(int productId) async {
    try {
      final response = await _api.get(ProductApi.variants(productId));
      final data = _unwrapData(response.data);
      final list = data is List ? data : <dynamic>[];
      return list
          .whereType<Map>()
          .map((item) => VariantItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy biến thể: $e');
    }
  }

  Future<List<dynamic>> generateVariants(
      int productId,
      Map<String, dynamic> data,
      ) async {
    try {
      final response = await _api.post(
        ProductApi.generateVariants(productId),
        data: data,
      );
      final result = _unwrapData(response.data);
      return result is List ? result : <dynamic>[];
    } catch (e) {
      throw Exception('Lỗi sinh biến thể: $e');
    }
  }

  Future<bool> updateVariant(
      int productId,
      int variantId,
      Map<String, dynamic> data,
      ) async {
    try {
      await _api.patch(
        ProductApi.variant(productId, variantId),
        data: data,
      );
      return true;
    } catch (e) {
      throw Exception('Lỗi cập nhật biến thể: $e');
    }
  }

  Future<dynamic> createVariant(int productId, Map<String, dynamic> data) {
    throw Exception('Backend hiện tại chưa có API tạo biến thể thủ công. Hãy dùng generate variants.');
  }

  Future<bool> deleteVariant(int productId, int variantId) {
    throw Exception('Backend hiện tại chưa có API xóa biến thể. Hãy dùng mode replace để tạo lại biến thể.');
  }

  Future<void> deleteProduct(int productId) async {
    try {
      await _api.delete(ProductApi.byId(productId));
    } catch (e) {
      throw Exception('Xóa sản phẩm thất bại: $e');
    }
  }

  Future<List<ProductModel>> getDeletedProducts({int limit = 50}) {
    return getAdminProducts(limit: limit);
  }

  Future<void> restoreProduct(int productId) {
    throw Exception('Backend hiện tại chưa có API khôi phục sản phẩm đã xóa.');
  }
}
