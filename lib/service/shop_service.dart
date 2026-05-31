// lib/service/shop_service.dart

import 'package:dio/dio.dart';

import '../models/shop_model.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';

class ShopService {
  final ApiClient _api = ApiClient();

  // ==================== REGISTER ====================
  // BE: POST /shops/register
  // Body theo CreateShopDto:
  // name, email, description, shopAddress, shopLat, shopLng, shopPlaceId, shopPhone.
  Future<ShopModel> register(Map<String, dynamic> data) async {
    final resp = await _api.post(
      ShopsApi.register,
      data: _normalizeShopPayload(data),
    );

    _throwIfError(resp);
    return ShopModel.fromJson(Map<String, dynamic>.from(resp.data['data']));
  }

  // ==================== MY SHOP ====================
  // BE: GET /shops/me
  Future<ShopModel> getMyShop() async {
    final resp = await _api.get(ShopsApi.myShop);

    _throwIfError(resp);
    return ShopModel.fromJson(Map<String, dynamic>.from(resp.data['data']));
  }

  // ==================== PUBLIC DETAIL ====================
  // BE: GET /shops/:id
  // Chỉ xem được shop ACTIVE, shop bị xóa mềm hoặc PENDING/SUSPENDED sẽ 404.
  Future<ShopModel> getShopById(int id) async {
    final resp = await _api.get(ShopsApi.byId('$id'));

    _throwIfError(resp);
    return ShopModel.fromJson(Map<String, dynamic>.from(resp.data['data']));
  }

  // ==================== UPDATE SHOP PROFILE ====================
  // BE: PATCH /shops/:id
  // Owner không được gửi status. Admin mới được đổi status.
  Future<ShopModel> update(int shopId, Map<String, dynamic> data) async {
    final resp = await _api.patch(
      ShopsApi.byId('$shopId'),
      data: _normalizeShopPayload(data),
    );

    _throwIfError(resp);
    return ShopModel.fromJson(Map<String, dynamic>.from(resp.data['data']));
  }

  // ==================== UPLOAD LOGO ====================
  // BE: PATCH /shops/me/logo, form field: file
  Future<ShopModel> uploadLogo({
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final resp = await _api.patch(
      ShopsApi.uploadLogo,
      data: await _buildImageFormData(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      ),
    );

    _throwIfError(resp);
    return ShopModel.fromJson(Map<String, dynamic>.from(resp.data['data']));
  }

  // ==================== UPLOAD COVER ====================
  // BE: PATCH /shops/me/cover, form field: file
  Future<ShopModel> uploadCover({
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final resp = await _api.patch(
      ShopsApi.uploadCover,
      data: await _buildImageFormData(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      ),
    );

    _throwIfError(resp);
    return ShopModel.fromJson(Map<String, dynamic>.from(resp.data['data']));
  }

  Future<FormData> _buildImageFormData({
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    if (fileBytes != null) {
      return FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName ?? 'shop-image.jpg',
        ),
      });
    }

    if (filePath != null && filePath.isNotEmpty) {
      return FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });
    }

    throw Exception('Vui lòng chọn ảnh.');
  }

  // ==================== DELETE ====================
  Future<void> delete(int shopId) async {
    final resp = await _api.delete(ShopsApi.byId('$shopId'));
    _throwIfError(resp);
  }

  // ==================== CHECK NAME ====================
  Future<bool> checkName(String name) async {
    final resp = await _api.get(
      ShopsApi.checkName,
      queryParameters: {'name': name},
    );

    _throwIfError(resp);
    return resp.data['data']['exists'] as bool;
  }

  // ==================== PUBLIC LIST / SEARCH SHOPS ====================
  // BE mới: GET /shops là PUBLIC và chỉ trả shop ACTIVE.
  Future<List<ShopModel>> getShops({
    String? q,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> qp = {
      'page': page,
      'limit': limit,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      // BE public hiện ép status ACTIVE, nhưng vẫn giữ để không vỡ code cũ.
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final resp = await _api.get(ShopsApi.shops, queryParameters: qp);

    _throwIfError(resp);

    final items = _extractShopItems(resp.data);
    return items.map((e) => ShopModel.fromJson(e)).toList();
  }

  Future<List<ShopModel>> searchShops({
    required String keyword,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    return getShops(
      q: keyword,
      status: status,
      page: page,
      limit: limit,
    );
  }

  // ==================== ADMIN LIST SHOPS ====================
  // BE mới: GET /shops/admin/all dành cho ADMIN.
  Future<List<ShopModel>> getAdminShops({
    String? q,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _api.get(
      ShopsApi.adminAll,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    _throwIfError(resp);

    final items = _extractShopItems(resp.data);
    return items.map((e) => ShopModel.fromJson(e)).toList();
  }

  // ==================== SELLER ORDERS / REVENUE ====================
  // BE: GET /shops/me/orders?page=1&limit=1000&range=1|7|30|all
  // BE đang lọc order theo order_items.shop_id, app không cần tự join product nữa.
  Future<ShopOrdersResult> getMyShopOrders({
    int page = 1,
    int limit = 1000,
    ShopOrderRange range = ShopOrderRange.sevenDays,
  }) async {
    final resp = await _api.get(
      ShopsApi.myShopOrders,
      queryParameters: {
        'page': page,
        'limit': limit,
        'range': range.queryValue,
      },
    );

    _throwIfError(resp);

    final data = _extractData(resp.data);
    return ShopOrdersResult.fromJson(data);
  }

  // ==================== HELPERS ====================
  Map<String, dynamic> _normalizeShopPayload(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);

    // App cũ dùng phone, BE dùng shopPhone.
    if (normalized.containsKey('phone') && !normalized.containsKey('shopPhone')) {
      normalized['shopPhone'] = normalized['phone'];
    }
    normalized.remove('phone');

    // Owner không được tự đổi status. Admin mới được phép gửi status.
    if (normalized['status'] == null) {
      normalized.remove('status');
    }

    normalized.removeWhere((key, value) => value == null);
    return normalized;
  }

  dynamic _extractData(dynamic body) {
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }

    return body;
  }

  List<Map<String, dynamic>> _extractShopItems(dynamic body) {
    dynamic current = body;

    if (current is List) {
      return current.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    if (current is! Map) {
      return [];
    }

    final root = Map<String, dynamic>.from(current);
    current = root['data'] ?? root['result'] ?? root['payload'] ?? root;

    if (current is List) {
      return current.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    if (current is! Map) {
      return [];
    }

    final map = Map<String, dynamic>.from(current);

    dynamic items = map['items'] ??
        map['shops'] ??
        map['rows'] ??
        map['results'] ??
        map['records'] ??
        map['list'] ??
        map['data'];

    if (items is Map) {
      final nested = Map<String, dynamic>.from(items);
      items = nested['items'] ??
          nested['shops'] ??
          nested['rows'] ??
          nested['results'] ??
          nested['records'] ??
          nested['list'] ??
          nested['data'];
    }

    if (items is! List) {
      return [];
    }

    return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void _throwIfError(Response resp) {
    final statusCode = resp.statusCode ?? 0;
    final body = resp.data;

    if (statusCode >= 400 || (body is Map && body['success'] == false)) {
      final message = body is Map
          ? (body['message'] ?? body['error'] ?? 'Lỗi không xác định')
          : 'Lỗi không xác định';

      throw Exception(message);
    }
  }
}
