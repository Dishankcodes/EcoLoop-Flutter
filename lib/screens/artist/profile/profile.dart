import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _skills = ['Woodwork', 'Upcycling', 'Home Decor'];

  final _stats = [
    {'count': '12', 'label': 'Products'},
    {'count': '56', 'label': 'Orders'},
    {'count': '4.8', 'label': 'Rating'},
    {'count': '2.4K', 'label': 'Followers'},
  ];

  void _toast(String title) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$title clicked',
            style: ArtistTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PROFILE HEADER
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ArtistColors.textPrimary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: ArtistColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Creative Studio',
                          style: ArtistTextStyles.title.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ArtistColors.light.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Verified Artist',
                            style: ArtistTextStyles.small.copyWith(
                              color: ArtistColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // METRICS
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: _cardDecoration(),
                child: Row(
                  children: _stats.map((stat) {
                    return Expanded(
                      child: InkWell(
                        onTap: () => _toast(stat['label']!),
                        child: Column(
                          children: [
                            Text(
                              stat['count']!,
                              style: ArtistTextStyles.title.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: ArtistColors.primary,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              stat['label']!,
                              style: ArtistTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 28),

              // BIO
              _sectionTitle('Bio'),

              const SizedBox(height: 8),

              Text(
                'We create unique upcycled products that bring new life to old materials.',
                style: ArtistTextStyles.body,
              ),

              const SizedBox(height: 24),

              // SKILLS
              _sectionTitle('Skills'),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skills.map((skill) {
                  return InkWell(
                    onTap: () => _toast(skill),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: ArtistColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ArtistColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '•',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ArtistColors.primary,
                            ),
                          ),

                          const SizedBox(width: 5),

                          Text(
                            skill,
                            style: ArtistTextStyles.caption.copyWith(
                              color: ArtistColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // LOCATION
              _sectionTitle('Location'),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: ArtistColors.primary,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    'Ahmedabad, Gujarat',
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _toast('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: ArtistColors.primary,
                        side: const BorderSide(
                          color: ArtistColors.primary,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: ArtistTextStyles.button.copyWith(
                          color: ArtistColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _toast('View Portfolio'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: ArtistColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'View Portfolio',
                        style: ArtistTextStyles.button.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // SECTION TITLE

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: ArtistTextStyles.title.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }

  // CARD DECORATION

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: ArtistColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ArtistColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
