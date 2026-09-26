import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCondition;

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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        title: Text(
          'Sell an Item',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: ArtistColors.background,
        foregroundColor: ArtistColors.textPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntro(),
              const SizedBox(height: 28),
              _buildSectionTitle(
                'Product Photos',
                'Add clear photos of your product',
              ),
              const SizedBox(height: 12),
              _buildImagePicker(),
              const SizedBox(height: 28),
              _buildSectionTitle(
                'Product Details',
                'Tell buyers about your item',
              ),
              const SizedBox(height: 18),
              _buildTextField(
                controller: _titleController,
                label: 'Product Title',
                hint: 'e.g. Upcycled Wooden Table',
                icon: Icons.title_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a product title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your product...',
                icon: Icons.description_outlined,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _priceController,
                label: 'Price',
                hint: 'Enter price',
                icon: Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }

                  final price = double.tryParse(value);

                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Category',
                hint: 'Select category',
                value: _selectedCategory,
                items: _categories,
                icon: Icons.category_outlined,
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
                hint: 'Select condition',
                value: _selectedCondition,
                items: _conditions,
                icon: Icons.auto_awesome_outlined,
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a condition';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              _buildSellButton(),
              const SizedBox(height: 16),
              _buildDonationOption(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ArtistColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ArtistColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ArtistColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'List your creation',
                  style: ArtistTextStyles.title.copyWith(
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Share your handmade or upcycled products with the EcoLoop community.',
                  style: ArtistTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title,
      String subtitle,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ArtistTextStyles.title.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: ArtistTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ArtistColors.border,
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image picker will be connected in the next phase.',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: ArtistColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ArtistColors.light.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: ArtistColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add Product Photos',
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: ArtistColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Add clear images of your product',
              style: ArtistTextStyles.small,
            ),
          ],
        ),
      ),
    );
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
        Text(
          label,
          style: ArtistTextStyles.label,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: ArtistTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ArtistTextStyles.hint,
            prefixIcon: Icon(
              icon,
              color: ArtistColors.primary,
              size: 21,
            ),
            filled: true,
            fillColor: ArtistColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: ArtistColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: ArtistColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: ArtistColors.primary,
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: ArtistColors.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
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
    required String hint,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ArtistTextStyles.label,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          onChanged: onChanged,
          style: ArtistTextStyles.bodyMedium,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ArtistColors.primary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ArtistTextStyles.hint,
            prefixIcon: Icon(
              icon,
              color: ArtistColors.primary,
              size: 21,
            ),
            filled: true,
            fillColor: ArtistColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: ArtistColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: ArtistColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: ArtistColors.primary,
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: ArtistColors.error,
              ),
            ),
          ),
          dropdownColor: ArtistColors.surface,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: ArtistTextStyles.bodyMedium,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSellButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Product listing will be connected in the next phase.',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: ArtistColors.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        icon: const Icon(
          Icons.sell_outlined,
          size: 20,
        ),
        label: Text(
          'List Product',
          style: ArtistTextStyles.button,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ArtistColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildDonationOption() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ArtistColors.border,
        ),
      ),
      child: ListTile(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Donation flow will be connected in the next phase.',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: ArtistColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ArtistColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.volunteer_activism_outlined,
            color: ArtistColors.primary,
          ),
        ),
        title: Text(
          'Want to donate instead?',
          style: ArtistTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Give your item a second life by donating it.',
          style: ArtistTextStyles.small,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 15,
          color: ArtistColors.textMuted,
        ),
      ),
    );
  }
}