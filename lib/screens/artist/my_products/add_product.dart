import 'package:flutter/material.dart';

import '../../../services/eco_image_picker.dart';
import '../../../services/ecoloop_api.dart';

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

  List<SelectedEcoImage> _images = [];
  bool _isSubmitting = false;

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
    if (index < _images.length) {
      final image = _images[index];
      return Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(image.bytes, height: 125, width: double.infinity, fit: BoxFit.cover)),
        Positioned(right: 6, top: 6, child: IconButton.filledTonal(onPressed: () => setState(() => _images.removeAt(index)), icon: const Icon(Icons.close, size: 16))),
      ]);
    }
    return GestureDetector(
      onTap: () async {
        try {
          final picked = await EcoImagePicker.pick(current: _images, maxImages: 4);
          if (mounted) setState(() => _images = picked);
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
        }
      },
      child: Container(
        height: 125,
        decoration: BoxDecoration(color: ArtistColors.surfaceSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: ArtistColors.border)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_a_photo_outlined, color: ArtistColors.primary, size: 25),
          const SizedBox(height: 7),
          Text(label, style: ArtistTextStyles.caption),
          const SizedBox(height: 3),
          Text('Add photo', style: ArtistTextStyles.caption),
        ]),
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
    return ElevatedButton.icon(
      onPressed: _isSubmitting ? null : _submitProduct,
      icon: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_business_outlined, size: 20),
      label: Text(_isSubmitting ? 'Saving product…' : 'List Product'),
      style: ElevatedButton.styleFrom(
        backgroundColor: ArtistColors.primary,
        foregroundColor: ArtistColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: ArtistTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one product photo.')));
      return;
    }
    if ((selectedListingType ?? 'Sell') == 'Donate') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('For donations, please use the Donate Item flow so pickup details can be recorded.')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await EcoLoopApi.instance.post('/products', {
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'categoryId': EcoLoopApi.categoryId(selectedCategory),
        'listingType': 'b2c',
        'condition': (selectedCondition ?? 'used').toLowerCase().replaceAll(' ', '_'),
        'price': double.parse(priceController.text.trim()),
        'quantity': int.parse(quantityController.text.trim()),
        'status': 'published',
        'imageBase64': await EcoImagePicker.payload(_images),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your product has been listed successfully.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
