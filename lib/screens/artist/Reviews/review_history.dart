import 'package:flutter/material.dart';
import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import 'write_review.dart';

class ReviewHistory extends StatefulWidget {
  const ReviewHistory({super.key});
  @override
  State<ReviewHistory> createState() => _ReviewHistoryState();
}

class _ReviewHistoryState extends State<ReviewHistory> {
  final _api = EcoLoopApi.instance;
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true, _refreshing = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      if (refresh)
        _refreshing = true;
      else
        _loading = true;
      _error = null;
    });
    try {
      final raw = await _api.get('/my/reviews');
      final rows = _list(raw)
          .where(
            (r) =>
                _text(r['reviewType']).toLowerCase() == 'product' &&
                _int(r['productId']) > 0,
          )
          .toList();
      if (mounted) setState(() => _reviews = rows);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
          _refreshing = false;
        });
    }
  }

  Future<void> _edit(Map<String, dynamic> r) async {
    final product = <String, dynamic>{
      'productId': r['productId'],
      'title': r['productTitle'],
      'image': r['productImage'],
    };
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReview(
          product: product,
          existingReviewId: _int(r['reviewId']),
          initialRating: _int(r['rating']),
          initialComment: _text(r['comment']),
        ),
      ),
    );
    if (result != null && mounted) _load(refresh: true);
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text(
          'This review will be removed from your review history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _api.delete('/reviews/${_int(r['reviewId'])}');
      if (mounted) {
        setState(
          () => _reviews.removeWhere(
            (x) => _int(x['reviewId']) == _int(r['reviewId']),
          ),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review deleted.')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ArtistColors.background,
    appBar: AppBar(
      backgroundColor: ArtistColors.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: ArtistColors.textPrimary,
      title: Text('My Reviews', style: ArtistTextStyles.title),
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: ArtistColors.primary),
          )
        : RefreshIndicator(
            color: ArtistColors.primary,
            onRefresh: () => _load(refresh: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _decoration(),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 30,
                        color: ArtistColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Product Reviews',
                              style: ArtistTextStyles.title.copyWith(
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              '${_reviews.length} reviews written',
                              style: ArtistTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      if (_refreshing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ArtistColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_error != null)
                  _status(
                    'Could not load review history',
                    _error!,
                    () => _load(refresh: true),
                  )
                else if (_reviews.isEmpty)
                  _status(
                    'No product reviews yet',
                    'Reviews you write for products you purchased will appear here.',
                    () => _load(refresh: true),
                  )
                else
                  ..._reviews.map(_card),
              ],
            ),
          ),
  );
  Widget _card(Map<String, dynamic> r) => Container(
    margin: const EdgeInsets.only(top: 11),
    padding: const EdgeInsets.all(13),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 62,
                height: 62,
                child: _text(r['productImage']).isEmpty
                    ? const Icon(
                        Icons.image_outlined,
                        color: ArtistColors.primary,
                      )
                    : Image.network(
                        _text(r['productImage']),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_outlined,
                          color: ArtistColors.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text(r['productTitle'], fallback: 'Product'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_int(r['rating'])} ★',
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      color: ArtistColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _dateLabel(r['createdAt']),
                    style: ArtistTextStyles.small,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit')
                  _edit(r);
                else
                  _delete(r);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit review')),
                PopupMenuItem(value: 'delete', child: Text('Delete review')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _text(r['comment']),
          style: ArtistTextStyles.body.copyWith(height: 1.4),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _edit(r),
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Edit'),
            ),
            TextButton.icon(
              onPressed: () => _delete(r),
              icon: const Icon(Icons.delete_outline, size: 17),
              label: const Text('Delete'),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _status(String title, String message, VoidCallback retry) => Container(
    margin: const EdgeInsets.only(top: 20),
    padding: const EdgeInsets.all(20),
    decoration: _decoration(),
    child: Column(
      children: [
        const Icon(
          Icons.rate_review_outlined,
          size: 36,
          color: ArtistColors.primary,
        ),
        const SizedBox(height: 10),
        Text(title, style: ArtistTextStyles.title),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: ArtistTextStyles.caption,
        ),
        TextButton(onPressed: retry, child: const Text('Try again')),
      ],
    ),
  );
  BoxDecoration _decoration() => BoxDecoration(
    color: ArtistColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: ArtistColors.border),
  );
}

Map<String, dynamic> _map(dynamic v) => v is Map<String, dynamic>
    ? v
    : v is Map
    ? v.map((k, val) => MapEntry(k.toString(), val))
    : <String, dynamic>{};
List<Map<String, dynamic>> _list(dynamic v) {
  if (v is List) return v.whereType<Map>().map(_map).toList();
  final m = _map(v);
  final rows = m['reviews'] ?? m['data'] ?? m['items'];
  return rows is List
      ? rows.whereType<Map>().map(_map).toList()
      : <Map<String, dynamic>>[];
}

int _int(dynamic v) =>
    v is num ? v.toInt() : int.tryParse((v ?? '').toString()) ?? 0;
String _text(dynamic v, {String fallback = ''}) {
  final s = (v ?? '').toString().trim();
  return s.isEmpty ? fallback : s;
}

DateTime _date(dynamic v) =>
    DateTime.tryParse((v ?? '').toString()) ??
    DateTime.fromMillisecondsSinceEpoch(0);
String _dateLabel(dynamic v) {
  final d = _date(v);
  return d.millisecondsSinceEpoch == 0
      ? 'Date unavailable'
      : '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
}

const _months = [
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
