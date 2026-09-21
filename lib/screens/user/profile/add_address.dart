import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';

class AddAddress extends StatefulWidget {
  const AddAddress({super.key});

  @override
  State<AddAddress> createState() => _AddAddressState();
}

class _AddAddressState extends State<AddAddress> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _isSaving = false;
  bool _locationLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text('Add Address', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Form(key: _formKey, child: _buildBody()),
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 7, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntro(),
          const SizedBox(height: 18),
          _buildLocationCard(),
          const SizedBox(height: 22),
          _buildSectionTitle('Contact Information'),
          const SizedBox(height: 11),
          _buildContactCard(),
          const SizedBox(height: 22),
          _buildSectionTitle('Address Details'),
          const SizedBox(height: 11),
          _buildAddressDetailsCard(),
          const SizedBox(height: 22),
          _buildSectionTitle('Address Type'),
          const SizedBox(height: 11),
          _buildAddressTypeCard(),
          const SizedBox(height: 22),
          _buildDefaultAddressCard(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add a New Address', style: AppTextStyles.heading),
        const SizedBox(height: 5),
        Text(
          'Save your delivery details for a faster and easier checkout experience.',
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.55)),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use Current Location',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Automatically fill your location details',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: _useCurrentLocation,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.55)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _locationLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Text(
                      'Use',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
    );
  }

  Widget _buildContactCard() {
    return _FormCard(
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter your phone number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: _phoneValidator,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDetailsCard() {
    return _FormCard(
      child: Column(
        children: [
          _buildTextField(
            controller: _houseController,
            label: 'House / Flat',
            hint: 'e.g. B-204',
            icon: Icons.home_outlined,
            textCapitalization: TextCapitalization.words,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _streetController,
            label: 'Street / Society',
            hint: 'Enter street or society name',
            icon: Icons.signpost_outlined,
            textCapitalization: TextCapitalization.words,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _areaController,
            label: 'Area',
            hint: 'Enter your area',
            icon: Icons.location_city_outlined,
            textCapitalization: TextCapitalization.words,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _landmarkController,
            label: 'Landmark',
            hint: 'e.g. Near City Mall',
            icon: Icons.place_outlined,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _cityController,
            label: 'City',
            hint: 'Enter your city',
            icon: Icons.location_city_rounded,
            textCapitalization: TextCapitalization.words,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _stateController,
            label: 'State',
            hint: 'Enter your state',
            icon: Icons.map_outlined,
            textCapitalization: TextCapitalization.words,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _pincodeController,
            label: 'Pincode',
            hint: 'Enter 6-digit pincode',
            icon: Icons.markunread_mailbox_outlined,
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: _pincodeValidator,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTypeCard() {
    return _FormCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save this address as',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AddressTypeButton(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  selected: _selectedLabel == 'Home',
                  onTap: () {
                    setState(() {
                      _selectedLabel = 'Home';
                    });
                  },
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _AddressTypeButton(
                  icon: Icons.work_outline_rounded,
                  label: 'Work',
                  selected: _selectedLabel == 'Work',
                  onTap: () {
                    setState(() {
                      _selectedLabel = 'Work';
                    });
                  },
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _AddressTypeButton(
                  icon: Icons.location_on_outlined,
                  label: 'Other',
                  selected: _selectedLabel == 'Other',
                  onTap: () {
                    setState(() {
                      _selectedLabel = 'Other';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAddressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.42)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set as Default Address',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Use this address automatically during checkout',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: _isDefault,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _isDefault = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      validator: validator,
      style: AppTextStyles.body.copyWith(
        color: AppColors.textPrimary,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        counterText: '',
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary.withOpacity(0.60),
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        errorStyle: const TextStyle(fontSize: 10, height: 1.2),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAddress,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: Text(_isSaving ? 'Saving Address...' : 'Save Address'),
          ),
        ),
      ),
    );
  }

  // Note: Current location feature will be connected to GPS/geocoding API later.
  Future<void> _useCurrentLocation() async {
    setState(() {
      _locationLoading = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      _locationLoading = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Current location will be connected later.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // Note: Save address endpoint integration via ApiManager and Retrofit will be connected later.
  Future<void> _saveAddress() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Address UI is ready. Backend connection will be added later.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final String phone = value.trim();
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _pincodeValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }

    final String pincode = value.trim();
    if (!RegExp(r'^[0-9]{6}$').hasMatch(pincode)) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _FormCard({
    required this.child,
    this.padding = const EdgeInsets.all(15),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.accent.withOpacity(0.42)),
      ),
      child: child,
    );
  }
}

class _AddressTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AddressTypeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.light : AppColors.background,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.accent.withOpacity(0.42),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 21,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
