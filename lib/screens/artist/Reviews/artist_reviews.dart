import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';

class ArtistReviews extends StatefulWidget {
  const ArtistReviews({super.key});

  @override
  State<ArtistReviews> createState() => _ArtistReviewsState();
}

class _ArtistReviewsState extends State<ArtistReviews> {
  final _api = EcoLoopApi.instance;
  static List<Map<String, dynamic>>? _cachedReviews;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 2);
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true, _refreshing = false;
  bool _requestInFlight = false;
  String? _error;
  String _filter = 'All', _sort = 'Newest';

  double get _rating => _reviews.isEmpty
      ? 0
      : _reviews.fold<double>(0, (sum, r) => sum + _num(r['rating'])) /
            _reviews.length;

  List<Map<String, dynamic>> get _visible {
    var rows = _reviews
        .where(
          (r) =>
              _filter == 'All' || (_num(r['rating']) == int.tryParse(_filter)),
        )
        .toList();
    if (_sort == 'Highest Rating')
      rows.sort((a, b) => _num(b['rating']).compareTo(_num(a['rating'])));
    else if (_sort == 'Lowest Rating')
      rows.sort((a, b) => _num(a['rating']).compareTo(_num(b['rating'])));
    else
      rows.sort(
        (a, b) => _date(b['createdAt']).compareTo(_date(a['createdAt'])),
      );
    return rows;
  }

  @override
  void initState() {
    super.initState();
    final cached = _cachedReviews;
    if (cached != null) {
      _reviews = List<Map<String, dynamic>>.from(cached);
      _loading = false;
    }
    _load(silent: cached != null);
  }

  Future<void> _load({bool refresh = false, bool silent = false}) async {
    if (!mounted || _requestInFlight) return;
    final cached = _cachedReviews;
    final fresh =
        cached != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration;
    if (!refresh && fresh) {
      if (_reviews.isEmpty && mounted)
        setState(() {
          _reviews = List<Map<String, dynamic>>.from(cached);
          _loading = false;
        });
      return;
    }
    _requestInFlight = true;
    if (!silent && mounted)
      setState(() {
        if (refresh || _reviews.isNotEmpty)
          _refreshing = true;
        else
          _loading = true;
        _error = null;
      });
    try {
      final response = await _api.get('/artist/product-reviews');
      final all = _list(response);
      all.sort(
        (a, b) => _date(b['createdAt']).compareTo(_date(a['createdAt'])),
      );
      _cachedReviews = List<Map<String, dynamic>>.from(all);
      _cacheTime = DateTime.now();
      if (mounted)
        setState(() {
          _reviews = all;
          _error = null;
        });
    } catch (e) {
      if (mounted && (_reviews.isEmpty || !silent))
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _requestInFlight = false;
      if (mounted)
        setState(() {
          _loading = false;
          _refreshing = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ArtistColors.background,
    appBar: AppBar(
      backgroundColor: ArtistColors.surface,
      elevation: 0,
      foregroundColor: ArtistColors.textPrimary,
      title: Text(
        'Customer Reviews',
        style: ArtistTextStyles.heading.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    body: RefreshIndicator(
      color: ArtistColors.primary,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _decoration(),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ArtistColors.light,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.rate_review_outlined,
                    color: ArtistColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Product Feedback',
                        style: ArtistTextStyles.heading.copyWith(fontSize: 16),
                      ),
                      Text(
                        'Reviews customers have left on your listings.',
                        style: ArtistTextStyles.body.copyWith(
                          color: ArtistColors.textMuted,
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
          _summary(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reviews (${_reviews.length})',
                  style: ArtistTextStyles.heading.copyWith(fontSize: 18),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'Newest', child: Text('Newest')),
                  PopupMenuItem(
                    value: 'Highest Rating',
                    child: Text('Highest rating'),
                  ),
                  PopupMenuItem(
                    value: 'Lowest Rating',
                    child: Text('Lowest rating'),
                  ),
                ],
                child: Row(
                  children: [
                    Text(_sort, style: ArtistTextStyles.small),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 5,
            children: ['All', '5', '4', '3', '2', '1']
                .map(
                  (f) => ChoiceChip(
                    label: Text(f == 'All' ? f : '$f ★'),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: ArtistColors.light,
                  ),
                )
                .toList(),
          ),
          if (_error != null)
            _status(
              'Could not load reviews',
              _error!,
              () => _load(refresh: true),
            )
          else if (_visible.isEmpty && !_loading)
            _status(
              'No customer reviews yet',
              'When customers review your products, they will appear here.',
              () => _load(refresh: true),
            )
          else
            ..._visible.map(_reviewCard),
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: CircularProgressIndicator(color: ArtistColors.primary),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _summary() {
    final counts = {
      for (var s = 1; s <= 5; s++)
        s: _reviews.where((r) => _num(r['rating']) == s).length,
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoration(),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Column(
              children: [
                Text(
                  _rating.toStringAsFixed(1),
                  style: ArtistTextStyles.heading.copyWith(fontSize: 31),
                ),
                const Icon(
                  Icons.star_rounded,
                  color: ArtistColors.warning,
                  size: 22,
                ),
                Text(
                  '${_reviews.length} reviews',
                  style: ArtistTextStyles.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = counts[star] ?? 0;
                final pct = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('$star ★', style: ArtistTextStyles.small),
                      const SizedBox(width: 7),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: ArtistColors.surfaceSoft,
                            valueColor: const AlwaysStoppedAnimation(
                              ArtistColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      SizedBox(
                        width: 22,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: ArtistTextStyles.small,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(14),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: ArtistColors.light,
              child: const Icon(
                Icons.person_outline,
                color: ArtistColors.primary,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text(r['reviewerName'], fallback: 'EcoLoop buyer'),
                    style: ArtistTextStyles.bodyMedium.copyWith(
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
            Text(
              '${_num(r['rating']).toStringAsFixed(0)} ★',
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: ArtistColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          _text(r['productTitle'], fallback: 'Product'),
          style: ArtistTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: ArtistColors.primary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _text(r['comment'], fallback: 'No written comment.'),
          style: ArtistTextStyles.body.copyWith(height: 1.4),
        ),
      ],
    ),
  );

  Widget _status(String title, String message, VoidCallback retry) => Container(
    margin: const EdgeInsets.only(top: 20),
    padding: const EdgeInsets.all(18),
    decoration: _decoration(),
    child: Column(
      children: [
        const Icon(
          Icons.rate_review_outlined,
          size: 34,
          color: ArtistColors.primary,
        ),
        const SizedBox(height: 8),
        Text(title, style: ArtistTextStyles.title),
        const SizedBox(height: 5),
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
    borderRadius: BorderRadius.circular(17),
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
  final rows = m['products'] ?? m['reviews'] ?? m['data'] ?? m['items'];
  return rows is List
      ? rows.whereType<Map>().map(_map).toList()
      : <Map<String, dynamic>>[];
}

int _int(dynamic v) =>
    v is num ? v.toInt() : int.tryParse((v ?? '').toString()) ?? 0;

double _num(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse((v ?? '').toString()) ?? 0;

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
