import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../shared_preferences_util.dart';
import 'product_details.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({super.key});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _query = '';

  // Keep the last successful response in memory so revisiting Wishlist is instant.
  // The server remains the source of truth; stale data is refreshed in the background.
  static List<Map<String, dynamic>>? _cachedItems;
  static DateTime? _cacheUpdatedAt;
  static Future<List<Map<String, dynamic>>>? _inFlightRequest;
  static const Duration _cacheDuration = Duration(seconds: 45);
  static const Duration _requestDeadline = Duration(seconds: 12);

  String get _persistentCacheKey {
    final role = Prefs.getString('userRole').trim().toLowerCase();
    final token = role == 'artist'
        ? Prefs.getString('artistToken')
        : Prefs.getString('authToken');
    // Scope cached wishlist data to the signed-in session, never share it between accounts.
    return 'artist_wishlist_cache_${role}_${token.hashCode}';
  }

  List<Map<String, dynamic>>? _readPersistentCache() {
    try {
      final raw = Prefs.getString(_persistentCacheKey);
      if (raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map(
            (row) => row.map((key, value) => MapEntry(key.toString(), value)),
          )
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePersistentCache(List<Map<String, dynamic>> items) async {
    try {
      await Prefs.setString(_persistentCacheKey, jsonEncode(items));
    } catch (_) {
      // Wishlist remains usable even if local caching is unavailable.
    }
  }

  Color get _primary => ArtistColors.primary;

  Color get _surface => ArtistColors.surface;

  Color get _background => ArtistColors.background;

  Color get _text => ArtistColors.textPrimary;

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is List) {
      return response.map(_map).where((row) => row.isNotEmpty).toList();
    }
    final root = _map(response);
    final data = root['data'];
    final dataMap = _map(data);
    for (final key in <String>['items', 'products', 'wishlist', 'results']) {
      final value = root[key] ?? dataMap[key] ?? (key == 'items' ? data : null);
      if (value is List) {
        return value.map(_map).where((row) => row.isNotEmpty).toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  String _id(Map<String, dynamic> product) {
    final nested = _map(product['product']);
    return (product['productId'] ??
            product['product_id'] ??
            product['id'] ??
            nested['productId'] ??
            nested['product_id'] ??
            nested['id'] ??
            '')
        .toString()
        .trim();
  }

  Future<List<Map<String, dynamic>>> _fetchWishlist() async {
    final response = await _api.get('/wishlist');
    final rows = _rows(response);
    final cleaned = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final row in rows) {
      final nested = _map(row['product']);
      final item = nested.isNotEmpty
          ? <String, dynamic>{...nested}
          : <String, dynamic>{...row};
      final rowId = _id(row);
      final id = rowId.isNotEmpty ? rowId : _id(item);
      if (id.isEmpty || !seen.add(id)) continue;
      item['productId'] = id;
      if (item['title'] != null || item['name'] != null) cleaned.add(item);
    }
    return cleaned;
  }

  Future<void> _load({bool forceRefresh = false}) async {
    if (!mounted) return;

    // Restore disk cache on first opening/app restart so the screen isn't blank
    // while Google Apps Script wakes up or processes the request.
    final cached = _cachedItems ?? _readPersistentCache();
    if (_cachedItems == null && cached != null) {
      _cachedItems = cached
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _cacheUpdatedAt ??= DateTime.now();
    }
    final cacheAge = _cacheUpdatedAt == null
        ? null
        : DateTime.now().difference(_cacheUpdatedAt!);
    final cacheIsFresh = cacheAge != null && cacheAge <= _cacheDuration;

    // Paint cached items first rather than blocking the entire page on Apps Script.
    if (cached != null) {
      setState(() {
        _items = cached.map((item) => Map<String, dynamic>.from(item)).toList();
        _loading = false;
        _error = null;
      });
      if (!forceRefresh && cacheIsFresh) return;
    } else {
      setState(() => _error = null);
      if (_items.isEmpty) setState(() => _loading = true);
    }

    try {
      final request = _inFlightRequest ??= _fetchWishlist();
      final fetched = await request.timeout(_requestDeadline);
      _cachedItems = fetched
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _cacheUpdatedAt = DateTime.now();
      await _savePersistentCache(fetched);
      if (!mounted) return;
      setState(() {
        _items = fetched;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      // Keep already-rendered cached data visible if a background refresh fails.
      setState(() {
        if (_items.isEmpty) {
          _error = error is TimeoutException
              ? 'Wishlist is taking too long to respond. Please retry; saved items will appear immediately when available.'
              : error.toString().replaceFirst('Exception: ', '');
        }
        _loading = false;
      });
    } finally {
      _inFlightRequest = null;
    }
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    if (_busy) return;
    final id = _id(item);
    if (id.isEmpty) {
      _message('Could not identify this product. Refresh and try again.');
      return;
    }
    final previous = List<Map<String, dynamic>>.from(_items);
    setState(() {
      _busy = true;
      _items.removeWhere((product) => _id(product) == id);
    });
    _cachedItems = _items
        .map((product) => Map<String, dynamic>.from(product))
        .toList();
    _cacheUpdatedAt = DateTime.now();
    await _savePersistentCache(_items);
    try {
      await _api.delete('/wishlist/$id');
      if (mounted) _message('Removed from wishlist');
    } catch (error) {
      if (!mounted) return;
      setState(() => _items = previous);
      _cachedItems = previous
          .map((product) => Map<String, dynamic>.from(product))
          .toList();
      _cacheUpdatedAt = DateTime.now();
      await _savePersistentCache(previous);
      _message(
        'Could not remove product: ${error.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _images(Map<String, dynamic> product) {
    final raw =
        product['imageUrls'] ??
        product['images'] ??
        product['imageUrl'] ??
        product['image'];
    if (raw is List) {
      return raw
          .map((value) => value.toString().trim())
          .where((value) => value.startsWith('http'))
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final value = raw.trim();
      if (value.startsWith('[') && value.endsWith(']')) {
        return value
            .substring(1, value.length - 1)
            .split(',')
            .map((part) => part.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((part) => part.startsWith('http'))
            .toList();
      }
      return value
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.startsWith('http'))
          .toList();
    }
    return <String>[];
  }

  List<Map<String, dynamic>> get _filteredItems {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((product) {
      final title = (product['title'] ?? product['name'] ?? '')
          .toString()
          .toLowerCase();
      final category = (product['category'] ?? product['categoryName'] ?? '')
          .toString()
          .toLowerCase();
      return title.contains(query) || category.contains(query);
    }).toList();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: ArtistTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
        ),
      );
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
    final items = _filteredItems;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          'Wishlist',
          style: ArtistTextStyles.heading.copyWith(fontSize: 20, color: _text),
        ),
        centerTitle: true,
        backgroundColor: _background,
        foregroundColor: _text,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh wishlist',
            onPressed: _loading ? null : () => _load(forceRefresh: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? _loadingView()
          : _error != null
          ? _errorView()
          : _items.isEmpty
          ? _emptyView()
          : RefreshIndicator(
              color: _primary,
              onRefresh: () => _load(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _primary.withValues(alpha: .15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.favorite_rounded, color: _primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_items.length} saved ${_items.length == 1 ? 'item' : 'items'}',
                                style: ArtistTextStyles.title.copyWith(
                                  fontSize: 16,
                                  color: _text,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Products you want to keep for later',
                                style: ArtistTextStyles.caption.copyWith(
                                  fontSize: 12,
                                  color: ArtistColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    style: ArtistTextStyles.bodyMedium.copyWith(color: _text),
                    decoration: InputDecoration(
                      hintText: 'Search saved products',
                      hintStyle: ArtistTextStyles.hint,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: ArtistColors.primary,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: _surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _primary.withValues(alpha: .12),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _primary, width: 1.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 44),
                      child: Center(
                        child: Text(
                          'No saved products match your search.',
                          style: ArtistTextStyles.body.copyWith(
                            color: ArtistColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...items.map(_productCard),
                ],
              ),
            ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final images = _images(product);
    final title = (product['title'] ?? product['name'] ?? 'Product').toString();
    final price = product['price'];
    final id = _id(product);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
          ).then((_) => _load()),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _primary.withValues(alpha: .13)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 94,
                    height: 104,
                    child: images.isEmpty
                        ? Container(
                            color: _primary.withValues(alpha: .07),
                            child: Icon(
                              Icons.image_outlined,
                              color: _primary,
                              size: 32,
                            ),
                          )
                        : Image.network(
                            images.first,
                            fit: BoxFit.cover,
                            frameBuilder:
                                (
                                  context,
                                  child,
                                  frame,
                                  wasSynchronouslyLoaded,
                                ) {
                                  if (wasSynchronouslyLoaded || frame != null)
                                    return child;
                                  return Container(
                                    color: _primary.withValues(alpha: .06),
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _primary.withValues(alpha: .65),
                                      ),
                                    ),
                                  );
                                },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: _primary.withValues(alpha: .07),
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: _primary,
                                    size: 30,
                                  ),
                                ),
                          ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: SizedBox(
                    height: 104,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ArtistTextStyles.bodyMedium.copyWith(
                            fontSize: 14,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 7),
                        if ((product['category'] ??
                                product['categoryName'] ??
                                '')
                            .toString()
                            .trim()
                            .isNotEmpty)
                          Text(
                            (product['category'] ?? product['categoryName'])
                                .toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ArtistTextStyles.caption.copyWith(
                              fontSize: 11,
                              color: ArtistColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 7),
                        Text(
                          price == null
                              ? 'Price unavailable'
                              : '₹${price.toString()}',
                          style: ArtistTextStyles.title.copyWith(
                            fontSize: 16,
                            color: _primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Tap to view details',
                          style: ArtistTextStyles.small.copyWith(
                            fontSize: 10,
                            color: ArtistColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove from wishlist',
                  onPressed: _busy || id.isEmpty
                      ? null
                      : () => _remove(product),
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingView() => ListView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
    children: [
      Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: _primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading your saved products…',
              style: ArtistTextStyles.body.copyWith(color: _text),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      for (var i = 0; i < 4; i++)
        Container(
          height: 126,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _primary.withValues(alpha: .10)),
          ),
          child: Row(
            children: [
              Container(
                width: 94,
                height: 104,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 11,
                      width: double.infinity,
                      color: _primary.withValues(alpha: .08),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 9,
                      width: 100,
                      color: _primary.withValues(alpha: .06),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 12,
                      width: 65,
                      color: _primary.withValues(alpha: .08),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 58,
            color: _text.withValues(alpha: .5),
          ),
          const SizedBox(height: 18),
          Text(
            'Could not load wishlist',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.heading.copyWith(
              fontSize: 21,
              color: _text,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _error ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.body.copyWith(
              fontSize: 14,
              height: 1.4,
              color: ArtistColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _load(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Try Again',
                style: ArtistTextStyles.button.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _emptyView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: .09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 44,
              color: _primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Your wishlist is empty',
            style: ArtistTextStyles.heading.copyWith(
              fontSize: 21,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open any product and tap the heart to save it here.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.body.copyWith(
              fontSize: 14,
              height: 1.45,
              color: ArtistColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
