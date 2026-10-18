import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/eco_image_picker.dart';
import '../../../services/ecoloop_api.dart';

class EditProduct extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProduct({super.key, required this.product});

  @override
  State<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _availableQuantityController;

  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedListingType;
  String _deliveryMethod = 'EcoLoop-Managed Delivery';

  static const List<String> _deliveryOptions = [
    'Free Delivery',
    'EcoLoop-Managed Delivery',
  ];

  bool _isSaving = false;
  bool _isLoadingCategories = true;
  bool _imagesChanged = false;
  List<Map<String, dynamic>> _categories = [];
  List<String> _existingImageUrls = [];
  List<SelectedEcoImage> _newImages = [];
  String? _categoryLoadError;

  List<String> get _categoryNames => _categories
      .map((category) => category['name']?.toString() ?? '')
      .where((name) => name.isNotEmpty)
      .toList();

  final List<String> _conditions = [
    'New',
    'Like New',
    'Good',
    'Used',
    'Needs Repair',
  ];

  final List<String> _listingTypes = ['Sell'];

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _titleController = TextEditingController(
      text: product['title']?.toString() ?? '',
    );

    _descriptionController = TextEditingController(
      text: product['description']?.toString() ?? '',
    );

    _priceController = TextEditingController(
      text: _formatInitialNumber(product['price']),
    );

    _quantityController = TextEditingController(
      text: product['quantity']?.toString() ?? '',
    );

    _availableQuantityController = TextEditingController(
      text: product['availableQuantity']?.toString() ?? '',
    );

    _selectedCategory = null;
    _selectedCondition = _getInitialValue(
      product['condition']?.toString().replaceAll('_', ' '),
      _conditions,
    );
    _selectedListingType = 'Sell';
    _deliveryMethod = _normalizeDeliveryMethod(product['deliveryMethod']);
    _existingImageUrls = _readImageUrls(product);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final result = await EcoLoopApi.instance.get('/categories');
      final rows = result is List ? result : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _categories = rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        _isLoadingCategories = false;
        _categoryLoadError = null;
        final id = int.tryParse(widget.product['categoryId']?.toString() ?? '');
        final match = _categories.where(
          (item) => int.tryParse(item['categoryId'].toString()) == id,
        );
        if (match.isNotEmpty) {
          _selectedCategory = match.first['name']?.toString();
        } else if (!_categoryNames.contains(_selectedCategory)) {
          _selectedCategory = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
        _categoryLoadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<String> _readImageUrls(Map<String, dynamic> product) {
    final dynamic value = product['imageUrls'];
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) return [value.trim()];
    final image = product['image']?.toString() ?? '';
    return image.isEmpty ? <String>[] : <String>[image];
  }

  int? _selectedCategoryId() {
    for (final category in _categories) {
      if (category['name']?.toString() == _selectedCategory) {
        return int.tryParse(category['categoryId'].toString());
      }
    }
    return null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _availableQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.pop(context);
                },
          icon: Icon(
            Icons.arrow_back_rounded,
            color: _isSaving
                ? ArtistColors.textMuted
                : ArtistColors.textPrimary,
          ),
        ),
        title: Text(
          'Edit Product',
          style: ArtistTextStyles.title.copyWith(fontSize: 19),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 35),
          children: [
            _buildProductHeader(),

            const SizedBox(height: 22),

            _buildSectionTitle(
              icon: Icons.photo_library_outlined,
              title: 'Product Photos',
              subtitle: 'Update the photos shown to buyers',
            ),

            const SizedBox(height: 12),

            _buildPhotoSection(),

            const SizedBox(height: 28),

            _buildSectionTitle(
              icon: Icons.info_outline_rounded,
              title: 'Product Details',
              subtitle: 'Update your product information',
            ),

            const SizedBox(height: 14),

            _buildTextField(
              controller: _titleController,
              label: 'Product Title',
              hint: 'Enter product title',
              icon: Icons.title_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a product title';
                }

                if (value.trim().length < 3) {
                  return 'Product title must be at least 3 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe your product',
              icon: Icons.description_outlined,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a product description';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Category',
              value: _selectedCategory,
              hint: _isLoadingCategories
                  ? 'Loading categories…'
                  : 'Select category',
              icon: Icons.category_outlined,
              items: _categoryNames,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Condition',
              value: _selectedCondition,
              hint: 'Select condition',
              icon: Icons.auto_awesome_outlined,
              items: _conditions,
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select product condition';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Listing Type',
              value: _selectedListingType,
              hint: 'Select listing type',
              icon: Icons.sell_outlined,
              items: _listingTypes,
              onChanged: (value) {
                setState(() {
                  _selectedListingType = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select listing type';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Delivery Option',
              value: _deliveryMethod,
              hint: 'Select delivery option',
              icon: Icons.local_shipping_outlined,
              items: _deliveryOptions,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _deliveryMethod = value);
              },
              validator: (value) => value == null || value.isEmpty
                  ? 'Please select a delivery option'
                  : null,
            ),

            const SizedBox(height: 10),
            _buildDeliveryHint(),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'Price',
                    hint: '0',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }

                      final price = double.tryParse(value.trim());

                      if (price == null || price < 0) {
                        return 'Invalid price';
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildTextField(
                    controller: _quantityController,
                    label: 'Total Quantity',
                    hint: '0',
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }

                      final quantity = int.tryParse(value.trim());

                      if (quantity == null || quantity < 1) {
                        return 'Invalid quantity';
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _availableQuantityController,
              label: 'Available Quantity',
              hint: 'Enter available quantity',
              icon: Icons.production_quantity_limits_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter available quantity';
                }

                final available = int.tryParse(value.trim());

                final quantity = int.tryParse(_quantityController.text.trim());

                if (available == null || available < 0) {
                  return 'Invalid quantity';
                }

                if (quantity != null && available > quantity) {
                  return 'Cannot exceed total quantity';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            _buildQuantityInfo(),

            const SizedBox(height: 28),

            _buildProductInfoCard(),

            const SizedBox(height: 28),

            _buildSaveButton(),

            const SizedBox(height: 12),

            _buildCancelButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    final productId = widget.product['productId']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: ArtistColors.primary,
              size: 27,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit your listing',
                  style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 15),
                ),

                const SizedBox(height: 3),

                Text(
                  productId.isEmpty
                      ? 'Update product information'
                      : 'Product ID: $productId',
                  style: ArtistTextStyles.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: ArtistColors.light,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: ArtistColors.primary, size: 20),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ArtistTextStyles.title.copyWith(fontSize: 17)),

              const SizedBox(height: 2),

              Text(subtitle, style: ArtistTextStyles.small),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    final images = <Widget>[];
    for (var index = 0; index < _existingImageUrls.length; index++) {
      final url = _existingImageUrls[index];
      images.add(
        _buildImageTile(
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: ArtistColors.textMuted,
              ),
            ),
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          ),
          onRemove: () => setState(() {
            _existingImageUrls.removeAt(index);
            _imagesChanged = true;
          }),
          isMain: index == 0 && _newImages.isEmpty,
        ),
      );
    }
    for (var index = 0; index < _newImages.length; index++) {
      final image = _newImages[index];
      images.add(
        _buildImageTile(
          child: Image.memory(image.bytes, fit: BoxFit.cover),
          onRemove: () => setState(() {
            _newImages.removeAt(index);
            _imagesChanged = true;
          }),
          isMain: _existingImageUrls.isEmpty && index == 0,
        ),
      );
    }
    if (_existingImageUrls.length + _newImages.length < 4) {
      images.add(
        GestureDetector(
          onTap: _pickMoreImages,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: ArtistColors.border),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: ArtistColors.primary,
                  size: 25,
                ),
                SizedBox(height: 6),
                Text('Add photo'),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Product Images', style: ArtistTextStyles.label),
              ),
              Text(
                '${_existingImageUrls.length + _newImages.length}/4 photos',
                style: ArtistTextStyles.small,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: images),
          const SizedBox(height: 10),
          Text(
            'Photos are stored in Google Drive when you save changes.',
            style: ArtistTextStyles.small,
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile({
    required Widget child,
    required VoidCallback onRemove,
    required bool isMain,
  }) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(13), child: child),
          if (isMain)
            Positioned(
              left: 5,
              bottom: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: ArtistColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Main',
                  style: ArtistTextStyles.small.copyWith(color: Colors.white),
                ),
              ),
            ),
          Positioned(
            right: 3,
            top: 3,
            child: IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 15),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMoreImages() async {
    final remaining = 4 - _existingImageUrls.length;
    if (remaining <= 0) {
      _showErrorMessage('Remove an existing photo before adding another.');
      return;
    }
    try {
      final picked = await EcoImagePicker.pick(
        current: _newImages,
        maxImages: remaining,
      );
      if (!mounted) return;
      setState(() {
        _newImages = picked;
        _imagesChanged = true;
      });
    } catch (error) {
      if (mounted)
        _showErrorMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ArtistTextStyles.label),

        const SizedBox(height: 7),

        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: ArtistTextStyles.bodyMedium,
          cursorColor: ArtistColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ArtistTextStyles.hint,
            prefixIcon: Icon(icon, color: ArtistColors.primary),
            filled: true,
            fillColor: ArtistColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ArtistColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ArtistColors.primary,
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ArtistColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ArtistColors.error,
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ArtistTextStyles.label),

        const SizedBox(height: 7),

        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ArtistColors.textSecondary,
          ),
          style: ArtistTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ArtistTextStyles.hint,
            prefixIcon: Icon(icon, color: ArtistColors.primary),
            filled: true,
            fillColor: ArtistColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ArtistColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ArtistColors.primary,
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ArtistColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: ArtistColors.error,
                width: 1.3,
              ),
            ),
          ),
          dropdownColor: ArtistColors.surface,
          borderRadius: BorderRadius.circular(14),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: ArtistTextStyles.bodyMedium),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildQuantityInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArtistColors.light.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: ArtistColors.primary,
            size: 18,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              'Available quantity cannot be greater than the total quantity.',
              style: ArtistTextStyles.small.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryHint() {
    final isFreeDelivery = _deliveryMethod == 'Free Delivery';
    final message = isFreeDelivery
        ? 'Free for the buyer. You are responsible for the applicable courier cost; consider including it in your product price.'
        : 'The buyer pays the applicable delivery charge at checkout. EcoLoop-managed shipping availability and charges depend on the route and service.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isFreeDelivery
                ? Icons.card_giftcard_outlined
                : Icons.local_shipping_outlined,
            color: ArtistColors.primary,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: ArtistTextStyles.small.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoCard() {
    final String status = widget.product['status']?.toString() ?? 'active';

    final String createdAt = _formatListingDate(widget.product['createdAt']);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listing Information',
            style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 15),
          ),

          const SizedBox(height: 13),

          _buildInfoRow(
            icon: Icons.local_shipping_outlined,
            label: 'Delivery Option',
            value: _deliveryMethod,
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.toggle_on_outlined,
            label: 'Current Status',
            value: _formatStatus(status),
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Created',
            value: createdAt,
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.visibility_outlined,
            label: 'Views',
            value: '${widget.product['views'] ?? 0}',
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.favorite_border_rounded,
            label: 'Wishlist',
            value: '${widget.product['wishlistCount'] ?? 0}',
          ),

          const SizedBox(height: 10),

          _buildInfoRow(
            icon: Icons.shopping_bag_outlined,
            label: 'Sales',
            value: '${widget.product['salesCount'] ?? 0}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    // Keep each field in a single vertical column: label first, value below.
    // This avoids cramped, side-by-side values on narrow phone screens.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: ArtistColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: ArtistTextStyles.small)),
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                value,
                textAlign: TextAlign.left,
                softWrap: true,
                style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatListingDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null' || raw == '-') {
      return 'Date unavailable';
    }

    DateTime? listedAt;
    final sheetIstPattern = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})$',
    );
    final sheetMatch = sheetIstPattern.firstMatch(raw);

    if (sheetMatch != null) {
      // Apps Script yyyy-MM-dd HH:mm:ss timestamps are already IST.
      listedAt = DateTime(
        int.parse(sheetMatch.group(1)!),
        int.parse(sheetMatch.group(2)!),
        int.parse(sheetMatch.group(3)!),
        int.parse(sheetMatch.group(4)!),
        int.parse(sheetMatch.group(5)!),
        int.parse(sheetMatch.group(6)!),
      );
    } else {
      final hasTimezone = RegExp(
        r'(Z|[+-]\d{2}:?\d{2})$',
        caseSensitive: false,
      ).hasMatch(raw);
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return 'Date unavailable';

      if (hasTimezone) {
        // Convert explicit UTC/offset timestamps to IST independent of device zone.
        listedAt = parsed.toUtc().add(const Duration(hours: 5, minutes: 30));
      } else {
        // A timestamp without a timezone is treated as an IST sheet value.
        listedAt = DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
        );
      }
    }

    final nowIst = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final today = DateTime(nowIst.year, nowIst.month, nowIst.day);
    final listedDay = DateTime(listedAt.year, listedAt.month, listedAt.day);
    final dayDifference = today.difference(listedDay).inDays;

    final hour12 = listedAt.hour % 12 == 0 ? 12 : listedAt.hour % 12;
    final minute = listedAt.minute.toString().padLeft(2, '0');
    final period = listedAt.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour12:$minute $period';

    if (dayDifference == 0) return 'Today, $time';
    if (dayDifference == 1) return 'Yesterday, $time';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${listedAt.day} ${months[listedAt.month - 1]} ${listedAt.year}, $time';
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: ArtistColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ArtistColors.primary.withOpacity(0.45),
          disabledForegroundColor: Colors.white.withOpacity(0.8),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Text(
                    'Saving Changes...',
                    style: ArtistTextStyles.button.copyWith(fontSize: 14),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.save_outlined,
                    size: 19,
                    color: Colors.white,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Save Changes',
                    style: ArtistTextStyles.button.copyWith(fontSize: 14),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isSaving
            ? null
            : () {
                Navigator.pop(context);
              },
        style: OutlinedButton.styleFrom(
          foregroundColor: ArtistColors.primary,
          backgroundColor: ArtistColors.surface,
          disabledForegroundColor: ArtistColors.textMuted,
          elevation: 0,
          side: BorderSide(
            color: _isSaving ? ArtistColors.border : ArtistColors.primary,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Cancel',
          style: ArtistTextStyles.bodyMedium.copyWith(
            color: _isSaving ? ArtistColors.textMuted : ArtistColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final totalQuantity = int.tryParse(_quantityController.text.trim());
    final availableQuantity = int.tryParse(
      _availableQuantityController.text.trim(),
    );
    final categoryId = _selectedCategoryId();
    if (totalQuantity == null ||
        availableQuantity == null ||
        categoryId == null) {
      _showErrorMessage(
        _categoryLoadError ?? 'Please select a valid category and quantity.',
      );
      return;
    }
    if (availableQuantity > totalQuantity) {
      _showErrorMessage('Available quantity cannot exceed total quantity.');
      return;
    }
    if (_existingImageUrls.length + _newImages.length > 4) {
      _showErrorMessage('You can keep up to 4 product photos.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categoryId': categoryId,
        'listingType': 'b2c',
        'condition': (_selectedCondition ?? 'Used').toLowerCase().replaceAll(
          ' ',
          '_',
        ),
        'price': double.parse(_priceController.text.trim()),
        'quantity': totalQuantity,
        'availableQuantity': availableQuantity,
        'deliveryMethod': _deliveryMethod,
      };
      if (_imagesChanged) {
        payload['existingImageUrls'] = _existingImageUrls;
        payload['imageBase64'] = await EcoImagePicker.payload(_newImages);
      }
      final id = int.tryParse(widget.product['productId']?.toString() ?? '');
      if (id == null)
        throw Exception(
          'Invalid product ID. Refresh My Products and try again.',
        );
      final updated = await EcoLoopApi.instance.put('/products/$id', payload);
      if (!mounted) return;
      if (updated is Map) {
        widget.product.addAll(Map<String, dynamic>.from(updated));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully.'),
          backgroundColor: ArtistColors.primary,
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted)
        _showErrorMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSheetIcon(IconData icon, {Color? color}) {
    final iconColor = color ?? ArtistColors.primary;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: iconColor),
    );
  }

  String _normalizeDeliveryMethod(dynamic value) {
    final raw = (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
    if (raw == 'free' ||
        raw == 'free delivery' ||
        raw == 'seller pays' ||
        raw == 'seller paid delivery') {
      return 'Free Delivery';
    }
    // Existing/missing values default to the buyer-paid EcoLoop-managed option.
    return 'EcoLoop-Managed Delivery';
  }

  String? _getInitialValue(dynamic value, List<String> options) {
    final String current = value?.toString() ?? '';

    if (options.contains(current)) {
      return current;
    }

    final String matched = options.firstWhere(
      (option) => option.toLowerCase() == current.toLowerCase(),
      orElse: () => '',
    );

    return matched.isEmpty ? null : matched;
  }

  String _firstImageUrl(Map<String, dynamic> product) {
    final dynamic imageUrls = product['imageUrls'];

    if (imageUrls is List && imageUrls.isNotEmpty) {
      return imageUrls.first.toString();
    }

    if (imageUrls is String && imageUrls.trim().isNotEmpty) {
      return imageUrls;
    }

    return '';
  }

  String _formatInitialNumber(dynamic value) {
    if (value == null) {
      return '';
    }

    final double? number = double.tryParse(value.toString());

    if (number == null) {
      return value.toString();
    }

    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toString();
  }

  String _formatStatus(String status) {
    if (status.isEmpty) {
      return '-';
    }

    return status[0].toUpperCase() + status.substring(1);
  }

  void _showPhotoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: ArtistTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        backgroundColor: ArtistColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: ArtistTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        backgroundColor: ArtistColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
