// lib/providers/order_provider.dart

import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../service/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  bool _isLoading = false;
  String? _errorMessage;
  OrderPreview? _orderPreview;
  List<OrderModel> _myOrders = [];
  final Set<String> _actionLoadingOrderIds = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OrderPreview? get orderPreview => _orderPreview;
  List<OrderModel> get myOrders => _myOrders;

  bool isOrderActionLoading(String orderId) => _actionLoadingOrderIds.contains(orderId);

  String _readableError(Object error) {
    final raw = error.toString();
    return raw.replaceFirst('Exception: ', '').trim();
  }

  void _replaceOrder(OrderModel updatedOrder) {
    final index = _myOrders.indexWhere((order) => order.id == updatedOrder.id);
    if (index >= 0) {
      _myOrders[index] = updatedOrder;
    } else {
      _myOrders.insert(0, updatedOrder);
    }
  }

  Future<void> previewOrder(int addressId, List<int> itemIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orderPreview = await _orderService.previewOrder(
        addressId: addressId,
        itemIds: itemIds,
      );
    } catch (error) {
      _errorMessage = _readableError(error);
      _orderPreview = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> placeOrder({
    required int addressId,
    required List<int> itemIds,
    required String paymentMethod,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _orderService.createOrder(
        addressId: addressId,
        itemIds: itemIds,
        paymentMethod: paymentMethod,
        note: note,
      );

      // COD tạo đơn ngay, nên refresh lại danh sách.
      // VNPAY chỉ tạo payment_session, order sẽ xuất hiện sau khi callback thành công.
      if (paymentMethod == 'COD') {
        await fetchMyOrders();
      }

      return result;
    } catch (error) {
      _errorMessage = _readableError(error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyOrders({bool refresh = false}) async {
    if (refresh) {
      _myOrders = [];
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _myOrders = await _orderService.getMyOrders();
    } catch (error) {
      _errorMessage = _readableError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> fetchOrderDetail(String orderId) async {
    try {
      final detail = await _orderService.getOrderDetail(orderId);
      _replaceOrder(detail);
      notifyListeners();
      return detail;
    } catch (error) {
      _errorMessage = _readableError(error);
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    _actionLoadingOrderIds.add(orderId);
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedOrder = await _orderService.cancelOrder(orderId);
      _replaceOrder(updatedOrder);
      return true;
    } catch (error) {
      _errorMessage = _readableError(error);
      return false;
    } finally {
      _actionLoadingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> confirmReceived(String orderId) async {
    _actionLoadingOrderIds.add(orderId);
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedOrder = await _orderService.confirmReceived(orderId);
      _replaceOrder(updatedOrder);
      return true;
    } catch (error) {
      _errorMessage = _readableError(error);
      return false;
    } finally {
      _actionLoadingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> requestReturn(String orderId) async {
    _actionLoadingOrderIds.add(orderId);
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedOrder = await _orderService.requestReturn(orderId);
      _replaceOrder(updatedOrder);
      return true;
    } catch (error) {
      _errorMessage = _readableError(error);
      return false;
    } finally {
      _actionLoadingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<bool> checkOrderStatus(String orderId) async {
    try {
      final order = await _orderService.getOrderDetail(orderId);
      return order.paymentStatus == 'PAID' ||
          order.status == 'PAID' ||
          order.status == 'COMPLETED';
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkPaidBySessionCode(String sessionCode) async {
    try {
      final list = await _orderService.getMyOrders(page: 1, limit: 50);

      for (final order in list) {
        if (order.sessionCode == sessionCode) {
          return order.paymentStatus == 'PAID' ||
              order.status == 'PAID' ||
              order.status == 'COMPLETED';
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
