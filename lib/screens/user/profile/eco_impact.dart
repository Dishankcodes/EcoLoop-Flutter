import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';

class EcoImpact extends StatefulWidget {
  const EcoImpact({super.key});

  @override
  State<EcoImpact> createState() => _EcoImpactState();
}

class _EcoImpactState extends State<EcoImpact> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _loadError;

  int _itemsReused = 0;
  int _itemsDonated = 0;
  int _ecoPoints = 0;

  double _co2Saved = 0;
  double _wasteDiverted = 0;

  @override
  void initState() {
    super.initState();
    _loadImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _loadImpact,
          child: _isLoading
              ? _buildLoading()
              : _hasError
              ? _buildError()
              : _buildPageContent(),
        ),
      ),
    );
  }

  // APP BAR

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
            'Eco Impact',
            style: AppTextStyles.title.copyWith(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Your sustainability journey',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.35),
              ),
            ),
            child: IconButton(
              tooltip: 'Refresh',
              onPressed: _isLoading ? null : _loadImpact,
              icon: Icon(
                Icons.refresh_rounded,
                size: 22,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // MAIN SCROLLABLE PAGE

  Widget _buildPageContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 650;
        final horizontalPadding = isTablet ? 28.0 : 18.0;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntro(isTablet),
                  const SizedBox(height: 22),

                  _buildHeroCard(),
                  const SizedBox(height: 18),

                  _buildSummaryCards(),
                  const SizedBox(height: 30),

                  _sectionHeading(
                    'Environmental Impact',
                    'Your actions are making a difference',
                  ),
                  const SizedBox(height: 15),

                  _buildImpactGrid(),
                  const SizedBox(height: 30),

                  _sectionHeading(
                    'Your Contributions',
                    'A breakdown of your EcoLoop activity',
                  ),
                  const SizedBox(height: 15),

                  _buildContributionCard(),
                  const SizedBox(height: 30),

                  _sectionHeading(
                    'What Your Impact Means',
                    'Small changes create lasting benefits',
                  ),
                  const SizedBox(height: 15),

                  _buildBenefitsCard(),
                  const SizedBox(height: 22),

                  _buildMotivationCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // INTRO

  Widget _buildIntro(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Small Actions,',
          style: AppTextStyles.heading.copyWith(
            fontSize: isTablet ? 34 : 29,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Big Impact.',
          style: AppTextStyles.heading.copyWith(
            fontSize: isTablet ? 34 : 29,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Every item reused or donated helps reduce waste and gives useful products another life.',
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

  // HERO CARD

  Widget _buildHeroCard() {
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
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.20),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Eco Impact',
                      style: AppTextStyles.title.copyWith(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Your journey towards a greener planet.',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.82),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    icon: Icons.recycling_rounded,
                    value: '$_itemsReused',
                    label: 'Items Reused',
                  ),
                ),
                Container(
                  width: 1,
                  height: 54,
                  color: Colors.white.withOpacity(0.22),
                ),
                Expanded(
                  child: _HeroMetric(
                    icon: Icons.cloud_done_outlined,
                    value: _formatNumber(_co2Saved),
                    label: 'kg CO₂ Saved',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFB9F6CA),
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Every contribution counts. Keep making a difference!',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SUMMARY CARDS

  Widget _buildSummaryCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.recycling_rounded,
            label: 'Items Reused',
            value: '$_itemsReused',
            iconColor: const Color(0xFF23834A),
            iconBackground: const Color(0xFFE5F5E9),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: _SummaryCard(
            icon: Icons.volunteer_activism_rounded,
            label: 'Items Donated',
            value: '$_itemsDonated',
            iconColor: const Color(0xFF3975B9),
            iconBackground: const Color(0xFFE7F0FC),
          ),
        ),
      ],
    );
  }

  // SECTION HEADING

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
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
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(
            fontSize: 11.5,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // RESPONSIVE IMPACT GRID

  Widget _buildImpactGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 4 : 2;
        final spacing = 13.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _impactCard(
              width: cardWidth,
              icon: Icons.cloud_done_rounded,
              title: 'CO₂ Saved',
              value: '${_formatNumber(_co2Saved)} kg',
              description: 'Estimated emissions avoided',
              iconColor: const Color(0xFF23834A),
              iconBackground: const Color(0xFFE5F5E9),
            ),
            _impactCard(
              width: cardWidth,
              icon: Icons.delete_sweep_rounded,
              title: 'Waste Diverted',
              value: '${_formatNumber(_wasteDiverted)} kg',
              description: 'Material kept in circulation',
              iconColor: const Color(0xFFB7791F),
              iconBackground: const Color(0xFFFFF3D9),
            ),
            _impactCard(
              width: cardWidth,
              icon: Icons.recycling_rounded,
              title: 'Items Reused',
              value: '$_itemsReused',
              description: 'Products given another life',
              iconColor: const Color(0xFF3975B9),
              iconBackground: const Color(0xFFE7F0FC),
            ),
            _impactCard(
              width: cardWidth,
              icon: Icons.stars_rounded,
              title: 'Eco Points',
              value: '$_ecoPoints',
              description: 'Points from your activity',
              iconColor: const Color(0xFF8B5BC0),
              iconBackground: const Color(0xFFF1E8FC),
            ),
          ],
        );
      },
    );
  }

  Widget _impactCard({
    required double width,
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required Color iconColor,
    required Color iconBackground,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 174),
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 23,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTextStyles.title.copyWith(
                  color: AppColors.primary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CONTRIBUTION CARD

  Widget _buildContributionCard() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _ContributionRow(
            icon: Icons.shopping_bag_outlined,
            title: 'Reusable Items',
            subtitle: 'Products given another life',
            value: '$_itemsReused',
            unit: 'items',
            iconColor: const Color(0xFF23834A),
            iconBackground: const Color(0xFFE5F5E9),
          ),
          _divider(),
          _ContributionRow(
            icon: Icons.volunteer_activism_outlined,
            title: 'Donations',
            subtitle: 'Items donated to others',
            value: '$_itemsDonated',
            unit: 'items',
            iconColor: const Color(0xFF3975B9),
            iconBackground: const Color(0xFFE7F0FC),
          ),
          _divider(),
          _ContributionRow(
            icon: Icons.delete_outline_rounded,
            title: 'Waste Reduction',
            subtitle: 'Estimated material diverted',
            value: _formatNumber(_wasteDiverted),
            unit: 'kg',
            iconColor: const Color(0xFFB7791F),
            iconBackground: const Color(0xFFFFF3D9),
          ),
          _divider(),
          _ContributionRow(
            icon: Icons.cloud_outlined,
            title: 'Carbon Reduction',
            subtitle: 'Estimated emissions avoided',
            value: _formatNumber(_co2Saved),
            unit: 'kg CO₂',
            iconColor: const Color(0xFF23834A),
            iconBackground: const Color(0xFFE5F5E9),
          ),
        ],
      ),
    );
  }

  // EXPLANATION CARD

  Widget _buildBenefitsCard() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _BenefitRow(
            icon: Icons.recycling_rounded,
            title: 'Reuse Products',
            description:
            'Reusing products extends their useful life and reduces the demand for new resources.',
            iconColor: const Color(0xFF23834A),
            iconBackground: const Color(0xFFE5F5E9),
          ),
          _divider(),
          _BenefitRow(
            icon: Icons.delete_outline_rounded,
            title: 'Reduce Waste',
            description:
            'Keeping usable items in circulation helps reduce the amount of material sent for disposal.',
            iconColor: const Color(0xFFB7791F),
            iconBackground: const Color(0xFFFFF3D9),
          ),
          _divider(),
          _BenefitRow(
            icon: Icons.public_rounded,
            title: 'Protect Our Planet',
            description:
            'Reusing and donating items can reduce the need to manufacture replacement products.',
            iconColor: const Color(0xFF3975B9),
            iconBackground: const Color(0xFFE7F0FC),
          ),
        ],
      ),
    );
  }

  // MOTIVATION CARD

  Widget _buildMotivationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFC8E6C9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.energy_savings_leaf_rounded,
              color: Color(0xFF23834A),
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep Making an Impact!',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF174D2B),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Every item reused and every donation helps build a more sustainable future.',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    height: 1.65,
                    color: const Color(0xFF466650),
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Reuse more. Waste less. Live greener.',
                    style: TextStyle(
                      color: Color(0xFF174D2B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

  // COMMON CARD STYLE

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
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.accent.withOpacity(0.20),
      ),
    );
  }

  // LOADING

  Widget _buildLoading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(18),
      children: [
        _skeleton(65),
        const SizedBox(height: 18),
        _skeleton(230),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _skeleton(125)),
            const SizedBox(width: 12),
            Expanded(child: _skeleton(125)),
          ],
        ),
        const SizedBox(height: 25),
        _skeleton(200),
        const SizedBox(height: 20),
        _skeleton(240),
        const SizedBox(height: 20),
        _skeleton(200),
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
          color: AppColors.accent.withOpacity(0.18),
        ),
      ),
    );
  }

  // ERROR

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 30),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Unable to Load Eco Impact',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          _loadError ??
              'Something went wrong while loading your impact.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: ElevatedButton.icon(
            onPressed: _loadImpact,
            icon: const Icon(Icons.refresh_rounded),
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

  // API DATA

  Future<void> _loadImpact() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _loadError = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        EcoLoopApi.instance.get('/eco-impact'),
        EcoLoopApi.instance.get('/donations'),
        EcoLoopApi.instance.get('/rewards'),
      ]);

      final response = results[0];

      if (response is! Map) {
        throw Exception('Unexpected Eco Impact response from the server.');
      }

      final data = Map<String, dynamic>.from(response);
      final donationResponse = results[1];

      final List<dynamic> donationRows = donationResponse is List
          ? donationResponse
          : donationResponse is Map &&
          donationResponse['donations'] is List
          ? donationResponse['donations'] as List
          : <dynamic>[];

      final acceptedDonationIds = <String>{};

      for (final row in donationRows.whereType<Map>()) {
        final status = (row['status'] ?? '')
            .toString()
            .toLowerCase()
            .trim();

        if (status == 'accepted' ||
            status == 'approved' ||
            status == 'completed') {
          final id = (row['donationId'] ?? row['id'] ?? '')
              .toString();

          if (id.isNotEmpty) {
            acceptedDonationIds.add(id);
          }
        }
      }

      final rewardResponse = results[2];

      final List<dynamic> transactions = rewardResponse is Map &&
          rewardResponse['transactions'] is List
          ? rewardResponse['transactions'] as List
          : rewardResponse is List
          ? rewardResponse
          : <dynamic>[];

      var acceptedPoints = 0;

      for (final row in transactions.whereType<Map>()) {
        final points = _asInt(row['points']);

        final referenceType = (row['referenceType'] ?? '')
            .toString()
            .toLowerCase()
            .trim();

        final referenceId = (row['referenceId'] ?? '').toString();

        if (referenceType == 'donation' &&
            !acceptedDonationIds.contains(referenceId)) {
          continue;
        }

        acceptedPoints += points;
      }

      final reused = _asInt(data['itemsReused']);
      final donated = acceptedDonationIds.length;

      if (!mounted) return;

      setState(() {
        _itemsReused = reused;
        _itemsDonated = donated;

        _co2Saved = (reused * 2.5) + (donated * 3.0);
        _wasteDiverted = (reused * 1.5) + (donated * 2.0);
        _ecoPoints = acceptedPoints;

        _isLoading = false;
        _hasError = false;
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

  int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}

// HERO METRIC

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFFB9F6CA),
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
        ],
      ),
    );
  }
}

// SUMMARY CARD

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBackground,
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
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
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
          const SizedBox(height: 15),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// CONTRIBUTION ROW

class _ContributionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String unit;
  final Color iconColor;
  final Color iconBackground;

  const _ContributionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.unit,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              size: 22,
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
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTextStyles.title.copyWith(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                unit,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 9.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// BENEFIT ROW

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color iconBackground;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
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
              size: 22,
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
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.65,
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