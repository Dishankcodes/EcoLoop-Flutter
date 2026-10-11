import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'product_details.dart';

/// Persisted wishlist backed by GET/POST/DELETE /wishlist.
class Wishlist extends StatefulWidget {
  const Wishlist({super.key});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _rows(dynamic response) {
    if (response is List)
      return response.map(_map).where((e) => e.isNotEmpty).toList();
    final root = _map(response);
    final data = _map(root['data']);
    for (final key in ['items', 'products', 'wishlist', 'results']) {
      final value = root[key] ?? data[key];
      if (value is List)
        return value.map(_map).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  String _id(Map<String, dynamic> p) {
    final nested = _map(p['product']);
    return (p['productId'] ??
            p['product_id'] ??
            p['id'] ??
            nested['productId'] ??
            nested['product_id'] ??
            nested['id'] ??
            '')
        .toString();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final rows = _rows(await _api.get('/wishlist'));
      final cleaned = <Map<String, dynamic>>[];
      for (final row in rows) {
        final nested = _map(row['product']);
        final item = nested.isNotEmpty
            ? <String, dynamic>{...nested}
            : <String, dynamic>{...row};
        final id = _id(row).isNotEmpty ? _id(row) : _id(item);
        if (id.isNotEmpty) item['productId'] = id;
        if (item['title'] != null || item['name'] != null) cleaned.add(item);
      }
      if (mounted)
        setState(() {
          _items = cleaned;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    final id = _id(item);
    if (id.isEmpty) return;
    final previous = List<Map<String, dynamic>>.from(_items);
    setState(() => _items.removeWhere((p) => _id(p) == id));
    try {
      await _api.delete('/wishlist/$id');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
    } catch (e) {
      if (mounted) setState(() => _items = previous);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update wishlist: $e')),
        );
    }
  }

  List<String> _images(Map<String, dynamic> p) {
    final raw = p['imageUrls'] ?? p['images'] ?? p['imageUrl'] ?? p['image'];
    if (raw is List)
      return raw
          .map((e) => e.toString())
          .where((e) => e.startsWith('http'))
          .toList();
    if (raw is String && raw.trim().isNotEmpty) {
      final t = raw.trim();
      if (t.startsWith('[') && t.endsWith(']'))
        return t
            .substring(1, t.length - 1)
            .split(',')
            .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((e) => e.startsWith('http'))
            .toList();
      return t
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.startsWith('http'))
          .toList();
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('My Wishlist'),
      backgroundColor: AppColors.background,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load your wishlist',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: const Text('Try again')),
                ],
              ),
            ),
          )
        : _items.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    size: 54,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Your wishlist is empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap the heart on any marketplace item to save it.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = _items[index];
                final imgs = _images(p);
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: SizedBox(
                      width: 76,
                      height: 76,
                      child: imgs.isEmpty
                          ? const Icon(Icons.image_outlined, size: 34)
                          : Image.network(
                              imgs.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                    title: Text(
                      (p['title'] ?? p['name'] ?? 'Product').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('₹${p['price'] ?? '—'}'),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetails(product: p),
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove from wishlist',
                      onPressed: () => _remove(p),
                      icon: const Icon(Icons.favorite, color: Colors.redAccent),
                    ),
                  ),
                );
              },
            ),
          ),
  );
}
