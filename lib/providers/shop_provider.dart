import 'package:flutter/material.dart';

import '../models/shop_model.dart';
import '../service/shop_service.dart';

class ShopProvider with ChangeNotifier {
  final ShopService service;

  ShopModel? _shop;
  List<ShopModel> _shops = [];
  bool _isLoading = false;
  String? _error;

  ShopProvider({required this.service});

  ShopModel? get shop => _shop;
  List<ShopModel> get shops => _shops;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyShop() async {
    _setLoading(true);
    try {
      final shop = await service.getMyShop();
      _shop = shop;
      _error = null;
    } catch (e) {
      final message = e.toString();

      if (message.contains('404') || message.contains('Bạn chưa có shop')) {
        _shop = null;
        _error = null;
      } else {
        _error = message;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      _shop = await service.register(data);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> update(int shopId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      _shop = await service.update(shopId, data);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> delete(int shopId) async {
    _setLoading(true);
    try {
      await service.delete(shopId);
      _shop = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkNameExists(String name) async {
    try {
      return await service.checkName(name);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return true;
    }
  }

  Future<void> fetchShops({
    String? q,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    _setLoading(true);
    try {
      _shops = await service.getShops(
        q: q,
        status: status,
        page: page,
        limit: limit,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<ShopModel> getShopById(int id) async {
    try {
      return await service.getShopById(id);
    } catch (e) {
      rethrow;
    }
  }

  void clearShops({bool notify = true}) {
    _shops = [];
    _error = null;
    if (notify) {
      notifyListeners();
    }
  }

  void clearShopData({bool notify = true}) {
    _shop = null;
    _shops = [];
    _error = null;
    _isLoading = false;

    if (notify) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}