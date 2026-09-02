import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';

class EditListing extends StatefulWidget {
  final Map<String, dynamic> listing;

  const EditListing({super.key, required this.listing});

  @override
  State<EditListing> createState() => _EditListingState();
}

class _EditListingState extends State<EditListing> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;

  String _category = 'Furniture';
  String _condition = 'Good';
  bool _available = true;

  final List<String> categories = [
    'Furniture',
    'Electronics',
    'Home & Decor',
    'Books',
    'Clothing',
    'Kitchen',
    'Sports',
    'Materials',
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
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.listing['title'] ?? '',
    );

    _priceController = TextEditingController(
      text: _extractPrice(widget.listing['price']),
    );

    _quantityController = TextEditingController(text: '1');

    _descriptionController = TextEditingController(
      text:
          widget.listing['description'] ??
          'A pre-owned item looking for a new home.',
    );

    if (categories.contains(widget.listing['category'])) {
      _category = widget.listing['category'];
    }

    if (conditions.contains(widget.listing['condition'])) {
      _condition = widget.listing['condition'];
    }

    _available = widget.listing['status'] != 'Sold';
  }

  String _extractPrice(dynamic price) {
    if (price == null) return '';

    return price.toString().replaceAll('₹', '').replaceAll(',', '').trim();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
            onPressed: _showDeleteConfirmation,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            tooltip: 'Delete Listing',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntro(),
            const SizedBox(height: 22),

            _buildPhotosSection(),
            const SizedBox(height: 24),

            _buildBasicInformation(),
            const SizedBox(height: 24),

            _buildDescription(),
            const SizedBox(height: 24),

            _buildAvailability(),
            const SizedBox(height: 30),

            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          'Make changes to your item before saving.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PHOTOS
  // ============================================================

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Product Photos', 'Update photos of your item'),
        const SizedBox(height: 12),

        Row(
          children: [
            _photoBox(icon: widget.listing['icon'] ?? Icons.image_outlined),
            const SizedBox(width: 10),
            _photoBox(icon: Icons.add_photo_alternate_outlined, isAdd: true),
            const SizedBox(width: 10),
            _photoBox(icon: Icons.add_photo_alternate_outlined, isAdd: true),
          ],
        ),

        const SizedBox(height: 8),

        const Text(
          'You can add or replace photos later.',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _photoBox({required IconData icon, bool isAdd = false}) {
    return GestureDetector(
      onTap: () {
        _showMessage(
          isAdd
              ? 'Image picker will be connected later.'
              : 'Photo editing will be connected later.',
        );
      },
      child: Container(
        height: 90,
        width: 90,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.accent.withOpacity(0.55)),
        ),
        child: Icon(icon, size: isAdd ? 27 : 38, color: AppColors.primary),
      ),
    );
  }

  // ============================================================
  // BASIC INFORMATION
  // ============================================================

  Widget _buildBasicInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Item Information', 'Update the details of your item'),
        const SizedBox(height: 15),

        _buildLabel('Product Name'),
        const SizedBox(height: 7),
        _buildTextField(
          controller: _nameController,
          hint: 'Enter product name',
        ),

        const SizedBox(height: 17),

        _buildLabel('Category'),
        const SizedBox(height: 7),
        _buildDropdown(
          value: _category,
          items: categories,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _category = value;
              });
            }
          },
        ),

        const SizedBox(height: 17),

        _buildLabel('Condition'),
        const SizedBox(height: 7),
        _buildDropdown(
          value: _condition,
          items: conditions,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _condition = value;
              });
            }
          },
        ),

        const SizedBox(height: 17),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Expected Price'),
                  const SizedBox(height: 7),
                  _buildTextField(
                    controller: _priceController,
                    hint: '₹ 0',
                    keyboardType: TextInputType.number,
                    prefix: '₹ ',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Quantity'),
                  const SizedBox(height: 7),
                  _buildTextField(
                    controller: _quantityController,
                    hint: '1',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Description', 'Tell buyers about the item'),
        const SizedBox(height: 15),

        _buildLabel('Item Description'),
        const SizedBox(height: 7),

        TextField(
          controller: _descriptionController,
          maxLines: 6,
          minLines: 4,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Describe the condition, usage and other details...',
            alignLabelWithHint: true,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.all(15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AVAILABILITY
  // ============================================================

  Widget _buildAvailability() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available for sale',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Buyers can see and purchase this listing.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: _available,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _available = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE LOGIC
  // ============================================================

  void _saveChanges() {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter a product name.');
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      _showMessage('Please enter the expected price.');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('Please enter a description.');
      return;
    }

    // API/update logic will be connected later.
    _showMessage('Listing changes saved successfully.');

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Listing?'),
          content: Text(
            'Are you sure you want to delete '
            '"${widget.listing['title']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                _showMessage('Delete will be connected later.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.primary,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
