import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import 'edit_product.dart';

class ListingDetails extends StatefulWidget {
  final Map<String, dynamic> listing;

  const ListingDetails({super.key, required this.listing});

  @override
  State<ListingDetails> createState() => _ListingDetailsState();
}

class _ListingDetailsState extends State<ListingDetails> {
  late String _status;

  @override
  void initState() {
    super.initState();

    _status = _normalizeStatus(widget.listing['status']?.toString());
  }

  String _normalizeStatus(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'active':
        return 'Active';

      case 'pending':
        return 'Pending';

      case 'inactive':
        return 'Unavailable';

      case 'sold':
      case 'sold out':
        return 'Sold';

      case 'draft':
        return 'Draft';

      default:
        return 'Active';
    }
  }

  String get title =>
      widget.listing['title']?.toString() ?? 'Handcrafted Product';

  String get price {
    final value = widget.listing['price'];

    if (value == null) return '₹0';

    final parsed = double.tryParse(value.toString()) ?? 0;

    if (parsed == parsed.roundToDouble()) {
      return '₹${parsed.toInt()}';
    }

    return '₹${parsed.toStringAsFixed(2)}';
  }

  String get condition => widget.listing['condition']?.toString() ?? 'Good';

  String get category =>
      widget.listing['category']?.toString() ?? 'Home & Decor';

  String get description =>
      widget.listing['description']?.toString() ??
      'No description available for this product.';

  String get productId => widget.listing['productId']?.toString() ?? 'PRD001';

  String get views => '${widget.listing['views']?.toString() ?? '0'} views';

  String get wishlistCount =>
      widget.listing['wishlistCount']?.toString() ?? '0';

  String get salesCount => widget.listing['salesCount']?.toString() ?? '0';

  String get quantity => widget.listing['quantity']?.toString() ?? '0';

  String get availableQuantity =>
      widget.listing['availableQuantity']?.toString() ?? '0';

  String get date =>
      widget.listing['createdAt']?.toString() ?? 'Listed recently';

  String get imageUrl => widget.listing['image']?.toString() ?? '';

  bool get isSold => _status == 'Sold';

  bool get isDraft => _status == 'Draft';

  bool get isUnavailable => _status == 'Unavailable';

  bool get isActive => _status == 'Active';

  bool get isPending => _status == 'Pending';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
        ),
        title: Text(
          'Listing Details',
          style: ArtistTextStyles.title.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: ArtistColors.textPrimary,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 105),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductPreview(),
                _buildStatusSection(),
                _buildListingInformation(),
                _buildPerformanceSection(),

                if (isSold) _buildSoldInformation(),

                if (isActive || isUnavailable) _buildVisibilityInformation(),

                if (isPending) _buildPendingInformation(),

                if (isDraft) _buildDraftInformation(),
              ],
            ),
          ),

          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildProductPreview() {
    return Container(
      color: ArtistColors.surface,
      child: Column(
        children: [
          _buildProductImage(),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTag(condition, Icons.verified_outlined),
                    const SizedBox(width: 8),
                    _buildTag(category, Icons.category_outlined),
                  ],
                ),

                const SizedBox(height: 14),

                Text(
                  title,
                  style: ArtistTextStyles.heading.copyWith(
                    fontSize: 23,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  price,
                  style: ArtistTextStyles.title.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: ArtistColors.primary,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: ArtistColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(views, style: ArtistTextStyles.small),

                    const SizedBox(width: 18),

                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: ArtistColors.textSecondary,
                    ),
                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ArtistTextStyles.small,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    if (imageUrl.isEmpty) {
      return Container(
        height: 270,
        width: double.infinity,
        color: ArtistColors.light,
        child: const Icon(
          Icons.inventory_2_outlined,
          size: 90,
          color: ArtistColors.primary,
        ),
      );
    }

    return SizedBox(
      height: 270,
      width: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            color: ArtistColors.light,
            child: const Icon(
              Icons.image_not_supported_outlined,
              size: 70,
              color: ArtistColors.primary,
            ),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Container(
            color: ArtistColors.light,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ArtistColors.primary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ArtistColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: ArtistTextStyles.small.copyWith(
              color: ArtistColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return _section(
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: _statusColor().withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_statusIcon(), color: _statusColor(), size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Listing Status', style: ArtistTextStyles.small),
                const SizedBox(height: 3),
                Text(
                  _status,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(),
                  ),
                ),
              ],
            ),
          ),

          _buildStatusChip(),
        ],
      ),
    );
  }

  IconData _statusIcon() {
    switch (_status) {
      case 'Sold':
        return Icons.check_circle_outline_rounded;

      case 'Draft':
        return Icons.edit_note_rounded;

      case 'Unavailable':
        return Icons.visibility_off_outlined;

      case 'Pending':
        return Icons.pending_outlined;

      default:
        return Icons.public_rounded;
    }
  }

  Color _statusColor() {
    switch (_status) {
      case 'Sold':
        return ArtistColors.success;

      case 'Draft':
        return ArtistColors.warning;

      case 'Pending':
        return ArtistColors.warning;

      case 'Unavailable':
        return ArtistColors.textSecondary;

      default:
        return ArtistColors.primary;
    }
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor().withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _status,
        style: ArtistTextStyles.small.copyWith(
          fontWeight: FontWeight.w600,
          color: _statusColor(),
        ),
      ),
    );
  }

  Widget _buildListingInformation() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listing Information',
            style: ArtistTextStyles.title.copyWith(fontSize: 17),
          ),

          const SizedBox(height: 17),

          _infoRow(Icons.inventory_2_outlined, 'Product ID', productId),

          _infoRow(Icons.category_outlined, 'Category', category),

          _infoRow(Icons.verified_outlined, 'Condition', condition),

          _infoRow(Icons.sell_outlined, 'Price', price),

          _infoRow(Icons.inventory_outlined, 'Quantity', quantity),

          _infoRow(Icons.inventory_2_outlined, 'Available', availableQuantity),

          _infoRow(Icons.visibility_outlined, 'Views', views),

          _infoRow(Icons.calendar_today_outlined, 'Listed On', date),

          const SizedBox(height: 3),

          Text('Description', style: ArtistTextStyles.label),

          const SizedBox(height: 7),

          Text(description, style: ArtistTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listing Performance',
            style: ArtistTextStyles.title.copyWith(fontSize: 17),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _performanceCard(
                  Icons.visibility_outlined,
                  widget.listing['views']?.toString() ?? '0',
                  'Views',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _performanceCard(
                  Icons.favorite_border_rounded,
                  wishlistCount,
                  'Saved',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _performanceCard(
                  Icons.shopping_bag_outlined,
                  salesCount,
                  'Sales',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: ArtistColors.surfaceSoft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 19, color: ArtistColors.primary),

          const SizedBox(height: 7),

          Text(
            value,
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          Text(label, style: ArtistTextStyles.small.copyWith(fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildSoldInformation() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ArtistColors.success.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: ArtistColors.success,
              size: 23,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                'This item has been sold. You can view the sale '
                'and order information from your Selling Orders.',
                style: ArtistTextStyles.body.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityInformation() {
    return _section(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: ArtistColors.primary,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              isActive
                  ? 'Your listing is currently visible to buyers '
                        'in the EcoLoop Marketplace.'
                  : 'This listing is currently hidden from buyers. '
                        'You can make it available again anytime.',
              style: ArtistTextStyles.body.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInformation() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ArtistColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.pending_outlined,
              size: 20,
              color: ArtistColors.warning,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                'This product is currently pending and may not '
                'be visible to buyers until it becomes active.',
                style: ArtistTextStyles.body.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftInformation() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ArtistColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.edit_note_rounded,
              size: 20,
              color: ArtistColors.warning,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                'This listing is saved as a draft and is not '
                'visible in the Marketplace yet.',
                style: ArtistTextStyles.body.copyWith(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    if (isSold) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 15),
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editListing,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ArtistColors.primary,
                    backgroundColor: ArtistColors.background,
                    side: const BorderSide(color: ArtistColors.primary),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isDraft ? _publishListing : _toggleAvailability,
                  icon: Icon(
                    isDraft
                        ? Icons.publish_outlined
                        : isUnavailable
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 17,
                  ),
                  label: Text(
                    isDraft
                        ? 'Publish'
                        : isUnavailable
                        ? 'Make Active'
                        : 'Hide',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArtistColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editListing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProduct(product: widget.listing)),
    );
  }

  void _toggleAvailability() {
    setState(() {
      _status = isUnavailable ? 'Active' : 'Unavailable';
    });

    _showMessage(
      isActive ? 'Listing is now active.' : 'Listing is now hidden.',
    );
  }

  void _publishListing() {
    setState(() {
      _status = 'Active';
    });

    _showMessage('Listing published successfully.');
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 42,
                  decoration: BoxDecoration(
                    color: ArtistColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                _actionTile(
                  Icons.edit_outlined,
                  'Edit Listing',
                  'Update your product details',
                  () {
                    Navigator.pop(context);
                    _editListing();
                  },
                ),

                if (!isSold)
                  _actionTile(
                    isUnavailable
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    isUnavailable ? 'Make Active' : 'Mark as Unavailable',
                    isUnavailable
                        ? 'Show this listing to buyers'
                        : 'Temporarily hide this listing',
                    () {
                      Navigator.pop(context);
                      _toggleAvailability();
                    },
                  ),

                if (!isSold)
                  _actionTile(
                    Icons.delete_outline_rounded,
                    'Delete Product',
                    'Permanently remove this product',
                    () {
                      Navigator.pop(context);
                      _confirmDelete();
                    },
                    destructive: true,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 3),
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: destructive
              ? ArtistColors.error.withOpacity(0.10)
              : ArtistColors.light,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: destructive ? ArtistColors.error : ArtistColors.primary,
        ),
      ),
      title: Text(
        title,
        style: ArtistTextStyles.bodyMedium.copyWith(
          color: destructive ? ArtistColors.error : ArtistColors.textPrimary,
        ),
      ),
      subtitle: Text(subtitle, style: ArtistTextStyles.small),
      onTap: onTap,
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ArtistColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Delete Product?',
            style: ArtistTextStyles.title.copyWith(fontSize: 20),
          ),
          content: Text(
            'Are you sure you want to delete "$title"?\n\n'
            'This action cannot be undone.',
            style: ArtistTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _showMessage('Delete will be connected later.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ArtistColors.primary),

          const SizedBox(width: 10),

          Text(title, style: ArtistTextStyles.small.copyWith(fontSize: 11.5)),

          const Spacer(),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: ArtistTextStyles.bodyMedium.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      color: ArtistColors.surface,
      child: child,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: ArtistTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: ArtistColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
