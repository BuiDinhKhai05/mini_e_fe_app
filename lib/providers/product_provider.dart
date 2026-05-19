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

/// ---------------------------------------------------------------------------
/// PRODUCT PROVIDER – QUẢN LÝ SẢN PHẨM & GỌI API
/// ---------------------------------------------------------------------------
/// Lưu ý quan trọng theo BE hiện tại:
/// - GET /products, GET /products/:id, GET /products/:id/variants là public.
/// - POST /products dùng multipart key là `images`.
/// - PATCH /products/:id hiện chỉ nhận JSON, chưa nhận upload ảnh.
/// - Product stock trên BE được đồng bộ từ variants, không sửa trực tiếp ở product.
/// - BE chưa có DELETE variant / POST variant thủ công.
class ProductProvider with ChangeNotifier {
  // ====================== DIO CLIENT ======================
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // ====================== TRẠNG THÁI ======================
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ProductProvider();

  // ========================================================================
  // 0. XÓA CACHE DỮ LIỆU (Dùng khi logout hoặc switch account)
  // ========================================================================
  void clearProductsCache({bool notify = true}) {
    _products = [];
    _error = null;
    _isLoading = false;

    if (notify) notifyListeners();
  }

  // ========================================================================
  // 1. TOKEN HELPERS
  // ========================================================================
  Future<String> _getToken() async {
    final token = await _getOptionalToken();
    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập');
    }
    return token;
  }

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

  Options _jsonAuthOptions(String token) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  // ========================================================================
  // 2. LẤY DANH SÁCH SẢN PHẨM
  // ========================================================================

  /// PUBLIC: chỉ lấy sản phẩm ACTIVE vì BE public đang hard-code ACTIVE.
  Future<void> fetchPublicProducts({bool showLoading = true}) async {
    await _fetchProductsWithFilter(showLoading: showLoading);
  }

  /// SELLER: BE hiện tại CHƯA có API lấy cả ACTIVE + DRAFT của shop.
  /// FE sẽ ưu tiên lọc theo shopId nếu load được shop, nhưng kết quả vẫn chỉ
  /// gồm ACTIVE do API public của BE đang giới hạn như vậy.
  Future<void> fetchAllProductsForSeller({bool showLoading = true}) async {
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

    await _fetchProductsWithFilter(
      shopId: shopId,
      showLoading: showLoading,
    );
  }

  Future<void> _fetchProductsWithFilter({
    int? shopId,
    required bool showLoading,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _products = [];
      _error = null;
      notifyListeners();
    } else {
      _error = null;
    }

    try {
      final response = await _dio.get(
        ProductApi.products,
        queryParameters: {
          'page': 1,
          'limit': 100,
          if (shopId != null) 'shopId': shopId,
        },
      );

      final dynamic data = response.data['data'];
      List<dynamic> rawList = [];

      if (data is Map) {
        rawList = data['items'] ?? [];
      } else if (data is List) {
        rawList = data;
      }

      _products = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => ProductModel.fromJson(item))
          .toList();
    } on DioException catch (e) {
      _error = _handleDioError(e, autoLogoutOn401: false);
    } catch (e) {
      _error = 'Lỗi tải sản phẩm: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================================================
  // 3. TẠO SẢN PHẨM MỚI – HỖ TRỢ MOBILE + WEB
  // ========================================================================
  Future<ProductModel?> createProduct({
    required String title,
    required double price,
    int? stock, // Giữ tham số để tránh sửa nhiều UI, nhưng BE hiện không nhận stock product.
    String? description,
    String? slug,
    List<dynamic>? images, // File (mobile) hoặc Uint8List (web)
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();

      final formData = FormData.fromMap({
        'title': title.trim(),
        'price': price,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
        // Không gửi stock vì CreateProductDto của BE hiện không có field stock.
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

          // BE NestJS: FilesInterceptor('images', 10, uploadOptions)
          formData.files.add(MapEntry('images', multipartFile));
        }
      }

      final response = await _dio.post(
        ProductApi.products,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final newProduct = ProductModel.fromJson(response.data['data']);
      _products.insert(0, newProduct);

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

  // ========================================================================
  // 4. CẬP NHẬT SẢN PHẨM
  // ========================================================================
  Future<bool> updateProduct({
    required int productId,
    String? title,
    double? price,
    int? stock, // BE không nhận field này ở product, tồn kho được sync từ variants.
    String? description,
    String? slug,
    String? status,
    List<dynamic>? images, // PATCH BE hiện chưa nhận upload ảnh, nên bỏ qua.
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final Map<String, dynamic> jsonBody = {};

      if (title != null) jsonBody['title'] = title.trim();
      if (price != null) jsonBody['price'] = price;
      if (description != null) jsonBody['description'] = description.trim();
      if (slug != null) jsonBody['slug'] = slug.trim();
      if (status != null) jsonBody['status'] = status;

      // Không gửi stock/images vì UpdateProductDto và PATCH hiện tại của BE chưa hỗ trợ.
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

      final data = response.data['data'];
      if (data is Map<String, dynamic>) {
        _updateLocalProduct(productId, data);
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

  void _updateLocalProduct(int id, Map<String, dynamic> jsonData) {
    final index = _products.indexWhere((p) => p.id == id);
    final incoming = ProductModel.fromJson(jsonData);

    if (index != -1) {
      final old = _products[index];
      _products[index] = incoming.copyWith(
        imageUrl: incoming.imageUrl.isNotEmpty ? incoming.imageUrl : old.imageUrl,
        images: incoming.images.isNotEmpty ? incoming.images : old.images,
        optionSchema: (incoming.optionSchema != null && incoming.optionSchema!.isNotEmpty)
            ? incoming.optionSchema
            : old.optionSchema,
        variants: (incoming.variants != null && incoming.variants!.isNotEmpty)
            ? incoming.variants
            : old.variants,
      );
      notifyListeners();
    }
  }

  ProductModel? getProductFromCache(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ========================================================================
  // 5. TẠO BIẾN THỂ TỰ ĐỘNG (GENERATE)
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
      final dto = {'options': options, 'mode': mode};

      final response = await _dio.post(
        ProductApi.generateVariants(productId),
        data: dto,
        options: _jsonAuthOptions(token),
      );

      _isLoading = false;
      notifyListeners();
      return response.data['data'];
    } on DioException catch (e) {
      _error = _handleDioError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ========================================================================
  // 6. LẤY DANH SÁCH BIẾN THỂ
  // ========================================================================
  Future<List<VariantItem>> getVariants(int productId) async {
    try {
      final response = await _dio.get(ProductApi.variants(productId));
      final List list = response.data['data'] ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => VariantItem.fromJson(e))
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

  // ========================================================================
  // 7. CẬP NHẬT MỘT BIẾN THỂ
  // ========================================================================
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

  // ========================================================================
  // 8. LẤY CHI TIẾT 1 SẢN PHẨM
  // ========================================================================
  Future<ProductModel?> fetchProductDetail(int id) async {
    try {
      final response = await _dio.get(ProductApi.byId(id));
      return ProductModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      _error = _handleDioError(e, autoLogoutOn401: false);
      notifyListeners();
      return null;
    }
  }

  // ========================================================================
  // 9. XÓA SẢN PHẨM
  // ========================================================================
  Future<bool> deleteProduct(int productId) async {
    try {
      final token = await _getToken();
      await _dio.delete(
        ProductApi.byId(productId),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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

  // ========================================================================
  // 10. REFRESH DATA
  // ========================================================================
  Future<void> refresh() async {
    final context = AuthProvider.navigatorKey.currentContext;
    if (context == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final role = authProvider.user?.role?.toUpperCase();

      if (role == 'SELLER') {
        await fetchAllProductsForSeller(showLoading: false);
      } else if (role == 'ADMIN') {
        clearProductsCache();
      } else {
        await fetchPublicProducts(showLoading: false);
      }
    } catch (_) {
      await fetchPublicProducts(showLoading: false);
    }
  }

  // ========================================================================
  // 11. XÓA MỘT BIẾN THỂ
  // ========================================================================
  Future<bool> deleteVariant(int productId, int variantId) async {
    // BE hiện tại chưa mở route DELETE /products/:productId/variants/:variantId.
    _error = 'Backend hiện tại chưa có API xóa biến thể. Hãy dùng chế độ "replace" để tạo lại danh sách biến thể.';
    notifyListeners();
    return false;
  }

  // ========================================================================
  // 12. TẠO MỘT BIẾN THỂ THỦ CÔNG
  // ========================================================================
  Future<dynamic> createVariant(int productId, Map<String, dynamic> dto) async {
    // BE hiện tại chưa mở route POST /products/:productId/variants.
    _error = 'Backend hiện tại chưa có API tạo biến thể thủ công. Hãy dùng chức năng generate biến thể.';
    notifyListeners();
    return null;
  }

  // ========================================================================
  // 13. CẬP NHẬT TRẠNG THÁI (DRAFT/ACTIVE)
  // ========================================================================
  Future<bool> updateProductStatus({
    required int productId,
    required String status,
  }) async {
    return updateProduct(productId: productId, status: status);
  }

  Future<bool> toggleProductStatus(int productId, {String? currentStatus}) async {
    final product = getProductFromCache(productId);
    final oldStatus = (currentStatus ?? product?.status)?.toUpperCase();

    if (oldStatus == null || oldStatus.isEmpty) {
      _error = 'Không xác định được trạng thái hiện tại của sản phẩm';
      notifyListeners();
      return false;
    }

    final newStatus = oldStatus == 'ACTIVE' ? 'DRAFT' : 'ACTIVE';
    return updateProductStatus(productId: productId, status: newStatus);
  }

  // ========================================================================
  // HELPER: XỬ LÝ LỖI DIO
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
        if (data['message'] is List) return (data['message'] as List).join('\n');
        return data['message'].toString();
      }
      return 'Lỗi server';
    }

    return 'Lỗi kết nối mạng';
  }
}
