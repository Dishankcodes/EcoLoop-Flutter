import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import 'product_details.dart';

/// Public profile for a regular EcoLoop user who has published listings.
/// Listings and counts are derived from the API; no demo items are displayed.
class SellerProfile extends StatefulWidget {
  const SellerProfile({super.key, required this.seller});

  final Map<String, dynamic> seller;

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _listings = [];

  Map<String, dynamic> _map(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _rows(dynamic v) {
    if (v is List) return v.map(_map).where((e) => e.isNotEmpty).toList();
    final m = _map(v);
    final data = _map(m['data']);
    for (final k in ['products', 'items', 'results']) {
      final x = m[k] ?? data[k];
      if (x is List) return x.map(_map).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }

  String _id(dynamic v) => v == null ? '' : v.toString().trim();

  String _productId(Map<String, dynamic> p) =>
      _id(p['productId'] ?? p['product_id'] ?? p['id']);

  String _sellerId(Map<String, dynamic> p) =>
      _id(p['sellerId'] ?? p['seller_id'] ?? p['userId'] ?? p['ownerId']);

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

  Future<void> _loadListings() async {
    if (mounted) setState(() => _loading = true);
    try {
      final rows = _rows(
        await _api.get(
          '/products',
          query: {'limit': 200, 'status': 'published'},
        ),
      );
      final sellerId = _id(
        widget.seller['userId'] ??
            widget.seller['id'] ??
            widget.seller['sellerId'],
      );
      final filtered = rows.where((p) {
        final status = (p['status'] ?? 'published').toString().toLowerCase();
        final type = (p['sellerType'] ?? p['seller_type'] ?? 'user')
            .toString()
            .toLowerCase();
        final sameId = sellerId.isNotEmpty && _sellerId(p) == sellerId;
        final available =
            num.tryParse(
              (p['availableQuantity'] ?? p['quantity'] ?? 1).toString(),
            ) ??
            1;
        return sameId &&
            type == 'user' &&
            (status.isEmpty || status == 'published' || status == 'active') &&
            available > 0;
      }).toList();
      if (mounted)
        setState(
          () => _listings = filtered
            ..sort(
              (a, b) => _id(b['createdAt']).compareTo(_id(a['createdAt'])),
            ),
        );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  @override
  Widget build(BuildContext context) {
    final name =
        (widget.seller['name'] ??
                widget.seller['sellerName'] ??
                'EcoLoop Member')
            .toString();
    final location =
        (widget.seller['location'] ??
                [widget.seller['city'], widget.seller['state']]
                    .where((v) => v != null && v.toString().trim().isNotEmpty)
                    .join(', '))
            .toString();
    final photo =
        (widget.seller['image'] ?? widget.seller['profilePhoto'] ?? '')
            .toString();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Seller Profile'),
        actions: [
          IconButton(
            onPressed: _loadListings,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadListings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.accent.withOpacity(.35)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.light,
                    backgroundImage: photo.startsWith('http')
                        ? NetworkImage(photo)
                        : null,
                    child: photo.startsWith('http')
                        ? null
                        : const Icon(
                            Icons.person_outline_rounded,
                            size: 38,
                            color: AppColors.primary,
                          ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: AppTextStyles.title.copyWith(fontSize: 21),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    location.isEmpty ? 'EcoLoop community seller' : location,
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _metric('${_listings.length}', 'Published items'),
                      Container(
                        height: 30,
                        width: 1,
                        color: AppColors.accent,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      _metric('User', 'Seller type'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Published listings',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Items currently available from this seller.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _message(
                Icons.cloud_off_outlined,
                'Could not load listings',
                _error!,
                onRetry: _loadListings,
              )
            else if (_listings.isEmpty)
              _message(
                Icons.inventory_2_outlined,
                'No published items',
                'This seller has no currently available listings.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _listings.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 650
                      ? 3
                      : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: .66,
                ),
                itemBuilder: (context, index) {
                  final p = _listings[index];
                  final imgs = _images(p);
                  final product = <String, dynamic>{
                    ...p,
                    'productId': _productId(p),
                    'sellerType': 'user',
                    'sellerName': p['sellerName'] ?? name,
                  };
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetails(product: product),
                      ),
                    ),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: imgs.isEmpty
                                ? Container(
                                    color: AppColors.light,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 34,
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    imgs.first,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppColors.light,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (p['title'] ?? 'Untitled item').toString(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '₹${p['price'] ?? '—'}',
                                  style: AppTextStyles.title.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  (p['condition'] ?? 'Pre-loved').toString(),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String value, String label) => Column(
    children: [
      Text(value, style: AppTextStyles.title.copyWith(fontSize: 17)),
      const SizedBox(height: 3),
      Text(label, style: AppTextStyles.caption),
    ],
  );

  Widget _message(
    IconData icon,
    String title,
    String subtitle, {
    Future<void> Function()? onRetry,
  }) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(icon, size: 34, color: AppColors.primary),
        const SizedBox(height: 10),
        Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
