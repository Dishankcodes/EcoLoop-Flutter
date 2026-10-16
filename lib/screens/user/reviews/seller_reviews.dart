import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'rating_summary.dart';

/// Displays real seller/ReMaker reviews from the EcoLoop Apps Script backend.
///
/// For the Write Review action, pass an eligible delivered orderId. The backend
/// remains responsible for validating review ownership and eligibility.
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
  final EcoLoopApi _api = EcoLoopApi.instance;

  bool _loading = true;
  bool _submitting = false;
  bool _checkingEligibility = true;
  String? _eligibleOrderId;
  String? _error;
  List<Map<String, dynamic>> _reviews = <Map<String, dynamic>>[];
  int _ratingFilter = 0;
  String _sort = 'Newest';

  String get _normalisedSellerType {
    final type = widget.sellerType.trim().toLowerCase();
    if (type == 'seller' || type == 'user') return 'user';
    if (type == 'remaker') return 'remaker';
    return type.isEmpty ? 'artist' : type;
  }

  bool get _isArtist =>
      _normalisedSellerType == 'artist' || _normalisedSellerType == 'remaker';

  bool get _canWriteReview =>
      widget.sellerId.trim().isNotEmpty &&
      (_eligibleOrderId?.trim().isNotEmpty ?? false) &&
      !_checkingEligibility;

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  String _string(dynamic value) => (value ?? '').toString().trim();

  double get _average {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<int>(
      0,
      (sum, review) => sum + _int(review['rating']).clamp(0, 5).toInt(),
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
    _loadEligibility();
  }

  @override
  void didUpdateWidget(covariant SellerReviews oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sellerId != widget.sellerId ||
        oldWidget.sellerType != widget.sellerType) {
      _load();
      _loadEligibility();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final id = int.tryParse(widget.sellerId.trim());
      if (id == null || id <= 0) {
        throw Exception('This seller has no valid profile ID.');
      }

      final path = _isArtist
          ? '/artists/$id/reviews'
          : '/sellers/user/$id/reviews';
      final dynamic response = await _api.get(path);
      final dynamic rows = _extractRows(response);
      final reviews = rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .where(
            (row) =>
                _string(row['status']).isEmpty ||
                _string(row['status']).toLowerCase() == 'active',
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadEligibility() async {
    if (!mounted) return;
    setState(() {
      _checkingEligibility = true;
      _eligibleOrderId = null;
    });

    try {
      final sellerId = int.tryParse(widget.sellerId.trim());
      if (sellerId == null || sellerId <= 0) {
        if (mounted) setState(() => _checkingEligibility = false);
        return;
      }

      String? eligibleOrderId;
      final suppliedOrderId = (widget.orderId ?? '').trim();

      if (!_isArtist) {
        final dynamic response = await _api.get(
          '/sellers/user/$sellerId/review-eligibility',
        );
        if (response is Map && response['eligible'] == true) {
          final value = _string(response['orderId']);
          if (value.isNotEmpty && value != '0') eligibleOrderId = value;
        }
      } else {
        final responses = await Future.wait<dynamic>([
          _api.get('/orders'),
          _api.get('/my/reviews'),
        ]);
        final rows = _extractRows(responses[0]);
        final myReviews = _extractRows(responses[1]);
        final alreadyReviewedArtist = myReviews.whereType<Map>().any((raw) {
          final review = Map<String, dynamic>.from(raw);
          final reviewArtistId = _int(
            review['artistId'] ??
                review['artist_id'] ??
                ((review['sellerType'] ?? review['seller_type'])
                            ?.toString()
                            .toLowerCase() ==
                        'artist'
                    ? review['sellerId'] ?? review['seller_id']
                    : null),
          );
          final type = _string(
            review['reviewType'] ?? review['review_type'],
          ).toLowerCase();
          final active =
              _string(review['status']).isEmpty ||
              _string(review['status']).toLowerCase() == 'active';
          return active &&
              reviewArtistId == sellerId &&
              (type == 'artist' ||
                  type == 'seller' ||
                  review['artistId'] != null ||
                  review['artist_id'] != null);
        });
        final eligibleOrders = alreadyReviewedArtist
            ? <Map<String, dynamic>>[]
            : rows
                  .whereType<Map>()
                  .map((row) {
                    return Map<String, dynamic>.from(row);
                  })
                  .where((order) {
                    final currentSellerId = _int(
                      order['sellerId'] ??
                          order['artistId'] ??
                          order['seller_id'],
                    );
                    final status = _string(
                      order['status'],
                    ).toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
                    final payment = _string(
                      order['paymentStatus'] ??
                          order['payment_status'] ??
                          order['payment'],
                    ).toLowerCase().replaceAll('_', ' ');
                    final paid = const <String>{
                      'paid',
                      'completed',
                      'success',
                      'successful',
                      'captured',
                      'cod paid',
                    }.contains(payment);
                    final type = _string(
                      order['sellerType'] ?? order['seller_type'],
                    ).toLowerCase();
                    final sellerTypeMatches =
                        type.isEmpty || type == 'artist' || type == 'remaker';
                    return currentSellerId == sellerId &&
                        status == 'delivered' &&
                        paid &&
                        sellerTypeMatches;
                  })
                  .toList();

        eligibleOrders.sort((a, b) {
          final dateA =
              DateTime.tryParse(
                _string(a['deliveredAt'] ?? a['updatedAt'] ?? a['createdAt']),
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final dateB =
              DateTime.tryParse(
                _string(b['deliveredAt'] ?? b['updatedAt'] ?? b['createdAt']),
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });

        if (eligibleOrders.isNotEmpty) {
          final order = eligibleOrders.firstWhere(
            (row) =>
                suppliedOrderId.isNotEmpty &&
                _string(row['orderId'] ?? row['id']) == suppliedOrderId,
            orElse: () => eligibleOrders.first,
          );
          final value = _string(order['orderId'] ?? order['id']);
          if (value.isNotEmpty && value != '0') eligibleOrderId = value;
        }
      }

      if (!mounted) return;
      setState(() {
        _eligibleOrderId = eligibleOrderId;
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

  dynamic _extractRows(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      if (response['reviews'] is List) return response['reviews'];
      if (response['items'] is List) return response['items'];
      if (response['results'] is List) return response['results'];
      if (response['data'] is List) return response['data'];
      final data = response['data'];
      if (data is Map) {
        if (data['reviews'] is List) return data['reviews'];
        if (data['items'] is List) return data['items'];
      }
    }
    return <dynamic>[];
  }

  List<Map<String, dynamic>> get _visibleReviews {
    final rows = _reviews
        .where(
          (review) =>
              _ratingFilter == 0 || _int(review['rating']) == _ratingFilter,
        )
        .toList();

    rows.sort((a, b) {
      final ratingA = _int(a['rating']);
      final ratingB = _int(b['rating']);
      final dateA =
          DateTime.tryParse(_string(a['createdAt'] ?? a['created_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB =
          DateTime.tryParse(_string(b['createdAt'] ?? b['created_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      switch (_sort) {
        case 'Highest rated':
          return ratingB.compareTo(ratingA);
        case 'Lowest rated':
          return ratingA.compareTo(ratingB);
        default:
          return dateB.compareTo(dateA);
      }
    });
    return rows;
  }

  Future<void> _openWriteReview() async {
    if (!_canWriteReview || _submitting) return;

    final commentController = TextEditingController();
    var selectedRating = 0;
    var validationMessage = '';

    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Review ${_isArtist ? 'ReMaker' : 'seller'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sellerName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                const Text('Your rating'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      tooltip: '$star star${star == 1 ? '' : 's'}',
                      onPressed: () => setDialogState(() {
                        selectedRating = star;
                        validationMessage = '';
                      }),
                      icon: Icon(
                        star <= selectedRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Your experience',
                    hintText: 'Write at least 5 characters',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  onChanged: (_) {
                    if (validationMessage.isNotEmpty) {
                      setDialogState(() => validationMessage = '');
                    }
                  },
                ),
                if (validationMessage.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    validationMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final comment = commentController.text.trim();
                if (selectedRating < 1) {
                  setDialogState(
                    () => validationMessage = 'Please select a star rating.',
                  );
                  return;
                }
                if (comment.length < 5) {
                  setDialogState(
                    () => validationMessage =
                        'Please write at least 5 characters.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Submit review'),
            ),
          ],
        ),
      ),
    );

    if (submitted != true || !mounted) {
      commentController.dispose();
      return;
    }

    final rating = selectedRating;
    final comment = commentController.text.trim();
    commentController.dispose();

    setState(() => _submitting = true);
    try {
      final sellerId = int.parse(widget.sellerId.trim());
      final orderId = int.tryParse((_eligibleOrderId ?? '').trim());
      if (orderId == null || orderId <= 0) {
        throw Exception(
          'A valid delivered order is required to submit a review.',
        );
      }

      if (_isArtist) {
        await _api.post('/reviews/artist', <String, dynamic>{
          'artistId': sellerId,
          'orderId': orderId,
          'rating': rating,
          'comment': comment,
        });
      } else {
        await _api.post('/reviews/seller', <String, dynamic>{
          'sellerId': sellerId,
          'sellerType': 'user',
          'orderId': orderId,
          'rating': rating,
          'comment': comment,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your review was submitted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleReviews = _visibleReviews;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isArtist ? 'ReMaker Reviews' : 'Seller Reviews'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _buildSellerCard(),
            const SizedBox(height: 16),
            RatingSummary(
              rating: _average,
              totalReviews: _reviews.length,
              ratingCounts: _counts,
            ),
            const SizedBox(height: 14),
            if (_checkingEligibility)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'Checking your eligible orders…',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            if (_canWriteReview)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _openWriteReview,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.rate_review_outlined),
                  label: Text(_submitting ? 'Submitting…' : 'Write a review'),
                ),
              ),
            if (!_checkingEligibility && !_canWriteReview) ...[
              const SizedBox(height: 2),
              const Text(
                'To review this seller, open this page from an eligible delivered order.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _ratingFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Rating',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      isDense: true,
                    ),
                    items: <DropdownMenuItem<int>>[
                      const DropdownMenuItem(
                        value: 0,
                        child: Text('All ratings'),
                      ),
                      for (var star = 5; star >= 1; star--)
                        DropdownMenuItem(
                          value: star,
                          child: Text('$star star${star == 1 ? '' : 's'}'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _ratingFilter = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sort,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      isDense: true,
                    ),
                    items: const <DropdownMenuItem<String>>[
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
                    onChanged: (value) {
                      if (value != null) setState(() => _sort = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _message(_error!, retry: _load)
            else if (visibleReviews.isEmpty)
              _message(
                _ratingFilter == 0
                    ? 'No reviews have been submitted yet.'
                    : 'No reviews match this rating filter.',
              )
            else
              ...visibleReviews.map(_buildReviewCard),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerCard() {
    final image = _string(widget.sellerImage);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.light,
            backgroundImage: image.isEmpty ? null : NetworkImage(image),
            child: image.isEmpty
                ? const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 30,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sellerName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_string(widget.sellerLocation).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _string(widget.sellerLocation),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  '${_reviews.length} ${_reviews.length == 1 ? 'review' : 'reviews'}',
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
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = _int(review['rating']).clamp(0, 5);
    final reviewerName = _string(
      review['reviewerName'] ?? review['userName'] ?? review['name'],
    );
    final comment = _string(review['comment'] ?? review['review']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  reviewerName.isEmpty ? 'EcoLoop user' : reviewerName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '$rating.0',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _formatDate(review['createdAt'] ?? review['created_at']),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(dynamic value) {
    final raw = _string(value);
    if (raw.isEmpty) return 'Date unavailable';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    final local = date.toLocal();
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
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  Widget _message(String text, {Future<void> Function()? retry}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          const Icon(
            Icons.rate_review_outlined,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (retry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: retry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}
