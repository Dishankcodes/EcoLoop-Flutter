import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import 'add_address.dart';

class AddressList extends StatefulWidget {
  const AddressList({super.key});

  @override
  State<AddressList> createState() => MyAddresses();
}

class MyAddresses extends State<AddressList> {
  // TEMPORARY UI DATA
  final List<AddressItem> _addresses = [
    AddressItem(
      id: '1',
      name: 'Creative Studio',
      phone: '9876543210',
      house: 'Studio 204, Green Heights',
      street: 'Satellite Road',
      area: 'Satellite',
      landmark: 'Near Iscon Mall',
      city: 'Ahmedabad',
      state: 'Gujarat',
      pincode: '380015',
      type: 'Studio',
      isDefault: true,
    ),
    AddressItem(
      id: '2',
      name: 'Creative Studio',
      phone: '9876543210',
      house: 'Workshop 302',
      street: 'C G Road',
      area: 'Navrangpura',
      landmark: 'Near Commerce Six Road',
      city: 'Ahmedabad',
      state: 'Gujarat',
      pincode: '380009',
      type: 'Workshop',
      isDefault: false,
    ),
  ];

  // ADD ADDRESS
  Future<void> _addAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAddress()),
    );
    if (!mounted) return;
    if (result == true) setState(() {});
  }

  // EDIT ADDRESS
  Future<void> _editAddress(AddressItem address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddAddress(address: address.toMap())),
    );
    if (!mounted) return;
    if (result == true) setState(() {});
  }

  // DELETE ADDRESS
  Future<void> _deleteAddress(AddressItem address) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ArtistColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Address?',
            style: ArtistTextStyles.title.copyWith(
              color: ArtistColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to remove this saved address?',
            style: ArtistTextStyles.body.copyWith(
              color: ArtistColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: ArtistTextStyles.body.copyWith(
                  color: ArtistColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: ArtistTextStyles.body.copyWith(
                  color: ArtistColors.error,
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
        backgroundColor: ArtistColors.success,
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
        backgroundColor: ArtistColors.success,
      ),
    );
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ArtistColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ArtistColors.textPrimary,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'My Addresses',
          style: ArtistTextStyles.title.copyWith(
            color: ArtistColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: _addresses.isEmpty
            ? _EmptyAddressState(onAddAddress: _addAddress)
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved addresses',
                      style: ArtistTextStyles.title.copyWith(
                        color: ArtistColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Manage your studio and workshop addresses for faster checkout.',
                      style: ArtistTextStyles.caption.copyWith(
                        color: ArtistColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._addresses.map(
                      (address) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _AddressCard(
                          address: address,
                          onEdit: () => _editAddress(address),
                          onDelete: () => _deleteAddress(address),
                          onSetDefault: () => _setDefaultAddress(address),
                        ),
                      ),
                    ),
                  ],
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
            child: ElevatedButton.icon(
              onPressed: _addAddress,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: Text(
                'Add New Address',
                style: ArtistTextStyles.body.copyWith(
                  color: ArtistColors.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: ArtistColors.background,
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
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: address.isDefault ? ArtistColors.primary : ArtistColors.border,
          width: address.isDefault ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _getAddressIcon(address.type),
                  color: ArtistColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
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
                            style: ArtistTextStyles.body.copyWith(
                              color: ArtistColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _AddressTypeBadge(type: address.type),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.phone,
                      style: ArtistTextStyles.caption.copyWith(
                        color: ArtistColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: ArtistColors.surface,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: ArtistColors.textSecondary,
                  size: 21,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                  if (value == 'default') onSetDefault();
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            color: ArtistColors.textPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Edit',
                            style: ArtistTextStyles.body.copyWith(
                              color: ArtistColors.textPrimary,
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
                            const Icon(
                              Icons.star_outline_rounded,
                              color: ArtistColors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Set as Default',
                              style: ArtistTextStyles.body.copyWith(
                                color: ArtistColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            color: ArtistColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: ArtistTextStyles.body.copyWith(
                              color: ArtistColors.error,
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
          Container(height: 1, color: ArtistColors.border),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: ArtistColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _buildFullAddress(),
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          if (address.isDefault) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: ArtistColors.success,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  'Default address',
                  style: ArtistTextStyles.caption.copyWith(
                    color: ArtistColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // FULL ADDRESS
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

  // ADDRESS ICON
  IconData _getAddressIcon(String type) {
    switch (type.toLowerCase()) {
      case 'workshop':
        return Icons.handyman_outlined;
      case 'studio':
        return Icons.palette_outlined;
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
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: ArtistTextStyles.caption.copyWith(
          color: ArtistColors.primary,
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
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: ArtistColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: ArtistColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No saved addresses',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.title.copyWith(
                color: ArtistColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your studio or workshop address to make '
              'product management and checkout easier.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body.copyWith(
                color: ArtistColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onAddAddress,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Add Address',
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.background,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtistColors.primary,
                  foregroundColor: ArtistColors.background,
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
