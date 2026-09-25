import 'package:flutter/material.dart';

import '../../app_theme/artist/artist_colors.dart';
import '../../app_theme/artist/artist_text_styles.dart';
import '../../app_theme/artist/artist_theme.dart';

class ArtistDashboard extends StatelessWidget {
  const ArtistDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ArtistTheme.lightTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: ArtistColors.background,
            appBar: AppBar(
              title: const Text('Artist Dashboard'),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: ArtistColors.primary.withOpacity(0.08),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 20,
                      color: ArtistColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 24),

                    _buildStatsGrid(),
                    const SizedBox(height: 28),

                    _buildSectionHeader(
                      title: 'Quick Actions',
                      action: 'View all',
                    ),
                    const SizedBox(height: 14),

                    _buildQuickActions(),
                    const SizedBox(height: 28),

                    _buildSectionHeader(
                      title: 'Recent Orders',
                      action: 'View orders',
                    ),
                    const SizedBox(height: 14),

                    _buildOrdersCard(),
                    const SizedBox(height: 28),

                    _buildSectionHeader(
                      title: 'Your Products',
                      action: 'Manage',
                    ),
                    const SizedBox(height: 14),

                    _buildProductsCard(),
                    const SizedBox(height: 28),

                    _buildSectionHeader(
                      title: 'Performance',
                      action: 'View analytics',
                    ),
                    const SizedBox(height: 14),

                    _buildPerformanceCard(),
                    const SizedBox(height: 28),

                    _buildSectionHeader(title: 'Theme Preview'),
                    const SizedBox(height: 14),

                    _buildTypographyPreview(),
                    const SizedBox(height: 20),

                    _buildButtonsPreview(),
                    const SizedBox(height: 20),

                    _buildInputsPreview(),
                    const SizedBox(height: 20),

                    _buildStatusPreview(),
                    const SizedBox(height: 20),

                    _buildColorsPreview(),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add_rounded),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArtistColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.palette_outlined,
              color: ArtistColors.accent,
              size: 27,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, Artist',
                  style: ArtistTextStyles.title.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Manage your creations and grow your store.',
                  style: ArtistTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white54,
            size: 16,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      // Lower aspect ratio allocates more height per card (Width / Height)
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          icon: Icons.shopping_bag_outlined,
          title: 'Total Orders',
          value: '128',
          subtitle: '+12 this month',
          iconColor: ArtistColors.primary,
        ),
        _buildStatCard(
          icon: Icons.currency_rupee_rounded,
          title: 'Total Earnings',
          value: '₹42.8K',
          subtitle: '+8.4% this month',
          iconColor: ArtistColors.success,
        ),
        _buildStatCard(
          icon: Icons.inventory_2_outlined,
          title: 'Products',
          value: '24',
          subtitle: '4 low in stock',
          iconColor: ArtistColors.secondary,
        ),
        _buildStatCard(
          icon: Icons.star_outline_rounded,
          title: 'Rating',
          value: '4.8',
          subtitle: '86 reviews',
          iconColor: ArtistColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color iconColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: ArtistColors.textMuted,
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: ArtistTextStyles.title.copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArtistTextStyles.caption,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ArtistTextStyles.small.copyWith(
                color: ArtistColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({required String title, String? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: ArtistTextStyles.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action,
              style: ArtistTextStyles.caption.copyWith(
                color: ArtistColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.add_box_outlined,
            title: 'Add Product',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.bar_chart_outlined,
            title: 'Analytics',
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String title}) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ArtistColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ArtistColors.primary, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArtistTextStyles.small.copyWith(
                  color: ArtistColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ORDERS
  // ============================================================

  Widget _buildOrdersCard() {
    return Card(
      child: Column(
        children: [
          _buildOrderItem(
            orderId: '#RO1024',
            product: 'Upcycled Glass Vase',
            customer: 'Rahul Shah',
            amount: '₹850',
            status: 'Delivered',
            statusColor: ArtistColors.success,
          ),
          const Divider(height: 1),
          _buildOrderItem(
            orderId: '#RO1023',
            product: 'Recycled Canvas Bag',
            customer: 'Priya Patel',
            amount: '₹620',
            status: 'Processing',
            statusColor: ArtistColors.warning,
          ),
          const Divider(height: 1),
          _buildOrderItem(
            orderId: '#RO1022',
            product: 'Handmade Bottle Lamp',
            customer: 'Aarav Mehta',
            amount: '₹1,250',
            status: 'Shipped',
            statusColor: ArtistColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem({
    required String orderId,
    required String product,
    required String customer,
    required String amount,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: ArtistColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.bodyMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '$orderId • $customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: ArtistTextStyles.bodyMedium),
              const SizedBox(height: 4),
              _buildStatusBadge(text: status, color: statusColor),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCTS
  // ============================================================

  Widget _buildProductsCard() {
    return Card(
      child: Column(
        children: [
          _buildProductItem(
            name: 'Upcycled Glass Vase',
            category: 'Home Decor',
            price: '₹850',
            stock: '12 in stock',
            stockColor: ArtistColors.success,
          ),
          const Divider(height: 1),
          _buildProductItem(
            name: 'Recycled Canvas Bag',
            category: 'Accessories',
            price: '₹620',
            stock: '5 in stock',
            stockColor: ArtistColors.warning,
          ),
          const Divider(height: 1),
          _buildProductItem(
            name: 'Bottle Lamp',
            category: 'Lighting',
            price: '₹1,250',
            stock: '2 in stock',
            stockColor: ArtistColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem({
    required String name,
    required String category,
    required String price,
    required String stock,
    required Color stockColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: ArtistColors.textMuted,
              size: 22,
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
                  style: ArtistTextStyles.bodyMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: ArtistTextStyles.bodyMedium),
              const SizedBox(height: 4),
              Text(
                stock,
                style: ArtistTextStyles.small.copyWith(color: stockColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERFORMANCE
  // ============================================================

  Widget _buildPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales overview',
                        style: ArtistTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('Last 7 days', style: ArtistTextStyles.small),
                    ],
                  ),
                ),
                Text(
                  '₹8,420',
                  style: ArtistTextStyles.title.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildChartBar('Mon', 0.42),
                  _buildChartBar('Tue', 0.65),
                  _buildChartBar('Wed', 0.48),
                  _buildChartBar('Thu', 0.78),
                  _buildChartBar('Fri', 0.55),
                  _buildChartBar('Sat', 0.90),
                  _buildChartBar('Sun', 0.68),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartBar(String day, double value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: value,
              child: Container(
                width: 18,
                decoration: BoxDecoration(
                  color: ArtistColors.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(day, style: ArtistTextStyles.small),
      ],
    );
  }

  // ============================================================
  // TYPOGRAPHY PREVIEW
  // ============================================================

  Widget _buildTypographyPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Typography', style: ArtistTextStyles.title),
            const SizedBox(height: 18),

            Text('Heading 26 / Bold', style: ArtistTextStyles.heading),
            const SizedBox(height: 12),

            Text('Title 20 / Semi Bold', style: ArtistTextStyles.title),
            const SizedBox(height: 12),

            Text('Body 14 / Regular', style: ArtistTextStyles.body),
            const SizedBox(height: 12),

            Text('Body Medium 14 / Medium', style: ArtistTextStyles.bodyMedium),
            const SizedBox(height: 12),

            Text('Caption 12', style: ArtistTextStyles.caption),
            const SizedBox(height: 12),

            Text('Small 11', style: ArtistTextStyles.small),
            const SizedBox(height: 12),

            Text('Label 14 / Semi Bold', style: ArtistTextStyles.label),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON PREVIEW
  // ============================================================

  Widget _buildButtonsPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buttons', style: ArtistTextStyles.title),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: const Text('Primary Button'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Outlined Button'),
              ),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {},
                child: const Text('Text Button'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INPUT PREVIEW
  // ============================================================

  Widget _buildInputsPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Input Fields', style: ArtistTextStyles.title),
            const SizedBox(height: 16),

            const TextField(
              decoration: InputDecoration(
                labelText: 'Product name',
                hintText: 'Enter product name',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),

            const SizedBox(height: 14),

            const TextField(
              decoration: InputDecoration(
                labelText: 'Category',
                hintText: 'Select category',
                prefixIcon: Icon(Icons.category_outlined),
                suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status & Chips', style: ArtistTextStyles.title),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusBadge(
                  text: 'Delivered',
                  color: ArtistColors.success,
                ),
                _buildStatusBadge(
                  text: 'Processing',
                  color: ArtistColors.warning,
                ),
                _buildStatusBadge(text: 'Shipped', color: ArtistColors.info),
                _buildStatusBadge(text: 'Cancelled', color: ArtistColors.error),
              ],
            ),

            const SizedBox(height: 18),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('Home Decor')),
                Chip(label: Text('Accessories')),
                Chip(label: Text('Upcycled')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: ArtistTextStyles.small.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // COLOR PREVIEW
  // ============================================================

  Widget _buildColorsPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artist Color Palette', style: ArtistTextStyles.title),
            const SizedBox(height: 18),

            _buildColorRow('Primary', ArtistColors.primary, '#270809'),
            _buildColorRow('Secondary', ArtistColors.secondary, '#08271F'),
            _buildColorRow('Accent', ArtistColors.accent, '#C1C8C4'),
            _buildColorRow('Background', ArtistColors.background, '#FAF9F7'),
            _buildColorRow('Surface Soft', ArtistColors.surfaceSoft, '#F4F1EF'),
            _buildColorRow('Text Primary', ArtistColors.textPrimary, '#211C1C'),
            _buildColorRow(
              'Text Secondary',
              ArtistColors.textSecondary,
              '#4F4848',
            ),
            _buildColorRow('Text Muted', ArtistColors.textMuted, '#756D6D'),
            _buildColorRow('Border', ArtistColors.border, '#E5E1DF'),
            _buildColorRow('Success', ArtistColors.success, '#2F6B4F'),
            _buildColorRow('Warning', ArtistColors.warning, '#9A6A24'),
            _buildColorRow('Error', ArtistColors.error, '#E53935'),
            _buildColorRow('Info', ArtistColors.info, '#496B70'),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(String name, Color color, String hex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ArtistColors.border),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: ArtistTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(hex, style: ArtistTextStyles.small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
