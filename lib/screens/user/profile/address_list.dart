import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import 'add_address.dart';

class AddressList extends StatefulWidget {
  const AddressList({super.key});

  @override
  State<AddressList> createState() => _AddressListState();
}

class _AddressListState extends State<AddressList> {
  // TEMPORARY UI DATA
  //
  // This is only for the UI phase.
  // Backend/API integration will replace this later.
  //

  final List<AddressItem> _addresses = [
    AddressItem(
      id: '1',
      name: 'Dishank Prajapati',
      phone: '9876543210',
      house: 'Flat 204, Green Heights',
      street: 'Satellite Road',
      area: 'Satellite',
      landmark: 'Near Iscon Mall',
      city: 'Ahmedabad',
      state: 'Gujarat',
      pincode: '380015',
      type: 'Home',
      isDefault: true,
    ),
    AddressItem(
      id: '2',
      name: 'Dishank Prajapati',
      phone: '9876543210',
      house: 'Office 302',
      street: 'C G Road',
      area: 'Navrangpura',
      landmark: 'Near Commerce Six Road',
      city: 'Ahmedabad',
      state: 'Gujarat',
      pincode: '380009',
      type: 'Work',
      isDefault: false,
    ),
  ];

  // ADD ADDRESS

  Future<void> _addAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAddress()),
    );

    // UI-only.
    //
    // Later this will refresh the address list from the backend.
    if (!mounted) return;

    if (result == true) {
      setState(() {});
    }
  }

  // EDIT ADDRESS

  Future<void> _editAddress(AddressItem address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddAddress(address: address.toMap())),
    );

    // UI-only.
    //
    // Later this will update the address through the backend.
    if (!mounted) return;

    if (result == true) {
      setState(() {});
    }
  }

  // DELETE ADDRESS

  Future<void> _deleteAddress(AddressItem address) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Address?',
            style: AppTextStyles.heading.copyWith(color: AppColors.textPrimary),
          ),
          content: Text(
            'Are you sure you want to remove this saved address?',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Cancel',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(
                'Delete',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _addresses.removeWhere((item) => item.id == address.id);
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Address deleted successfully'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  // SET DEFAULT

  void _setDefaultAddress(AddressItem address) {
    setState(() {
      for (final item in _addresses) {
        item.isDefault = item.id == address.id;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Default address updated'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // APP BAR
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),

        title: Text(
          'My Addresses',
          style: AppTextStyles.heading.copyWith(color: AppColors.textPrimary),
        ),
      ),

      // BODY
      body: SafeArea(
        child: _addresses.isEmpty
            ? _EmptyAddressState(onAddAddress: _addAddress)
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================================
                    // HEADER
                    Text(
                      'Saved addresses',
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Manage your delivery addresses for a faster checkout.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ADDRESS CARDS
                    ..._addresses.map(
                      (address) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _AddressCard(
                          address: address,
                          onEdit: () {
                            _editAddress(address);
                          },
                          onDelete: () {
                            _deleteAddress(address);
                          },
                          onSetDefault: () {
                            _setDefaultAddress(address);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),

      // ADD ADDRESS BUTTON
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.light)),
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addAddress,

              icon: const Icon(Icons.add_rounded, size: 22),

              label: Text(
                'Add New Address',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ADDRESS ITEM MODEL

class AddressItem {
  final String id;

  final String name;
  final String phone;

  final String house;
  final String street;
  final String area;
  final String landmark;

  final String city;
  final String state;
  final String pincode;

  final String type;

  bool isDefault;

  AddressItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.house,
    required this.street,
    required this.area,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.type,
    required this.isDefault,
  });

  // CONVERT TO MAP

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'house': house,
      'street': street,
      'area': area,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pincode,
      'type': type,
      'isDefault': isDefault,
    };
  }
}

// ADDRESS CARD

class _AddressCard extends StatelessWidget {
  final AddressItem address;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: address.isDefault ? AppColors.primary : AppColors.light,
          width: address.isDefault ? 1.4 : 1,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------------
          // TOP ROW
          // -------------------------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------------
              // ADDRESS TYPE ICON
              // ---------------------------------------------------------------
              Container(
                width: 44,
                height: 44,

                decoration: BoxDecoration(
                  color: AppColors.light,

                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(
                  _getAddressIcon(address.type),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // ---------------------------------------------------------------
              // NAME + TYPE
              // ---------------------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            address.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        _AddressTypeBadge(type: address.type),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      address.phone,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // ---------------------------------------------------------------
              // MORE MENU
              // ---------------------------------------------------------------
              PopupMenuButton<String>(
                color: AppColors.surface,

                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  }

                  if (value == 'delete') {
                    onDelete();
                  }

                  if (value == 'default') {
                    onSetDefault();
                  }
                },

                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),

                          const SizedBox(width: 10),

                          Text(
                            'Edit',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (!address.isDefault)
                      PopupMenuItem(
                        value: 'default',
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_outline_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),

                            const SizedBox(width: 10),

                            Text(
                              'Set as Default',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),

                          const SizedBox(width: 10),

                          Text(
                            'Delete',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // -------------------------------------------------------------------
          // DIVIDER
          // -------------------------------------------------------------------
          Container(height: 1, color: AppColors.light),

          const SizedBox(height: 15),

          // -------------------------------------------------------------------
          // FULL ADDRESS
          // -------------------------------------------------------------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  _buildFullAddress(),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // -------------------------------------------------------------------
          // DEFAULT BADGE
          // -------------------------------------------------------------------
          if (address.isDefault)
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 17,
                ),

                const SizedBox(width: 6),

                Text(
                  'Default address',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _buildFullAddress() {
    final parts = <String>[
      address.house,
      address.street,
      address.area,
      if (address.landmark.trim().isNotEmpty) address.landmark,
      address.city,
      address.state,
      address.pincode,
    ];

    return parts.join(', ');
  }

  IconData _getAddressIcon(String type) {
    switch (type.toLowerCase()) {
      case 'work':
        return Icons.work_outline_rounded;

      case 'other':
        return Icons.location_on_outlined;

      case 'home':
      default:
        return Icons.home_outlined;
    }
  }
}

// ADDRESS TYPE BADGE

class _AddressTypeBadge extends StatelessWidget {
  final String type;

  const _AddressTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: AppColors.light,

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        type,

        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// EMPTY STATE

class _EmptyAddressState extends StatelessWidget {
  final VoidCallback onAddAddress;

  const _EmptyAddressState({required this.onAddAddress});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // -----------------------------------------------------------------
            // ICON
            // -----------------------------------------------------------------
            Container(
              width: 82,
              height: 82,

              decoration: BoxDecoration(
                color: AppColors.light,

                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),

            const SizedBox(height: 20),

            // -----------------------------------------------------------------
            // TITLE
            // -----------------------------------------------------------------
            Text(
              'No saved addresses',
              textAlign: TextAlign.center,

              style: AppTextStyles.title.copyWith(color: AppColors.textPrimary),
            ),

            const SizedBox(height: 8),

            // -----------------------------------------------------------------
            // DESCRIPTION
            // -----------------------------------------------------------------
            Text(
              'Add your first delivery address to make checkout faster and easier.',
              textAlign: TextAlign.center,

              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 24),

            // ADD BUTTON
            SizedBox(
              height: 50,

              child: ElevatedButton.icon(
                onPressed: onAddAddress,

                icon: const Icon(Icons.add_rounded),

                label: Text(
                  'Add Address',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,

                  foregroundColor: AppColors.surface,

                  elevation: 0,

                  padding: const EdgeInsets.symmetric(horizontal: 22),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
