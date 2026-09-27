import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import 'write_review.dart';

class ProductReviews extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductReviews({super.key, required this.product});

  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  String _selectedFilter = 'All';
  String _selectedSort = 'Most Relevant';

  final List<String> _filters = const [
    'All',
    '5 Star',
    '4 Star',
    '3 Star',
    '2 Star',
    '1 Star',
    'With Photos',
  ];

  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Priya Shah',
      'initials': 'PS',
      'rating': 5,
      'date': '2 weeks ago',
      'verified': true,
      'comment':
          'Really happy with the product. The condition was exactly as described and the seller packed everything carefully.',
      'helpful': 18,
      'photos': [
        'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=500&q=80',
      ],
    },
    {
      'name': 'Rahul Mehta',
      'initials': 'RM',
      'rating': 4,
      'date': '1 month ago',
      'verified': true,
      'comment':
          'Good quality and a smooth buying experience. Delivery was also handled nicely.',
      'helpful': 11,
      'photos': <String>[],
    },
    {
      'name': 'Aarav Patel',
      'initials': 'AP',
      'rating': 5,
      'date': '1 month ago',
      'verified': true,
      'comment':
          'Loved giving this item a second life. It looks great and feels much better than buying something new.',
      'helpful': 9,
      'photos': <String>[],
    },
    {
      'name': 'Meera Joshi',
      'initials': 'MJ',
      'rating': 4,
      'date': '2 months ago',
      'verified': false,
      'comment':
          'Nice product overall. A few small marks were visible, but the listing had mentioned the used condition.',
      'helpful': 6,
      'photos': <String>[],
    },
    {
      'name': 'Dev Trivedi',
      'initials': 'DT',
      'rating': 5,
      'date': '2 months ago',
      'verified': true,
      'comment':
          'Excellent experience from start to finish. Would definitely consider buying from this seller again.',
      'helpful': 14,
      'photos': [
        'https://images.unsplash.com/photo-1541558869434-2840d308329a?auto=format&fit=crop&w=500&q=80',
      ],
    },
    {
      'name': 'Neha Patel',
      'initials': 'NP',
      'rating': 3,
      'date': '3 months ago',
      'verified': true,
      'comment':
          'The product was okay for the price. Communication with the seller was good.',
      'helpful': 3,
      'photos': <String>[],
    },
  ];

  String get _title =>
      widget.product['title']?.toString() ?? 'Wooden Study Table';

  String get _image {
    final images = widget.product['images'];

    if (images is List && images.isNotEmpty) {
      return images.first.toString();
    }

    final image = widget.product['image']?.toString();

    if (image != null && image.isNotEmpty) {
      return image;
    }

    return 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6b0?auto=format&fit=crop&w=700&q=80';
  }

  double get _rating {
    final value = widget.product['rating'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 4.8;
  }

  int get _reviewCount {
    final value = widget.product['reviewCount'] ?? widget.product['reviews'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 42;
  }

  List<Map<String, dynamic>> get _filteredReviews {
    var result = List<Map<String, dynamic>>.from(_reviews);

    switch (_selectedFilter) {
      case '5 Star':
        result = result.where((review) => review['rating'] == 5).toList();
        break;

      case '4 Star':
        result = result.where((review) => review['rating'] == 4).toList();
        break;

      case '3 Star':
        result = result.where((review) => review['rating'] == 3).toList();
        break;

      case '2 Star':
        result = result.where((review) => review['rating'] == 2).toList();
        break;

      case '1 Star':
        result = result.where((review) => review['rating'] == 1).toList();
        break;

      case 'With Photos':
        result = result
            .where(
              (review) =>
                  (review['photos'] as List<dynamic>? ?? const []).isNotEmpty,
            )
            .toList();
        break;
    }

    if (_selectedSort == 'Newest') {
      result = List<Map<String, dynamic>>.from(result.reversed);
    } else if (_selectedSort == 'Highest Rating') {
      result.sort((a, b) => (b['rating'] as int).compareTo(a['rating'] as int));
    } else if (_selectedSort == 'Lowest Rating') {
      result.sort((a, b) => (a['rating'] as int).compareTo(b['rating'] as int));
    } else if (_selectedSort == 'Most Helpful') {
      result.sort(
        (a, b) => (b['helpful'] as int).compareTo(a['helpful'] as int),
      );
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductCard(),
            const SizedBox(height: 14),
            _buildRatingSummary(),
            const SizedBox(height: 14),
            _buildWriteReviewCard(),
            const SizedBox(height: 18),
            _buildFilterHeader(),
            const SizedBox(height: 10),
            _buildFilterChips(),
            const SizedBox(height: 12),
            _buildReviews(),
          ],
        ),
      ),
    );
  }

  // App bar.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ArtistColors.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: ArtistColors.textPrimary,
        ),
        tooltip: 'Back',
      ),
      title: Text(
        'Reviews',
        style: ArtistTextStyles.title.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Product card.
  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _image,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: ArtistColors.surfaceSoft,
                child: const Icon(
                  Icons.image_outlined,
                  color: ArtistColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _ratingBadge(_rating),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        '$_reviewCount reviews',
                        overflow: TextOverflow.ellipsis,
                        style: ArtistTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rating summary.
  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 82,
            child: Column(
              children: [
                Text(
                  _rating.toStringAsFixed(1),
                  style: ArtistTextStyles.heading.copyWith(fontSize: 32),
                ),
                const SizedBox(height: 2),
                _buildStars(_rating, size: 16),
                const SizedBox(height: 4),
                Text(
                  '$_reviewCount ratings',
                  textAlign: TextAlign.center,
                  style: ArtistTextStyles.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              children: [
                _ratingBar(5, 82),
                _ratingBar(4, 12),
                _ratingBar(3, 4),
                _ratingBar(2, 1),
                _ratingBar(1, 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rating bar.
  Widget _ratingBar(int rating, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rating ★',
              style: ArtistTextStyles.small.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: percentage / 100,
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
            width: 30,
            child: Text(
              '${percentage.toInt()}%',
              textAlign: TextAlign.right,
              style: ArtistTextStyles.small,
            ),
          ),
        ],
      ),
    );
  }

  // Write review card.
  Widget _buildWriteReviewCard() {
    return InkWell(
      onTap: _openWriteReview,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ArtistColors.surfaceSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: ArtistColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                color: ArtistColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share your experience',
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tell other EcoLoop users what you think.',
                    style: ArtistTextStyles.small,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: ArtistColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  // Filter header.
  Widget _buildFilterHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Customer reviews',
            style: ArtistTextStyles.title.copyWith(fontSize: 17),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() {
              _selectedSort = value;
            });
          },
          color: ArtistColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          itemBuilder: (_) => [
            _sortMenuItem('Most Relevant'),
            _sortMenuItem('Newest'),
            _sortMenuItem('Highest Rating'),
            _sortMenuItem('Lowest Rating'),
            _sortMenuItem('Most Helpful'),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ArtistColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sort_rounded,
                  size: 17,
                  color: ArtistColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  _selectedSort,
                  style: ArtistTextStyles.small.copyWith(
                    color: ArtistColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Sort menu item.
  PopupMenuItem<String> _sortMenuItem(String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        value,
        style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 13),
      ),
    );
  }

  // Filter chips.
  Widget _buildFilterChips() {
    return SizedBox(
      height: 37,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, index) {
          final filter = _filters[index];
          final selected = filter == _selectedFilter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            labelStyle: ArtistTextStyles.small.copyWith(
              color: selected ? Colors.white : ArtistColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: ArtistColors.primary,
            backgroundColor: ArtistColors.surface,
            side: BorderSide(
              color: selected ? ArtistColors.primary : ArtistColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }

  // Reviews list.
  Widget _buildReviews() {
    final reviews = _filteredReviews;

    if (reviews.isEmpty) {
      return _buildEmptyReviews();
    }

    return Column(
      children: [
        for (final review in reviews) ...[
          _buildReviewCard(review),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  // Review card.
  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] as int;
    final photos = review['photos'] as List<dynamic>? ?? const [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer information.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(review['initials']?.toString() ?? '?'),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review['name']?.toString() ?? 'EcoLoop User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ArtistTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (review['verified'] == true) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: ArtistColors.success,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _buildStars(rating.toDouble(), size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            review['date']?.toString() ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: ArtistTextStyles.small,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 19,
                color: ArtistColors.surface,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'report') {
                    _showMessage('Report option selected.');
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Text(
                      'Report review',
                      style: ArtistTextStyles.bodyMedium.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 11),

          // Review text.
          Text(
            review['comment']?.toString() ?? '',
            style: ArtistTextStyles.body.copyWith(fontSize: 13, height: 1.45),
          ),

          // Review photos.
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 11),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      photos[index].toString(),
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 74,
                        height: 74,
                        color: ArtistColors.surfaceSoft,
                        child: const Icon(
                          Icons.image_outlined,
                          color: ArtistColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 11),

          // Helpful actions.
          Row(
            children: [
              Text('Was this helpful?', style: ArtistTextStyles.small),
              const SizedBox(width: 7),
              _helpfulButton(
                icon: Icons.thumb_up_outlined,
                text: '${review['helpful'] ?? 0}',
                onTap: () {
                  _showMessage('Thanks for your feedback.');
                },
              ),
              const SizedBox(width: 6),
              _helpfulButton(
                icon: Icons.thumb_down_outlined,
                text: '',
                onTap: () {
                  _showMessage('Thanks for your feedback.');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helpful button.
  Widget _helpfulButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: ArtistColors.background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: ArtistColors.primary),
            if (text.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                text,
                style: ArtistTextStyles.small.copyWith(
                  color: ArtistColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Empty state.
  Widget _buildEmptyReviews() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: ArtistColors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              color: ArtistColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'No reviews found',
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try another filter or be the first to share your experience.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.small.copyWith(fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  // Rating badge.
  Widget _ratingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: ArtistColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: ArtistColors.warning, size: 15),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: ArtistTextStyles.small.copyWith(
              color: ArtistColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // Stars.
  Widget _buildStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final value = index + 1;

        return Icon(
          rating >= value
              ? Icons.star_rounded
              : rating >= value - 0.5
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          size: size,
          color: ArtistColors.warning,
        );
      }),
    );
  }

  // Reviewer avatar.
  Widget _avatar(String initials) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: ArtistColors.surfaceSoft,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: ArtistTextStyles.bodyMedium.copyWith(
          color: ArtistColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // Open write review.
  void _openWriteReview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WriteReview(product: widget.product)),
    );
  }

  // Show message.
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: ArtistTextStyles.body.copyWith(
              color: Colors.white,
              fontSize: 12.5,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.accent,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      );
  }
}
