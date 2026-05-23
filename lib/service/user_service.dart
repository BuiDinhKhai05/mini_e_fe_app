import 'package:dio/dio.dart';

import '../models/user_model.dart';
import '../utils/app_constants.dart';
import 'api_client.dart';

class UserQuery {
  final int page;
  final int limit;
  final String? search;

  // Đồng bộ với QueryUserDto của BE.
  final String? sortBy; // createdAt | name | lastLoginAt | deletedAt ...
  final String? sortOrder; // ASC | DESC

  // Giữ lại để tránh lỗi compile nếu chỗ khác còn truyền role/isVerified.
  // BE hiện tại chưa filter theo 2 field này nên không gửi lên queryParameters.
  final String? role;
  final bool? isVerified;

  UserQuery({
    this.page = 1,
    this.limit = 20,
    this.search,
    this.sortBy,
    this.sortOrder,
    this.role,
    this.isVerified,
  });

  Map<String, String> toQuery() {
    final map = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search!.trim().isNotEmpty) {
      map['search'] = search!.trim();
    }

    if (sortBy != null && sortBy!.trim().isNotEmpty) {
      map['sortBy'] = sortBy!.trim();
    }

    if (sortOrder != null && sortOrder!.trim().isNotEmpty) {
      map['sortOrder'] = sortOrder!.trim().toUpperCase();
    }

    return map;
  }
}

class Paged<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;

  Paged({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });
}

class UserService {
  final Dio _dio = ApiClient().dio;

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  bool _looksLikeUserMap(Map<String, dynamic> map) {
    return map.containsKey('id') ||
        map.containsKey('name') ||
        map.containsKey('email') ||
        map.containsKey('phone') ||
        map.containsKey('avatarUrl') ||
        map.containsKey('birthday') ||
        map.containsKey('role');
  }

  Map<String, dynamic> _unwrapDataMap(dynamic responseData) {
    final root = _asMap(responseData);

    // Trường hợp response đã là user trực tiếp.
    if (_looksLikeUserMap(root)) return root;

    // Trường hợp chuẩn của BE hiện tại:
    // { success, statusCode, data: { user fields... } }
    final data = _asMap(root['data']);
    if (_looksLikeUserMap(data)) return data;

    // Trường hợp project có interceptor bọc thêm 1 lớp data:
    // { data: { success, statusCode, data: { user fields... } } }
    final nestedData = _asMap(data['data']);
    if (_looksLikeUserMap(nestedData)) return nestedData;

    // Fallback để tránh parse ra UserModel rỗng nếu BE đổi format nhẹ.
    if (data.isNotEmpty) return data;
    return root;
  }

  int _parseInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  Map<String, dynamic> _sanitizeUpdateMePatch(Map<String, dynamic> patch) {
    final allowedKeys = <String>{
      'name',
      'email',
      'phone',
      'avatarUrl',
      'birthday',
      'gender',
    };

    final data = <String, dynamic>{};

    for (final entry in patch.entries) {
      if (allowedKeys.contains(entry.key)) {
        data[entry.key] = entry.value;
      }
    }

    // FE cũ có thể gửi avatar. BE hiện tại chỉ nhận avatarUrl.
    final oldAvatar = patch['avatar'];
    if (!data.containsKey('avatarUrl') && oldAvatar is String && oldAvatar.trim().isNotEmpty) {
      data['avatarUrl'] = oldAvatar.trim();
    }

    return data;
  }

  Map<String, dynamic> _sanitizeUpdateUserPatch(Map<String, dynamic> patch) {
    final allowedKeys = <String>{
      'name',
      'email',
      'phone',
      'password',
      'avatarUrl',
      'birthday',
      'gender',
      'isVerified',
      'role',
    };

    final data = <String, dynamic>{};

    for (final entry in patch.entries) {
      if (allowedKeys.contains(entry.key)) {
        data[entry.key] = entry.value;
      }
    }

    final oldAvatar = patch['avatar'];
    if (!data.containsKey('avatarUrl') && oldAvatar is String && oldAvatar.trim().isNotEmpty) {
      data['avatarUrl'] = oldAvatar.trim();
    }

    return data;
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get(UsersApi.me);
    return UserModel.fromJson(_unwrapDataMap(res.data));
  }

  Future<UserModel> updateMe(Map<String, dynamic> patch) async {
    final data = _sanitizeUpdateMePatch(patch);
    final res = await _dio.patch(UsersApi.me, data: data);
    return UserModel.fromJson(_unwrapDataMap(res.data));
  }

  Future<void> deleteMeSoft() async {
    await _dio.delete(UsersApi.me);
  }

  Future<Paged<UserModel>> listUsers(UserQuery query) async {
    final res = await _dio.get(
      UsersApi.users,
      queryParameters: query.toQuery(),
    );

    // BE hiện tại trả:
    // { success, statusCode, data: { items: [...], meta: {...} } }
    final payload = res.data['data'];
    final payloadMap = _asMap(payload);
    final rawItems = payloadMap['items'] ?? payload;
    final meta = _asMap(payloadMap['meta'] ?? res.data['meta']);

    final items = UserModel.listFrom(rawItems);

    return Paged<UserModel>(
      items: items,
      page: _parseInt(meta['page'], query.page),
      limit: _parseInt(meta['limit'], query.limit),
      total: _parseInt(meta['total'], items.length),
    );
  }

  Future<List<UserModel>> listDeletedUsers() async {
    final res = await _dio.get(UsersApi.deletedAll);

    // BE hiện tại trả data.items, giữ fallback data là list để tương thích code cũ.
    final payload = res.data['data'];
    final payloadMap = _asMap(payload);
    final rawItems = payloadMap['items'] ?? payload;

    return UserModel.listFrom(rawItems);
  }

  Future<UserModel> getUserById(String id) async {
    final res = await _dio.get(UsersApi.byId(id));
    return UserModel.fromJson(_unwrapDataMap(res.data));
  }

  Future<UserModel> updateUserById(String id, Map<String, dynamic> patch) async {
    final data = _sanitizeUpdateUserPatch(patch);
    final res = await _dio.patch(UsersApi.byId(id), data: data);
    return UserModel.fromJson(_unwrapDataMap(res.data));
  }

  Future<void> deleteUserSoft(String id) async {
    await _dio.delete(UsersApi.byId(id));
  }

  Future<UserModel> restoreUser(String id) async {
    // BE: POST /users/:id/restore
    // Response chỉ là { id, restored: true }, nên gọi tiếp GET để lấy user đầy đủ.
    await _dio.post(UsersApi.restore(id));
    return getUserById(id);
  }

  Future<void> deleteUserHard(String id) async {
    await _dio.delete(UsersApi.hardDelete(id));
  }

  Future<UserModel> createUser(Map<String, dynamic> body) async {
    final data = _sanitizeUpdateUserPatch(body);
    final res = await _dio.post(UsersApi.users, data: data);
    return UserModel.fromJson(_unwrapDataMap(res.data));
  }
}
