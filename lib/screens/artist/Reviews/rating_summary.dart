import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

/// Displays the rating summary calculated from the reviews loaded by the
/// parent review screen. This widget does not invent or fetch review data.
class RatingSummary extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final Map<int, int>? ratingCounts;

  const RatingSummary({
    super.key,
    required this.rating,
    required this.totalReviews,
    this.ratingCounts,
  });

  int _count(int star) => (ratingCounts?[star] ?? 0).clamp(0, 1 << 30).toInt();

  @override
  Widget build(BuildContext context) {
    final safeRating = rating.isFinite ? rating.clamp(0.0, 5.0) : 0.0;
    final total = totalReviews < 0 ? 0 : totalReviews;
    final distribution = [
      5,
      4,
      3,
      2,
      1,
    ].fold<int>(0, (sum, star) => sum + _count(star));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Column(
              children: [
                Text(
                  safeRating.toStringAsFixed(1),
                  style: ArtistTextStyles.heading.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    final icon = safeRating >= star
                        ? Icons.star_rounded
                        : safeRating >= star - 0.5
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded;
                    return Icon(icon, size: 14, color: ArtistColors.warning);
                  }),
                ),
                const SizedBox(height: 5),
                Text(
                  '$total ${total == 1 ? 'review' : 'reviews'}',
                  textAlign: TextAlign.center,
                  style: ArtistTextStyles.small.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (final star in [5, 4, 3, 2, 1])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          child: Text(
                            '$star',
                            style: ArtistTextStyles.small.copyWith(
                              fontSize: 11,
                              color: ArtistColors.textSecondary,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: ArtistColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: distribution == 0
                                  ? 0
                                  : (_count(star) / distribution).clamp(
                                      0.0,
                                      1.0,
                                    ),
                              minHeight: 7,
                              backgroundColor: ArtistColors.surfaceSoft,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                ArtistColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${_count(star)}',
                            textAlign: TextAlign.right,
                            style: ArtistTextStyles.small.copyWith(
                              fontSize: 10,
                              color: ArtistColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
