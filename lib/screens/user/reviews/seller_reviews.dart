import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'rating_summary.dart';
import 'write_seller_review.dart';

class SellerReviews extends StatefulWidget {
  final String sellerId;
  final String sellerType;
  final String sellerName;
  final String? sellerImage;
  final String? sellerLocation;
  final String? orderId;

  const SellerReviews({
    super.key,
    this.sellerId = '',
    this.sellerType = 'artist',
    required this.sellerName,
    this.sellerImage,
    this.sellerLocation,
    this.orderId,
  });

  @override
  State<SellerReviews> createState() => _SellerReviewsState();
}

class _SellerReviewsState extends State<SellerReviews> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reviews = [];
  int _ratingFilter = 0;
  String _sort = 'Newest';

  int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

  double get _average => _reviews.isEmpty
      ? 0
      : _reviews.fold<double>(0, (sum, r) => sum + _int(r['rating'])) /
            _reviews.length;

  Map<int, int> get _counts => {
    for (var n = 1; n <= 5; n++)
      n: _reviews.where((r) => _int(r['rating']) == n).length,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = int.tryParse(widget.sellerId);
      if (id == null) throw Exception('Invalid seller ID.');
      final path =
          widget.sellerType.toLowerCase() == 'artist' ||
              widget.sellerType.toLowerCase() == 'remaker'
          ? '/artists/$id/reviews'
          : '/sellers/${widget.sellerType.toLowerCase()}/$id/reviews';
      final data = await EcoLoopApi.instance.get(path);
      final rows = data is List
          ? data
          : (data is Map && data['reviews'] is List
                ? data['reviews'] as List
                : <dynamic>[]);
      if (!mounted) return;
      setState(() {
        _reviews = rows
            .whereType<Map>()
            .map((r) => Map<String, dynamic>.from(r))
            .toList();
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

  List<Map<String, dynamic>> get _visible {
    var rows = _reviews
        .where((r) => _ratingFilter == 0 || _int(r['rating']) == _ratingFilter)
        .toList();
    rows.sort((a, b) {
      final ar = _int(a['rating']), br = _int(b['rating']);
      final ad =
          DateTime.tryParse('${a['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bd =
          DateTime.tryParse('${b['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      if (_sort == 'Highest rated') return br.compareTo(ar);
      if (_sort == 'Lowest rated') return ar.compareTo(br);
      return bd.compareTo(ad);
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Seller Reviews'),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.light,
                  backgroundImage:
                      (widget.sellerImage?.trim().isNotEmpty ?? false)
                      ? NetworkImage(widget.sellerImage!)
                      : null,
                  child: (widget.sellerImage?.trim().isNotEmpty ?? false)
                      ? null
                      : const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sellerName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((widget.sellerLocation ?? '').isNotEmpty)
                        Text(
                          widget.sellerLocation!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        '${_reviews.length} reviews',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          RatingSummary(
            rating: _average,
            totalReviews: _reviews.length,
            ratingCounts: _counts,
          ),
          const SizedBox(height: 12),
          if (widget.orderId != null &&
              widget.orderId!.isNotEmpty &&
              widget.sellerId.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WriteSellerReview(
                      sellerName: widget.sellerName,
                      sellerImage: widget.sellerImage,
                      sellerId: widget.sellerId,
                      sellerType: widget.sellerType,
                      orderId: widget.orderId!,
                    ),
                  ),
                );
                if (result == true) _load();
              },
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Write a seller review'),
            ),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _ratingFilter,
                  decoration: const InputDecoration(
                    labelText: 'Rating',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('All ratings'),
                    ),
                    for (var i = 5; i >= 1; i--)
                      DropdownMenuItem(value: i, child: Text('$i stars')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _ratingFilter = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sort,
                  decoration: const InputDecoration(
                    labelText: 'Sort',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                    DropdownMenuItem(
                      value: 'Highest rated',
                      child: Text('Highest rated'),
                    ),
                    DropdownMenuItem(
                      value: 'Lowest rated',
                      child: Text('Lowest rated'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _sort = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _empty(_error!, retry: _load)
          else if (_visible.isEmpty)
            _empty('No seller reviews have been submitted yet.')
          else
            ..._visible.map(
              (r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${r['reviewerName'] ?? 'EcoLoop user'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${_int(r['rating'])} ★',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${r['createdAt'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${r['comment'] ?? ''}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _empty(String text, {Future<void> Function()? retry}) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const Icon(
          Icons.rate_review_outlined,
          size: 34,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center),
        if (retry != null)
          TextButton(onPressed: retry, child: const Text('Try again')),
      ],
    ),
  );
}
