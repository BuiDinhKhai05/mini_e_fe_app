// lib/providers/product_provider.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';
import '../utils/app_constants.dart';
import '../service/api_client.dart';
import 'auth_provider.dart';
import 'shop_provider.dart';

class ProductProvider with ChangeNotifier {
  // Dùng ApiClient chung của app để mọi request sản phẩm đều đi qua
  // interceptor refresh token. Không tạo Dio riêng ở provider nữa,
  // vì Dio riêng sẽ không tự gọi /auth/refresh khi access token hết hạn.
  final ApiClient _api = ApiClient();

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
    // Chỉ dùng để biết người dùng đang có token hay không.
    // Token thật sẽ được ApiClient tự gắn vào header và tự refresh khi 401.
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) return null;
      return token;
    } catch (_) {
      return null;
    }
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

  bool _isApiErrorResponse(dynamic responseData) {
    if (responseData is! Map) return false;

    final success = responseData['success'];
    final statusCode = responseData['statusCode'];
    final error = responseData['error']?.toString().toLowerCase() ?? '';
    final message = responseData['message']?.toString().toLowerCase() ?? '';

    return success == false ||
        statusCode == 413 ||
        error.contains('payload too large') ||
        message.contains('file too large');
  }

  String _extractApiErrorMessage(dynamic responseData) {
    if (responseData is! Map) {
      return 'Thao tác thất bại';
    }

    final statusCode = responseData['statusCode'];
    final error = responseData['error']?.toString().toLowerCase() ?? '';
    final messageRaw = responseData['message'];

    if (statusCode == 413 ||
        error.contains('payload too large') ||
        messageRaw.toString().toLowerCase().contains('file too large')) {
      return 'Ảnh sản phẩm quá lớn. Vui lòng chọn ảnh nhỏ hơn hoặc chọn ảnh đã được nén.';
    }

    if (messageRaw is List) {
      return messageRaw.map((e) => e.toString()).join('\n');
    }

    if (messageRaw != null && messageRaw.toString().trim().isNotEmpty) {
      return messageRaw.toString();
    }

    final errorText = responseData['error']?.toString();
    if (errorText != null && errorText.trim().isNotEmpty) {
      return errorText;
    }

    return 'Thao tác thất bại';
  }

  Map<String, dynamic>? _extractProductMap(dynamic responseData) {
    final data = _unwrapData(responseData);

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      if (_isApiErrorResponse(map)) return null;

      final hasProductFields = map.containsKey('id') ||
          map.containsKey('productId') ||
          map.containsKey('product_id') ||
          map.containsKey('title') ||
          map.containsKey('name');

      if (hasProductFields) return map;

      for (final key in const [
        'product',
        'item',
        'result',
        'payload',
        'createdProduct',
        'savedProduct',
      ]) {
        final nested = map[key];
        if (nested is Map) {
          final extracted = _extractProductMap(nested);
          if (extracted != null) return extracted;
        }
      }
    }

    return null;
  }

  List<ProductModel> _parseProductsFromResponse(dynamic responseData) {
    final data = _unwrapData(responseData);
    dynamic rawList;

    if (data is Map) {
      rawList = data['items'] ??
          data['products'] ??
          data['rows'] ??
          data['data'] ??
          [];
    } else if (data is List) {
      rawList = data;
    } else {
      rawList = [];
    }

    if (rawList is! List) return [];

    return rawList
        .whereType<Map>()
        .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
        .where((product) => product.id > 0)
        .toList();
  }

  ProductModel? _parseProductDetail(dynamic responseData) {
    final map = _extractProductMap(responseData);
    if (map == null) return null;

    final product = ProductModel.fromJson(map);
    if (product.id <= 0) return null;

    return product;
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
      final response = await _api.get(
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
      final response = await _api.get(
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
        response = await _api.get(
          ProductApi.byShop(shopId),
          queryParameters: {
            'page': page,
            'limit': limit,
            'sort': sort,
          },
        );
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;

        response = await _api.get(
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
      final response = await _api.get(
        ProductApi.myShopProducts,
        queryParameters: {
          'page': 1,
          'limit': 100,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
          if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
          if (categoryId != null) 'categoryId': categoryId,
        },
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

    final response = await _api.get(
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
      final response = await _api.patch(
        ProductApi.byId(productId),
        data: {'status': ProductStatusValue.locked},
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


  Future<bool> activateProductByAdmin(int productId) async {
    try {
      final response = await _api.patch(
        ProductApi.byId(productId),
        data: {'status': ProductStatusValue.active},
      );

      final updated = _parseProductDetail(response.data);
      if (updated != null) {
        _updateLocalProduct(updated);
      } else {
        final old = getProductFromCache(productId);
        if (old != null) {
          _updateLocalProduct(old.copyWith(status: ProductStatusValue.active));
        }
      }

      notifyListeners();
      return true;
    } on DioException catch (e) {
      _adminProductError = _handleDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _adminProductError = 'Không thể mở khóa sản phẩm: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProductByAdmin(int productId) async {
    try {
      await _api.delete(
        ProductApi.byId(productId),
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

      final response = await _api.post(
        ProductApi.products,
        data: formData,
      );

      // Một số ApiClient không throw DioException với HTTP 413,
      // mà trả body lỗi dạng {success:false, statusCode:413, ...}.
      // Vì vậy phải kiểm tra body trước khi parse ProductModel.
      if (_isApiErrorResponse(response.data)) {
        _error = _extractApiErrorMessage(response.data);
        debugPrint('Create product failed response: ${response.data}');
        return null;
      }

      final newProduct = _parseProductDetail(response.data);
      if (newProduct == null || newProduct.id <= 0) {
        _error =
        'Tạo sản phẩm thành công nhưng FE không lấy được mã sản phẩm mới. Vui lòng tải lại danh sách sản phẩm.';
        debugPrint('Create product response missing valid id: ${response.data}');
        return null;
      }

      _products.insert(0, newProduct);
      notifyListeners();
      return newProduct;
    } on DioException catch (e) {
      _error = _handleDioError(e);
      debugPrint('Create product error: ${e.response?.data}');
      return null;
    } catch (e) {
      _error = 'Lỗi tạo sản phẩm: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      final response = await _api.patch(
        ProductApi.byId(productId),
        data: jsonBody,
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
      await _api.delete(
        ProductApi.byId(productId),
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
          final manageResponse = await _api.get(
            ProductApi.manageDetail(id),
          );
          final manageProduct = _parseProductDetail(manageResponse.data);
          if (manageProduct != null) return manageProduct;
        } on DioException catch (e) {
          if (e.response?.statusCode != 404) {
            rethrow;
          }
        }
      }

      final response = await _api.get(ProductApi.byId(id));
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
      final response = await _api.post(
        ProductApi.generateVariants(productId),
        data: {
          'options': options,
          'mode': mode,
        },
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
      final response = await _api.get(ProductApi.variants(productId));
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
      await _api.patch(
        ProductApi.variant(productId, variantId),
        data: dto,
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

    if (e.response?.statusCode == 413) {
      return 'Ảnh sản phẩm quá lớn. Vui lòng chọn ảnh nhỏ hơn hoặc chọn ảnh đã được nén.';
    }

    if (e.response != null) {
      final data = e.response?.data;

      if (data is Map) {
        return _extractApiErrorMessage(data);
      }

      return 'Lỗi server';
    }

    return 'Lỗi kết nối mạng';
  }

}
