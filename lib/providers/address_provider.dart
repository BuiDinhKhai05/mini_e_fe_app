import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../service/address_service.dart';

class AddressProvider with ChangeNotifier {
  final AddressService _service = AddressService();

  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void>? _runningFetch;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAddresses(String token, {bool force = false}) async {
    if (_runningFetch != null && !force) {
      return _runningFetch!;
    }

    _runningFetch = _fetchAddressesInternal(token);
    return _runningFetch!;
  }

  Future<void> _fetchAddressesInternal(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _addresses = await _service
          .fetchAddresses(token)
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('ADDRESS FETCH ERROR: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');

      // Không xóa dữ liệu cũ nếu trước đó đã có địa chỉ
      if (_addresses.isEmpty) {
        _addresses = [];
      }
    } finally {
      _isLoading = false;
      _runningFetch = null;
      notifyListeners();
    }
  }

  Future<void> addAddress(String token, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createAddress(token, data);
      await fetchAddresses(token, force: true);
    } catch (e) {
      debugPrint('ADDRESS ADD ERROR: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAddress(
      String token,
      int id,
      Map<String, dynamic> data,
      ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateAddress(token, id, data);

      if (data['isDefault'] == true) {
        await _service.setDefault(token, id);
      }

      await fetchAddresses(token, force: true);
    } catch (e) {
      debugPrint('ADDRESS UPDATE ERROR: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String token, int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteAddress(token, id);
      await fetchAddresses(token, force: true);
    } catch (e) {
      debugPrint('ADDRESS DELETE ERROR: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}