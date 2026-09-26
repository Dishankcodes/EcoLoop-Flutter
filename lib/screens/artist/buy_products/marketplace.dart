import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../widgets/artist_more_menu.dart';
import 'product_details.dart';

/// Screen displaying the circular marketplace catalog with search, filtering, and sorting capabilities.
class Marketplace extends StatefulWidget {
  const Marketplace({super.key, this.initialSearch, this.initialCategory});

  final String? initialSearch;
  final String? initialCategory;

  @override
  State<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  String selectedCategory = 'All';
  String searchQuery = '';
  String selectedCondition = 'All';
  String selectedSort = 'Newest First';
  RangeValues priceRange = const RangeValues(0, 10000);

  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = [
    'All',
    'Furniture',
    'Decor',
    'Electronics',
    'Materials',
    'Fashion',
    'Books',
  ];

  final List<String> conditions = [
    'All',
    'New',
    'Like New',
    'Good',
    'Used',
    'Upcycled',
    'Recycled',
  ];

  final List<Map<String, dynamic>> products = [
    {
      'productId': 1,
      'sellerId': 101,
      'sellerType': 'artist',
      'title': 'Wooden Table',
      'price': 2500,
      'condition': 'Used',
      'categoryId': 1,
      'category': 'Furniture',
      'listingType': 'c2c',
      'seller': 'Rahul',
      'location': 'Ahmedabad, Gujarat',
      'views': 126,
      'wishlistCount': 14,
      'salesCount': 8,
      'quantity': 1,
      'availableQuantity': 1,
      'status': 'published',
      'description':
          'A sturdy pre-owned wooden table in good usable condition. Perfect for study, work or creative projects.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?auto=format&fit=crop&w=1200&q=85',
        'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 2,
      'sellerId': 102,
      'sellerType': 'artist',
      'title': 'Wooden Chair',
      'price': 1200,
      'condition': 'Used',
      'categoryId': 1,
      'category': 'Furniture',
      'listingType': 'c2c',
      'seller': 'Amit',
      'location': 'Vadodara, Gujarat',
      'views': 89,
      'wishlistCount': 9,
      'salesCount': 5,
      'quantity': 2,
      'availableQuantity': 2,
      'status': 'published',
      'description':
          'Comfortable wooden chair available for reuse. Minor signs of use but structurally strong.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1503602642458-232111445657?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 3,
      'sellerId': 103,
      'sellerType': 'artist',
      'title': 'Bottle Lamp',
      'price': 899,
      'condition': 'Upcycled',
      'categoryId': 2,
      'category': 'Decor',
      'listingType': 'b2c',
      'seller': 'Priya',
      'location': 'Surat, Gujarat',
      'views': 174,
      'wishlistCount': 23,
      'salesCount': 12,
      'quantity': 1,
      'availableQuantity': 1,
      'status': 'published',
      'description':
          'Creative decorative lamp made using reused glass bottles. A beautiful example of upcycling.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 4,
      'sellerId': 104,
      'sellerType': 'artist',
      'title': 'Old Speaker',
      'price': 1500,
      'condition': 'Good',
      'categoryId': 3,
      'category': 'Electronics',
      'listingType': 'c2c',
      'seller': 'Karan',
      'location': 'Ahmedabad, Gujarat',
      'views': 102,
      'wishlistCount': 11,
      'salesCount': 4,
      'quantity': 1,
      'availableQuantity': 1,
      'status': 'published',
      'description':
          'Pre-owned speaker in working condition. Suitable for home entertainment or creative reuse.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1545454675-3531b543be5d?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 5,
      'sellerId': 105,
      'sellerType': 'artist',
      'title': 'Glass Decoration',
      'price': 650,
      'condition': 'Recycled',
      'categoryId': 2,
      'category': 'Decor',
      'listingType': 'b2c',
      'seller': 'Neha',
      'location': 'Rajkot, Gujarat',
      'views': 65,
      'wishlistCount': 7,
      'salesCount': 3,
      'quantity': 3,
      'availableQuantity': 3,
      'status': 'published',
      'description':
          'Beautiful decorative piece created from recycled glass material.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1610701596007-11502861dcfa?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 6,
      'sellerId': 106,
      'sellerType': 'artist',
      'title': 'Wooden Cabinet',
      'price': 2200,
      'condition': 'Used',
      'categoryId': 1,
      'category': 'Furniture',
      'listingType': 'c2c',
      'seller': 'Vivek',
      'location': 'Gandhinagar, Gujarat',
      'views': 211,
      'wishlistCount': 31,
      'salesCount': 17,
      'quantity': 1,
      'availableQuantity': 1,
      'status': 'published',
      'description':
          'Large wooden cabinet available for reuse. Good for storage and home organization.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1595428774223-ef52624120d2?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 7,
      'sellerId': 107,
      'sellerType': 'artist',
      'title': 'Craft Wood Pieces',
      'price': 450,
      'condition': 'Recycled',
      'categoryId': 4,
      'category': 'Materials',
      'listingType': 'b2c',
      'seller': 'EcoCraft',
      'location': 'Ahmedabad, Gujarat',
      'views': 93,
      'wishlistCount': 12,
      'salesCount': 19,
      'quantity': 8,
      'availableQuantity': 8,
      'status': 'published',
      'description':
          'Reusable wood pieces suitable for DIY projects, art, craft and furniture making.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 8,
      'sellerId': 108,
      'sellerType': 'artist',
      'title': 'Denim Material Bundle',
      'price': 700,
      'condition': 'Used',
      'categoryId': 5,
      'category': 'Fashion',
      'listingType': 'c2c',
      'seller': 'Mira',
      'location': 'Mumbai, Maharashtra',
      'views': 77,
      'wishlistCount': 8,
      'salesCount': 6,
      'quantity': 5,
      'availableQuantity': 5,
      'status': 'published',
      'description':
          'Reusable denim fabric pieces for crafting, upcycling and DIY fashion projects.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=1200&q=85',
      ],
    },
    {
      'productId': 9,
      'sellerId': 109,
      'sellerType': 'artist',
      'title': 'Programming Books Bundle',
      'price': 850,
      'condition': 'Good',
      'categoryId': 6,
      'category': 'Books',
      'listingType': 'c2c',
      'seller': 'Arjun',
      'location': 'Pune, Maharashtra',
      'views': 118,
      'wishlistCount': 16,
      'salesCount': 7,
      'quantity': 4,
      'availableQuantity': 4,
      'status': 'published',
      'description':
          'Collection of useful programming and computer science books. Great for students and beginners.',
      'imageUrls': [
        'https://images.unsplash.com/photo-1512820790803-83ca734da794?auto=format&fit=crop&w=1200&q=85',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    searchQuery = widget.initialSearch ?? '';
    _searchController.text = searchQuery;

    if (widget.initialCategory != null &&
        categories.contains(widget.initialCategory)) {
      selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filters products based on selected category, search term, condition, price, and status.
  List<Map<String, dynamic>> get filteredProducts {
    List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      products,
    );

    result = result
        .where(
          (product) =>
              product['status'].toString().toLowerCase() == 'published',
        )
        .toList();

    if (selectedCategory != 'All') {
      result = result
          .where((product) => product['category'] == selectedCategory)
          .toList();
    }

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

    if (selectedCondition != 'All') {
      result = result
          .where((product) => product['condition'] == selectedCondition)
          .toList();
    }

    result = result.where((product) {
      final price = (product['price'] as num).toDouble();
      return price >= priceRange.start && price <= priceRange.end;
    }).toList();

    if (selectedSort == 'Price: Low to High') {
      result.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    } else if (selectedSort == 'Price: High to Low') {
      result.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    } else if (selectedSort == 'Popular') {
      result.sort((a, b) => (b['views'] as num).compareTo(a['views'] as num));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
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

  /// Header section showing title, subtitle, and overflow actions.
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
                style: ArtistTextStyles.heading.copyWith(fontSize: 23),
              ),
              const SizedBox(height: 2),
              Text(
                'Discover materials, products & creative finds',
                style: ArtistTextStyles.caption,
              ),
            ],
          ),
          const Spacer(),
          const ArtistMoreMenu(),
        ],
      ),
    );
  }

  /// Search field with action buttons to filter or clear search terms.
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: ArtistColors.accent.withOpacity(0.45)),
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
          style: ArtistTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search furniture, decor, materials...',
            hintStyle: ArtistTextStyles.hint,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: ArtistColors.primary,
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
                      color: ArtistColors.textSecondary,
                    ),
                  )
                : IconButton(
                    onPressed: _showFilterSheet,
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: ArtistColors.primary,
                    ),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  /// Horizontal scrollable category filter chips list.
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
                color: selected ? ArtistColors.primary : ArtistColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? ArtistColors.primary : ArtistColors.border,
                ),
              ),
              child: Text(
                category,
                style: ArtistTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : ArtistColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Active filter indicators and action triggers for modal filter sheets.
  Widget _buildFilterRow() {
    final count = filteredProducts.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'product' : 'products'}',
            style: ArtistTextStyles.caption,
          ),
          const Spacer(),
          if (selectedCategory != 'All')
            _activeFilterChip(selectedCategory, () {
              setState(() {
                selectedCategory = 'All';
              });
            }),
          if (selectedCategory != 'All') const SizedBox(width: 6),
          if (selectedCondition != 'All')
            _activeFilterChip(selectedCondition, () {
              setState(() {
                selectedCondition = 'All';
              });
            }),
          if (selectedCondition != 'All') const SizedBox(width: 6),
          _smallActionButton(
            icon: Icons.tune_rounded,
            text: 'Filter',
            onTap: _showFilterSheet,
          ),
          const SizedBox(width: 7),
          _smallActionButton(
            icon: Icons.swap_vert_rounded,
            text: 'Sort',
            onTap: _showSortSheet,
          ),
        ],
      ),
    );
  }

  /// Active filter indicator chip with removal action.
  Widget _activeFilterChip(String text, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 9, right: 6),
        decoration: BoxDecoration(
          color: ArtistColors.light.withOpacity(0.55),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: ArtistTextStyles.small.copyWith(
                fontSize: 9,
                color: ArtistColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.close_rounded,
              size: 14,
              color: ArtistColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// Compact action button for triggering bottom sheets.
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
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: ArtistColors.primary),
            const SizedBox(width: 4),
            Text(
              text,
              style: ArtistTextStyles.caption.copyWith(
                color: ArtistColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Grid view rendering the current list of products or empty state.
  Widget _buildProductGrid() {
    final items = filteredProducts;

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
          onTap: () => _showProductPreview(items[index]),
        );
      },
    );
  }

  /// Modal preview sheet showing details for a selected product.
  void _showProductPreview(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
    );
  }

  /// Tag chip rendered inside the product preview modal.
  Widget _previewTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ArtistColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ArtistColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: ArtistTextStyles.small.copyWith(
              color: ArtistColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state placeholder rendered when zero items match search/filter criteria.
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
              decoration: BoxDecoration(
                color: ArtistColors.light.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: ArtistColors.primary,
              ),
            ),
            const SizedBox(height: 17),
            Text('No products found', style: ArtistTextStyles.title),
            const SizedBox(height: 6),
            Text(
              'Try another search, category or filter.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _resetFilters,
              child: Text(
                'Clear Filters',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet modal containing detailed search filtering controls.
  void _showFilterSheet() {
    RangeValues temporaryPrice = priceRange;
    String temporaryCondition = selectedCondition;
    String temporaryCategory = selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArtistColors.surface,
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
                      Center(
                        child: Container(
                          height: 4,
                          width: 42,
                          decoration: BoxDecoration(
                            color: ArtistColors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Filter Products',
                            style: ArtistTextStyles.title,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                temporaryCategory = 'All';
                                temporaryCondition = 'All';
                                temporaryPrice = const RangeValues(0, 10000);
                              });
                            },
                            child: Text(
                              'Reset',
                              style: ArtistTextStyles.bodyMedium.copyWith(
                                color: ArtistColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Category', style: ArtistTextStyles.label),
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
                            selectedColor: ArtistColors.primary,
                            backgroundColor: ArtistColors.surfaceSoft,
                            side: BorderSide(color: ArtistColors.border),
                            labelStyle: ArtistTextStyles.small.copyWith(
                              color: selected
                                  ? Colors.white
                                  : ArtistColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      Text('Condition', style: ArtistTextStyles.label),
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
                            selectedColor: ArtistColors.primary,
                            backgroundColor: ArtistColors.surfaceSoft,
                            side: BorderSide(color: ArtistColors.border),
                            labelStyle: ArtistTextStyles.small.copyWith(
                              color: selected
                                  ? Colors.white
                                  : ArtistColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 22),
                      Text('Price Range', style: ArtistTextStyles.label),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            '₹${temporaryPrice.start.round()}',
                            style: ArtistTextStyles.caption,
                          ),
                          const Spacer(),
                          Text(
                            '₹${temporaryPrice.end.round()}',
                            style: ArtistTextStyles.caption,
                          ),
                        ],
                      ),
                      RangeSlider(
                        values: temporaryPrice,
                        min: 0,
                        max: 10000,
                        divisions: 20,
                        activeColor: ArtistColors.primary,
                        inactiveColor: ArtistColors.border,
                        onChanged: (values) {
                          setSheetState(() {
                            temporaryPrice = values;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
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
                          child: Text(
                            'Apply Filters',
                            style: ArtistTextStyles.button,
                          ),
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

  /// Bottom sheet modal options for sorting the products grid.
  void _showSortSheet() {
    final options = [
      'Newest First',
      'Price: Low to High',
      'Price: High to Low',
      'Popular',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
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
                Center(
                  child: Container(
                    height: 4,
                    width: 42,
                    decoration: BoxDecoration(
                      color: ArtistColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Sort Products', style: ArtistTextStyles.title),
                const SizedBox(height: 10),
                ...options.map((option) {
                  final selected = selectedSort == option;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ArtistColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _sortIcon(option),
                        color: ArtistColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      option,
                      style: ArtistTextStyles.body.copyWith(
                        color: ArtistColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: ArtistColors.primary,
                          )
                        : const Icon(
                            Icons.radio_button_unchecked,
                            color: ArtistColors.textSecondary,
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

  /// Helper mapping sort option titles to icons.
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

  /// Resets all search input, filters, and sort configurations back to defaults.
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

  /// Displays floating feedback snackbar.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: ArtistTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}

/// Product card component displayed within the marketplace grid view.
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int price = (product['price'] as num).toInt();
    final List<dynamic> imageUrls = product['imageUrls'] as List<dynamic>;
    final String image = imageUrls.isNotEmpty ? imageUrls.first.toString() : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: ArtistColors.border),
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
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: image.isEmpty
                        ? _imageError()
                        : Image.network(
                            image,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: ArtistColors.surfaceSoft,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ArtistColors.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _imageError();
                            },
                          ),
                  ),
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
                        product['condition'].toString(),
                        style: ArtistTextStyles.small.copyWith(
                          fontSize: 8.5,
                          color: ArtistColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 9,
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
                        product['listingType'].toString().toUpperCase(),
                        style: ArtistTextStyles.small.copyWith(
                          fontSize: 7.5,
                          color: ArtistColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
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
                        product['category'].toString(),
                        style: ArtistTextStyles.small.copyWith(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.body.copyWith(
                      color: ArtistColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${price.toStringAsFixed(0)}',
                    style: ArtistTextStyles.title.copyWith(
                      fontSize: 17,
                      color: ArtistColors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 12,
                        color: ArtistColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          product['seller'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ArtistTextStyles.caption.copyWith(
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: ArtistColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          product['location'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ArtistTextStyles.caption.copyWith(
                            fontSize: 8.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ArtistColors.primary,
                        side: const BorderSide(color: ArtistColors.primary),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: Text(
                        'View Product',
                        style: ArtistTextStyles.small.copyWith(
                          fontSize: 10,
                          color: ArtistColors.primary,
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

  /// Image load error fallback container.
  Widget _imageError() {
    return Container(
      color: ArtistColors.surfaceSoft,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 40,
          color: ArtistColors.textMuted,
        ),
      ),
    );
  }
}
