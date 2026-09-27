import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import 'edit_product.dart';
class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );

  String? selectedCategory;
  String? selectedCondition;
  String? selectedListingType;

  final List<String> categories = [
    'Furniture',
    'Electronics',
    'Home & Decor',
    'Books',
    'Clothing',
    'Kitchen',
    'Sports',
    'Other',
  ];

  final List<String> conditions = [
    'New',
    'Like New',
    'Good',
    'Used',
    'Needs Repair',
  ];

  final List<String> listingTypes = ['Sell', 'Donate'];

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      // APP BAR
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
        ),
        title: Text('Add Product', style: ArtistTextStyles.title),
      ),

      // BODY
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _buildIntro(),

            const SizedBox(height: 24),

            // PRODUCT PHOTOS
            _buildSectionTitle('Product Photos'),

            const SizedBox(height: 10),

            _buildImagePicker(),

            const SizedBox(height: 25),

            // PRODUCT DETAILS
            _buildSectionTitle('Product Details'),

            const SizedBox(height: 10),

            // Product Name
            _buildTextField(
              controller: titleController,
              label: 'Product Name',
              hint: 'e.g. Handcrafted Wooden Table',
              icon: Icons.inventory_2_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter product name';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            // Category
            _buildDropdown(
              value: selectedCategory,
              label: 'Category',
              hint: 'Select category',
              icon: Icons.category_outlined,
              items: categories,
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 14),

            // Condition
            _buildDropdown(
              value: selectedCondition,
              label: 'Condition',
              hint: 'Select condition',
              icon: Icons.recycling_outlined,
              items: conditions,
              onChanged: (value) {
                setState(() {
                  selectedCondition = value;
                });
              },
            ),

            const SizedBox(height: 14),

            // Listing Type
            _buildDropdown(
              value: selectedListingType,
              label: 'Listing Type',
              hint: 'Select listing type',
              icon: Icons.sell_outlined,
              items: listingTypes,
              onChanged: (value) {
                setState(() {
                  selectedListingType = value;
                });
              },
            ),

            const SizedBox(height: 14),

            // Price
            _buildTextField(
              controller: priceController,
              label: 'Price',
              hint: 'Enter product price',
              icon: Icons.currency_rupee_rounded,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter price';
                }

                final price = double.tryParse(value.trim());

                if (price == null || price < 0) {
                  return 'Please enter a valid price';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            // Quantity
            _buildTextField(
              controller: quantityController,
              label: 'Quantity',
              hint: 'Enter available quantity',
              icon: Icons.inventory_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter quantity';
                }

                final quantity = int.tryParse(value.trim());

                if (quantity == null || quantity <= 0) {
                  return 'Quantity must be greater than 0';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            // Description
            _buildTextField(
              controller: descriptionController,
              label: 'Description',
              hint: 'Tell buyers about your product...',
              icon: Icons.description_outlined,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please add a description';
                }

                return null;
              },
            ),

            const SizedBox(height: 28),

            // LIST PRODUCT BUTTON
            _buildListProductButton(),

            const SizedBox(height: 18),

            // PRODUCT TIPS
            _buildProductTips(),
          ],
        ),
      ),
    );
  }

  // INTRO

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bring your creation to the marketplace',
                  style: ArtistTextStyles.bodyMedium,
                ),

                const SizedBox(height: 4),

                Text(
                  'Add your product details and make it available to EcoLoop buyers.',
                  style: ArtistTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // SECTION TITLE

  Widget _buildSectionTitle(String title) {
    return Text(title, style: ArtistTextStyles.title.copyWith(fontSize: 16));
  }

  // IMAGE PICKER

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add up to 4 photos', style: ArtistTextStyles.caption),

        const SizedBox(height: 10),

        // ------------------------------------------------------
        // ROW 1
        // ------------------------------------------------------
        Row(
          children: [
            Expanded(child: _buildPhotoSlot(index: 0, label: 'Main Photo')),

            const SizedBox(width: 10),

            Expanded(child: _buildPhotoSlot(index: 1, label: 'Photo 2')),
          ],
        ),

        const SizedBox(height: 10),

        // ------------------------------------------------------
        // ROW 2
        // ------------------------------------------------------
        Row(
          children: [
            Expanded(child: _buildPhotoSlot(index: 2, label: 'Photo 3')),

            const SizedBox(width: 10),

            Expanded(child: _buildPhotoSlot(index: 3, label: 'Photo 4')),
          ],
        ),
      ],
    );
  }

  // INDIVIDUAL PHOTO SLOT

  Widget _buildPhotoSlot({required int index, required String label}) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$label image picker will be connected in the next phase.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        height: 125,
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ArtistColors.light,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                index == 0
                    ? Icons.add_a_photo_outlined
                    : Icons.add_photo_alternate_outlined,
                color: ArtistColors.primary,
                size: 22,
              ),
            ),

            const SizedBox(height: 9),

            Text(
              label,
              style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 12),
            ),

            const SizedBox(height: 2),

            Text(
              index == 0 ? 'Required' : 'Optional',
              style: ArtistTextStyles.small,
            ),
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
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ArtistTextStyles.label),

        const SizedBox(height: 7),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ArtistTextStyles.hint,
            prefixIcon: Icon(icon, color: ArtistColors.primary, size: 21),
          ),
        ),
      ],
    );
  }

  // DROPDOWN

  Widget _buildDropdown({
    required String? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ArtistTextStyles.label),

        const SizedBox(height: 7),

        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint, style: ArtistTextStyles.hint),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: ArtistColors.textSecondary,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: ArtistColors.primary, size: 21),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: ArtistTextStyles.bodyMedium),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select $label';
            }

            return null;
          },
        ),
      ],
    );
  }

  // LIST PRODUCT BUTTON
  Widget _buildListProductButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          if (!_formKey.currentState!.validate()) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Product listing will be connected in the next phase.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        icon: const Icon(Icons.add_business_outlined, size: 20),
        label: const Text('List Product'),
        style: ElevatedButton.styleFrom(
          backgroundColor: ArtistColors.primary,
          foregroundColor: ArtistColors.background,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: ArtistTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // PRODUCT TIPS

  Widget _buildProductTips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ArtistColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: ArtistColors.warning,
                size: 21,
              ),

              const SizedBox(width: 9),

              Text('Product Listing Tips', style: ArtistTextStyles.bodyMedium),
            ],
          ),

          const SizedBox(height: 12),

          _buildTip('Use clear, well-lit product photos.'),

          _buildTip('Write an accurate and detailed description.'),

          _buildTip('Choose the correct category and condition.'),

          _buildTip('Keep your price and available quantity updated.'),
        ],
      ),
    );
  }

  // SINGLE TIP

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 5, color: ArtistColors.primary),
          ),

          const SizedBox(width: 9),

          Expanded(child: Text(text, style: ArtistTextStyles.caption)),
        ],
      ),
    );
  }
}
