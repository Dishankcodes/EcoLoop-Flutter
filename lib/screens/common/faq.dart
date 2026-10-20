import 'package:flutter/material.dart';

import '../../app_theme/user/app_colors.dart';

class FAQ extends StatefulWidget {
  const FAQ({super.key});

  @override
  State<FAQ> createState() => _FAQState();
}

class _FAQState extends State<FAQ> {
  final List<Map<String, String>> faqs = const [
    {
      'question': 'What is EcoLoop?',
      'answer':
          'EcoLoop is a community marketplace where users can buy, sell, '
          'reuse and donate items, and explore products and portfolios '
          'published by ReMakers.',
    },
    {
      'question': 'How do I sell an item?',
      'answer':
          'Open Add Product, upload item photos, enter accurate details, '
          'choose the available category and condition, set the price and '
          'quantity, and publish the listing.',
    },
    {
      'question': 'Can I donate an item?',
      'answer':
          'Use the Donate an Item flow to submit a donation request. '
          'Acceptance, eligibility, collection and any reward depend on '
          'the actual donation process. Rewards are not guaranteed.',
    },
    {
      'question': 'Is pickup available for donated items?',
      'answer':
          'Pickup availability may depend on location, item eligibility '
          'and the options offered for your donation. A pickup is not '
          'guaranteed until it is confirmed in the app or by EcoLoop.',
    },
    {
      'question': 'How do I buy an item?',
      'answer':
          'Open Marketplace, select a product, review its details and '
          'seller information, then continue through the available '
          'checkout flow.',
    },
    {
      'question': 'What payment methods are available?',
      'answer':
          'Current arrangements are Cash on Delivery (COD) and/or offline '
          'payment only. Online payment gateway processing is not active. '
          'Follow the payment instructions shown in your order.',
    },
    {
      'question': 'Can I edit my listing?',
      'answer':
          'Open Profile and My Listings, select the relevant listing, '
          'and use its available edit option. The fields you can edit '
          'depend on the listing and current app workflow.',
    },
    {
      'question': 'Can I message a seller through EcoLoop?',
      'answer':
          'Do not assume in-app messaging is available. The previous FAQ '
          'identified messaging as not yet connected to the backend. '
          'Use only contact options actually provided by the app.',
    },
    {
      'question': 'What happens after I place an order?',
      'answer':
          'Your order should appear under Orders and Buying Orders where '
          'the current workflow supports it. Open the order to see the '
          'details and status information currently available.',
    },
    {
      'question': 'Can I cancel an order?',
      'answer':
          'Cancellation availability may depend on order status and the '
          'available actions. The complete cancellation, return and refund '
          'policy is Pending confirmation. Contact support for assistance.',
    },
    {
      'question': 'Can I track an order?',
      'answer':
          'Open your order and check the available tracking or status '
          'information. The detail shown depends on the information '
          'recorded by the current order workflow.',
    },
    {
      'question': 'When can I write a review?',
      'answer':
          'Reviews should reflect a genuine purchase or experience. '
          'Use the review option when it is available for an eligible '
          'order. Do not submit fake or misleading reviews.',
    },
    {
      'question': 'How does the wishlist work?',
      'answer':
          'Use the wishlist option on a product to save it for later. '
          'Saved items are associated with your account according to '
          'the current app functionality.',
    },
    {
      'question': 'What are ReMakers?',
      'answer':
          'ReMakers are creators who can showcase their work and portfolios '
          'and publish products through the platform. Custom-service '
          'features may also allow them to respond to project requests.',
    },
    {
      'question': 'How do custom services work?',
      'answer':
          'Where the custom-service feature is available, you can submit '
          'a project brief, budget and reference material and review '
          'proposals. Agree on scope, price, timeline, revisions and '
          'delivery before work starts.',
    },
    {
      'question': 'Can I delete my account?',
      'answer':
          'Contact ecoloopp2026@gmail.com to request account assistance. '
          'Current account closure may deactivate the account without '
          'erasing all related orders, reviews or stored media. Complete '
          'deletion and retention timelines are Pending.',
    },
    {
      'question': 'How is my information used?',
      'answer':
          'Information may be used for account access, listings, orders, '
          'donations, custom services, support and other features you use. '
          'Read the Privacy Policy for more information and unresolved '
          'implementation details.',
    },
    {
      'question': 'How do I contact EcoLoop support?',
      'answer':
          'Email ecoloopp2026@gmail.com. Phone support, live chat and '
          'formal grievance response timelines are not confirmed as '
          'available services.',
    },
  ];

  String searchQuery = '';

  List<Map<String, String>> get filteredFaqs {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return faqs;
    }

    return faqs.where((faq) {
      return faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredFaqs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildIntro(),
          _buildSearch(),
          Expanded(
            child: items.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) => _buildQuestion(items[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: AppColors.primary,
              size: 29,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Search for answers about products, orders, donations '
                    'and your account.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search questions...',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
          ),
          suffixIcon: searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () => setState(() => searchQuery = ''),
                  icon: const Icon(Icons.close_rounded),
                ),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(
              color: AppColors.accent.withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(Map<String, String> faq) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 17),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            faq['question']!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq['answer']!,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 75,
              width: 75,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 35,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'No questions found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching with a different keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
