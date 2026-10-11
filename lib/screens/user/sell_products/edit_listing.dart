import 'package:flutter/material.dart';

import '../../../services/ecoloop_api.dart';
import '../../../app_theme/user/app_colors.dart';

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
  List<Map<String, dynamic>> _categories = [];
  String? _categoryId;
  String _condition = 'good';

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
    _quantityController = TextEditingController(
      text:
          '${widget.listing['quantity'] ?? widget.listing['availableQuantity'] ?? 1}',
    );
    _descriptionController = TextEditingController(
      text: '${widget.listing['description'] ?? ''}',
    );
    _condition = _normalizeCondition(
      widget.listing['condition']?.toString() ?? 'good',
    );
    _available = !_isUnavailable(
      widget.listing['status']?.toString() ?? 'published',
    );
    _loadCategories();
  }

  String _normalizeCondition(String value) {
    final normalized = value.toLowerCase().replaceAll(' ', '_');
    return _conditions.any((e) => e['value'] == normalized)
        ? normalized
        : 'good';
  }

  bool _isUnavailable(String status) =>
      ['sold', 'archived', 'out_of_stock'].contains(status.toLowerCase());

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
        if (row is Map) list.add(Map<String, dynamic>.from(row));
      }
      if (!mounted) return;
      final currentId = '${widget.listing['categoryId'] ?? ''}';
      setState(() {
        _categories = list;
        if (list.any((c) => '${c['categoryId']}' == currentId)) {
          _categoryId = currentId;
        } else if (list.isNotEmpty) {
          _categoryId = '${list.first['categoryId']}';
        }
      });
    } catch (_) {
      if (mounted) setState(() {});
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
    if (!_formKey.currentState!.validate()) return;
    if (_id <= 0) {
      _message(
        'This listing has no valid product ID, so it cannot be updated.',
      );
      return;
    }
    if (_categoryId == null) {
      _message('No active category is available.');
      return;
    }
    setState(() => _saving = true);
    try {
      await EcoLoopApi.instance.put('/products/$_id', {
        'title': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categoryId': int.parse(_categoryId!),
        'condition': _condition,
        'price': double.parse(_priceController.text.trim()),
        'quantity': int.parse(_quantityController.text.trim()),
        'availableQuantity': int.parse(_quantityController.text.trim()),
        'status': _available ? 'published' : 'out_of_stock',
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
    if (confirm != true || !mounted) return;
    try {
      await EcoLoopApi.instance.delete('/products/$_id');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
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
                    (c) => DropdownMenuItem(
                      value: '${c['categoryId']}',
                      child: Text('${c['name'] ?? 'Category'}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _categoryId = v),
              decoration: const InputDecoration(),
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
                      _label('Quantity'),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          return n == null || n < 1 ? 'Min. 1' : null;
                        },
                        decoration: const InputDecoration(hintText: '1'),
                      ),
                    ],
                  ),
                ),
              ],
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
