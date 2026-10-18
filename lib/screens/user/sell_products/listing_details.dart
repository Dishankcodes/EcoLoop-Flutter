import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'edit_listing.dart';

class ListingDetails extends StatefulWidget {
  final Map<String, dynamic> listing;

  const ListingDetails({super.key, required this.listing});

  @override
  State<ListingDetails> createState() => _ListingDetailsState();
}

class _ListingDetailsState extends State<ListingDetails> {
  late Map<String, dynamic> _listing;
  bool _busy = false;

  int get _id =>
      int.tryParse('${_listing['productId'] ?? _listing['id'] ?? ''}') ?? 0;

  String get _status => (_listing['status'] ?? 'published').toString();

  String get _title => (_listing['title'] ?? 'Untitled item').toString();

  String get _condition =>
      (_listing['condition'] ?? '—').toString().replaceAll('_', ' ');

  String get _price => '₹${_listing['price'] ?? 0}';

  String get _description => (_listing['description'] ?? '').toString();

  String get _deliveryLabel {
    final value = (_listing['deliveryMethod'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return value == 'free delivery' ||
            value == 'free' ||
            value == 'free_delivery'
        ? 'Free Delivery (seller pays courier)'
        : 'EcoLoop-Managed Delivery (buyer pays delivery)';
  }

  String get _category =>
      (_listing['categoryName'] ??
              _listing['category'] ??
              'Category #${_listing['categoryId'] ?? '—'}')
          .toString();

  List<dynamic> get _images =>
      _listing['imageUrls'] is List ? _listing['imageUrls'] as List : [];

  @override
  void initState() {
    super.initState();
    _listing = Map<String, dynamic>.from(widget.listing);
  }

  /// Formats timestamps from Google Sheets / Apps Script as Indian local time.
  /// ISO values ending in Z are UTC; timezone-less Apps Script values are IST.
  String _formatDateLabel(dynamic rawValue) {
    final raw = rawValue?.toString().trim() ?? '';
    if (raw.isEmpty || raw == 'null') return '—';

    DateTime parsed;
    try {
      final hasZone = RegExp(
        r'(Z|[+-]\d{2}:?\d{2})$',
        caseSensitive: false,
      ).hasMatch(raw);
      if (hasZone) {
        parsed = DateTime.parse(
          raw,
        ).toUtc().add(const Duration(hours: 5, minutes: 30));
      } else {
        // Apps Script format yyyy-MM-dd HH:mm:ss is already in Asia/Kolkata.
        final normalized = raw.replaceFirst(' ', 'T');
        final localParsed = DateTime.parse(normalized);
        parsed = DateTime.utc(
          localParsed.year,
          localParsed.month,
          localParsed.day,
          localParsed.hour,
          localParsed.minute,
          localParsed.second,
          localParsed.millisecond,
        ).add(const Duration(hours: 5, minutes: 30));
        // Date-only values should not be shifted to the following day.
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
          parsed = DateTime.parse('${raw}T00:00:00');
        }
      }
    } catch (_) {
      return raw;
    }

    final nowUtc = DateTime.now().toUtc();
    final nowIst = nowUtc.add(const Duration(hours: 5, minutes: 30));
    final today = DateTime(nowIst.year, nowIst.month, nowIst.day);
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final time =
        _twoDigits(parsed.hour % 12 == 0 ? 12 : parsed.hour % 12) +
        ':' +
        _twoDigits(parsed.minute) +
        (parsed.hour >= 12 ? ' PM' : ' AM');

    if (date == today) return 'Today, $time';
    if (date == yesterday) return 'Yesterday, $time';
    return '${_twoDigits(parsed.day)} ${_monthName(parsed.month)} ${parsed.year}, $time';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _monthName(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _prettyStatus(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return 'Active';
      case 'draft':
        return 'Draft';
      case 'sold':
        return 'Sold';
      case 'out_of_stock':
        return 'Unavailable';
      case 'archived':
        return 'Archived';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sold':
        return AppColors.success;
      case 'draft':
        return Colors.orange;
      case 'out_of_stock':
      case 'archived':
        return AppColors.textSecondary;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _setStatus(String status) async {
    if (_id <= 0) {
      _message('Invalid product ID.');
      return;
    }
    setState(() => _busy = true);
    try {
      final updated = await EcoLoopApi.instance.post('/products/$_id/status', {
        'status': status,
      });
      if (updated is Map)
        _listing = {..._listing, ...Map<String, dynamic>.from(updated)};
      else
        _listing['status'] = status;
      if (mounted) setState(() {});
      _message('Listing status updated.');
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditListing(listing: _listing)),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final status = _status.toLowerCase();
    final color = _statusColor(status);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Listing Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _edit();
              if (v == 'archive') _setStatus('archived');
              if (v == 'publish') _setStatus('published');
              if (v == 'draft') _setStatus('draft');
              if (v == 'sold') _setStatus('sold');
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit listing')),
              PopupMenuItem(value: 'publish', child: Text('Publish')),
              PopupMenuItem(value: 'draft', child: Text('Save as draft')),
              PopupMenuItem(value: 'sold', child: Text('Mark as sold')),
              PopupMenuItem(value: 'archive', child: Text('Archive')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Container(
            height: 260,
            color: AppColors.light,
            child:
                _images.isNotEmpty &&
                    _images.first.toString().startsWith('http')
                ? Image.network(
                    _images.first.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: AppColors.primary,
                  ),
          ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _prettyStatus(_status),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _price,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(_category, Icons.category_outlined),
                    _chip(_condition, Icons.verified_outlined),
                    _chip(
                      'Qty: ${_listing['availableQuantity'] ?? _listing['quantity'] ?? 0}',
                      Icons.inventory_2_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _section(
            'Description',
            _description.isEmpty ? 'No description provided.' : _description,
          ),
          _section('Delivery option', _deliveryLabel),
          _section(
            'Listing information',
            'Product ID: ${_listing['productId'] ?? '—'}\nCreated: ${_formatDateLabel(_listing['createdAt'])}\nViews: ${_listing['views'] ?? 0}\nSaved: ${_listing['wishlistCount'] ?? 0}\nSales: ${_listing['salesCount'] ?? 0}',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _edit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit listing'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _setStatus(
                            status == 'published'
                                ? 'out_of_stock'
                                : 'published',
                          ),
                    icon: Icon(
                      status == 'published'
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    label: Text(
                      _busy
                          ? 'Saving…'
                          : status == 'published'
                          ? 'Hide listing'
                          : 'Publish',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
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

  Widget _chip(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.light,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _section(String title, String value) => Container(
    margin: const EdgeInsets.only(top: 12),
    color: AppColors.surface,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(height: 1.6, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}
