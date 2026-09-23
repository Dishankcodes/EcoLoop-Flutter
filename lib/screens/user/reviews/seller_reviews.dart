import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
import 'rating_summary.dart';
import 'write_seller_review.dart';

class SellerReviews extends StatefulWidget {
  final String sellerName;
  final String? sellerImage;
  final String? sellerLocation;
  final double rating;
  final int reviewCount;
  final bool isVerified;

  const SellerReviews({
    super.key,
    required this.sellerName,
    this.sellerImage,
    this.sellerLocation,
    this.rating = 4.8,
    this.reviewCount = 124,
    this.isVerified = true,
  });

  @override
  State<SellerReviews> createState() => _SellerReviewsState();
}

class _SellerReviewsState extends State<SellerReviews> {
  int selectedRating = 0;
  String selectedSort = 'Most Relevant';

  late List<_SellerReview> _reviews;
  late int _reviewCount;
  late double _rating;

  @override
  void initState() {
    super.initState();

    _reviewCount = widget.reviewCount;
    _rating = widget.rating;

    _reviews = [
      _SellerReview(
        name: 'Aarav Shah',
        initials: 'AS',
        rating: 5,
        date: '2 days ago',
        review:
        'Really happy with the experience. The ReMaker was very responsive and the product quality was excellent.',
        verifiedBuyer: true,
        helpfulCount: 18,
      ),
      _SellerReview(
        name: 'Nivya Maniyar',
        initials: 'NM',
        rating: 5,
        date: '1 week ago',
        review:
        'Beautiful work and very good packaging. Everything arrived exactly as shown.',
        verifiedBuyer: true,
        helpfulCount: 12,
      ),
      _SellerReview(
        name: 'Riya Patel',
        initials: 'RP',
        rating: 4,
        date: '2 weeks ago',
        review:
        'Good quality product and quick communication. Would definitely consider buying again.',
        verifiedBuyer: true,
        helpfulCount: 9,
      ),
      _SellerReview(
        name: 'Karan Mehta',
        initials: 'KM',
        rating: 5,
        date: '3 weeks ago',
        review:
        'One of the best ReMakers I have purchased from. Very professional throughout the process.',
        verifiedBuyer: true,
        helpfulCount: 7,
      ),
      _SellerReview(
        name: 'Meera Joshi',
        initials: 'MJ',
        rating: 3,
        date: '1 month ago',
        review:
        'The product was good overall. Delivery took slightly longer than expected.',
        verifiedBuyer: true,
        helpfulCount: 4,
      ),
    ];
  }

  List<_SellerReview> get filteredReviews {
    final result = List<_SellerReview>.from(_reviews);

    if (selectedRating != 0) {
      result.removeWhere((review) => review.rating != selectedRating);
    }

    switch (selectedSort) {
      case 'Highest Rated':
        result.sort((a, b) => b.rating.compareTo(a.rating));
        break;

      case 'Lowest Rated':
        result.sort((a, b) => a.rating.compareTo(b.rating));
        break;

      case 'Most Helpful':
        result.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
        break;

      case 'Most Relevant':
        break;
    }

    return result;
  }

  Map<int, int> get _ratingCounts {
    final counts = <int, int>{
      5: 0,
      4: 0,
      3: 0,
      2: 0,
      1: 0,
    };

    for (final review in _reviews) {
      counts[review.rating] = (counts[review.rating] ?? 0) + 1;
    }

    final demoTotal = _reviewCount - _reviews.length;

    if (demoTotal > 0) {
      counts[5] = (counts[5] ?? 0) + 77;
      counts[4] = (counts[4] ?? 0) + 17;
      counts[3] = (counts[3] ?? 0) + 4;
      counts[2] = (counts[2] ?? 0) + 1;
      counts[1] = (counts[1] ?? 0) + 0;
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          'Seller Reviews',
          style: AppTextStyles.title.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildSellerHeader()),
            SliverToBoxAdapter(child: _buildRatingSummary()),
            SliverToBoxAdapter(child: _buildRatingFilters()),
            SliverToBoxAdapter(child: _buildReviewsHeader()),
            _buildReviewList(),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildWriteReviewButton(),
    );
  }

  Widget _buildSellerHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSellerAvatar(),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.sellerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
                if (widget.sellerLocation != null &&
                    widget.sellerLocation!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.sellerLocation!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 7),
                Row(
                  children: [
                    _buildStars(_rating, size: 16),
                    const SizedBox(width: 7),
                    Text(
                      _rating.toStringAsFixed(1),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '($_reviewCount reviews)',
                      style: AppTextStyles.caption,
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

  Widget _buildSellerAvatar() {
    final hasImage =
        widget.sellerImage != null && widget.sellerImage!.trim().isNotEmpty;

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.light,
        shape: BoxShape.circle,
        image: hasImage
            ? DecorationImage(
          image: NetworkImage(widget.sellerImage!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: hasImage
          ? null
          : const Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: 34,
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RatingSummary(
        rating: _rating,
        totalReviews: _reviewCount,
        ratingCounts: _ratingCounts,
      ),
    );
  }

  Widget _buildRatingFilters() {
    return SizedBox(
      height: 58,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildFilterChip(label: 'All', value: 0),
          const SizedBox(width: 8),
          _buildFilterChip(label: '5 ★', value: 5),
          const SizedBox(width: 8),
          _buildFilterChip(label: '4 ★', value: 4),
          const SizedBox(width: 8),
          _buildFilterChip(label: '3 ★', value: 3),
          const SizedBox(width: 8),
          _buildFilterChip(label: '2 ★', value: 2),
          const SizedBox(width: 8),
          _buildFilterChip(label: '1 ★', value: 1),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int value,
  }) {
    final selected = selectedRating == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRating = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.accent.withOpacity(0.5),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedRating == 0
                  ? 'Customer Reviews'
                  : '$selectedRating-star Reviews',
              style: AppTextStyles.title.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _showSortOptions,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 7,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sort_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    selectedSort,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    final reviews = filteredReviews;

    if (reviews.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return _buildReviewCard(reviews[index]);
        },
        childCount: reviews.length,
      ),
    );
  }

  Widget _buildReviewCard(_SellerReview review) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewAvatar(review),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (review.verifiedBuyer) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.light,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'Verified',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStars(
                          review.rating.toDouble(),
                          size: 14,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          review.date,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => _showReportSheet(review),
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  size: 21,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            review.review,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                review.isHelpful = !review.isHelpful;

                if (review.isHelpful) {
                  review.helpfulCount++;
                } else if (review.helpfulCount > 0) {
                  review.helpfulCount--;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: review.isHelpful
                    ? AppColors.light
                    : AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    review.isHelpful
                        ? Icons.thumb_up_rounded
                        : Icons.thumb_up_outlined,
                    size: 15,
                    color: review.isHelpful
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Helpful ${review.helpfulCount}',
                    style: AppTextStyles.caption.copyWith(
                      color: review.isHelpful
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewAvatar(_SellerReview review) {
    final hasImage =
        review.image != null && review.image!.trim().isNotEmpty;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.light,
        image: hasImage
            ? DecorationImage(
          image: NetworkImage(review.image!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: hasImage
          ? null
          : Center(
        child: Text(
          review.initials,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildStars(
      double rating, {
        double size = 16,
      }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
            (index) {
          final starValue = index + 1;

          if (rating >= starValue) {
            return Icon(
              Icons.star_rounded,
              size: size,
              color: AppColors.primary,
            );
          }

          if (rating >= starValue - 0.5) {
            return Icon(
              Icons.star_half_rounded,
              size: size,
              color: AppColors.primary,
            );
          }

          return Icon(
            Icons.star_outline_rounded,
            size: size,
            color: AppColors.textSecondary,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: AppColors.light,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              color: AppColors.primary,
              size: 31,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No reviews found',
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'There are no reviews matching this rating filter.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () {
              setState(() {
                selectedRating = 0;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(
                color: AppColors.primary,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Clear Filter',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteReviewButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(
              color: AppColors.accent.withOpacity(0.4),
            ),
          ),
        ),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openWriteReview,
            icon: const Icon(
              Icons.rate_review_outlined,
              size: 19,
            ),
            label: Text(
              'Write a Review',
              style: AppTextStyles.button,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openWriteReview() async {
    final result = await Navigator.push<SellerReviewResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WriteSellerReview(
          sellerName: widget.sellerName,
          sellerImage: widget.sellerImage,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _reviews.insert(
        0,
        _SellerReview(
          name: result.reviewerName,
          initials: result.initials,
          rating: result.rating,
          date: 'Just now',
          review: result.review,
          verifiedBuyer: true,
          helpfulCount: 0,
        ),
      );

      _reviewCount++;

      final totalRating =
          (_rating * (widget.reviewCount)) + result.rating;

      _rating = totalRating / _reviewCount;

      selectedRating = 0;
      selectedSort = 'Most Relevant';
    });

    _showMessage('Your seller review has been submitted.');
  }

  void _showSortOptions() {
    const options = [
      'Most Relevant',
      'Highest Rated',
      'Lowest Rated',
      'Most Helpful',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort Reviews',
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ...options.map(
                      (option) {
                    final selected = selectedSort == option;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        setState(() {
                          selectedSort = option;
                        });

                        Navigator.pop(context);
                      },
                      title: Text(
                        option,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.primary,
                      )
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportSheet(_SellerReview review) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 24),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.flag_outlined,
                color: AppColors.textPrimary,
              ),
              title: Text(
                'Report review',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showReportConfirmation();
              },
            ),
          ),
        );
      },
    );
  }

  void _showReportConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Report review?',
            style: AppTextStyles.title.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'This review will be submitted for moderation.',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showMessage('Review reported successfully.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SellerReview {
  final String name;
  final String initials;
  final int rating;
  final String date;
  final String review;
  final bool verifiedBuyer;
  final String? image;

  int helpfulCount;
  bool isHelpful;

  _SellerReview({
    required this.name,
    required this.initials,
    required this.rating,
    required this.date,
    required this.review,
    required this.verifiedBuyer,
    required this.helpfulCount,
    this.image,
    this.isHelpful = false,
  });
}