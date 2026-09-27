import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

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

  // Safe rating.
  double get _safeRating {
    if (rating.isNaN || rating.isInfinite) {
      return 0;
    }

    return rating.clamp(0.0, 5.0);
  }

  // Safe review count.
  int get _safeTotalReviews {
    return totalReviews < 0 ? 0 : totalReviews;
  }

  // Get rating count.
  int _getRatingCount(int starRating) {
    final count = ratingCounts?[starRating] ?? 0;

    if (count < 0) {
      return 0;
    }

    return count;
  }

  // Total distribution count.
  int get _distributionTotal {
    if (ratingCounts == null) {
      return 0;
    }

    return List.generate(5, (index) {
      final starRating = 5 - index;
      return _getRatingCount(starRating);
    }).fold<int>(0, (sum, count) => sum + count);
  }

  // Get percentage.
  double _getPercentage(int starRating) {
    final count = _getRatingCount(starRating);

    if (_distributionTotal > 0) {
      return (count / _distributionTotal).clamp(0.0, 1.0);
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.textPrimary.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Overall rating.
          SizedBox(
            width: 88,
            child: Column(
              children: [
                Text(
                  _safeRating.toStringAsFixed(1),
                  style: ArtistTextStyles.heading.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                _buildStars(_safeRating, size: 17),
                const SizedBox(height: 5),
                Text(
                  '${_safeTotalReviews} '
                  '${_safeTotalReviews == 1 ? 'review' : 'reviews'}',
                  textAlign: TextAlign.center,
                  style: ArtistTextStyles.small.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Rating distribution.
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

  // Rating bar.
  Widget _buildRatingBar(int starRating) {
    final percentage = _getPercentage(starRating);
    final count = _getRatingCount(starRating);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          // Star number.
          SizedBox(
            width: 14,
            child: Text(
              '$starRating',
              style: ArtistTextStyles.small.copyWith(
                fontSize: 11,
                color: ArtistColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 3),

          // Star icon.
          const Icon(Icons.star_rounded, size: 14, color: ArtistColors.warning),

          const SizedBox(width: 6),

          // Progress bar.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 6,
                backgroundColor: ArtistColors.surfaceSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ArtistColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Percentage.
          SizedBox(
            width: 34,
            child: Text(
              '${(percentage * 100).round()}%',
              textAlign: TextAlign.right,
              style: ArtistTextStyles.small.copyWith(
                fontSize: 10,
                color: ArtistColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Count.
          SizedBox(
            width: 22,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: ArtistTextStyles.small.copyWith(
                fontSize: 9,
                color: ArtistColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Stars.
  Widget _buildStars(double value, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;

        if (value >= starValue) {
          return Icon(
            Icons.star_rounded,
            size: size,
            color: ArtistColors.warning,
          );
        }

        if (value >= starValue - 0.5) {
          return Icon(
            Icons.star_half_rounded,
            size: size,
            color: ArtistColors.warning,
          );
        }

        return Icon(
          Icons.star_outline_rounded,
          size: size,
          color: ArtistColors.textMuted,
        );
      }),
    );
  }
}
