import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../reviews/seller_reviews.dart';
import 'product_details.dart';

class SellerProfile extends StatefulWidget {
  const SellerProfile({super.key, required this.seller});

  final Map<String, dynamic> seller;

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  List<Map<String, dynamic>> _listings = <Map<String, dynamic>>[];
  bool _loadingListings = true;
  bool _loadingProfile = true;
  String? _profileError;
  Map<String, dynamic> _profile = <String, dynamic>{};
  Map<String, dynamic> _stats = <String, dynamic>{};
  bool _showAllListings = false;
  String? _listingError;
  Map<String, dynamic> _contactDetails = <String, dynamic>{};
  bool _loadingContact = false;

  // SELLER TYPE
  String get sellerType {
    final value =
        widget.seller['sellerType'] ??
        widget.seller['role'] ??
        widget.seller['type'] ??
        'user';

    return value.toString().toLowerCase();
  }

  bool get isArtist {
    return sellerType == 'artist' ||
        sellerType == 'remaker' ||
        sellerType == 're_maker';
  }

  String get sellerRoleLabel {
    return isArtist ? 'EcoLoop ReMaker' : 'EcoLoop User';
  }

  // INIT
  @override
  void initState() {
    super.initState();

    _loadSellerProfile();
  }

  // One lightweight endpoint returns the profile, aggregate stats and only this seller's listings.
  Future<void> _loadSellerProfile() async {
    if (mounted) {
      setState(() {
        _loadingProfile = true;
        _loadingListings = true;
        _profileError = null;
        _listingError = null;
      });
    }
    try {
      final raw = await EcoLoopApi.instance.get(
        '/public/seller/${isArtist ? 'artist' : 'user'}/$_sellerId/profile',
      );
      if (raw is! Map)
        throw const FormatException('Invalid seller profile response.');
      final data = Map<String, dynamic>.from(raw);
      final seller = data['seller'];
      final stats = data['stats'];
      final products = data['products'];
      if (!mounted) return;
      setState(() {
        _profile = seller is Map
            ? Map<String, dynamic>.from(seller)
            : <String, dynamic>{};
        _stats = stats is Map
            ? Map<String, dynamic>.from(stats)
            : <String, dynamic>{};
        _listings = (products is List ? products : <dynamic>[])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loadingProfile = false;
        _loadingListings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError = e.toString();
        _listingError = e.toString();
        _loadingProfile = false;
        _loadingListings = false;
      });
    }
  }

  String _text(dynamic value, {String fallback = ''}) {
    final result = (value ?? '').toString().trim();
    return result.isEmpty ? fallback : result;
  }

  String _dateLabel(dynamic value) {
    final raw = _text(value);
    if (raw.isEmpty) return 'Member date unavailable';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String get _sellerId =>
      (widget.seller['userId'] ??
              widget.seller['id'] ??
              widget.seller['sellerId'] ??
              widget.seller['artistId'] ??
              '')
          .toString();

  Future<void> _loadContactDetails() async {
    if (_loadingContact) return;
    setState(() => _loadingContact = true);
    try {
      final raw = await EcoLoopApi.instance.get(
        '/sellers/user/$_sellerId/contact',
      );
      if (!mounted) return;
      setState(() {
        if (raw is Map) _contactDetails = Map<String, dynamic>.from(raw);
        _loadingContact = false;
      });
      _showContactCard();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingContact = false);
      // Use any contact fields already supplied by the caller if API route is not deployed.
      _contactDetails = Map<String, dynamic>.from(widget.seller);
      _showContactCard();
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final sellerData = <String, dynamic>{...widget.seller, ..._profile};
    final sellerName = _text(
      sellerData['name'] ?? sellerData['userName'] ?? sellerData['username'],
      fallback: '',
    );
    final sellerImage = _getSellerImage();
    final location = _text(sellerData['location'], fallback: _buildLocation());
    final rating = _number(_stats['rating']).toStringAsFixed(1);
    final reviews = _number(_stats['reviewCount']).toInt().toString();
    final listings = _number(_stats['listings']).toInt().toString();
    final sold = _number(_stats['sold']).toInt().toString();
    final positive = '${_number(_stats['positivePercent']).toInt()}%';
    final memberSince = _dateLabel(
      sellerData['memberSince'] ?? sellerData['createdAt'],
    );

    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
        ),
        title: Text(
          'Seller Profile',
          style: ArtistTextStyles.title.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSellerHeader(
                sellerName: sellerName,
                sellerImage: sellerImage,
                location: location,
                rating: rating,
                reviews: reviews,
                memberSince: memberSince,
              ),
              const SizedBox(height: 18),
              _buildActionButtons(),
              const SizedBox(height: 22),
              _buildStats(listings: listings, sold: sold, positive: positive),
              const SizedBox(height: 24),
              _buildReviewsSection(
                sellerName: sellerName,
                sellerImage: sellerImage,
                location: location,
                rating: rating,
                reviews: reviews,
              ),
              const SizedBox(height: 25),
              _buildListingsHeader(),
              const SizedBox(height: 12),
              if (_profileError != null && _listings.isEmpty)
                Center(
                  child: TextButton.icon(
                    onPressed: _loadSellerProfile,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry loading seller profile'),
                  ),
                ),
              _buildListingsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // SELLER IMAGE
  String? _getSellerImage() {
    final image =
        _profile['profilePhotoUrl'] ??
        _profile['image'] ??
        widget.seller['image'] ??
        widget.seller['profilePhotoUrl'] ??
        widget.seller['profileImage'] ??
        widget.seller['photoUrl'];

    if (image == null) {
      return null;
    }

    final value = image.toString().trim();
    return value.isEmpty ? null : value;
  }

  // LOCATION
  String _buildLocation() {
    final city = widget.seller['city']?.toString() ?? '';
    final state = widget.seller['state']?.toString() ?? '';
    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city, $state';
    }

    if (city.isNotEmpty) {
      return city;
    }

    if (state.isNotEmpty) {
      return state;
    }
    return 'Location unavailable';
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // SELLER HEADER

  Widget _buildSellerHeader({
    required String sellerName,
    required String? sellerImage,
    required String location,
    required String rating,
    required String reviews,
    required String memberSince,
  }) {
    final hasImage = sellerImage != null && sellerImage.trim().isNotEmpty;

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  shape: BoxShape.circle,
                  border: Border.all(color: ArtistColors.accent, width: 3),
                ),
                child: hasImage
                    ? ClipOval(
                        child: Image.network(
                          sellerImage,
                          width: 94,
                          height: 94,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildSellerInitial(sellerName);
                          },
                        ),
                      )
                    : _buildSellerInitial(sellerName),
              ),
              Positioned(
                right: 1,
                bottom: 3,
                child: Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: ArtistColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: ArtistColors.surface, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  sellerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.title.copyWith(fontSize: 20),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.verified_rounded,
                size: 18,
                color: ArtistColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: ArtistColors.light.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sellerRoleLabel,
              style: ArtistTextStyles.small.copyWith(
                color: ArtistColors.primary,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              _openSellerReviews(
                sellerName: sellerName,
                sellerImage: sellerImage,
                location: location,
                rating: rating,
                reviews: reviews,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: ArtistColors.primary,
                  size: 17,
                ),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    color: ArtistColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 3),
                Text('($reviews reviews)', style: ArtistTextStyles.caption),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: ArtistColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: ArtistColors.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Member since $memberSince',
            style: ArtistTextStyles.caption.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }

  // SELLER INITIAL

  Widget _buildSellerInitial(String sellerName) {
    return Center(
      child: Text(
        sellerName.isNotEmpty ? sellerName[0].toUpperCase() : 'S',
        style: ArtistTextStyles.heading.copyWith(
          color: ArtistColors.primary,
          fontSize: 36,
        ),
      ),
    );
  }

  // ACTION BUTTONS

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _contactSeller,
        icon: const Icon(Icons.contact_phone_outlined, size: 18),
        label: Text(
          'Contact Seller',
          style: ArtistTextStyles.button.copyWith(fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ArtistColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // STATS

  Widget _buildStats({
    required String listings,
    required String sold,
    required String positive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              value: listings,
              label: 'Listings',
              icon: Icons.inventory_2_outlined,
            ),
          ),
          _statDivider(),
          Expanded(
            child: _statItem(
              value: sold,
              label: 'Sold',
              icon: Icons.shopping_bag_outlined,
            ),
          ),
          _statDivider(),
          Expanded(
            child: _statItem(
              value: positive,
              label: 'Positive',
              icon: Icons.thumb_up_alt_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: ArtistColors.primary),
        const SizedBox(height: 5),
        Text(value, style: ArtistTextStyles.title.copyWith(fontSize: 17)),
        const SizedBox(height: 2),
        Text(label, style: ArtistTextStyles.caption.copyWith(fontSize: 9)),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 42,
      color: ArtistColors.accent.withValues(alpha: 0.55),
    );
  }

  // REVIEWS

  Widget _buildReviewsSection({
    required String sellerName,
    required String? sellerImage,
    required String location,
    required String rating,
    required String reviews,
  }) {
    final ratingValue = double.tryParse(rating) ?? 0;

    final reviewCount = int.tryParse(reviews) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews', style: ArtistTextStyles.title.copyWith(fontSize: 16)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            _openSellerReviews(
              sellerName: sellerName,
              sellerImage: sellerImage,
              location: location,
              rating: rating,
              reviews: reviews,
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ArtistColors.accent.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: ArtistColors.light,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: ArtistColors.primary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArtist ? 'ReMaker Reviews' : 'Seller Reviews',
                        style: ArtistTextStyles.title.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: ArtistColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ratingValue.toStringAsFixed(1),
                            style: ArtistTextStyles.body.copyWith(
                              color: ArtistColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$reviewCount reviews',
                            style: ArtistTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ArtistColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // SELLER REVIEWS

  void _openSellerReviews({
    required String sellerName,
    required String? sellerImage,
    required String location,
    required String rating,
    required String reviews,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerReviews(
          sellerId:
              (widget.seller['userId'] ??
                      widget.seller['id'] ??
                      widget.seller['sellerId'] ??
                      '')
                  .toString(),
          sellerType: sellerType,
          sellerName: sellerName,
          sellerImage: sellerImage,
          sellerLocation: location,
        ),
      ),
    );
  }

  // LISTINGS HEADER

  Widget _buildListingsHeader() {
    return Row(
      children: [
        Text(
          'Active Listings',
          style: ArtistTextStyles.title.copyWith(fontSize: 16),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: ArtistColors.light,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$_listingsCount',
            style: ArtistTextStyles.small.copyWith(
              color: ArtistColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        if (_listings.length > 4)
          TextButton(
            onPressed: () =>
                setState(() => _showAllListings = !_showAllListings),
            child: Text(
              _showAllListings ? 'Show Less' : 'View All',
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: ArtistColors.primary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  int get _listingsCount => _listings.length;

  // LISTINGS GRID

  Widget _buildListingsGrid() {
    if (_loadingListings)
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    if (_listingError != null) {
      return Column(
        children: [
          Text(
            'Could not load active listings',
            style: ArtistTextStyles.bodyMedium,
          ),
          TextButton.icon(
            onPressed: _loadSellerProfile,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      );
    }
    if (_listings.isEmpty) return _buildEmptyListings();
    final visible = _showAllListings ? _listings : _listings.take(4).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.67,
      ),
      itemBuilder: (context, index) {
        final product = visible[index];
        final rawImages =
            product['imageUrls'] ??
            product['images'] ??
            product['imageUrlsJson'];
        List<dynamic> images = rawImages is List ? rawImages : <dynamic>[];
        if (images.isEmpty &&
            rawImages is String &&
            rawImages.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawImages);
            if (decoded is List) images = decoded;
            if (decoded is String && decoded.trim().isNotEmpty)
              images = <dynamic>[decoded];
          } catch (_) {
            if (rawImages.startsWith('http')) images = <dynamic>[rawImages];
          }
        }
        final mapped = <String, dynamic>{
          ...product,
          'id': product['productId'] ?? product['id'],
          'seller':
              product['sellerName'] ??
              widget.seller['name'] ??
              widget.seller['userName'] ??
              'Seller',
          'location':
              [
                    product['sellerCity'] ?? product['city'],
                    product['sellerState'] ?? product['state'],
                  ]
                  .where((e) => e != null && e.toString().trim().isNotEmpty)
                  .join(', '),
          'image': images.isNotEmpty ? images.first : '',
          'images': images,
        };
        return _SellerProductCard(
          product: mapped,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetails(product: mapped)),
          ),
        );
      },
    );
  }

  // EMPTY LISTINGS

  Widget _buildEmptyListings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: ArtistColors.light,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: ArtistColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No Active Listings',
            style: ArtistTextStyles.title.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            'This seller currently has no active products.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.body.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Contact details are loaded from the seller-contact endpoint backed by Sheets.
  void _contactSeller() => _loadContactDetails();

  void _showContactCard() {
    final name =
        (_contactDetails['name'] ??
                _contactDetails['sellerName'] ??
                widget.seller['name'] ??
                widget.seller['userName'] ??
                'Seller')
            .toString();
    final phone = (_contactDetails['phone'] ?? _contactDetails['mobile'] ?? '')
        .toString();
    final email = (_contactDetails['email'] ?? '').toString();
    final address =
        (_contactDetails['address'] ?? _contactDetails['addressLine'] ?? '')
            .toString();
    final city = (_contactDetails['city'] ?? widget.seller['city'] ?? '')
        .toString();
    final state = (_contactDetails['state'] ?? widget.seller['state'] ?? '')
        .toString();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ArtistColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Seller Contact Details',
                style: ArtistTextStyles.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(name, style: ArtistTextStyles.bodyMedium),
              const SizedBox(height: 16),
              _contactRow(Icons.phone_outlined, 'Mobile number', phone),
              _contactRow(Icons.email_outlined, 'Email', email),
              _contactRow(
                Icons.location_on_outlined,
                'Address',
                [address, city, state, _contactDetails['pincode']]
                    .where((e) => e != null && e.toString().trim().isNotEmpty)
                    .join(', '),
              ),
              if ([
                phone,
                email,
                address,
                city,
                state,
              ].every((e) => e.toString().trim().isEmpty))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Contact details are not available yet.',
                    style: ArtistTextStyles.caption,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ArtistColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArtistColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ArtistColors.primary, size: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ArtistTextStyles.caption),
                const SizedBox(height: 3),
                Text(
                  value.trim().isEmpty ? 'Not provided' : value,
                  style: ArtistTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MESSAGE

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: ArtistTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ArtistColors.textPrimary,
      ),
    );
  }
}

// SELLER PRODUCT CARD

class _SellerProductCard extends StatelessWidget {
  const _SellerProductCard({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = _priceValue(product['price']);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: ArtistColors.accent.withValues(alpha: 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child:
                        (product['image']?.toString().trim().isNotEmpty ??
                            false)
                        ? Image.network(
                            product['image'].toString(),
                            fit: BoxFit.cover,
                            cacheWidth: 480,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: ArtistColors.light,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 32,
                                    color: ArtistColors.secondary,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: ArtistColors.light,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 32,
                                color: ArtistColors.secondary,
                              ),
                            ),
                          ),
                  ),

                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        product['condition']?.toString() ?? '-',
                        style: ArtistTextStyles.small.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: ArtistColors.primary,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product['category']?.toString() ?? '-',
                        style: ArtistTextStyles.small.copyWith(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title']?.toString() ?? 'Product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.body.copyWith(
                      color: ArtistColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '₹$price',
                    style: ArtistTextStyles.title.copyWith(fontSize: 16),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 11,
                        color: ArtistColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${product['views'] ?? 0} views',
                        style: ArtistTextStyles.caption.copyWith(fontSize: 9),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: ArtistColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _priceValue(dynamic value) {
    if (value is num) {
      if (value % 1 == 0) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }
    return value?.toString() ?? '0';
  }
}
