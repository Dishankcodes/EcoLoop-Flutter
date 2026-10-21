import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../ai_chat_screen.dart';

class ArtistHelpSupportScreen extends StatefulWidget {
  const ArtistHelpSupportScreen({super.key});

  @override
  State<ArtistHelpSupportScreen> createState() =>
      _ArtistHelpSupportScreenState();
}

class _ArtistHelpSupportScreenState extends State<ArtistHelpSupportScreen> {
  static const String _supportEmail = 'ecoloopp2026@gmail.com';

  final List<Map<String, String>> _topics = const [
    {
      'title': 'Products and listings',
      'description':
          'Help with publishing, editing, product images, categories, prices '
          'and stock information.',
      'icon': 'products',
    },
    {
      'title': 'Orders and delivery',
      'description':
          'Questions about selling orders, order status, COD arrangements '
          'or delivery issues.',
      'icon': 'orders',
    },
    {
      'title': 'Profile and portfolio',
      'description':
          'Help with your ReMaker profile, portfolio stories, profile image '
          'or certificate information.',
      'icon': 'profile',
    },
    {
      'title': 'Custom services',
      'description':
          'Questions about project briefs, proposals, scope, timelines, '
          'reference images or customer acceptance.',
      'icon': 'custom',
    },
    {
      'title': 'Reviews and followers',
      'description':
          'Help understanding displayed reviews, ratings and profile '
          'following features.',
      'icon': 'reviews',
    },
    {
      'title': 'Privacy and account',
      'description':
          'Privacy questions, suspected unauthorised access, account '
          'closure or requests concerning personal information.',
      'icon': 'privacy',
    },
  ];

  IconData _iconFor(String key) {
    switch (key) {
      case 'products':
        return Icons.inventory_2_outlined;
      case 'orders':
        return Icons.local_shipping_outlined;
      case 'profile':
        return Icons.person_outline_rounded;
      case 'custom':
        return Icons.design_services_outlined;
      case 'reviews':
        return Icons.star_outline_rounded;
      case 'privacy':
        return Icons.shield_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Future<void> _showContactOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ArtistColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact EcoLoop Support',
                  style: ArtistTextStyles.title.copyWith(fontSize: 19),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email is the current support contact. Phone support and '
                  'live chat availability are not confirmed.',
                  style: ArtistTextStyles.body.copyWith(
                    height: 1.5,
                    color: ArtistColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ArtistColors.background,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: ArtistColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: ArtistColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SelectableText(
                          _supportEmail,
                          style: ArtistTextStyles.bodyMedium.copyWith(
                            color: ArtistColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy email',
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Support email: ecoloopp2026@gmail.com',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        },
                        icon: const Icon(Icons.info_outline_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtistColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Got It',
                      style: ArtistTextStyles.button.copyWith(fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        foregroundColor: ArtistColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Help & Support',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: ArtistColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: ArtistColors.border)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: ArtistColors.light, child: Icon(Icons.auto_awesome_rounded, color: ArtistColors.primary)),
              title: Text('Chat with EcoLoop AI', style: ArtistTextStyles.title.copyWith(fontSize: 14)),
              subtitle: Text('Get quick answers for your ReMaker account', style: ArtistTextStyles.body.copyWith(fontSize: 11, color: ArtistColors.textSecondary)),
              trailing: Icon(Icons.chevron_right_rounded, color: ArtistColors.primary),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiChatScreen())),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ArtistColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 13),
                const Text(
                  'We’re here to help',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Find the right support topic for your ReMaker account.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 17),
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _showContactOptions,
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('Contact Support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          Text(
            'What do you need help with?',
            style: ArtistTextStyles.title.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 12),
          ..._topics.map((topic) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: ArtistColors.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: ArtistColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: ArtistColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        _iconFor(topic['icon']!),
                        color: ArtistColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic['title']!,
                            style: ArtistTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            topic['description']!,
                            style: ArtistTextStyles.body.copyWith(
                              fontSize: 12,
                              height: 1.5,
                              color: ArtistColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: ArtistColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before contacting support',
                  style: ArtistTextStyles.title.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Include the relevant order or product reference, describe '
                  'what happened and explain what help you need. Do not send '
                  'your password, OTP or full payment credentials.',
                  style: ArtistTextStyles.body.copyWith(
                    fontSize: 12,
                    height: 1.6,
                    color: ArtistColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Support email: $_supportEmail\n'
              'Formal grievance officer and response deadlines: Pending.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.caption.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
