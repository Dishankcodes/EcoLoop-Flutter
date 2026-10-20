import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';

class EditListing extends StatefulWidget {
  final Map<String, dynamic> listing;

  const EditListing({super.key, required this.listing});

  @override
  State<EditListing> createState() => _EditListingState();
}

class _EditListingState extends State<EditListing> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _descriptionController;
  bool _saving = false;
  bool _available = true;
  String _deliveryMethod = 'EcoLoop-Managed Delivery';
  List<Map<String, dynamic>> _categories = [];
  String? _categoryId;
  String? _originalCategoryId;
  String _originalCategoryName = 'Current category';
  String _condition = 'good';
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _existingImageUrls = [];
  final List<XFile> _newImages = [];
  int _originalTotalQuantity = 0;
  int _originalAvailableQuantity = 0;

  final List<Map<String, String>> _conditions = const [
    {'label': 'New', 'value': 'new'},
    {'label': 'Like New', 'value': 'like_new'},
    {'label': 'Good', 'value': 'good'},
    {'label': 'Used', 'value': 'used'},
    {'label': 'Needs Repair', 'value': 'needs_repair'},
  ];

  int get _id =>
      int.tryParse(
        '${widget.listing['productId'] ?? widget.listing['id'] ?? ''}',
      ) ??
      0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: '${widget.listing['title'] ?? ''}',
    );
    _priceController = TextEditingController(
      text: '${widget.listing['price'] ?? ''}'
          .replaceAll('₹', '')
          .replaceAll(',', ''),
    );
    _originalTotalQuantity = _intValue(widget.listing['quantity']);
    _originalAvailableQuantity = _intValue(
      widget.listing['availableQuantity'],
      fallback: _originalTotalQuantity,
    );
    if (_originalTotalQuantity < _originalAvailableQuantity) {
      _originalTotalQuantity = _originalAvailableQuantity;
    }
    // This field edits remaining stock, not lifetime/listed quantity.
    _quantityController = TextEditingController(
      text: '$_originalAvailableQuantity',
    );
    _existingImageUrls.addAll(_readImageUrls(widget.listing['imageUrls']));
    _descriptionController = TextEditingController(
      text: '${widget.listing['description'] ?? ''}',
    );
    _originalCategoryId = _readOriginalCategoryId();
    _originalCategoryName = _readOriginalCategoryName();
    _categoryId = _originalCategoryId;
    _condition = _normalizeCondition(
      widget.listing['condition']?.toString() ?? 'good',
    );
    _deliveryMethod = _normalizeDeliveryMethod(
      widget.listing['deliveryMethod']?.toString() ?? '',
    );
    _available = !_isUnavailable(
      widget.listing['status']?.toString() ?? 'published',
    );
    _loadCategories();
  }

  int _intValue(dynamic value, {int fallback = 0}) {
    if (value == null || '$value'.trim().isEmpty) return fallback;
    return int.tryParse('$value') ?? fallback;
  }

  List<String> _readImageUrls(dynamic value) {
    dynamic parsed = value;
    if (parsed is String) {
      try {
        parsed = jsonDecode(parsed);
      } catch (_) {
        return parsed.trim().isEmpty ? [] : [parsed.trim()];
      }
    }
    if (parsed is List) {
      return parsed
          .map((item) => item.toString().trim())
          .where((url) => url.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<void> _pickImages() async {
    try {
      final remaining = 5 - _existingImageUrls.length - _newImages.length;
      if (remaining <= 0) {
        _message('You can keep up to 5 product images.');
        return;
      }
      final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (!mounted || picked.isEmpty) return;
      setState(() {
        _newImages.addAll(picked.take(remaining));
      });
      if (picked.length > remaining) {
        _message('Only $remaining more image(s) were added (maximum 5).');
      }
    } catch (e) {
      _message(
        'Could not select images: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  String _normalizeCondition(String value) {
    final normalized = value.toLowerCase().replaceAll(' ', '_');
    return _conditions.any((e) => e['value'] == normalized)
        ? normalized
        : 'good';
  }

  String _normalizeDeliveryMethod(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('_', ' ');
    return normalized == 'free delivery' || normalized == 'free'
        ? 'Free Delivery'
        : 'EcoLoop-Managed Delivery';
  }

  bool _isUnavailable(String status) =>
      ['sold', 'archived', 'out_of_stock'].contains(status.toLowerCase());

  String? _readOriginalCategoryId() {
    final value = widget.listing['categoryId'] ?? widget.listing['category_id'];
    if (value == null || '$value'.trim().isEmpty) return null;
    return '$value'.trim();
  }

  String _readOriginalCategoryName() {
    final value =
        widget.listing['categoryName'] ??
        widget.listing['category_name'] ??
        widget.listing['category'];
    final name = value?.toString().trim() ?? '';
    return name.isEmpty ? 'Current category' : name;
  }

  Future<void> _loadCategories() async {
    try {
      final response = await EcoLoopApi.instance.get('/categories');
      final rows = response is List
          ? response
          : (response is Map
                ? (response['data'] ?? response['categories'] ?? [])
                : []);
      final list = <Map<String, dynamic>>[];
      for (final row in rows) {
        if (row is Map) {
          final category = Map<String, dynamic>.from(row);
          // Some API responses use `id` instead of `categoryId`.
          category['categoryId'] ??= category['id'];
          if (category['categoryId'] != null) list.add(category);
        }
      }
      if (!mounted) return;
      final currentId = _originalCategoryId;
      setState(() {
        // Never silently replace the listing's category with the first active
        // category. If the original category is missing from the endpoint,
        // keep it as a clearly labelled option until the seller chooses another.
        if (currentId != null &&
            currentId.isNotEmpty &&
            !list.any((c) => '${c['categoryId']}' == currentId)) {
          list.insert(0, {
            'categoryId': currentId,
            'name':
                '$_originalCategoryName (current; not in active categories)',
            '_preservedInactiveCategory': true,
          });
        }
        _categories = list;
        _categoryId =
            currentId != null &&
                list.any((c) => '${c['categoryId']}' == currentId)
            ? currentId
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        // If categories cannot be loaded, keep the existing category selectable
        // rather than leaving a dropdown value that has no matching item.
        if (_originalCategoryId != null && _originalCategoryId!.isNotEmpty) {
          _categories = [
            {
              'categoryId': _originalCategoryId,
              'name':
                  '$_originalCategoryName (current; categories unavailable)',
              '_preservedInactiveCategory': true,
            },
          ];
          _categoryId = _originalCategoryId;
        } else {
          _categories = [];
          _categoryId = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_id <= 0) {
      _message(
        'This listing has no valid product ID, so it cannot be updated.',
      );
      return;
    }
    if (_categoryId == null || _categoryId!.trim().isEmpty) {
      _message('Please select a category before saving this listing.');
      return;
    }
    setState(() => _saving = true);
    try {
      final newAvailableQuantity = int.parse(_quantityController.text.trim());
      final soldQuantity = (_originalTotalQuantity - _originalAvailableQuantity)
          .clamp(0, 1 << 30)
          .toInt();
      final newTotalQuantity = soldQuantity + newAvailableQuantity;
      // Read selected files concurrently to reduce time spent waiting on each image.
      final encodedImages = await Future.wait(
        _newImages.map((image) async {
          final bytes = await image.readAsBytes();
          final pathParts = image.name.split('.');
          final extension = pathParts.length > 1
              ? pathParts.last.toLowerCase()
              : 'jpg';
          final mimeType = extension == 'png'
              ? 'image/png'
              : (extension == 'webp' ? 'image/webp' : 'image/jpeg');
          return <String, dynamic>{
            'base64': base64Encode(bytes),
            'fileName': image.name,
            'mimeType': mimeType,
          };
        }),
      );

      await EcoLoopApi.instance.put('/products/$_id', {
        'title': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categoryId': int.parse(_categoryId!),
        'condition': _condition,
        'deliveryMethod': _deliveryMethod,
        'price': double.parse(_priceController.text.trim()),
        // Keep sold quantity intact; editing price/details cannot restore sold stock.
        'quantity': newTotalQuantity,
        'availableQuantity': newAvailableQuantity,
        'imageUrls': _existingImageUrls,
        'imageBase64': encodedImages,
        'status': _available && newAvailableQuantity > 0
            ? 'published'
            : 'out_of_stock',
      });
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing updated successfully.')),
      );
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteListing() async {
    if (_saving) return;
    if (_id <= 0) {
      _message('Invalid product ID.');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive listing?'),
        content: Text(
          '“${widget.listing['title'] ?? 'This item'}” will be removed from active listings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted || _saving) return;
    setState(() => _saving = true);
    try {
      await EcoLoopApi.instance.delete('/products/$_id');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Edit Listing',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _saving ? null : _deleteListing,
            icon: const Icon(Icons.archive_outlined, color: AppColors.error),
            tooltip: 'Archive listing',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            const Text(
              'Update your listing',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Changes are saved to your EcoLoop account.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            _label('Product Name'),
            TextFormField(
              controller: _nameController,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
              decoration: const InputDecoration(hintText: 'Product name'),
            ),
            const SizedBox(height: 16),
            _label('Category'),
            DropdownButtonFormField<String>(
              value: _categoryId,
              isExpanded: true,
              hint: const Text('Select category'),
              items: _categories
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: '${c['categoryId']}',
                      child: Text(
                        '${c['name'] ?? c['categoryName'] ?? 'Category'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              decoration: const InputDecoration(),
            ),
            if (_originalCategoryId != null &&
                !_categories.any(
                  (c) =>
                      '${c['categoryId']}' == _originalCategoryId &&
                      c['_preservedInactiveCategory'] != true,
                ))
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'The current category is not in the active category list. It is preserved unless you explicitly choose another category.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _label('Condition'),
            DropdownButtonFormField<String>(
              value: _condition,
              items: _conditions
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['value'],
                      child: Text(c['label']!),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _condition = v);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Price (₹'),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          return n == null || n < 0
                              ? 'Enter valid price'
                              : null;
                        },
                        decoration: const InputDecoration(hintText: '0.00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Available Stock'),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return n == null || n < 0 ? 'Enter 0 or more' : null;
                        },
                        decoration: const InputDecoration(hintText: '1'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _label('Delivery Option'),
            const SizedBox(height: 8),
            _deliveryOption(
              title: 'Free Delivery',
              subtitle:
                  'The buyer sees free delivery. You pay the applicable courier charge; consider including it in your product price.',
              value: 'Free Delivery',
              icon: Icons.card_giftcard_outlined,
            ),
            const SizedBox(height: 10),
            _deliveryOption(
              title: 'EcoLoop-Managed Delivery',
              subtitle:
                  'The buyer pays the applicable delivery charge at checkout.',
              value: 'EcoLoop-Managed Delivery',
              icon: Icons.local_shipping_outlined,
            ),
            const SizedBox(height: 16),
            _label('Description'),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 7,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter description' : null,
              decoration: const InputDecoration(
                hintText: 'Describe the item...',
              ),
            ),
            const SizedBox(height: 18),
            _label('Product Images'),
            const Text(
              'Remove images with ×, or add replacement images. Up to 5 images total.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._existingImageUrls.asMap().entries.map((entry) {
                  return _imageTile(
                    image: Image.network(
                      entry.value,
                      width: 94,
                      height: 94,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 94,
                        height: 94,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                    onRemove: () => _removeExistingImage(entry.key),
                  );
                }),
                ..._newImages.asMap().entries.map((entry) {
                  return _imageTile(
                    image: FutureBuilder<Uint8List>(
                      future: entry.value.readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(
                            width: 94,
                            height: 94,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return Image.memory(
                          snapshot.data!,
                          width: 94,
                          height: 94,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    onRemove: () => _removeNewImage(entry.key),
                  );
                }),
                if (_existingImageUrls.length + _newImages.length < 5)
                  InkWell(
                    onTap: _saving ? null : _pickImages,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 28),
                          SizedBox(height: 5),
                          Text('Add image', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              value: _available,
              onChanged: (v) => setState(() => _available = v),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: const Text('Available in Marketplace'),
              subtitle: const Text('Turn off to mark the listing unavailable.'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageTile({required Widget image, required VoidCallback onRemove}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 94, height: 94, child: image),
        ),
        Positioned(
          top: -7,
          right: -7,
          child: Material(
            color: AppColors.error,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _deliveryOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final selected = _deliveryMethod == value;
    return InkWell(
      onTap: _saving ? null : () => setState(() => _deliveryMethod = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.light : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.accent.withOpacity(0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Icon(icon, color: AppColors.primary, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
  );
}
