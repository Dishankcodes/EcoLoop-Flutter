import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

/// ===============================================================
/// PUBLIC ARTIST PROFILE
/// ===============================================================
///
/// This page is used when a USER views another ARTIST / REMAKER.
///
/// It is intentionally separate from the artist's own Profile page.
///
/// Own Profile:
///     - Edit profile
///     - Manage products
///     - Manage portfolio
///     - Settings
///
/// Public Artist Profile:
///     - Follow artist
///     - Contact artist
///     - About
///     - Portfolio
///     - Before / After work
///     - Products
///     - Reviews
///     - Certification
///     - Report / Block
///
/// Later, [artist] can be populated directly from the Django API.
/// The current implementation contains safe demo fallback data so
/// the UI can be developed and tested before the API is connected.
/// ===============================================================

class ArtistProfile extends StatefulWidget {
  const ArtistProfile({super.key, required this.artist});

  /// Artist data received from marketplace / artist listing.
  ///
  /// Supported keys:
  ///
  /// id
  /// name / userName
  /// email
  /// phone
  /// bio
  /// city
  /// state
  /// location
  /// skills
  /// experience
  /// rating
  /// reviews
  /// followers
  /// products
  /// sold
  /// verified
  /// profileImage
  final Map<String, dynamic> artist;

  @override
  State<ArtistProfile> createState() => _ArtistProfileState();
}

class _ArtistProfileState extends State<ArtistProfile> {
  // ===============================================================
  // UI STATE
  // ===============================================================

  bool _isFollowing = false;

  // ===============================================================
  // DEMO PORTFOLIO
  // ===============================================================
  //
  // These are intentionally structured so they can later be replaced
  // by API response objects.
  //
  // BEFORE / AFTER is a core ReOrbit / EcoLoop artist feature.
  // ===============================================================

  late final List<Map<String, dynamic>> _portfolio;

  // ===============================================================
  // DEMO PRODUCTS
  // ===============================================================

  late final List<Map<String, dynamic>> _products;

  @override
  void initState() {
    super.initState();

    _portfolio = [
      {
        'id': 1,
        'title': 'Reclaimed Wood Coffee Table',
        'category': 'Furniture',
        'description':
            'A discarded wooden frame transformed into a functional '
            'and modern coffee table.',
        'before':
            'https://images.unsplash.com/photo-1519710164239-da123dc03ef4'
            '?auto=format&fit=crop&w=1000&q=85',
        'after':
            'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc'
            '?auto=format&fit=crop&w=1000&q=85',
        'likes': 84,
        'views': 312,
        'featured': true,
      },
      {
        'id': 2,
        'title': 'Upcycled Wall Decor',
        'category': 'Home Decor',
        'description':
            'Old materials redesigned into a handmade decorative '
            'wall piece.',
        'before':
            'https://images.unsplash.com/photo-1501004318641-b39e6451bec6'
            '?auto=format&fit=crop&w=1000&q=85',
        'after':
            'https://images.unsplash.com/photo-1549490349-8643362247b5'
            '?auto=format&fit=crop&w=1000&q=85',
        'likes': 61,
        'views': 248,
        'featured': true,
      },
      {
        'id': 3,
        'title': 'Recycled Wooden Organizer',
        'category': 'Utility',
        'description':
            'Leftover wood pieces converted into a useful desk '
            'organizer.',
        'before':
            'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122'
            '?auto=format&fit=crop&w=1000&q=85',
        'after':
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7'
            '?auto=format&fit=crop&w=1000&q=85',
        'likes': 42,
        'views': 176,
        'featured': false,
      },
      {
        'id': 4,
        'title': 'Decorative Shelf',
        'category': 'Furniture',
        'description':
            'Reclaimed timber turned into a minimalist decorative shelf.',
        'before':
            'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4'
            '?auto=format&fit=crop&w=1000&q=85',
        'after':
            'https://images.unsplash.com/photo-1594620302200-9a762244a156'
            '?auto=format&fit=crop&w=1000&q=85',
        'likes': 37,
        'views': 151,
        'featured': false,
      },
    ];

    _products = [
      {
        'id': 101,
        'title': 'Reclaimed Wood Coffee Table',
        'price': 2500,
        'category': 'Furniture',
        'condition': 'Upcycled',
        'image':
            'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc'
            '?auto=format&fit=crop&w=1000&q=85',
      },
      {
        'id': 102,
        'title': 'Handmade Wall Decor',
        'price': 850,
        'category': 'Home Decor',
        'condition': 'Handmade',
        'image':
            'https://images.unsplash.com/photo-1549490349-8643362247b5'
            '?auto=format&fit=crop&w=1000&q=85',
      },
      {
        'id': 103,
        'title': 'Wooden Desk Organizer',
        'price': 650,
        'category': 'Utility',
        'condition': 'Upcycled',
        'image':
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7'
            '?auto=format&fit=crop&w=1000&q=85',
      },
      {
        'id': 104,
        'title': 'Reclaimed Shelf',
        'price': 1200,
        'category': 'Furniture',
        'condition': 'Upcycled',
        'image':
            'https://images.unsplash.com/photo-1594620302200-9a762244a156'
            '?auto=format&fit=crop&w=1000&q=85',
      },
    ];
  }

  // ===============================================================
  // DATA HELPERS
  // ===============================================================

  String _artistName() {
    return widget.artist['name']?.toString() ??
        widget.artist['userName']?.toString() ??
        'Creative Studio';
  }

  String _location() {
    if (widget.artist['location'] != null) {
      return widget.artist['location'].toString();
    }

    final city = widget.artist['city']?.toString();
    final state = widget.artist['state']?.toString();

    if (city != null && city.isNotEmpty && state != null && state.isNotEmpty) {
      return '$city, $state';
    }

    if (city != null && city.isNotEmpty) {
      return city;
    }

    return 'Ahmedabad, Gujarat';
  }

  String _bio() {
    return widget.artist['bio']?.toString() ??
        'I create meaningful products by giving discarded materials '
            'a new life through thoughtful design, craftsmanship and '
            'sustainable creativity.';
  }

  String _rating() {
    return widget.artist['rating']?.toString() ?? '4.8';
  }

  int _reviewCount() {
    return _toInt(widget.artist['reviews'], 42);
  }

  int _followers() {
    return _toInt(widget.artist['followers'], 1240);
  }

  int _sold() {
    return _toInt(widget.artist['sold'], 42);
  }

  bool _isVerified() {
    return widget.artist['verified'] != false;
  }

  String? _profileImage() {
    final image =
        widget.artist['profileImage'] ??
        widget.artist['profile_image'] ??
        widget.artist['image'];

    if (image == null) {
      return null;
    }

    final value = image.toString().trim();

    return value.isEmpty ? null : value;
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    final name = _artistName();

    return Scaffold(
      backgroundColor: ArtistColors.background,

      // ===========================================================
      // APP BAR
      // ===========================================================
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
          'Artist Profile',
          style: ArtistTextStyles.title.copyWith(fontSize: 19),
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
          const SizedBox(width: 5),
        ],
      ),

      // ===========================================================
      // BODY
      // ===========================================================
      body: SafeArea(
        child: RefreshIndicator(
          color: ArtistColors.primary,
          onRefresh: _refreshProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 5, 18, 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildArtistHeader(),

                const SizedBox(height: 17),

                _buildActionButtons(),

                const SizedBox(height: 21),

                _buildStats(),

                const SizedBox(height: 24),

                _buildAboutSection(),

                const SizedBox(height: 24),

                _buildSkillsSection(),

                const SizedBox(height: 24),

                _buildPortfolioSection(),

                const SizedBox(height: 24),

                _buildProductsSection(),

                const SizedBox(height: 24),

                _buildReviewsSection(),

                const SizedBox(height: 24),

                _buildCertificationSection(),

                const SizedBox(height: 20),

                _buildMemberSection(),

                const SizedBox(height: 10),

                Center(
                  child: Text(
                    'EcoLoop • Give Things a New Life',
                    style: ArtistTextStyles.caption.copyWith(
                      color: ArtistColors.textSecondary.withOpacity(0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // ARTIST HEADER
  // ===============================================================

  Widget _buildArtistHeader() {
    final name = _artistName();
    final location = _location();
    final image = _profileImage();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withOpacity(0.055),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // -------------------------------------------------------
          // PROFILE IMAGE
          // -------------------------------------------------------
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ArtistColors.light,
                  border: Border.all(
                    color: ArtistColors.primary.withOpacity(0.35),
                    width: 2.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: image != null
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return _buildInitialAvatar(name, fontSize: 38);
                        },
                      )
                    : _buildInitialAvatar(name, fontSize: 38),
              ),

              if (_isVerified())
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: ArtistColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: ArtistColors.surface, width: 3),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 13),

          // -------------------------------------------------------
          // NAME
          // -------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.title.copyWith(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (_isVerified()) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified_rounded,
                  size: 19,
                  color: ArtistColors.primary,
                ),
              ],
            ],
          ),

          const SizedBox(height: 5),

          // -------------------------------------------------------
          // REMAKER LABEL
          // -------------------------------------------------------
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
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),

          const SizedBox(height: 9),

          // -------------------------------------------------------
          // RATING
          // -------------------------------------------------------
          GestureDetector(
            onTap: _openReviews,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: ArtistColors.primary,
                  size: 18,
                ),

                const SizedBox(width: 4),

                Text(
                  _rating(),
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(width: 4),

                Text(
                  '(${_reviewCount()} reviews)',
                  style: ArtistTextStyles.caption,
                ),

                const SizedBox(width: 2),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: ArtistColors.textSecondary,
                  size: 17,
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // -------------------------------------------------------
          // LOCATION
          // -------------------------------------------------------
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
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.caption,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // -------------------------------------------------------
          // SPECIALTY
          // -------------------------------------------------------
          Text(
            'Sustainable crafts • Upcycling • Handmade creations',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption.copyWith(
              height: 1.45,
              color: ArtistColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // INITIAL AVATAR
  // ===============================================================

  Widget _buildInitialAvatar(String name, {double fontSize = 30}) {
    final firstLetter = name.isNotEmpty ? name.trim()[0].toUpperCase() : 'A';

    return Center(
      child: Text(
        firstLetter,
        style: TextStyle(
          color: ArtistColors.primary,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ===============================================================
  // ACTION BUTTONS
  // ===============================================================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _toggleFollow,
            icon: Icon(
              _isFollowing
                  ? Icons.check_rounded
                  : Icons.person_add_alt_1_outlined,
              size: 18,
            ),
            label: Text(_isFollowing ? 'Following' : 'Follow'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ArtistColors.primary,
              side: const BorderSide(color: ArtistColors.primary),
              minimumSize: const Size(0, 47),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: ElevatedButton.icon(
            onPressed: _contactArtist,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtistColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 47),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // STATS
  // ===============================================================

  Widget _buildStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ProfileStat(
              icon: Icons.people_outline_rounded,
              value: _formatCount(_followers()),
              label: 'Followers',
            ),
          ),

          _statDivider(),

          Expanded(
            child: _ProfileStat(
              icon: Icons.collections_outlined,
              value: '${_portfolio.length}',
              label: 'Works',
            ),
          ),

          _statDivider(),

          Expanded(
            child: _ProfileStat(
              icon: Icons.shopping_bag_outlined,
              value: '${_sold()}',
              label: 'Sold',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 43, color: ArtistColors.border);
  }

  // ===============================================================
  // ABOUT
  // ===============================================================

  Widget _buildAboutSection() {
    return _ProfileSection(
      title: 'About',
      icon: Icons.person_outline_rounded,
      child: Text(_bio(), style: ArtistTextStyles.body.copyWith(height: 1.55)),
    );
  }

  // ===============================================================
  // SKILLS
  // ===============================================================

  Widget _buildSkillsSection() {
    final rawSkills = widget.artist['skills'];

    List<String> skills = [];

    if (rawSkills is List) {
      skills = rawSkills
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawSkills != null) {
      skills = rawSkills
          .toString()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (skills.isEmpty) {
      skills = const [
        'Upcycling',
        'Furniture',
        'Handmade',
        'Home Decor',
        'Sustainable Design',
      ];
    }

    return _ProfileSection(
      title: 'Skills & Specialties',
      icon: Icons.auto_awesome_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: skills.map(_skillChip).toList(),
      ),
    );
  }

  Widget _skillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        skill,
        style: ArtistTextStyles.caption.copyWith(
          color: ArtistColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  // ===============================================================
  // PORTFOLIO
  // ===============================================================

  Widget _buildPortfolioSection() {
    final featured = _portfolio
        .where((item) => item['featured'] == true)
        .take(2)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portfolio',
                    style: ArtistTextStyles.title.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Before & after transformations',
                    style: ArtistTextStyles.caption,
                  ),
                ],
              ),
            ),

            TextButton(
              onPressed: _openFullPortfolio,
              style: TextButton.styleFrom(
                foregroundColor: ArtistColors.primary,
                padding: EdgeInsets.zero,
              ),
              child: const Text('View All'),
            ),
          ],
        ),

        const SizedBox(height: 11),

        if (featured.isEmpty)
          _buildEmptyPortfolio()
        else
          SizedBox(
            height: 305,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: featured.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                return _buildPortfolioPreviewCard(featured[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPortfolioPreviewCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _openPortfolioItem(item),
      child: Container(
        width: 275,
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ArtistColors.border),
          boxShadow: [
            BoxShadow(
              color: ArtistColors.primary.withOpacity(0.045),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildBeforeAfterPreview(item)),

            Padding(
              padding: const EdgeInsets.fromLTRB(13, 10, 13, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    item['category'].toString(),
                    style: ArtistTextStyles.caption.copyWith(
                      color: ArtistColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_border_rounded,
                        size: 14,
                        color: ArtistColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item['likes']}',
                        style: ArtistTextStyles.caption.copyWith(fontSize: 10),
                      ),
                      const SizedBox(width: 11),
                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: ArtistColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item['views']}',
                        style: ArtistTextStyles.caption.copyWith(fontSize: 10),
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

  // ===============================================================
  // BEFORE / AFTER PREVIEW
  // ===============================================================

  Widget _buildBeforeAfterPreview(Map<String, dynamic> item) {
    final before = item['before']?.toString();
    final after = item['after']?.toString();

    return Row(
      children: [
        Expanded(
          child: _BeforeAfterImage(
            image: before,
            label: 'BEFORE',
            alignment: Alignment.center,
          ),
        ),

        Container(width: 1, color: ArtistColors.surface),

        Expanded(
          child: _BeforeAfterImage(
            image: after,
            label: 'AFTER',
            alignment: Alignment.center,
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // EMPTY PORTFOLIO
  // ===============================================================

  Widget _buildEmptyPortfolio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.collections_outlined,
            color: ArtistColors.primary,
            size: 35,
          ),
          const SizedBox(height: 9),
          Text(
            'No portfolio work yet',
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This artist has not added portfolio work yet.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption,
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // PRODUCTS
  // ===============================================================

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Products',
                    style: ArtistTextStyles.title.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Available creations from this artist',
                    style: ArtistTextStyles.caption,
                  ),
                ],
              ),
            ),

            TextButton(
              onPressed: _openProducts,
              style: TextButton.styleFrom(
                foregroundColor: ArtistColors.primary,
                padding: EdgeInsets.zero,
              ),
              child: const Text('View All'),
            ),
          ],
        ),

        const SizedBox(height: 11),

        SizedBox(
          height: 248,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              return _buildProductCard(_products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => _showProductDetails(product),
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: ArtistColors.border),
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
                      product['image'].toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: ArtistColors.light,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: ArtistColors.primary,
                              size: 30,
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
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        product['condition'].toString(),
                        style: ArtistTextStyles.caption.copyWith(
                          color: ArtistColors.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '₹${product['price']}',
                    style: ArtistTextStyles.title.copyWith(
                      fontSize: 16,
                      color: ArtistColors.primary,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    product['category'].toString(),
                    style: ArtistTextStyles.caption.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // REVIEWS
  // ===============================================================

  Widget _buildReviewsSection() {
    return _ProfileSection(
      title: 'Reviews',
      icon: Icons.star_outline_rounded,
      trailing: TextButton(
        onPressed: _openReviews,
        style: TextButton.styleFrom(
          foregroundColor: ArtistColors.primary,
          padding: EdgeInsets.zero,
        ),
        child: const Text('View All'),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: ArtistColors.primary,
                  size: 31,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _rating(),
                      style: ArtistTextStyles.title.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '${_reviewCount()} reviews from buyers',
                      style: ArtistTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: ArtistColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: ArtistColors.primary,
                  size: 20,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Beautiful craftsmanship and the transformation '
                    'was exactly what I expected.',
                    style: ArtistTextStyles.caption.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // CERTIFICATION
  // ===============================================================

  Widget _buildCertificationSection() {
    return _ProfileSection(
      title: 'Certification',
      icon: Icons.workspace_premium_outlined,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ArtistColors.background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: ArtistColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_outlined,
                color: ArtistColors.primary,
                size: 25,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EcoLoop ReMaker',
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Verified sustainable creator',
                    style: ArtistTextStyles.caption,
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.check_circle_rounded,
              color: ArtistColors.success,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // MEMBER INFO
  // ===============================================================

  Widget _buildMemberSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_outlined, color: ArtistColors.primary, size: 21),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              'Supporting reuse and sustainable creativity on EcoLoop.',
              style: ArtistTextStyles.caption.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // OPEN FULL PORTFOLIO
  // ===============================================================

  void _openFullPortfolio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtistPublicPortfolio(
          artistName: _artistName(),
          portfolio: _portfolio,
        ),
      ),
    );
  }

  // ===============================================================
  // OPEN PORTFOLIO ITEM
  // ===============================================================

  void _openPortfolioItem(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _PortfolioWorkSheet(item: item);
      },
    );
  }

  // ===============================================================
  // PRODUCTS
  // ===============================================================

  void _openProducts() {
    _showMessage('Artist product marketplace will open here.');
  }

  void _showProductDetails(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ProductPreviewSheet(product: product);
      },
    );
  }

  // ===============================================================
  // REVIEWS
  // ===============================================================

  void _openReviews() {
    _showMessage('Artist reviews will open here.');
  }

  // ===============================================================
  // FOLLOW
  // ===============================================================

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });

    _showMessage(
      _isFollowing
          ? 'You are now following ${_artistName()}.'
          : 'You unfollowed ${_artistName()}.',
    );
  }

  // ===============================================================
  // CONTACT
  // ===============================================================

  void _contactArtist() {
    _showMessage('Artist messaging will be connected here.');
  }

  // ===============================================================
  // MORE
  // ===============================================================

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ArtistColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                _MoreOption(
                  icon: Icons.share_outlined,
                  title: 'Share Artist',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage('Artist sharing will be connected here.');
                  },
                ),

                const SizedBox(height: 8),

                _MoreOption(
                  icon: Icons.flag_outlined,
                  title: 'Report Artist',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage('Report artist option selected.');
                  },
                ),

                const SizedBox(height: 8),

                _MoreOption(
                  icon: Icons.block_outlined,
                  title: 'Block Artist',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage('Block artist option selected.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===============================================================
  // REFRESH
  // ===============================================================

  Future<void> _refreshProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    _showMessage('Artist profile refreshed.');
  }

  // ===============================================================
  // SNACKBAR
  // ===============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ===============================================================
  // FORMAT COUNT
  // ===============================================================

  String _formatCount(int value) {
    if (value >= 1000000) {
      final result = (value / 1000000).toStringAsFixed(1);

      return result.endsWith('.0')
          ? '${result.substring(0, result.length - 2)}M'
          : '${result}M';
    }

    if (value >= 1000) {
      final result = (value / 1000).toStringAsFixed(1);

      return result.endsWith('.0')
          ? '${result.substring(0, result.length - 2)}K'
          : '${result}K';
    }

    return value.toString();
  }
}

// ==================================================================
// PROFILE SECTION
// ==================================================================

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 33,
                height: 33,
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
                  style: ArtistTextStyles.title.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (trailing != null) trailing!,
            ],
          ),

          const SizedBox(height: 13),

          child,
        ],
      ),
    );
  }
}

// ==================================================================
// PROFILE STAT
// ==================================================================

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 19, color: ArtistColors.primary),

        const SizedBox(height: 5),

        Text(
          value,
          style: ArtistTextStyles.title.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 2),

        Text(label, style: ArtistTextStyles.caption.copyWith(fontSize: 9)),
      ],
    );
  }
}

// ==================================================================
// BEFORE / AFTER IMAGE
// ==================================================================

class _BeforeAfterImage extends StatelessWidget {
  const _BeforeAfterImage({
    required this.image,
    required this.label,
    required this.alignment,
  });

  final String? image;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (image != null)
          Image.network(
            image!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return _fallback();
            },
          )
        else
          _fallback(),

        Positioned(
          top: 9,
          left: 9,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: label == 'BEFORE'
                  ? Colors.black.withOpacity(0.62)
                  : ArtistColors.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      color: ArtistColors.light,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: ArtistColors.primary,
          size: 27,
        ),
      ),
    );
  }
}

// ==================================================================
// MORE OPTION
// ==================================================================

class _MoreOption extends StatelessWidget {
  const _MoreOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? ArtistColors.error : ArtistColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: destructive
              ? ArtistColors.error.withOpacity(0.045)
              : ArtistColors.background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: destructive
                ? ArtistColors.error.withOpacity(0.18)
                : ArtistColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),

            const SizedBox(width: 10),

            Text(
              title,
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            Icon(Icons.chevron_right_rounded, size: 19, color: color),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// PUBLIC PORTFOLIO PAGE
// ==================================================================
//
// This is READ-ONLY.
// The artist's own Portfolio page handles CRUD.
// ==================================================================

class ArtistPublicPortfolio extends StatelessWidget {
  const ArtistPublicPortfolio({
    super.key,
    required this.artistName,
    required this.portfolio,
  });

  final String artistName;
  final List<Map<String, dynamic>> portfolio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
        ),
        title: Text('Portfolio', style: ArtistTextStyles.title),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 5, 18, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ArtistColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ArtistColors.border),
                ),
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
                        Icons.collections_bookmark_outlined,
                        color: ArtistColors.primary,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$artistName Portfolio',
                            style: ArtistTextStyles.title.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Before & after transformations',
                            style: ArtistTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'Creative Work',
                style: ArtistTextStyles.title.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${portfolio.length} projects',
                style: ArtistTextStyles.caption,
              ),

              const SizedBox(height: 13),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: portfolio.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (_, index) {
                  final item = portfolio[index];

                  return GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _PortfolioWorkSheet(item: item),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: ArtistColors.surface,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: ArtistColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _BeforeAfterImage(
                                    image: item['before']?.toString(),
                                    label: 'BEFORE',
                                    alignment: Alignment.center,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  color: ArtistColors.surface,
                                ),
                                Expanded(
                                  child: _BeforeAfterImage(
                                    image: item['after']?.toString(),
                                    label: 'AFTER',
                                    alignment: Alignment.center,
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
                                  item['title'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ArtistTextStyles.bodyMedium.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  item['category'].toString(),
                                  style: ArtistTextStyles.caption.copyWith(
                                    color: ArtistColors.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// PORTFOLIO WORK SHEET
// ==================================================================

class _PortfolioWorkSheet extends StatelessWidget {
  const _PortfolioWorkSheet({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 700),
      decoration: const BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 270,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: _BeforeAfterImage(
                          image: item['before']?.toString(),
                          label: 'BEFORE',
                          alignment: Alignment.center,
                        ),
                      ),

                      Container(width: 2, color: ArtistColors.surface),

                      Expanded(
                        child: _BeforeAfterImage(
                          image: item['after']?.toString(),
                          label: 'AFTER',
                          alignment: Alignment.center,
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 13,
                  right: 13,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title'].toString(),
                          style: ArtistTextStyles.title.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: ArtistColors.light,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: ArtistColors.primary,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Remade',
                              style: TextStyle(
                                color: ArtistColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    item['category'].toString(),
                    style: ArtistTextStyles.caption.copyWith(
                      color: ArtistColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    item['description'].toString(),
                    style: ArtistTextStyles.body.copyWith(height: 1.55),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: ArtistColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.eco_outlined,
                          color: ArtistColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'This project demonstrates how an existing '
                            'material or object was transformed into '
                            'a useful new creation.',
                            style: ArtistTextStyles.caption.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_border_rounded,
                        size: 17,
                        color: ArtistColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${item['likes']} likes',
                        style: ArtistTextStyles.caption,
                      ),
                      const SizedBox(width: 15),
                      const Icon(
                        Icons.visibility_outlined,
                        size: 17,
                        color: ArtistColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${item['views']} views',
                        style: ArtistTextStyles.caption,
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
}

// ==================================================================
// PRODUCT PREVIEW SHEET
// ==================================================================

class _ProductPreviewSheet extends StatelessWidget {
  const _ProductPreviewSheet({required this.product});

  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 620),
      decoration: const BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  product['image'].toString(),
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 250,
                      color: ArtistColors.light,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: ArtistColors.primary,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),

                Positioned(
                  top: 13,
                  right: 13,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'].toString(),
                    style: ArtistTextStyles.title.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    product['category'].toString(),
                    style: ArtistTextStyles.caption.copyWith(
                      color: ArtistColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '₹${product['price']}',
                    style: ArtistTextStyles.title.copyWith(
                      color: ArtistColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'This product is created by the artist using '
                    'sustainable or reclaimed materials.',
                    style: ArtistTextStyles.body.copyWith(height: 1.5),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArtistColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View Product'),
                    ),
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
