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
  bool _isLoading = false;
  bool _hasError = false;

  int _ecoPoints = 0;
  int _pointsEarned = 0;
  int _pointsUsed = 0;

  final List<RewardHistoryItem> _history = [];
  List<Map<String, dynamic>> _vouchers = [];
  bool _claimingVoucher = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

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

          const SizedBox(height: 18),

          _buildVouchers(),

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
            color: AppColors.primary.withValues(alpha: 0.16),
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
                  color: Colors.white.withValues(alpha: 0.13),
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
                  color: Colors.white.withValues(alpha: 0.12),
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
              color: Colors.white.withValues(alpha: 0.75),
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
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
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
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.40)),
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
              color: AppColors.accent.withValues(alpha: 0.20),
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
                    color: AppColors.textSecondary.withValues(alpha: 0.65),
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
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.40)),
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
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.40)),
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
      child: Divider(
        height: 1,
        color: AppColors.accent.withValues(alpha: 0.20),
      ),
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
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
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
              color: AppColors.error.withValues(alpha: 0.08),
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
          _loadError ??
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

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asRows(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  // Loads the current account's reward transactions from the Apps Script API.
  // Donation-related points are shown only after the matching donation has
  // been accepted/approved/completed in the Google Sheet.
  Future<void> _loadRewards() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _loadError = null;
    });

    try {
      // Rewards are the primary source for points and vouchers.
      final rewardResponse = await EcoLoopApi.instance.get('/rewards');
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

      // Donation status is supplementary. If the endpoint is unavailable,
      // the rewards API remains authoritative for already-credited rewards.
      dynamic donationResponse;
      try {
        donationResponse = await EcoLoopApi.instance.get('/donations');
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

      final donations = donationValue is List ? donationValue : <dynamic>[];

      final donationStatuses = <String, String>{};
      for (final item in donations.whereType<Map>()) {
        final donation = _asMap(item);
        final id =
            (donation['donationId'] ??
                    donation['donation_id'] ??
                    donation['id'] ??
                    '')
                .toString()
                .trim();

        if (id.isNotEmpty) {
          donationStatuses[id] = (donation['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
        }
      }

      final parsed = <RewardHistoryItem>[];
      var earned = 0;
      var used = 0;
      var calculatedBalance = 0;

      for (final item in transactions.whereType<Map>()) {
        final row = _asMap(item);
        final points = int.tryParse((row['points'] ?? 0).toString()) ?? 0;
        final referenceType =
            (row['referenceType'] ?? row['reference_type'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
        final referenceId = (row['referenceId'] ?? row['reference_id'] ?? '')
            .toString();
        final reason = (row['reason'] ?? 'EcoLoop reward').toString();

        if (referenceType == 'donation') {
          final status = donationStatuses[referenceId] ?? '';
          final statusIsKnown = status.isNotEmpty;
          final acceptedStatus =
              status == 'accepted' ||
              status == 'approved' ||
              status == 'completed';
          final creditedReason = reason.toLowerCase().startsWith(
            'accepted donation reward',
          );

          // If a matching donation status is available, require acceptance.
          // If the status is missing, trust the reward transaction already
          // returned by /rewards, but still require the credited-reward reason.
          if (!creditedReason || (statusIsKnown && !acceptedStatus)) {
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
              (row['createdAt'] ?? row['created_at'] ?? '').toString(),
            ),
            type: points < 0
                ? RewardHistoryType.used
                : RewardHistoryType.earned,
          ),
        );
      }

      // The API response may provide the authoritative balance directly,
      // e.g. {data: {totalPoints: 100, transactions: [...], vouchers: [...]}}.
      final totalPointsValue =
          rewardData['totalPoints'] ?? rewardRoot['totalPoints'];
      final apiBalance = int.tryParse((totalPointsValue ?? '').toString());
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Widget _buildVouchers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Redeem Eco Points',
          style: AppTextStyles.title.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 5),
        Text(
          'Claim available vouchers using your current points balance.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 10),
        if (_vouchers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
              ),
            ),
            child: const Text('No active vouchers are available right now.'),
          )
        else
          ..._vouchers.map((voucher) {
            final id = (voucher['voucherId'] ?? '').toString();
            final title = (voucher['title'] ?? 'EcoLoop Voucher').toString();
            final description = (voucher['description'] ?? '').toString();
            final cost = int.tryParse('${voucher['pointsCost'] ?? 0}') ?? 0;
            final affordable = _ecoPoints >= cost && cost > 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(description, style: AppTextStyles.caption),
                        ],
                        const SizedBox(height: 5),
                        Text(
                          '$cost Eco Points',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 78,
                    child: ElevatedButton(
                      onPressed: (!_claimingVoucher && affordable)
                          ? () => _claimVoucher(id, title)
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(78, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        affordable ? 'Claim' : 'Locked',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _claimVoucher(String voucherId, String title) async {
    if (_claimingVoucher || voucherId.isEmpty) return;
    setState(() => _claimingVoucher = true);
    try {
      final response = await EcoLoopApi.instance.post('/rewards/claim', {
        'voucherId': voucherId,
      });
      if (!mounted) return;
      final map = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      final claim = map['claim'] is Map
          ? Map<String, dynamic>.from(map['claim'] as Map)
          : <String, dynamic>{};
      final code = (claim['claimCode'] ?? '').toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _claimingVoucher = false);
    }
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  String _formatRewardDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.isEmpty ? 'Date unavailable' : raw;
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
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.40)),
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
