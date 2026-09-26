import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ProductAnalytics extends StatelessWidget {
  const ProductAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: ArtistColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        title: Text('Product Analytics', style: ArtistTextStyles.title),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Products',
                style: ArtistTextStyles.title.copyWith(fontSize: 17),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _AnalyticsCard(
                      icon: Icons.inventory_2_outlined,
                      value: '12',
                      label: 'Total Products',
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _AnalyticsCard(
                      icon: Icons.visibility_outlined,
                      value: '2,450',
                      label: 'Total Views',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _AnalyticsCard(
                      icon: Icons.shopping_bag_outlined,
                      value: '56',
                      label: 'Total Sales',
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _AnalyticsCard(
                      icon: Icons.favorite_border_rounded,
                      value: '128',
                      label: 'Wishlist Adds',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Performance Overview',
                style: ArtistTextStyles.title.copyWith(fontSize: 17),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ArtistColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: ArtistColors.border),
                ),

                child: Column(
                  children: [
                    _PerformanceRow(
                      label: 'Products Sold',
                      value: '56',
                      icon: Icons.sell_outlined,
                    ),

                    const Divider(height: 24, color: ArtistColors.border),

                    _PerformanceRow(
                      label: 'Pending Orders',
                      value: '6',
                      icon: Icons.pending_actions_outlined,
                    ),

                    const Divider(height: 24, color: ArtistColors.border),

                    _PerformanceRow(
                      label: 'Low Stock Items',
                      value: '2',
                      icon: Icons.warning_amber_outlined,
                    ),

                    const Divider(height: 24, color: ArtistColors.border),

                    _PerformanceRow(
                      label: 'Total Earnings',
                      value: '₹24,850',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Top Products',
                style: ArtistTextStyles.title.copyWith(fontSize: 17),
              ),

              const SizedBox(height: 12),

              _ProductTile(
                name: 'Handmade Terracotta Vase',
                views: '620 views',
                sales: '18 sales',
              ),

              const SizedBox(height: 10),

              _ProductTile(
                name: 'Upcycled Wall Decor',
                views: '485 views',
                sales: '14 sales',
              ),

              const SizedBox(height: 10),

              _ProductTile(
                name: 'Handcrafted Storage Basket',
                views: '310 views',
                sales: '9 sales',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ANALYTICS CARD
// -----------------------------------------------------------------------------

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),

      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),

      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: ArtistColors.primary),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PERFORMANCE ROW
// -----------------------------------------------------------------------------

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: ArtistColors.surfaceSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: ArtistColors.primary),
        ),

        const SizedBox(width: 12),

        Expanded(child: Text(label, style: ArtistTextStyles.bodyMedium)),

        Text(
          value,
          style: ArtistTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: ArtistColors.primary,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// PRODUCT TILE
// -----------------------------------------------------------------------------

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.name,
    required this.views,
    required this.sales,
  });

  final String name;
  final String views;
  final String sales;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Text(views, style: ArtistTextStyles.small),

                    const SizedBox(width: 10),

                    Text(
                      sales,
                      style: ArtistTextStyles.small.copyWith(
                        color: ArtistColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: ArtistColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
