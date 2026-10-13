import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../services/categories_repository.dart';
import '../services/product_editor_repository.dart';
import '../services/products_data_source.dart';

class ProductEditorScreen extends StatefulWidget {
  final StoreProduct product;
  final ProductEditorRepository? repository;
  final CategoriesRepository? categoriesRepository;

  const ProductEditorScreen({
    super.key,
    required this.product,
    this.repository,
    this.categoriesRepository,
  });

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final ProductEditorRepository _repository;
  late final CategoriesRepository _categoriesRepository;
  late final Stream<List<String>> _categoriesStream;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _subCategoryController;
  late final List<_VariantFields> _variants;
  late final List<_PartFields> _parts;
  late final List<_ExistingImage> _existingImages;
  final List<_NewImage> _newImages = [];
  String? _selectedCategory;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ImgBBProductEditorRepository();
    _categoriesRepository =
        widget.categoriesRepository ?? FirestoreCategoriesRepository();
    _categoriesStream = _categoriesRepository.watchCategories();
    final product = widget.product;
    _nameController = TextEditingController(text: product.name);
    _descriptionController = TextEditingController(
      text: product.description ?? '',
    );
    _priceController = TextEditingController(
      text: product.price?.toString() ?? '',
    );
    _selectedCategory = product.category;
    _subCategoryController = TextEditingController(text: product.subCategory);
    _variants = product.variants
        .map(
          (variant) => _VariantFields(
            name: variant.name,
            price: variant.price?.toString() ?? '',
          ),
        )
        .toList();
    _parts = product.parts
        .map(
          (part) => _PartFields(
            name: part.name,
            specs: part.specs ?? '',
            price: part.price?.toString() ?? '',
          ),
        )
        .toList();
    _existingImages = [
      for (var index = 0; index < product.imageUrls.length; index++)
        _ExistingImage(
          url: product.imageUrls[index],
        ),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _subCategoryController.dispose();
    for (final variant in _variants) {
      variant.dispose();
    }
    for (final part in _parts) {
      part.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        title: const Text('Edit product'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _sectionTitle('Product information'),
            _readOnlyField('Product ID', widget.product.id),
            _textField(_nameController, 'Name', required: true),
            _textField(_descriptionController, 'Description', maxLines: 3),
            _textField(
              _priceController,
              'Base price (PKR)',
              required: true,
              numeric: true,
            ),
            _buildCategoryField(),
            _textField(_subCategoryController, 'Subcategory'),
            const SizedBox(height: 22),
            _sectionTitle('Product images'),
            const Text(
              'Images are stored in Firebase Storage. Removing an image removes it from this product.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _buildImageGrid(),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving ? null : _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add images from device'),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Variants'),
            ..._variants.asMap().entries.map(
              (entry) => _buildVariantEditor(entry.key, entry.value),
            ),
            _addRowButton(
              label: 'Add variant',
              onPressed: () => setState(() => _variants.add(_VariantFields())),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Parts'),
            ..._parts.asMap().entries.map(
              (entry) => _buildPartEditor(entry.key, entry.value),
            ),
            _addRowButton(
              label: 'Add part',
              onPressed: () => setState(() => _parts.add(_PartFields())),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save product changes'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: _inputDecoration(label),
        child: Text(
          value,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return StreamBuilder<List<String>>(
      stream: _categoriesStream,
      builder: (context, snapshot) {
        final categoryNames = <String>{...?snapshot.data};
        if ((snapshot.hasError || !snapshot.hasData) &&
            widget.product.category.isNotEmpty) {
          categoryNames.add(widget.product.category);
        }
        final categories = categoryNames.toList()..sort();
        final selectedCategory = categories.contains(_selectedCategory)
            ? _selectedCategory
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Could not load categories: ${snapshot.error}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (!snapshot.hasData && !snapshot.hasError)
                const LinearProgressIndicator(minHeight: 2),
              DropdownButtonFormField<String>(
                key: ValueKey(categories.join('\u0000')),
                initialValue: selectedCategory,
                isExpanded: true,
                decoration: _inputDecoration('Category'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                dropdownColor: AppColors.cardSurface,
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (category) => setState(() {
                        _selectedCategory = category;
                      }),
                validator: (category) => category == null
                    ? 'Select a category.'
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool numeric = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: _inputDecoration(label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return '$label is required.';
          if (numeric && text.isNotEmpty && _parsePrice(text) == null) {
            return 'Enter a valid non-negative price.';
          }
          return null;
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.cardSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.cardBorder.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.cardBorder.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final imageCount = _existingImages.length + _newImages.length;
    if (imageCount == 0) {
      return Container(
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No images added',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._existingImages.asMap().entries.map(
          (entry) => _imageTile(
            image: Image.network(
              entry.value.url,
              width: 92,
              height: 92,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _imageFallback(),
            ),
            onRemove: () => setState(() {
              _existingImages.removeAt(entry.key);
            }),
          ),
        ),
        ..._newImages.asMap().entries.map(
          (entry) => _imageTile(
            image: Image.memory(
              entry.value.bytes,
              width: 92,
              height: 92,
              fit: BoxFit.cover,
            ),
            onRemove: () => setState(() {
              _newImages.removeAt(entry.key);
            }),
          ),
        ),
      ],
    );
  }

  Widget _imageTile({required Widget image, required VoidCallback onRemove}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 92, height: 92, child: image),
        ),
        Positioned(
          right: 3,
          top: 3,
          child: Material(
            color: Colors.black.withValues(alpha: 0.7),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.cardSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildVariantEditor(int index, _VariantFields variant) {
    return _editorRow(
      title: 'Variant ${index + 1}',
      onRemove: () => setState(() {
        _variants.removeAt(index).dispose();
      }),
      children: [
        _textField(variant.name, 'Variant name', required: true),
        _textField(
          variant.price,
          'Variant price (PKR)',
          required: true,
          numeric: true,
        ),
      ],
    );
  }

  Widget _buildPartEditor(int index, _PartFields part) {
    return _editorRow(
      title: 'Part ${index + 1}',
      onRemove: () => setState(() {
        _parts.removeAt(index).dispose();
      }),
      children: [
        _textField(part.name, 'Part name', required: true),
        _textField(part.specs, 'Specifications'),
        _textField(
          part.price,
          'Part price (PKR)',
          required: true,
          numeric: true,
        ),
      ],
    );
  }

  Widget _editorRow({
    required String title,
    required VoidCallback onRemove,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove $title',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _addRowButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _saving ? null : onPressed,
        icon: const Icon(Icons.add_rounded),
        label: Text(label),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final files = await _picker.pickMultiImage();
      if (!mounted || files.isEmpty) return;
      final images = <_NewImage>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          throw FormatException('Selected image "${file.name}" is empty.');
        }
        images.add(_NewImage(file: file, bytes: bytes));
      }
      if (!mounted) return;
      setState(() => _newImages.addAll(images));
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not read selected images: $error');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final category = _selectedCategory;
    if (category == null) return;
    final price = _parsePrice(_priceController.text);
    if (price == null) return;

    setState(() => _saving = true);
    try {
      final fields = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'category': category,
        'subCategory': _subCategoryController.text.trim(),
        'variants': _variants
            .map(
              (variant) => {
                'name': variant.name.text.trim(),
                'price': _parsePrice(variant.price.text)!,
              },
            )
            .toList(),
        'parts': _parts
            .map(
              (part) => {
                'partName': part.name.text.trim(),
                'specs': part.specs.text.trim(),
                'price': _parsePrice(part.price.text)!,
              },
            )
            .toList(),
      };

      await _repository.updateProduct(
        productId: widget.product.id,
        fields: fields,
        retainedImageUrls: _existingImages.map((image) => image.url).toList(),
        addedImages: _newImages.map((image) => image.file).toList(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ProductImageUploadException catch (error) {
      if (!mounted) return;
      await _showErrorDialog(error.toString());
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not save product changes: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  num? _parsePrice(String value) {
    final price = num.tryParse(value.trim().replaceAll(',', ''));
    if (price == null || price < 0) return null;
    return price;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image upload failed'),
        content: SingleChildScrollView(child: SelectableText(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ExistingImage {
  final String url;

  const _ExistingImage({required this.url});
}

class _NewImage {
  final XFile file;
  final Uint8List bytes;

  const _NewImage({required this.file, required this.bytes});
}

class _VariantFields {
  final TextEditingController name;
  final TextEditingController price;

  _VariantFields({String name = '', String price = ''})
    : name = TextEditingController(text: name),
      price = TextEditingController(text: price);

  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _PartFields {
  final TextEditingController name;
  final TextEditingController specs;
  final TextEditingController price;

  _PartFields({String name = '', String specs = '', String price = ''})
    : name = TextEditingController(text: name),
      specs = TextEditingController(text: specs),
      price = TextEditingController(text: price);

  void dispose() {
    name.dispose();
    specs.dispose();
    price.dispose();
  }
}
