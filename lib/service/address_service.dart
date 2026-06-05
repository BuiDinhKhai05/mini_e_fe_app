import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/address_model.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';

class AddressService {
  // ================================================================
  // ADDRESS SERVICE
  // ================================================================

  final ApiClient _apiClient = ApiClient();

  // ================================================================
  // Helper: decode response body
  // ================================================================
  dynamic _decodeBody(dynamic body) {
    if (body is String && body.trim().isNotEmpty) {
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }
    return body;
  }

  // ================================================================
  // Helper: lấy message lỗi từ BE
  // ================================================================
  String _extractMessage(dynamic body, String fallback) {
    final decoded = _decodeBody(body);

    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      if (message is List && message.isNotEmpty) {
        return message.join(', ');
      }

      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error;
      }
    }

    return fallback;
  }

  // ================================================================
  // Helper: kiểm tra status thành công
  // ================================================================
  void _ensureSuccess(
      Response response, {
        required List<int> successStatusCodes,
        required String fallbackMessage,
      }) {
    final statusCode = response.statusCode;

    if (statusCode != null && successStatusCodes.contains(statusCode)) {
      return;
    }

    final message = _extractMessage(response.data, fallbackMessage);
    throw Exception('$fallbackMessage: ${statusCode ?? 'unknown'} - $message');
  }

  // ================================================================
  // 1. Lấy danh sách địa chỉ
  // ================================================================
  Future<List<AddressModel>> fetchAddresses(String _token) async {
    final response = await _apiClient.get(AddressApi.list);

    _ensureSuccess(
      response,
      successStatusCodes: const [200],
      fallbackMessage: 'Không thể tải danh sách địa chỉ',
    );

    final body = _decodeBody(response.data);

    if (body is Map<String, dynamic>) {
      final success = body['success'];
      final data = body['data'];

      if (success == true && data is List) {
        return data.map((e) => AddressModel.fromJson(e)).toList();
      }

      // Dự phòng nếu BE trả { data: [...] } nhưng không có success.
      if (data is List) {
        return data.map((e) => AddressModel.fromJson(e)).toList();
      }
    }

    // Dự phòng nếu BE trả thẳng list địa chỉ.
    if (body is List) {
      return body.map((e) => AddressModel.fromJson(e)).toList();
    }

    throw Exception('Không thể đọc dữ liệu danh sách địa chỉ');
  }

  // ================================================================
  // 2. Thêm mới địa chỉ
  // ================================================================
  Future<void> createAddress(String _token, Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      AddressApi.list,
      data: data,
    );

    _ensureSuccess(
      response,
      successStatusCodes: const [200, 201],
      fallbackMessage: 'Lỗi khi thêm địa chỉ',
    );
  }

  // ================================================================
  // 3. Cập nhật địa chỉ
 // ================================================================
  Future<void> updateAddress(
      String _token,
      int id,
      Map<String, dynamic> data,
      ) async {
    final response = await _apiClient.patch(
      AddressApi.byId(id),
      data: data,
    );

    _ensureSuccess(
      response,
      successStatusCodes: const [200],
      fallbackMessage: 'Lỗi khi cập nhật địa chỉ',
    );
  }

  // ================================================================
  // 4. Xóa địa chỉ
  // ================================================================
  Future<void> deleteAddress(String _token, int id) async {
    final response = await _apiClient.delete(AddressApi.byId(id));

    _ensureSuccess(
      response,
      successStatusCodes: const [200, 204],
      fallbackMessage: 'Lỗi khi xóa địa chỉ',
    );
  }

  // ================================================================
  // 5. Thiết lập địa chỉ mặc định
  // ================================================================
  Future<void> setDefault(String _token, int id) async {
    final response = await _apiClient.patch(AddressApi.setDefault(id));

    _ensureSuccess(
      response,
      successStatusCodes: const [200],
      fallbackMessage: 'Lỗi khi đặt mặc định',
    );
  }
}
