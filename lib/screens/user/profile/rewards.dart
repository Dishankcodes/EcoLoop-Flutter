import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';

class Rewards extends StatefulWidget {
  const Rewards({super.key});

  @override
  State<Rewards> createState() => _RewardsState();
}

class _RewardsState extends State<Rewards> {
  bool _isLoading = true;
  bool _hasError = false;
  bool _claimingVoucher = false;

  String? _loadError;

  int _ecoPoints = 0;
  int _pointsEarned = 0;
  int _pointsUsed = 0;

  final List<RewardHistoryItem> _history = [];
  List<Map<String, dynamic>> _vouchers = [];

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  // ------------------------------------------------------------
  // MILESTONE CALCULATIONS
  // ------------------------------------------------------------

  int get _nextMilestone {
    if (_ecoPoints < 500) return 500;
    if (_ecoPoints < 1000) return 1000;
    if (_ecoPoints < 2000) return 2000;
    if (_ecoPoints < 5000) return 5000;

    return ((_ecoPoints ~/ 1000) + 1) * 1000;
  }

  int get _pointsToNextMilestone {
    return (_nextMilestone - _ecoPoints).clamp(0, _nextMilestone);
  }

  double get _milestoneProgress {
    if (_nextMilestone <= 0) return 0;

    return (_ecoPoints / _nextMilestone).clamp(0.0, 1.0);
  }

  // ------------------------------------------------------------
  // MAIN BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _loadRewards,
          child: _isLoading
              ? _buildLoadingState()
              : _hasError
              ? _buildErrorState()
              : _buildBody(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 18,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rewards',
            style: AppTextStyles.title.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Earn points. Make an impact.',
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.35),
              ),
            ),
            child: IconButton(
              tooltip: 'Refresh rewards',
              onPressed: _isLoading ? null : _loadRewards,
              icon: Icon(
                Icons.refresh_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // PAGE BODY
  // ------------------------------------------------------------

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth;
        final isDesktop = pageWidth >= 1000;
        final horizontalPadding = pageWidth >= 1500
            ? 36.0
            : pageWidth >= 1000
            ? 28.0
            : 18.0;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            40,
          ),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntro(isDesktop),
                const SizedBox(height: 24),
                _buildPointsCard(),
                const SizedBox(height: 18),
                _buildStats(),
                const SizedBox(height: 32),

                // Full-width desktop layout, in the requested vertical order.
                _buildSectionHeading(
                  'Redeem Eco Points',
                  'Use your points to claim available rewards.',
                ),
                const SizedBox(height: 16),
                _buildVouchers(),
                const SizedBox(height: 30),

                _buildSectionHeading(
                  'Reward History',
                  'Keep track of your points activity.',
                  trailing: _history.isNotEmpty
                      ? TextButton(
                    onPressed: _showFullHistory,
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                _buildHistory(),
                const SizedBox(height: 30),

                _buildMilestoneCard(),
                const SizedBox(height: 30),

                _buildSectionHeading(
                  'How to Earn Points',
                  'Make sustainable choices every day.',
                ),
                const SizedBox(height: 16),
                _buildWaysToEarn(),
                const SizedBox(height: 22),
                _buildInfoCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // INTRO
  // ------------------------------------------------------------

  Widget _buildIntro(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Eco Rewards',
          style: AppTextStyles.heading.copyWith(
            fontSize: isWide ? 33 : 29,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 9),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 570),
          child: Text(
            'Every sustainable action counts. Earn Eco Points by making better choices for people and the planet.',
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              height: 1.7,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // POINTS BALANCE HERO
  // ------------------------------------------------------------

  Widget _buildPointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF174D2B),
            Color(0xFF247443),
            Color(0xFF398B54),
          ],
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                child: const Icon(
                  Icons.redeem_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eco Points Balance',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Your sustainable rewards wallet',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10.5,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.13),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      color: Color(0xFFB9F6CA),
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'ECOPLUS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 27),

          Text(
            'AVAILABLE BALANCE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.72),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _ecoPoints.toString(),
                    style: const TextStyle(
                      fontSize: 43,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  'POINTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Color(0xFFB9F6CA),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: Color(0xFFB9F6CA),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    _ecoPoints == 0
                        ? 'Start your sustainability journey to earn Eco Points.'
                        : 'Great work! Keep making sustainable choices to earn more rewards.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EARNED AND USED STATISTICS
  // ------------------------------------------------------------

  Widget _buildStats() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up_rounded,
            title: 'Points Earned',
            value: _pointsEarned.toString(),
            subtitle: 'Total earned',
            iconColor: const Color(0xFF23834A),
            iconBackground: const Color(0xFFE5F5E9),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: _StatCard(
            icon: Icons.redeem_rounded,
            title: 'Points Used',
            value: _pointsUsed.toString(),
            subtitle: 'Total redeemed',
            iconColor: const Color(0xFF3975B9),
            iconBackground: const Color(0xFFE7F0FC),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // MILESTONE
  // ------------------------------------------------------------

  Widget _buildMilestoneCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFB7791F),
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Next Milestone',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_nextMilestone.toString()} Eco Points',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1D7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_milestoneProgress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF98600B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: _milestoneProgress,
              backgroundColor: AppColors.light,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF39945B),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$_ecoPoints / $_nextMilestone points',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _pointsToNextMilestone == 0
                      ? 'Milestone reached!'
                      : '$_pointsToNextMilestone more to go',
                  textAlign: TextAlign.end,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION HEADINGS
  // ------------------------------------------------------------

  Widget _buildSectionHeading(
      String title,
      String subtitle, {
        Widget? trailing,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.title.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          trailing,
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // VOUCHERS
  // ------------------------------------------------------------

  Widget _buildVouchers() {
    if (_vouchers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(21),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                color: AppColors.primary,
                size: 29,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              'No Active Vouchers',
              style: AppTextStyles.title.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Available rewards will appear here when vouchers are published.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _vouchers.map((voucher) {
        final id = (voucher['voucherId'] ?? '').toString();
        final title =
        (voucher['title'] ?? 'EcoLoop Voucher').toString();
        final description =
        (voucher['description'] ?? '').toString();
        final cost =
            int.tryParse('${voucher['pointsCost'] ?? 0}') ?? 0;

        final affordable = _ecoPoints >= cost && cost > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE5F5E9),
                          Color(0xFFF4FAF3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Color(0xFF23834A),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            description,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '$cost Eco Points',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: affordable
                            ? const Color(0xFFE5F5E9)
                            : const Color(0xFFFFF1D7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        affordable ? 'Available' : 'Locked',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: affordable
                              ? const Color(0xFF23834A)
                              : const Color(0xFF98600B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (!_claimingVoucher && affordable && id.isNotEmpty)
                      ? () => _claimVoucher(id, title)
                      : null,
                  icon: Icon(
                    affordable
                        ? Icons.redeem_rounded
                        : Icons.lock_outline_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _claimingVoucher
                        ? 'Processing...'
                        : affordable
                        ? 'Claim Reward'
                        : 'Not Enough Points',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    AppColors.accent.withOpacity(0.25),
                    disabledForegroundColor: AppColors.textSecondary,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 47),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------
  // REWARD HISTORY
  // ------------------------------------------------------------

  Widget _buildHistory() {
    if (_history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 27, 22, 27),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.history_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No Reward Activity Yet',
              style: AppTextStyles.title.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Your earned and redeemed Eco Points will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final visibleCount = _history.length > 5 ? 5 : _history.length;

    return Container(
      decoration: _cardDecoration(),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: visibleCount,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(left: 70, right: 15),
          child: Divider(
            height: 1,
            color: AppColors.accent.withOpacity(0.22),
          ),
        ),
        itemBuilder: (context, index) {
          return _buildHistoryItem(_history[index]);
        },
      ),
    );
  }

  Widget _buildHistoryItem(RewardHistoryItem item) {
    final isEarned = item.type == RewardHistoryType.earned;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: isEarned
                  ? const Color(0xFFE5F5E9)
                  : const Color(0xFFE7F0FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEarned
                  ? Icons.add_rounded
                  : Icons.redeem_rounded,
              color: isEarned
                  ? const Color(0xFF23834A)
                  : const Color(0xFF3975B9),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.date,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: isEarned
                  ? const Color(0xFFE5F5E9)
                  : const Color(0xFFF0F1F2),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              isEarned ? '+${item.points}' : '-${item.points}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isEarned
                    ? const Color(0xFF23834A)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // WAYS TO EARN POINTS
  // ------------------------------------------------------------

  Widget _buildWaysToEarn() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _EarnItem(
            icon: Icons.volunteer_activism_rounded,
            title: 'Donate Items',
            subtitle: 'Give useful items a second life.',
            iconColor: const Color(0xFF23834A),
            iconBackground: const Color(0xFFE5F5E9),
          ),
          _divider(),
          _EarnItem(
            icon: Icons.sell_outlined,
            title: 'Sell Products',
            subtitle: 'Keep products in circulation.',
            iconColor: const Color(0xFF3975B9),
            iconBackground: const Color(0xFFE7F0FC),
          ),
          _divider(),
          _EarnItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Buy and Reuse',
            subtitle: 'Choose pre-loved and reusable products.',
            iconColor: const Color(0xFFB7791F),
            iconBackground: const Color(0xFFFFF3D9),
          ),
          _divider(),
          _EarnItem(
            icon: Icons.eco_rounded,
            title: 'Sustainable Actions',
            subtitle: 'Participate in eligible EcoLoop activities.',
            iconColor: const Color(0xFF8B5BC0),
            iconBackground: const Color(0xFFF1E8FC),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70, right: 15),
      child: Divider(
        height: 1,
        color: AppColors.accent.withOpacity(0.22),
      ),
    );
  }

  // ------------------------------------------------------------
  // INFORMATION CARD
  // ------------------------------------------------------------

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC8E6C9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Color(0xFF23834A),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Every Point Has a Purpose',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF174D2B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your Eco Points reflect eligible activity recorded in your EcoLoop account. Keep choosing reuse, donation and more sustainable habits.',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    height: 1.65,
                    color: const Color(0xFF466650),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // LOADING STATE
  // ------------------------------------------------------------

  Widget _buildLoadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        _skeleton(65),
        const SizedBox(height: 20),
        _skeleton(230),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _skeleton(125)),
            const SizedBox(width: 13),
            Expanded(child: _skeleton(125)),
          ],
        ),
        const SizedBox(height: 25),
        _skeleton(140),
        const SizedBox(height: 25),
        _skeleton(210),
        const SizedBox(height: 25),
        _skeleton(220),
      ],
    );
  }

  Widget _skeleton(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.22),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ERROR STATE
  // ------------------------------------------------------------

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 30),
      children: [
        Center(
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Unable to Load Rewards',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          _loadError ??
              'Something went wrong while loading your rewards. Please try again.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: ElevatedButton.icon(
            onPressed: _loadRewards,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 23,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // API HELPERS
  // ------------------------------------------------------------

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return value.map(
            (key, item) => MapEntry(key.toString(), item),
      );
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asRows(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((row) => _asMap(row))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  // ------------------------------------------------------------
  // LOAD REWARDS
  // ------------------------------------------------------------

  Future<void> _loadRewards() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _loadError = null;
    });

    try {
      final rewardResponse =
      await EcoLoopApi.instance.get('/rewards');

      final rewardRoot = _asMap(rewardResponse);
      final rewardData = rewardRoot['data'] is Map
          ? _asMap(rewardRoot['data'])
          : rewardRoot;

      final voucherRows = _asRows(
        rewardData['vouchers'] ?? rewardRoot['vouchers'],
      );

      final dynamic transactionValue =
          rewardData['transactions'] ??
              rewardRoot['transactions'] ??
              (rewardResponse is List ? rewardResponse : null);

      final transactions = transactionValue is List
          ? transactionValue
          : <dynamic>[];

      // Donation status is supplementary to the rewards response.
      dynamic donationResponse;

      try {
        donationResponse =
        await EcoLoopApi.instance.get('/donations');
      } catch (_) {
        donationResponse = null;
      }

      final donationRoot = _asMap(donationResponse);
      final donationData = donationRoot['data'] is Map
          ? _asMap(donationRoot['data'])
          : donationRoot;

      final dynamic donationValue = donationResponse is List
          ? donationResponse
          : donationData['donations'] ??
          donationData['items'] ??
          donationData['results'] ??
          donationRoot['donations'] ??
          donationRoot['items'];

      final donations = donationValue is List
          ? donationValue
          : <dynamic>[];

      final donationStatuses = <String, String>{};

      for (final item in donations.whereType<Map>()) {
        final donation = _asMap(item);

        final id = (
            donation['donationId'] ??
                donation['donation_id'] ??
                donation['id'] ??
                ''
        ).toString().trim();

        if (id.isNotEmpty) {
          donationStatuses[id] = (donation['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase()
              .replaceAll('_', ' ')
              .replaceAll(RegExp(r'\s+'), ' ');
        }
      }

      final parsed = <RewardHistoryItem>[];

      var earned = 0;
      var used = 0;
      var calculatedBalance = 0;

      for (final item in transactions.whereType<Map>()) {
        final row = _asMap(item);

        final points =
            int.tryParse((row['points'] ?? 0).toString()) ?? 0;

        final referenceType = (
            row['referenceType'] ??
                row['reference_type'] ??
                ''
        )
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll('_', ' ');

        final referenceId = (
            row['referenceId'] ??
                row['reference_id'] ??
                ''
        ).toString();

        final reason =
        (row['reason'] ?? 'EcoLoop reward').toString();

        if (referenceType == 'donation') {
          final status = donationStatuses[referenceId] ?? '';
          final statusIsKnown = status.isNotEmpty;

          final acceptedStatus =
              status == 'accepted' ||
                  status == 'approved' ||
                  status == 'completed';

          final creditedReason = reason
              .trim()
              .toLowerCase()
              .startsWith('accepted donation reward');

          // Donation points count only when eligibility is confirmed.
          if (!creditedReason ||
              (statusIsKnown && !acceptedStatus)) {
            continue;
          }
        }

        calculatedBalance += points;

        if (points >= 0) {
          earned += points;
        } else {
          used += points.abs();
        }

        parsed.add(
          RewardHistoryItem(
            title: reason,
            description: referenceType.isEmpty
                ? 'EcoLoop activity'
                : referenceId.isEmpty
                ? _capitalize(referenceType)
                : '${_capitalize(referenceType)} reference #$referenceId',
            points: points.abs(),
            date: _formatRewardDate(
              (
                  row['createdAt'] ??
                      row['created_at'] ??
                      ''
              ).toString(),
            ),
            type: points < 0
                ? RewardHistoryType.used
                : RewardHistoryType.earned,
          ),
        );
      }

      final totalPointsValue =
          rewardData['totalPoints'] ??
              rewardRoot['totalPoints'];

      final apiBalance =
      int.tryParse((totalPointsValue ?? '').toString());

      final balance = apiBalance ?? calculatedBalance;

      if (!mounted) return;

      setState(() {
        _ecoPoints = balance < 0 ? 0 : balance;
        _pointsEarned = earned;
        _pointsUsed = used;

        _history
          ..clear()
          ..addAll(parsed);

        _vouchers = voucherRows;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _loadError =
            e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // CLAIM VOUCHER
  // ------------------------------------------------------------

  Future<void> _claimVoucher(
      String voucherId,
      String title,
      ) async {
    if (_claimingVoucher || voucherId.isEmpty) return;

    setState(() {
      _claimingVoucher = true;
    });

    try {
      final response = await EcoLoopApi.instance.post(
        '/rewards/claim',
        {'voucherId': voucherId},
      );

      if (!mounted) return;

      final map = response is Map
          ? _asMap(response)
          : <String, dynamic>{};

      final claim = map['claim'] is Map
          ? _asMap(map['claim'])
          : <String, dynamic>{};

      final code = (claim['claimCode'] ?? '').toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            code.isEmpty
                ? '$title claimed successfully.'
                : '$title claimed. Code: $code',
          ),
        ),
      );

      await _loadRewards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _claimingVoucher = false;
        });
      }
    }
  }

  // ------------------------------------------------------------
  // FULL REWARD HISTORY
  // ------------------------------------------------------------

  void _showFullHistory() {
    if (_history.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(27),
        ),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                18,
              ),
              child: Column(
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
                  const SizedBox(height: 20),
                  Text(
                    'Reward History',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Your complete Eco Points activity',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: _history.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 7),
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: _buildHistoryItem(_history[index]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // COMMON CARD STYLE
  // ------------------------------------------------------------

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: AppColors.accent.withOpacity(0.32),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 17,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _formatRewardDate(String raw) {
    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return raw.isEmpty ? 'Date unavailable' : raw;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color iconBackground;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.title.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EARN ITEM
// ============================================================

class _EarnItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBackground;

  const _EarnItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10.5,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: AppColors.textSecondary.withOpacity(0.65),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// REWARD HISTORY MODEL
// ============================================================

enum RewardHistoryType {
  earned,
  used,
}

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
