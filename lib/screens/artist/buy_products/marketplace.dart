import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
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
  RangeValues priceRange = const RangeValues(0, 1000);

  final TextEditingController _searchController = TextEditingController();

  /// Categories and conditions are populated from real backend data.
  List<String> categories = <String>['All'];
  List<String> conditions = <String>['All'];
  final List<Map<String, dynamic>> products = [];

  bool _loadingProducts = true;
  String? _loadError;
  double _priceCeiling = 1000;
  int? _currentArtistId;

  /// Reads the authenticated artist ID from the existing /auth/me response.
  /// The API may return the account directly or wrap it in data/account/user.
  int? _artistIdFromResponse(dynamic response) {
    dynamic current = response;

    for (var depth = 0; depth < 4; depth++) {
      if (current is! Map) return null;

      final map = Map<String, dynamic>.from(current);
      final role = _cleanString(
        map['role'] ?? map['accountType'],
      ).toLowerCase();

      final rawId =
          map['artistId'] ??
          (role == 'artist' ? map['accountId'] ?? map['id'] : null);
      final parsedId = _toInt(rawId, fallback: -1);
      if (parsedId > 0) return parsedId;

      if (map['account'] is Map) {
        current = map['account'];
      } else if (map['artist'] is Map) {
        current = map['artist'];
      } else if (map['user'] is Map) {
        current = map['user'];
      } else if (map['data'] is Map) {
        current = map['data'];
      } else {
        return null;
      }
    }

    return null;
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().trim()) ?? fallback;
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim()) ?? fallback;
  }

  String _cleanString(dynamic value, {String fallback = ''}) {
    final result = (value ?? '').toString().trim();
    return result.isEmpty ? fallback : result;
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _loadingProducts = true;
        _loadError = null;
      });
    }

    try {
      // Identify the signed-in artist first so their own listings can never
      // appear as purchasable marketplace products.
      final rawAccount = await EcoLoopApi.instance.get('/auth/me');
      final artistId = _artistIdFromResponse(rawAccount);
      if (artistId == null) {
        throw Exception(
          'Could not identify the signed-in artist. Please sign in again and retry.',
        );
      }
      _currentArtistId = artistId;

      // Product and category data both come from the existing Apps Script API.
      final rawProducts = await EcoLoopApi.instance.get('/products');

      // Category lookup is supported by the current Code.gs. If that endpoint
      // is temporarily unavailable, still show products rather than failing
      // the entire marketplace screen.
      dynamic rawCategories = <dynamic>[];
      try {
        rawCategories = await EcoLoopApi.instance.get('/categories');
      } catch (_) {
        rawCategories = <dynamic>[];
      }

      final categoryRows = (rawCategories is List ? rawCategories : <dynamic>[])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      final categoryMap = <String, String>{};
      for (final category in categoryRows) {
        final id = _cleanString(category['categoryId'] ?? category['id']);
        final name = _cleanString(category['name'] ?? category['categoryName']);
        final status = _cleanString(
          category['status'],
          fallback: 'active',
        ).toLowerCase();
        if (name.isNotEmpty && (status.isEmpty || status == 'active')) {
          if (id.isNotEmpty) categoryMap[id] = name;
        }
      }

      final rows = (rawProducts is List ? rawProducts : <dynamic>[])
          .whereType<Map>()
          .map((raw) {
            final product = Map<String, dynamic>.from(raw);
            final rawImages = product['imageUrls'];
            final images = rawImages is List
                ? rawImages
                      .map((image) => image.toString().trim())
                      .where((image) => image.isNotEmpty)
                      .toList()
                : <String>[];

            final categoryId = _cleanString(product['categoryId']);
            final category = _cleanString(
              product['categoryName'] ?? product['category'],
              fallback:
                  categoryMap[categoryId] ??
                  (categoryId.isNotEmpty ? 'Category $categoryId' : 'Other'),
            );
            final location =
                [
                      product['sellerCity'] ?? product['city'],
                      product['sellerState'] ?? product['state'],
                    ]
                    .map((value) => _cleanString(value))
                    .where((value) => value.isNotEmpty)
                    .join(', ');

            return <String, dynamic>{
              ...product,
              'productId': product['productId'] ?? product['id'],
              'category': category,
              'seller': _cleanString(
                product['sellerName'],
                fallback: 'EcoLoop Member',
              ),
              'location': location,
              'imageUrls': images,
              'image': images.isNotEmpty ? images.first : '',
              'price': _toDouble(product['price']),
              'views': _toInt(product['views']),
              'wishlistCount': _toInt(
                product['wishlistCount'] ?? product['likes'],
              ),
              'availableQuantity': _toInt(
                product['availableQuantity'] ?? product['quantity'],
              ),
              'condition': _cleanString(
                product['condition'],
                fallback: 'Not specified',
              ),
              'listingType': _cleanString(
                product['listingType'],
                fallback: 'c2c',
              ),
              'status': _cleanString(product['status']).toLowerCase(),
              'title': _cleanString(
                product['title'],
                fallback: 'Untitled item',
              ),
              'description': _cleanString(product['description']),
            };
          })
          .where((product) => product['status'] == 'published')
          // Hide only products owned by this artist. Products belonging to
          // regular users or other artists remain visible.
          .where((product) {
            final sellerType = _cleanString(
              product['sellerType'],
              fallback: 'user',
            ).toLowerCase();
            final sellerId = _toInt(product['sellerId'], fallback: -1);
            return !(sellerType == 'artist' &&
                _currentArtistId != null &&
                sellerId == _currentArtistId);
          })
          .toList();

      rows.sort((a, b) {
        final dateA = DateTime.tryParse(_cleanString(a['createdAt']));
        final dateB = DateTime.tryParse(_cleanString(b['createdAt']));
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });

      final dynamicConditions =
          rows
              .map((product) => _cleanString(product['condition']))
              .where(
                (condition) =>
                    condition.isNotEmpty && condition != 'Not specified',
              )
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      final dynamicCategories = categoryMap.values.toSet().toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      // Include categories returned by products too, for older records whose
      // category is no longer in the active category list.
      for (final product in rows) {
        final category = _cleanString(product['category']);
        if (category.isNotEmpty &&
            category != 'Other' &&
            !dynamicCategories.contains(category)) {
          dynamicCategories.add(category);
        }
      }

      final maximumPrice = rows.fold<double>(0, (maximum, product) {
        final price = _toDouble(product['price']);
        return price > maximum ? price : maximum;
      });
      final ceiling = maximumPrice > 0 ? maximumPrice : 1000.0;

      if (!mounted) return;
      setState(() {
        products
          ..clear()
          ..addAll(rows);
        categories = <String>['All', ...dynamicCategories];
        conditions = <String>['All', ...dynamicConditions];
        _priceCeiling = ceiling;

        if (!categories.contains(selectedCategory)) {
          selectedCategory = 'All';
        }
        if (!conditions.contains(selectedCondition)) {
          selectedCondition = 'All';
        }
        priceRange = RangeValues(0, _priceCeiling);
        _loadingProducts = false;
        _loadError = null;

        if (widget.initialCategory != null &&
            categories.any(
              (category) =>
                  category.toLowerCase() ==
                  widget.initialCategory!.trim().toLowerCase(),
            )) {
          selectedCategory = categories.firstWhere(
            (category) =>
                category.toLowerCase() ==
                widget.initialCategory!.trim().toLowerCase(),
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
        _loadError = error.toString();
      });
    }
  }

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filters products based on selected category, search term, condition, price, and status.
  List<Map<String, dynamic>> get filteredProducts {
    var result = List<Map<String, dynamic>>.from(products);

    if (selectedCategory != 'All') {
      result = result
          .where(
            (product) =>
                _cleanString(product['category']).toLowerCase() ==
                selectedCategory.toLowerCase(),
          )
          .toList();
    }

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((product) {
        final searchableFields = [
          product['title'],
          product['category'],
          product['seller'],
          product['description'],
          product['location'],
        ];
        return searchableFields.any(
          (value) => _cleanString(value).toLowerCase().contains(query),
        );
      }).toList();
    }

    if (selectedCondition != 'All') {
      result = result
          .where(
            (product) =>
                _cleanString(product['condition']).toLowerCase() ==
                selectedCondition.toLowerCase(),
          )
          .toList();
    }

    result = result.where((product) {
      final price = _toDouble(product['price']);
      return price >= priceRange.start && price <= priceRange.end;
    }).toList();

    switch (selectedSort) {
      case 'Price: Low to High':
        result.sort(
          (a, b) => _toDouble(a['price']).compareTo(_toDouble(b['price'])),
        );
        break;
      case 'Price: High to Low':
        result.sort(
          (a, b) => _toDouble(b['price']).compareTo(_toDouble(a['price'])),
        );
        break;
      case 'Popular':
        result.sort((a, b) => _toInt(b['views']).compareTo(_toInt(a['views'])));
        break;
      case 'Newest First':
      default:
        result.sort((a, b) {
          final dateA = DateTime.tryParse(_cleanString(a['createdAt']));
          final dateB = DateTime.tryParse(_cleanString(b['createdAt']));
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
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
            Expanded(
              child: RefreshIndicator(
                color: ArtistColors.primary,
                onRefresh: _loadProducts,
                child: _buildProductGrid(),
              ),
            ),
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

    if (_loadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          const SizedBox(height: 90),
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: ArtistColors.primary,
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Could not load marketplace',
              style: ArtistTextStyles.title,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption,
          ),
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: 360, child: _buildEmptyState())],
      );
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
                                temporaryPrice = RangeValues(0, _priceCeiling);
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
                        max: _priceCeiling,
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
      priceRange = RangeValues(0, _priceCeiling);
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
    final double priceValue = product['price'] is num
        ? (product['price'] as num).toDouble()
        : double.tryParse('${product['price']}') ?? 0;
    final String price = priceValue == priceValue.roundToDouble()
        ? priceValue.toStringAsFixed(0)
        : priceValue.toStringAsFixed(2);
    final rawImages = product['imageUrls'];
    final List<dynamic> imageUrls = rawImages is List ? rawImages : <dynamic>[];
    final String image = imageUrls.isNotEmpty
        ? imageUrls.first.toString().trim()
        : '';

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
                    '₹$price',
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
