import 'package:flutter/material.dart';

import '/../app_theme/artist/artist_text_styles.dart';
import '/app_theme/artist/artist_colors.dart';

class ArtistHelpSupportScreen extends StatefulWidget {
  const ArtistHelpSupportScreen({super.key});

  @override
  State<ArtistHelpSupportScreen> createState() =>
      _ArtistHelpSupportScreenState();
}

class _ArtistHelpSupportScreenState extends State<ArtistHelpSupportScreen> {
  final List<Map<String, String>> faqs = [
    {
      'question': 'How do I add a product?',
      'answer':
          'Open the Add Product option from your artist dashboard. Enter your product information, category, price, stock and description, then publish the product.',
    },
    {
      'question': 'How can I manage my products?',
      'answer':
          'Use the My Products section to view your listed products and manage product information, availability and other product details.',
    },
    {
      'question': 'How do I manage an order?',
      'answer':
          'Open your Orders section to view customer orders. Select an order to check its details and current order status.',
    },
    {
      'question': 'How can I see customer reviews?',
      'answer':
          'Open the About You section from your artist profile. Reviews and ratings provided by customers can be viewed there.',
    },
    {
      'question': 'How do I add a certificate?',
      'answer':
          'Open the Certificate section, enter the certificate information and submit it. Certificates may be reviewed before appearing on your artist profile.',
    },
    {
      'question': 'How can I check my followers?',
      'answer':
          'Open the Followers section from your artist profile to view users who follow your artist account.',
    },
    {
      'question': 'What should I do if I have an order problem?',
      'answer':
          'Open the relevant order and review the order information. If you need additional assistance, contact support through this Help & Support section.',
    },
  ];

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: ArtistTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.primary,
          margin: const EdgeInsets.all(14),
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
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
          tooltip: 'Back',
        ),
        title: Text(
          'Help & Support',
          style: ArtistTextStyles.title.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: _showHelpInfo,
            icon: const Icon(
              Icons.info_outline_rounded,
              color: ArtistColors.textSecondary,
            ),
            tooltip: 'Help Info',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 18),

              _sectionTitle('Quick Help'),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _quickHelpCard(
                      Icons.inventory_2_outlined,
                      'Products',
                      'Manage your products',
                      () => _showSnackBar('Product Support'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickHelpCard(
                      Icons.receipt_long_outlined,
                      'Orders',
                      'Manage customer orders',
                      () => _showSnackBar('Order Support'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _quickHelpCard(
                      Icons.verified_outlined,
                      'Certificate',
                      'Manage certificates',
                      () => _showSnackBar('Certificate Support'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _quickHelpCard(
                      Icons.people_outline_rounded,
                      'Followers',
                      'View your followers',
                      () => _showSnackBar('Follower Support'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              _sectionTitle('How Artist Selling Works'),
              const SizedBox(height: 10),

              _howItWorksStep(
                number: '01',
                icon: Icons.person_outline_rounded,
                title: 'Create Your Artist Profile',
                description:
                    'Complete your artist profile and provide information that helps users understand your work and creative background.',
              ),
              _howItWorksStep(
                number: '02',
                icon: Icons.verified_outlined,
                title: 'Add Your Certificates',
                description:
                    'Add relevant certificate information to your artist profile. Submitted certificates may be reviewed before appearing on your profile.',
              ),
              _howItWorksStep(
                number: '03',
                icon: Icons.add_box_outlined,
                title: 'Add Your Products',
                description:
                    'Create product listings with product name, category, price, stock quantity and description.',
              ),
              _howItWorksStep(
                number: '04',
                icon: Icons.storefront_outlined,
                title: 'Your Products Are Available',
                description:
                    'Once your products are listed, users can explore your products and interact with your artist profile.',
              ),
              _howItWorksStep(
                number: '05',
                icon: Icons.shopping_bag_outlined,
                title: 'Receive Customer Orders',
                description:
                    'View customer orders from your Orders section and open individual orders to see their details.',
              ),
              _howItWorksStep(
                number: '06',
                icon: Icons.local_shipping_outlined,
                title: 'Manage Order Progress',
                description:
                    'Keep track of order information and update or manage the order according to the available order workflow.',
              ),
              _howItWorksStep(
                number: '07',
                icon: Icons.star_outline_rounded,
                title: 'Receive Customer Reviews',
                description:
                    'Customers can review their experience. You can view the feedback and ratings from the About You section.',
              ),

              const SizedBox(height: 12),

              _sectionTitle('Frequently Asked Questions'),
              const SizedBox(height: 8),

              ...faqs.map((faq) => _faqCard(faq['question']!, faq['answer']!)),

              const SizedBox(height: 10),

              _sectionTitle('Contact Support'),
              const SizedBox(height: 10),

              _buildSupportCard(),

              const SizedBox(height: 16),

              _buildSupportNote(),
            ],
          ),
        ),
      ),
    );
  }

  // Header.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: ArtistColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Artist Support',
                  style: ArtistTextStyles.title.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your products, orders, profile and get help when you need it.',
                  style: ArtistTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section title.
  Widget _sectionTitle(String title) {
    return Text(title, style: ArtistTextStyles.title.copyWith(fontSize: 16));
  }

  // Quick help card.
  Widget _quickHelpCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: ArtistColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: ArtistColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ArtistColors.light.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ArtistColors.primary, size: 21),
              ),
              const SizedBox(height: 9),
              Text(title, style: ArtistTextStyles.label.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ArtistTextStyles.small.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Selling step.
  Widget _howItWorksStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ArtistColors.light.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: ArtistColors.primary, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      number,
                      style: ArtistTextStyles.small.copyWith(
                        color: ArtistColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        title,
                        style: ArtistTextStyles.label.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: ArtistTextStyles.small.copyWith(
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FAQ card.
  Widget _faqCard(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: ArtistColors.primary,
          collapsedIconColor: ArtistColors.textMuted,
          title: Text(
            question,
            style: ArtistTextStyles.label.copyWith(fontSize: 12.5),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: ArtistTextStyles.small.copyWith(
                  fontSize: 10.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Support card.
  Widget _buildSupportCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          _supportOption(
            Icons.chat_bubble_outline_rounded,
            'Artist Support Chat',
            'Get help with your artist account',
            () => _showSnackBar('Opening Artist Support Chat'),
          ),
          const Divider(height: 20, color: ArtistColors.border),
          _supportOption(
            Icons.email_outlined,
            'Email Support',
            'Send your issue to support',
            () => _showSnackBar('Opening Email Support'),
          ),
          const Divider(height: 20, color: ArtistColors.border),
          _supportOption(
            Icons.report_problem_outlined,
            'Report a Problem',
            'Report an issue with your artist account',
            () => _showSnackBar('Report Problem'),
          ),
          const Divider(height: 20, color: ArtistColors.border),
          _supportOption(
            Icons.help_outline_rounded,
            'Certificate Help',
            'Get help with certificate information',
            _showCertificateHelp,
          ),
        ],
      ),
    );
  }

  // Support option.
  Widget _supportOption(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ArtistColors.light.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: ArtistColors.primary, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ArtistTextStyles.label.copyWith(fontSize: 12.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: ArtistTextStyles.small.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ArtistColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Support note.
  Widget _buildSupportNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.light.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: ArtistColors.primary,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'For faster assistance, mention your product, order or certificate details when contacting support.',
              style: ArtistTextStyles.small.copyWith(
                color: ArtistColors.textPrimary,
                fontSize: 10.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Help information.
  void _showHelpInfo() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ArtistColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ArtistColors.light.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: ArtistColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Artist Help',
                style: ArtistTextStyles.title.copyWith(fontSize: 18),
              ),
            ],
          ),
          content: Text(
            'Use this page to learn how artist features work, manage products and orders, understand certificates and reviews, or contact support.',
            style: ArtistTextStyles.body.copyWith(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Got It',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Certificate help.
  void _showCertificateHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
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
                        color: ArtistColors.light.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        color: ArtistColors.primary,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Text(
                      'Certificate Help',
                      style: ArtistTextStyles.title.copyWith(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Certificate information helps present your artist credentials on your profile.',
                  style: ArtistTextStyles.body.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 10),
                Text(
                  '• Enter the certificate name correctly.\n'
                  '• Add the issuing organization.\n'
                  '• Select the appropriate certificate type.\n'
                  '• Add the relevant year.\n'
                  '• Submit the information for review.',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 18),
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
}
