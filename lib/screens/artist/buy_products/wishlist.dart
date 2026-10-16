import 'package:flutter/material.dart';

import '../../../services/ecoloop_api.dart';
import 'product_details.dart';

/// Account-scoped wishlist for both regular users and artists.
/// Uses the signed-in role's token through EcoLoopApi.
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

  Color get _primary => Theme.of(context).colorScheme.primary;

  Color get _surface => Theme.of(context).colorScheme.surface;

  Color get _background => Theme.of(context).scaffoldBackgroundColor;

  Color get _text => Theme.of(context).colorScheme.onSurface;

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

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.get('/wishlist');
      final rows = _rows(response);
      final cleaned = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final row in rows) {
        final nested = _map(row['product']);
        final item = nested.isNotEmpty
            ? <String, dynamic>{...nested}
            : <String, dynamic>{...row};
        final id = _id(row).isNotEmpty ? _id(row) : _id(item);
        if (id.isEmpty || !seen.add(id)) continue;
        item['productId'] = id;
        if (item['title'] != null || item['name'] != null) cleaned.add(item);
      }
      if (!mounted) return;
      setState(() {
        _items = cleaned;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
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
    try {
      await _api.delete('/wishlist/$id');
      if (mounted) _message('Removed from wishlist');
    } catch (error) {
      if (!mounted) return;
      setState(() => _items = previous);
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
          content: Text(message),
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
        title: const Text(
          'Wishlist',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: _background,
        foregroundColor: _text,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh wishlist',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _primary))
          : _error != null
          ? _errorView()
          : _items.isEmpty
          ? _emptyView()
          : RefreshIndicator(
              color: _primary,
              onRefresh: _load,
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
                      border: Border.all(color: _primary.withOpacity(.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(.09),
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _text,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Products you want to keep for later',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _text.withOpacity(.65),
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
                    decoration: InputDecoration(
                      hintText: 'Search saved products',
                      prefixIcon: const Icon(Icons.search_rounded),
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
                          color: _primary.withOpacity(.12),
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
                          style: TextStyle(color: _text.withOpacity(.65)),
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
              border: Border.all(color: _primary.withOpacity(.13)),
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
                            color: _primary.withOpacity(.07),
                            child: Icon(
                              Icons.image_outlined,
                              color: _primary,
                              size: 32,
                            ),
                          )
                        : Image.network(
                            images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _primary.withOpacity(.07),
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
                          style: TextStyle(
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
                            style: TextStyle(
                              fontSize: 11,
                              color: _text.withOpacity(.6),
                            ),
                          ),
                        const SizedBox(height: 7),
                        Text(
                          price == null
                              ? 'Price unavailable'
                              : '₹${price.toString()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Tap to view details',
                          style: TextStyle(
                            fontSize: 10,
                            color: _text.withOpacity(.55),
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

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 58, color: _text.withOpacity(.5)),
          const SizedBox(height: 18),
          Text(
            'Could not load wishlist',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            _error ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: _text.withOpacity(.65),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
              color: _primary.withOpacity(.09),
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
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open any product and tap the heart to save it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: _text.withOpacity(.65),
            ),
          ),
        ],
      ),
    ),
  );
}
