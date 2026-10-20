import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'rating_summary.dart';
import 'write_review.dart';

/// Displays reviews loaded from the EcoLoop backend for a product.
class ProductReviews extends StatefulWidget {
  final Map<String, dynamic> product;

  /// The delivered order containing this product, when the current user is eligible to review.
  final String? orderId;

  const ProductReviews({super.key, required this.product, this.orderId});

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reviews = <Map<String, dynamic>>[];
  String _filter = 'All';
  String _sort = 'Newest';
  String? _eligibleOrderId;
  String _eligibilityMessage = 'Checking your order…';
  bool _checkingEligibility = true;
  int _loadGeneration = 0;
  int _eligibilityGeneration = 0;

  final EcoLoopApi _api = EcoLoopApi.instance;

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0.0;
  }

  String get _id =>
      (widget.product['productId'] ??
              widget.product['product_id'] ??
              widget.product['id'] ??
              '')
          .toString()
          .trim();

  String get _title {
    final title = (widget.product['title'] ?? widget.product['name'] ?? '')
        .toString()
        .trim();
    return title.isEmpty ? 'Product' : title;
  }

  String get _image {
    final dynamic images =
        widget.product['imageUrls'] ?? widget.product['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first.toString().trim();
      if (first.isNotEmpty) return first;
    }
    return (widget.product['imageUrl'] ?? widget.product['image'] ?? '')
        .toString()
        .trim();
  }

  double get _average {
    if (_reviews.isEmpty) return 0.0;
    final total = _reviews.fold<double>(
      0.0,
      (sum, review) => sum + _double(review['rating']),
    );
    return total / _reviews.length;
  }

  Map<int, int> get _counts => <int, int>{
    for (var star = 1; star <= 5; star++)
      star: _reviews.where((review) => _int(review['rating']) == star).length,
  };

  @override
  void initState() {
    super.initState();
    _load();
    _loadEligibleOrder();
  }

  @override
  void didUpdateWidget(covariant ProductReviews oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product != widget.product ||
        oldWidget.orderId != widget.orderId) {
      _load();
      _loadEligibleOrder();
    }
  }

  Map<String, dynamic>? _extractMap(dynamic response) {
    if (response is Map) {
      final direct = Map<String, dynamic>.from(response);
      if (direct.containsKey('eligible') || direct.containsKey('orderId')) {
        return direct;
      }
      final data = direct['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      final result = direct['result'];
      if (result is Map) return Map<String, dynamic>.from(result);
    }
    return null;
  }

  Future<void> _loadEligibleOrder() async {
    if (!mounted) return;
    final generation = ++_eligibilityGeneration;
    final productId = _id;
    setState(() {
      _checkingEligibility = true;
      _eligibleOrderId = null;
      _eligibilityMessage = 'Checking your order…';
    });

    try {
      if (productId.isEmpty) {
        if (mounted) {
          setState(() {
            _checkingEligibility = false;
            _eligibilityMessage = 'This product has no valid product ID.';
          });
        }
        return;
      }

      // The backend is the source of truth: it checks the signed-in buyer,
      // order status, paid status, product match, and duplicate reviews.
      final dynamic response = await _api.get(
        '/products/$productId/review-eligibility',
      );
      final result = _extractMap(response);
      final eligible =
          result?['eligible'] == true ||
          result?['eligible']?.toString().toLowerCase() == 'true';
      final rawOrderId = result?['orderId'] ?? result?['order_id'];
      final orderId = (rawOrderId ?? '').toString().trim();
      final reason = (result?['reason'] ?? '').toString().trim();

      if (!mounted || generation != _eligibilityGeneration) return;
      setState(() {
        _eligibleOrderId = eligible && orderId.isNotEmpty ? orderId : null;
        _checkingEligibility = false;
        _eligibilityMessage = eligible && orderId.isNotEmpty
            ? 'Verified purchase: you can review this product.'
            : reason.isNotEmpty
            ? reason
            : 'A confirmed or delivered order with paid payment is required, and each product can be reviewed only once.';
      });
    } catch (error) {
      if (!mounted || generation != _eligibilityGeneration) return;
      setState(() {
        _eligibleOrderId = null;
        _checkingEligibility = false;
        _eligibilityMessage =
            'Could not verify review eligibility. Please refresh and try again.';
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait<void>([_load(), _loadEligibleOrder()]);
  }

  Future<void> _load() async {
    if (!mounted) return;
    final generation = ++_loadGeneration;
    final productId = _id;
    final hasContent = _reviews.isNotEmpty;
    setState(() {
      _loading = !hasContent;
      _error = null;
    });

    try {
      if (productId.isEmpty) {
        throw Exception('This product has no valid product ID.');
      }

      final dynamic response = await _api.get('/products/$productId/reviews');
      dynamic rows;

      if (response is List) {
        rows = response;
      } else if (response is Map) {
        final data = response['data'];
        if (response['reviews'] is List) {
          rows = response['reviews'];
        } else if (data is List) {
          rows = data;
        } else if (data is Map && data['reviews'] is List) {
          rows = data['reviews'];
        } else if (response['items'] is List) {
          rows = response['items'];
        } else if (response['results'] is List) {
          rows = response['results'];
        }
      }

      final parsedReviews = rows is List
          ? rows
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _reviews = parsedReviews;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visibleReviews {
    var rows = List<Map<String, dynamic>>.from(_reviews);

    if (_filter == 'With Photos') {
      rows = rows.where((review) {
        final photos = review['photos'] ?? review['images'];
        return photos is List && photos.isNotEmpty;
      }).toList();
    } else if (_filter != 'All') {
      final star = int.tryParse(_filter.split(' ').first) ?? 0;
      rows = rows.where((review) => _int(review['rating']) == star).toList();
    }

    rows.sort((a, b) {
      if (_sort == 'Highest Rating') {
        return _int(b['rating']).compareTo(_int(a['rating']));
      }
      if (_sort == 'Lowest Rating') {
        return _int(a['rating']).compareTo(_int(b['rating']));
      }

      final dateA =
          DateTime.tryParse(
            (a['createdAt'] ?? a['created_at'] ?? '').toString(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB =
          DateTime.tryParse(
            (b['createdAt'] ?? b['created_at'] ?? '').toString(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Product Reviews'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _productCard(),
            const SizedBox(height: 14),
            RatingSummary(
              rating: _average,
              totalReviews: _reviews.length,
              ratingCounts: _counts,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _checkingEligibility || _eligibleOrderId == null
                    ? null
                    : _openWriteReview,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Write a review'),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _eligibilityMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  <String>[
                    'All',
                    '5 Star',
                    '4 Star',
                    '3 Star',
                    '2 Star',
                    '1 Star',
                    'With Photos',
                  ].map((filter) {
                    return ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (selected) {
                        if (selected) setState(() => _filter = filter);
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _sort,
              decoration: const InputDecoration(
                labelText: 'Sort reviews',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Newest', child: Text('Newest')),
                DropdownMenuItem(
                  value: 'Highest Rating',
                  child: Text('Highest Rating'),
                ),
                DropdownMenuItem(
                  value: 'Lowest Rating',
                  child: Text('Lowest Rating'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _sort = value);
              },
            ),
            const SizedBox(height: 12),
            if (_loading && _reviews.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _message(_error!, action: _load)
            else if (_visibleReviews.isEmpty)
              _message('No reviews have been submitted for this product yet.')
            else
              ..._visibleReviews.map(_reviewCard),
          ],
        ),
      ),
    );
  }

  Future<void> _openWriteReview() async {
    final orderId = _eligibleOrderId;
    if (_checkingEligibility || orderId == null || orderId.trim().isEmpty) {
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => WriteReview(product: widget.product, orderId: orderId),
      ),
    );

    if (result == true && mounted) {
      await _refreshAll();
    }
  }

  Widget _productCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 68,
              height: 68,
              child: _image.isEmpty
                  ? const ColoredBox(
                      color: AppColors.light,
                      child: Icon(Icons.image_outlined),
                    )
                  : Image.network(
                      _image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                            color: AppColors.light,
                            child: Icon(Icons.image_not_supported_outlined),
                          ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final rating = _int(review['rating']).clamp(0, 5);
    final reviewerName =
        (review['reviewerName'] ??
                review['userName'] ??
                review['name'] ??
                'EcoLoop user')
            .toString();
    final date = (review['createdAt'] ?? review['created_at'] ?? '').toString();
    final comment = (review['comment'] ?? review['review'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reviewerName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '$rating ★',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            date,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(comment),
          ],
        ],
      ),
    );
  }

  Widget _message(String message, {Future<void> Function()? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const Icon(
            Icons.rate_review_outlined,
            size: 34,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Try again')),
        ],
      ),
    );
  }
}
