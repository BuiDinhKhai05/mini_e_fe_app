// lib/service/shop_service.dart

import 'package:dio/dio.dart';

import '../models/shop_model.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';

class ShopService {
  final ApiClient _api = ApiClient(); // Singleton

  // ==================== REGISTER ====================
  // BE: POST /shops/register
  // Body theo CreateShopDto: name, email, description, shopAddress,
  // shopLat, shopLng, shopPlaceId, shopPhone.
  Future<ShopModel> register(Map<String, dynamic> data) async {
    final resp = await _api.post(
      ShopsApi.register,
      data: _normalizeShopPayload(data),
    );
    _throwIfError(resp);
    return ShopModel.fromJson(resp.data['data']);
  }

  // ==================== MY SHOP ====================
  // BE: GET /shops/me
  Future<ShopModel> getMyShop() async {
    final resp = await _api.get(ShopsApi.myShop);
    _throwIfError(resp);
    return ShopModel.fromJson(resp.data['data']);
  }

  // ==================== PUBLIC DETAIL ====================
  // BE: GET /shops/:id
  // Lưu ý: BE hiện tại chỉ public shop ACTIVE và không trả relation products.
  Future<ShopModel> getShopById(int id) async {
    final resp = await _api.get(ShopsApi.byId('$id'));
    _throwIfError(resp);
    return ShopModel.fromJson(resp.data['data']);
  }

  // ==================== UPDATE SHOP PROFILE ====================
  // BE: PATCH /shops/:id
  // Owner không được gửi status. Chỉ ADMIN được đổi status.
  Future<ShopModel> update(int shopId, Map<String, dynamic> data) async {
    final resp = await _api.patch(
      ShopsApi.byId('$shopId'),
      data: _normalizeShopPayload(data),
    );
    _throwIfError(resp);
    return ShopModel.fromJson(resp.data['data']);
  }

  // ==================== UPLOAD LOGO ====================
  // BE: PATCH /shops/me/logo, multipart field name: file
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
    return ShopModel.fromJson(resp.data['data']);
  }

  // ==================== UPLOAD COVER ====================
  // BE: PATCH /shops/me/cover, multipart field name: file
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
    return ShopModel.fromJson(resp.data['data']);
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
  // BE: DELETE /shops/:id
  // BE sẽ xóa shop và xóa cứng products thuộc shop.
  Future<void> delete(int shopId) async {
    final resp = await _api.delete(ShopsApi.byId('$shopId'));
    _throwIfError(resp);
  }

  // ==================== CHECK NAME ====================
  // BE: GET /shops/check-name?name=...
  Future<bool> checkName(String name) async {
    final resp = await _api.get(
      ShopsApi.checkName,
      queryParameters: {'name': name},
    );
    _throwIfError(resp);
    return resp.data['data']['exists'] as bool;
  }

  // ==================== LIST SHOPS ====================
  // BE hiện tại: GET /shops chỉ cho ADMIN.
  // User thường có thể gặp 403 nếu dùng màn danh sách shop.
  Future<List<ShopModel>> getShops({
    String? q,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final Map<String, dynamic> qp = {
      'page': page,
      'limit': limit,
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final resp = await _api.get(ShopsApi.shops, queryParameters: qp);
    _throwIfError(resp);

    final List items = resp.data['data']['items'] ?? [];
    return items.map((e) => ShopModel.fromJson(e)).toList();
  }

  // ==================== HELPER ====================
  Map<String, dynamic> _normalizeShopPayload(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);

    // FE cũ dùng phone, BE mới dùng shopPhone.
    if (normalized.containsKey('phone') && !normalized.containsKey('shopPhone')) {
      normalized['shopPhone'] = normalized['phone'];
    }
    normalized.remove('phone');

    // Owner không được tự đổi status theo controller BE.
    // Nếu cần đổi status, chỉ admin mới được gọi payload có status.
    if (normalized['status'] == null) {
      normalized.remove('status');
    }

    normalized.removeWhere((key, value) => value == null);
    return normalized;
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
