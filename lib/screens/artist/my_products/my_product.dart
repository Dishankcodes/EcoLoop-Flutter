import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
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

  // Keep the last successful response in memory so revisiting this page paints
  // immediately instead of waiting for Google Sheets / Apps Script.
  static List<Map<String, dynamic>>? _cachedProducts;
  static List<Map<String, dynamic>>? _cachedCategories;
  static DateTime? _cacheUpdatedAt;
  static const Duration _cacheDuration = Duration(minutes: 2);

  final List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _requestInProgress = false;
  String? _loadError;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    final cached = _cachedProducts;
    if (cached != null) {
      _products.addAll(cached.map((item) => Map<String, dynamic>.from(item)));
      _isLoading = false;
    }
    // Fresh cache is shown immediately; stale cache remains visible while refreshing.
    _loadProducts();
  }

  String _displayStatus(dynamic rawStatus) {
    switch ((rawStatus ?? '').toString().toLowerCase()) {
      case 'published':
        return 'active';
      case 'archived':
        return 'inactive';
      case 'draft':
        return 'pending';
      case 'out_of_stock':
        return 'out_of_stock';
      case 'sold':
        return 'sold';
      default:
        return (rawStatus ?? '').toString().toLowerCase();
    }
  }

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    if (_requestInProgress) return;

    final cached = _cachedProducts;
    final cachedAt = _cacheUpdatedAt;
    final hasCache = cached != null;
    final cacheIsFresh =
        hasCache &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheDuration;

    if (hasCache && _products.isEmpty && mounted) {
      _products.addAll(cached.map((item) => Map<String, dynamic>.from(item)));
      if (mounted) setState(() => _isLoading = false);
    }
    if (cacheIsFresh && !forceRefresh) {
      if (mounted && _isLoading) setState(() => _isLoading = false);
      return;
    }

    _requestInProgress = true;
    if (!hasCache && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    } else if (mounted) {
      // Keep the existing list visible during a background refresh.
      setState(() => _loadError = null);
    }

    try {
      // Categories and products are fetched in parallel. Reuse categories when
      // available; only request them again when there is no cached category data.
      final Future<dynamic> categoriesFuture = _cachedCategories != null
          ? Future<dynamic>.value(_cachedCategories)
          : EcoLoopApi.instance.get('/categories');
      final results = await Future.wait<dynamic>([
        categoriesFuture,
        EcoLoopApi.instance.get('/my/products'),
      ]);
      final categoryRows = results[0] is List
          ? results[0] as List
          : <dynamic>[];
      final productRows = results[1] is List ? results[1] as List : <dynamic>[];
      final categories = categoryRows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
      _cachedCategories = categories;

      final categoryNames = <int, String>{};
      for (final category in categories) {
        final id = int.tryParse(category['categoryId']?.toString() ?? '');
        if (id != null) categoryNames[id] = category['name']?.toString() ?? '';
      }
      final products = productRows
          .whereType<Map>()
          .map((raw) {
            final product = Map<String, dynamic>.from(raw);
            final rawStatus = product['status']?.toString() ?? '';
            final imageUrls = product['imageUrls'] is List
                ? (product['imageUrls'] as List)
                      .map((value) => value.toString())
                      .where((value) => value.isNotEmpty)
                      .toList(growable: false)
                : <String>[];
            product['imageUrls'] = imageUrls;
            product['image'] = imageUrls.isNotEmpty ? imageUrls.first : '';
            product['category'] =
                categoryNames[int.tryParse(
                  product['categoryId']?.toString() ?? '',
                )] ??
                '';
            product['_backendStatus'] = rawStatus;
            product['status'] = _displayStatus(rawStatus);
            product['price'] =
                double.tryParse(product['price']?.toString() ?? '') ?? 0.0;
            product['quantity'] =
                int.tryParse(product['quantity']?.toString() ?? '') ?? 0;
            product['availableQuantity'] =
                int.tryParse(product['availableQuantity']?.toString() ?? '') ??
                0;
            product['views'] =
                int.tryParse(product['views']?.toString() ?? '') ?? 0;
            product['wishlistCount'] =
                int.tryParse(product['wishlistCount']?.toString() ?? '') ?? 0;
            product['salesCount'] =
                int.tryParse(product['salesCount']?.toString() ?? '') ?? 0;
            return product;
          })
          .toList(growable: false);

      _cachedProducts = products
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      _cacheUpdatedAt = DateTime.now();
      if (!mounted) return;
      setState(() {
        _products
          ..clear()
          ..addAll(products);
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // If stale data exists, keep it on screen and report the issue subtly
        // through the existing error state only when there is nothing to show.
        if (_products.isEmpty) {
          _loadError = error.toString().replaceFirst('Exception: ', '');
        }
      });
    } finally {
      _requestInProgress = false;
    }
  }

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
            return status == 'out_of_stock' || available == 0;

          case 'Inactive':
            return status == 'inactive' || status == 'sold';

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
          (a, b) => (double.tryParse(a['price'].toString()) ?? 0).compareTo(
            double.tryParse(b['price'].toString()) ?? 0,
          ),
        );
        break;

      case 'Price: High to Low':
        products.sort(
          (a, b) => (double.tryParse(b['price'].toString()) ?? 0).compareTo(
            double.tryParse(a['price'].toString()) ?? 0,
          ),
        );
        break;

      case 'Most Viewed':
        products.sort(
          (a, b) => (int.tryParse(b['views'].toString()) ?? 0).compareTo(
            int.tryParse(a['views'].toString()) ?? 0,
          ),
        );
        break;

      case 'Most Sold':
        products.sort(
          (a, b) => (int.tryParse(b['salesCount'].toString()) ?? 0).compareTo(
            int.tryParse(a['salesCount'].toString()) ?? 0,
          ),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? _buildLoadError()
                : products.isEmpty
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
          (int.tryParse(product['availableQuantity'].toString()) ?? 0) > 0;
    }).length;

    final soldOut = _products.where((product) {
      return (int.tryParse(product['availableQuantity'].toString()) ?? 0) == 0;
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
          Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => ListingDetails(listing: product)),
          ).then((changed) {
            if (changed == true) _loadProducts(forceRefresh: true);
          });
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
        child: (product['image']?.toString().isNotEmpty ?? false)
            ? Image.network(
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
              )
            : const Center(
                child: Icon(
                  Icons.image_outlined,
                  color: ArtistColors.textMuted,
                  size: 28,
                ),
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
        Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => ListingDetails(listing: product)),
        ).then((changed) {
          if (changed == true) _loadProducts(forceRefresh: true);
        });
        break;

      case 'edit':
        Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => EditProduct(product: product)),
        ).then((changed) {
          if (changed == true) _loadProducts(forceRefresh: true);
        });
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
                      _setProductStatus(product, 'published');
                    },
                  ),
                  _buildStatusOption(
                    icon: Icons.pause_circle_outline_rounded,
                    title: 'Inactive',
                    subtitle: 'Temporarily hide this product',
                    color: ArtistColors.textSecondary,
                    onTap: () {
                      Navigator.pop(context);
                      _setProductStatus(product, 'archived');
                    },
                  ),
                  _buildStatusOption(
                    icon: Icons.pending_outlined,
                    title: 'Pending',
                    subtitle: 'Keep this product pending',
                    color: ArtistColors.warning,
                    onTap: () {
                      Navigator.pop(context);
                      _setProductStatus(product, 'draft');
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
            'Archive Product?',
            style: ArtistTextStyles.title.copyWith(fontSize: 20),
          ),
          content: Text(
            'Archive "${product['title']}"?\n\n'
            'This hides the listing from buyers. You can still find it under Inactive.',
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
              onPressed: () async {
                Navigator.pop(dialogContext);
                final id = int.tryParse(product['productId']?.toString() ?? '');
                if (id == null) {
                  _showOperationMessage('Invalid product ID.');
                  return;
                }
                try {
                  await EcoLoopApi.instance.delete('/products/$id');
                  if (!mounted) return;
                  _showOperationMessage('Product archived successfully.');
                  await _loadProducts(forceRefresh: true);
                } catch (error) {
                  if (mounted) {
                    _showOperationMessage(
                      error.toString().replaceFirst('Exception: ', ''),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
  }

  // Simulates pull-to-refresh action
  Future<void> _refreshProducts() => _loadProducts(forceRefresh: true);

  Future<void> _setProductStatus(
    Map<String, dynamic> product,
    String status,
  ) async {
    final id = int.tryParse(product['productId']?.toString() ?? '');
    if (id == null || _isMutating) return;
    setState(() => _isMutating = true);
    try {
      await EcoLoopApi.instance.post('/products/$id/status', {
        'status': status,
      });
      if (!mounted) return;
      _showOperationMessage('Product status updated.');
      await _loadProducts(forceRefresh: true);
    } catch (error) {
      if (mounted)
        _showOperationMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: ArtistColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _loadError ?? 'Could not load products.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOperationMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
