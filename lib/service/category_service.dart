import 'package:dio/dio.dart';
import '../utils/app_constants.dart';
import '../models/category_model.dart';
import 'api_client.dart';

class CategoryService {
  final Dio _dio;

  CategoryService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  dynamic _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data')) return data['data'];
    }
    return data;
  }

  Future<List<CategoryModel>> getCategories({
    String? q,
    int? parentId,
    bool? isActive,
  }) async {
    final query = <String, dynamic>{};
    if (q != null && q.trim().isNotEmpty) query['q'] = q.trim();
    if (parentId != null) query['parentId'] = parentId;
    if (isActive != null) query['isActive'] = isActive;

    final res = await _dio.get(CategoryApi.categories, queryParameters: query);
    final data = _unwrap(res.data);

    final list = (data is List)
        ? data
        : (data is Map && data['items'] is List ? data['items'] : <dynamic>[]);

    return list
        .whereType<Map>()
        .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<CategoryModel>> getTree() async {
    final res = await _dio.get(CategoryApi.tree);
    final data = _unwrap(res.data);

    final list = (data is List) ? data : <dynamic>[];
    return list
        .whereType<Map>()
        .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CategoryModel> getDetail(int id) async {
    final res = await _dio.get(CategoryApi.byId(id));
    final data = _unwrap(res.data);

    if (data is Map<String, dynamic>) {
      return CategoryModel.fromJson(data);
    }
    throw Exception('Invalid category detail response');
  }

  // ADMIN
  Future<CategoryModel> create({
    required String name,
    String? slug,
    String? description,
    int? parentId,
    bool? isActive,
    int? sortOrder,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
      if (description != null) 'description': description,
      if (parentId != null) 'parentId': parentId,
      if (isActive != null) 'isActive': isActive,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };

    final res = await _dio.post(CategoryApi.categories, data: body);
    final data = _unwrap(res.data);

    if (data is Map<String, dynamic>) return CategoryModel.fromJson(data);
    throw Exception('Invalid create category response');
  }

  Future<CategoryModel> update(
      int id, {
        String? name,
        String? slug,
        String? description,
        int? parentId,
        bool updateParent = false,
        bool? isActive,
        int? sortOrder,
      }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
      if (description != null) 'description': description,

      // Quan trọng cho màn admin:
      // - Khi chọn danh mục cha: gửi parentId = id cha
      // - Khi chuyển về danh mục gốc: gửi parentId = null
      // Nếu chỉ dùng `if (parentId != null)` thì FE không thể xóa parent cũ.
      if (updateParent) 'parentId': parentId,

      if (isActive != null) 'isActive': isActive,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };

    final res = await _dio.patch(CategoryApi.byId(id), data: body);
    final data = _unwrap(res.data);

    if (data is Map<String, dynamic>) return CategoryModel.fromJson(data);
    throw Exception('Invalid update category response');
  }

  Future<void> remove(int id) async {
    await _dio.delete(CategoryApi.byId(id));
  }
}
