import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import 'edit_listing.dart';

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
    _status = widget.listing['status']?.toString() ?? 'Active';
  }

  String get title =>
      widget.listing['title']?.toString() ?? 'Wooden Study Table';

  String get price => widget.listing['price']?.toString() ?? '₹2,500';

  String get condition => widget.listing['condition']?.toString() ?? 'Good';

  String get category => widget.listing['category']?.toString() ?? 'Furniture';

  String get views => widget.listing['views']?.toString() ?? '12 views';

  String get date => widget.listing['date']?.toString() ?? 'Listed recently';

  IconData get itemIcon =>
      widget.listing['icon'] as IconData? ?? Icons.inventory_2_outlined;

  @override
  Widget build(BuildContext context) {
    final isDraft = _status == 'Draft';
    final isSold = _status == 'Sold';
    final isActive = _status == 'Active';
    final isUnavailable = _status == 'Unavailable';

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),

        title: const Text(
          'Listing Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert_rounded),
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

                if (isDraft) _buildDraftInformation(),
              ],
            ),
          ),

          _buildBottomActions(),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT PREVIEW
  // ============================================================

  Widget _buildProductPreview() {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Container(
            height: 270,
            width: double.infinity,
            color: AppColors.light,
            child: Icon(itemIcon, size: 90, color: AppColors.primary),
          ),

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
                  style: const TextStyle(
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      views,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 18),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
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

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusSection() {
    return _section(
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_statusIcon(), color: _statusColor(), size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Listing Status',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _status,
                  style: TextStyle(
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
      default:
        return Icons.public_rounded;
    }
  }

  Color _statusColor() {
    switch (_status) {
      case 'Sold':
        return AppColors.success;
      case 'Draft':
        return Colors.orange;
      case 'Unavailable':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
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
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _statusColor(),
        ),
      ),
    );
  }

  // ============================================================
  // LISTING INFORMATION
  // ============================================================

  Widget _buildListingInformation() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Listing Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 17),

          _infoRow(Icons.category_outlined, 'Category', category),

          _infoRow(Icons.verified_outlined, 'Condition', condition),

          _infoRow(Icons.sell_outlined, 'Price', price),

          _infoRow(Icons.visibility_outlined, 'Views', views),

          _infoRow(Icons.calendar_today_outlined, 'Date', date),
        ],
      ),
    );
  }

  // ============================================================
  // PERFORMANCE
  // ============================================================

  Widget _buildPerformanceSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Listing Performance',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _performanceCard(
                  Icons.visibility_outlined,
                  views.replaceAll(' views', ''),
                  'Views',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _performanceCard(
                  Icons.favorite_border_rounded,
                  '4',
                  'Saved',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _performanceCard(
                  Icons.chat_bubble_outline_rounded,
                  '2',
                  'Enquiries',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _performanceCard(IconData icon, String value, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.light.withOpacity(0.65),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SOLD
  // ============================================================

  Widget _buildSoldInformation() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.light.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 23,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This item has been sold. You can view the sale '
                'and order information from your Selling Orders.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VISIBILITY
  // ============================================================

  Widget _buildVisibilityInformation() {
    return _section(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _status == 'Active'
                  ? 'Your listing is currently visible to buyers '
                        'in the EcoLoop Marketplace.'
                  : 'This listing is currently hidden from buyers. '
                        'You can make it available again anytime.',
              style: const TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DRAFT
  // ============================================================

  Widget _buildDraftInformation() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.edit_note_rounded, size: 20, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This listing is saved as a draft and is not visible '
                'in the Marketplace yet.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTIONS
  // ============================================================

  Widget _buildBottomActions() {
    final isDraft = _status == 'Draft';
    final isSold = _status == 'Sold';

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
          color: AppColors.surface,
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
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
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
                        : _status == 'Unavailable'
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 17,
                  ),
                  label: Text(
                    isDraft
                        ? 'Publish'
                        : _status == 'Unavailable'
                        ? 'Make Active'
                        : 'Hide',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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

  // ============================================================
  // ACTIONS
  // ============================================================

  void _editListing() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditListing(listing: widget.listing)),
    );
  }

  void _toggleAvailability() {
    setState(() {
      _status = _status == 'Unavailable' ? 'Active' : 'Unavailable';
    });

    _showMessage(
      _status == 'Active' ? 'Listing is now active.' : 'Listing is now hidden.',
    );
  }

  void _publishListing() {
    setState(() {
      _status = 'Active';
    });

    _showMessage('Listing published successfully.');
  }

  // ============================================================
  // MORE OPTIONS
  // ============================================================

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                _actionTile(
                  Icons.edit_outlined,
                  'Edit Listing',
                  'Update your listing details',
                  () {
                    Navigator.pop(context);
                    _editListing();
                  },
                ),

                if (_status != 'Sold')
                  _actionTile(
                    _status == 'Unavailable'
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    _status == 'Unavailable'
                        ? 'Make Active'
                        : 'Mark as Unavailable',
                    _status == 'Unavailable'
                        ? 'Show this listing to buyers'
                        : 'Temporarily hide this listing',
                    () {
                      Navigator.pop(context);
                      _toggleAvailability();
                    },
                  ),

                if (_status != 'Sold')
                  _actionTile(
                    Icons.delete_outline_rounded,
                    'Delete Listing',
                    'Permanently remove this listing',
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
              ? AppColors.error.withOpacity(0.10)
              : AppColors.light,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: destructive ? AppColors.error : AppColors.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: destructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      onTap: onTap,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Listing?'),
          content: Text(
            'Are you sure you want to permanently delete '
            '"$title"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                _showMessage('Delete will be connected later.');
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SECTION

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: child,
    );
  }


  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
