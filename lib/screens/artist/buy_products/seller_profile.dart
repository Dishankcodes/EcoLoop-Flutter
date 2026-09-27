import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../user/reviews/seller_reviews.dart';
import 'product_details.dart';

class SellerProfile extends StatefulWidget {
  const SellerProfile({super.key, required this.seller});

  final Map<String, dynamic> seller;

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  bool _isFollowing = false;

  late final List<Map<String, dynamic>> _listings;

  // ==========================================================
  // SELLER TYPE
  // ==========================================================

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

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _listings = _createListings();
  }

  // ==========================================================
  // CREATE LISTINGS DATA
  // ==========================================================

  List<Map<String, dynamic>> _createListings() {
    final sellerName =
        widget.seller['name']?.toString() ??
        widget.seller['userName']?.toString() ??
        widget.seller['username']?.toString() ??
        'Seller';

    final location = widget.seller['location']?.toString() ?? _buildLocation();

    return [
      {
        'id': 101,
        'title': 'Wooden Study Table',
        'price': 2500,
        'seller': sellerName,
        'sellerType': sellerType,
        'condition': 'Used',
        'category': 'Furniture',
        'location': location,
        'views': 182,
        'wishlistCount': 21,
        'availableQuantity': 1,
        'quantity': 1,
        'description':
            'Solid wooden study table in good condition. Suitable for home offices, study rooms and creative spaces.',
        'image':
            'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?auto=format&fit=crop&w=1000&q=85',
        'images': [
          'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc?auto=format&fit=crop&w=1200&q=85',
        ],
      },
      {
        'id': 102,
        'title': 'Wooden Side Chair',
        'price': 1200,
        'seller': sellerName,
        'sellerType': sellerType,
        'condition': 'Good',
        'category': 'Furniture',
        'location': location,
        'views': 94,
        'wishlistCount': 12,
        'availableQuantity': 2,
        'quantity': 2,
        'description':
            'Comfortable wooden chair that can be reused at home, in a workspace or for creative projects.',
        'image':
            'https://images.unsplash.com/photo-1503602642458-232111445657?auto=format&fit=crop&w=1000&q=85',
        'images': [
          'https://images.unsplash.com/photo-1503602642458-232111445657?auto=format&fit=crop&w=1200&q=85',
        ],
      },
      {
        'id': 103,
        'title': 'Reclaimed Wood Pieces',
        'price': 450,
        'seller': sellerName,
        'sellerType': sellerType,
        'condition': 'Recycled',
        'category': 'Materials',
        'location': location,
        'views': 71,
        'wishlistCount': 8,
        'availableQuantity': 5,
        'quantity': 5,
        'description':
            'Collection of reclaimed wood pieces for DIY, crafting and upcycling projects.',
        'image':
            'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=1000&q=85',
        'images': [
          'https://images.unsplash.com/photo-1519710164239-da123dc03ef4?auto=format&fit=crop&w=1200&q=85',
        ],
      },
      {
        'id': 104,
        'title': 'Vintage Storage Cabinet',
        'price': 2200,
        'seller': sellerName,
        'sellerType': sellerType,
        'condition': 'Used',
        'category': 'Furniture',
        'location': location,
        'views': 143,
        'wishlistCount': 16,
        'availableQuantity': 1,
        'quantity': 1,
        'description':
            'Vintage storage cabinet with plenty of room for books, decor and household items.',
        'image':
            'https://images.unsplash.com/photo-1558997519-83ea9252edf8?auto=format&fit=crop&w=1000&q=85',
        'images': [
          'https://images.unsplash.com/photo-1558997519-83ea9252edf8?auto=format&fit=crop&w=1200&q=85',
        ],
      },
    ];
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final sellerName =
        widget.seller['name']?.toString() ??
        widget.seller['userName']?.toString() ??
        widget.seller['username']?.toString() ??
        'Seller';

    final sellerImage = _getSellerImage();

    final location = widget.seller['location']?.toString() ?? _buildLocation();

    final rating = widget.seller['rating']?.toString() ?? '4.8';

    final reviews = widget.seller['reviews']?.toString() ?? '42';

    final listings =
        widget.seller['listings']?.toString() ?? '${_listings.length}';

    final sold = widget.seller['sold']?.toString() ?? '42';

    final positive = widget.seller['positive']?.toString() ?? '98%';

    final memberSince =
        widget.seller['memberSince']?.toString() ?? 'January 2025';

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
        actions: [
          IconButton(
            tooltip: 'More',
            onPressed: _showMoreOptions,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: ArtistColors.textPrimary,
            ),
          ),
        ],
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
              _buildAboutSeller(),
              const SizedBox(height: 18),
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
              _buildListingsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SELLER IMAGE
  // ==========================================================

  String? _getSellerImage() {
    final image =
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

  // ==========================================================
  // LOCATION
  // ==========================================================

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

    return 'Ahmedabad, Gujarat';
  }

  // ==========================================================
  // SELLER HEADER
  // ==========================================================

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

  // ==========================================================
  // SELLER INITIAL
  // ==========================================================

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

  // ==========================================================
  // ACTION BUTTONS
  // ==========================================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isFollowing = !_isFollowing;
              });

              _showMessage(
                _isFollowing
                    ? 'You are now following this seller.'
                    : 'Seller removed from following.',
              );
            },
            icon: Icon(
              _isFollowing
                  ? Icons.check_rounded
                  : Icons.person_add_alt_1_outlined,
              size: 17,
            ),
            label: Text(
              _isFollowing ? 'Following' : 'Follow',
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: ArtistColors.primary,
                fontSize: 12.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ArtistColors.primary,
              side: const BorderSide(color: ArtistColors.primary),
              minimumSize: const Size(0, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _contactSeller,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
            label: Text(
              'Contact Seller',
              style: ArtistTextStyles.button.copyWith(fontSize: 12.5),
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
        ),
      ],
    );
  }

  // ==========================================================
  // STATS
  // ==========================================================

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

  // ==========================================================
  // ABOUT SELLER
  // ==========================================================

  Widget _buildAboutSeller() {
    final bio = widget.seller['bio']?.toString();

    final skills = widget.seller['skills']?.toString();

    final defaultBio = isArtist
        ? 'I create meaningful products by giving materials and everyday objects a second life through creative design and sustainable craftsmanship.'
        : 'I believe useful things should not be thrown away. I enjoy giving furniture, materials and household items a second life.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArtist ? 'About ReMaker' : 'About Seller',
          style: ArtistTextStyles.title.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: ArtistColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ArtistColors.accent.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bio != null && bio.trim().isNotEmpty ? bio : defaultBio,
                style: ArtistTextStyles.body.copyWith(
                  fontSize: 12,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 13),
              if (skills != null && skills.trim().isNotEmpty)
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: _buildSkillTags(skills),
                )
              else
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _interestTag('Sustainability'),
                    _interestTag('Upcycling'),
                    _interestTag('DIY'),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSkillTags(String skills) {
    final values = skills
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(5)
        .toList();

    return values.map((skill) => _interestTag(skill)).toList();
  }

  Widget _interestTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: ArtistTextStyles.small.copyWith(
          fontSize: 9,
          color: ArtistColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================================
  // REVIEWS
  // ==========================================================

  Widget _buildReviewsSection({
    required String sellerName,
    required String? sellerImage,
    required String location,
    required String rating,
    required String reviews,
  }) {
    final ratingValue = double.tryParse(rating) ?? 4.8;

    final reviewCount = int.tryParse(reviews) ?? 42;

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

  // ==========================================================
  // SELLER REVIEWS
  // ==========================================================

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
          sellerName: sellerName,
          sellerImage: sellerImage,
          sellerLocation: location,
          rating: double.tryParse(rating) ?? 4.8,
          reviewCount: int.tryParse(reviews) ?? 42,
          isVerified: true,
        ),
      ),
    );
  }

  // ==========================================================
  // LISTINGS HEADER
  // ==========================================================

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
            '${_listings.length}',
            style: ArtistTextStyles.small.copyWith(
              color: ArtistColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Newest',
          style: ArtistTextStyles.caption.copyWith(
            color: ArtistColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 3),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: ArtistColors.primary,
        ),
      ],
    );
  }

  // ==========================================================
  // LISTINGS GRID
  // ==========================================================

  Widget _buildListingsGrid() {
    if (_listings.isEmpty) {
      return _buildEmptyListings();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _listings.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.67,
      ),
      itemBuilder: (context, index) {
        final product = _listings[index];

        return _SellerProductCard(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetails(product: product),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // EMPTY LISTINGS
  // ==========================================================

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

  // ==========================================================
  // CONTACT SELLER
  // ==========================================================

  void _contactSeller() {
    final sellerName =
        widget.seller['name']?.toString() ??
        widget.seller['userName']?.toString() ??
        'Seller';

    _showMessage('Chat with $sellerName will be connected later.');
  }

  // ==========================================================
  // MORE OPTIONS
  // ==========================================================

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ArtistColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                _sellerOption(
                  icon: Icons.flag_outlined,
                  title: 'Report Seller',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage('Report seller option selected.');
                  },
                ),
                const SizedBox(height: 9),
                _sellerOption(
                  icon: Icons.block_outlined,
                  title: 'Block Seller',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage('Block seller option selected.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // SELLER OPTION
  // ==========================================================

  Widget _sellerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final optionColor = destructive ? ArtistColors.error : ArtistColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: destructive
              ? ArtistColors.error.withValues(alpha: 0.05)
              : ArtistColors.background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: destructive
                ? ArtistColors.error.withValues(alpha: 0.20)
                : ArtistColors.accent.withValues(alpha: 0.40),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: optionColor),
            const SizedBox(width: 10),
            Text(
              title,
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: optionColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: destructive
                  ? ArtistColors.error
                  : ArtistColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

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

// ============================================================
// SELLER PRODUCT CARD
// ============================================================

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
                    child: Image.network(
                      product['image']?.toString() ?? '',
                      fit: BoxFit.cover,
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
