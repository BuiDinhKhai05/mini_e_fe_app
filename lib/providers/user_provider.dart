import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../service/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  UserModel? _me;
  bool _loading = false;
  String? _error;

  List<UserModel> _users = [];
  int _page = 1;
  int _limit = 20;
  int _total = 0;

  List<UserModel> _deletedUsers = [];

  UserModel? get me => _me;
  bool get isLoading => _loading;
  String? get error => _error;

  List<UserModel> get users => _users;
  int get page => _page;
  int get limit => _limit;
  int get total => _total;
  List<UserModel> get deletedUsers => _deletedUsers;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> fetchMe({bool force = false}) async {
    if (!force && _me != null) return;

    _setLoading(true);
    try {
      _me = await _userService.getMe();
      _setError(null);
    } catch (e) {
      // Không xóa _me khi API lỗi để màn thông tin cá nhân không bị trắng/spinner vô hạn.
      // Nếu trước đó đã có user trong state thì vẫn giữ lại để hiển thị.
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void clearAll({bool notify = true}) {
    _me = null;
    _loading = false;
    _error = null;

    _users = [];
    _deletedUsers = [];

    _page = 1;
    _limit = 20;
    _total = 0;

    if (notify) {
      notifyListeners();
    }
  }

  void clearMe() {
    clearAll();
  }

  Future<bool> updateMe(Map<String, dynamic> patch) async {
    _setLoading(true);
    try {
      final updated = await _userService.updateMe(patch);
      _me = updated;
      _setError(null);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteMeSoft() async {
    if (_me?.id == null) return false;

    _setLoading(true);
    try {
      await _userService.deleteMeSoft();
      _setError(null);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createUser(Map<String, dynamic> body) async {
    _setLoading(true);
    try {
      await _userService.createUser(body);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchUsers(UserQuery query) async {
    _setLoading(true);
    try {
      final pageResp = await _userService.listUsers(query);
      _users = pageResp.items;
      _page = pageResp.page;
      _limit = pageResp.limit;
      _total = pageResp.total;
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<UserModel?> fetchUserById(String id) async {
    _setLoading(true);
    try {
      final user = await _userService.getUserById(id);
      _setError(null);
      return user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserById(String id, Map<String, dynamic> patch) async {
    _setLoading(true);
    try {
      final updated = await _userService.updateUserById(id, patch);
      final idx = _users.indexWhere((u) => u.id == id);

      if (idx >= 0) {
        _users[idx] = updated;
        notifyListeners();
      }

      _setError(null);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteUserSoft(String id) async {
    _setLoading(true);
    try {
      await _userService.deleteUserSoft(id);
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
      _setError(null);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> restoreUser(String id) async {
    _setLoading(true);
    try {
      final restored = await _userService.restoreUser(id);
      _deletedUsers.removeWhere((u) => u.id == id);

      final idx = _users.indexWhere((u) => u.id == id);
      if (idx >= 0) {
        _users[idx] = restored;
      }

      notifyListeners();
      _setError(null);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteUserHard(String id) async {
    _setLoading(true);
    try {
      await _userService.deleteUserHard(id);
      _users.removeWhere((u) => u.id == id);
      _deletedUsers.removeWhere((u) => u.id == id);
      notifyListeners();
      _setError(null);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchDeletedUsers() async {
    _setLoading(true);
    try {
      _deletedUsers = await _userService.listDeletedUsers();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      final updated = await _userService.updateMe(updates);
      _me = updated;
      _setError(null);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}