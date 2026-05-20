// lib/service/order_service.dart

import '../models/order_model.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient _apiClient = ApiClient();

  // Preview đơn hàng trước khi đặt.
  // BE trả: { success: true, data: { address, orders, summary } }
  Future<OrderPreview> previewOrder({
    required int addressId,
    required List<int> itemIds,
  }) async {
    final response = await _apiClient.post(
      OrderApi.preview,
      data: {
        'addressId': addressId,
        'itemIds': itemIds,
      },
    );

    if (response.data['success'] == true) {
      final summary = response.data['data']?['summary'];
      if (summary is Map<String, dynamic>) {
        return OrderPreview.fromJson(summary);
      }
      if (summary is Map) {
        return OrderPreview.fromJson(Map<String, dynamic>.from(summary));
      }
    }

    throw Exception(response.data['message'] ?? 'Lỗi tính phí ship');
  }

  // Tạo đơn hàng.
  // COD   -> { orders: [...] }
  // VNPAY -> { session: {...}, paymentUrl: "..." }
  Future<Map<String, dynamic>> createOrder({
    required int addressId,
    required List<int> itemIds,
    required String paymentMethod, // COD | VNPAY
    String? note,
  }) async {
    final response = await _apiClient.post(
      OrderApi.create,
      data: {
        'addressId': addressId,
        'itemIds': itemIds,
        'paymentMethod': paymentMethod,
        'note': note,
      },
    );

    if (response.data['success'] == true) {
      return Map<String, dynamic>.from(response.data['data'] ?? {});
    }

    throw Exception(response.data['message'] ?? 'Đặt hàng thất bại');
  }

  // Lấy danh sách đơn hàng của user hiện tại.
  Future<List<OrderModel>> getMyOrders({int page = 1, int limit = 30}) async {
    final response = await _apiClient.get('${OrderApi.mine}?page=$page&limit=$limit');

    if (response.data['success'] == true) {
      final List<dynamic> listData = response.data['data']?['items'] ?? [];
      return listData.map((item) => OrderModel.fromJson(item)).toList();
    }

    throw Exception(response.data['message'] ?? 'Lỗi tải danh sách đơn hàng');
  }

  // Lấy chi tiết đơn hàng, BE trả thêm items.
  Future<OrderModel> getOrderDetail(String orderId) async {
    final response = await _apiClient.get(OrderApi.detail(orderId));

    if (response.data['success'] == true) {
      return OrderModel.fromJson(response.data['data']);
    }

    throw Exception(response.data['message'] ?? 'Không tìm thấy đơn hàng');
  }

  // User hủy đơn.
  // BE: POST /orders/:id/cancel
  Future<OrderModel> cancelOrder(String orderId) async {
    final response = await _apiClient.post('/orders/$orderId/cancel');

    if (response.data['success'] == true) {
      return OrderModel.fromJson(response.data['data']);
    }

    throw Exception(response.data['message'] ?? 'Hủy đơn thất bại');
  }

  // User xác nhận đã nhận hàng.
  // BE: POST /orders/:id/confirm-received
  Future<OrderModel> confirmReceived(String orderId) async {
    final response = await _apiClient.post('/orders/$orderId/confirm-received');

    if (response.data['success'] == true) {
      return OrderModel.fromJson(response.data['data']);
    }

    throw Exception(response.data['message'] ?? 'Xác nhận nhận hàng thất bại');
  }

  // User yêu cầu hoàn/trả hàng.
  // BE: POST /orders/:id/request-return
  Future<OrderModel> requestReturn(String orderId) async {
    final response = await _apiClient.post('/orders/$orderId/request-return');

    if (response.data['success'] == true) {
      return OrderModel.fromJson(response.data['data']);
    }

    throw Exception(response.data['message'] ?? 'Yêu cầu trả hàng thất bại');
  }
}
