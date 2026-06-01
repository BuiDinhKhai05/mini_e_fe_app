// lib/providers/product_provider.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../utils/app_constants.dart';
import 'auth_provider.dart';
import 'shop_provider.dart';

class ProductProvider with ChangeNotifier {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ====================== ADMIN PRODUCTS ======================
  List<ProductModel> _adminProducts = [];
  bool _isLoadingAdminProducts = false;
  String? _adminProductError;

  List<ProductModel> get adminProducts => _adminProducts;
  bool get isLoadingAdminProducts => _isLoadingAdminProducts;
  String? get adminProductError => _adminProductError;

  void clearProductsCache({bool notify = true}) {
    _products = [];
    _adminProducts = [];
    _error = null;
    _adminProductError = null;
    _isLoading = false;
    _isLoadingAdminProducts = false;

    if (notify) notifyListeners();
  }

  // ========================================================================
  // TOKEN HELPERS
  // ========================================================================
  Future<String?> _getOptionalToken() async {
    final context = AuthProvider.navigatorKey.currentContext;
    if (context == null) return null;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;
      if (token == null || token.isEmpty) return null;
      return token;
    } catch (_) {
      return null;
    }
  }

  Future<String> _getToken() async {
    final token = await _getOptionalToken();
    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập');
    }
    return token;
  }

  Options _authOptions(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Options _jsonAuthOptions(String token) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  // ========================================================================
  // PARSE HELPERS
  // ========================================================================
  dynamic _unwrapData(dynamic responseData) {
    if (responseData is Map && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  List<ProductModel> _parseProductsFromResponse(dynamic responseData) {
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

  ProductModel? _parseProductDetail(dynamic responseData) {
    final data = _unwrapData(responseData);
    if (data is Map) {
      return ProductModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  void _upsertInList(List<ProductModel> list, ProductModel product) {
    final index = list.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      final old = list[index];
      list[index] = product.copyWith(
        imageUrl: product.imageUrl.isNotEmpty ? product.imageUrl : old.imageUrl,
        images: product.images.isNotEmpty ? product.images : old.images,
        optionSchema: product.optionSchema ?? old.optionSchema,
        variants: product.variants ?? old.variants,
      );
    } else {
      list.insert(0, product);
    }
  }

  void _updateLocalProduct(ProductModel product) {
    _upsertInList(_products, product);
    _upsertInList(_adminProducts, product);
  }

  ProductModel? getProductFromCache(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      try {
        return _adminProducts.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  // ========================================================================
  // PUBLIC PRODUCTS
  // ========================================================================
  Future<void> fetchPublicProducts({
    bool showLoading = true,
    int page = 1,
    int limit = 100,
    String? q,
    int? shopId,
    int? categoryId,
    String? status,
    String sort = ProductSortValue.latest,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else {
      _error = null;
    }

    try {
      final response = await _dio.get(
        ProductApi.products,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (shopId != null) 'shopId': shopId,
          if (categoryId != null) 'categoryId': categoryId,
          if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
          'sort': sort,
        },
      );

      _products = _parseProductsFromResponse(response.data);
    } on DioException catch (e) {
      _error = _handleDioError(e, autoLogoutOn401: false);
    } catch (e) {
      _error = 'Lỗi tải sản phẩm: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ProductModel>> fetchBestSellingProducts({
    int page = 1,
    int limit = 6,
  }) async {
    try {
      final response = await _dio.get(
        ProductApi.products,
        queryParameters: {
          'page': page,
          'limit': limit,
          'sort': ProductSortValue.bestSelling,
        },
      );
      return _parseProductsFromResponse(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e, autoLogoutOn401: false));
    } catch (e) {
      throw Exception('Lỗi tải sản phẩm bán chạy: $e');
    }
  }

  Future<List<ProductModel>> fetchProductsByShopId(
      int shopId, {
        int page = 1,
        int limit = 100,
        String sort = ProductSortValue.latest,
      }) async {
    try {
      Response response;

      try {
        response = await _dio.get(
          ProductApi.byShop(shopId),
          queryParameters: {
            'page': page,
            'limit': limit,
            'sort': sort,
          },
        );
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;

        response = await _dio.get(
          ProductApi.products,
          queryParameters: {
            'page': page,
            'limit': limit,
            'shopId': shopId,
            'sort': sort,
          },
        );
      }

      return _parseProductsFromResponse(response.data);
    } on DioException catch (e) {
      throw Exception(_handleDioError(e, autoLogoutOn401: false));
    } catch (e) {
      throw Exception('Lỗi tải sản phẩm của shop: $e');
    }
  }

  // ========================================================================
  // SELLER PRODUCTS
  // ========================================================================
  Future<void> fetchAllProductsForSeller({
    bool showLoading = true,
    String? q,
    String? status,
    int? categoryId,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else {
      _error = null;
    }

    try {
      final token = await _getToken();

      final response = await _dio.get(
        ProductApi.myShopProducts,
        queryParameters: {
          'page': 1,
          'limit': 100,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
          if (categoryId != null) 'categoryId': categoryId,
        },
        options: _jsonAuthOptions(token),
      );

      _products = _parseProductsFromResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        await _fallbackFetchSellerProductsByShop();
      } else {
        _error = _handleDioError(e);
      }
    } catch (e) {
      _error = 'Lỗi tải sản phẩm của shop: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fallbackFetchSellerProductsByShop() async {
    int? shopId;
    final context = AuthProvider.navigatorKey.currentContext;

    if (context != null) {
      try {
        final shopProvider = Provider.of<ShopProvider>(context, listen: false);
        if (shopProvider.shop == null) {
          await shopProvider.loadMyShop();
        }
        shopId = shopProvider.shop?.id;
      } catch (_) {
        shopId = null;
      }
    }

    if (shopId == null) {
      _products = [];
      _error = 'Không tìm thấy shop của tài khoản seller';
      return;
    }

    final response = await _dio.get(
      ProductApi.products,
      queryParameters: {
        'page': 1,
        'limit': 100,
        'shopId': shopId,
      },
    );

    _products = _parseProductsFromResponse(response.data);
  }

  // ========================================================================
  // ADMIN PRODUCTS
  // ========================================================================
  Future<void> fetchAdminProducts({
    int page = 1,
    int limit = 100,
    String? q,
    String? status,
    int? shopId,
    int? categoryId,
  }) async {
    _isLoadingAdminProducts = true;
    _adminProductError = null;
    notifyListeners();

    try {
      final token = await _getToken();

      final response = await _dio.get(
        ProductApi.adminAll,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
          if (shopId != null) 'shopId': shopId,
          if (categoryId != null) 'categoryId': categoryId,
        },
        options: _jsonAuthOptions(token),
      );

      _adminProducts = _parseProductsFromResponse(response.data);
    } on DioException catch (e) {
      _adminProductError = _handleDioError(e);
      debugPrint('Admin products error: ${e.response?.data}');
    } catch (e) {
      _adminProductError = 'Lỗi tải danh sách sản phẩm admin: $e';
    } finally {
      _isLoadingAdminProducts = false;
      notifyListeners();
    }
  }

  Future<bool> lockProductByAdmin(int productId) async {
    try {
      final token = await _getToken();

      final response = await _dio.patch(
        ProductApi.byId(productId),
        data: {'status': ProductStatusValue.locked},
        options: _jsonAuthOptions(token),
      );

      final updated = _parseProductDetail(response.data);
      if (updated != null) {
        _updateLocalProduct(updated);
      } else {
        final old = getProductFromCache(productId);
        if (old != null) {
          _updateLocalProduct(old.copyWith(status: ProductStatusValue.locked));
        }
      }

      notifyListeners();
      return true;
    } on DioException catch (e) {
      _adminProductError = _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _adminProductError = 'Không thể khóa sản phẩm: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProductByAdmin(int productId) async {
    try {
      final token = await _getToken();

      await _dio.delete(
        ProductApi.byId(productId),
        options: _authOptions(token),
      );

      final old = getProductFromCache(productId);
      if (old != null) {
        _updateLocalProduct(
          old.copyWith(deletedAt: DateTime.now().toIso8601String()),
        );
      }

      notifyListeners();
      return true;
    } on DioException catch (e) {
      _adminProductError = _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _adminProductError = 'Không thể xóa sản phẩm: $e';
      notifyListeners();
      return false;
    }
  }

  // ========================================================================
  // CREATE / UPDATE / DELETE
  // ========================================================================
  Future<ProductModel?> createProduct({
    required String title,
    required double price,
    int? stock,
    int? categoryId,
    String? description,
    String? slug,
    List<dynamic>? images,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();

      final formData = FormData.fromMap({
        'title': title.trim(),
        'price': price,
        if (categoryId != null) 'categoryId': categoryId,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
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

      final response = await _dio.post(
        ProductApi.products,
        data: formData,
        options: _authOptions(token),
      );

      final newProduct = _parseProductDetail(response.data);
      if (newProduct != null) {
        _products.insert(0, newProduct);
      }

      _isLoading = false;
      notifyListeners();
      return newProduct;
    } on DioException catch (e) {
      _error = _handleDioError(e);
      debugPrint('Create product error: ${e.response?.data}');
    } catch (e) {
      _error = 'Lỗi tạo sản phẩm: $e';
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<bool> updateProduct({
    required int productId,
    String? title,
    double? price,
    int? stock,
    int? categoryId,
    String? description,
    String? slug,
    String? status,
    List<dynamic>? images,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final jsonBody = <String, dynamic>{};

      if (title != null) jsonBody['title'] = title.trim();
      if (price != null) jsonBody['price'] = price;
      if (categoryId != null) jsonBody['categoryId'] = categoryId;
      if (description != null) jsonBody['description'] = description.trim();
      if (slug != null) jsonBody['slug'] = slug.trim();
      if (status != null) jsonBody['status'] = status.toUpperCase().trim();

      if (jsonBody.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final response = await _dio.patch(
        ProductApi.byId(productId),
        data: jsonBody,
        options: _jsonAuthOptions(token),
      );

      final updated = _parseProductDetail(response.data);
      if (updated != null) {
        _updateLocalProduct(updated);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _handleDioError(e);
      debugPrint('Update product error: ${e.response?.data}');
    } catch (e) {
      _error = 'Lỗi cập nhật sản phẩm: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteProduct(int productId) async {
    try {
      final token = await _getToken();

      await _dio.delete(
        ProductApi.byId(productId),
        options: _authOptions(token),
      );

      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Lỗi xóa sản phẩm: $e';
      notifyListeners();
      return false;
    }
  }

  Future<ProductModel?> fetchProductDetail(int id) async {
    try {
      final token = await _getOptionalToken();

      if (token != null) {
        try {
          final manageResponse = await _dio.get(
            ProductApi.manageDetail(id),
            options: _jsonAuthOptions(token),
          );
          final manageProduct = _parseProductDetail(manageResponse.data);
          if (manageProduct != null) return manageProduct;
        } on DioException catch (e) {
          if (e.response?.statusCode != 404) {
            rethrow;
          }
        }
      }

      final response = await _dio.get(ProductApi.byId(id));
      return _parseProductDetail(response.data);
    } on DioException catch (e) {
      _error = _handleDioError(e, autoLogoutOn401: false);
      notifyListeners();
      return getProductFromCache(id);
    } catch (_) {
      return getProductFromCache(id);
    }
  }

  // ========================================================================
  // VARIANTS
  // ========================================================================
  Future<List<dynamic>?> generateVariants(
      int productId,
      List<Map<String, dynamic>> options, {
        String mode = 'replace',
      }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();

      final response = await _dio.post(
        ProductApi.generateVariants(productId),
        data: {
          'options': options,
          'mode': mode,
        },
        options: _jsonAuthOptions(token),
      );

      _isLoading = false;
      notifyListeners();

      final data = _unwrapData(response.data);
      return data is List ? data : <dynamic>[];
    } on DioException catch (e) {
      _error = _handleDioError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<VariantItem>> getVariants(int productId) async {
    try {
      final response = await _dio.get(ProductApi.variants(productId));
      final data = _unwrapData(response.data);
      final list = data is List ? data : <dynamic>[];

      return list
          .whereType<Map>()
          .map((item) => VariantItem.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on DioException catch (e) {
      _error = _handleDioError(e, autoLogoutOn401: false);
      debugPrint('Get variants error: $_error');
      notifyListeners();
      return [];
    } catch (e) {
      debugPrint('Get variants error: $e');
      return [];
    }
  }

  Future<bool> updateVariant(
      int productId,
      int variantId,
      Map<String, dynamic> dto,
      ) async {
    try {
      final token = await _getToken();

      await _dio.patch(
        ProductApi.variant(productId, variantId),
        data: dto,
        options: _jsonAuthOptions(token),
      );

      return true;
    } on DioException catch (e) {
      _error = _handleDioError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVariant(int productId, int variantId) async {
    _error =
    'Backend hiện tại chưa có API xóa biến thể. Hãy dùng chế độ replace để tạo lại danh sách biến thể.';
    notifyListeners();
    return false;
  }

  Future<dynamic> createVariant(int productId, Map<String, dynamic> dto) async {
    _error =
    'Backend hiện tại chưa có API tạo biến thể thủ công. Hãy dùng chức năng generate biến thể.';
    notifyListeners();
    return null;
  }

  // ========================================================================
  // STATUS
  // ========================================================================
  Future<bool> updateProductStatus({
    required int productId,
    required String status,
  }) async {
    final nextStatus = status.toUpperCase().trim();

    if (![ProductStatusValue.active, ProductStatusValue.outOfStock, ProductStatusValue.locked]
        .contains(nextStatus)) {
      _error = 'Trạng thái sản phẩm không hợp lệ';
      notifyListeners();
      return false;
    }

    return updateProduct(productId: productId, status: nextStatus);
  }

  Future<bool> toggleProductStatus(int productId, {String? currentStatus}) async {
    final product = getProductFromCache(productId);
    final oldStatus = (currentStatus ?? product?.status)?.toUpperCase().trim();

    if (oldStatus == null || oldStatus.isEmpty) {
      _error = 'Không xác định được trạng thái hiện tại của sản phẩm';
      notifyListeners();
      return false;
    }

    if (oldStatus == ProductStatusValue.locked) {
      _error = 'Sản phẩm đã bị admin khóa, không thể đổi trạng thái';
      notifyListeners();
      return false;
    }

    final newStatus = oldStatus == ProductStatusValue.active
        ? ProductStatusValue.outOfStock
        : ProductStatusValue.active;

    return updateProductStatus(productId: productId, status: newStatus);
  }

  Future<void> refresh() async {
    final context = AuthProvider.navigatorKey.currentContext;
    if (context == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.user?.role?.toUpperCase();

      if (role == 'SELLER') {
        await fetchAllProductsForSeller(showLoading: false);
      } else if (role == 'ADMIN') {
        await fetchAdminProducts();
      } else {
        await fetchPublicProducts(showLoading: false);
      }
    } catch (_) {
      await fetchPublicProducts(showLoading: false);
    }
  }

  // ========================================================================
  // ERROR
  // ========================================================================
  String _handleDioError(DioException e, {bool autoLogoutOn401 = true}) {
    debugPrint('Dio Error: ${e.type} | Status: ${e.response?.statusCode}');

    if (e.response?.statusCode == 401) {
      final context = AuthProvider.navigatorKey.currentContext;
      if (autoLogoutOn401 && context != null && context.mounted) {
        Provider.of<AuthProvider>(context, listen: false).logout();
      }
      return 'Phiên đăng nhập hết hạn';
    }

    if (e.response != null) {
      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        if (data['message'] is List) {
          return (data['message'] as List).join('\n');
        }
        return data['message'].toString();
      }

      return 'Lỗi server';
    }

    return 'Lỗi kết nối mạng';
  }
}
