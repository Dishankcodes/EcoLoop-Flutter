import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ArtistFAQ extends StatefulWidget {
  const ArtistFAQ({super.key});

  @override
  State<ArtistFAQ> createState() => _ArtistFAQState();
}

class _ArtistFAQState extends State<ArtistFAQ> {
  final List<Map<String, String>> faqs = [
    {
      'question': 'What is EcoLoop?',
      'answer':
          'EcoLoop is a community marketplace where users and artists can sell, buy, reuse and donate unused items.',
    },
    {
      'question': 'How do I sell a product as an artist?',
      'answer':
          'Open Add Product, upload your product photos, enter the product details, choose a category and condition, set your price and publish the product.',
    },
    {
      'question': 'How can I manage my products?',
      'answer':
          'Open My Products from your artist dashboard. From there you can view your products, edit product information and manage your listings.',
    },
    {
      'question': 'Can I edit my product after publishing?',
      'answer':
          'Yes. Open My Products, select the product and choose the edit option to update its available product information.',
    },
    {
      'question': 'How do I receive customer orders?',
      'answer':
          'When a customer purchases one of your products, the order will appear in your Selling Orders section where you can view the order details and manage its status.',
    },
    {
      'question': 'Can I manage my selling order status?',
      'answer':
          'Yes. Open Selling Orders, select an order and use the order status section to manage the available order stages.',
    },
    {
      'question': 'Can an artist buy products too?',
      'answer':
          'Yes. Artists can also use the Marketplace to discover and purchase products and materials available on EcoLoop.',
    },
    {
      'question': 'Can an artist buy from another artist?',
      'answer':
          'Yes. Artists can purchase products from both users and other artists when those products are available in the marketplace.',
    },
    {
      'question': 'Can users follow my artist profile?',
      'answer':
          'Yes. Users can follow artist profiles and view their available products and profile information.',
    },
    {
      'question': 'Where can I see my reviews?',
      'answer':
          'Your product reviews can be accessed from the Reviews section of your artist account.',
    },
    {
      'question': 'Where can I see my earnings?',
      'answer':
          'Your available earnings and sales-related information can be viewed from the relevant earnings section of your artist account.',
    },
    {
      'question': 'Can I update my artist profile?',
      'answer':
          'Yes. Open your artist profile and choose Edit Profile to update information such as your name, bio, skills, location and profile image.',
    },
    {
      'question': 'Can I change my email from Edit Profile?',
      'answer':
          'No. The artist email is treated as account information and is not part of the regular profile editing fields.',
    },
    {
      'question': 'How can I contact EcoLoop support?',
      'answer':
          'Open Help & Support from the More menu to access the available support options.',
    },
  ];

  String searchQuery = '';

  List<Map<String, String>> get filteredFaqs {
    if (searchQuery.trim().isEmpty) {
      return faqs;
    }

    final query = searchQuery.toLowerCase().trim();

    return faqs.where((faq) {
      final question = faq['question']?.toLowerCase() ?? '';
      final answer = faq['answer']?.toLowerCase() ?? '';

      return question.contains(query) || answer.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredFaqs;

    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: AppBar(
        backgroundColor: ArtistColors.surface,
        foregroundColor: ArtistColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Frequently Asked Questions',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: ArtistColors.textPrimary,
          ),
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
                    separatorBuilder: (_, __) {
                      return const SizedBox(height: 8);
                    },
                    itemBuilder: (_, index) {
                      return _buildQuestion(items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // INTRO
  // ===========================================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      color: ArtistColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 17),
      child: Row(
        children: [
          const Icon(
            Icons.help_outline_rounded,
            color: ArtistColors.primary,
            size: 25,
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              'Find quick answers about selling, buying and managing your artist account on EcoLoop.',
              style: ArtistTextStyles.body.copyWith(
                fontSize: 12,
                height: 1.4,
                color: ArtistColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  Widget _buildSearch() {
    return Container(
      color: ArtistColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 3, 16, 15),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },

        style: ArtistTextStyles.body.copyWith(
          fontSize: 12,
          color: ArtistColors.textPrimary,
        ),

        decoration: InputDecoration(
          hintText: 'Search questions...',

          hintStyle: ArtistTextStyles.body.copyWith(
            fontSize: 12,
            color: ArtistColors.textSecondary,
          ),

          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ArtistColors.textSecondary,
          ),

          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: ArtistColors.textSecondary,
                  ),
                )
              : null,

          filled: true,
          fillColor: ArtistColors.background,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ArtistColors.primary, width: 1),
          ),

          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ===========================================================================
  // QUESTION
  // ===========================================================================

  Widget _buildQuestion(Map<String, String> faq) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: ArtistColors.border),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),

          childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 16),

          iconColor: ArtistColors.primary,
          collapsedIconColor: ArtistColors.textSecondary,

          title: Text(
            faq['question'] ?? '',
            style: ArtistTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ArtistColors.textPrimary,
            ),
          ),

          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                faq['answer'] ?? '',
                style: ArtistTextStyles.body.copyWith(
                  fontSize: 11,
                  height: 1.55,
                  color: ArtistColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY
  // ===========================================================================

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
                color: ArtistColors.surfaceSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 35,
                color: ArtistColors.primary,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              'No questions found',
              style: ArtistTextStyles.title.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ArtistColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Try searching with a different keyword.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body.copyWith(
                fontSize: 11,
                color: ArtistColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
