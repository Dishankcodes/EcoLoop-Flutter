import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../buy_products/product_details.dart';

/// Public profile shown when a user opens an artist/ReMaker from a listing.
/// Profile details are taken from the selected backend artist record; portfolio,
/// products, reviews, follow state and review eligibility are loaded from API.
class ArtistProfile extends StatefulWidget {
  const ArtistProfile({super.key, required this.artist});

  final Map<String, dynamic> artist;

  @override
  State<ArtistProfile> createState() => _ArtistProfileState();
}

class _ArtistProfileState extends State<ArtistProfile> {
  final EcoLoopApi _api = EcoLoopApi.instance;

  late Map<String, dynamic> _artist;
  List<Map<String, dynamic>> _portfolio = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _reviews = [];

  bool _loading = true;
  bool _following = false;
  bool _followBusy = false;
  bool _reviewEligibilityChecked = false;
  bool _canReview = false;
  bool _alreadyReviewed = false;
  String? _eligibleOrderId;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _artist = Map<String, dynamic>.from(widget.artist);
    _loadProfileData();
  }

  String _firstValue(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = _artist[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  String get _artistId =>
      _firstValue(['artistId', 'artist_id', 'id', 'userId', 'user_id']);

  String get _name => _firstValue([
    'name',
    'artistName',
    'artist_name',
    'userName',
    'username',
    'fullName',
  ], fallback: 'ReMaker');

  String get _bio => _firstValue(['bio', 'about', 'description']);

  String get _location {
    final direct = _firstValue(['location', 'address']);
    if (direct.isNotEmpty) return direct;
    final city = _firstValue(['city']);
    final state = _firstValue(['state', 'stateName']);
    if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
    return city.isNotEmpty ? city : state;
  }

  String get _avatar => _firstValue([
    'profileImage',
    'profile_image',
    'profileImageUrl',
    'profile_image_url',
    'image',
    'avatarUrl',
    'avatar_url',
  ]);

  String get _email => _firstValue(['email']);

  String get _phone => _firstValue(['phone', 'mobile', 'phoneNumber']);

  bool get _verified {
    final value =
        _artist['verified'] ?? _artist['isVerified'] ?? _artist['is_verified'];
    return value == true || value?.toString().toLowerCase() == 'true';
  }

  Future<void> _loadProfileData({bool refresh = false}) async {
    if (_artistId.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError =
          'Artist ID is missing. Open this page using the artist record returned by the backend.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        if (!refresh && _portfolio.isEmpty && _products.isEmpty && _reviews.isEmpty) {
          _loading = true;
        }
        _loadError = null;
      });
    }

    final results = await Future.wait<dynamic>([
      _safeGet('/artists/$_artistId/portfolio', fallback: <dynamic>[]),
      _safeGet('/products', fallback: <dynamic>[]),
      _safeGet('/artists/$_artistId/reviews', fallback: <dynamic>[]),
      _safeGet('/my/following', fallback: <dynamic>[]),
      _safeGet('/orders', fallback: <dynamic>[]),
      _safeGet('/my/reviews', fallback: <dynamic>[]),
    ]);

    if (!mounted) return;

    final portfolio = _asList(results[0]);
    final allProducts = _asList(results[1]);
    final reviews = _asList(results[2]);
    final following = _asList(results[3]);
    final orders = _asList(results[4]);
    final myReviews = _asList(results[5]);

    final artistProducts = allProducts.where((product) {
      final owner = _value(product, [
        'artistId',
        'artist_id',
        'sellerId',
        'seller_id',
        'ownerId',
        'owner_id',
      ]);
      return owner.isNotEmpty && owner == _artistId && !_isUnavailable(product);
    }).toList();

    final followsArtist = following.any((item) {
      final id = _value(item, [
        'artistId',
        'artist_id',
        'id',
        'userId',
        'user_id',
      ]);
      return id == _artistId;
    });

    final alreadyReviewed = myReviews.any((item) {
      final id = _value(item, [
        'artistId',
        'artist_id',
        'sellerId',
        'seller_id',
      ]);
      final type = _value(item, [
        'reviewType',
        'sellerType',
        'type',
      ]).toLowerCase();
      return id == _artistId &&
          (type.isEmpty || type.contains('artist') || type.contains('remaker'));
    });

    final eligibleOrder = _findEligibleOrder(orders, artistProducts);
    if (!mounted) return;
    setState(() {
      _portfolio = portfolio.where((item) => !_isUnavailable(item)).toList();
      _products = artistProducts;
      _reviews = reviews;
      _following = followsArtist;
      _alreadyReviewed = alreadyReviewed;
      _eligibleOrderId = eligibleOrder;
      _canReview = eligibleOrder != null && !alreadyReviewed;
      _reviewEligibilityChecked = true;
      _loading = false;
    });
  }

  Future<dynamic> _safeGet(String path, {required dynamic fallback}) async {
    try {
      return await _api.get(path);
    } catch (_) {
      return fallback;
    }
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    dynamic current = value;
    if (current is Map) {
      current =
          current['items'] ??
              current['results'] ??
              current['data'] ??
              current['portfolio'] ??
              current['products'] ??
              current['reviews'] ??
              current['orders'] ??
              current['following'];
      if (current is Map) {
        current = current['items'] ?? current['results'] ?? current['data'];
      }
    }
    if (current is! List) return <Map<String, dynamic>>[];
    return current
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _value(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  bool _isUnavailable(Map<String, dynamic> item) {
    final status = _value(item, [
      'status',
      'productStatus',
      'product_status',
    ]).toLowerCase();
    return status == 'deleted' ||
        status == 'inactive' ||
        status == 'draft' ||
        status == 'rejected' ||
        status == 'hidden';
  }

  String? _findEligibleOrder(
      List<Map<String, dynamic>> orders,
      List<Map<String, dynamic>> artistProducts,
      ) {
    final productIds = artistProducts
        .map((p) => _value(p, ['productId', 'product_id', 'id']))
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final order in orders) {
      final status = _value(order, [
        'status',
        'orderStatus',
        'order_status',
      ]).toLowerCase();
      final payment = _value(order, [
        'paymentStatus',
        'payment_status',
        'paymentState',
      ]).toLowerCase();
      if (!(status == 'confirmed' ||
          status == 'delivered' ||
          status == 'completed'))
        continue;
      if (!(payment == 'paid' ||
          payment == 'success' ||
          payment == 'successful'))
        continue;

      final orderId = _value(order, ['orderId', 'order_id', 'id']);
      final items = _asList(
        order['items'] ??
            order['orderItems'] ??
            order['order_items'] ??
            order['products'],
      );
      final directArtist = _value(order, [
        'artistId',
        'artist_id',
        'sellerId',
        'seller_id',
      ]);
      final hasArtist =
          directArtist == _artistId ||
              items.any((item) {
                final artistId = _value(item, [
                  'artistId',
                  'artist_id',
                  'sellerId',
                  'seller_id',
                ]);
                final productId = _value(item, ['productId', 'product_id', 'id']);
                return artistId == _artistId || productIds.contains(productId);
              });
      if (hasArtist && orderId.isNotEmpty) return orderId;
    }
    return null;
  }

  Future<void> _toggleFollow() async {
    if (_artistId.isEmpty || _followBusy) return;
    setState(() => _followBusy = true);
    try {
      if (_following) {
        await _api.delete('/artists/$_artistId/follow');
      } else {
        await _api.post('/artists/$_artistId/follow', <String, dynamic>{});
      }
      if (mounted) setState(() => _following = !_following);
    } catch (e) {
      _message('Could not update follow status: $e');
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _openWriteReview() async {
    if (!_canReview || _eligibleOrderId == null) return;
    final rating = ValueNotifier<int>(5);
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: ArtistColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review $_name',
                    style: ArtistTextStyles.title.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share feedback about your purchase from this ReMaker.',
                    style: ArtistTextStyles.caption,
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<int>(
                    valueListenable: rating,
                    builder: (context, value, child) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                            (index) => IconButton(
                          onPressed: () => rating.value = index + 1,
                          icon: Icon(
                            index < value
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: ArtistColors.primary,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: commentController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      labelText: 'Your review',
                      hintText:
                      'Tell others about the product and your experience...',
                      filled: true,
                      fillColor: ArtistColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) =>
                    (value == null || value.trim().length < 5)
                        ? 'Please write at least 5 characters.'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!(formKey.currentState?.validate() ?? false)) {
                          return;
                        }
                        Navigator.pop(sheetContext, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArtistColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Submit Review'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (submitted == true) {
      try {
        await _api.post('/reviews/artist', <String, dynamic>{
          'artistId': _artistId,
          'orderId': _eligibleOrderId,
          'rating': rating.value,
          'comment': commentController.text.trim(),
          'review': commentController.text.trim(),
        });
        if (mounted) {
          _message('Review submitted.');
          await _loadProfileData(refresh: true);
        }
      } catch (e) {
        _message('Could not submit review: $e');
      }
    }
    rating.dispose();
    commentController.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Artist Profile',
          style: ArtistTextStyles.title.copyWith(fontSize: 19),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: () => _loadProfileData(refresh: true),
            icon: const Icon(
              Icons.refresh_rounded,
              color: ArtistColors.textPrimary,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        color: ArtistColors.primary,
        onRefresh: () => _loadProfileData(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
          children: [
            if (_loadError != null) _errorBanner(_loadError!),
            _buildHeader(),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _followBusy ? null : _toggleFollow,
                    icon: _followBusy
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : Icon(
                      _following
                          ? Icons.check_rounded
                          : Icons.person_add_alt_1_outlined,
                    ),
                    label: Text(_following ? 'Following' : 'Follow'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ArtistColors.primary,
                      side: const BorderSide(color: ArtistColors.primary),
                      minimumSize: const Size(0, 46),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _email.isNotEmpty || _phone.isNotEmpty
                        ? _contactArtist
                        : null,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtistColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 46),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStats(),
            if (_bio.isNotEmpty) ...[
              const SizedBox(height: 22),
              _section(
                'About',
                Icons.person_outline_rounded,
                Text(
                  _bio,
                  style: ArtistTextStyles.body.copyWith(height: 1.55),
                ),
              ),
            ],
            if (_skills.isNotEmpty) ...[
              const SizedBox(height: 20),
              _section(
                'Skills & Specialties',
                Icons.auto_awesome_outlined,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.map(_skillChip).toList(),
                ),
              ),
            ],
            const SizedBox(height: 22),
            _buildPortfolio(),
            const SizedBox(height: 22),
            _buildProducts(),
            const SizedBox(height: 22),
            _buildReviews(),
            const SizedBox(height: 22),
            if (_verified) _buildCertification(),
            const SizedBox(height: 14),
            const Center(child: Text('EcoLoop • Give Things a New Life')),
          ],
        ),
      ),
    );
  }

  List<String> get _skills {
    final raw =
        _artist['skills'] ?? _artist['specialties'] ?? _artist['categories'];
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArtistColors.light),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: ArtistColors.light,
            backgroundImage: _avatar.isNotEmpty ? NetworkImage(_avatar) : null,
            child: _avatar.isEmpty
                ? Text(
              _name.trim().isEmpty ? 'R' : _name.trim()[0].toUpperCase(),
              style: ArtistTextStyles.title.copyWith(
                fontSize: 34,
                color: ArtistColors.primary,
              ),
            )
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _name,
                  textAlign: TextAlign.center,
                  style: ArtistTextStyles.title.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_verified) ...[
                const SizedBox(width: 5),
                const Icon(
                  Icons.verified_rounded,
                  color: ArtistColors.primary,
                  size: 19,
                ),
              ],
            ],
          ),
          if (_verified) ...[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ArtistColors.light,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Verified ReMaker',
                style: ArtistTextStyles.caption.copyWith(
                  color: ArtistColors.primary,
                ),
              ),
            ),
          ],
          if (_location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: ArtistColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _location,
                    style: ArtistTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
          if (_email.isNotEmpty || _phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [_email, _phone].where((e) => e.isNotEmpty).join(' • '),
              textAlign: TextAlign.center,
              style: ArtistTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStats() {
    final followers = _number(
      _artist['followersCount'] ?? _artist['followers'],
    );
    final sold = _number(
      _artist['soldCount'] ?? _artist['sold'] ?? _artist['totalSold'],
    );
    final average = _averageRating();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.light),
      ),
      child: Row(
        children: [
          _stat('people_outline_rounded', _compact(followers), 'Followers'),
          Container(width: 1, height: 40, color: ArtistColors.light),
          _stat('collections_outlined', '${_portfolio.length}', 'Works'),
          Container(width: 1, height: 40, color: ArtistColors.light),
          _stat('shopping_bag_outlined', '$sold', 'Sold'),
          Container(width: 1, height: 40, color: ArtistColors.light),
          _stat(
            'star_rounded',
            average == null ? '—' : average.toStringAsFixed(1),
            'Rating',
          ),
        ],
      ),
    );
  }

  Widget _stat(String iconName, String value, String label) {
    final icons = <String, IconData>{
      'people_outline_rounded': Icons.people_outline_rounded,
      'collections_outlined': Icons.collections_outlined,
      'shopping_bag_outlined': Icons.shopping_bag_outlined,
      'star_rounded': Icons.star_rounded,
    };
    return Expanded(
      child: Column(
        children: [
          Icon(icons[iconName], color: ArtistColors.primary, size: 19),
          const SizedBox(height: 5),
          Text(
            value,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: ArtistTextStyles.caption.copyWith(fontSize: 9)),
        ],
      ),
    );
  }

  int _number(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _compact(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }

  double? _averageRating() {
    if (_reviews.isEmpty) {
      final raw =
          _artist['rating'] ??
              _artist['averageRating'] ??
              _artist['average_rating'];
      return raw is num
          ? raw.toDouble()
          : double.tryParse(raw?.toString() ?? '');
    }
    final values = _reviews
        .map((r) => double.tryParse(_value(r, ['rating', 'stars'])) ?? 0)
        .where((r) => r > 0)
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Widget _section(String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.light),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: ArtistColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: ArtistTextStyles.title.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _skillChip(String skill) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: ArtistColors.light,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      skill,
      style: ArtistTextStyles.caption.copyWith(color: ArtistColors.primary),
    ),
  );

  Widget _buildPortfolio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Portfolio',
          'Before & after transformations',
          onViewAll: _portfolio.isEmpty
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    _PortfolioListPage(name: _name, items: _portfolio),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        if (_portfolio.isEmpty)
          _emptyCard(
            'No portfolio work yet',
            'This ReMaker has not published portfolio projects.',
          )
        else
          SizedBox(
            height: 285,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _portfolio.length > 5 ? 5 : _portfolio.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (_, i) =>
                  _PortfolioCard(item: _portfolio[i], width: 255),
            ),
          ),
      ],
    );
  }

  Widget _buildProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Products',
          'Available creations from this ReMaker',
          onViewAll: _products.isEmpty
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    _ArtistProductsPage(name: _name, products: _products),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        if (_products.isEmpty)
          _emptyCard(
            'No available products',
            'There are no active products listed by this ReMaker right now.',
          )
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _products.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _ProductCard(
                product: _products[i],
                onTap: () => _showProduct(_products[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeading(
      String title,
      String subtitle, {
        VoidCallback? onViewAll,
      }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ArtistTextStyles.title.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(subtitle, style: ArtistTextStyles.caption),
            ],
          ),
        ),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: const Text('View All')),
      ],
    );
  }

  Widget _emptyCard(String title, String subtitle) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: ArtistColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ArtistColors.light),
    ),
    child: Column(
      children: [
        const Icon(Icons.inbox_outlined, color: ArtistColors.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          title,
          style: ArtistTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: ArtistTextStyles.caption,
        ),
      ],
    ),
  );

  Widget _buildReviews() {
    final average = _averageRating();
    return _section(
      'Reviews',
      Icons.star_outline_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: ArtistColors.primary,
                size: 29,
              ),
              const SizedBox(width: 7),
              Text(
                average?.toStringAsFixed(1) ?? '—',
                style: ArtistTextStyles.title.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${_reviews.length} reviews',
                  style: ArtistTextStyles.caption,
                ),
              ),
              if (_reviews.length > 3)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          _ArtistReviewsPage(name: _name, reviews: _reviews),
                    ),
                  ),
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_reviews.isEmpty)
            Text(
              'No reviews have been published for this ReMaker yet.',
              style: ArtistTextStyles.caption,
            )
          else
            ..._reviews.take(3).map(_reviewTile),
          const SizedBox(height: 14),
          if (_reviewEligibilityChecked && _canReview)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openWriteReview,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Write a Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtistColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          else if (_reviewEligibilityChecked && _alreadyReviewed)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: ArtistColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'You have already reviewed this ReMaker.',
                    style: ArtistTextStyles.caption,
                  ),
                ),
              ],
            )
          else if (_reviewEligibilityChecked)
              Text(
                'Write a review becomes available after a qualifying paid and confirmed/delivered purchase from this ReMaker.',
                style: ArtistTextStyles.caption.copyWith(height: 1.4),
              ),
        ],
      ),
    );
  }

  Widget _reviewTile(Map<String, dynamic> review) {
    final name = _value(review, [
      'reviewerName',
      'userName',
      'name',
      'buyerName',
    ]);
    final comment = _value(review, [
      'comment',
      'review',
      'reviewText',
      'review_text',
      'message',
    ]);
    final rating = _value(review, ['rating', 'stars']);
    final date = _value(review, ['createdAt', 'created_at', 'date']);
    return Container(
      margin: const EdgeInsets.only(top: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArtistColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? 'Buyer' : name,
                  style: ArtistTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.star_rounded,
                color: ArtistColors.primary,
                size: 16,
              ),
              Text(rating.isEmpty ? '—' : rating),
            ],
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(date, style: ArtistTextStyles.caption.copyWith(fontSize: 10)),
          ],
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              comment,
              style: ArtistTextStyles.caption.copyWith(height: 1.45),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCertification() => _section(
    'Certification',
    Icons.workspace_premium_outlined,
    Row(
      children: [
        const Icon(
          Icons.verified_rounded,
          color: ArtistColors.primary,
          size: 27,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EcoLoop ReMaker',
                style: ArtistTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text('Verified creator profile', style: ArtistTextStyles.caption),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _errorBanner(String message) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ArtistColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: ArtistColors.light),
    ),
    child: Text(message, style: ArtistTextStyles.caption),
  );

  void _contactArtist() {
    final address = _location;
    final details = <String>[
      if (_email.isNotEmpty) 'Email: $_email',
      if (address.isNotEmpty) 'Address: $address',
      if (_phone.isNotEmpty) 'Phone: $_phone',
    ];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Contact $_name'),
        content: details.isEmpty
            ? const Text('No public contact information is available.')
            : SelectableText(details.join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProduct(Map<String, dynamic> product) async {
    final id = _value(product, ['productId', 'product_id', 'id']);
    if (id.isEmpty) {
      _message('Product details are unavailable for this item.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProductDetails(product: Map<String, dynamic>.from(product)),
      ),
    );
    if (mounted) await _loadProfileData(refresh: true);
  }
}

class _ArtistProductsPage extends StatelessWidget {
  const _ArtistProductsPage({required this.name, required this.products});

  final String name;
  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        title: Text('$name Products', style: ArtistTextStyles.title),
      ),
      body: products.isEmpty
          ? Center(
        child: Text(
          'No available products yet.',
          style: ArtistTextStyles.caption,
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: .66,
        ),
        itemBuilder: (context, index) => _ProductCard(
          product: products[index],
          width: double.infinity,
          onTap: () {
            final product = products[index];
            final id =
                product['productId'] ??
                    product['product_id'] ??
                    product['id'];
            if (id == null || id.toString().trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Product details are unavailable.'),
                ),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProductDetails(
                  product: Map<String, dynamic>.from(product),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ArtistReviewsPage extends StatelessWidget {
  const _ArtistReviewsPage({required this.name, required this.reviews});

  final String name;
  final List<Map<String, dynamic>> reviews;

  String _value(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty)
        return value.toString().trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        title: Text('$name Reviews', style: ArtistTextStyles.title),
      ),
      body: reviews.isEmpty
          ? Center(
        child: Text('No reviews yet.', style: ArtistTextStyles.caption),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reviews.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final review = reviews[index];
          final reviewer = _value(review, [
            'reviewerName',
            'userName',
            'name',
            'buyerName',
          ]);
          final rating = _value(review, ['rating', 'stars']);
          final comment = _value(review, [
            'comment',
            'review',
            'text',
            'description',
          ]);
          final date = _value(review, [
            'createdAt',
            'created_at',
            'date',
            'reviewDate',
          ]);
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ArtistColors.light),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reviewer.isEmpty ? 'EcoLoop customer' : reviewer,
                        style: ArtistTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.star_rounded,
                      color: ArtistColors.primary,
                      size: 17,
                    ),
                    Text(rating.isEmpty ? '—' : rating),
                  ],
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: ArtistTextStyles.caption.copyWith(
                      fontSize: 10,
                    ),
                  ),
                ],
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    comment,
                    style: ArtistTextStyles.caption.copyWith(
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PortfolioListPage extends StatelessWidget {
  const _PortfolioListPage({required this.name, required this.items});

  final String name;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ArtistColors.background,
    appBar: AppBar(
      backgroundColor: ArtistColors.background,
      title: Text('$name Portfolio', style: ArtistTextStyles.title),
    ),
    body: GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: .72,
      ),
      itemBuilder: (_, i) =>
          _PortfolioCard(item: items[i], width: double.infinity),
    ),
  );
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({required this.item, required this.width});

  final Map<String, dynamic> item;
  final double width;

  String _value(List<String> keys) {
    for (final key in keys) {
      final v = item[key];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final title = _value(['title', 'name']);
    final category = _value(['category']);
    final before = _value([
      'beforeImageUrl',
      'before_image_url',
      'before',
      'imageBefore',
    ]);
    final after = _value([
      'afterImageUrl',
      'after_image_url',
      'after',
      'imageUrl',
      'image_url',
      'image',
    ]);
    final description = _value(['description', 'caption']);
    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          constraints: const BoxConstraints(maxHeight: 700),
          decoration: const BoxDecoration(
            color: ArtistColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 270,
                  child: Row(
                    children: [
                      Expanded(child: _image(before, 'BEFORE')),
                      Container(width: 2, color: ArtistColors.surface),
                      Expanded(child: _image(after, 'AFTER')),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'Portfolio project' : title,
                        style: ArtistTextStyles.title.copyWith(fontSize: 20),
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          category,
                          style: ArtistTextStyles.caption.copyWith(
                            color: ArtistColors.primary,
                          ),
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: ArtistTextStyles.body.copyWith(height: 1.5),
                        ),
                      ],
                      for (final pair in <List<String>>[
                        [
                          'Materials',
                          _value(['materialsUsed', 'materials_used']),
                        ],
                        [
                          'Process',
                          _value(['processDescription', 'process_description']),
                        ],
                        [
                          'Environmental impact',
                          _value([
                            'environmentalImpact',
                            'environmental_impact',
                          ]),
                        ],
                      ])
                        if (pair[1].isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            pair[0],
                            style: ArtistTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            pair[1],
                            style: ArtistTextStyles.caption.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ArtistColors.light),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _image(before, 'BEFORE')),
                  Container(width: 1, color: ArtistColors.surface),
                  Expanded(child: _image(after, 'AFTER')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Portfolio project' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (category.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: ArtistTextStyles.caption.copyWith(
                        color: ArtistColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(String url, String label) => Stack(
    fit: StackFit.expand,
    children: [
      if (url.isNotEmpty)
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        )
      else
        _fallback(),
      Positioned(
        left: 7,
        top: 7,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: label == 'BEFORE' ? Colors.black54 : ArtistColors.primary,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _fallback() => Container(
    color: ArtistColors.light,
    child: const Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: ArtistColors.primary,
      ),
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    this.width = 185,
  });

  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final double width;

  String _value(List<String> keys) {
    for (final key in keys) {
      final value = product[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final title = _value(['title', 'name']);
    final price = _value(['price', 'sellingPrice', 'selling_price']);
    final category = _value(['category', 'categoryName', 'category_name']);
    final image = _value([
      'imageUrl',
      'image_url',
      'image',
      'thumbnail',
      'primaryImage',
    ]);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ArtistColors.light),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: image.isEmpty
                  ? Container(
                color: ArtistColors.light,
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    color: ArtistColors.primary,
                    size: 35,
                  ),
                ),
              )
                  : Image.network(
                image,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: ArtistColors.light,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: ArtistColors.primary,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Product' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (price.isNotEmpty)
                    Text(
                      '₹$price',
                      style: ArtistTextStyles.title.copyWith(
                        color: ArtistColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  if (category.isNotEmpty)
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.caption,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
