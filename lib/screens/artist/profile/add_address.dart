import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class AddAddress extends StatefulWidget {
  final Map<String, dynamic>? address;

  const AddAddress({super.key, this.address});

  bool get isEditing => address != null;

  @override
  State<AddAddress> createState() => _AddAddressState();
}

class _AddAddressState extends State<AddAddress> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _houseController;
  late final TextEditingController _streetController;
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

  String _addressType = 'Studio';
  bool _isDefault = false;
  bool _isSaving = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _nameController = TextEditingController(
      text: address?['name']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: address?['phone']?.toString() ?? '',
    );
    _houseController = TextEditingController(
      text: address?['house']?.toString() ?? '',
    );
    _streetController = TextEditingController(
      text: address?['street']?.toString() ?? '',
    );
    _areaController = TextEditingController(
      text: address?['area']?.toString() ?? '',
    );
    _landmarkController = TextEditingController(
      text: address?['landmark']?.toString() ?? '',
    );
    _cityController = TextEditingController(
      text: address?['city']?.toString() ?? '',
    );
    _stateController = TextEditingController(
      text: address?['state']?.toString() ?? '',
    );
    _pincodeController = TextEditingController(
      text: address?['pincode']?.toString() ?? '',
    );
    final savedType = address?['type']?.toString();
    if (savedType == 'Studio' ||
        savedType == 'Workshop' ||
        savedType == 'Other') {
      _addressType = savedType!;
    }
    _isDefault = address?['isDefault'] == true;
  }

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

  // CURRENT LOCATION
  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() {
      _isGettingLocation = true;
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _isGettingLocation = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Current location will be connected later.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // SAVE ADDRESS
  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });
    final result = {
      'id':
          widget.address?['id'] ??
          'address_${DateTime.now().millisecondsSinceEpoch}',
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'house': _houseController.text.trim(),
      'street': _streetController.text.trim(),
      'area': _areaController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'type': _addressType,
      'isDefault': _isDefault,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? 'Address updated successfully'
              : 'Address saved successfully',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ArtistColors.success,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pop(context, result);
  }

  // VALIDATORS
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
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _pincodeValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }

  // INPUT STYLE
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: ArtistColors.primary),
      filled: true,
      fillColor: ArtistColors.surface,
      labelStyle: ArtistTextStyles.caption.copyWith(
        color: ArtistColors.textSecondary,
      ),
      hintStyle: ArtistTextStyles.body.copyWith(
        color: ArtistColors.textSecondary.withOpacity(0.7),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: ArtistColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: ArtistColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ArtistColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ArtistColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ArtistColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ArtistColors.textPrimary,
            size: 20,
          ),
        ),
        title: Text(
          widget.isEditing ? 'Edit Address' : 'Add Address',
          style: ArtistTextStyles.title.copyWith(
            color: ArtistColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing
                      ? 'Update your address'
                      : 'Add a new address',
                  style: ArtistTextStyles.title.copyWith(
                    color: ArtistColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isEditing
                      ? 'Make changes to your saved studio or workshop address.'
                      : 'Add your studio or workshop details for smoother orders.',
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                _LocationCard(
                  isLoading: _isGettingLocation,
                  onPressed: _useCurrentLocation,
                ),
                const SizedBox(height: 18),
                _FormCard(
                  title: 'Contact Information',
                  icon: Icons.person_outline_rounded,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      validator: _requiredValidator,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        label: 'Name',
                        hint: 'Enter studio or owner name',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      validator: _phoneValidator,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: _inputDecoration(
                        label: 'Phone Number',
                        hint: 'Enter 10-digit phone number',
                        icon: Icons.phone_outlined,
                      ).copyWith(counterText: ''),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _FormCard(
                  title: 'Address Details',
                  icon: Icons.location_on_outlined,
                  children: [
                    TextFormField(
                      controller: _houseController,
                      validator: _requiredValidator,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        label: 'Studio / Building',
                        hint: 'e.g. Studio 204, Green Heights',
                        icon: Icons.home_work_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _streetController,
                      validator: _requiredValidator,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        label: 'Street / Society',
                        hint: 'Enter street or society name',
                        icon: Icons.signpost_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _areaController,
                      validator: _requiredValidator,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        label: 'Area',
                        hint: 'Enter area or locality',
                        icon: Icons.location_city_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _landmarkController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(
                        label: 'Landmark',
                        hint: 'Optional',
                        icon: Icons.flag_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            validator: _requiredValidator,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              label: 'City',
                              hint: 'City',
                              icon: Icons.location_city_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            validator: _requiredValidator,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              label: 'State',
                              hint: 'State',
                              icon: Icons.map_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pincodeController,
                      validator: _pincodeValidator,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: _inputDecoration(
                        label: 'Pincode',
                        hint: 'Enter 6-digit pincode',
                        icon: Icons.pin_drop_outlined,
                      ).copyWith(counterText: ''),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _FormCard(
                  title: 'Address Type',
                  icon: Icons.label_outline_rounded,
                  children: [
                    Text(
                      'Choose a label for this address',
                      style: ArtistTextStyles.body.copyWith(
                        color: ArtistColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _AddressTypeButton(
                            label: 'Studio',
                            icon: Icons.palette_outlined,
                            selected: _addressType == 'Studio',
                            onTap: () {
                              setState(() {
                                _addressType = 'Studio';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AddressTypeButton(
                            label: 'Workshop',
                            icon: Icons.handyman_outlined,
                            selected: _addressType == 'Workshop',
                            onTap: () {
                              setState(() {
                                _addressType = 'Workshop';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AddressTypeButton(
                            label: 'Other',
                            icon: Icons.location_on_outlined,
                            selected: _addressType == 'Other',
                            onTap: () {
                              setState(() {
                                _addressType = 'Other';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _DefaultAddressCard(
                  value: _isDefault,
                  onChanged: (value) {
                    setState(() {
                      _isDefault = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: ArtistColors.background,
            border: Border(top: BorderSide(color: ArtistColors.border)),
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: ArtistColors.background,
                disabledBackgroundColor: ArtistColors.primary.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: ArtistColors.background,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isEditing
                              ? Icons.check_rounded
                              : Icons.save_outlined,
                          size: 21,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isEditing ? 'Update Address' : 'Save Address',
                          style: ArtistTextStyles.body.copyWith(
                            color: ArtistColors.background,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// LOCATION CARD
class _LocationCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LocationCard({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: ArtistColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use Current Location',
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Automatically fill your address details',
                  style: ArtistTextStyles.caption.copyWith(
                    color: ArtistColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: ArtistColors.primary,
                side: const BorderSide(color: ArtistColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 13),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ArtistColors.primary,
                      ),
                    )
                  : const Text('Use'),
            ),
          ),
        ],
      ),
    );
  }
}

// FORM CARD
class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ArtistColors.primary, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: ArtistTextStyles.title.copyWith(
                    color: ArtistColors.textPrimary,
                    fontSize: 17,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

// ADDRESS TYPE BUTTON
class _AddressTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AddressTypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? ArtistColors.light : ArtistColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? ArtistColors.primary : ArtistColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected
                  ? ArtistColors.primary
                  : ArtistColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: ArtistTextStyles.caption.copyWith(
                color: selected
                    ? ArtistColors.primary
                    : ArtistColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DEFAULT ADDRESS CARD
class _DefaultAddressCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DefaultAddressCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.star_outline_rounded,
              color: ArtistColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set as default address',
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Use this address automatically for orders.',
                  style: ArtistTextStyles.caption.copyWith(
                    color: ArtistColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: ArtistColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
