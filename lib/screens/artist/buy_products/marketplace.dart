import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class Marketplace extends StatefulWidget {
  final String? initialSearch;
  final String? initialCategory;

  const Marketplace({super.key, this.initialSearch, this.initialCategory});

  @override
  State<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _selectedCondition = 'All';
  String _selectedSort = 'Newest';
  RangeValues _priceRange = const RangeValues(0, 50000);

  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Furniture',
    'Decor',
    'Electronics',
    'Materials',
    'Fashion',
    'Books',
  ];

  final List<String> _conditions = [
    'All',
    'New',
    'Like New',
    'Good',
    'Used',
    'Upcycled',
    'Recycled',
  ];

  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'title': 'Upcycled Wooden Table',
      'price': 4500,
      'condition': 'Upcycled',
      'category': 'Furniture',
      'seller': 'Creative Studio',
      'location': 'Ahmedabad',
      'views': 124,
      'wishlistCount': 18,
      'availableQuantity': 2,
      'description':
          'Beautiful handmade table created using reclaimed wooden materials.',
      'image': '',
      'images': <String>[],
    },
    {
      'id': '2',
      'title': 'Handmade Wall Decor',
      'price': 1800,
      'condition': 'New',
      'category': 'Decor',
      'seller': 'Eco Crafts',
      'location': 'Ahmedabad',
      'views': 98,
      'wishlistCount': 12,
      'availableQuantity': 5,
      'description':
          'Unique handmade wall decoration made from sustainable materials.',
      'image': '',
      'images': <String>[],
    },
    {
      'id': '3',
      'title': 'Recycled Storage Box',
      'price': 850,
      'condition': 'Recycled',
      'category': 'Furniture',
      'seller': 'Green Hands',
      'location': 'Gandhinagar',
      'views': 76,
      'wishlistCount': 9,
      'availableQuantity': 8,
      'description': 'Useful storage box created from recycled materials.',
      'image': '',
      'images': <String>[],
    },
    {
      'id': '4',
      'title': 'Vintage Lamp',
      'price': 2200,
      'condition': 'Like New',
      'category': 'Decor',
      'seller': 'ReArt Studio',
      'location': 'Ahmedabad',
      'views': 145,
      'wishlistCount': 22,
      'availableQuantity': 3,
      'description': 'Vintage style lamp restored and ready for a new home.',
      'image': '',
      'images': <String>[],
    },
    {
      'id': '5',
      'title': 'Upcycled Denim Bag',
      'price': 1200,
      'condition': 'Upcycled',
      'category': 'Fashion',
      'seller': 'Crafty Soul',
      'location': 'Vadodara',
      'views': 112,
      'wishlistCount': 16,
      'availableQuantity': 4,
      'description': 'Stylish handmade bag made from old denim fabric.',
      'image': '',
      'images': <String>[],
    },
    {
      'id': '6',
      'title': 'Recycled Bookshelf',
      'price': 3200,
      'condition': 'Recycled',
      'category': 'Furniture',
      'seller': 'Eco Makers',
      'location': 'Ahmedabad',
      'views': 87,
      'wishlistCount': 11,
      'availableQuantity': 2,
      'description': 'Compact bookshelf crafted using reclaimed materials.',
      'image': '',
      'images': <String>[],
    },
  ];

  @override
  void initState() {
    super.initState();

    _searchQuery = widget.initialSearch ?? '';
    _selectedCategory = widget.initialCategory ?? 'All';

    _searchController.text = _searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> filtered = List.from(_products);

    if (_selectedCategory != 'All') {
      filtered = filtered.where((product) {
        return product['category'] == _selectedCategory;
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();

      filtered = filtered.where((product) {
        return product['title'].toString().toLowerCase().contains(query) ||
            product['category'].toString().toLowerCase().contains(query) ||
            product['seller'].toString().toLowerCase().contains(query) ||
            product['description'].toString().toLowerCase().contains(query) ||
            product['location'].toString().toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedCondition != 'All') {
      filtered = filtered.where((product) {
        return product['condition'] == _selectedCondition;
      }).toList();
    }

    filtered = filtered.where((product) {
      final price = (product['price'] as num).toDouble();

      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    switch (_selectedSort) {
      case 'Price: Low to High':
        filtered.sort(
          (a, b) => (a['price'] as num).compareTo(b['price'] as num),
        );
        break;

      case 'Price: High to Low':
        filtered.sort(
          (a, b) => (b['price'] as num).compareTo(a['price'] as num),
        );
        break;

      case 'Popular':
        filtered.sort(
          (a, b) => (b['views'] as num).compareTo(a['views'] as num),
        );
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Marketplace',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategories(),
          _buildFilterSortRow(),
          Expanded(
            child: _filteredProducts.isEmpty
                ? _buildEmptyState()
                : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: ArtistTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: ArtistTextStyles.hint,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ArtistColors.primary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ArtistColors.textSecondary,
                  ),
                )
              : null,
          filled: true,
          fillColor: ArtistColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ArtistColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ArtistColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: ArtistColors.primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = _selectedCategory == category;

          return ChoiceChip(
            label: Text(
              category,
              style: ArtistTextStyles.caption.copyWith(
                color: selected ? Colors.white : ArtistColors.textPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
              });
            },
            selectedColor: ArtistColors.primary,
            backgroundColor: ArtistColors.surface,
            side: BorderSide(
              color: selected ? ArtistColors.primary : ArtistColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildFilterSortRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showFilterSheet,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(
                'Filter',
                style: ArtistTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ArtistColors.primary,
                side: const BorderSide(color: ArtistColors.border),
                backgroundColor: ArtistColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showSortSheet,
              icon: const Icon(Icons.sort_rounded, size: 18),
              label: Text(
                'Sort',
                style: ArtistTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: ArtistColors.primary,
                side: const BorderSide(color: ArtistColors.border),
                backgroundColor: ArtistColors.surface,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return _ProductCard(
          product: _filteredProducts[index],
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Opening ${_filteredProducts[index]['title']}',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: ArtistColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: ArtistColors.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: ArtistColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No products found',
              style: ArtistTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your search or filters.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Reset Filters', style: ArtistTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    String tempCondition = _selectedCondition;
    RangeValues tempRange = _priceRange;

    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Filters', style: ArtistTextStyles.title),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            tempCondition = 'All';
                            tempRange = const RangeValues(0, 50000);
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
                  const SizedBox(height: 20),
                  Text('Condition', style: ArtistTextStyles.label),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _conditions.map((condition) {
                      final selected = tempCondition == condition;

                      return ChoiceChip(
                        label: Text(
                          condition,
                          style: ArtistTextStyles.caption.copyWith(
                            color: selected
                                ? Colors.white
                                : ArtistColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) {
                          setSheetState(() {
                            tempCondition = condition;
                          });
                        },
                        selectedColor: ArtistColors.primary,
                        backgroundColor: ArtistColors.surfaceSoft,
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('Price Range', style: ArtistTextStyles.label),
                  RangeSlider(
                    values: tempRange,
                    min: 0,
                    max: 50000,
                    divisions: 100,
                    activeColor: ArtistColors.primary,
                    inactiveColor: ArtistColors.border,
                    labels: RangeLabels(
                      '₹${tempRange.start.round()}',
                      '₹${tempRange.end.round()}',
                    ),
                    onChanged: (value) {
                      setSheetState(() {
                        tempRange = value;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${tempRange.start.round()}',
                        style: ArtistTextStyles.caption,
                      ),
                      Text(
                        '₹${tempRange.end.round()}',
                        style: ArtistTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCondition = tempCondition;
                          _priceRange = tempRange;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArtistColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: ArtistTextStyles.button,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortSheet() {
    final options = [
      'Newest',
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
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sort By', style: ArtistTextStyles.title),
                const SizedBox(height: 12),
                ...options.map(
                  (option) => RadioListTile<String>(
                    value: option,
                    groupValue: _selectedSort,
                    activeColor: ArtistColors.primary,
                    title: Text(option, style: ArtistTextStyles.bodyMedium),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedSort = value;
                      });

                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetFilters() {
    _searchController.clear();

    setState(() {
      _selectedCategory = 'All';
      _searchQuery = '';
      _selectedCondition = 'All';
      _selectedSort = 'Newest';
      _priceRange = const RangeValues(0, 50000);
    });
  }
}

class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isWishlisted = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ArtistColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 8,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: ArtistColors.surfaceSoft,
                    child: product['image'].toString().isNotEmpty
                        ? Image.network(
                            product['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.image_not_supported_outlined,
                                color: ArtistColors.textMuted,
                                size: 40,
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: ArtistColors.primary,
                              size: 42,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ArtistColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product['condition'],
                        style: ArtistTextStyles.small.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: ArtistColors.surface.withOpacity(0.92),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isWishlisted = !_isWishlisted;
                          });
                        },
                        icon: Icon(
                          _isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isWishlisted
                              ? ArtistColors.error
                              : ArtistColors.textSecondary,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(7),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['category'],
                      style: ArtistTextStyles.small.copyWith(
                        color: ArtistColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '₹${product['price']}',
                      style: ArtistTextStyles.title.copyWith(
                        fontSize: 16,
                        color: ArtistColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: ArtistColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            product['seller'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ArtistTextStyles.small,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: ArtistColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            product['location'],
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
            ),
          ],
        ),
      ),
    );
  }
}
