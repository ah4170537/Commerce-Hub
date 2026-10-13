import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/categories_repository.dart';

class CategoriesScreen extends StatefulWidget {
  final CategoriesRepository? repository;

  const CategoriesScreen({super.key, this.repository});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final CategoriesRepository _repository;
  late final Stream<List<String>> _categoriesStream;
  final Set<String> _deletingCategories = {};
  String? _operationError;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestoreCategoriesRepository();
    _categoriesStream = _repository.watchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categories',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Organize the categories used by your products',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: 'Add category',
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        if (_operationError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _errorBanner(_operationError!),
          ),
        Expanded(
          child: StreamBuilder<List<String>>(
            stream: _categoriesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _message(
                  'Could not load categories.\n${snapshot.error}',
                  Icons.error_outline_rounded,
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                );
              }

              final categories = snapshot.data!;
              if (categories.isEmpty) {
                return _message(
                  'No categories yet. Add one to start organizing products.',
                  Icons.category_outlined,
                );
              }

              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: categories.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _categoryCard(
                    category,
                    deleting: _deletingCategories.contains(category),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(String category, {required bool deleting}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryAccentMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.category_outlined,
            color: AppColors.primaryAccentLight,
          ),
        ),
        title: Text(
          category,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          deleting
              ? 'Deleting category and its products...'
              : 'Renaming updates the category on its products',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit $category',
              onPressed: deleting
                  ? null
                  : () => _showCategoryDialog(category: category),
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.primaryAccentLight,
              ),
            ),
            IconButton(
              tooltip: 'Delete $category',
              onPressed: deleting ? null : () => _confirmDeleteCategory(category),
              icon: deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.warning,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCategory(String category) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text('Delete category?'),
        content: Text(
          'Deleting "$category" will permanently delete the category and every product assigned to it. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.backgroundPrimary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete category and products'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() {
      _operationError = null;
      _deletingCategories.add(category);
    });
    try {
      await _repository.deleteCategory(category);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$category" and its products were deleted.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _operationError = 'Could not delete "$category": $error');
    } finally {
      if (mounted) setState(() => _deletingCategories.remove(category));
    }
  }

  Widget _message(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.warning, fontSize: 12),
      ),
    );
  }

  Future<void> _showCategoryDialog({String? category}) async {
    var categoryName = category ?? '';
    String? errorMessage;
    var saving = false;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: Text(category == null ? 'Add category' : 'Edit category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: category ?? '',
                decoration: InputDecoration(
                  labelText: 'Category name',
                  errorText: errorMessage,
                ),
                onChanged: (value) {
                  categoryName = value;
                  if (errorMessage != null) {
                    setDialogState(() => errorMessage = null);
                  }
                },
                autofocus: true,
                enabled: !saving,
                textCapitalization: TextCapitalization.words,
                onFieldSubmitted: (value) {
                  categoryName = value;
                  if (!saving) {
                    setDialogState(() => saving = true);
                    _saveCategory(
                      dialogContext,
                      setDialogState,
                      categoryName,
                      category,
                      (error) => errorMessage = error,
                      () => saving = false,
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () {
                      setDialogState(() => saving = true);
                      _saveCategory(
                        dialogContext,
                        setDialogState,
                        categoryName,
                        category,
                        (error) => errorMessage = error,
                        () => saving = false,
                      );
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _operationError = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            category == null
                ? 'Category added.'
                : 'Category renamed and matching products updated.',
          ),
        ),
      );
    }
  }

  Future<void> _saveCategory(
    BuildContext dialogContext,
    StateSetter setDialogState,
    String value,
    String? oldName,
    void Function(String?) setError,
    VoidCallback resetSaving,
  ) async {
    final newName = value.trim();
    if (newName.isEmpty) {
      setDialogState(() {
        resetSaving();
        setError('Enter a category name.');
      });
      return;
    }

    try {
      if (oldName == null) {
        await _repository.addCategory(newName);
      } else {
        await _repository.renameCategory(oldName: oldName, newName: newName);
      }
      if (dialogContext.mounted) Navigator.pop(dialogContext, newName);
    } catch (error) {
      if (!dialogContext.mounted) return;
      setDialogState(() {
        resetSaving();
        setError(error.toString());
      });
    }
  }
}
