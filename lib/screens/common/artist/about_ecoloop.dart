import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ArtistAboutEcoLoop extends StatelessWidget {
  const ArtistAboutEcoLoop({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: AppBar(
        backgroundColor: ArtistColors.surface,
        foregroundColor: ArtistColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'About EcoLoop',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ArtistColors.textPrimary,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            _buildHero(),
            _buildMission(),
            _buildHowItWorks(),
            _buildValues(),
            _buildCommunity(),
            _buildVersion(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HERO
  // ===========================================================================

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      color: ArtistColors.surface,
      padding: const EdgeInsets.fromLTRB(25, 28, 25, 30),
      child: Column(
        children: [
          Container(
            height: 82,
            width: 82,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(27),
            ),
            child: const Icon(
              Icons.eco_rounded,
              size: 46,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'EcoLoop',
            style: ArtistTextStyles.title.copyWith(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Give unused things a new life.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.body.copyWith(
              fontSize: 14,
              color: ArtistColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MISSION
  // ===========================================================================

  Widget _buildMission() {
    return _section(
      title: 'Our Mission',
      child: Text(
        'EcoLoop is a community marketplace built to help people '
        'sell, buy, reuse and donate items that still have value. '
        'Instead of letting useful products become waste, EcoLoop '
        'helps connect them with people who can use them again.',
        style: ArtistTextStyles.body.copyWith(
          fontSize: 13,
          height: 1.65,
          color: ArtistColors.textSecondary,
        ),
      ),
    );
  }

  // ===========================================================================
  // HOW IT WORKS
  // ===========================================================================

  Widget _buildHowItWorks() {
    return _section(
      title: 'How EcoLoop Works',
      child: Column(
        children: [
          _step(
            '01',
            Icons.sell_outlined,
            'List an Item',
            'Sell your unused items by creating a simple listing.',
          ),

          _step(
            '02',
            Icons.search_rounded,
            'Find Something Useful',
            'Explore items listed by people and creators in the community.',
          ),

          _step(
            '03',
            Icons.recycling_rounded,
            'Reuse & Recycle',
            'Give products, materials and useful items another purpose.',
          ),

          _step(
            '04',
            Icons.volunteer_activism_outlined,
            'Donate',
            'Donate items that can help someone else instead of throwing them away.',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STEP
  // ===========================================================================

  Widget _step(String number, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: ArtistColors.primary, size: 22),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ArtistColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        number,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        title,
                        style: ArtistTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ArtistColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: ArtistTextStyles.body.copyWith(
                    fontSize: 11,
                    height: 1.45,
                    color: ArtistColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // VALUES
  // ===========================================================================

  Widget _buildValues() {
    return _section(
      title: 'What We Believe In',
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          _tag(Icons.recycling, 'Reuse'),

          _tag(Icons.eco_outlined, 'Sustainability'),

          _tag(Icons.people_outline, 'Community'),

          _tag(Icons.favorite_border, 'Responsibility'),

          _tag(Icons.auto_awesome_outlined, 'Creativity'),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAG
  // ===========================================================================

  Widget _tag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: ArtistColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ArtistColors.primary),

          const SizedBox(width: 6),

          Text(
            text,
            style: ArtistTextStyles.body.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ArtistColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COMMUNITY
  // ===========================================================================

  Widget _buildCommunity() {
    return _section(
      title: 'Built for the Community',
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: ArtistColors.surfaceSoft.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.groups_outlined,
              color: ArtistColors.primary,
              size: 25,
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Text(
                'Every item reused is one less item going to waste. '
                'Together, small actions can create a bigger impact.',
                style: ArtistTextStyles.body.copyWith(
                  fontSize: 11,
                  height: 1.5,
                  color: ArtistColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // VERSION
  // ===========================================================================

  Widget _buildVersion() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Text(
            'EcoLoop',
            style: ArtistTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Version 1.0.0',
            style: ArtistTextStyles.body.copyWith(
              fontSize: 10,
              color: ArtistColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION
  // ===========================================================================

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      color: ArtistColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ArtistColors.textPrimary,
            ),
          ),

          const SizedBox(height: 15),

          child,
        ],
      ),
    );
  }
}
