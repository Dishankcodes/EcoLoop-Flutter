import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../widgets/user_more_menu.dart';
import 'product_details.dart';
import 'wishlist.dart';

class Marketplace extends StatefulWidget {
  const Marketplace({super.key, this.initialSearch, this.initialCategory});

  final String? initialSearch;
  final String? initialCategory;

  @override
  State<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  // STATE

  String selectedCategory = 'All';

  String searchQuery = '';
  String selectedCondition = 'All';
  String selectedSort = 'Newest First';

  RangeValues priceRange = const RangeValues(0, 10000);

  final TextEditingController _searchController = TextEditingController();

  // CATEGORIES

  final List<String> categories = [
    'All',
    'Furniture',
    'Decor',
    'Electronics',
    'Materials',
    'Fashion',
    'Books',
  ];

  // CONDITIONS

  final List<String> conditions = [
    'All',
    'New',
    'Like New',
    'Good',
    'Used',
    'Upcycled',
    'Recycled',
  ];

  // DUMMY PRODUCTS

  final List<Map<String, dynamic>> products = [];

  bool _loadingProducts = true;
  String? _loadError;

  Future<void> _loadProducts() async {
    try {
      final data = await EcoLoopApi.instance.get('/products');
      final rows = (data is List ? data : <dynamic>[]).whereType<Map>().map((
        raw,
      ) {
        final p = Map<String, dynamic>.from(raw);
        final images = (p['imageUrls'] is List)
            ? List<dynamic>.from(p['imageUrls'])
            : <dynamic>[];
        final category = (p['categoryName'] ?? p['category'] ?? 'Other')
            .toString();
        final seller = (p['sellerName'] ?? 'EcoLoop seller').toString();
        final location = [
          p['city'],
          p['state'],
        ].where((v) => v != null && v.toString().trim().isNotEmpty).join(', ');
        return <String, dynamic>{
          ...p,
          'id': p['productId'],
          'category': category,
          'seller': seller,
          'location': location.isEmpty ? 'Location not provided' : location,
          'image': images.isNotEmpty ? images.first.toString() : '',
          'images': images,
          'price': p['price'] ?? 0,
          'condition': p['condition'] ?? 'Not specified',
          'availableQuantity': p['availableQuantity'] ?? 0,
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        products
          ..clear()
          ..addAll(rows);
        _loadingProducts = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
        _loadError = e.toString();
      });
    }
  }

  // INIT

  @override
  void initState() {
    super.initState();
    _loadProducts();

    searchQuery = widget.initialSearch ?? '';

    _searchController.text = searchQuery;

    if (widget.initialCategory != null &&
        categories.contains(widget.initialCategory)) {
      selectedCategory = widget.initialCategory!;
    }
  }

  // DISPOSE

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // FILTERED PRODUCTS

  List<Map<String, dynamic>> get filteredProducts {
    List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      products,
    );

    // CATEGORY

    if (selectedCategory != 'All') {
      result = result
          .where((product) => product['category'] == selectedCategory)
          .toList();
    }

    // SEARCH

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase().trim();

      result = result.where((product) {
        final title = product['title'].toString().toLowerCase();
        final category = product['category'].toString().toLowerCase();
        final seller = product['seller'].toString().toLowerCase();
        final description = product['description'].toString().toLowerCase();
        final location = product['location'].toString().toLowerCase();

        return title.contains(query) ||
            category.contains(query) ||
            seller.contains(query) ||
            description.contains(query) ||
            location.contains(query);
      }).toList();
    }

    // CONDITION

    if (selectedCondition != 'All') {
      result = result
          .where((product) => product['condition'] == selectedCondition)
          .toList();
    }

    // PRICE

    result = result.where((product) {
      final price = (product['price'] as num).toDouble();

      return price >= priceRange.start && price <= priceRange.end;
    }).toList();

    // SORT

    if (selectedSort == 'Price: Low to High') {
      result.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (selectedSort == 'Price: High to Low') {
      result.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    } else if (selectedSort == 'Popular') {
      result.sort((a, b) => (b['views'] as num).compareTo(a['views'] as num));
    }

    return result;
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildCategories(),
            _buildFilterRow(),
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marketplace',
                style: AppTextStyles.heading.copyWith(fontSize: 23),
              ),
              const SizedBox(height: 2),
              Text(
                'Give useful things another life',
                style: AppTextStyles.caption,
              ),
            ],
          ),

          const Spacer(),

          // WISHLIST SHORTCUT
          IconButton(
            tooltip: 'Wishlist',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Wishlist()),
              );
            },
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.primary,
            ),
          ),

          // MORE MENU
          const UserMoreMenu(),
        ],
      ),
    );
  }

  // SEARCH BAR

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.accent.withOpacity(0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search furniture, decor, materials...',
            hintStyle: AppTextStyles.hint,

            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
            ),

            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();

                      setState(() {
                        searchQuery = '';
                      });
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 19,
                      color: AppColors.textSecondary,
                    ),
                  )
                : IconButton(
                    onPressed: _showFilterSheet,
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                    ),
                  ),

            border: InputBorder.none,

            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  // CATEGORIES

  Widget _buildCategories() {
    return SizedBox(
      height: 57,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.accent.withOpacity(0.7),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // FILTER ROW

  Widget _buildFilterRow() {
    final count = filteredProducts.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'product' : 'products'}',
            style: AppTextStyles.caption,
          ),

          const Spacer(),

          // ACTIVE CATEGORY
          if (selectedCategory != 'All')
            _activeFilterChip(selectedCategory, () {
              setState(() {
                selectedCategory = 'All';
              });
            }),

          if (selectedCategory != 'All') const SizedBox(width: 6),

          // ACTIVE CONDITION
          if (selectedCondition != 'All')
            _activeFilterChip(selectedCondition, () {
              setState(() {
                selectedCondition = 'All';
              });
            }),

          if (selectedCondition != 'All') const SizedBox(width: 6),

          // FILTER
          _smallActionButton(
            icon: Icons.tune_rounded,
            text: 'Filter',
            onTap: _showFilterSheet,
          ),

          const SizedBox(width: 7),

          // SORT
          _smallActionButton(
            icon: Icons.swap_vert_rounded,
            text: 'Sort',
            onTap: _showSortSheet,
          ),
        ],
      ),
    );
  }

  // ACTIVE FILTER CHIP

  Widget _activeFilterChip(String text, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 9, right: 6),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // SMALL ACTION BUTTON

  Widget _smallActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.accent.withOpacity(0.55)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PRODUCT GRID

  Widget _buildProductGrid() {
    final items = filteredProducts;

    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.64,
      ),
      itemBuilder: (context, index) {
        return _ProductCard(
          product: items[index],
          onTap: () {
            _openProductDetails(items[index]);
          },
        );
      },
    );
  }

  // PRODUCT DETAILS

  void _openProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 17),

            Text(
              _loadError == null
                  ? 'No products found'
                  : 'Products could not be loaded',
              style: AppTextStyles.title,
            ),

            const SizedBox(height: 6),

            Text(
              _loadError == null
                  ? 'No live listings match your filters yet.'
                  : 'Check your internet connection and Apps Script deployment, then retry.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: _loadError != null ? _loadProducts : _resetFilters,
              child: Text(_loadError != null ? 'Retry' : 'Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  // FILTER SHEET

  void _showFilterSheet() {
    RangeValues temporaryPrice = priceRange;

    String temporaryCondition = selectedCondition;
    String temporaryCategory = selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HANDLE
                      Center(
                        child: Container(
                          height: 4,
                          width: 42,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // TITLE
                      Row(
                        children: [
                          Text('Filter Products', style: AppTextStyles.title),

                          const Spacer(),

                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                temporaryCategory = 'All';
                                temporaryCondition = 'All';
                                temporaryPrice = const RangeValues(0, 10000);
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // CATEGORY
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((category) {
                          final selected = temporaryCategory == category;

                          return ChoiceChip(
                            label: Text(category),
                            selected: selected,
                            onSelected: (_) {
                              setSheetState(() {
                                temporaryCategory = category;
                              });
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // CONDITION
                      const Text(
                        'Condition',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: conditions.map((condition) {
                          final selected = temporaryCondition == condition;

                          return ChoiceChip(
                            label: Text(condition),
                            selected: selected,
                            onSelected: (_) {
                              setSheetState(() {
                                temporaryCondition = condition;
                              });
                            },
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 22),

                      // PRICE
                      const Text(
                        'Price Range',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Text(
                            '₹${temporaryPrice.start.round()}',
                            style: AppTextStyles.caption,
                          ),

                          const Spacer(),

                          Text(
                            '₹${temporaryPrice.end.round()}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),

                      RangeSlider(
                        values: temporaryPrice,
                        min: 0,
                        max: 10000,
                        divisions: 20,
                        activeColor: AppColors.primary,
                        onChanged: (values) {
                          setSheetState(() {
                            temporaryPrice = values;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      // APPLY
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCategory = temporaryCategory;

                              selectedCondition = temporaryCondition;

                              priceRange = temporaryPrice;
                            });

                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // SORT SHEET

  void _showSortSheet() {
    final options = [
      'Newest First',
      'Price: Low to High',
      'Price: High to Low',
      'Popular',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HANDLE
                Center(
                  child: Container(
                    height: 4,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text('Sort Products', style: AppTextStyles.title),

                const SizedBox(height: 10),

                ...options.map((option) {
                  final selected = selectedSort == option;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,

                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.light,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _sortIcon(option),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),

                    title: Text(
                      option,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),

                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : const Icon(
                            Icons.radio_button_unchecked,
                            color: AppColors.textSecondary,
                          ),

                    onTap: () {
                      setState(() {
                        selectedSort = option;
                      });

                      Navigator.pop(sheetContext);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // SORT ICON

  IconData _sortIcon(String option) {
    switch (option) {
      case 'Price: Low to High':
        return Icons.arrow_upward_rounded;

      case 'Price: High to Low':
        return Icons.arrow_downward_rounded;

      case 'Popular':
        return Icons.trending_up_rounded;

      default:
        return Icons.access_time_rounded;
    }
  }

  // RESET FILTERS

  void _resetFilters() {
    _searchController.clear();

    setState(() {
      searchQuery = '';
      selectedCategory = 'All';
      selectedCondition = 'All';
      selectedSort = 'Newest First';
      priceRange = const RangeValues(0, 10000);
    });
  }

  // MESSAGE

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// PRODUCT CARD

class _ProductCard extends StatefulWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool isWishlisted = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final int price = (product['price'] as num).toInt();

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.accent.withOpacity(0.42)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      product['image'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return Container(
                          color: AppColors.light,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.light,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: AppColors.secondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // CONDITION
                  Positioned(
                    left: 9,
                    top: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        product['condition'],
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // WISHLIST
                  Positioned(
                    right: 9,
                    top: 9,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isWishlisted = !isWishlisted;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isWishlisted
                                  ? 'Added to wishlist'
                                  : 'Removed from wishlist',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(milliseconds: 900),
                          ),
                        );
                      },
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: isWishlisted
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // CATEGORY
                  Positioned(
                    left: 9,
                    bottom: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product['category'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PRODUCT INFO
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    product['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // PRICE
                  Text(
                    '₹${price.toStringAsFixed(0)}',
                    style: AppTextStyles.title.copyWith(fontSize: 17),
                  ),

                  const SizedBox(height: 5),

                  // SELLER
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          product['seller'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(fontSize: 9.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // LOCATION
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Expanded(
                        child: Text(
                          product['location'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(fontSize: 8.5),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // VIEW PRODUCT
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      onPressed: widget.onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'View Product',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
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
}
