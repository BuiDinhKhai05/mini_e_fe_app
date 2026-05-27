// lib/screens/admins/admin_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_theme.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _keyword = '';
  bool _deleting = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchTree();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  String _friendlyError(Object error) {
    final message = error.toString();

    if (message.contains('403')) {
      return 'Bạn không có quyền thực hiện thao tác này. Chỉ admin mới được tạo, sửa, xóa danh mục.';
    }

    if (message.contains('401')) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }

    if (message.contains('409')) {
      return 'Danh mục hoặc slug đã tồn tại.';
    }

    if (message.contains('400')) {
      return 'Dữ liệu danh mục không hợp lệ. Vui lòng kiểm tra lại.';
    }

    return message.replaceFirst('Exception: ', '');
  }

  List<_CategoryOption> _flattenOptions(
      List<CategoryModel> nodes, {
        Set<int> excludedIds = const {},
        int depth = 0,
      }) {
    final result = <_CategoryOption>[];

    for (final node in nodes) {
      if (!excludedIds.contains(node.id)) {
        result.add(
          _CategoryOption(
            category: node,
            label: '${'— ' * depth}${node.name}',
          ),
        );
      }

      result.addAll(
        _flattenOptions(
          node.children,
          excludedIds: excludedIds,
          depth: depth + 1,
        ),
      );
    }

    return result;
  }

  Set<int> _collectSelfAndDescendantIds(CategoryModel category) {
    final ids = <int>{category.id};

    void walk(CategoryModel node) {
      for (final child in node.children) {
        ids.add(child.id);
        walk(child);
      }
    }

    walk(category);
    return ids;
  }

  List<CategoryModel> _flattenCategories(List<CategoryModel> nodes) {
    final result = <CategoryModel>[];

    void walk(List<CategoryModel> list) {
      for (final item in list) {
        result.add(item);
        if (item.children.isNotEmpty) {
          walk(item.children);
        }
      }
    }

    walk(nodes);
    return result;
  }

  List<CategoryModel> _getFilteredCategories(List<CategoryModel> tree) {
    final keyword = _normalize(_keyword);
    if (keyword.isEmpty) return tree;

    return _flattenCategories(tree).where((category) {
      final name = _normalize(category.name);
      final slug = _normalize(category.slug);
      final description = _normalize(category.description ?? '');

      return name.contains(keyword) ||
          slug.contains(keyword) ||
          description.contains(keyword);
    }).toList();
  }

  Future<void> _refresh() async {
    await context.read<CategoryProvider>().fetchTree();
  }

  Future<void> _showCategoryForm({CategoryModel? category}) async {
    final provider = context.read<CategoryProvider>();
    final isEdit = category != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: category?.name ?? '');
    final slugController = TextEditingController(text: category?.slug ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    final sortOrderController = TextEditingController(
      text: (category?.sortOrder ?? 0).toString(),
    );

    bool isActive = category?.isActive ?? true;
    bool formSubmitting = false;
    int? parentId = category?.parentId;

    final excludedIds = category == null
        ? <int>{}
        : _collectSelfAndDescendantIds(category);

    final parentOptions = _flattenOptions(
      provider.tree,
      excludedIds: excludedIds,
    );

    if (parentId != null &&
        !parentOptions.any((option) => option.category.id == parentId)) {
      parentId = null;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.extraLarge),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    AppSpacing.lg,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.lightPink,
                              borderRadius: BorderRadius.circular(
                                AppRadius.large,
                              ),
                            ),
                            child: Icon(
                              isEdit
                                  ? Icons.edit_outlined
                                  : Icons.add_circle_outline,
                              color: AppColors.primaryPink,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              isEdit ? 'Sửa danh mục' : 'Tạo danh mục',
                              style: AppTextStyles.titleMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: formSubmitting
                                ? null
                                : () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      TextFormField(
                        controller: nameController,
                        enabled: !formSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Tên danh mục',
                          hintText: 'Ví dụ: Gấu bông',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên danh mục';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: slugController,
                        enabled: !formSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Slug',
                          hintText: 'Có thể bỏ trống nếu BE tự tạo',
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      DropdownButtonFormField<int?>(
                        value: parentId,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục cha',
                          prefixIcon: Icon(Icons.account_tree_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Danh mục gốc'),
                          ),
                          ...parentOptions.map(
                                (option) => DropdownMenuItem<int?>(
                              value: option.category.id,
                              child: Text(
                                option.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: formSubmitting
                            ? null
                            : (value) {
                          setModalState(() {
                            parentId = value;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: sortOrderController,
                        enabled: !formSubmitting,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Thứ tự sắp xếp',
                          hintText: 'Ví dụ: 0, 1, 2...',
                          prefixIcon: Icon(Icons.sort),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }

                          if (int.tryParse(value.trim()) == null) {
                            return 'Thứ tự phải là số';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: descriptionController,
                        enabled: !formSubmitting,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                          hintText: 'Mô tả ngắn cho danh mục',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      SwitchListTile(
                        value: isActive,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primaryPink,
                        title: const Text('Đang hoạt động'),
                        subtitle: Text(
                          isActive
                              ? 'Danh mục được hiển thị cho người dùng'
                              : 'Danh mục đang bị ẩn',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                        onChanged: formSubmitting
                            ? null
                            : (value) {
                          setModalState(() {
                            isActive = value;
                          });
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: formSubmitting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Icon(isEdit ? Icons.save : Icons.add),
                          label: Text(
                            formSubmitting
                                ? 'Đang lưu...'
                                : isEdit
                                ? 'Lưu thay đổi'
                                : 'Tạo danh mục',
                          ),
                          onPressed: formSubmitting
                              ? null
                              : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            setModalState(() => formSubmitting = true);
                            var success = false;

                            try {
                              final name = nameController.text.trim();
                              final slug = _emptyToNull(
                                slugController.text,
                              );
                              final description = _emptyToNull(
                                descriptionController.text,
                              );
                              final sortOrder = int.tryParse(
                                sortOrderController.text.trim(),
                              ) ??
                                  0;

                              if (isEdit) {
                                await context
                                    .read<CategoryProvider>()
                                    .update(
                                  category.id,
                                  name: name,
                                  slug: slug,
                                  description: description,
                                  parentId: parentId,
                                  updateParent: true,
                                  isActive: isActive,
                                  sortOrder: sortOrder,
                                );
                              } else {
                                await context
                                    .read<CategoryProvider>()
                                    .create(
                                  name: name,
                                  slug: slug,
                                  description: description,
                                  parentId: parentId,
                                  isActive: isActive,
                                  sortOrder: sortOrder,
                                );
                              }

                              success = true;

                              if (!mounted) return;
                              Navigator.pop(sheetContext);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEdit
                                        ? 'Đã cập nhật danh mục'
                                        : 'Đã tạo danh mục',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_friendlyError(e)),
                                ),
                              );
                            } finally {
                              if (!success) {
                                setModalState(
                                      () => formSubmitting = false,
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    slugController.dispose();
    descriptionController.dispose();
    sortOrderController.dispose();
  }

  Future<void> _confirmDelete(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa danh mục'),
          content: Text(
            category.children.isNotEmpty
                ? 'Danh mục "${category.name}" đang có danh mục con. Nếu BE không cho xóa danh mục có con hoặc có sản phẩm, thao tác sẽ bị từ chối.\n\nBạn vẫn muốn xóa?'
                : 'Bạn có chắc muốn xóa danh mục "${category.name}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _deleting = true);

    try {
      await context.read<CategoryProvider>().remove(category.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa danh mục')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  Widget _statusChip(CategoryModel category) {
    final active = category.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withOpacity(0.12)
            : AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.circle),
      ),
      child: Text(
        active ? 'Đang hiện' : 'Đang ẩn',
        style: AppTextStyles.caption.copyWith(
          color: active ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _categoryCard(
      CategoryModel category, {
        int depth = 0,
        bool searchMode = false,
      }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: AppSpacing.sm,
        left: searchMode ? 0 : depth * 16.0,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: depth == 0 ? AppShadows.softShadow : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightPink,
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Icon(
                depth == 0
                    ? Icons.category_outlined
                    : Icons.subdirectory_arrow_right,
                color: AppColors.primaryPink,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'ID: ${category.id}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                      if (category.slug.isNotEmpty)
                        Text(
                          'Slug: ${category.slug}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                      Text(
                        'Sort: ${category.sortOrder}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                      _statusChip(category),
                    ],
                  ),
                  if ((category.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      category.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: 'Sửa',
              onPressed: _deleting
                  ? null
                  : () => _showCategoryForm(category: category),
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.info,
            ),
            IconButton(
              tooltip: 'Xóa',
              onPressed: _deleting ? null : () => _confirmDelete(category),
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTree(CategoryModel category, {int depth = 0}) {
    return Column(
      children: [
        _categoryCard(category, depth: depth),
        for (final child in category.children)
          _categoryTree(child, depth: depth + 1),
      ],
    );
  }

  Widget _headerCard(int total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        border: Border.all(color: AppColors.borderPink),
        boxShadow: AppShadows.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.lightPink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.category_outlined,
              size: 32,
              color: AppColors.primaryPink,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý danh mục',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tạo, sửa, xóa và sắp xếp danh mục sản phẩm. Tổng hiện có: $total danh mục.',
                  style: AppTextStyles.bodyGrey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Tìm theo tên, slug hoặc mô tả...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _keyword.isEmpty
            ? null
            : IconButton(
          onPressed: () {
            _searchController.clear();
            setState(() => _keyword = '');
          },
          icon: const Icon(Icons.close),
        ),
      ),
      onChanged: (value) {
        setState(() => _keyword = value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        final allCategories = _flattenCategories(provider.tree);
        final filtered = _getFilteredCategories(provider.tree);
        final searchMode = _keyword.trim().isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('QUẢN LÝ DANH MỤC'),
            backgroundColor: AppColors.primaryPink,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Tải lại',
                onPressed: provider.loadingTree || _deleting ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Thêm danh mục',
                onPressed: _deleting ? null : () => _showCategoryForm(),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primaryPink,
            foregroundColor: Colors.white,
            onPressed: _deleting ? null : () => _showCategoryForm(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm danh mục'),
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    96,
                  ),
                  children: [
                    _headerCard(allCategories.length),
                    const SizedBox(height: AppSpacing.lg),
                    _searchBox(),
                    const SizedBox(height: AppSpacing.lg),

                    if (provider.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppRadius.large),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          provider.error!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (provider.loadingTree && provider.tree.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppRadius.large),
                          border: Border.all(color: AppColors.borderGrey),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 48,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              searchMode
                                  ? 'Không tìm thấy danh mục phù hợp'
                                  : 'Chưa có danh mục nào',
                              style: AppTextStyles.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              searchMode
                                  ? 'Thử tìm bằng từ khóa khác.'
                                  : 'Bấm nút thêm để tạo danh mục đầu tiên.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyGrey,
                            ),
                          ],
                        ),
                      )
                    else if (searchMode)
                        ...filtered.map(
                              (category) => _categoryCard(
                            category,
                            searchMode: true,
                          ),
                        )
                      else
                        ...provider.tree.map(
                              (category) => _categoryTree(category),
                        ),
                  ],
                ),
              ),

              if (_deleting)
                Container(
                  color: Colors.black.withOpacity(0.08),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryOption {
  final CategoryModel category;
  final String label;

  const _CategoryOption({
    required this.category,
    required this.label,
  });
}
