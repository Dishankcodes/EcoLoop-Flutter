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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            _hero(),
            _section(
              'Our Mission',
              'EcoLoop is a community marketplace designed to help people '
                  'buy, sell and donate reusable items, while connecting them '
                  'with ReMakers who create, restore and transform materials. '
                  'The goal is to give useful things another life and encourage '
                  'more thoughtful consumption.',
            ),
            _howItWorks(),
            _values(),
            _community(),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
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
          const SizedBox(height: 12),
          Text(
            'A marketplace for reuse, creativity and more sustainable choices.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String description) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      color: ArtistColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: ArtistTextStyles.body.copyWith(
              fontSize: 13,
              height: 1.65,
              color: ArtistColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
      color: ArtistColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How EcoLoop Works',
            style: ArtistTextStyles.title.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          _step(
            '01',
            Icons.sell_outlined,
            'List an Item',
            'Create a listing with an accurate description, photos, price '
                'and availability.',
          ),
          _step(
            '02',
            Icons.search_rounded,
            'Discover Useful Products',
            'Explore products and reusable materials offered by users '
                'and ReMakers.',
          ),
          _step(
            '03',
            Icons.palette_outlined,
            'Showcase Your Creativity',
            'Use your ReMaker profile and portfolio to present your work '
                'and transformation stories.',
          ),
          _step(
            '04',
            Icons.volunteer_activism_outlined,
            'Donate and Reuse',
            'Use the available donation features to offer eligible items '
                'for reuse. Pickup and reward availability are not guaranteed.',
          ),
        ],
      ),
    );
  }

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
                    height: 1.5,
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

  Widget _values() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: ArtistColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What We Value',
            style: ArtistTextStyles.title.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          _value(
            Icons.recycling_outlined,
            'Reuse over waste',
            'Encourage useful items and materials to find a new purpose.',
          ),
          _value(
            Icons.handshake_outlined,
            'Community',
            'Connect people who have useful items with people who need them.',
          ),
          _value(
            Icons.brush_outlined,
            'Creativity',
            'Give ReMakers a place to present their work and skills.',
          ),
          _value(
            Icons.verified_user_outlined,
            'Responsible participation',
            'Encourage honest listings, respectful communication and '
                'responsible handling of customer information.',
          ),
        ],
      ),
    );
  }

  Widget _value(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 23, color: ArtistColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: ArtistTextStyles.caption.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _community() {
    return _section(
      'For ReMakers',
      'EcoLoop provides features for managing a public profile, presenting '
          'portfolio work, publishing product listings, viewing orders and '
          'engaging with customer reviews. ReMakers can also explore available '
          'marketplace products and respond to custom-service requests where '
          'those features are available. Earnings displays should not be treated '
          'as proof that a payment has been collected or settled.',
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
      child: Column(
        children: [
          const Icon(Icons.eco_outlined, size: 26, color: ArtistColors.primary),
          const SizedBox(height: 8),
          Text(
            'EcoLoop',
            style: ArtistTextStyles.title.copyWith(
              color: ArtistColors.primary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Support: ecoloopp2026@gmail.com',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption,
          ),
          const SizedBox(height: 5),
          Text(
            'Operator legal details and formal business address: Pending.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}
