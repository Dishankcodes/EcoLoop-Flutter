import 'package:flutter/material.dart';

void main() => runApp(
  const MaterialApp(debugShowCheckedModeBanner: false, home: AboutYou()),
);

class AboutYou extends StatefulWidget {
  const AboutYou({super.key});

  @override
  State<AboutYou> createState() => _AboutYouState();
}

class _AboutYouState extends State<AboutYou> {
  // ARTIST THEME

  final Color primary = const Color(0xFFAD563E);
  final Color background = const Color(0xFFF7F0E7);
  final Color cardColor = const Color(0xFFFFFCF8);
  final Color borderColor = const Color(0xFFE2D5C8);
  final Color textColor = const Color(0xFF292522);
  final Color mutedColor = const Color(0xFF8B817A);

  // SAMPLE REVIEWS

  final List<Map<String, dynamic>> reviews = [
    {
      'name': 'Priya Shah',
      'date': '12 Sep 2026',
      'rating': 5,
      'review':
          'Beautiful handmade work. The finishing and attention to detail were excellent.',
    },
    {
      'name': 'Rahul Patel',
      'date': '05 Sep 2026',
      'rating': 5,
      'review':
          'Really happy with my purchase. The product looks exactly like the pictures.',
    },
    {
      'name': 'Meera Joshi',
      'date': '28 Aug 2026',
      'rating': 4,
      'review':
          'Very creative and unique work. Delivery was smooth and the quality was good.',
    },
    {
      'name': 'Aarav Mehta',
      'date': '19 Aug 2026',
      'rating': 4,
      'review':
          'Good craftsmanship and a beautiful design. Would definitely explore more products.',
    },
    {
      'name': 'Kavya Patel',
      'date': '11 Aug 2026',
      'rating': 5,
      'review':
          'One of the most beautiful handmade products I have purchased. Highly recommended.',
    },
  ];

  // TOAST

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // APP BAR
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 25),
          onPressed: () => _toast('Back clicked'),
        ),

        title: Text(
          'About You',
          style: TextStyle(
            color: textColor,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'About You Help',
            icon: Icon(Icons.info_outline_rounded, color: textColor, size: 23),
            onPressed: _showAboutHelp,
          ),
        ],
      ),

      // BODY
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // INTRO
                    Text(
                      'What People Say About You',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'See what customers think about your work, products and overall experience.',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ARTIST PROFILE CARD
                    _artistProfileCard(),

                    const SizedBox(height: 20),

                    // RATING SUMMARY
                    _ratingSummary(),

                    const SizedBox(height: 22),

                    // REVIEWS TITLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customer Reviews',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0DED4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${reviews.length} Reviews',
                            style: TextStyle(
                              color: primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 13),

                    // REVIEW LIST
                    ...reviews.map((review) => _reviewCard(review)),

                    const SizedBox(height: 10),

                    // BOTTOM INFORMATION
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0DED4),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            color: primary,
                            size: 21,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              'Your customer reviews help visitors understand your work and build trust in your artist profile.',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 11,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM NAVIGATION
            _bottomNavigation(),
          ],
        ),
      ),
    );
  }

  // ARTIST PROFILE CARD

  Widget _artistProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF0DED4),
              border: Border.all(
                color: primary.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Icon(Icons.person_rounded, color: primary, size: 38),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Artist Profile',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Handmade Artist',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.star_rounded, color: primary, size: 17),

                    const SizedBox(width: 4),

                    Text(
                      '4.8',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      'from 5 reviews',
                      style: TextStyle(color: mutedColor, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () => _toast('Edit About You'),
            icon: Icon(Icons.edit_outlined, color: mutedColor, size: 20),
          ),
        ],
      ),
    );
  }

  // RATING SUMMARY

  Widget _ratingSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Overall rating
          SizedBox(
            width: 92,
            child: Column(
              children: [
                Text(
                  '4.8',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) =>
                        Icon(Icons.star_rounded, color: primary, size: 16),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Overall Rating',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              children: [
                _ratingBar(5, 4),
                _ratingBar(4, 1),
                _ratingBar(3, 0),
                _ratingBar(2, 0),
                _ratingBar(1, 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // RATING BAR

  Widget _ratingBar(int rating, int count) {
    final double progress = reviews.isEmpty ? 0 : count / reviews.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$rating',
              style: TextStyle(
                color: mutedColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Icon(Icons.star_rounded, color: primary, size: 12),

          const SizedBox(width: 6),

          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFEDE5DC),
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            ),
          ),

          const SizedBox(width: 7),

          SizedBox(
            width: 15,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(color: mutedColor, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  // REVIEW CARD

  Widget _reviewCard(Map<String, dynamic> review) {
    final int rating = review['rating'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer header
          Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF0DED4),
                ),
                child: Center(
                  child: Text(
                    review['name'].toString().substring(0, 1),
                    style: TextStyle(
                      color: primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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
                      review['name'],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      review['date'],
                      style: TextStyle(color: mutedColor, fontSize: 9.5),
                    ),
                  ],
                ),
              ),

              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0DED4),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: primary, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '$rating.0',
                      style: TextStyle(
                        color: primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // Stars
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: primary,
                size: 17,
              ),
            ),
          ),

          const SizedBox(height: 9),

          // Review text
          Text(
            review['review'],
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // Helpful
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, color: mutedColor, size: 15),

              const SizedBox(width: 5),

              Text(
                'Helpful review',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              InkWell(
                onTap: () => _toast('Review options'),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: mutedColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ABOUT HELP

  void _showAboutHelp() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0DED4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: primary,
                        size: 25,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'About You',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: mutedColor),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  'Customer Reviews',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'This section shows reviews and ratings given by customers who have interacted with your products or services.',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'You can use these reviews to understand customer feedback and improve your artist profile and products.',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Got It',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // BOTTOM NAVIGATION

  Widget _bottomNavigation() {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_outlined, 'Dashboard'),

          _navItem(Icons.search_outlined, 'Materials'),

          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _toast('Add New Item'),
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          _navItem(Icons.receipt_long_outlined, 'Orders'),

          _navItem(Icons.person_outline_rounded, 'Profile'),
        ],
      ),
    );
  }

  // NAV ITEM

  Widget _navItem(IconData icon, String label) {
    return InkWell(
      onTap: () => _toast('$label clicked'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: mutedColor, size: 22),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                color: mutedColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
