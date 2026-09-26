import 'package:flutter/material.dart';

import '../../app_theme/artist/artist_colors.dart';
import '../../app_theme/artist/artist_text_styles.dart';
import '../../widgets/artist_more_menu.dart';

class ArtistHome extends StatefulWidget {
  const ArtistHome({super.key});

  @override
  State<ArtistHome> createState() => _ArtistHomeState();
}

class _ArtistHomeState extends State<ArtistHome> {
  final _stats = [
    {'title': 'Total Sales', 'count': '56'},
    {'title': 'Total Products', 'count': '12'},
    {'title': 'Orders', 'count': '18'},
    {'title': 'Portfolio Views', 'count': '2,450'},
  ];

  final _overview = [
    {
      'icon': Icons.inventory_2_outlined,
      'title': 'Pending Orders',
      'count': '6',
    },
    {
      'icon': Icons.chat_bubble_outline_rounded,
      'title': 'Unread Messages',
      'count': '3',
    },
    {
      'icon': Icons.shopping_bag_outlined,
      'title': 'Low Stock Items',
      'count': '2',
    },
  ];

  final _quickActions = [
    {'icon': Icons.add_rounded, 'label': 'Add Product'},
    {'icon': Icons.category_outlined, 'label': 'Materials'},
    {'icon': Icons.assignment_outlined, 'label': 'Orders'},
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Earnings'},
  ];

  void _toast(String title) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$title clicked',
            style: ArtistTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.primary,
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

      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 20),

              _buildEarningsCard(),

              const SizedBox(height: 16),

              _buildStats(),

              const SizedBox(height: 28),

              _sectionTitle('Overview'),

              const SizedBox(height: 12),

              _buildOverview(),

              const SizedBox(height: 28),

              _sectionTitle('Quick Actions'),

              const SizedBox(height: 12),

              _buildQuickActions(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Hi, Creative Studio',
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.title.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text('👋', style: TextStyle(fontSize: 20)),
            ],
          ),
        ),

        const ArtistMoreMenu(),
      ],
    );
  }

  // EARNINGS CARD

  Widget _buildEarningsCard() {
    return InkWell(
      onTap: () => _toast('Total Earnings'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ArtistColors.surfaceSoft, ArtistColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ArtistColors.border),
          boxShadow: [
            BoxShadow(
              color: ArtistColors.primary.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Earnings',
                    style: ArtistTextStyles.label.copyWith(
                      color: ArtistColors.primary,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '₹24,850',
                    style: ArtistTextStyles.heading.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ArtistColors.textPrimary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+12%',
                          style: ArtistTextStyles.caption.copyWith(
                            color: ArtistColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      Text(
                        'this month',
                        style: ArtistTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ArtistColors.primary, ArtistColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: ArtistColors.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STATS

  Widget _buildStats() {
    return Row(
      children: _stats.map((stat) {
        final bool isLast = stat == _stats.last;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 10),
            child: InkWell(
              onTap: () => _toast(stat['title']!),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  color: ArtistColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ArtistColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      stat['title']!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.small.copyWith(
                        fontSize: 10.5,
                        color: ArtistColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      stat['count']!,
                      style: ArtistTextStyles.title.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: ArtistColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // OVERVIEW

  Widget _buildOverview() {
    return Container(
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_overview.length, (index) {
          final item = _overview[index];

          final bool isFirst = index == 0;
          final bool isLast = index == _overview.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () => _toast(item['title'] as String),
                borderRadius: BorderRadius.vertical(
                  top: isFirst ? const Radius.circular(20) : Radius.zero,
                  bottom: isLast ? const Radius.circular(20) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ArtistColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 18,
                          color: ArtistColors.primary,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          item['title'] as String,
                          style: ArtistTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ArtistColors.light.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['count'] as String,
                          style: ArtistTextStyles.caption.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: ArtistColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: ArtistColors.border),
                ),
            ],
          );
        }),
      ),
    );
  }

  // QUICK ACTIONS

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _quickActions.map((action) {
        return InkWell(
          onTap: () => _toast(action['label'] as String),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 80,
            height: 82,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ArtistColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action['icon'] as IconData,
                  color: ArtistColors.primary,
                  size: 24,
                ),

                const SizedBox(height: 8),

                Text(
                  action['label'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.small.copyWith(
                    fontSize: 11,
                    color: ArtistColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // SECTION TITLE

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: ArtistTextStyles.title.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }
}
