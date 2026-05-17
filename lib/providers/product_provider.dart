// lib/providers/product_provider.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http_parser/http_parser.dart'; // cho MediaType
import '../models/product_model.dart'; // Đảm bảo file này đã có class VariantItem
import '../utils/app_constants.dart';

import 'auth_provider.dart';
import 'shop_provider.dart';

/// ---------------------------------------------------------------------------
/// PRODUCT PROVIDER – QUẢN LÝ SẢN PHẨM & GỌI API
/// ---------------------------------------------------------------------------
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

  // ====================== CONSTRUCTOR ======================
  ProductProvider();

  // ========================================================================
  // 0. HÀM MỚI: XÓA CACHE DỮ LIỆU (Dùng khi logout hoặc switch account)
  // ========================================================================
  void clearProductsCache({bool notify = true}) {
    _products = [];
    _error = null;
    _isLoading = false;

    if (notify) {
      notifyListeners();
    }
  }

  // ========================================================================
  // 1. LẤY TOKEN TỪ AUTH PROVIDER
  // ========================================================================
  Future<String> _getToken() async {
    final context = AuthProvider.navigatorKey.currentContext;
    if (context == null) throw Exception('App chưa khởi tạo');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập');
    }

    return token;
  }

  // ========================================================================
  // 2. LẤY DANH SÁCH SẢN PHẨM (PAGINATION)
  // ========================================================================

  // PUBLIC: Chỉ lấy sản phẩm đang bán (ACTIVE)
  Future<void> fetchPublicProducts({bool showLoading = true}) async {
    await _fetchProductsWithFilter(status: 'ACTIVE', showLoading: showLoading);
  }

  // SELLER: Lấy tất cả sản phẩm (cả DRAFT)
  Future<void> fetchAllProductsForSeller({bool showLoading = true}) async {
    await _fetchProductsWithFilter(status: null, showLoading: showLoading);
  }

  // HÀM RIÊNG – CORE FETCH
  Future<void> _fetchProductsWithFilter({
    required String? status,
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
      final token = await _getToken();
      final url = status != null
          ? '${ProductApi.products}?status=$status'
          : ProductApi.products;

      final response = await _dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final dynamic data = response.data['data'];
      List<dynamic> rawList = [];

      if (data is Map) {
        rawList = data['items'] ?? [];
      } else if (data is List) {
        rawList = data;
      }

      final parsedProducts = rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => ProductModel.fromJson(item))
          .toList();

      _products = parsedProducts;
    } on DioException catch (e) {
      _error = _handleDioError(e);
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
    int? stock,
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
        if (stock != null && stock > 0) 'stock': stock,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
      });

      // Xử lý ảnh upload - key đúng: images[0], images[1]...
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
          } else if (item is File) {
            multipartFile = await MultipartFile.fromFile(
              item.path,
              filename: item.path.split('/').last,
            );
          } else {
            continue; // Bỏ qua nếu loại không hỗ trợ
          }

          // KEY QUAN TRỌNG: images[0], images[1]... → backend nhận mảng
          formData.files.add(MapEntry('images', multipartFile));
        }
      }

      final response = await _dio.post(
        ProductApi.products,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final newProduct = ProductModel.fromJson(response.data['data']);
      _products.insert(0, newProduct); // Thêm vào đầu danh sách

      _isLoading = false;
      notifyListeners();
      return newProduct;
    } on DioException catch (e) {
      _error = _handleDioError(e);
      print('Create product error: ${e.response?.data}');
    } catch (e) {
      _error = 'Lỗi tạo sản phẩm: $e';
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  // ========================================================================
  // 4. CẬP NHẬT SẢN PHẨM – ĐÃ SỬA ĐÚNG KEY ẢNH + HAI TRƯỜNG HỢP
  // ========================================================================
  Future<bool> updateProduct({
    required int productId,
    String? title,
    double? price,
    int? stock,
    String? description,
    String? slug,
    String? status,
    List<dynamic>? images, // File hoặc Uint8List
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final hasNewImages = images != null && images.isNotEmpty;

      // Trường hợp 1: Không có ảnh mới → gửi JSON
      if (!hasNewImages) {
        final Map<String, dynamic> jsonBody = {};
        if (title != null) jsonBody['title'] = title.trim();
        if (price != null) jsonBody['price'] = price;
        if (stock != null) jsonBody['stock'] = stock;
        if (description != null) jsonBody['description'] = description.trim();
        if (slug != null) jsonBody['slug'] = slug.trim();
        if (status != null) jsonBody['status'] = status;

        if (jsonBody.isEmpty) {
          _isLoading = false;
          notifyListeners();
          return true; // Không có gì để update
        }

        final response = await _dio.patch(
          ProductApi.byId(productId),
          data: jsonBody,
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );

        _updateLocalProduct(productId, response.data['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Trường hợp 2: Có ảnh mới → gửi FormData
      final formData = FormData();

      if (title != null) formData.fields.add(MapEntry('title', title.trim()));
      if (price != null) formData.fields.add(MapEntry('price', price.toString()));
      if (stock != null) formData.fields.add(MapEntry('stock', stock.toString()));
      if (description != null) formData.fields.add(MapEntry('description', description.trim()));
      if (slug != null) formData.fields.add(MapEntry('slug', slug.trim()));
      if (status != null) formData.fields.add(MapEntry('status', status));

      // Upload ảnh mới với key đúng
      for (int i = 0; i < images!.length; i++) {
        final item = images[i];
        MultipartFile multipartFile;

        if (kIsWeb && item is Uint8List) {
          multipartFile = MultipartFile.fromBytes(
            item,
            filename: 'image_$i.jpg',
            contentType: MediaType('image', 'jpeg'),
          );
        } else if (item is File) {
          multipartFile = await MultipartFile.fromFile(
            item.path,
            filename: item.path.split('/').last,
          );
        } else {
          continue;
        }

        formData.files.add(MapEntry('images', multipartFile));
      }

      final response = await _dio.patch(
        ProductApi.byId(productId),
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      _updateLocalProduct(productId, response.data['data']);
      _isLoading = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = _handleDioError(e);
      print('Update product error: ${e.response?.data}');
    } catch (e) {
      _error = 'Lỗi cập nhật sản phẩm: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void _updateLocalProduct(int id, Map<String, dynamic> jsonData) {
    final updatedProduct = ProductModel.fromJson(jsonData);
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) {
      _products[index] = updatedProduct;
      notifyListeners();
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
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
  // 6. LẤY DANH SÁCH BIẾN THỂ (CẬP NHẬT TRẢ VỀ VariantItem)
  // ========================================================================
  Future<List<VariantItem>> getVariants(int productId) async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        ProductApi.variants(productId),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final List list = response.data['data'];
      return list.map((e) => VariantItem.fromJson(e)).toList();
    } on DioException catch (e) {
      _error = _handleDioError(e);
      print("Get Variants Error: $_error");
      notifyListeners();
      return [];
    } catch (e) {
      print("Get Variants Error: $e");
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
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
      final token = await _getToken();
      final response = await _dio.get(
        ProductApi.byId(id),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return ProductModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      _error = _handleDioError(e);
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
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final role = authProvider.user?.role?.toUpperCase();

      if (role == 'SELLER') {
        await shopProvider.loadMyShop();
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
    try {
      // 1. Gửi request xóa lên server
      // Lưu ý: Đảm bảo đường dẫn API khớp với backend: DELETE /products/:id/variants/:variantId
      await _dio.delete('/products/$productId/variants/$variantId');

      // 2. Cập nhật lại danh sách biến thể ở local (nếu cần)
      // Thông thường UI sẽ gọi lại hàm getVariants để làm mới, nên ở đây chỉ cần return true
      return true;
    } catch (e) {
      print('Lỗi xóa biến thể: $e');
      return false;
    }
  }

  // ========================================================================
  // 12. TẠO MỘT BIẾN THỂ THỦ CÔNG
  // ========================================================================
  Future<dynamic> createVariant(int productId, Map<String, dynamic> dto) async {
    try {
      final token = await _getToken();
      final response = await _dio.post(
        ProductApi.variants(productId),
        data: dto,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      notifyListeners();
      return response.data['data'];
    } on DioException catch (e) {
      _error = _handleDioError(e);
      notifyListeners();
      return null;
    }
  }

  // ========================================================================
  // 13. CẬP NHẬT TRẠNG THÁI (DRAFT/ACTIVE)
  // ========================================================================
  Future<bool> updateProductStatus({
    required int productId,
    required String status,
  }) async {
    // Tận dụng hàm updateProduct chung để tránh lặp code
    return await updateProduct(productId: productId, status: status);
  }

  Future<bool> toggleProductStatus(int productId) async {
    final product = _products.firstWhere(
          (p) => p.id == productId,
      orElse: () => ProductModel(id: productId, title: '', price: 0, imageUrl: '', shopId: 0),
    );
    final newStatus = product.status == 'ACTIVE' ? 'DRAFT' : 'ACTIVE';
    return await updateProductStatus(productId: productId, status: newStatus);
  }

  // ========================================================================
  // HELPER: XỬ LÝ LỖI DIO
  // ========================================================================
  String _handleDioError(DioException e) {
    print('Dio Error: ${e.type} | Status: ${e.response?.statusCode}');
    if (e.response?.statusCode == 401) {
      final context = AuthProvider.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        Provider.of<AuthProvider>(context, listen: false).logout();
      }
      return 'Phiên đăng nhập hết hạn';
    }
    if (e.response != null) {
      return e.response?.data['message']?.toString() ?? 'Lỗi server';
    }
    return 'Lỗi kết nối mạng';
  }
}