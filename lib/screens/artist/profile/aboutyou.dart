import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class AboutYou extends StatefulWidget {
  const AboutYou({super.key});

  @override
  State<AboutYou> createState() => _AboutYouState();
}

class _AboutYouState extends State<AboutYou> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
            size: 23,
          ),
        ),
        title: Text(
          'About You',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Help',
            onPressed: _showAboutHelp,
            icon: const Icon(
              Icons.info_outline_rounded,
              color: ArtistColors.textPrimary,
              size: 21,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What People Say About You',
                style: ArtistTextStyles.heading.copyWith(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'See what customers think about your work, products and overall experience.',
                style: ArtistTextStyles.body.copyWith(
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _buildArtistProfile(),
              const SizedBox(height: 16),
              _buildRatingSummary(),
              const SizedBox(height: 20),
              _buildReviewsHeader(),
              const SizedBox(height: 12),
              ...reviews.map(_buildReviewCard),
              const SizedBox(height: 2),
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  // Artist profile card.
  Widget _buildArtistProfile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ArtistColors.light,
              border: Border.all(
                color: ArtistColors.primary.withOpacity(0.25),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: ArtistColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Artist Profile',
                  style: ArtistTextStyles.title.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text('Handmade Artist', style: ArtistTextStyles.caption),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: ArtistColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: ArtistColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'from 5 reviews',
                      style: ArtistTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: ArtistColors.light,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _editAboutYou,
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: Icon(
                  Icons.edit_outlined,
                  color: ArtistColors.primary,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Rating summary.
  Widget _buildRatingSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Column(
              children: [
                Text(
                  '4.8',
                  style: ArtistTextStyles.heading.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star_rounded,
                      color: ArtistColors.primary,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Overall Rating',
                  style: ArtistTextStyles.caption.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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

  // Rating progress row.
  Widget _ratingBar(int rating, int count) {
    final progress = reviews.isEmpty ? 0.0 : count / reviews.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '$rating',
              style: ArtistTextStyles.caption.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.star_rounded, color: ArtistColors.primary, size: 11),
          const SizedBox(width: 5),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: ArtistColors.surfaceSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ArtistColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 14,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: ArtistTextStyles.caption.copyWith(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  // Reviews header.
  Widget _buildReviewsHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Customer Reviews',
            style: ArtistTextStyles.title.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: ArtistColors.light,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '${reviews.length} Reviews',
            style: ArtistTextStyles.caption.copyWith(
              color: ArtistColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // Review card.
  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] as int;
    final name = review['name']?.toString() ?? 'Customer';
    final date = review['date']?.toString() ?? '';
    final reviewText = review['review']?.toString() ?? '';
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ArtistColors.light,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      color: ArtistColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: ArtistColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: ArtistTextStyles.caption.copyWith(fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: ArtistColors.primary,
                      size: 13,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$rating.0',
                      style: ArtistTextStyles.caption.copyWith(
                        color: ArtistColors.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: ArtistColors.primary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            reviewText,
            style: ArtistTextStyles.body.copyWith(
              color: ArtistColors.textPrimary,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.thumb_up_alt_outlined,
                color: ArtistColors.textMuted,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                'Helpful review',
                style: ArtistTextStyles.caption.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showReviewOptions(review),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: ArtistColors.textMuted,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Information card.
  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArtistColors.border.withOpacity(0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: ArtistColors.primary,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Your customer reviews help visitors understand your work and build trust in your artist profile.',
              style: ArtistTextStyles.body.copyWith(
                color: ArtistColors.textPrimary,
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Edit action.
  void _editAboutYou() {
    _showMessage('Edit About You is ready to connect.');
  }

  // Review options.
  void _showReviewOptions(Map<String, dynamic> review) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ArtistColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: ArtistColors.light,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.rate_review_outlined,
                        color: ArtistColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Text(
                      'Review Options',
                      style: ArtistTextStyles.title.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sheetOption(
                  icon: Icons.visibility_outlined,
                  title: 'View Review',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage('Review selected.');
                  },
                ),
                _sheetOption(
                  icon: Icons.flag_outlined,
                  title: 'Report Review',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage('Review reported.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Bottom sheet option.
  Widget _sheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: ArtistColors.surfaceSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: ArtistColors.primary, size: 19),
      ),
      title: Text(
        title,
        style: ArtistTextStyles.bodyMedium.copyWith(
          color: ArtistColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: ArtistColors.textMuted,
      ),
      onTap: onTap,
    );
  }

  // Help dialog.
  void _showAboutHelp() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: ArtistColors.surface,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ArtistColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ArtistColors.light,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: ArtistColors.primary,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'About You',
                        style: ArtistTextStyles.title.copyWith(fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: ArtistColors.textMuted,
                        size: 21,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Customer Reviews',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    color: ArtistColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'This section shows reviews and ratings given by customers who have interacted with your products or services.',
                  style: ArtistTextStyles.body.copyWith(
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Use customer feedback to understand their experience and improve your artist profile and products.',
                  style: ArtistTextStyles.body.copyWith(
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtistColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: Text(
                      'Got It',
                      style: ArtistTextStyles.button.copyWith(fontSize: 13),
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

  // Snackbar message.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: ArtistTextStyles.body.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.accent,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      );
  }
}
