import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/eco_image_picker.dart';
import '../../../services/ecoloop_api.dart';
import '../profile/add_address.dart';

class DonateItem extends StatefulWidget {
  const DonateItem({super.key});

  @override
  State<DonateItem> createState() => _DonateItemState();
}

class _DonateItemState extends State<DonateItem> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  List<SelectedEcoImage> _images = [];
  List<Map<String, dynamic>> _addresses = [];
  List<Map<String, dynamic>> _categories = [];

  String? selectedCategory;
  String? selectedCondition;
  String? _selectedAddressId;

  bool _isSubmitting = false;
  bool _loadingAddresses = true;
  bool _loadingCategories = true;
  bool _openingAddress = false;

  String? _addressError;
  String? _categoryLoadError;

  final List<String> conditions = [
    'New',
    'Like New',
    'Good',
    'Used',
    'Needs Repair',
  ];

  List<String> get categories => _categories
      .map((e) => e['name']?.toString() ?? '')
      .where((e) => e.trim().isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadAddresses();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ==================== CATEGORY API ====================

  Future<void> _loadCategories() async {
    try {
      final response =
      await EcoLoopApi.instance.get('/categories');

      final rows = response is List
          ? response
          : response is Map &&
          response['categories'] is List
          ? response['categories'] as List
          : <dynamic>[];

      final parsed = rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) =>
      e['categoryId'] != null && e['name'] != null)
          .toList();

      if (!mounted) return;

      setState(() {
        _categories = parsed;
        _loadingCategories = false;
        _categoryLoadError = parsed.isEmpty
            ? 'No active categories are available.'
            : null;

        if (selectedCategory != null &&
            !categories.contains(selectedCategory)) {
          selectedCategory = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCategories = false;
        _categoryLoadError =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ==================== MAIN SCREEN ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: AppColors.accent.withOpacity(.5),
                ),
              ),
            ),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        title: Text(
          'Donate an Item',
          style: AppTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
          children: [
            _buildIntro(),
            const SizedBox(height: 18),

            _buildDonationSteps(),
            const SizedBox(height: 27),

            _buildSectionTitle(
              'Show us your item',
              'Add clear photos so your donation can be reviewed easily.',
            ),
            const SizedBox(height: 12),
            _buildImagePicker(),

            const SizedBox(height: 27),

            _buildSectionTitle(
              'Donation details',
              'A few details help us find the right next home.',
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: titleController,
              label: 'What are you donating?',
              hint: 'e.g. Books, clothes, wooden chair',
              icon: Icons.inventory_2_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),
            _buildCategoryCards(),

            if (_loadingCategories)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: LinearProgressIndicator(minHeight: 3),
              )
            else if (_categoryLoadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _categoryLoadError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadCategories,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),
            _buildConditionSelector(),

            const SizedBox(height: 18),

            _buildTextField(
              controller: descriptionController,
              label: 'Item description',
              hint:
              'Share the size, age, condition or anything '
                  'the recipient should know...',
              icon: Icons.notes_rounded,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please add a description';
                }
                return null;
              },
            ),

            const SizedBox(height: 22),
            _buildImpactCard(),

            const SizedBox(height: 12),
            _buildPickupInfo(),

            const SizedBox(height: 27),

            _buildSectionTitle(
              'Pickup details',
              'Choose where EcoLoop should collect your donation.',
            ),
            const SizedBox(height: 13),

            _buildPickupAddressSelector(),

            const SizedBox(height: 24),
            _buildDonateButton(),
            const SizedBox(height: 13),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your details are used only to arrange your donation.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HERO BANNER ====================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF2E7D32),
            Color(0xFF438B4A),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.16),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withOpacity(.22),
                  ),
                ),
                child: const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'ECOLOOP GIVING',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          Text(
            'Give More.\nWaste Less.',
            style: AppTextStyles.heading.copyWith(
              color: Colors.white,
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your unused items can make a real difference. '
                'Pass them on, support your community and help '
                'keep useful things out of landfills.',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withOpacity(.92),
              height: 1.55,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _heroPill(
                Icons.favorite_outline_rounded,
                'Help someone',
              ),
              _heroPill(
                Icons.recycling_rounded,
                'Keep it in use',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.13),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DONATION STEPS ====================

  Widget _buildDonationSteps() {
    final steps = [
      (Icons.add_a_photo_outlined, 'Add item'),
      (Icons.fact_check_outlined, 'Add details'),
      (Icons.local_shipping_outlined, 'Arrange pickup'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(.45),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      steps[i].$1,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    steps[i].$2,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (i != steps.length - 1)
              Container(
                width: 22,
                height: 1.5,
                color: AppColors.accent,
              ),
          ],
        ],
      ),
    );
  }

  // ==================== SECTION TITLE ====================

  Widget _buildSectionTitle(
      String title, [
        String? subtitle,
      ]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.title.copyWith(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==================== PHOTO PICKER ====================

  Widget _buildImagePicker() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(.45),
        ),
      ),
      child: EcoImagePicker.gallery(
        context: context,
        images: _images,
        onChanged: (images) => setState(() => _images = images),
        maxImages: 4,
        accent: AppColors.primary,
      ),
    );
  }

  // ==================== CATEGORY CARDS ====================

  Widget _buildCategoryCards() {
    final icons = <String, IconData>{
      'clothes': Icons.checkroom_rounded,
      'clothing': Icons.checkroom_rounded,
      'book': Icons.menu_book_rounded,
      'furniture': Icons.chair_alt_rounded,
      'electronic': Icons.devices_other_rounded,
      'toy': Icons.toys_outlined,
      'home': Icons.weekend_outlined,
      'other': Icons.category_outlined,
    };

    IconData iconFor(String name) {
      final key = name.toLowerCase();

      for (final entry in icons.entries) {
        if (key.contains(entry.key)) {
          return entry.value;
        }
      }

      return Icons.volunteer_activism_outlined;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Donation category',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 9),
        if (_categories.isEmpty && !_loadingCategories)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: _fieldDecoration(),
            child: Text(
              'Categories will appear here when available.',
              style: AppTextStyles.caption,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth < 360 ? 2 : 3;
              final width =
                  (constraints.maxWidth - ((count - 1) * 9)) / count;

              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: _categories.map((category) {
                  final name = category['name']?.toString() ?? '';
                  final selected = selectedCategory == name;

                  return SizedBox(
                    width: width,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        setState(() => selectedCategory = name);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.light
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.accent.withOpacity(.5),
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              iconFor(name),
                              color: AppColors.primary,
                              size: 23,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 10.5,
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(height: 5),
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        if (selectedCategory == null)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              'Choose the category that best fits your item.',
              style: AppTextStyles.caption.copyWith(fontSize: 10.5),
            ),
          ),
      ],
    );
  }

  // ==================== ITEM CONDITION ====================

  Widget _buildConditionSelector() {
    const conditionIcons = <String, IconData>{
      'New': Icons.auto_awesome_outlined,
      'Like New': Icons.stars_outlined,
      'Good': Icons.thumb_up_alt_outlined,
      'Used': Icons.recycling_outlined,
      'Needs Repair': Icons.build_outlined,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item condition',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Be honest about the condition so the next owner '
              'knows what to expect.',
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: conditions.map((condition) {
            final selected = selectedCondition == condition;

            return InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                setState(() => selectedCondition = condition);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.accent.withOpacity(.65),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      conditionIcons[condition] ??
                          Icons.check_circle_outline,
                      size: 15,
                      color: selected
                          ? Colors.white
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      condition,
                      style: AppTextStyles.caption.copyWith(
                        color: selected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedCondition == null)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              'Select the current condition of your item.',
              style: AppTextStyles.caption.copyWith(fontSize: 10.5),
            ),
          ),
      ],
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.accent.withOpacity(.5),
      ),
    );
  }

  // ==================== TEXT FIELDS ====================

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
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.hint.copyWith(fontSize: 11.5),
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                bottom: maxLines > 1 ? 57 : 0,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 15 : 17,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.accent.withOpacity(.55),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== IMPACT CARD ====================

  Widget _buildImpactCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withOpacity(.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Small act. Real impact.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Every useful item deserves another chance.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _impactPoint(
                  Icons.recycling_rounded,
                  'Less waste',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _impactPoint(
                  Icons.favorite_outline_rounded,
                  'Help others',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _impactPoint(
                  Icons.loop_rounded,
                  'Reuse more',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _impactPoint(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ==================== PICKUP INFO ====================

  Widget _buildPickupInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accent.withOpacity(.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free doorstep pickup',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a saved address below so the pickup '
                      'team knows where to collect your item.',
                  style: AppTextStyles.caption.copyWith(
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DONATE BUTTON ====================

  Widget _buildDonateButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xFF2E7D32),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.22),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitDonation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 58),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(
          Icons.volunteer_activism_rounded,
          size: 21,
        ),
        label: Text(
          _isSubmitting
              ? 'Submitting donation...'
              : 'Donate this item',
          style: AppTextStyles.button.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }

  // ==================== ADDRESS HELPERS ====================

  String _idOf(Map<String, dynamic> address) =>
      (address['addressId'] ?? address['id'] ?? '').toString();

  bool _isDefault(Map<String, dynamic> address) {
    final value = address['isDefault'];

    return value == true ||
        value.toString().toLowerCase() == 'true' ||
        value.toString() == '1';
  }

  Map<String, dynamic>? get _selectedAddress {
    for (final address in _addresses) {
      if (_idOf(address) == _selectedAddressId) {
        return address;
      }
    }
    return null;
  }

  String _addressText(Map<String, dynamic> address) {
    final parts = [
      address['addressLine'],
      address['house'],
      address['street'],
      address['area'],
      address['landmark'],
      address['city'],
      address['state'],
      address['pincode'],
    ]
        .where((value) =>
    value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString().trim())
        .toList();

    final uniqueParts = <String>[];

    for (final part in parts) {
      if (!uniqueParts.contains(part)) {
        uniqueParts.add(part);
      }
    }

    return uniqueParts.join(', ');
  }

  // ==================== LOAD ADDRESSES ====================

  Future<void> _loadAddresses() async {
    if (!mounted) return;

    setState(() {
      _loadingAddresses = true;
      _addressError = null;
    });

    try {
      final response =
      await EcoLoopApi.instance.get('/addresses');

      dynamic payload = response;

      if (payload is Map) {
        if (payload['success'] == false) {
          throw Exception(
            payload['message'] ??
                payload['error'] ??
                'Unable to load addresses.',
          );
        }

        payload = payload['data'] ??
            payload['addresses'] ??
            payload['items'] ??
            [];

        if (payload is Map) {
          payload =
              payload['addresses'] ?? payload['items'] ?? [];
        }
      }

      final addresses = payload is List
          ? payload
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => _idOf(e).isNotEmpty)
          .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      Map<String, dynamic>? preferred;

      for (final address in addresses) {
        if (_idOf(address) == _selectedAddressId) {
          preferred = address;
          break;
        }
      }

      if (preferred == null) {
        for (final address in addresses) {
          if (_isDefault(address)) {
            preferred = address;
            break;
          }
        }
      }

      preferred ??=
      addresses.isNotEmpty ? addresses.first : null;

      setState(() {
        _addresses = addresses;
        _selectedAddressId =
        preferred == null ? null : _idOf(preferred);
        _loadingAddresses = false;
        _addressError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingAddresses = false;
        _addressError =
            error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ==================== ADD ADDRESS ====================

  Future<void> _addAddress() async {
    if (_openingAddress) return;

    setState(() => _openingAddress = true);

    try {
      final savedAddress =
      await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute<Map<String, dynamic>>(
          builder: (_) => const AddAddress(),
        ),
      );

      if (!mounted) return;

      await _loadAddresses();

      if (savedAddress != null && mounted) {
        final returnedId = _idOf(savedAddress);

        if (returnedId.isNotEmpty &&
            _addresses.any(
                  (address) => _idOf(address) == returnedId,
            )) {
          setState(() => _selectedAddressId = returnedId);
        } else {
          for (final address in _addresses) {
            final matches =
                (address['name'] ?? '').toString() ==
                    (savedAddress['name'] ?? '').toString() &&
                    (address['phone'] ?? '').toString() ==
                        (savedAddress['phone'] ?? '').toString() &&
                    (address['pincode'] ?? '').toString() ==
                        (savedAddress['pincode'] ?? '').toString();

            if (matches) {
              setState(
                    () => _selectedAddressId = _idOf(address),
              );
              break;
            }
          }
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open address form: $error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingAddress = false);
      }
    }
  }

  // ==================== ADDRESS SELECTOR ====================

  Widget _buildPickupAddressSelector() {
    if (_loadingAddresses) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: _addressCardDecoration(),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_addressError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _addressCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Could not load saved pickup addresses.',
            ),
            const SizedBox(height: 5),
            Text(
              _addressError!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            TextButton.icon(
              onPressed: _loadAddresses,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_addresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _addressCardDecoration(),
            child: const Column(
              children: [
                Icon(
                  Icons.location_off_outlined,
                  size: 30,
                  color: AppColors.primary,
                ),
                SizedBox(height: 8),
                Text(
                  'No saved addresses yet',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Add a pickup address saved to your EcoLoop account.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._addresses.map(_pickupAddressCard),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _openingAddress ? null : _addAddress,
          icon: _openingAddress
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.add_location_alt_outlined),
          label: Text(
            _openingAddress
                ? 'Opening address form...'
                : 'Add new address',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 51),
            side: BorderSide(
              color: AppColors.primary.withOpacity(.45),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pickupAddressCard(Map<String, dynamic> address) {
    final selected = _idOf(address) == _selectedAddressId;

    final name =
    (address['name'] ?? address['fullName'] ?? '')
        .toString()
        .trim();

    final phone = (address['phone'] ?? '').toString().trim();

    final label =
    (address['label'] ?? address['type'] ?? 'Pickup address')
        .toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        boxShadow: selected
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(.07),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ]
            : [],
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.accent.withOpacity(.45),
          width: selected ? 1.7 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(19),
        onTap: () {
          setState(() => _selectedAddressId = _idOf(address));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isEmpty ? label : name,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (_isDefault(address))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: AppTextStyles.caption,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _addressText(address),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (address['landmark'] != null &&
                        address['landmark']
                            .toString()
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Landmark: ${address['landmark']}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _addressCardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(
        color: AppColors.accent.withOpacity(.45),
      ),
    );
  }

  // ==================== SUBMIT DONATION ====================

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_loadingCategories || _categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Categories are unavailable. Please retry loading categories.',
          ),
        ),
      );
      return;
    }

    final pickupAddress = _selectedAddress;

    if (pickupAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add and select a pickup address.',
          ),
        ),
      );
      return;
    }

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item photo.'),
        ),
      );
      return;
    }

    if (selectedCategory == null ||
        !categories.contains(selectedCategory)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a donation category.'),
        ),
      );
      return;
    }

    if (selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the item condition.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final category = _categories.firstWhere(
            (item) => item['name'].toString() == selectedCategory,
      );

      await EcoLoopApi.instance.post('/donations', {
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'categoryId': category['categoryId'],
        'condition': selectedCondition!
            .toLowerCase()
            .replaceAll(' ', '_'),
        'address': _addressText(pickupAddress),
        'city': (pickupAddress['city'] ?? '').toString().trim(),
        'state': (pickupAddress['state'] ?? '').toString().trim(),
        'pickupAddressId': _idOf(pickupAddress),
        'pickupAddress': Map<String, dynamic>.from(pickupAddress),
        'imageBase64': await EcoImagePicker.payload(_images),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation saved successfully.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}