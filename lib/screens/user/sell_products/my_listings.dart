import 'package:flutter/material.dart';

import '../../../services/ecoloop_api.dart';
import '../../../app_theme/user/app_colors.dart';
import 'edit_listing.dart';
import 'listing_details.dart';

class MyListings extends StatefulWidget {
  const MyListings({super.key});

  @override
  State<MyListings> createState() => _MyListingsState();
}

class _MyListingsState extends State<MyListings>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _listings = [];
  Map<String, String> _categoryNames = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this)
      ..addListener(() {
        if (mounted && !_tabs.indexIsChanging) setState(() {});
      });
    _loadListings();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        EcoLoopApi.instance.get('/my/products'),
        EcoLoopApi.instance.get('/categories'),
      ]);
      final productResponse = responses[0];
      final categoryResponse = responses[1];
      final productRows = productResponse is List
          ? productResponse
          : (productResponse is Map
                ? (productResponse['data'] ?? productResponse['products'] ?? [])
                : []);
      final categoryRows = categoryResponse is List
          ? categoryResponse
          : (categoryResponse is Map
                ? (categoryResponse['data'] ??
                      categoryResponse['categories'] ??
                      [])
                : []);
      final listings = <Map<String, dynamic>>[];
      for (final row in productRows) {
        if (row is Map) listings.add(Map<String, dynamic>.from(row));
      }
      final categories = <String, String>{};
      for (final row in categoryRows) {
        if (row is Map)
          categories['${row['categoryId']}'] = '${row['name'] ?? 'Category'}';
      }
      if (!mounted) return;
      setState(() {
        _listings = listings
            .where(
              (item) =>
                  (item['status'] ?? '').toString().toLowerCase() != 'archived',
            )
            .toList();
        _categoryNames = categories;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _status(Map<String, dynamic> item) {
    switch ((item['status'] ?? '').toString().toLowerCase()) {
      case 'published':
        return 'Active';
      case 'sold':
        return 'Sold';
      case 'draft':
        return 'Draft';
      case 'out_of_stock':
        return 'Unavailable';
      case 'archived':
        return 'Archived';
      default:
        return (item['status'] ?? 'Unknown').toString();
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final all = _listings;
    switch (_tabs.index) {
      case 1:
        return all.where((e) => _status(e) == 'Active').toList();
      case 2:
        return all.where((e) => _status(e) == 'Sold').toList();
      case 3:
        return all.where((e) => _status(e) == 'Draft').toList();
      case 4:
        return all.where((e) => _status(e) == 'Unavailable').toList();
      default:
        return all;
    }
  }

  Future<void> _openDetails(Map<String, dynamic> listing) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ListingDetails(listing: _withCategory(listing)),
      ),
    );
    if (changed == true) _loadListings();
  }

  Future<void> _edit(Map<String, dynamic> listing) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditListing(listing: _withCategory(listing)),
      ),
    );
    if (changed == true) _loadListings();
  }

  Map<String, dynamic> _withCategory(Map<String, dynamic> item) => {
    ...item,
    'categoryName':
        _categoryNames['${item['categoryId']}'] ??
        item['categoryName'] ??
        'Category #${item['categoryId'] ?? '—'}',
  };

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _setStatus(Map<String, dynamic> item, String status) async {
    final id = int.tryParse('${item['productId'] ?? item['id'] ?? ''}') ?? 0;
    if (id <= 0) {
      _message('Invalid product ID.');
      return;
    }
    try {
      await EcoLoopApi.instance.post('/products/$id/status', {
        'status': status,
      });
      await _loadListings();
      if (mounted) _message('Listing status updated.');
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'My Listings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadListings,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Sold'),
            Tab(text: 'Drafts'),
            Tab(text: 'Unavailable'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadListings,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 100),
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _loadListings,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ),
                ],
              )
            : filtered.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 110),
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Text(
                      _listings.isEmpty
                          ? 'You have no listings yet'
                          : 'No ${_tabs.index == 1
                                ? 'active'
                                : _tabs.index == 2
                                ? 'sold'
                                : _tabs.index == 3
                                ? 'draft'
                                : 'unavailable'} listings',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Center(
                    child: Text(
                      'Items you list for sale will appear here.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 13),
                itemBuilder: (_, i) => _card(filtered[i]),
              ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> raw) {
    final item = _withCategory(raw);
    final status = _status(item);
    final id = item['productId'] ?? item['id'] ?? '—';
    final images = item['imageUrls'] is List
        ? item['imageUrls'] as List
        : <dynamic>[];
    final image = images.isNotEmpty ? images.first.toString() : '';
    final color = status == 'Sold'
        ? AppColors.success
        : status == 'Draft'
        ? Colors.orange
        : AppColors.primary;
    return InkWell(
      onTap: () => _openDetails(item),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.accent.withOpacity(.4)),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    height: 96,
                    width: 96,
                    color: AppColors.light,
                    child: image.startsWith('http')
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.inventory_2_outlined,
                              size: 36,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            size: 36,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['title'] ?? 'Untitled item'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${item['price'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${item['condition'] ?? '—'} • ${item['categoryName']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _edit(item);
                    if (v == 'publish') _setStatus(item, 'published');
                    if (v == 'draft') _setStatus(item, 'draft');
                    if (v == 'sold') _setStatus(item, 'sold');
                    if (v == 'hide') _setStatus(item, 'out_of_stock');
                    if (v == 'archive') _setStatus(item, 'archived');
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit listing')),
                    PopupMenuItem(value: 'publish', child: Text('Publish')),
                    PopupMenuItem(value: 'draft', child: Text('Save as draft')),
                    PopupMenuItem(value: 'sold', child: Text('Mark as sold')),
                    PopupMenuItem(value: 'hide', child: Text('Hide listing')),
                    PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive listing'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 22),
            Row(
              children: [
                const Icon(
                  Icons.tag_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  'ID: $id',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${item['views'] ?? 0} views',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _edit(item),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
