import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';

class Rewards extends StatefulWidget {
  const Rewards({super.key});

  @override
  State<Rewards> createState() => _RewardsState();
}

class _RewardsState extends State<Rewards> {
  bool _isLoading = false;
  bool _hasError = false;

  // TEMPORARY UI STATE

  //
  // These values are intentionally kept at zero until the actual Rewards
  // endpoint from Google Apps Script is connected.
  //
  // DO NOT replace these with guessed API calls.
  //
  // Once Code.gs is provided, these values will come from the real backend.

  int _ecoPoints = 0;
  int _pointsEarned = 0;
  int _pointsUsed = 0;

  final List<RewardHistoryItem> _history = [];

  // REWARD MILESTONE

  int get _nextMilestone {
    if (_ecoPoints < 500) {
      return 500;
    }

    if (_ecoPoints < 1000) {
      return 1000;
    }

    if (_ecoPoints < 2000) {
      return 2000;
    }

    if (_ecoPoints < 5000) {
      return 5000;
    }

    return ((_ecoPoints ~/ 1000) + 1) * 1000;
  }

  int get _pointsToNextMilestone {
    final remaining = _nextMilestone - _ecoPoints;
    return remaining < 0 ? 0 : remaining;
  }

  double get _milestoneProgress {
    if (_nextMilestone <= 0) {
      return 0;
    }

    final progress = _ecoPoints / _nextMilestone;

    if (progress < 0) {
      return 0;
    }

    if (progress > 1) {
      return 1;
    }

    return progress;
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('Rewards', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _loadRewards,
          child: _buildBody(),
        ),
      ),
    );
  }

  // BODY

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntro(),

          const SizedBox(height: 18),

          _buildPointsCard(),

          const SizedBox(height: 14),

          _buildStats(),

          const SizedBox(height: 22),

          _buildMilestoneCard(),

          const SizedBox(height: 24),

          _buildSectionTitle(
            title: 'Reward History',
            action: _history.isNotEmpty
                ? TextButton(
                    onPressed: _showFullHistory,
                    child: const Text('View All'),
                  )
                : null,
          ),

          const SizedBox(height: 10),

          _buildHistory(),

          const SizedBox(height: 24),

          _buildSectionTitle(title: 'How You Earn Points'),

          const SizedBox(height: 10),

          _buildWaysToEarn(),

          const SizedBox(height: 24),

          _buildInfoCard(),
        ],
      ),
    );
  }

  // INTRO

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Eco Rewards', style: AppTextStyles.heading),
        const SizedBox(height: 5),
        Text(
          'Every sustainable action helps you earn Eco Points and make a positive impact.',
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  // ECO POINTS CARD

  Widget _buildPointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 19),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.redeem_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Eco Points Balance',
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco_rounded, color: AppColors.accent, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'ECOPLUS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$_ecoPoints',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  'points',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Text(
            _ecoPoints == 0
                ? 'Start earning Eco Points through sustainable actions.'
                : 'Available Eco Points',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  // STATS

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up_rounded,
            title: 'Points Earned',
            value: '$_pointsEarned',
            iconBackground: AppColors.light,
            iconColor: AppColors.success,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _StatCard(
            icon: Icons.redeem_outlined,
            title: 'Points Used',
            value: '$_pointsUsed',
            iconBackground: AppColors.light,
            iconColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  // MILESTONE

  Widget _buildMilestoneCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Milestone',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_nextMilestone Eco Points',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: _milestoneProgress,
              backgroundColor: AppColors.light,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondary,
              ),
            ),
          ),

          const SizedBox(height: 9),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_ecoPoints / $_nextMilestone',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _pointsToNextMilestone == 0
                    ? 'Milestone reached'
                    : '${_pointsToNextMilestone} more',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SECTION TITLE

  Widget _buildSectionTitle({required String title, Widget? action}) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppTextStyles.title.copyWith(fontSize: 17)),
        ),
        if (action != null) action,
      ],
    );
  }

  // HISTORY

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return _buildEmptyHistory();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.40)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _history.length > 5 ? 5 : _history.length,
        separatorBuilder: (_, __) {
          return Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Divider(
              height: 1,
              color: AppColors.accent.withOpacity(0.20),
            ),
          );
        },
        itemBuilder: (context, index) {
          return _buildHistoryItem(_history[index]);
        },
      ),
    );
  }

  Widget _buildHistoryItem(RewardHistoryItem item) {
    final bool isEarned = item.type == RewardHistoryType.earned;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEarned
                  ? Icons.add_circle_outline_rounded
                  : Icons.redeem_outlined,
              color: isEarned ? AppColors.success : AppColors.primary,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),

                const SizedBox(height: 3),

                Text(
                  item.date,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            isEarned ? '+${item.points}' : '-${item.points}',
            style: AppTextStyles.body.copyWith(
              color: isEarned ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.40)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),

          const SizedBox(height: 13),

          Text(
            'No Reward Activity Yet',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Your Eco Points activity will appear here once you start earning or using points.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }

  // WAYS TO EARN

  Widget _buildWaysToEarn() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.40)),
      ),
      child: Column(
        children: [
          _EarnItem(
            icon: Icons.volunteer_activism_outlined,
            title: 'Donate Items',
            subtitle: 'Give unused items a new life.',
          ),

          _divider(),

          _EarnItem(
            icon: Icons.sell_outlined,
            title: 'Sell Products',
            subtitle: 'Keep products in circulation.',
          ),

          _divider(),

          _EarnItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Buy & Reuse',
            subtitle: 'Choose reusable products.',
          ),

          _divider(),

          _EarnItem(
            icon: Icons.eco_outlined,
            title: 'Sustainable Actions',
            subtitle: 'Participate in eligible EcoLoop activities.',
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 69),
      child: Divider(height: 1, color: AppColors.accent.withOpacity(0.20)),
    );
  }

  // INFO CARD

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 21,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Eco Points, reward history and eligible activities will be synchronized with your EcoLoop account once the Rewards backend is connected.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LOADING

  Widget _buildLoadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      children: [
        _skeleton(height: 30, width: 210),

        const SizedBox(height: 9),

        _skeleton(height: 18, width: double.infinity),

        const SizedBox(height: 18),

        _skeleton(height: 205, width: double.infinity),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _skeleton(height: 110, width: double.infinity)),
            const SizedBox(width: 10),
            Expanded(child: _skeleton(height: 110, width: double.infinity)),
          ],
        ),

        const SizedBox(height: 14),

        _skeleton(height: 125, width: double.infinity),

        const SizedBox(height: 20),

        _skeleton(height: 180, width: double.infinity),
      ],
    );
  }

  Widget _skeleton({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
    );
  }

  // ERROR

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 30),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 31,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Unable to Load Rewards',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),

        const SizedBox(height: 6),

        Text(
          'Something went wrong while loading your rewards. Please try again.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),

        const SizedBox(height: 18),

        Center(
          child: SizedBox(
            width: 130,
            height: 44,
            child: ElevatedButton(
              onPressed: _loadRewards,
              child: const Text('Try Again'),
            ),
          ),
        ),
      ],
    );
  }

  // BACKEND HOOK

  Future<void> _loadRewards() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    /*
     * BACKEND INTEGRATION TODO
     *
     * Do not add a guessed endpoint here.
     *
     * Once the actual Google Apps Script Code.gs Rewards endpoint is provided,
     * this method will:
     *
     * 1. Get the logged-in user's ID/token.
     * 2. Call the actual Rewards endpoint through ApiManager().
     * 3. Parse the actual response into the Rewards model.
     * 4. Update:
     *      _ecoPoints
     *      _pointsEarned
     *      _pointsUsed
     *      _history
     *
     * The current Flutter Retrofit client does not contain a Rewards method.
     */

    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  // FULL HISTORY

  void _showFullHistory() {
    if (_history.isEmpty) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Text('Reward History', style: AppTextStyles.title),

                const SizedBox(height: 4),

                Text(
                  'Your complete Eco Points activity',
                  style: AppTextStyles.caption,
                ),

                const SizedBox(height: 14),

                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _history.length,
                    separatorBuilder: (_, __) {
                      return const SizedBox(height: 4);
                    },
                    itemBuilder: (context, index) {
                      return _buildHistoryItem(_history[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// STAT CARD

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconBackground;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 2),

          Text(title, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// EARN ITEM

class _EarnItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EarnItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 21),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// REWARD HISTORY MODEL

enum RewardHistoryType { earned, used }

class RewardHistoryItem {
  final String title;
  final String description;
  final int points;
  final String date;
  final RewardHistoryType type;

  const RewardHistoryItem({
    required this.title,
    required this.description,
    required this.points,
    required this.date,
    required this.type,
  });
}
