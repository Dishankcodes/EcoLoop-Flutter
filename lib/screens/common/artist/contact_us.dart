import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ContactUs extends StatelessWidget {
  const ContactUs({super.key});

  static const String _supportEmail = 'ecoloopp2026@gmail.com';

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'EcoLoop ReMaker Support'},
    );

    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        await Clipboard.setData(const ClipboardData(text: _supportEmail));
        _showMessage(
          context,
          'Email app unavailable. Support email copied to clipboard.',
        );
      }
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: _supportEmail));
      if (context.mounted) {
        _showMessage(context, 'Support email copied to clipboard.');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

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
                      'Have a question about your ReMaker account, products, orders or custom services? Contact EcoLoop by email.',
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
                subtitle: _supportEmail,
                onTap: () => _openEmail(context),
              ),
              const SizedBox(height: 10),
              _ContactTile(
                icon: Icons.phone_outlined,
                title: 'Call Support',
                subtitle: 'Phone support is not currently available.',
                onTap: () => _showMessage(
                  context,
                  'Please contact EcoLoop by email: $_supportEmail',
                ),
              ),
              const SizedBox(height: 10),
              _ContactTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Live Chat',
                subtitle: 'Live chat is not currently available.',
                onTap: () => _showMessage(
                  context,
                  'Please contact EcoLoop by email: $_supportEmail',
                ),
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
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: ArtistColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ArtistColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: ArtistColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'For privacy requests, account concerns or grievances, email $_supportEmail. The formal grievance-handling process and response timelines are pending confirmation.',
                        style: ArtistTextStyles.body.copyWith(
                          fontSize: 12,
                          height: 1.5,
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
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ArtistColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: ArtistColors.primary, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ArtistTextStyles.title.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: ArtistTextStyles.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ArtistColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessHourRow extends StatelessWidget {
  final String day;
  final String time;

  const _BusinessHourRow({required this.day, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            day,
            style: ArtistTextStyles.body.copyWith(
              fontSize: 12,
              color: ArtistColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          time,
          style: ArtistTextStyles.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
