import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import 'edit_product.dart';
import 'listing_details.dart';

class MyProducts extends StatefulWidget {
  const MyProducts({super.key});

  @override
  State<MyProducts> createState() => _MyProductsState();
}

class _MyProductsState extends State<MyProducts> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';

  final List<String> _filters = [
    'All',
    'Active',
    'Pending',
    'Sold Out',
    'Inactive',
  ];

  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Price: Low to High',
    'Price: High to Low',
    'Most Viewed',
    'Most Sold',
  ];

  // Demo products data list
  final List<Map<String, dynamic>> _products = [
    {
      'productId': 'PRD001',
      'title': 'Handcrafted Wooden Table',
      'description':
          'Beautiful handcrafted wooden table made from reclaimed wood.',
      'price': 4500.0,
      'category': 'Furniture',
      'categoryId': 'CAT001',
      'listingType': 'Sell',
      'condition': 'Good',
      'quantity': 4,
      'availableQuantity': 3,
      'status': 'active',
      'views': 248,
      'wishlistCount': 34,
      'salesCount': 6,
      'image': 'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc',
      'createdAt': '2026-09-25',
    },
    {
      'productId': 'PRD002',
      'title': 'Upcycled Glass Vase',
      'description': 'Decorative vase created from recycled glass materials.',
      'price': 850.0,
      'category': 'Home & Decor',
      'categoryId': 'CAT002',
      'listingType': 'Sell',
      'condition': 'Like New',
      'quantity': 10,
      'availableQuantity': 7,
      'status': 'active',
      'views': 184,
      'wishlistCount': 21,
      'salesCount': 9,
      'image': 'https://images.unsplash.com/photo-1612196808214-b8e1d6145a8c',
      'createdAt': '2026-09-22',
    },
    {
      'productId': 'PRD003',
      'title': 'Recycled Fabric Tote Bag',
      'description': 'Eco-friendly tote bag created using recycled fabric.',
      'price': 550.0,
      'category': 'Clothing',
      'categoryId': 'CAT003',
      'listingType': 'Sell',
      'condition': 'New',
      'quantity': 5,
      'availableQuantity': 0,
      'status': 'active',
      'views': 321,
      'wishlistCount': 46,
      'salesCount': 12,
      'image': 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7',
      'createdAt': '2026-09-19',
    },
    {
      'productId': 'PRD004',
      'title': 'Reclaimed Wood Wall Decor',
      'description':
          'Handmade wall decor created using reclaimed wooden pieces.',
      'price': 1250.0,
      'category': 'Home & Decor',
      'categoryId': 'CAT002',
      'listingType': 'Sell',
      'condition': 'Good',
      'quantity': 3,
      'availableQuantity': 2,
      'status': 'pending',
      'views': 96,
      'wishlistCount': 12,
      'salesCount': 2,
      'image': 'https://images.unsplash.com/photo-1577083552431-6e5fd01aa342',
      'createdAt': '2026-09-16',
    },
    {
      'productId': 'PRD005',
      'title': 'Recycled Metal Planter',
      'description': 'Decorative planter made from reused metal materials.',
      'price': 950.0,
      'category': 'Home & Decor',
      'categoryId': 'CAT002',
      'listingType': 'Sell',
      'condition': 'New',
      'quantity': 6,
      'availableQuantity': 6,
      'status': 'inactive',
      'views': 71,
      'wishlistCount': 8,
      'salesCount': 0,
      'image': 'https://images.unsplash.com/photo-1485955900006-10f4d324d411',
      'createdAt': '2026-09-10',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Returns filtered and sorted products list
  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> products = List.from(_products);

    final String query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      products = products.where((product) {
        final title = (product['title'] ?? '').toString().toLowerCase();
        final category = (product['category'] ?? '').toString().toLowerCase();
        final productId = (product['productId'] ?? '').toString().toLowerCase();

        return title.contains(query) ||
            category.contains(query) ||
            productId.contains(query);
      }).toList();
    }

    if (_selectedFilter != 'All') {
      products = products.where((product) {
        final status = product['status'].toString().toLowerCase();
        final available = (product['availableQuantity'] ?? 0) as int;

        switch (_selectedFilter) {
          case 'Active':
            return status == 'active' && available > 0;

          case 'Pending':
            return status == 'pending';

          case 'Sold Out':
            return available == 0;

          case 'Inactive':
            return status == 'inactive';

          default:
            return true;
        }
      }).toList();
    }

    switch (_selectedSort) {
      case 'Oldest':
        products.sort(
          (a, b) =>
              a['createdAt'].toString().compareTo(b['createdAt'].toString()),
        );
        break;

      case 'Price: Low to High':
        products.sort(
          (a, b) => (a['price'] as double).compareTo(b['price'] as double),
        );
        break;

      case 'Price: High to Low':
        products.sort(
          (a, b) => (b['price'] as double).compareTo(a['price'] as double),
        );
        break;

      case 'Most Viewed':
        products.sort(
          (a, b) => (b['views'] as int).compareTo(a['views'] as int),
        );
        break;

      case 'Most Sold':
        products.sort(
          (a, b) => (b['salesCount'] as int).compareTo(a['salesCount'] as int),
        );
        break;

      case 'Newest':
      default:
        products.sort(
          (a, b) =>
              b['createdAt'].toString().compareTo(a['createdAt'].toString()),
        );
        break;
    }

    return products;
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
        ),
        title: Text(
          'My Products',
          style: ArtistTextStyles.title.copyWith(fontSize: 19),
        ),
        actions: [
          IconButton(
            onPressed: _showSortSheet,
            tooltip: 'Sort',
            icon: const Icon(
              Icons.sort_rounded,
              color: ArtistColors.textPrimary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildSummary(),
          _buildFilterChips(),
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: ArtistColors.primary,
                    onRefresh: _refreshProducts,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return _buildProductCard(products[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Search input bar
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Search your products...',
          hintStyle: ArtistTextStyles.hint,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ArtistColors.primary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ArtistColors.textSecondary,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // Products overview summary statistics
  Widget _buildSummary() {
    final total = _products.length;

    final active = _products.where((product) {
      return product['status'] == 'active' &&
          (product['availableQuantity'] as int) > 0;
    }).length;

    final soldOut = _products.where((product) {
      return (product['availableQuantity'] as int) == 0;
    }).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.inventory_2_outlined,
              value: '$total',
              label: 'Products',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.check_circle_outline_rounded,
              value: '$active',
              label: 'Active',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.remove_shopping_cart_outlined,
              value: '$soldOut',
              label: 'Sold Out',
            ),
          ),
        ],
      ),
    );
  }

  // Individual summary statistic card widget
  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: ArtistColors.primary),
          const SizedBox(height: 5),
          Text(value, style: ArtistTextStyles.title.copyWith(fontSize: 17)),
          const SizedBox(height: 1),
          Text(label, style: ArtistTextStyles.small),
        ],
      ),
    );
  }

  // Filter selection chips bar
  Widget _buildFilterChips() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            labelStyle: selected
                ? ArtistTextStyles.bodyMedium.copyWith(
                    color: ArtistColors.primary,
                    fontSize: 12,
                  )
                : ArtistTextStyles.body.copyWith(fontSize: 12),
            backgroundColor: ArtistColors.surface,
            selectedColor: ArtistColors.light,
            side: BorderSide(
              color: selected ? ArtistColors.primary : ArtistColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  // Product card layout container
  Widget _buildProductCard(Map<String, dynamic> product) {
    final int availableQuantity = product['availableQuantity'] as int;
    final String status = product['status'].toString();
    final bool soldOut = availableQuantity <= 0;

    return Container(
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ListingDetails(listing: product)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(product),
                  const SizedBox(width: 12),
                  Expanded(child: _buildProductInfo(product, soldOut)),
                  _buildProductMenu(product),
                ],
              ),
              const SizedBox(height: 13),
              Divider(height: 1, color: ArtistColors.border),
              const SizedBox(height: 12),
              _buildProductStats(product),
              const SizedBox(height: 12),
              _buildProductActions(product),
            ],
          ),
        ),
      ),
    );
  }

  // Product thumbnail image
  Widget _buildProductImage(Map<String, dynamic> product) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 92,
        height: 105,
        color: ArtistColors.surfaceSoft,
        child: Image.network(
          product['image'].toString(),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: ArtistColors.textMuted,
                size: 28,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ArtistColors.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Product information details
  Widget _buildProductInfo(Map<String, dynamic> product, bool soldOut) {
    final String status = product['status'].toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product['title'].toString(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          '₹${_formatPrice(product['price'])}',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            color: ArtistColors.primary,
          ),
        ),
        const SizedBox(height: 5),
        Text(product['category'].toString(), style: ArtistTextStyles.small),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildStatusBadge(status, soldOut),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${product['availableQuantity']}/${product['quantity']} available',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArtistTextStyles.small,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Product status badge indicator
  Widget _buildStatusBadge(String status, bool soldOut) {
    String label;
    Color backgroundColor;
    Color textColor;

    if (soldOut) {
      label = 'Sold Out';
      backgroundColor = ArtistColors.error.withOpacity(0.10);
      textColor = ArtistColors.error;
    } else if (status == 'pending') {
      label = 'Pending';
      backgroundColor = ArtistColors.warning.withOpacity(0.12);
      textColor = ArtistColors.warning;
    } else if (status == 'inactive') {
      label = 'Inactive';
      backgroundColor = ArtistColors.textMuted.withOpacity(0.12);
      textColor = ArtistColors.textSecondary;
    } else {
      label = 'Active';
      backgroundColor = ArtistColors.success.withOpacity(0.12);
      textColor = ArtistColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: ArtistTextStyles.small.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  // Contextual popup menu for product item
  Widget _buildProductMenu(Map<String, dynamic> product) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.more_vert_rounded,
        color: ArtistColors.textSecondary,
        size: 21,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        _handleProductMenu(value, product);
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, color: ArtistColors.primary),
              SizedBox(width: 10),
              Text('View Product'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: ArtistColors.primary),
              SizedBox(width: 10),
              Text('Edit Product'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'status',
          child: Row(
            children: [
              Icon(Icons.toggle_on_outlined, color: ArtistColors.primary),
              SizedBox(width: 10),
              Text('Change Status'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: ArtistColors.error),
              SizedBox(width: 10),
              Text('Delete Product'),
            ],
          ),
        ),
      ],
    );
  }

  // Product engagement metrics stats row
  Widget _buildProductStats(Map<String, dynamic> product) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            Icons.visibility_outlined,
            '${product['views']}',
            'Views',
          ),
        ),
        Expanded(
          child: _buildStatItem(
            Icons.favorite_border_rounded,
            '${product['wishlistCount']}',
            'Wishlist',
          ),
        ),
        Expanded(
          child: _buildStatItem(
            Icons.shopping_bag_outlined,
            '${product['salesCount']}',
            'Sales',
          ),
        ),
        Expanded(
          child: _buildStatItem(
            Icons.inventory_2_outlined,
            '${product['availableQuantity']}',
            'Available',
          ),
        ),
      ],
    );
  }

  // Single stat metric layout unit
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 17, color: ArtistColors.textSecondary),
        const SizedBox(height: 3),
        Text(value, style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 12)),
        Text(label, style: ArtistTextStyles.small.copyWith(fontSize: 9.5)),
      ],
    );
  }

  // Artist-themed Edit and View action buttons
  Widget _buildProductActions(Map<String, dynamic> product) {
    return Row(
      children: [
        // EDIT BUTTON
        Expanded(
          child: SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProduct(product: product),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ArtistColors.primary,
                backgroundColor: ArtistColors.background,
                side: const BorderSide(color: ArtistColors.primary, width: 1.2),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: ArtistColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Edit',
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ArtistColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 9),

        // VIEW BUTTON
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListingDetails(listing: product),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 17,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'View',
                    style: ArtistTextStyles.button.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Empty products list fallback placeholder
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
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
                Icons.inventory_2_outlined,
                color: ArtistColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Products Found',
              style: ArtistTextStyles.title.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 7),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try searching with a different product name or category.'
                  : 'You do not have any products in this category yet.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'All';
                  _searchController.clear();
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ArtistColors.primary,
                side: const BorderSide(color: ArtistColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Reset Filters',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Scrollable Sort Options modal bottom sheet
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sort Products',
                        style: ArtistTextStyles.title.copyWith(fontSize: 19),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: ArtistColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._sortOptions.map((option) {
                    final selected = _selectedSort == option;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        setState(() {
                          _selectedSort = option;
                        });
                        Navigator.pop(context);
                      },
                      leading: Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: selected
                            ? ArtistColors.primary
                            : ArtistColors.textMuted,
                      ),
                      title: Text(
                        option,
                        style: selected
                            ? ArtistTextStyles.bodyMedium
                            : ArtistTextStyles.body,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Handles popup menu choice routing
  void _handleProductMenu(String value, Map<String, dynamic> product) {
    switch (value) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ListingDetails(listing: product)),
        );
        break;

      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditProduct(product: product)),
        );
        break;

      case 'status':
        _showStatusSheet(product);
        break;

      case 'delete':
        _showDeleteDialog(product);
        break;
    }
  }

  // Scrollable Change Product Status modal bottom sheet
  void _showStatusSheet(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Change Product Status',
                    style: ArtistTextStyles.title.copyWith(fontSize: 19),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product['title'].toString(),
                    textAlign: TextAlign.center,
                    style: ArtistTextStyles.caption,
                  ),
                  const SizedBox(height: 18),
                  _buildStatusOption(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Active',
                    subtitle: 'Make this product visible for buyers',
                    color: ArtistColors.success,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Activate Product');
                    },
                  ),
                  _buildStatusOption(
                    icon: Icons.pause_circle_outline_rounded,
                    title: 'Inactive',
                    subtitle: 'Temporarily hide this product',
                    color: ArtistColors.textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Deactivate Product');
                    },
                  ),
                  _buildStatusOption(
                    icon: Icons.pending_outlined,
                    title: 'Pending',
                    subtitle: 'Keep this product pending',
                    color: ArtistColors.warning,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon('Update Product Status');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper tile for status modal choices
  Widget _buildStatusOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: ArtistTextStyles.bodyMedium),
      subtitle: Text(subtitle, style: ArtistTextStyles.small),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: ArtistColors.textMuted,
      ),
    );
  }

  // Delete product confirmation alert dialog
  void _showDeleteDialog(Map<String, dynamic> product) {
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
            'Are you sure you want to delete "${product['title']}"?\n\n'
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

                setState(() {
                  _products.remove(product);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '"${product['title']}" deleted successfully.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: ArtistColors.primary,
                  ),
                );
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

  // Simulates pull-to-refresh action
  Future<void> _refreshProducts() async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {});
  }

  // Displays coming soon snackbar message
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature will be connected in the next phase.',
          style: ArtistTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontSize: 13,
          ),
        ),
        backgroundColor: ArtistColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Price formatting helper
  String _formatPrice(dynamic value) {
    final double price = double.tryParse(value.toString()) ?? 0;

    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    }

    return price.toStringAsFixed(2);
  }
}
