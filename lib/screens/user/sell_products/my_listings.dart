import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import 'edit_listing.dart';
import 'listing_details.dart';

class MyListings extends StatefulWidget {
  const MyListings({super.key});

  @override
  State<MyListings> createState() => _MyListingsState();
}

class _MyListingsState extends State<MyListings>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> listings = [
    {
      'title': 'Wooden Study Table',
      'price': '₹2,500',
      'condition': 'Good',
      'category': 'Furniture',
      'status': 'Active',
      'views': '12 views',
      'date': 'Listed 28 Aug 2026',
      'icon': Icons.table_restaurant_outlined,
    },
    {
      'title': 'Desk Lamp',
      'price': '₹650',
      'condition': 'Like New',
      'category': 'Home & Decor',
      'status': 'Active',
      'views': '8 views',
      'date': 'Listed 31 Aug 2026',
      'icon': Icons.light_outlined,
    },
    {
      'title': 'Old Wooden Chair',
      'price': '₹1,200',
      'condition': 'Used',
      'category': 'Furniture',
      'status': 'Sold',
      'views': '24 views',
      'date': 'Sold 27 Aug 2026',
      'icon': Icons.chair_outlined,
    },
    {
      'title': 'Canvas Art Frame',
      'price': '₹900',
      'condition': 'Good',
      'category': 'Home & Decor',
      'status': 'Active',
      'views': '5 views',
      'date': 'Listed 01 Sep 2026',
      'icon': Icons.image_outlined,
    },
    {
      'title': 'Glass Bottle Collection',
      'price': '₹450',
      'condition': 'Good',
      'category': 'Materials',
      'status': 'Draft',
      'views': 'Not published',
      'date': 'Saved 01 Sep 2026',
      'icon': Icons.local_drink_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> getFilteredListings() {
    switch (_tabController.index) {
      case 1:
        return listings.where((item) => item['status'] == 'Active').toList();

      case 2:
        return listings.where((item) => item['status'] == 'Sold').toList();

      case 3:
        return listings.where((item) => item['status'] == 'Draft').toList();

      default:
        return listings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredListings = getFilteredListings();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'My Listings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _showListingOptions,
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildIntro(),
          _buildTabs(),
          Expanded(
            child: filteredListings.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                    itemCount: filteredListings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) {
                      return _buildListingCard(filteredListings[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${listings.length} listings in your account',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Active'),
          Tab(text: 'Sold'),
          Tab(text: 'Drafts'),
        ],
      ),
    );
  }

  // ============================================================
  // LISTING CARD
  // ============================================================

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final status = listing['status'];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ListingDetails(listing: listing)),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // IMAGE
                  // ------------------------------------------------
                  Container(
                    height: 105,
                    width: 105,
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      listing['icon'],
                      size: 45,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ------------------------------------------------
                  // DETAILS
                  // ------------------------------------------------
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                listing['title'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () {
                                _showListingActions(listing);
                              },
                              child: const Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 7),

                        Text(
                          listing['price'],
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '${listing['condition']} • ${listing['category']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 9),

                        _buildStatusChip(status),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------------
            // BOTTOM INFORMATION
            // ------------------------------------------------------
            Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              decoration: BoxDecoration(
                color: AppColors.light.withOpacity(0.45),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    status == 'Sold'
                        ? Icons.check_circle_outline
                        : status == 'Draft'
                        ? Icons.edit_note_rounded
                        : Icons.visibility_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status == 'Draft' ? listing['date'] : listing['views'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const Spacer(),

                  if (status == 'Active')
                    TextButton(
                      onPressed: () {
                        _editListing(listing);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Edit Listing',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  if (status == 'Sold')
                    TextButton(
                      onPressed: () {
                        _showSoldDetails(listing);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'View Sale',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 15),
                        ],
                      ),
                    ),

                  if (status == 'Draft')
                    TextButton(
                      onPressed: () {
                        _editListing(listing);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Continue Editing',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(String status) {
    Color color;

    IconData icon;

    switch (status) {
      case 'Sold':
        color = AppColors.success;
        icon = Icons.check_circle_outline;
        break;

      case 'Draft':
        color = Colors.orange;
        icon = Icons.edit_outlined;
        break;

      default:
        color = AppColors.primary;
        icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LISTING ACTIONS
  // ============================================================

  void _showListingActions(Map<String, dynamic> listing) {
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

                const SizedBox(height: 20),

                Text(
                  listing['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 20),

                _actionTile(
                  Icons.edit_outlined,
                  'Edit Listing',
                  'Update price, photos or details',
                  () {
                    Navigator.pop(context);
                    _editListing(listing);
                  },
                ),

                if (listing['status'] == 'Active')
                  _actionTile(
                    Icons.visibility_off_outlined,
                    'Mark as Unavailable',
                    'Temporarily hide this listing',
                    () {
                      Navigator.pop(context);
                      _showMessage('Listing will be updated later.');
                    },
                  ),

                if (listing['status'] == 'Draft')
                  _actionTile(
                    Icons.publish_outlined,
                    'Publish Listing',
                    'Make this item visible in Marketplace',
                    () {
                      Navigator.pop(context);
                      _showMessage('Publishing will be connected later.');
                    },
                  ),

                _actionTile(
                  Icons.delete_outline_rounded,
                  'Delete Listing',
                  'Remove this listing',
                  () {
                    Navigator.pop(context);
                    _confirmDelete(listing);
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

  // EDIT

  void _editListing(Map<String, dynamic> listing) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditListing(listing: listing)),
    );
  }

  // SOLD DETAILS

  void _showSoldDetails(Map<String, dynamic> listing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sale Completed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  listing['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Sold for ${listing['price']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  listing['date'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _confirmDelete(Map<String, dynamic> listing) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Listing?'),
          content: Text(
            'Are you sure you want to delete "${listing['title']}"?',
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
  // MORE OPTIONS
  // ============================================================

  void _showListingOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.sort_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Sort Listings'),
                onTap: () {
                  Navigator.pop(context);
                  _showMessage('Sorting will be added later.');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Filter Listings'),
                onTap: () {
                  Navigator.pop(context);
                  _showMessage('Filtering will be added later.');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    String title;
    String description;

    switch (_tabController.index) {
      case 1:
        title = 'No active listings';
        description = 'Items currently available for sale will appear here.';
        break;

      case 2:
        title = 'No sold items';
        description = 'Once someone buys your item, it will appear here.';
        break;

      case 3:
        title = 'No drafts';
        description = 'Incomplete listings saved for later will appear here.';
        break;

      default:
        title = 'No listings yet';
        description = 'Start listing your unused items on EcoLoop.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
