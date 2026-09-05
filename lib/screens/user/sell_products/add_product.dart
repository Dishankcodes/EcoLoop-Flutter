import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
import '../donations/donate_item.dart';

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

  String? selectedCategory;
  String? selectedCondition;

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

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text('Sell an Item', style: AppTextStyles.title),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _buildIntro(),

            const SizedBox(height: 24),

            _buildSectionTitle('Product Photos'),

            const SizedBox(height: 10),

            _buildImagePicker(),

            const SizedBox(height: 25),

            _buildSectionTitle('Product Details'),

            const SizedBox(height: 10),

            _buildTextField(
              controller: titleController,
              label: 'Product Name',
              hint: 'e.g. Wooden Study Table',
              icon: Icons.inventory_2_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter product name';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

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

            _buildTextField(
              controller: priceController,
              label: 'Expected Price',
              hint: 'Enter your expected price',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter expected price';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            _buildTextField(
              controller: descriptionController,
              label: 'Description',
              hint: 'Tell buyers about your item...',
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

            _buildSellButton(),

            const SizedBox(height: 18),

            _buildDonationOption(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // INTRO
  // ==========================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco_outlined, color: AppColors.primary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Give your item a new orbit',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Sell your unused item and give it a second life with a new owner.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.title.copyWith(fontSize: 16));
  }

  // ==========================================================
  // IMAGE PICKER
  // ==========================================================

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image picker will be connected in the next phase.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.7)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Add Product Photos',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 3),

            Text('Add clear photos of your item', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TEXT FIELD
  // ==========================================================

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
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 7),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 21),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // DROPDOWN
  // ==========================================================

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
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 7),

        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint, style: AppTextStyles.hint),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 21),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
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

  // ==========================================================
  // SELL BUTTON
  // ==========================================================

  Widget _buildSellButton() {
    return ElevatedButton.icon(
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
      icon: const Icon(Icons.sell_outlined),
      label: const Text('List Item for Sale'),
    );
  }

  // ==========================================================
  // DONATE OPTION
  // ==========================================================

  Widget _buildDonationOption() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              color: AppColors.primary,
              size: 25,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Want to donate instead?',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Give your unused item to the community with free pickup.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonateItem()),
              );
            },
            icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
            label: const Text('Donate This Item'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
