import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';

/// Reusable rating summary widget.
///
/// Displays:
/// - Overall rating
/// - Total review count
/// - 5-star to 1-star distribution
/// - Percentage bars
/// - Individual rating counts
///
/// UI-only for now.
/// Real rating data will be supplied by the backend later.
class RatingSummary extends StatelessWidget {
  final double rating;
  final int totalReviews;

  /// Number of reviews for each rating.
  ///
  /// Example:
  /// {
  ///   5: 78,
  ///   4: 15,
  ///   3: 4,
  ///   2: 2,
  ///   1: 1,
  /// }
  final Map<int, int>? ratingCounts;

  const RatingSummary({
    super.key,
    required this.rating,
    required this.totalReviews,
    this.ratingCounts,
  });

  // SAFE VALUES

  double get _safeRating {
    if (rating.isNaN || rating.isInfinite) {
      return 0;
    }

    return rating.clamp(0.0, 5.0);
  }

  int get _safeTotalReviews {
    return totalReviews < 0 ? 0 : totalReviews;
  }

  // GET COUNT

  int _getRatingCount(int starRating) {
    final count = ratingCounts?[starRating] ?? 0;

    if (count < 0) {
      return 0;
    }

    return count;
  }

  // TOTAL DISTRIBUTION COUNT

  int get _distributionTotal {
    if (ratingCounts == null) {
      return 0;
    }

    return List.generate(5, (index) {
      final starRating = 5 - index;
      return _getRatingCount(starRating);
    }).fold<int>(0, (sum, count) => sum + count);
  }

  // PERCENTAGE

  double _getPercentage(int starRating) {
    final count = _getRatingCount(starRating);

    // If rating distribution is supplied, use the actual
    // distribution total. This prevents incorrect percentages
    // when the distribution and totalReviews don't match.
    if (_distributionTotal > 0) {
      return (count / _distributionTotal).clamp(0.0, 1.0);
    }

    // If there is no distribution data, keep the bars empty.
    return 0;
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          
          // OVERALL RATING
          
          SizedBox(
            width: 92,
            child: Column(
              children: [
                Text(
                  _safeRating.toStringAsFixed(1),
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                _buildStars(_safeRating, size: 17),

                const SizedBox(height: 6),

                Text(
                  '${_safeTotalReviews} '
                  '${_safeTotalReviews == 1 ? 'review' : 'reviews'}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          
          // RATING DISTRIBUTION
          
          Expanded(
            child: Column(
              children: [
                _buildRatingBar(5),
                _buildRatingBar(4),
                _buildRatingBar(3),
                _buildRatingBar(2),
                _buildRatingBar(1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // RATING BAR

  Widget _buildRatingBar(int starRating) {
    final percentage = _getPercentage(starRating);
    final count = _getRatingCount(starRating);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // STAR NUMBER
          SizedBox(
            width: 15,
            child: Text(
              '$starRating',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 3),

          // STAR ICON
          const Icon(Icons.star_rounded, size: 14, color: AppColors.primary),

          const SizedBox(width: 7),

          // PROGRESS BAR
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 7,
                backgroundColor: AppColors.light,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 7),

          // PERCENTAGE
          SizedBox(
            width: 36,
            child: Text(
              '${(percentage * 100).round()}%',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 5),

          // COUNT
          SizedBox(
            width: 24,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STARS

  Widget _buildStars(double value, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;

        if (value >= starValue) {
          return Icon(Icons.star_rounded, size: size, color: AppColors.primary);
        }

        if (value >= starValue - 0.5) {
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
      }),
    );
  }
}
