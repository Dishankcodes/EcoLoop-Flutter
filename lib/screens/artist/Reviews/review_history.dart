import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import 'write_review.dart';
import 'write_seller_review.dart';

class ReviewHistory extends StatefulWidget {
  const ReviewHistory({super.key});

  @override
  State<ReviewHistory> createState() => _ReviewHistoryState();
}

class _ReviewHistoryState extends State<ReviewHistory> {
  final EcoLoopApi _api = EcoLoopApi.instance;

  // Reuse the last successful response when this screen is reopened.
  static List<Map<String, dynamic>>? _cachedReviews;
  static List<Map<String, dynamic>>? _cachedOrders;
  static DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(seconds: 90);

  int _tab = 0;
  bool _loading = true;
  bool _reviewsLoaded = false;
  bool _ordersLoaded = false;
  String? _error;
  List<Map<String, dynamic>> _reviews = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _orders = <Map<String, dynamic>>[];
  final Set<String> _deletingIds = <String>{};

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  String _string(dynamic value) => (value ?? '').toString().trim();

  String _first(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = _string(row[key]);
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return fallback;
  }

  String _imageValue(dynamic value) {
    if (value == null) return '';
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final key in const [
        'url',
        'imageUrl',
        'image_url',
        'image',
        'src',
        'downloadUrl',
        'thumbnailUrl',
        'thumbnail',
      ]) {
        final candidate = _imageValue(map[key]);
        if (candidate.isNotEmpty) return candidate;
      }
      return '';
    }
    if (value is List) {
      for (final item in value) {
        final candidate = _imageValue(item);
        if (candidate.isNotEmpty) return candidate;
      }
      return '';
    }
    final raw = _string(value);
    if (raw.isEmpty || raw.toLowerCase() == 'null') return '';
    if (raw.startsWith('[') || raw.startsWith('{')) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return _imageValue(decoded);
        if (decoded is Map) {
          return _first(Map<String, dynamic>.from(decoded), [
            'url',
            'imageUrl',
            'image',
            'src',
            'downloadUrl',
            'thumbnailUrl',
            'thumbnail',
          ]);
        }
      } catch (_) {
        // Treat it as a normal URL below if it is not valid JSON.
      }
    }
    if (!(raw.startsWith('http://') || raw.startsWith('https://'))) return '';
    // Normalize common Google Drive share URLs for Image.network.
    final driveFile = RegExp(
      r'drive\.google\.com/file/d/([^/?#]+)',
    ).firstMatch(raw);
    if (driveFile != null)
      return 'https://drive.google.com/uc?export=view&id=${driveFile.group(1)}';
    final driveId = RegExp(r'[?&]id=([^&#]+)').firstMatch(raw);
    if (raw.contains('drive.google.com') && driveId != null) {
      return 'https://drive.google.com/uc?export=view&id=${driveId.group(1)}';
    }
    return raw;
  }

  String _rowImage(Map<String, dynamic> row, {required bool seller}) {
    final keys = seller
        ? [
            'sellerImage',
            'sellerProfileImage',
            'sellerProfilePhotoUrl',
            'artistImage',
            'artistProfileImage',
            'artistPhotoUrl',
            'profilePhotoUrl',
            'profileImage',
            'profilePicture',
            'avatar',
            'photoUrl',
            'imageUrl',
          ]
        : [
            'productImage',
            'productImageUrl',
            'productImageURL',
            'imageUrls',
            'productImageUrls',
            'images',
            'productImages',
            'imageUrl',
            'image',
            'thumbnail',
          ];
    for (final key in keys) {
      final image = _imageValue(row[key]);
      if (image.isNotEmpty) return image;
    }
    return '';
  }

  String _reviewImage(Map<String, dynamic> review, {required bool seller}) {
    final direct = _rowImage(review, seller: seller);
    if (direct.isNotEmpty) return direct;

    // Review endpoints may return only IDs; enrich from the already-loaded orders.
    final productId = _productId(review);
    final sellerId = _sellerId(review);
    for (final order in _orders) {
      if (seller) {
        if (sellerId.isNotEmpty && _sellerId(order) == sellerId) {
          final image = _rowImage(order, seller: true);
          if (image.isNotEmpty) return image;
        }
      } else if (productId.isNotEmpty && _productId(order) == productId) {
        final image = _rowImage(order, seller: false);
        if (image.isNotEmpty) return image;
      }
    }
    return '';
  }

  Widget _thumbnail(String url, {required bool seller, double size = 48}) {
    final fallback = Container(
      color: ArtistColors.surfaceSoft,
      alignment: Alignment.center,
      child: Icon(
        seller ? Icons.person_outline_rounded : Icons.image_outlined,
        color: ArtistColors.primary,
        size: size * 0.48,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: (size * 2).round(),
                cacheHeight: (size * 2).round(),
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                    wasSynchronouslyLoaded || frame != null ? child : fallback,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }

  String _reviewId(Map<String, dynamic> review) =>
      _first(review, ['reviewId', 'review_id', 'id']);

  String _productId(Map<String, dynamic> row) =>
      _first(row, ['productId', 'product_id']);

  String _sellerId(Map<String, dynamic> row) =>
      _first(row, ['sellerId', 'seller_id', 'artistId', 'artist_id']);

  String _sellerType(Map<String, dynamic> row) {
    final type = _first(
      row,
      ['sellerType', 'seller_type', 'targetType', 'target_type'],
      fallback: 'user',
    ).toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    return const {'artist', 'remaker', 're_maker'}.contains(type)
        ? 'artist'
        : 'user';
  }

  bool _isSellerReview(Map<String, dynamic> review) {
    final type = _first(review, ['reviewType', 'review_type']).toLowerCase();
    if (type == 'seller' || type == 'artist') return true;
    final sellerId = _first(review, ['sellerId', 'seller_id']);
    final artistId = _first(review, ['artistId', 'artist_id']);
    final productId = _first(review, ['productId', 'product_id']);
    return (sellerId.isNotEmpty || artistId.isNotEmpty) && productId.isEmpty;
  }

  bool _isArtistReview(Map<String, dynamic> review) {
    final type = _first(review, [
      'reviewType',
      'review_type',
      'sellerType',
      'seller_type',
      'targetType',
      'target_type',
    ]).toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    return const {'artist', 'remaker', 're_maker'}.contains(type) ||
        _first(review, ['artistId', 'artist_id']).isNotEmpty;
  }

  bool _isEligibleOrder(Map<String, dynamic> order) {
    final status = _first(order, [
      'status',
      'orderStatus',
      'order_status',
    ]).toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
    final payment = _first(order, [
      'paymentStatus',
      'payment_status',
      'payment',
    ]).toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ').trim();
    const allowedStatuses = {'delivered'};
    const paidStatuses = {
      'paid',
      'completed',
      'success',
      'successful',
      'captured',
      'cod paid',
    };
    return allowedStatuses.contains(status) && paidStatuses.contains(payment);
  }

  bool _hasProductReview(Map<String, dynamic> order) {
    final productId = _productId(order);
    if (productId.isEmpty) return true;
    return _reviews.any(
      (review) =>
          !_isSellerReview(review) &&
          _first(review, ['productId', 'product_id']) == productId,
    );
  }

  // A seller/artist can be reviewed only once by this account, regardless
  // of how many qualifying orders the buyer has with them.
  bool _hasSellerReview(Map<String, dynamic> order) {
    final sellerId = _sellerId(order);
    if (sellerId.isEmpty) return true;
    final targetType = _sellerType(order);
    return _reviews.any((review) {
      if (!_isSellerReview(review)) return false;
      final reviewedId = _first(review, [
        'sellerId',
        'seller_id',
        'artistId',
        'artist_id',
      ]);
      if (reviewedId != sellerId) return false;
      return targetType == 'artist'
          ? _isArtistReview(review)
          : !_isArtistReview(review) && _sellerType(review) == 'user';
    });
  }

  List<Map<String, dynamic>> get _pendingOrders {
    final eligible = _orders.where(_isEligibleOrder).toList();
    final filtered = eligible
        .where(
          (order) =>
              _tab == 0 ? !_hasProductReview(order) : !_hasSellerReview(order),
        )
        .toList();
    filtered.sort((a, b) {
      final da = DateTime.tryParse(_first(a, ['createdAt', 'created_at']));
      final db = DateTime.tryParse(_first(b, ['createdAt', 'created_at']));
      return (db ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        da ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
    // Avoid repeating the same product/seller card when there are multiple qualifying orders.
    final seen = <String>{};
    return filtered.where((order) {
      final key = _tab == 0
          ? 'p:${_productId(order)}'
          : 's:${_sellerType(order)}:${_sellerId(order)}';
      return key != 'p:' &&
          key != 's:user:' &&
          key != 's:artist:' &&
          seen.add(key);
    }).toList();
  }

  List<Map<String, dynamic>> get _visibleReviews {
    final result = _reviews
        .where(
          (review) =>
              _tab == 0 ? !_isSellerReview(review) : _isSellerReview(review),
        )
        .toList();
    result.sort((a, b) {
      final dateA = DateTime.tryParse(_first(a, ['createdAt', 'created_at']));
      final dateB = DateTime.tryParse(_first(b, ['createdAt', 'created_at']));
      return (dateB ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        dateA ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
    return result;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<List<Map<String, dynamic>>> _getRows(String path) async {
    final dynamic response = await _api.get(path);
    dynamic rows = response;
    for (var depth = 0; depth < 4; depth++) {
      if (rows is String) {
        try {
          rows = jsonDecode(rows);
        } catch (_) {
          break;
        }
      }
      if (rows is List) break;
      if (rows is Map) {
        final map = Map<String, dynamic>.from(rows);
        dynamic next;
        for (final key in const [
          'reviews',
          'orders',
          'items',
          'results',
          'data',
          'rows',
          'records',
          'list',
        ]) {
          if (map.containsKey(key) && map[key] != null) {
            next = map[key];
            break;
          }
        }
        if (next == null || identical(next, rows)) break;
        rows = next;
        continue;
      }
      break;
    }
    if (rows is! List) return <Map<String, dynamic>>[];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  Future<void> _load({bool force = false}) async {
    final cacheIsFresh =
        _cachedReviews != null &&
        _cachedOrders != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration;

    if (!force && cacheIsFresh) {
      if (!mounted) return;
      setState(() {
        _reviews = List<Map<String, dynamic>>.from(_cachedReviews!);
        _orders = List<Map<String, dynamic>>.from(_cachedOrders!);
        _reviewsLoaded = true;
        _ordersLoaded = true;
        _loading = false;
        _error = null;
      });
      return;
    }

    // Paint the page shell immediately. Fetch reviews and orders concurrently,
    // then render each section as soon as its own request finishes.
    final hasCachedContent =
        _reviewsLoaded ||
        _ordersLoaded ||
        _reviews.isNotEmpty ||
        _orders.isNotEmpty ||
        _cachedReviews != null ||
        _cachedOrders != null;
    if (!mounted) return;
    setState(() {
      if (_cachedReviews != null) {
        _reviews = List<Map<String, dynamic>>.from(_cachedReviews!);
        _reviewsLoaded = true;
      } else if (_reviews.isEmpty) {
        _reviewsLoaded = false;
      }
      if (_cachedOrders != null) {
        _orders = List<Map<String, dynamic>>.from(_cachedOrders!);
        _ordersLoaded = true;
      } else if (_orders.isEmpty) {
        _ordersLoaded = false;
      }
      _loading = !hasCachedContent;
      _error = null;
    });

    var succeeded = 0;
    Object? firstError;
    final reviewsFuture = _getRows('/my/reviews')
        .then((rows) {
          if (!mounted) return;
          _cachedReviews = List<Map<String, dynamic>>.from(rows);
          if (_cachedOrders != null) _cacheTime = DateTime.now();
          setState(() {
            _reviews = rows;
            _reviewsLoaded = true;
            _loading = false;
            _error = null;
          });
          succeeded++;
        })
        .catchError((Object error) {
          firstError ??= error;
        });

    final ordersFuture = _getRows('/orders')
        .then((rows) {
          if (!mounted) return;
          _cachedOrders = List<Map<String, dynamic>>.from(rows);
          if (_cachedReviews != null) _cacheTime = DateTime.now();
          setState(() {
            _orders = rows;
            _ordersLoaded = true;
            _loading = false;
            _error = null;
          });
          succeeded++;
        })
        .catchError((Object error) {
          firstError ??= error;
        });

    await Future.wait<void>([reviewsFuture, ordersFuture]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (succeeded == 0) {
        _error = (firstError ?? 'Unable to load review history.')
            .toString()
            .replaceFirst('Exception: ', '');
      } else {
        _error = null;
        if (_cachedReviews != null && _cachedOrders != null) {
          _cacheTime = DateTime.now();
        }
      }
    });
  }

  Future<void> _writeProductReview(Map<String, dynamic> order) async {
    final productId = _productId(order);
    final orderId = _first(order, ['orderId', 'order_id', 'id']);
    if (productId.isEmpty || orderId.isEmpty) {
      _message('Product or order information is missing.');
      return;
    }
    final product = <String, dynamic>{
      'productId': _int(productId),
      'title': _first(order, [
        'productName',
        'productTitle',
        'title',
      ], fallback: 'Product'),
      'name': _first(order, [
        'productName',
        'productTitle',
        'title',
      ], fallback: 'Product'),
      'imageUrl': _first(order, ['productImage', 'imageUrl', 'image']),
      'imageUrls': <String>[
        _first(order, ['productImage', 'imageUrl', 'image']),
      ],
    };
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => WriteReview(product: product, orderId: _int(orderId)),
      ),
    );
    if (result == true && mounted) {
      _message('Product review submitted successfully.');
      await _load(force: true);
    }
  }

  Future<void> _writeSellerReview(Map<String, dynamic> order) async {
    final sellerId = _sellerId(order);
    final orderId = _first(order, ['orderId', 'order_id', 'id']);
    if (sellerId.isEmpty || orderId.isEmpty) {
      _message('Seller or order information is missing.');
      return;
    }
    final type = _sellerType(order);
    final name = _first(order, [
      'sellerName',
      'artistName',
      'remakerName',
    ], fallback: type == 'artist' ? 'ReMaker' : 'Seller');
    final image = _first(order, [
      'sellerImage',
      'artistImage',
      'profileImage',
      'avatar',
    ]);
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (_) => WriteSellerReview(
          sellerName: name,
          sellerImage: image.isEmpty ? null : image,
          sellerId: sellerId,
          sellerType: type,
          orderId: orderId,
        ),
      ),
    );
    if (result == true && mounted) {
      // Refresh immediately so the pending card disappears and the submitted
      // review appears in history without waiting for the cache to expire.
      _cachedReviews = null;
      _cachedOrders = null;
      _cacheTime = null;
      _reviewsLoaded = false;
      _ordersLoaded = false;
      _message('Seller review submitted successfully.');
      await _load(force: true);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _confirmDelete(Map<String, dynamic> review) async {
    final id = _reviewId(review);
    if (id.isEmpty || _deletingIds.contains(id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArtistColors.surface,
        title: const Text('Delete review?'),
        content: const Text(
          'This review will be removed from your review history and no longer appear publicly. This action cannot be undone from the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ArtistColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete review'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingIds.add(id));
    try {
      await _api.delete('/reviews/$id');
      if (!mounted) return;
      setState(() {
        _reviews.removeWhere((item) => _reviewId(item) == id);
        _cachedReviews = List<Map<String, dynamic>>.from(_reviews);
        _cacheTime = DateTime.now();
        _deletingIds.remove(id);
      });
      _message('Review deleted successfully.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(id));
      _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _dateLabel(dynamic value) {
    final parsed = DateTime.tryParse(_string(value));
    if (parsed == null) return 'Date unavailable';
    final local = parsed.toLocal();
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

  @override
  Widget build(BuildContext context) {
    final reviews = _visibleReviews;
    final pending = _pendingOrders;
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        title: Text('My Reviews', style: ArtistTextStyles.title),
        centerTitle: true,
        backgroundColor: ArtistColors.surface,
        foregroundColor: ArtistColors.primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                border: Border.all(color: ArtistColors.primary, width: 1.2),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  _tabButton(label: 'Products', index: 0),
                  _tabButton(label: 'Sellers & Artists', index: 1),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(force: true),
              color: ArtistColors.primary,
              child: _loading && !_reviewsLoaded && !_ordersLoaded
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 140),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                      children: [
                        const Icon(
                          Icons.rate_review_outlined,
                          size: 42,
                          color: ArtistColors.textSecondary,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: ArtistTextStyles.body.copyWith(
                            color: ArtistColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _load,
                            child: const Text('Try again'),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      children: [
                        _sectionHeader(
                          title: 'Waiting for your review',
                          subtitle: _tab == 0
                              ? 'Share feedback about products from eligible orders.'
                              : 'Review the seller or ReMaker behind your purchase.',
                          count: pending.length,
                        ),
                        if (!_ordersLoaded)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ArtistColors.primary,
                                ),
                              ),
                            ),
                          )
                        else if (pending.isEmpty)
                          _emptyPanel(
                            icon: Icons.task_alt_rounded,
                            title: _tab == 0
                                ? 'No product reviews pending'
                                : 'No seller reviews pending',
                            message:
                                'Eligible paid orders that have not been reviewed will appear here.',
                          )
                        else
                          ...pending.map(_pendingCard),
                        const SizedBox(height: 22),
                        _sectionHeader(
                          title: _tab == 0
                              ? 'Your product reviews'
                              : 'Your seller & artist reviews',
                          subtitle: 'Reviews you have already submitted.',
                          count: reviews.length,
                        ),
                        if (!_reviewsLoaded)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ArtistColors.primary,
                                ),
                              ),
                            ),
                          )
                        else if (reviews.isEmpty)
                          _emptyPanel(
                            icon: Icons.rate_review_outlined,
                            title: _tab == 0
                                ? 'No product reviews yet'
                                : 'No seller reviews yet',
                            message: 'Reviews you submit will appear here.',
                          )
                        else
                          ...reviews.map(_reviewCard),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArtistTextStyles.title.copyWith(
                    color: ArtistColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: ArtistTextStyles.caption.copyWith(
                    color: ArtistColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: ArtistColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({required String label, required int index}) {
    final selected = _tab == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
          decoration: BoxDecoration(
            color: selected ? ArtistColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 17, color: Colors.white),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    color: selected ? Colors.white : ArtistColors.textPrimary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyPanel({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: ArtistColors.primary),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: ArtistTextStyles.bodyMedium.copyWith(
              color: ArtistColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption.copyWith(
              color: ArtistColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingCard(Map<String, dynamic> order) {
    final artist = _sellerType(order) == 'artist';
    final productName = _first(order, [
      'productName',
      'productTitle',
      'title',
    ], fallback: 'Product');
    final sellerName = _first(order, [
      'sellerName',
      'artistName',
      'remakerName',
    ], fallback: artist ? 'ReMaker' : 'Seller');
    final image = _rowImage(order, seller: !(_tab == 0));
    final orderId = _first(order, ['orderId', 'order_id', 'id']);
    final isProductTab = _tab == 0;
    final title = isProductTab ? productName : sellerName;
    final subtitle = isProductTab
        ? 'Order #$orderId • Product review'
        : 'Order #$orderId • ${artist ? 'ReMaker / artist' : 'Seller'} review';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _thumbnail(image, seller: !isProductTab, size: 62),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: ArtistColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: ArtistTextStyles.caption.copyWith(
                        color: ArtistColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: ArtistColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Eligible order',
                          style: ArtistTextStyles.caption.copyWith(
                            color: ArtistColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => isProductTab
                  ? _writeProductReview(order)
                  : _writeSellerReview(order),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: Text(
                isProductTab
                    ? 'Write Product Review'
                    : artist
                    ? 'Review ReMaker / Artist'
                    : 'Write Seller Review',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final sellerReview = _isSellerReview(review);
    final title = sellerReview
        ? _first(review, [
            'sellerName',
            'artistName',
            'remakerName',
          ], fallback: 'Seller / ReMaker')
        : _first(review, [
            'productTitle',
            'productName',
            'title',
          ], fallback: 'Product');
    final comment = _string(review['comment']);
    final image = _reviewImage(review, seller: sellerReview);
    final id = _reviewId(review);
    final deleting = _deletingIds.contains(id);
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumbnail(image, seller: sellerReview, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: ArtistColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${sellerReview ? (_isArtistReview(review) ? 'Artist review' : 'Seller review') : 'Product review'} • ${_dateLabel(review['createdAt'] ?? review['created_at'])}',
                      style: ArtistTextStyles.caption.copyWith(
                        color: ArtistColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D8),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _int(review['rating']).toString(),
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: const Color(0xFF855B00),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF4B400),
                      size: 17,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 13),
            Text(
              comment,
              style: ArtistTextStyles.body.copyWith(
                color: ArtistColors.textPrimary,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE7EAE5)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: deleting ? null : () => _confirmDelete(review),
              icon: deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(deleting ? 'Deleting…' : 'Delete review'),
              style: TextButton.styleFrom(
                foregroundColor: ArtistColors.error,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
