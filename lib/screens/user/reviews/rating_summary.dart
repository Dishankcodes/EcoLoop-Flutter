import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';

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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Column(
              children: [
                Text(
                  safeRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < safeRating.floor()
                          ? Icons.star_rounded
                          : (i < safeRating
                                ? Icons.star_half_rounded
                                : Icons.star_outline_rounded),
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$total ${total == 1 ? 'review' : 'reviews'}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
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
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: distribution == 0
                                  ? 0
                                  : _count(star) / distribution,
                              minHeight: 7,
                              backgroundColor: AppColors.light,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${_count(star)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
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
