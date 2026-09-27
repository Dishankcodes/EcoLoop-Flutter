import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ArtistReviews extends StatefulWidget {
  const ArtistReviews({super.key});

  @override
  State<ArtistReviews> createState() => _ArtistReviewsState();
}

class _ArtistReviewsState extends State<ArtistReviews> {
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
      'Really happy with the product. The quality was excellent and everything was packed carefully.',
      'helpful': 18,
      'photos': [
        'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=500&q=80',
      ],
      'product': 'Handcrafted Wooden Shelf',
    },
    {
      'name': 'Rahul Kumar',
      'initials': 'RK',
      'rating': 4,
      'date': '1 month ago',
      'verified': true,
      'comment':
      'Good quality and a smooth buying experience. The product looks exactly like the pictures.',
      'helpful': 11,
      'photos': <String>[],
      'product': 'Recycled Wood Table',
    },
    {
      'name': 'Aarav Patel',
      'initials': 'AP',
      'rating': 5,
      'date': '1 month ago',
      'verified': true,
      'comment':
      'Loved giving this item a second life. Beautiful work and very good finishing.',
      'helpful': 9,
      'photos': <String>[],
      'product': 'Upcycled Wall Decor',
    },
    {
      'name': 'Meera Joshi',
      'initials': 'MJ',
      'rating': 4,
      'date': '2 months ago',
      'verified': false,
      'comment':
      'Nice product overall. A few small marks were visible, but the used condition was mentioned.',
      'helpful': 6,
      'photos': <String>[],
      'product': 'Vintage Wooden Chair',
    },
    {
      'name': 'Dev Kumar',
      'initials': 'DK',
      'rating': 5,
      'date': '2 months ago',
      'verified': true,
      'comment':
      'Excellent experience from start to finish. Would definitely purchase from this artist again.',
      'helpful': 14,
      'photos': [
        'https://images.unsplash.com/photo-1541558869434-2840d308329a?auto=format&fit=crop&w=500&q=80',
      ],
      'product': 'Handmade Decor Set',
    },
    {
      'name': 'Neha Patel',
      'initials': 'NP',
      'rating': 3,
      'date': '3 months ago',
      'verified': true,
      'comment':
      'The product was okay for the price. Communication with the artist was good.',
      'helpful': 4,
      'photos': <String>[],
      'product': 'Recycled Home Decor',
    },
  ];

  List<Map<String, dynamic>> get _filteredReviews {
    List<Map<String, dynamic>> result =
    List<Map<String, dynamic>>.from(_reviews);

    switch (_selectedFilter) {
      case '5 Star':
        result = result.where((r) => r['rating'] == 5).toList();
        break;
      case '4 Star':
        result = result.where((r) => r['rating'] == 4).toList();
        break;
      case '3 Star':
        result = result.where((r) => r['rating'] == 3).toList();
        break;
      case '2 Star':
        result = result.where((r) => r['rating'] == 2).toList();
        break;
      case '1 Star':
        result = result.where((r) => r['rating'] == 1).toList();
        break;
      case 'With Photos':
        result = result
            .where(
              (r) => (r['photos'] as List<dynamic>).isNotEmpty,
        )
            .toList();
        break;
    }

    if (_selectedSort == 'Newest') {
      result = List<Map<String, dynamic>>.from(result.reversed);
    } else if (_selectedSort == 'Highest Rating') {
      result.sort(
            (a, b) => (b['rating'] as int).compareTo(a['rating'] as int),
      );
    } else if (_selectedSort == 'Lowest Rating') {
      result.sort(
            (a, b) => (a['rating'] as int).compareTo(b['rating'] as int),
      );
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
      appBar: AppBar(
        backgroundColor: ArtistColors.surface,
        elevation: 0,
        foregroundColor: ArtistColors.textPrimary,
        title: Text(
          'Customer Reviews',
          style: ArtistTextStyles.heading.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildArtistHeader(),
            const SizedBox(height: 18),
            _buildRatingSummary(),
            const SizedBox(height: 20),
            _buildFilterHeader(),
            const SizedBox(height: 12),
            _buildFilters(),
            const SizedBox(height: 18),
            _buildReviews(),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ArtistColors.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ArtistColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              color: ArtistColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Customer Feedback',
                  style: ArtistTextStyles.heading.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'See what customers think about your work.',
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textMuted,
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

  Widget _buildRatingSummary() {
    const counts = {
      5: 3,
      4: 2,
      3: 1,
      2: 0,
      1: 0,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ArtistColors.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Column(
              children: [
                Text(
                  '4.5',
                  style: ArtistTextStyles.heading.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                _stars(4.5, size: 17),
                const SizedBox(height: 7),
                Text(
                  '6 reviews',
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = counts[star] ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: ArtistTextStyles.body.copyWith(
                          fontSize: 11,
                          color: ArtistColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: ArtistColors.primary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: count / 3,
                            minHeight: 6,
                            backgroundColor:
                            ArtistColors.primary.withValues(alpha: 0.10),
                            valueColor:
                            const AlwaysStoppedAnimation<Color>(
                              ArtistColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      SizedBox(
                        width: 18,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: ArtistTextStyles.body.copyWith(
                            fontSize: 11,
                            color: ArtistColors.textMuted,
                          ),
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

  Widget _buildFilterHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Reviews',
          style: ArtistTextStyles.heading.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() => _selectedSort = value);
          },
          color: ArtistColors.surface,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'Most Relevant',
              child: Text('Most Relevant'),
            ),
            PopupMenuItem(
              value: 'Newest',
              child: Text('Newest'),
            ),
            PopupMenuItem(
              value: 'Highest Rating',
              child: Text('Highest Rating'),
            ),
            PopupMenuItem(
              value: 'Lowest Rating',
              child: Text('Lowest Rating'),
            ),
            PopupMenuItem(
              value: 'Most Helpful',
              child: Text('Most Helpful'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: ArtistColors.primary.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sort_rounded,
                  size: 16,
                  color: ArtistColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Sort',
                  style: ArtistTextStyles.body.copyWith(
                    fontSize: 11,
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

  Widget _buildFilters() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final filter = _filters[index];
          final selected = filter == _selectedFilter;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilter = filter);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? ArtistColors.primary
                    : ArtistColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? ArtistColors.primary
                      : ArtistColors.primary.withValues(alpha: 0.20),
                ),
              ),
              child: Text(
                filter,
                style: ArtistTextStyles.body.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : ArtistColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviews() {
    final reviews = _filteredReviews;

    if (reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(35),
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.rate_review_outlined,
              size: 45,
              color: ArtistColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No reviews found',
              style: ArtistTextStyles.heading.copyWith(
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Try another filter.',
              style: ArtistTextStyles.body.copyWith(
                color: ArtistColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: reviews.map(_reviewCard).toList(),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final photos = review['photos'] as List<dynamic>;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ArtistColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ArtistColors.primary.withValues(alpha: 0.13),
                child: Text(
                  review['initials'],
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          review['name'],
                          style: ArtistTextStyles.body.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (review['verified'] == true) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: ArtistColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _stars(
                          (review['rating'] as int).toDouble(),
                          size: 14,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          review['date'],
                          style: ArtistTextStyles.body.copyWith(
                            fontSize: 10,
                            color: ArtistColors.textMuted,
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: ArtistColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              review['product'],
              style: ArtistTextStyles.body.copyWith(
                fontSize: 10,
                color: ArtistColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            review['comment'],
            style: ArtistTextStyles.body.copyWith(
              fontSize: 12,
              height: 1.45,
            ),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 65,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      photos[index],
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.thumb_up_alt_outlined,
                size: 14,
                color: ArtistColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                '${review['helpful']} people found this helpful',
                style: ArtistTextStyles.body.copyWith(
                  fontSize: 10,
                  color: ArtistColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
          color: ArtistColors.primary,
          size: size,
        );
      }),
    );
  }
}
