import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: ArtistReviewSummaryPage(),
));

class ArtistReviewSummaryPage extends StatelessWidget {
  const ArtistReviewSummaryPage({super.key});

  // ------------------------------------------------------------
  // ARTIST THEME
  // ------------------------------------------------------------

  static const Color primary = Color(0xFFA6533C);
  static const Color primaryDark = Color(0xFF7D3F2F);
  static const Color background = Color(0xFFF9F5F2);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF2D2522);
  static const Color secondaryText = Color(0xFF8A7D77);
  static const Color borderColor = Color(0xFFE8DDD8);
  static const Color starColor = Color(0xFFE5A33D);

  final double overallRating = 4.6;
  final int totalReviews = 128;

  final Map<int, int> ratingCounts = const {
    5: 92,
    4: 24,
    3: 8,
    2: 3,
    1: 1,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ------------------------------------------------------------
      // APP BAR
      // ------------------------------------------------------------

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Review Summary',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),

      // ------------------------------------------------------------
      // BODY
      // ------------------------------------------------------------

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ------------------------------------------------------
              // HEADER
              // ------------------------------------------------------

              const Text(
                'What users say about you',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'See your overall rating and feedback from customers.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: secondaryText,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------------
              // OVERALL RATING CARD
              // ------------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [

                    // Rating
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          const Text(
                            'Overall Rating',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            overallRating.toString(),
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                                  (index) {
                                return Icon(
                                  index < 4
                                      ? Icons.star_rounded
                                      : Icons.star_half_rounded,
                                  size: 20,
                                  color: starColor,
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 7),

                          Text(
                            '$totalReviews reviews',
                            style: const TextStyle(
                              fontSize: 11,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 125,
                      width: 1,
                      color: borderColor,
                    ),

                    const SizedBox(width: 18),

                    // Rating summary
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          _ratingRow(5),
                          const SizedBox(height: 7),
                          _ratingRow(4),
                          const SizedBox(height: 7),
                          _ratingRow(3),
                          const SizedBox(height: 7),
                          _ratingRow(2),
                          const SizedBox(height: 7),
                          _ratingRow(1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ------------------------------------------------------
              // REVIEW SUMMARY TITLE
              // ------------------------------------------------------

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Customer Reviews',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalReviews',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------------
              // REVIEW 1
              // ------------------------------------------------------

              _reviewCard(
                name: 'Priya Shah',
                date: '18 Sep 2026',
                rating: 5,
                review:
                'Beautiful product and excellent quality. The finishing was really good and the product looked exactly like the photos.',
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------------
              // REVIEW 2
              // ------------------------------------------------------

              _reviewCard(
                name: 'Rahul Patel',
                date: '12 Sep 2026',
                rating: 5,
                review:
                'I really liked the craftsmanship. Packaging was also neat and the product arrived safely.',
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------------
              // REVIEW 3
              // ------------------------------------------------------

              _reviewCard(
                name: 'Meera Joshi',
                date: '05 Sep 2026',
                rating: 4,
                review:
                'Good quality and nice design. The product is worth the price. Delivery was also smooth.',
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------------
              // REVIEW 4
              // ------------------------------------------------------

              _reviewCard(
                name: 'Karan Mehta',
                date: '29 Aug 2026',
                rating: 4,
                review:
                'Overall a good experience. I liked the handmade look and attention to detail.',
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------------
              // REVIEW 5
              // ------------------------------------------------------

              _reviewCard(
                name: 'Anjali Desai',
                date: '21 Aug 2026',
                rating: 5,
                review:
                'Amazing work! The product feels unique and premium. Would definitely recommend this artist.',
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------------
              // VIEW ALL REVIEWS
              // ------------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: const Text('All reviews clicked'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(
                      color: primary,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'View All Reviews',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // RATING ROW
  // ------------------------------------------------------------

  Widget _ratingRow(int rating) {
    final count = ratingCounts[rating] ?? 0;
    final percentage = count / totalReviews;

    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            '$rating',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),

        const SizedBox(width: 3),

        const Icon(
          Icons.star_rounded,
          size: 13,
          color: starColor,
        ),

        const SizedBox(width: 6),

        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: const Color(0xFFEDE5E1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                primary,
              ),
            ),
          ),
        ),

        const SizedBox(width: 7),

        SizedBox(
          width: 23,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 9,
              color: secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // REVIEW CARD
  // ------------------------------------------------------------

  Widget _reviewCard({
    required String name,
    required String date,
    required int rating,
    required String review,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // User information
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primary.withValues(alpha: 0.12),
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 10,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                children: List.generate(
                  5,
                      (index) => Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 16,
                    color: starColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // Review text
          Text(
            review,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: Color(0xFF5F5551),
            ),
          ),
        ],
      ),
    );
  }
}