import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
import 'add_address.dart';

class AddressList extends StatefulWidget {
  const AddressList({super.key});

  @override
  State<AddressList> createState() => _AddressListState();
}

class _AddressListState extends State<AddressList> {
  bool _isLoading = false;
  bool _hasError = false;

  // Note: Temporary mock data for UI testing before Google Apps Script API integration.
  final List<AddressItem> _addresses = [
    AddressItem(
      id: '1',
      label: 'Home',
      fullName: 'Dishank Prajapati',
      phone: '+91 98765 43210',
      houseFlat: 'B-204',
      street: 'Shivam Residency',
      area: 'Satellite',
      landmark: 'Near ISRO Road',
      city: 'Ahmedabad',
      state: 'Gujarat',
      pincode: '380015',
      isDefault: true,
    ),
    AddressItem(
      id: '2',
      label: 'Work',
      fullName: 'Dishank Prajapati',
      phone: '+91 98765 43210',
      houseFlat: 'Office 302',
      street: 'Business Hub',
      area: 'Prahlad Nagar',
      landmark: 'Near Corporate Road',
      city: 'Ahmedabad',
      state: 'Gujarat',
      pincode: '380051',
      isDefault: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('My Addresses', style: AppTextStyles.title),
        actions: [
          if (_addresses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Refresh',
                onPressed: _loadAddresses,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: _addresses.isNotEmpty
          ? _buildBottomAddButton()
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    if (_hasError) {
      return _buildErrorState();
    }
    if (_addresses.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _loadAddresses,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
        children: [
          _buildIntro(),
          const SizedBox(height: 18),
          _buildDefaultAddressNotice(),
          const SizedBox(height: 18),
          ..._addresses.map(
            (address) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAddressCard(address),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Saved Addresses', style: AppTextStyles.heading),
        const SizedBox(height: 5),
        Text(
          'Manage your delivery addresses and choose where your orders should be delivered.',
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  Widget _buildDefaultAddressNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Default address',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your default address will be selected automatically during checkout.',
                  style: AppTextStyles.caption.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AddressItem address) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: address.isDefault
              ? AppColors.primary.withOpacity(0.55)
              : AppColors.accent.withOpacity(0.40),
          width: address.isDefault ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getAddressIcon(address.label),
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        _buildDefaultBadge(),
                      ],
                    ],
                  ),
                ),
                _buildMoreButton(address),
              ],
            ),
            const SizedBox(height: 15),
            Divider(height: 1, color: AppColors.accent.withOpacity(0.20)),
            const SizedBox(height: 14),
            Text(
              address.fullName,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(address.phone, style: AppTextStyles.caption),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textSecondary,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatAddress(address),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (!address.isDefault)
                  Expanded(
                    child: _buildSecondaryButton(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Set Default',
                      onPressed: () {
                        _setDefaultAddress(address);
                      },
                    ),
                  ),
                if (!address.isDefault) const SizedBox(width: 8),
                Expanded(
                  child: _buildSecondaryButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onPressed: () {
                      _showEditMessage(address);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'DEFAULT',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildMoreButton(AddressItem address) {
    return PopupMenuButton<String>(
      tooltip: 'Address options',
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.surface,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _showEditMessage(address);
            break;
          case 'default':
            _setDefaultAddress(address);
            break;
          case 'delete':
            _confirmDelete(address);
            break;
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 19, color: AppColors.primary),
                SizedBox(width: 10),
                Text(
                  'Edit Address',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                ),
              ],
            ),
          ),
          if (!address.isDefault)
            const PopupMenuItem<String>(
              value: 'default',
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 19,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Set as Default',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  ),
                ],
              ),
            ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: AppColors.error,
                ),
                SizedBox(width: 10),
                Text(
                  'Delete Address',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.accent.withOpacity(0.65)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAddButton() {
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
            onPressed: _showAddMessage,
            icon: const Icon(Icons.add_rounded, size: 21),
            label: const Text('Add New Address'),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _loadAddresses,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(24, 90, 24, 30),
        children: [
          Center(
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.location_off_outlined,
                color: AppColors.primary,
                size: 39,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Saved Addresses',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 19),
          ),
          const SizedBox(height: 7),
          Text(
            'Add an address to make checkout faster and easier.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 22),
          Center(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _showAddMessage,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Address'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
      children: [
        _skeleton(height: 30, width: 210),
        const SizedBox(height: 9),
        _skeleton(height: 18, width: double.infinity),
        const SizedBox(height: 18),
        _skeleton(height: 78, width: double.infinity),
        const SizedBox(height: 14),
        _skeleton(height: 245, width: double.infinity),
        const SizedBox(height: 12),
        _skeleton(height: 245, width: double.infinity),
      ],
    );
  }

  Widget _skeleton({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.20)),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 30),
      children: [
        Center(
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 17),
        Text(
          'Unable to Load Addresses',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          'Something went wrong while loading your saved addresses.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 18),
        Center(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _loadAddresses,
              child: const Text('Try Again'),
            ),
          ),
        ),
      ],
    );
  }

  // Note: Backend endpoint integration will be hooked up using ApiManager & Retrofit client.
  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  void _setDefaultAddress(AddressItem selectedAddress) {
    setState(() {
      for (final address in _addresses) {
        address.isDefault = address.id == selectedAddress.id;
      }
    });

    _showMessage('${selectedAddress.label} is now your default address.');
  }

  Future<void> _confirmDelete(AddressItem address) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Address?',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
          content: Text(
            'Are you sure you want to delete your ${address.label.toLowerCase()} address?',
            style: AppTextStyles.body.copyWith(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
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

    if (shouldDelete != true) return;
    if (!mounted) return;

    setState(() {
      _addresses.removeWhere((item) => item.id == address.id);

      // Reassign default address if the deleted one was default.
      if (address.isDefault && _addresses.isNotEmpty) {
        for (int i = 0; i < _addresses.length; i++) {
          _addresses[i].isDefault = i == 0;
        }
      }
    });

    _showMessage('${address.label} address deleted.');
  }

  void _showEditMessage(AddressItem address) {
    _showMessage(
      'Edit Address will open when the Add/Edit Address screen is completed.',
    );
  }

  void _showAddMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAddress()),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  IconData _getAddressIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.work_outline_rounded;
      case 'office':
        return Icons.business_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  String _formatAddress(AddressItem address) {
    final List<String> lines = [];

    if (address.houseFlat.trim().isNotEmpty) {
      lines.add(address.houseFlat.trim());
    }
    if (address.street.trim().isNotEmpty) {
      lines.add(address.street.trim());
    }
    if (address.area.trim().isNotEmpty) {
      lines.add(address.area.trim());
    }
    if (address.landmark.trim().isNotEmpty) {
      lines.add('Near ${address.landmark.trim()}');
    }

    lines.add('${address.city}, ${address.state} - ${address.pincode}');

    return lines.join(', ');
  }
}

class AddressItem {
  final String id;
  final String label;
  final String fullName;
  final String phone;
  final String houseFlat;
  final String street;
  final String area;
  final String landmark;
  final String city;
  final String state;
  final String pincode;

  bool isDefault;

  AddressItem({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.houseFlat,
    required this.street,
    required this.area,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
  });
}
