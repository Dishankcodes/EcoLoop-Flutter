import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ContactUs extends StatelessWidget {
  const ContactUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: Text('Contact Us', style: ArtistTextStyles.title),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  color: ArtistColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ArtistColors.border),
                ),

                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: ArtistColors.light,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        size: 32,
                        color: ArtistColors.primary,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text('How can we help?', style: ArtistTextStyles.title),

                    const SizedBox(height: 6),

                    Text(
                      'Have a question or need help with your artist account? We are here to help.',
                      textAlign: TextAlign.center,
                      style: ArtistTextStyles.body,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Contact Options',
                style: ArtistTextStyles.title.copyWith(fontSize: 17),
              ),

              const SizedBox(height: 12),

              _ContactTile(
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'support@ecoloop.com',
                onTap: () {
                  _showMessage(
                    context,
                    'Email support will be connected soon.',
                  );
                },
              ),

              const SizedBox(height: 10),

              _ContactTile(
                icon: Icons.phone_outlined,
                title: 'Call Support',
                subtitle: 'Talk to our support team',
                onTap: () {
                  _showMessage(context, 'Call support will be connected soon.');
                },
              ),

              const SizedBox(height: 10),

              _ContactTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Live Chat',
                subtitle: 'Chat with EcoLoop support',
                onTap: () {
                  _showMessage(context, 'Live chat will be connected soon.');
                },
              ),

              const SizedBox(height: 28),

              Text(
                'Business Hours',
                style: ArtistTextStyles.title.copyWith(fontSize: 17),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: ArtistColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ArtistColors.border),
                ),

                child: Column(
                  children: [
                    _BusinessHourRow(
                      day: 'Monday - Friday',
                      time: '10:00 AM - 6:00 PM',
                    ),

                    const Divider(height: 24, color: ArtistColors.border),

                    _BusinessHourRow(
                      day: 'Saturday',
                      time: '10:00 AM - 2:00 PM',
                    ),

                    const Divider(height: 24, color: ArtistColors.border),

                    _BusinessHourRow(day: 'Sunday', time: 'Closed'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}

// -----------------------------------------------------------------------------
// CONTACT TILE
// -----------------------------------------------------------------------------

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),

      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ArtistColors.border),
        ),

        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ArtistColors.light,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: ArtistColors.primary),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(subtitle, style: ArtistTextStyles.caption),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: ArtistColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// BUSINESS HOURS
// -----------------------------------------------------------------------------

class _BusinessHourRow extends StatelessWidget {
  const _BusinessHourRow({required this.day, required this.time});

  final String day;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            day,
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Text(
          time,
          style: ArtistTextStyles.caption.copyWith(
            color: ArtistColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
