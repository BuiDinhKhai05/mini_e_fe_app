// lib/providers/shop_provider.dart
import 'package:flutter/material.dart';

import '../models/shop_model.dart';
import '../service/shop_service.dart';

class ShopProvider with ChangeNotifier {
  final ShopService service;

  ShopModel? _shop;
  List<ShopModel> _shops = [];
  bool _isLoading = false;
  String? _error;

  // Lưu lại bộ lọc hiện tại của màn danh sách shop.
  // Việc lưu state này giúp pull-to-refresh hoặc tải lại vẫn giữ đúng từ khóa đang tìm.
  String _shopSearchKeyword = '';
  String? _shopStatusFilter;
  int _shopPage = 1;
  int _shopLimit = 20;

  ShopProvider({required this.service});

  ShopModel? get shop => _shop;
  List<ShopModel> get shops => _shops;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get shopSearchKeyword => _shopSearchKeyword;
  String? get shopStatusFilter => _shopStatusFilter;

  bool get isSearchingShop =>
      _shopSearchKeyword.trim().isNotEmpty || _shopStatusFilter != null;

  // ==================== MY SHOP ====================
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

  // ==================== REGISTER ====================
  Future<bool> register(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      _shop = await service.register(data);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== UPDATE PROFILE ====================
  Future<bool> update(int shopId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      _shop = await service.update(shopId, data);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== UPLOAD LOGO / COVER ====================
  Future<bool> uploadLogo({
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    _setLoading(true);
    try {
      _shop = await service.uploadLogo(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> uploadCover({
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    _setLoading(true);
    try {
      _shop = await service.uploadCover(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== DELETE ====================
  Future<bool> delete(int shopId) async {
    _setLoading(true);
    try {
      await service.delete(shopId);
      _shop = null;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== CHECK NAME ====================
  Future<bool> checkNameExists(String name) async {
    try {
      return await service.checkName(name);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return true;
    }
  }

  // ==================== LIST / SEARCH SHOPS ====================
  // Dùng chung cho:
  // - tải danh sách shop ban đầu
  // - tìm shop theo tên/từ khóa
  // - lọc shop theo trạng thái
  Future<void> fetchShops({
    String? q,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final keyword = q?.trim() ?? '';

    _shopSearchKeyword = keyword;
    _shopStatusFilter = status;
    _shopPage = page;
    _shopLimit = limit;

    _setLoading(true);
    try {
      _shops = await service.getShops(
        q: keyword.isEmpty ? null : keyword,
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

  // Hàm riêng cho màn tìm kiếm shop để code UI dễ đọc hơn.
  Future<void> searchShops({
    required String keyword,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    await fetchShops(
      q: keyword,
      status: status,
      page: page,
      limit: limit,
    );
  }

  // Tải lại danh sách với đúng keyword/status hiện tại.
  Future<void> refreshShops() async {
    await fetchShops(
      q: _shopSearchKeyword,
      status: _shopStatusFilter,
      page: _shopPage,
      limit: _shopLimit,
    );
  }

  // Xóa từ khóa tìm kiếm nhưng vẫn giữ bộ lọc trạng thái nếu đang chọn.
  Future<void> clearShopKeyword() async {
    await fetchShops(
      q: null,
      status: _shopStatusFilter,
      page: 1,
      limit: _shopLimit,
    );
  }

  // Xóa toàn bộ bộ lọc tìm kiếm shop.
  Future<void> clearShopSearch() async {
    await fetchShops(
      q: null,
      status: null,
      page: 1,
      limit: _shopLimit,
    );
  }

  // ==================== PUBLIC DETAIL ====================
  Future<ShopModel> getShopById(int id) async {
    try {
      return await service.getShopById(id);
    } catch (_) {
      rethrow;
    }
  }

  void clearShops({bool notify = true}) {
    _shops = [];
    _error = null;
    _shopSearchKeyword = '';
    _shopStatusFilter = null;
    if (notify) notifyListeners();
  }

  void clearShopData({bool notify = true}) {
    _shop = null;
    _shops = [];
    _error = null;
    _isLoading = false;
    _shopSearchKeyword = '';
    _shopStatusFilter = null;
    _shopPage = 1;
    _shopLimit = 20;

    if (notify) notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
