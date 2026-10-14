import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/eco_image_picker.dart';
import '../../../services/ecoloop_api.dart';

/// Screen allowing users to list unused items for free donation and pickup.
class DonateItem extends StatefulWidget {
  const DonateItem({super.key});

  @override
  State<DonateItem> createState() => _DonateItemState();
}

class _DonateItemState extends State<DonateItem> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  List<SelectedEcoImage> _images = [];
  bool _isSubmitting = false;

  String? selectedCategory;
  String? selectedCondition;

  final List<String> categories = [
    'Furniture',
    'Decor',
    'Electronics',
    'Materials',
    'Fashion',
    'Books',
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
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text('Donate an Item', style: AppTextStyles.title),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            _buildIntro(),
            const SizedBox(height: 24),
            _buildSectionTitle('Item Photos'),
            const SizedBox(height: 10),
            _buildImagePicker(),
            const SizedBox(height: 25),
            _buildSectionTitle('Item Details'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: titleController,
              label: 'Item Name',
              hint: 'e.g. Wooden Chair',
              icon: Icons.inventory_2_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter item name';
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
              controller: descriptionController,
              label: 'Description',
              hint: 'Tell us about the item...',
              icon: Icons.description_outlined,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please add a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            _buildPickupInfo(),
            const SizedBox(height: 14),
            _buildRewardInfo(),
            const SizedBox(height: 28),
            _buildSectionTitle('Pickup Address'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: addressController,
              label: 'Full Address',
              hint: 'House / street / area',
              icon: Icons.location_on_outlined,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter pickup address'
                  : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: cityController,
              label: 'City',
              hint: 'Enter your city',
              icon: Icons.location_city_outlined,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter city'
                  : null,
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: stateController,
              label: 'State',
              hint: 'Enter your state',
              icon: Icons.map_outlined,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter state'
                  : null,
            ),
            const SizedBox(height: 24),
            _buildDonateButton(),
          ],
        ),
      ),
    );
  }

  /// Informational banner promoting community impact.
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
            child: const Icon(
              Icons.volunteer_activism_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Give your item a new life',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Donate unused items and help them reach someone who needs them.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Form section title label.
  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.title.copyWith(fontSize: 16));
  }

  /// Dashed/bordered box placeholder for selecting item photos.
  Widget _buildImagePicker() {
    return EcoImagePicker.gallery(
      context: context,
      images: _images,
      onChanged: (images) => setState(() => _images = images),
      maxImages: 4,
      accent: AppColors.primary,
    );
  }

  /// Standardized labeled text form field with leading icon.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
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

  /// Standardized dropdown field wrapper.
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

  /// Feature card informing users about doorstep pickup availability.
  Widget _buildPickupInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: AppColors.primary,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Pickup',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'EcoLoop provides free pickup for donated items.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Feature card detailing EcoLoop donor rewards.
  Widget _buildRewardInfo() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.card_giftcard_outlined,
            color: AppColors.primary,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Donation Reward',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Eligible donations may receive an EcoLoop gift.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Primary submission action button.
  Widget _buildDonateButton() {
    return ElevatedButton.icon(
      onPressed: _isSubmitting ? null : _submitDonation,
      icon: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.volunteer_activism_outlined),
      label: Text(_isSubmitting ? 'Submitting donation…' : 'Donate Item'),
    );
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item photo.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await EcoLoopApi.instance.post('/donations', {
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'categoryId': EcoLoopApi.categoryId(selectedCategory),
        'condition': (selectedCondition ?? 'used').toLowerCase().replaceAll(
          ' ',
          '_',
        ),
        'address': addressController.text.trim(),
        'city': cityController.text.trim(),
        'state': stateController.text.trim(),
        'imageBase64': await EcoImagePicker.payload(_images),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation saved successfully.')),
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
}
