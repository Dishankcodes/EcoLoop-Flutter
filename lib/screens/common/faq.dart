import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';

class FAQ extends StatefulWidget {
  const FAQ({super.key});

  @override
  State<FAQ> createState() => _FAQState();
}

class _FAQState extends State<FAQ> {
  final List<Map<String, String>> faqs = [
    {
      'question': 'What is EcoLoop?',
      'answer':
          'EcoLoop is a community marketplace where users can sell, buy, reuse and donate unused items.',
    },
    {
      'question': 'How do I sell an item?',
      'answer':
          'Open Add Product, upload your item photos, enter the item details, choose a category and condition, set your price and publish the listing.',
    },
    {
      'question': 'Can I donate an item?',
      'answer':
          'Yes. You can use Donate an Item to submit unused items for donation. Eligible donations may also receive an EcoLoop gift or reward.',
    },
    {
      'question': 'Is pickup available for donated items?',
      'answer':
          'EcoLoop is designed to provide free pickup for eligible donated items. Pickup availability may depend on location and donation eligibility.',
    },
    {
      'question': 'How do I buy an item?',
      'answer':
          'Open Marketplace, select an item, review its details and seller information, then choose Buy Now to continue to checkout.',
    },
    {
      'question': 'Can I edit my listing?',
      'answer':
          'Yes. Open Profile → My Listings and select Edit Listing for an active or draft listing.',
    },
    {
      'question': 'How can I contact a seller?',
      'answer':
          'Open the product details and select the seller profile or contact option. Messaging functionality will be connected to the backend later.',
    },
    {
      'question': 'What happens after I purchase something?',
      'answer':
          'Your order will appear under Orders → Buying. You can open the order to view its status, item details, delivery information and payment summary.',
    },
    {
      'question': 'Can I cancel an order?',
      'answer':
          'Cancellation availability depends on the order status and EcoLoop policies.',
    },
    {
      'question': 'How does EcoLoop protect the community?',
      'answer':
          'EcoLoop provides listing information, seller details, reporting options and support tools to encourage safer community transactions.',
    },
  ];

  String searchQuery = '';

  List<Map<String, String>> get filteredFaqs {
    if (searchQuery.trim().isEmpty) {
      return faqs;
    }

    final query = searchQuery.toLowerCase();

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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      return _buildQuestion(items[index]);
                    },
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
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 17),
      child: const Row(
        children: [
          Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 25),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Find quick answers about buying, selling and donating on EcoLoop.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 3, 16, 15),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search questions...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear_rounded),
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQuestion(Map<String, String> faq) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.accent.withOpacity(0.35)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            faq['question']!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
                  height: 1.55,
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
