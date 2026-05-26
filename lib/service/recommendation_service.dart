import 'package:dio/dio.dart';

import '../models/product_model.dart';
import 'api_client.dart';

class RecommendationService {
  final Dio _dio;

  /// Dùng Dio của ApiClient để tự có baseUrl + token interceptor giống các service khác.
  /// Nếu project của bạn đặt getter khác `dio`, hãy đổi lại đúng tên getter trong api_client.dart.
  RecommendationService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<void> trackEvent({
    required int productId,
    required String eventType,
    Map<String, dynamic>? metadata,
  }) async {
    await _dio.post(
      '/recommendations/events',
      data: {
        'productId': productId,
        'eventType': eventType,
        'metadata': metadata ?? <String, dynamic>{},
      },
    );
  }

  Future<List<ProductModel>> getRecommendedProducts({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/recommendations/products',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    return _parseProducts(response.data);
  }

  Future<void> addFavorite(int productId) async {
    await _dio.post('/recommendations/favorites/$productId');
  }

  Future<void> removeFavorite(int productId) async {
    await _dio.delete('/recommendations/favorites/$productId');
  }

  Future<List<ProductModel>> getFavorites({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/recommendations/favorites',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    return _parseProducts(response.data);
  }

  List<ProductModel> _parseProducts(dynamic raw) {
    final items = _extractItems(raw);

    return items
        .whereType<Map>()
        .map((item) => ProductModel.fromJson(
      Map<String, dynamic>.from(item),
    ))
        .toList();
  }

  List<dynamic> _extractItems(dynamic raw) {
    if (raw is List) return raw;

    if (raw is Map) {
      // Trường hợp BE trả trực tiếp:
      // { page, limit, items: [...] }
      final directItems = raw['items'];
      if (directItems is List) return directItems;

      // Trường hợp app có interceptor/global response:
      // { success: true, data: { page, limit, items: [...] } }
      final data = raw['data'];
      if (data is List) return data;

      if (data is Map) {
        final nestedItems = data['items'];
        if (nestedItems is List) return nestedItems;

        final nestedData = data['data'];
        if (nestedData is List) return nestedData;
      }
    }

    return <dynamic>[];
  }
}
