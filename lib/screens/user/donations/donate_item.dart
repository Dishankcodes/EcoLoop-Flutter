import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/eco_image_picker.dart';
import '../../../services/ecoloop_api.dart';
import 'donation_data_cache.dart';
import '../profile/add_address.dart';

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
  List<SelectedEcoImage> _images = [];
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;
  bool _loadingAddresses = true;
  bool _openingAddress = false;
  String? _addressError;

  String? selectedCategory;
  String? selectedCondition;
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;
  bool _categoriesRequestInFlight = false;
  bool _addressesRequestInFlight = false;
  String? _categoryLoadError;

  List<String> get categories => _categories
      .map((category) => category['name']?.toString() ?? '')
      .where((name) => name.trim().isNotEmpty)
      .toList();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadAddresses();
  }

  Future<void> _loadCategories() async {
    if (_categoriesRequestInFlight) return;
    _categoriesRequestInFlight = true;
    try {
      final response = await EcoLoopApi.instance.get('/categories');
      final rows = response is List
          ? response
          : response is Map && response['categories'] is List
          ? response['categories'] as List
          : <dynamic>[];
      final parsed = rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .where((row) => row['categoryId'] != null && row['name'] != null)
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
        _categoryLoadError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      _categoriesRequestInFlight = false;
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
            if (_loadingCategories)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              )
            else if (_categoryLoadError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _categoryLoadError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadCategories,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
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
            _buildPickupAddressSelector(),
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
      if (_idOf(address) == _selectedAddressId) return address;
    }
    return null;
  }

  String _addressText(Map<String, dynamic> address) {
    final parts =
        [
              address['addressLine'],
              address['house'],
              address['street'],
              address['area'],
              address['landmark'],
              address['city'],
              address['state'],
              address['pincode'],
            ]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .map((value) => value.toString().trim())
            .toList();

    final uniqueParts = <String>[];
    for (final part in parts) {
      if (!uniqueParts.contains(part)) uniqueParts.add(part);
    }
    return uniqueParts.join(', ');
  }

  Future<void> _loadAddresses() async {
    if (!mounted || _addressesRequestInFlight) return;
    _addressesRequestInFlight = true;
    setState(() {
      _loadingAddresses = true;
      _addressError = null;
    });

    try {
      final response = await EcoLoopApi.instance.get('/addresses');
      dynamic payload = response;

      if (payload is Map) {
        if (payload['success'] == false) {
          throw Exception(
            payload['message'] ??
                payload['error'] ??
                'Unable to load addresses.',
          );
        }
        payload =
            payload['data'] ?? payload['addresses'] ?? payload['items'] ?? [];
        if (payload is Map) {
          payload = payload['addresses'] ?? payload['items'] ?? [];
        }
      }

      final addresses = payload is List
          ? payload
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .where((item) => _idOf(item).isNotEmpty)
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
      preferred ??= addresses.isNotEmpty ? addresses.first : null;

      setState(() {
        _addresses = addresses;
        _selectedAddressId = preferred == null ? null : _idOf(preferred);
        _loadingAddresses = false;
        _addressError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingAddresses = false;
        _addressError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      _addressesRequestInFlight = false;
    }
  }

  Future<void> _addAddress() async {
    if (_openingAddress) return;
    setState(() => _openingAddress = true);

    try {
      final savedAddress = await Navigator.push<Map<String, dynamic>>(
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
            _addresses.any((address) => _idOf(address) == returnedId)) {
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
              setState(() => _selectedAddressId = _idOf(address));
              break;
            }
          }
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open address form: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingAddress = false);
    }
  }

  Widget _buildPickupAddressSelector() {
    if (_loadingAddresses) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: _addressCardDecoration(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_addressError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _addressCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Could not load saved pickup addresses.'),
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
            _openingAddress ? 'Opening address form…' : 'Add new address',
          ),
        ),
      ],
    );
  }

  Widget _pickupAddressCard(Map<String, dynamic> address) {
    final selected = _idOf(address) == _selectedAddressId;
    final name = (address['name'] ?? address['fullName'] ?? '')
        .toString()
        .trim();
    final phone = (address['phone'] ?? '').toString().trim();
    final label = (address['label'] ?? address['type'] ?? 'Pickup address')
        .toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.accent.withOpacity(0.45),
          width: selected ? 1.7 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedAddressId = _idOf(address)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.textSecondary,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
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
                      Text(phone, style: AppTextStyles.caption),
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
                        address['landmark'].toString().trim().isNotEmpty)
                      const SizedBox(height: 3),
                    if (address['landmark'] != null &&
                        address['landmark'].toString().trim().isNotEmpty)
                      Text(
                        'Landmark: ${address['landmark']}',
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _addressCardDecoration() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.accent.withOpacity(0.45)),
  );

  Future<void> _submitDonation() async {
    if (_isSubmitting) return;
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
          content: Text('Please add and select a pickup address.'),
        ),
      );
      return;
    }
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
        'categoryId': _categories.firstWhere(
          (category) => category['name'].toString() == selectedCategory,
          orElse: () => <String, dynamic>{},
        )['categoryId'],
        'condition': (selectedCondition ?? 'used').toLowerCase().replaceAll(
          ' ',
          '_',
        ),
        'address': _addressText(pickupAddress),
        'city': (pickupAddress['city'] ?? '').toString().trim(),
        'state': (pickupAddress['state'] ?? '').toString().trim(),
        'pickupAddressId': _idOf(pickupAddress),
        'pickupAddress': Map<String, dynamic>.from(pickupAddress),
        'imageBase64': await EcoImagePicker.payload(_images),
      });
      DonationDataCache.clear();
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
