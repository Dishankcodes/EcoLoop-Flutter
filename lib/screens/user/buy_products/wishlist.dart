import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'product_details.dart';

/// Persistent wishlist for the signed-in account.
/// The backend scopes wishlist records by account type (user or artist).
class Wishlist extends StatefulWidget {
  const Wishlist({super.key});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final EcoLoopApi _api = EcoLoopApi.instance;

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  final Set<String> _removingIds = <String>{};
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'Recently saved';
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

  List<Map<String, dynamic>> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    final result = _items.where((item) {
      if (query.isEmpty) return true;
      final title = _text(item, ['title', 'name']).toLowerCase();
      final category = _text(item, [
        'category',
        'categoryName',
        'category_name',
      ]).toLowerCase();
      final seller = _text(item, [
        'sellerName',
        'seller_name',
        'seller',
        'artistName',
        'userName',
      ]).toLowerCase();
      return title.contains(query) ||
          category.contains(query) ||
          seller.contains(query);
    }).toList();

    if (_sortBy == 'Price: low to high') {
      result.sort(
        (a, b) => (_price(a) ?? double.infinity).compareTo(
          _price(b) ?? double.infinity,
        ),
      );
    } else if (_sortBy == 'Price: high to low') {
      result.sort((a, b) => (_price(b) ?? -1).compareTo(_price(a) ?? -1));
    } else if (_sortBy == 'Name: A–Z') {
      result.sort(
        (a, b) => _text(a, [
          'title',
          'name',
        ]).toLowerCase().compareTo(_text(b, ['title', 'name']).toLowerCase()),
      );
    }
    return result;
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is List) {
      return response.map(_map).where((row) => row.isNotEmpty).toList();
    }
    final root = _map(response);
    final data = _map(root['data']);
    for (final key in <String>['items', 'products', 'wishlist', 'results']) {
      final value = root[key] ?? data[key];
      if (value is List) {
        return value.map(_map).where((row) => row.isNotEmpty).toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  String _productId(Map<String, dynamic> product) {
    final nested = _map(product['product']);
    final value =
        product['productId'] ??
        product['product_id'] ??
        product['id'] ??
        nested['productId'] ??
        nested['product_id'] ??
        nested['id'];
    return value?.toString().trim() ?? '';
  }

  String _text(
    Map<String, dynamic> product,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = product[key];
      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString().toLowerCase() != 'null') {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  double? _price(Map<String, dynamic> product) {
    final raw =
        product['price'] ?? product['sellingPrice'] ?? product['selling_price'];
    if (raw is num) return raw.toDouble();
    final cleaned = (raw ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  String _formatPrice(double? value) {
    if (value == null) return 'Price unavailable';
    final whole = value == value.roundToDouble();
    return '₹${whole ? value.toStringAsFixed(0) : value.toStringAsFixed(2)}';
  }

  List<String> _images(Map<String, dynamic> product) {
    dynamic raw =
        product['imageUrls'] ??
        product['images'] ??
        product['imageUrl'] ??
        product['image_url'] ??
        product['image'];
    if (raw is List) {
      return raw
          .map((entry) => entry.toString().trim())
          .where(_isHttpUrl)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final value = raw.trim();
      // Handles JSON-encoded arrays as well as comma-separated legacy fields.
      final normalized = value
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll("'", '');
      return normalized
          .split(RegExp(r'[,;\n]'))
          .map((entry) => entry.trim())
          .where(_isHttpUrl)
          .toSet()
          .toList();
    }
    return <String>[];
  }

  bool _isHttpUrl(String value) =>
      value.startsWith('https://') || value.startsWith('http://');

  String _sellerType(Map<String, dynamic> product) {
    final value = _text(product, [
      'sellerType',
      'seller_type',
      'sellerRole',
      'seller_role',
      'role',
    ], fallback: 'user').toLowerCase();
    return <String>{'artist', 'remaker', 're-maker', 're_maker'}.contains(value)
        ? 'ReMaker'
        : 'User seller';
  }

  Future<void> _load({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      if (refresh) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _error = null;
    });

    try {
      final rows = _rows(await _api.get('/wishlist'));
      final cleaned = <Map<String, dynamic>>[];
      final seen = <String>{};

      for (final row in rows) {
        final nested = _map(row['product']);
        final item = nested.isNotEmpty
            ? <String, dynamic>{...row, ...nested}
            : <String, dynamic>{...row};
        final id = _productId(item).isNotEmpty
            ? _productId(item)
            : _productId(row);
        if (id.isEmpty || !seen.add(id)) continue;
        item['productId'] = id;
        // Keep records with a usable title even if the listing is missing optional fields.
        final title = _text(item, [
          'title',
          'name',
          'productName',
          'product_name',
        ]);
        if (title.isEmpty) continue;
        item['title'] = title;
        cleaned.add(item);
      }

      if (!mounted) return;
      setState(() {
        _items = cleaned;
        _loading = false;
        _refreshing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _refreshing = false;
      });
    }
  }

  Future<void> _remove(Map<String, dynamic> product) async {
    final id = _productId(product);
    if (id.isEmpty || _removingIds.contains(id)) return;

    final previous = List<Map<String, dynamic>>.from(_items);
    setState(() {
      _removingIds.add(id);
      _items.removeWhere((item) => _productId(item) == id);
    });

    try {
      await _api.delete('/wishlist/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Removed from your wishlist')),
        );
    } catch (error) {
      if (!mounted) return;
      setState(() => _items = previous);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Could not remove item: ${error.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _removingIds.remove(id));
    }
  }

  Future<void> _openProduct(Map<String, dynamic> product) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProductDetails(product: Map<String, dynamic>.from(product)),
      ),
    );
    // Product details can change wishlist state; resync when returning.
    if (mounted) _load(refresh: true);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Wishlist',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              '${_items.length} saved ${_items.length == 1 ? 'item' : 'items'}',
              style: TextStyle(
                color: primary.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh wishlist',
            onPressed: _refreshing ? null : () => _load(refresh: true),
            icon: _refreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _stateMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load your wishlist',
        message: _error!,
        actionLabel: 'Try again',
        onAction: () => _load(),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 70),
            _stateMessage(
              icon: Icons.favorite_border_rounded,
              title: 'Your wishlist is waiting',
              message:
                  'Save items you love from the marketplace. They’ll be kept here for you.',
              actionLabel: 'Refresh',
              onAction: () => _load(refresh: true),
            ),
          ],
        ),
      );
    }

    final visible = _visibleItems;
    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          _wishlistHero(),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search saved items, sellers...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: .10),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.primary, width: 1.3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your saved finds',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${visible.length} ${visible.length == 1 ? 'item' : 'items'}${_searchController.text.trim().isNotEmpty ? ' found' : ' saved for later'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Sort wishlist',
                initialValue: _sortBy,
                onSelected: (value) => setState(() => _sortBy = value),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'Recently saved',
                    child: Text('Recently saved'),
                  ),
                  PopupMenuItem(
                    value: 'Price: low to high',
                    child: Text('Price: low to high'),
                  ),
                  PopupMenuItem(
                    value: 'Price: high to low',
                    child: Text('Price: high to low'),
                  ),
                  PopupMenuItem(value: 'Name: A–Z', child: Text('Name: A–Z')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: .12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swap_vert_rounded,
                        size: 17,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Sort',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 44),
              child: _stateMessage(
                icon: Icons.search_off_rounded,
                title: 'No matching items',
                message: 'Try another product, category, or seller name.',
                actionLabel: 'Clear search',
                onAction: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 620 ? 3 : 2;
                final ratio = constraints.maxWidth < 360 ? .52 : .58;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: ratio,
                  ),
                  itemBuilder: (context, index) =>
                      _wishlistCard(visible[index]),
                );
              },
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.eco_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Good finds deserve a second life. Keep your favourites close until you’re ready.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wishlistHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(19, 20, 16, 19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: .86)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'YOUR PERSONAL COLLECTION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Loved it?\nSave it here.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A little place for things you love.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFFFD4D8),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_items.length} saved ${_items.length == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .24)),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 38,
              color: Color(0xFFFFD4D8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stateMessage({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wishlistCard(Map<String, dynamic> product) {
    final images = _images(product);
    final id = _productId(product);
    final title = _text(product, ['title', 'name'], fallback: 'Product');
    final seller = _text(
      product,
      ['sellerName', 'seller_name', 'seller', 'artistName', 'userName'],
      fallback: _sellerType(product) == 'ReMaker'
          ? 'ReMaker'
          : 'EcoLoop seller',
    );
    final category = _text(product, [
      'category',
      'categoryName',
      'category_name',
    ]);
    final removing = _removingIds.contains(id);
    final price = _formatPrice(_price(product));

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openProduct(product),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.75),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.15,
                    child: images.isEmpty
                        ? _imageFallback()
                        : Image.network(
                            images.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  _imageFallback(),
                                  Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                      value: progress.expectedTotalBytes == null
                                          ? null
                                          : progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!,
                                    ),
                                  ),
                                ],
                              );
                            },
                            errorBuilder: (_, __, ___) => _imageFallback(),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.96),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 38,
                          minHeight: 38,
                        ),
                        tooltip: 'Remove from wishlist',
                        onPressed: removing ? null : () => _remove(product),
                        icon: removing
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.favorite_rounded,
                                color: Colors.redAccent,
                              ),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.58),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${images.length} photos',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 9, 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          if (category.isNotEmpty) const SizedBox(height: 8),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                _sellerType(product) == 'ReMaker'
                                    ? Icons.brush_outlined
                                    : Icons.storefront_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  seller,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            price,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.07),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 42,
          color: AppColors.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
