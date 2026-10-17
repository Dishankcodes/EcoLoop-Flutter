import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import 'write_review.dart';

class ProductReviews extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductReviews({super.key, required this.product});

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  final EcoLoopApi _api = EcoLoopApi.instance;

  List<Map<String, dynamic>> _reviews = [];

  bool _loading = true;
  bool _eligible = false;
  bool _refreshing = false;

  int? _orderId;
  String? _error;

  String _filter = 'All';
  String _sort = 'Newest';

  int get _productId {
    return _toInt(widget.product['productId'] ?? widget.product['id']);
  }

  String get _title {
    return _text(
      widget.product['title'] ?? widget.product['name'],
      fallback: 'Product',
    );
  }

  double get _rating {
    if (_reviews.isEmpty) return 0;

    final total = _reviews.fold<double>(
      0,
      (sum, review) => sum + _toInt(review['rating']),
    );

    return total / _reviews.length;
  }

  List<Map<String, dynamic>> get _visible {
    final list = _reviews.where((review) {
      return _filter == 'All' ||
          _toInt(review['rating']) == int.tryParse(_filter);
    }).toList();

    if (_sort == 'Highest Rating') {
      list.sort((a, b) => _toInt(b['rating']).compareTo(_toInt(a['rating'])));
    } else if (_sort == 'Lowest Rating') {
      list.sort((a, b) => _toInt(a['rating']).compareTo(_toInt(b['rating'])));
    } else {
      list.sort(
        (a, b) => _date(b['createdAt']).compareTo(_date(a['createdAt'])),
      );
    }

    return list;
  }

  @override
  void initState() {
    super.initState();
    _load();
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
      if (_productId <= 0) {
        throw Exception('Product ID is missing.');
      }

      final results = await Future.wait<dynamic>([
        _api.get('/products/$_productId/reviews'),
        _api.get('/products/$_productId/review-eligibility'),
      ]);

      final rawReviews = _list(results[0]);
      final eligibility = _map(results[1]);

      if (!mounted) return;

      setState(() {
        _reviews = rawReviews;
        _eligible = _bool(eligibility['eligible']);

        final eligibleOrderId = _toInt(eligibility['orderId']);
        _orderId = eligibleOrderId > 0 ? eligibleOrderId : null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _write() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            WriteReview(product: widget.product, orderId: _orderId),
      ),
    );

    if (result != null && mounted) {
      await _load(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ArtistColors.textPrimary,
        title: Text('Product Reviews', style: ArtistTextStyles.title),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: ArtistColors.primary),
            )
          : RefreshIndicator(
              color: ArtistColors.primary,
              onRefresh: () => _load(refresh: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _productHeader(),
                  const SizedBox(height: 12),
                  _summary(),

                  if (_eligible) ...[const SizedBox(height: 12), _writeCard()],

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Customer reviews',
                          style: ArtistTextStyles.title.copyWith(fontSize: 18),
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          setState(() {
                            _sort = value;
                          });
                        },
                        itemBuilder: (context) => const [
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
                            Text(_sort, style: ArtistTextStyles.caption),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: ['All', '5', '4', '3', '2', '1']
                        .map(
                          (value) => ChoiceChip(
                            label: Text(value == 'All' ? 'All' : '$value ★'),
                            selected: _filter == value,
                            onSelected: (selected) {
                              if (!selected) return;

                              setState(() {
                                _filter = value;
                              });
                            },
                            selectedColor: ArtistColors.light,
                          ),
                        )
                        .toList(),
                  ),

                  if (_error != null) ...[
                    _status(
                      Icons.cloud_off_outlined,
                      'Could not load reviews',
                      _error!,
                      () => _load(refresh: true),
                    ),
                  ] else if (_visible.isEmpty) ...[
                    _status(
                      Icons.rate_review_outlined,
                      'No reviews yet',
                      'Reviews submitted by verified purchasers will appear here.',
                      () => _load(refresh: true),
                    ),
                  ] else ...[
                    ..._visible.map(_reviewCard),
                  ],

                  if (_refreshing)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: ArtistColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _productHeader() {
    final imageUrl = _image(widget.product);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _decoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 68,
              height: 68,
              child: imageUrl.isEmpty
                  ? const Icon(
                      Icons.image_outlined,
                      color: ArtistColors.primary,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_outlined,
                          color: ArtistColors.primary,
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ArtistTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    final counts = <int, int>{
      for (var star = 1; star <= 5; star++)
        star: _reviews
            .where((review) => _toInt(review['rating']) == star)
            .length,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoration(),
      child: Row(
        children: [
          SizedBox(
            width: 88,
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
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = counts[star] ?? 0;

                final ratio = _reviews.isEmpty ? 0.0 : count / _reviews.length;

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
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: ArtistColors.surfaceSoft,
                            valueColor: const AlwaysStoppedAnimation<Color>(
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

  Widget _writeCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _decoration(),
      child: Row(
        children: [
          const Icon(
            Icons.rate_review_outlined,
            color: ArtistColors.primary,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bought this product?',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Your order is eligible for a review.',
                  style: ArtistTextStyles.caption,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _write,
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtistColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Write review'),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    return Container(
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
                      _text(review['reviewerName'], fallback: 'EcoLoop buyer'),
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _dateLabel(review['createdAt']),
                      style: ArtistTextStyles.small,
                    ),
                  ],
                ),
              ),
              Text(
                '${_toInt(review['rating'])} ★',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _text(review['comment'], fallback: 'No comment provided.'),
            style: ArtistTextStyles.body.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _status(
    IconData icon,
    String title,
    String message,
    VoidCallback retry,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: _decoration(),
      child: Column(
        children: [
          Icon(icon, size: 34, color: ArtistColors.primary),
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
  }

  BoxDecoration _decoration() {
    return BoxDecoration(
      color: ArtistColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ArtistColors.border),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  return <String, dynamic>{};
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is List) {
    return value.whereType<Map>().map(_map).toList();
  }

  final map = _map(value);
  final rows = map['reviews'] ?? map['data'] ?? map['items'];

  if (rows is List) {
    return rows.whereType<Map>().map(_map).toList();
  }

  return <Map<String, dynamic>>[];
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse((value ?? '').toString()) ?? 0;
}

bool _bool(dynamic value) {
  return value == true ||
      value.toString().toLowerCase() == 'true' ||
      value.toString() == '1';
}

String _text(dynamic value, {String fallback = ''}) {
  final result = (value ?? '').toString().trim();
  return result.isEmpty ? fallback : result;
}

String _image(Map<String, dynamic> product) {
  final images = product['images'] ?? product['imageUrls'];

  if (images is List && images.isNotEmpty) {
    return images.first.toString();
  }

  return _text(product['image'] ?? product['imageUrl']);
}

DateTime _date(dynamic value) {
  return DateTime.tryParse((value ?? '').toString()) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

String _dateLabel(dynamic value) {
  final date = _date(value);

  if (date.millisecondsSinceEpoch == 0) {
    return 'Date unavailable';
  }

  return '${date.day.toString().padLeft(2, '0')} '
      '${_months[date.month - 1]} ${date.year}';
}

const List<String> _months = [
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
