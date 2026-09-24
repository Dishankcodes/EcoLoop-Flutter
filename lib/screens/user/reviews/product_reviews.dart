import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import 'write_review.dart';

/// Product Reviews
///
/// UI-only review page for EcoLoop.
///
/// Expected product map keys:
/// - title
/// - image / images
/// - rating
/// - reviewCount
///
/// Review data is currently local demo data. API integration can be added
/// later without changing the page structure.
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
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductCard(),
            const SizedBox(height: 16),
            _buildRatingSummary(),
            const SizedBox(height: 16),
            _buildWriteReviewCard(),
            const SizedBox(height: 20),
            _buildFilterHeader(),
            const SizedBox(height: 12),
            _buildFilterChips(),
            const SizedBox(height: 14),
            _buildReviews(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.textPrimary,
      title: Text(
        'Reviews',
        style: AppTextStyles.title.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.network(
              _image,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 72,
                height: 72,
                color: AppColors.light,
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    _ratingBadge(_rating),
                    const SizedBox(width: 7),
                    Text(
                      '$_reviewCount reviews',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
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

  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Column(
              children: [
                Text(
                  _rating.toStringAsFixed(1),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                _buildStars(_rating, size: 17),
                const SizedBox(height: 5),
                Text(
                  '$_reviewCount ratings',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 17),
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

  Widget _ratingBar(int rating, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rating ★',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 7,
                backgroundColor: AppColors.light,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 31,
            child: Text(
              '${percentage.toInt()}%',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteReviewCard() {
    return InkWell(
      onTap: _openWriteReview,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share your experience',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tell other EcoLoop users what you think.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Customer reviews',
            style: AppTextStyles.title.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() {
              _selectedSort = value;
            });
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'Most Relevant', child: Text('Most Relevant')),
            PopupMenuItem(value: 'Newest', child: Text('Newest')),
            PopupMenuItem(
              value: 'Highest Rating',
              child: Text('Highest Rating'),
            ),
            PopupMenuItem(value: 'Lowest Rating', child: Text('Lowest Rating')),
            PopupMenuItem(value: 'Most Helpful', child: Text('Most Helpful')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.accent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sort_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  _selectedSort,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
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

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
            labelStyle: AppTextStyles.caption.copyWith(
              color: selected ? AppColors.surface : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected
                  ? AppColors.primary
                  : AppColors.accent.withOpacity(0.45),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildReviews() {
    final reviews = _filteredReviews;

    if (reviews.isEmpty) {
      return _buildEmptyReviews();
    }

    return Column(
      children: [
        for (final review in reviews) ...[
          _buildReviewCard(review),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] as int;
    final photos = review['photos'] as List<dynamic>? ?? const [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(review['initials']?.toString() ?? '?'),
              const SizedBox(width: 11),
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
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (review['verified'] == true) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStars(rating.toDouble(), size: 14),
                        const SizedBox(width: 7),
                        Text(
                          review['date']?.toString() ?? '',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 20,
                onSelected: (value) {
                  if (value == 'report') {
                    _showMessage('Report option selected.');
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'report', child: Text('Report review')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            review['comment']?.toString() ?? '',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      photos[index].toString(),
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 76,
                        height: 76,
                        color: AppColors.light,
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              Text(
                'Was this helpful?',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              _helpfulButton(
                icon: Icons.thumb_up_outlined,
                text: '${review['helpful'] ?? 0}',
                onTap: () {
                  _showMessage('Thanks for your feedback.');
                },
              ),
              const SizedBox(width: 7),
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

  Widget _helpfulButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            if (text.isNotEmpty) ...[
              const SizedBox(width: 5),
              Text(
                text,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.light,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'No reviews found',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Try another filter or be the first to share your experience.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.primary, size: 15),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

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
          color: AppColors.primary,
        );
      }),
    );
  }

  Widget _avatar(String initials) {
    return Container(
      width: 43,
      height: 43,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.light, shape: BoxShape.circle),
      child: Text(
        initials,
        style: AppTextStyles.body.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _openWriteReview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WriteReview(product: widget.product)),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
