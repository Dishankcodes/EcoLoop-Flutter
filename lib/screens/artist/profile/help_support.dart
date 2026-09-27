import 'package:flutter/material.dart';

void main() => runApp(
  const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ArtistHelpSupportScreen(),
  ),
);

class ArtistHelpSupportScreen extends StatefulWidget {
  const ArtistHelpSupportScreen({super.key});

  @override
  State<ArtistHelpSupportScreen> createState() =>
      _ArtistHelpSupportScreenState();
}

class _ArtistHelpSupportScreenState
    extends State<ArtistHelpSupportScreen> {

  // ================================================================
  // ARTIST THEME
  // ================================================================

  final Color primary = const Color(0xFFAD563E);
  final Color background = const Color(0xFFF7F0E7);
  final Color cardColor = const Color(0xFFFFFCF8);
  final Color softTerracotta = const Color(0xFFF0DED4);
  final Color textColor = const Color(0xFF292522);
  final Color mutedColor = const Color(0xFF8B817A);
  final Color borderColor = const Color(0xFFE2D5C8);

  // ================================================================
  // FAQ DATA
  // ================================================================

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

  // ================================================================
  // TOAST
  // ================================================================

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

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          onPressed: () => _toast('Back clicked'),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textColor,
          ),
        ),

        title: Text(
          'Help & Support',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _showHelpInfo,
            icon: Icon(
              Icons.info_outline_rounded,
              color: mutedColor,
            ),
          ),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ======================================================
              // HEADER
              // ======================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.20),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [

                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Artist Support',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Manage your products, orders, profile and get help when you need it.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ======================================================
              // QUICK HELP
              // ======================================================

              _sectionTitle('Quick Help'),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _quickHelpCard(
                      Icons.inventory_2_outlined,
                      'Products',
                      'Manage your products',
                          () => _toast('Product Support'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickHelpCard(
                      Icons.receipt_long_outlined,
                      'Orders',
                      'Manage customer orders',
                          () => _toast('Order Support'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _quickHelpCard(
                      Icons.verified_outlined,
                      'Certificate',
                      'Manage certificates',
                          () => _toast('Certificate Support'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickHelpCard(
                      Icons.people_outline_rounded,
                      'Followers',
                      'View your followers',
                          () => _toast('Follower Support'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ======================================================
              // HOW IT WORKS
              // ======================================================

              _sectionTitle('How Artist Selling Works'),

              const SizedBox(height: 12),

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

              const SizedBox(height: 20),

              // ======================================================
              // ARTIST FAQ
              // ======================================================

              _sectionTitle('Frequently Asked Questions'),

              const SizedBox(height: 10),

              ...faqs.map(
                    (faq) => _faqCard(
                  faq['question']!,
                  faq['answer']!,
                ),
              ),

              const SizedBox(height: 18),

              // ======================================================
              // SUPPORT
              // ======================================================

              _sectionTitle('Contact Support'),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: Column(
                  children: [

                    _supportOption(
                      Icons.chat_bubble_outline_rounded,
                      'Artist Support Chat',
                      'Get help with your artist account',
                          () => _toast('Opening Artist Support Chat'),
                    ),

                    const Divider(height: 22),

                    _supportOption(
                      Icons.email_outlined,
                      'Email Support',
                      'Send your issue to support',
                          () => _toast('Opening Email Support'),
                    ),

                    const Divider(height: 22),

                    _supportOption(
                      Icons.report_problem_outlined,
                      'Report a Problem',
                      'Report an issue with your artist account',
                          () => _toast('Report Problem'),
                    ),

                    const Divider(height: 22),

                    _supportOption(
                      Icons.help_outline_rounded,
                      'Certificate Help',
                      'Get help with certificate information',
                          () => _showCertificateHelp(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ======================================================
              // ARTIST SUPPORT NOTE
              // ======================================================

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: softTerracotta,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: primary,
                      size: 21,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'For faster assistance, mention your product, order or certificate details when contacting support.',
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
    );
  }

  // ================================================================
  // SECTION TITLE
  // ================================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: textColor,
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }

  // ================================================================
  // QUICK HELP CARD
  // ================================================================

  Widget _quickHelpCard(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: softTerracotta,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: primary,
                size: 22,
              ),
            ),

            const SizedBox(height: 11),

            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              style: TextStyle(
                color: mutedColor,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HOW IT WORKS
  // ================================================================

  Widget _howItWorksStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: softTerracotta,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        color: primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 10.5,
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

  // ================================================================
  // FAQ
  // ================================================================

  Widget _faqCard(
      String question,
      String answer,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 15,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          15,
          0,
          15,
          15,
        ),
        iconColor: primary,
        collapsedIconColor: mutedColor,
        title: Text(
          question,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: TextStyle(
                color: mutedColor,
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUPPORT OPTION
  // ================================================================

  Widget _supportOption(
      IconData icon,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: softTerracotta,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            Icons.chevron_right_rounded,
            color: mutedColor,
            size: 21,
          ),
        ],
      ),
    );
  }

  // ================================================================
  // HELP INFO
  // ================================================================

  void _showHelpInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Artist Help',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Text(
            'Use this page to learn how artist features work, manage products and orders, understand certificates and reviews, or contact support.',
            style: TextStyle(
              color: mutedColor,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: Text(
                'Got It',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // CERTIFICATE HELP
  // ================================================================

  void _showCertificateHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: softTerracotta,
                      borderRadius:
                      BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.verified_outlined,
                      color: primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Text(
                    'Certificate Help',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                'Certificate information helps present your artist credentials on your profile.',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '• Enter the certificate name correctly.\n'
                    '• Add the issuing organization.\n'
                    '• Select the appropriate certificate type.\n'
                    '• Add the relevant year.\n'
                    '• Submit the information for review.',
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'Got It',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}