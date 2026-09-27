import 'package:flutter/material.dart';

void main() => runApp(
  const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: UserHelpSupportScreen(),
  ),
);

class UserHelpSupportScreen extends StatefulWidget {
  const UserHelpSupportScreen({super.key});

  @override
  State<UserHelpSupportScreen> createState() =>
      _UserHelpSupportScreenState();
}

class _UserHelpSupportScreenState extends State<UserHelpSupportScreen> {
  // ================================================================
  // USER THEME
  // ================================================================

  final Color primary = const Color(0xFF5A49E3);
  final Color background = const Color(0xFFF8F9FE);
  final Color softPurple = const Color(0xFFEDEBFB);
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF1E1E2D);
  final Color mutedColor = const Color(0xFF7E8CA0);
  final Color borderColor = const Color(0xFFEAEAF3);

  // ================================================================
  // FAQ DATA
  // ================================================================

  final List<Map<String, String>> faqs = [
    {
      'question': 'How do I buy a product?',
      'answer':
      'Browse products from the marketplace, open the product you like, check its details and add it to your cart. Continue to checkout and complete your payment.',
    },
    {
      'question': 'How can I track my order?',
      'answer':
      'Open the Orders section from your profile or navigation menu. Select an order to view its current status and tracking information.',
    },
    {
      'question': 'How do I add a product to wishlist?',
      'answer':
      'Open any product and tap the heart icon. The product will be saved in your Wishlist so you can easily find it later.',
    },
    {
      'question': 'How can I become an artist?',
      'answer':
      'Use the selling/artist option available in your account and complete the required artist information and verification steps.',
    },
    {
      'question': 'Can I review a product?',
      'answer':
      'After purchasing a product, you can provide your feedback and rating from the relevant order or product section.',
    },
    {
      'question': 'What should I do if I have a problem with my order?',
      'answer':
      'Open your order details and check the available support options. You can also contact support for assistance.',
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
  // MAIN BUILD
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

        leading: IconButton(
          onPressed: () => _toast('Back clicked'),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF1E1E2D),
          ),
        ),

        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Color(0xFF1E1E2D),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        centerTitle: true,
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
              // HEADER CARD
              // ======================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.18),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How can we help?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Find answers, learn how EcoLoop works or contact support.',
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
                      Icons.shopping_bag_outlined,
                      'Orders',
                      'Track your orders',
                          () => _toast('Orders Support'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickHelpCard(
                      Icons.favorite_border_rounded,
                      'Wishlist',
                      'Manage saved items',
                          () => _toast('Wishlist Support'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _quickHelpCard(
                      Icons.payment_outlined,
                      'Payments',
                      'Payment assistance',
                          () => _toast('Payment Support'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickHelpCard(
                      Icons.person_outline_rounded,
                      'Account',
                      'Account assistance',
                          () => _toast('Account Support'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ======================================================
              // HOW IT WORKS
              // ======================================================

              _sectionTitle('How EcoLoop Works'),

              const SizedBox(height: 12),

              _howItWorksStep(
                number: '01',
                icon: Icons.search_rounded,
                title: 'Explore Products',
                description:
                'Browse handmade, upcycled and sustainable products available on EcoLoop.',
              ),

              _howItWorksStep(
                number: '02',
                icon: Icons.favorite_border_rounded,
                title: 'Save or Add to Cart',
                description:
                'Save products to your wishlist or add the products you want to purchase to your cart.',
              ),

              _howItWorksStep(
                number: '03',
                icon: Icons.shopping_cart_outlined,
                title: 'Place Your Order',
                description:
                'Review your selected products, provide the required details and complete checkout.',
              ),

              _howItWorksStep(
                number: '04',
                icon: Icons.local_shipping_outlined,
                title: 'Track Delivery',
                description:
                'View your order status and follow the delivery progress from the Orders section.',
              ),

              _howItWorksStep(
                number: '05',
                icon: Icons.star_outline_rounded,
                title: 'Share Your Review',
                description:
                'After receiving your product, share your experience by giving a rating and review.',
              ),

              const SizedBox(height: 20),

              // ======================================================
              // FAQ
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
              // CONTACT SUPPORT
              // ======================================================

              _sectionTitle('Need More Help?'),

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
                      'Chat with Support',
                      'Get help with your issue',
                          () => _toast('Opening Support Chat'),
                    ),

                    const Divider(height: 22),

                    _supportOption(
                      Icons.email_outlined,
                      'Email Support',
                      'Send us your question',
                          () => _toast('Opening Email Support'),
                    ),

                    const Divider(height: 22),

                    _supportOption(
                      Icons.report_problem_outlined,
                      'Report a Problem',
                      'Tell us what went wrong',
                          () => _toast('Report Problem'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ======================================================
              // SUPPORT NOTE
              // ======================================================

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: softPurple,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: primary,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'When contacting support, keep your order details or relevant account information ready so your issue can be handled more easily.',
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
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E1E2D),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: softPurple,
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
              style: const TextStyle(
                color: Color(0xFF1E1E2D),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF7E8CA0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: softPurple,
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: const TextStyle(
                          color: Color(0xFF1E1E2D),
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
                  style: const TextStyle(
                    color: Color(0xFF7E8CA0),
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
          style: const TextStyle(
            color: Color(0xFF1E1E2D),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                color: Color(0xFF7E8CA0),
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
              color: softPurple,
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
                  style: const TextStyle(
                    color: Color(0xFF1E1E2D),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7E8CA0),
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9EA8B6),
            size: 21,
          ),
        ],
      ),
    );
  }
}