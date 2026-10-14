import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/eco_image_picker.dart';
import '../../../services/ecoloop_api.dart';
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
  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );
  String _deliveryMethod = 'EcoLoop Delivery';

  List<SelectedEcoImage> _images = [];
  bool _isSubmitting = false;

  String? selectedCategory;
  String? selectedCondition;

  List<String> categories = [];
  final Map<String, int> _categoryIds = {};
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final result = await EcoLoopApi.instance.get('/categories');
      final rows = result is List
          ? result
          : (result is Map
                ? (result['data'] ?? result['categories'] ?? [])
                : []);
      final names = <String>[];
      final ids = <String, int>{};
      for (final row in rows) {
        if (row is Map && row['name'] != null && row['categoryId'] != null) {
          final name = row['name'].toString();
          names.add(name);
          ids[name] = int.tryParse(row['categoryId'].toString()) ?? 0;
        }
      }
      if (mounted) {
        setState(() {
          categories = names;
          _categoryIds
            ..clear()
            ..addAll(ids);
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

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
    quantityController.dispose();
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
                final price = double.tryParse((value ?? '').trim());
                if (price == null || price < 0) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            _buildTextField(
              controller: quantityController,
              label: 'Available Quantity',
              hint: 'Enter quantity in numbers',
              icon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                final quantity = int.tryParse((value ?? '').trim());
                if (quantity == null || quantity < 1) {
                  return 'Enter a quantity of at least 1';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),
            _buildSectionTitle('Delivery Option'),
            const SizedBox(height: 10),
            _buildDeliveryOption(
              title: 'Manage delivery yourself',
              subtitle: 'Coordinate delivery directly with the buyer.',
              value: 'Self Delivery',
            ),
            const SizedBox(height: 10),
            _buildDeliveryOption(
              title: 'EcoLoop delivery',
              subtitle:
                  '₹45–₹60 for the first 500 g on local/short routes. Final charges depend on distance.',
              value: 'EcoLoop Delivery',
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
    return EcoImagePicker.gallery(
      context: context,
      images: _images,
      onChanged: (images) => setState(() => _images = images),
      maxImages: 4,
      accent: AppColors.primary,
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

  Widget _buildDeliveryOption({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final selected = _deliveryMethod == value;
    return InkWell(
      onTap: () => setState(() => _deliveryMethod = value),
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
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: AppColors.primary,
            ),
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
                  Text(subtitle, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellButton() {
    return ElevatedButton.icon(
      onPressed: _isSubmitting ? null : _submitProduct,
      icon: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sell_outlined),
      label: Text(_isSubmitting ? 'Saving listing…' : 'List Item for Sale'),
    );
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active categories found. Please add categories in the backend sheet.',
          ),
        ),
      );
      return;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product photo.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await EcoLoopApi.instance.post('/products', {
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'categoryId': _categoryIds[selectedCategory],
        'listingType': 'c2c',
        'condition': (selectedCondition ?? 'used').toLowerCase().replaceAll(
          ' ',
          '_',
        ),
        'price': double.parse(priceController.text.trim()),
        'quantity': int.parse(quantityController.text.trim()),
        'deliveryMethod': _deliveryMethod,
        'status': 'published',
        'imageBase64': await EcoImagePicker.payload(_images),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your item has been listed successfully.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
