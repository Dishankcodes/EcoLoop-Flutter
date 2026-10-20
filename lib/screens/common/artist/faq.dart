import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ArtistFAQ extends StatefulWidget {
  const ArtistFAQ({super.key});

  @override
  State<ArtistFAQ> createState() => _ArtistFAQState();
}

class _ArtistFAQState extends State<ArtistFAQ> {
  final List<Map<String, String>> faqs = const [
    {
      'question': 'What is EcoLoop?',
      'answer':
          'EcoLoop is a community marketplace for buying, selling and donating '
          'reusable items. ReMakers can showcase their creative work and list '
          'products for interested buyers.',
    },
    {
      'question': 'How do I sell a product?',
      'answer':
          'Open Add Product, provide the product details and images, choose '
          'the available category, enter the price and quantity, and publish '
          'the listing. Make sure all information is accurate.',
    },
    {
      'question': 'How can I manage my products?',
      'answer':
          'Open My Products to view and manage your existing listings. The '
          'available edit and stock-management actions depend on the product '
          'and the options provided in the app.',
    },
    {
      'question': 'Can I edit a product after publishing?',
      'answer':
          'Use the edit option for the relevant listing, where available. '
          'Update its description, images, price or other editable fields '
          'and save your changes.',
    },
    {
      'question': 'Where can I find customer orders?',
      'answer':
          'Open Selling Orders or the relevant Orders section to view orders '
          'associated with your products. Open an order to inspect its '
          'available details and status.',
    },
    {
      'question': 'How do I update an order?',
      'answer':
          'Open the relevant selling order and use the status actions shown '
          'in the app. Only select a status that accurately reflects the '
          'order progress. Exact cancellation, return and refund rules are '
          'Pending confirmation.',
    },
    {
      'question': 'Can ReMakers buy products too?',
      'answer':
          'Yes. ReMakers can browse the marketplace and purchase products '
          'listed by other participating users or ReMakers.',
    },
    {
      'question': 'Can people follow my profile?',
      'answer':
          'The app includes profile-following features. Public profile '
          'information and published listings may be visible to other users '
          'and the public.',
    },
    {
      'question': 'Where can I see my reviews?',
      'answer':
          'Open the Reviews or relevant profile section available in your '
          'account to view feedback displayed for your work or products. '
          'Reviews should reflect genuine experiences.',
    },
    {
      'question': 'Where can I see my earnings?',
      'answer':
          'Use the available earnings or analytics section. Figures shown '
          'are app records and do not by themselves confirm that money has '
          'been collected or settled. Payout methods and settlement timelines '
          'are Pending unless explicitly provided in the live service.',
    },
    {
      'question': 'How do custom-service requests work?',
      'answer':
          'Users may submit a project brief, budget and reference materials. '
          'Where custom-service responses are available, you can review the '
          'request and send a proposal. Agree on scope, price, timeline, '
          'revisions and delivery or collection arrangements before starting.',
    },
    {
      'question': 'Can I use customer reference images in my portfolio?',
      'answer':
          'Only use material you have permission to use. Customer reference '
          'images and private project details must not be republished in '
          'your portfolio without appropriate permission.',
    },
    {
      'question': 'Does EcoLoop currently support online payments?',
      'answer':
          'Current payment arrangements are COD and/or offline only. Online '
          'payment gateway processing is not active. Follow the payment '
          'arrangement shown in the actual order flow.',
    },
    {
      'question': 'Can I change my registered email?',
      'answer':
          'The current profile workflow does not offer email editing from '
          'the edit-profile screen. A separate email-change process is '
          'Pending confirmation. Contact support if you need assistance.',
    },
    {
      'question': 'How can I request account deletion?',
      'answer':
          'Contact ecoloopp2026@gmail.com. Account closure may deactivate '
          'your account without erasing all associated orders, reviews or '
          'stored media. Complete deletion and retention timelines are '
          'Pending confirmation.',
    },
    {
      'question': 'How do I contact EcoLoop?',
      'answer':
          'Email ecoloopp2026@gmail.com. Live chat and phone support should '
          'not be considered available unless EcoLoop officially activates '
          'those channels.',
    },
  ];

  final Set<int> _expandedItems = <int>{};

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
          'Frequently Asked Questions',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: ArtistColors.primary,
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.help_outline_rounded, color: Colors.white, size: 30),
                SizedBox(height: 12),
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Find answers about your ReMaker profile, products, orders, '
                  'custom services and account.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ReMaker Help',
            style: ArtistTextStyles.title.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 10),
          ...List.generate(faqs.length, (index) {
            final faq = faqs[index];
            final expanded = _expandedItems.contains(index);

            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                color: ArtistColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ArtistColors.border),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: PageStorageKey<String>('artist-faq-$index'),
                  initiallyExpanded: expanded,
                  onExpansionChanged: (value) {
                    setState(() {
                      if (value) {
                        _expandedItems.add(index);
                      } else {
                        _expandedItems.remove(index);
                      }
                    });
                  },
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 3,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
                  iconColor: ArtistColors.primary,
                  collapsedIconColor: ArtistColors.textSecondary,
                  title: Text(
                    faq['question']!,
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq['answer']!,
                        style: ArtistTextStyles.body.copyWith(
                          height: 1.6,
                          color: ArtistColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: ArtistColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Still need help?',
                  style: ArtistTextStyles.title.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'For account, order, privacy or other support concerns, '
                  'contact EcoLoop by email.',
                  style: ArtistTextStyles.body.copyWith(
                    height: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'ecoloopp2026@gmail.com',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    color: ArtistColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
