import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

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

  bool _isSaving = false;

  final List<String> _categories = [
    'Furniture',
    'Electronics',
    'Home & Decor',
    'Books',
    'Clothing',
    'Kitchen',
    'Sports',
    'Other',
  ];

  final List<String> _conditions = [
    'New',
    'Like New',
    'Good',
    'Used',
    'Needs Repair',
  ];

  final List<String> _listingTypes = ['Sell', 'Donate'];

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

    _selectedCategory = _getInitialCategory(product);

    _selectedCondition = _getInitialValue(product['condition'], _conditions);

    _selectedListingType = _getInitialValue(
      product['listingType'],
      _listingTypes,
    );
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

  // BUILD

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
              hint: 'Select category',
              icon: Icons.category_outlined,
              items: _categories,
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

  // PRODUCT HEADER

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

  // SECTION TITLE

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

  // PHOTOS

  Widget _buildPhotoSection() {
    final String imageUrl =
        widget.product['image']?.toString() ?? _firstImageUrl(widget.product);

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
              Text('Up to 4 photos', style: ArtistTextStyles.small),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 105,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildExistingImage(imageUrl: imageUrl, isMain: true),
                ),

                const SizedBox(width: 10),

                Expanded(child: _buildPhotoPlaceholder(label: 'Photo 2')),

                const SizedBox(width: 10),

                Expanded(child: _buildPhotoPlaceholder(label: 'Photo 3')),

                const SizedBox(width: 10),

                Expanded(child: _buildPhotoPlaceholder(label: 'Photo 4')),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Tap a photo to replace or remove it.',
            style: ArtistTextStyles.small,
          ),
        ],
      ),
    );
  }

  Widget _buildExistingImage({required String imageUrl, required bool isMain}) {
    return GestureDetector(
      onTap: () {
        _showImageOptions(isExisting: imageUrl.isNotEmpty);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: ArtistColors.surfaceSoft,
              child: imageUrl.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: ArtistColors.textMuted,
                        size: 30,
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: ArtistColors.textMuted,
                            size: 28,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ArtistColors.primary,
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (isMain)
              Positioned(
                left: 7,
                bottom: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ArtistColors.accent.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'Main',
                    style: ArtistTextStyles.small.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),

            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ArtistColors.surface.withOpacity(0.94),
                  shape: BoxShape.circle,
                  border: Border.all(color: ArtistColors.border),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: ArtistColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder({required String label}) {
    return GestureDetector(
      onTap: () {
        _showImageOptions();
      },
      child: Container(
        decoration: BoxDecoration(
          color: ArtistColors.surfaceSoft,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              color: ArtistColors.primary,
              size: 23,
            ),

            const SizedBox(height: 5),

            Text(label, style: ArtistTextStyles.small.copyWith(fontSize: 9)),
          ],
        ),
      ),
    );
  }

  // TEXT FIELD

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

  // DROPDOWN

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

  // QUANTITY INFO

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
              'Available quantity cannot be greater than the total quantity. Sold quantities are reflected automatically.',
              style: ArtistTextStyles.small.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // PRODUCT INFO

  Widget _buildProductInfoCard() {
    final String status = widget.product['status']?.toString() ?? 'active';

    final String createdAt = widget.product['createdAt']?.toString() ?? '-';

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
    return Row(
      children: [
        Icon(icon, size: 18, color: ArtistColors.textSecondary),

        const SizedBox(width: 10),

        Expanded(child: Text(label, style: ArtistTextStyles.small)),

        Text(value, style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 12)),
      ],
    );
  }

  // SAVE BUTTON

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

  // CANCEL BUTTON

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

  // SAVE

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? totalQuantity = int.tryParse(_quantityController.text.trim());

    final int? availableQuantity = int.tryParse(
      _availableQuantityController.text.trim(),
    );

    if (totalQuantity != null &&
        availableQuantity != null &&
        availableQuantity > totalQuantity) {
      _showMessage('Available quantity cannot exceed total quantity.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // UI ONLY FOR NOW.
    // Backend PUT /products/:id will be connected later.

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    _showSuccessMessage('Product changes will be connected in the next phase.');
  }

  // IMAGE OPTIONS

  void _showImageOptions({bool isExisting = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ArtistColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  isExisting ? 'Edit Product Photo' : 'Add Product Photo',
                  style: ArtistTextStyles.title.copyWith(fontSize: 19),
                ),

                const SizedBox(height: 18),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _buildSheetIcon(Icons.photo_library_outlined),
                  title: Text(
                    'Choose from Gallery',
                    style: ArtistTextStyles.bodyMedium,
                  ),
                  subtitle: Text(
                    'Select an existing image',
                    style: ArtistTextStyles.small,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon('Gallery');
                  },
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _buildSheetIcon(Icons.camera_alt_outlined),
                  title: Text(
                    'Take a Photo',
                    style: ArtistTextStyles.bodyMedium,
                  ),
                  subtitle: Text(
                    'Use your camera',
                    style: ArtistTextStyles.small,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon('Camera');
                  },
                ),

                if (isExisting)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _buildSheetIcon(
                      Icons.delete_outline_rounded,
                      color: ArtistColors.error,
                    ),
                    title: Text(
                      'Remove Photo',
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: ArtistColors.error,
                      ),
                    ),
                    subtitle: Text(
                      'Remove this product image',
                      style: ArtistTextStyles.small,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Remove Photo');
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
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

  // HELPERS

  String? _getInitialCategory(Map<String, dynamic> product) {
    final String category = product['category']?.toString() ?? '';

    if (_categories.contains(category)) {
      return category;
    }

    return null;
  }

  String? _getInitialValue(dynamic value, List<String> options) {
    final String current = value?.toString() ?? '';

    if (options.contains(current)) {
      return current;
    }

    return null;
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

  // SNACKBARS

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature will be connected in the next phase.',
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: ArtistTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        backgroundColor: ArtistColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showMessage(String message) {
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
