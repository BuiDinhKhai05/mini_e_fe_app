import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../service/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _service;

  CategoryProvider({CategoryService? service})
      : _service = service ?? CategoryService();

  bool loadingTree = false;
  bool loadingList = false;
  String? error;

  List<CategoryModel> tree = [];
  List<CategoryModel> categories = [];

  Future<void> fetchTree() async {
    loadingTree = true;
    error = null;
    notifyListeners();
    try {
      tree = await _service.getTree();
    } catch (e) {
      error = e.toString();
    } finally {
      loadingTree = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories({String? q, int? parentId, bool? isActive}) async {
    loadingList = true;
    error = null;
    notifyListeners();
    try {
      categories = await _service.getCategories(q: q, parentId: parentId, isActive: isActive);
    } catch (e) {
      error = e.toString();
    } finally {
      loadingList = false;
      notifyListeners();
    }
  }

  // ADMIN
  Future<void> create({
    required String name,
    String? slug,
    String? description,
    int? parentId,
    bool? isActive,
    int? sortOrder,
  }) async {
    error = null;
    notifyListeners();
    await _service.create(
      name: name,
      slug: slug,
      description: description,
      parentId: parentId,
      isActive: isActive,
      sortOrder: sortOrder,
    );
    await fetchTree();
  }

  Future<void> update(
      int id, {
        String? name,
        String? slug,
        String? description,
        int? parentId,
        bool updateParent = false,
        bool? isActive,
        int? sortOrder,
      }) async {
    error = null;
    notifyListeners();
    await _service.update(
      id,
      name: name,
      slug: slug,
      description: description,
      parentId: parentId,
      updateParent: updateParent,
      isActive: isActive,
      sortOrder: sortOrder,
    );
    await fetchTree();
  }

  Future<void> remove(int id) async {
    error = null;
    notifyListeners();
    await _service.remove(id);
    await fetchTree();
  }

  // Helper flatten tree để show picker
  List<CategoryModel> flattenTree() {
    final out = <CategoryModel>[];
    void walk(List<CategoryModel> nodes, int depth) {
      for (final n in nodes) {
        out.add(CategoryModel(
          id: n.id,
          name: '${'—' * depth} ${n.name}'.trim(),
          slug: n.slug,
          description: n.description,
          parentId: n.parentId,
          isActive: n.isActive,
          sortOrder: n.sortOrder,
          children: n.children,
        ));
        if (n.children.isNotEmpty) walk(n.children, depth + 1);
      }
    }
    walk(tree, 0);
    return out;
  }
}
