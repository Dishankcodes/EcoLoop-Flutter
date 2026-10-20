import 'package:flutter/material.dart';
import '../../app_theme/user/app_colors.dart';

class AboutEcoLoop extends StatelessWidget {
  const AboutEcoLoop({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'About EcoLoop',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            _buildHero(),
            _section(
              title: 'Our Mission',
              child: const Text(
                'EcoLoop is a community marketplace designed to help people '
                'buy, sell and donate reusable items. It also connects users '
                'with ReMakers who showcase creative work and products. '
                'Our goal is to help useful items find a new purpose and '
                'encourage more thoughtful consumption.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.65,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            _buildHowItWorks(),
            _buildValues(),
            _buildCommunity(),
            _buildContact(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(25, 28, 25, 30),
      child: Column(
        children: [
          Container(
            height: 82,
            width: 82,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(27),
            ),
            child: const Icon(
              Icons.eco_rounded,
              size: 46,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'EcoLoop',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Give unused things a new life.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Buy, sell, donate, reuse and discover creative work.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return _section(
      title: 'How EcoLoop Works',
      child: Column(
        children: [
          _step(
            '01',
            Icons.search_rounded,
            'Discover Products',
            'Browse marketplace listings and review product details, '
                'prices and seller information.',
          ),
          _step(
            '02',
            Icons.shopping_bag_outlined,
            'Buy an Item',
            'Choose a product, review checkout information and place '
                'an order using the payment arrangement shown in the app.',
          ),
          _step(
            '03',
            Icons.sell_outlined,
            'Sell Your Items',
            'Create a listing with accurate photos, descriptions, '
                'category, quantity and price.',
          ),
          _step(
            '04',
            Icons.volunteer_activism_outlined,
            'Donate Items',
            'Submit items through the donation flow. Acceptance, '
                'pickup availability and rewards are subject to eligibility '
                'and the actual service offered.',
          ),
          _step(
            '05',
            Icons.palette_outlined,
            'Explore ReMaker Creations',
            'Discover ReMaker profiles, products and creative portfolios.',
          ),
        ],
      ),
    );
  }

  Widget _step(String number, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValues() {
    return _section(
      title: 'What We Believe In',
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          _tag(Icons.recycling, 'Reuse'),
          _tag(Icons.eco_outlined, 'Sustainability'),
          _tag(Icons.people_outline, 'Community'),
          _tag(Icons.favorite_border, 'Responsibility'),
          _tag(Icons.auto_awesome_outlined, 'Creativity'),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunity() {
    return _section(
      title: 'Built for the Community',
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          children: [
            Icon(Icons.groups_outlined, color: AppColors.primary, size: 25),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'Reuse can help reduce waste. Every listing, purchase '
                'and eligible donation is an opportunity to keep useful '
                'items in circulation.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContact() {
    return _section(
      title: 'Contact EcoLoop',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'For questions about your account, orders, donations or privacy, '
            'contact our support email.',
            style: TextStyle(
              fontSize: 12,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          const SelectableText(
            'ecoloopp2026@gmail.com',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Minimum age, formal operator details and the formal grievance '
            'procedure: Pending confirmation.',
            style: TextStyle(
              fontSize: 10,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
}
