import 'package:flutter/material.dart';

import '../../../services/ecoloop_api.dart';
import '../../artist/profile/artist_profile.dart';
import 'product_details.dart';
import 'seller_profile.dart';
import 'wishlist.dart';

/// EcoLoop marketplace backed by the existing Google Apps Script API.
/// Expected API: GET /products, GET /categories, GET /wishlist,
/// POST /wishlist {productId: ...}, DELETE /wishlist/:productId.
/// No demo/sample products are inserted when the API returns an empty list.
class Marketplace extends StatefulWidget {
  const Marketplace({super.key, this.initialSearch, this.initialCategory});

  final String? initialSearch;
  final String? initialCategory;

  @override
  State<Marketplace> createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  Set<String> _wishlistIds = <String>{};
  List<Map<String, dynamic>> _wishlistProducts = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _loadingMore = false;
  bool _wishlistLoading = false;
  String? _error;
  String _query = '';
  String _selectedCategory = 'All';
  String _selectedCondition = 'Any condition';
  String _sortBy = 'Newest';
  double _minPrice = 0;
  double _maxPrice = 100000;
  bool _filtersApplied = false;
  int _page = 1;
  static const int _pageSize = 24;
  bool _hasMore = true;

  Color get _primary => Theme.of(context).colorScheme.primary;

  Color get _surface => Theme.of(context).colorScheme.surface;

  Color get _onSurface => Theme.of(context).colorScheme.onSurface;

  @override
  void initState() {
    super.initState();
    _query = widget.initialSearch?.trim() ?? '';
    _selectedCategory = (widget.initialCategory?.trim().isNotEmpty ?? false)
        ? widget.initialCategory!.trim()
        : 'All';
    _searchController.text = _query;
    _loadMarketplace();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 360) {
      _loadMore();
    }
  }

  String _id(dynamic value) => value == null ? '' : value.toString().trim();

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map)
      return value.map((key, val) => MapEntry(key.toString(), val));
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractList(dynamic response, List<String> keys) {
    if (response is List) {
      return response.map(_asMap).where((m) => m.isNotEmpty).toList();
    }
    final map = _asMap(response);
    for (final key in keys) {
      final value = map[key];
      if (value is List) {
        return value.map(_asMap).where((m) => m.isNotEmpty).toList();
      }
    }
    final data = _asMap(map['data']);
    for (final key in keys) {
      final value = data[key];
      if (value is List) {
        return value.map(_asMap).where((m) => m.isNotEmpty).toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _loadMarketplace({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }
    if (mounted) {
      setState(() {
        _loading = !refresh;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<dynamic>([
        _api.get(
          '/products',
          query: <String, dynamic>{
            'page': _page,
            'limit': _pageSize,
            'status': 'published',
          },
        ),
        _api.get('/categories'),
        _api.get('/wishlist'),
      ]);
      final productRows = _extractList(results[0], const [
        'products',
        'items',
        'results',
      ]);
      final categoryRows = _extractList(results[1], const [
        'categories',
        'items',
        'results',
      ]);
      final wishlistRows = _extractList(results[2], const [
        'items',
        'products',
        'wishlist',
      ]);
      final wishIds = <String>{};
      final wishProducts = <Map<String, dynamic>>[];
      for (final item in wishlistRows) {
        final nestedProduct = _asMap(item['product']);
        final product = nestedProduct.isNotEmpty ? nestedProduct : item;
        final id = _id(
          item['productId'] ??
              item['product_id'] ??
              item['id'] ??
              product['productId'] ??
              product['product_id'] ??
              product['id'],
        );
        if (id.isNotEmpty) {
          wishIds.add(id);
          if (product.containsKey('title') || product.containsKey('name')) {
            wishProducts.add(<String, dynamic>{...product, 'productId': id});
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _products = productRows.where(_isPublished).toList();
        _categories = categoryRows;
        _wishlistIds = wishIds;
        _wishlistProducts = wishProducts;
        _hasMore = productRows.length >= _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final response = await _api.get(
        '/products',
        query: <String, dynamic>{
          'page': nextPage,
          'limit': _pageSize,
          'status': 'published',
        },
      );
      final rows = _extractList(response, const [
        'products',
        'items',
        'results',
      ]).where(_isPublished).toList();
      if (!mounted) return;
      setState(() {
        _products.addAll(
          rows.where(
            (item) => !_products.any(
              (existing) =>
                  _id(existing['productId'] ?? existing['id']) ==
                  _id(item['productId'] ?? item['id']),
            ),
          ),
        );
        _page = nextPage;
        _hasMore = rows.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  bool _isPublished(Map<String, dynamic> product) {
    final status = (product['status'] ?? 'published').toString().toLowerCase();
    final available = _number(
      product['availableQuantity'] ?? product['quantity'],
      fallback: 1,
    );
    return (status.isEmpty || status == 'published' || status == 'active') &&
        available > 0;
  }

  double _number(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(
      (value ?? '').toString().replaceAll(',', '').replaceAll('₹', '').trim(),
    );
    return parsed ?? fallback;
  }

  String _productId(Map<String, dynamic> product) =>
      _id(product['productId'] ?? product['product_id'] ?? product['id']);

  String _title(Map<String, dynamic> product) =>
      (product['title'] ?? product['name'] ?? 'Untitled item').toString();

  String _categoryName(Map<String, dynamic> product) {
    final value =
        product['categoryName'] ??
        product['category'] ??
        product['categoryTitle'];
    if (value is Map) return (value['name'] ?? value['title'] ?? '').toString();
    if (value != null && value.toString().trim().isNotEmpty)
      return value.toString();
    final id = _id(product['categoryId']);
    for (final category in _categories) {
      if (_id(category['categoryId'] ?? category['id']) == id) {
        return (category['name'] ?? category['title'] ?? 'Other').toString();
      }
    }
    return 'Other';
  }

  List<String> _images(Map<String, dynamic> product) {
    final raw =
        product['imageUrls'] ??
        product['images'] ??
        product['imageUrl'] ??
        product['image'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.startsWith('http'))
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      // Some existing rows store image URLs as JSON or comma-separated text.
      final text = raw.trim();
      if (text.startsWith('[') && text.endsWith(']')) {
        return text
            .substring(1, text.length - 1)
            .split(',')
            .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((e) => e.startsWith('http'))
            .toList();
      }
      return text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.startsWith('http'))
          .toList();
    }
    return <String>[];
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final q = _query.trim().toLowerCase();
    final list = _products.where((product) {
      final title = _title(product).toLowerCase();
      final description = (product['description'] ?? '')
          .toString()
          .toLowerCase();
      final category = _categoryName(product).toLowerCase();
      final seller = (product['sellerName'] ?? product['seller'] ?? '')
          .toString()
          .toLowerCase();
      final location =
          '${product['sellerCity'] ?? product['city'] ?? ''} ${product['sellerState'] ?? product['state'] ?? ''}'
              .toLowerCase();
      final price = _number(product['price']);
      final condition = (product['condition'] ?? '').toString().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          '$title $description $category $seller $location'.contains(q);
      final matchesCategory =
          _selectedCategory == 'All' ||
          category == _selectedCategory.toLowerCase();
      final matchesCondition =
          _selectedCondition == 'Any condition' ||
          condition == _selectedCondition.toLowerCase();
      final matchesPrice =
          !_filtersApplied || (price >= _minPrice && price <= _maxPrice);
      return matchesQuery &&
          matchesCategory &&
          matchesCondition &&
          matchesPrice;
    }).toList();
    switch (_sortBy) {
      case 'Price: low to high':
        list.sort((a, b) => _number(a['price']).compareTo(_number(b['price'])));
        break;
      case 'Price: high to low':
        list.sort((a, b) => _number(b['price']).compareTo(_number(a['price'])));
        break;
      case 'Title A–Z':
        list.sort(
          (a, b) => _title(a).toLowerCase().compareTo(_title(b).toLowerCase()),
        );
        break;
      default:
        list.sort(
          (a, b) => _dateValue(
            b['createdAt'] ?? b['created_at'],
          ).compareTo(_dateValue(a['createdAt'] ?? a['created_at'])),
        );
    }
    return list;
  }

  DateTime _dateValue(dynamic value) =>
      DateTime.tryParse((value ?? '').toString()) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.toLowerCase().contains('socket') ||
        text.toLowerCase().contains('network')) {
      return 'Could not connect. Check your internet connection and try again.';
    }
    return text.isEmpty
        ? 'Marketplace could not be loaded. Please try again.'
        : text;
  }

  Future<void> _toggleWishlist(Map<String, dynamic> product) async {
    final id = _productId(product);
    if (id.isEmpty || _wishlistLoading) return;
    final wasSaved = _wishlistIds.contains(id);
    // Optimistic UI, reverted if the API request fails.
    setState(() {
      if (wasSaved) {
        _wishlistIds.remove(id);
      } else {
        _wishlistIds.add(id);
      }
      _wishlistLoading = true;
    });
    try {
      if (wasSaved) {
        await _api.delete('/wishlist/$id');
      } else {
        await _api.post('/wishlist', <String, dynamic>{'productId': id});
      }
      if (mounted) {
        setState(() {
          if (wasSaved) {
            _wishlistProducts.removeWhere((p) => _productId(p) == id);
          } else if (!_wishlistProducts.any((p) => _productId(p) == id)) {
            _wishlistProducts.add(product);
          }
        });
        _toast(wasSaved ? 'Removed from wishlist' : 'Saved to wishlist');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _wishlistIds.add(id);
        } else {
          _wishlistIds.remove(id);
        }
      });
      _toast('Wishlist update failed: ${_friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _openFilters() async {
    var condition = _selectedCondition;
    var minPrice = _minPrice;
    var maxPrice = _maxPrice;
    var sort = _sortBy;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filter & sort',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Condition',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                              'Any condition',
                              'Like New',
                              'Excellent',
                              'Good',
                              'Fair',
                              'Refurbished',
                            ]
                            .map(
                              (item) => ChoiceChip(
                                label: Text(item),
                                selected:
                                    condition.toLowerCase() ==
                                    item.toLowerCase(),
                                onSelected: (_) =>
                                    setSheetState(() => condition = item),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Price range: ₹${minPrice.round()} – ₹${maxPrice.round()}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  RangeSlider(
                    values: RangeValues(
                      minPrice.clamp(0, 100000).toDouble(),
                      maxPrice.clamp(0, 100000).toDouble(),
                    ),
                    min: 0,
                    max: 100000,
                    divisions: 100,
                    onChanged: (v) => setSheetState(() {
                      minPrice = v.start;
                      maxPrice = v.end;
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sort by',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: sort,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items:
                        const [
                              'Newest',
                              'Price: low to high',
                              'Price: high to low',
                              'Title A–Z',
                            ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (v) => setSheetState(() => sort = v ?? 'Newest'),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              condition = 'Any condition';
                              minPrice = 0;
                              maxPrice = 100000;
                              sort = 'Newest';
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(sheetContext, true),
                          child: const Text('Apply filters'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _selectedCondition = condition;
        _minPrice = minPrice;
        _maxPrice = maxPrice;
        _sortBy = sort;
        _filtersApplied = minPrice > 0 || maxPrice < 100000;
      });
    }
  }

  bool _isArtistSeller(Map<String, dynamic> product) {
    final raw =
        (product['sellerType'] ??
                product['sellerRole'] ??
                product['seller_type'] ??
                product['role'] ??
                'user')
            .toString()
            .trim()
            .toLowerCase();
    return const {'artist', 'remaker', 're_maker', 're-maker'}.contains(raw);
  }

  void _openSellerProfile(Map<String, dynamic> product) {
    final artist = _isArtistSeller(product);
    final city = (product['sellerCity'] ?? product['city'] ?? '').toString();
    final state = (product['sellerState'] ?? product['state'] ?? '').toString();
    final location = [city, state].where((v) => v.trim().isNotEmpty).join(', ');
    final sellerId =
        product['sellerId'] ??
        product['seller_id'] ??
        product['artistId'] ??
        product['userId'];
    final name =
        (product['sellerName'] ??
                product['seller'] ??
                (artist ? 'EcoLoop ReMaker' : 'EcoLoop Member'))
            .toString();
    if (artist) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ArtistProfile(
            artist: {
              'artistId': sellerId,
              'id': sellerId,
              'name': name,
              'userName': name,
              'location': location,
              'city': city,
              'state': state,
              'sellerType': 'artist',
            },
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SellerProfile(
            seller: {
              'userId': sellerId,
              'id': sellerId,
              'name': name,
              'location': location,
              'city': city,
              'state': state,
              'sellerType': 'user',
            },
          ),
        ),
      );
    }
  }

  void _openProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => ProductDetails(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100 ? 4 : width >= 700 ? 3 : 2;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text(
          'Marketplace',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.4),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh marketplace',
            onPressed: () => _loadMarketplace(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Wishlist',
            onPressed: _openWishlist,
            icon: Badge(
              label: Text('${_wishlistIds.length}'),
              isLabelVisible: _wishlistIds.isNotEmpty,
              child: const Icon(Icons.favorite_border_rounded),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMarketplace(refresh: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search items, categories, sellers',
                        hintStyle: TextStyle(color: muted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        filled: true,
                        fillColor: _surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: theme.dividerColor.withValues(alpha: .35),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: theme.dividerColor.withValues(alpha: .35),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: _primary, width: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Categories',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.2,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _openFilters,
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('Filter & sort'),
                          style: TextButton.styleFrom(
                            foregroundColor: _primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          _categoryChip('All'),
                          ..._categories
                              .map((category) =>
                                  (category['name'] ?? category['title'] ?? '')
                                      .toString()
                                      .trim())
                              .where((name) => name.isNotEmpty)
                              .toSet()
                              .map(_categoryChip),
                          ..._products
                              .map(_categoryName)
                              .where((name) => name.isNotEmpty && name != 'Other')
                              .toSet()
                              .where((name) => !_categories.any((category) =>
                                  (category['name'] ?? category['title'] ?? '')
                                      .toString()
                                      .toLowerCase() ==
                                  name.toLowerCase()))
                              .map(_categoryChip),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _query.isEmpty ? 'Explore items' : 'Search results',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.5,
                            ),
                          ),
                        ),
                        Text(
                          '${products.length} ${products.length == 1 ? 'item' : 'items'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_filtersApplied ||
                        _selectedCondition != 'Any condition' ||
                        _sortBy != 'Newest') ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 7,
                        runSpacing: 6,
                        children: [
                          if (_selectedCondition != 'Any condition')
                            InputChip(
                              label: Text(_selectedCondition),
                              onDeleted: () => setState(
                                () => _selectedCondition = 'Any condition',
                              ),
                            ),
                          if (_filtersApplied)
                            InputChip(
                              label: Text(
                                '₹${_minPrice.round()}–₹${_maxPrice.round()}',
                              ),
                              onDeleted: () => setState(() {
                                _minPrice = 0;
                                _maxPrice = 100000;
                                _filtersApplied = false;
                              }),
                            ),
                          if (_sortBy != 'Newest')
                            InputChip(
                              label: Text(_sortBy),
                              onDeleted: () =>
                                  setState(() => _sortBy = 'Newest'),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(
                  Icons.cloud_off_rounded,
                  'Could not load marketplace',
                  _error!,
                  action: TextButton.icon(
                    onPressed: () => _loadMarketplace(refresh: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ),
              )
            else if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(
                  Icons.search_off_rounded,
                  _products.isEmpty
                      ? 'No products available yet'
                      : 'No matching products',
                  _products.isEmpty
                      ? 'Published listings from EcoLoop users and ReMakers will appear here.'
                      : 'Try another search or clear your filters.',
                  action: _query.isNotEmpty ||
                          _filtersApplied ||
                          _selectedCondition != 'Any condition' ||
                          _selectedCategory != 'All'
                      ? TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear search and filters'),
                        )
                      : null,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: width < 380 ? .62 : width < 700 ? .66 : .70,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _productCard(products[index]),
                    childCount: products.length,
                  ),
                ),
              ),
            if (_loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (!_hasMore && products.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24, top: 4),
                  child: Center(
                    child: Text(
                      'You’re all caught up',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String name) {
    final selected = _selectedCategory.toLowerCase() == name.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: selected,
        onSelected: (_) => setState(() => _selectedCategory = name),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
        selectedColor: _primary,
        backgroundColor: _surface,
        side: BorderSide(
          color: selected ? _primary : Theme.of(context).dividerColor.withValues(alpha: .5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final images = _images(product);
    final id = _productId(product);
    final saved = _wishlistIds.contains(id);
    final price = _number(product['price']);
    final seller =
        (product['sellerName'] ?? product['seller'] ?? 'EcoLoop member').toString();
    final city = (product['sellerCity'] ?? product['city'] ?? '').toString();
    final state = (product['sellerState'] ?? product['state'] ?? '').toString();
    final location = [city, state].where((e) => e.trim().isNotEmpty).join(', ');
    final condition = (product['condition'] ?? 'Pre-loved').toString();

    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openProduct(product),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: .35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (images.isNotEmpty)
                      Image.network(
                        images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _imageFallback(),
                      )
                    else
                      _imageFallback(),
                    Positioned(
                      left: 9,
                      top: 9,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 125),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .94),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          condition,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: .96),
                        shape: const CircleBorder(),
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                          padding: EdgeInsets.zero,
                          tooltip: saved ? 'Remove from wishlist' : 'Add to wishlist',
                          onPressed: () => _toggleWishlist(product),
                          icon: Icon(
                            saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: saved ? Colors.redAccent : _primary,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _categoryName(product).toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _primary,
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _title(product),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      InkWell(
                        onTap: () => _openSellerProfile(product),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          children: [
                            Icon(
                              _isArtistSeller(product)
                                  ? Icons.palette_outlined
                                  : Icons.person_outline_rounded,
                              size: 13,
                              color: _primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                seller,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: _primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 15),
                          ],
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(
      Icons.image_not_supported_outlined,
      size: 42,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  Widget _emptyState(
    IconData icon,
    String title,
    String message, {
    Widget? action,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 54,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    ),
  );

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedCategory = 'All';
      _selectedCondition = 'Any condition';
      _minPrice = 0;
      _maxPrice = 100000;
      _filtersApplied = false;
      _sortBy = 'Newest';
    });
  }

  void _openWishlist() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const Wishlist()),
    ).then((_) => _loadMarketplace(refresh: true));
  }
}

/// Compatibility alias for routes that name the screen MarketplaceScreen.
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) => const Marketplace();
}
