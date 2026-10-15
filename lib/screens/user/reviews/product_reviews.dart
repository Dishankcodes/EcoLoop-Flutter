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
  bool _checkingEligibility = true;

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

  List<Map<String, dynamic>> _extractRows(dynamic response) {
    dynamic rows;
    if (response is List) {
      rows = response;
    } else if (response is Map) {
      final data = response['data'];
      if (response['orders'] is List) {
        rows = response['orders'];
      } else if (data is List) {
        rows = data;
      } else if (data is Map && data['orders'] is List) {
        rows = data['orders'];
      } else if (response['items'] is List) {
        rows = response['items'];
      } else if (response['results'] is List) {
        rows = response['results'];
      }
    }
    if (rows is! List) return <Map<String, dynamic>>[];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  String _normaliseId(dynamic value) => (value ?? '').toString().trim();

  Future<void> _loadEligibleOrder() async {
    if (!mounted) return;
    setState(() {
      _checkingEligibility = true;
      _eligibleOrderId = null;
    });

    try {
      if (_id.isEmpty) {
        if (mounted) setState(() => _checkingEligibility = false);
        return;
      }

      // Eligibility is derived from the signed-in user's actual orders.
      // The backend still performs the authoritative check on submission.
      final dynamic response = await _api.get('/orders');
      final orders = _extractRows(response);
      final productId = _normaliseId(int.tryParse(_id) ?? _id);

      final eligible = orders.where((order) {
        final orderedProductId = _normaliseId(
          order['productId'] ?? order['product_id'] ?? order['productID'],
        );
        final status = (order['status'] ?? '')
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll('-', '_')
            .replaceAll(' ', '_');
        return orderedProductId == productId && status == 'delivered';
      }).toList();

      eligible.sort((a, b) {
        final aDate =
            DateTime.tryParse(
              (a['deliveredAt'] ?? a['updatedAt'] ?? a['createdAt'] ?? '')
                  .toString(),
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            DateTime.tryParse(
              (b['deliveredAt'] ?? b['updatedAt'] ?? b['createdAt'] ?? '')
                  .toString(),
            ) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      String? chosenOrderId;
      final suppliedOrderId = (widget.orderId ?? '').trim();
      if (suppliedOrderId.isNotEmpty) {
        for (final order in eligible) {
          final currentId = _normaliseId(order['orderId'] ?? order['id']);
          if (currentId == suppliedOrderId) {
            chosenOrderId = currentId;
            break;
          }
        }
      }
      chosenOrderId ??= eligible.isNotEmpty
          ? _normaliseId(eligible.first['orderId'] ?? eligible.first['id'])
          : null;

      if (!mounted) return;
      setState(() {
        _eligibleOrderId = chosenOrderId == null || chosenOrderId.isEmpty
            ? null
            : chosenOrderId;
        _checkingEligibility = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _eligibleOrderId = null;
        _checkingEligibility = false;
      });
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_id.isEmpty) {
        throw Exception('This product has no valid product ID.');
      }

      final dynamic response = await _api.get('/products/$_id/reviews');
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

      if (!mounted) return;
      setState(() {
        _reviews = parsedReviews;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
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
        onRefresh: _load,
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
              _checkingEligibility
                  ? 'Checking your delivered orders…'
                  : _eligibleOrderId == null
                  ? 'You can review this product after your order is delivered.'
                  : 'Verified purchase: you can review this product.',
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
            if (_loading)
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
      await Future.wait<void>([_load(), _loadEligibleOrder()]);
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
