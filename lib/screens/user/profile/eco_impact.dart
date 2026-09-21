import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';

class EcoImpact extends StatefulWidget {
  const EcoImpact({super.key});

  @override
  State<EcoImpact> createState() => _EcoImpactState();
}

class _EcoImpactState extends State<EcoImpact> {
  bool _isLoading = false;
  bool _hasError = false;

  // Note: Temporary values for testing UI before Google Apps Script integration.
  int _itemsReused = 24;
  int _itemsDonated = 8;
  double _co2Saved = 42.6;
  double _wasteDiverted = 18.4;
  int _ecoPoints = 1250;

  final List<_ImpactMonth> _monthlyImpact = const [
    _ImpactMonth(label: 'Apr', value: 3),
    _ImpactMonth(label: 'May', value: 5),
    _ImpactMonth(label: 'Jun', value: 7),
    _ImpactMonth(label: 'Jul', value: 8),
    _ImpactMonth(label: 'Aug', value: 11),
    _ImpactMonth(label: 'Sep', value: 14),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('Eco Impact', style: AppTextStyles.title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadImpact,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: _loadImpact,
          child: _buildBody(),
        ),
      ),
    );
  }

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
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIntro(),
          const SizedBox(height: 18),
          _buildImpactHero(),
          const SizedBox(height: 16),
          _buildPrimaryStats(),
          const SizedBox(height: 22),
          _buildSectionTitle('Your Environmental Impact'),
          const SizedBox(height: 11),
          _buildImpactGrid(),
          const SizedBox(height: 24),
          _buildSectionTitle('Impact Over Time', trailing: _buildPeriodChip()),
          const SizedBox(height: 11),
          _buildImpactChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('Your Eco Contributions'),
          const SizedBox(height: 11),
          _buildContributionCard(),
          const SizedBox(height: 24),
          _buildSectionTitle('What Your Impact Means'),
          const SizedBox(height: 11),
          _buildImpactExplanation(),
          const SizedBox(height: 24),
          _buildMotivationCard(),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Small Actions, Big Impact', style: AppTextStyles.heading),
        const SizedBox(height: 5),
        Text(
          'Every item reused, donated, or kept away from waste contributes to a more sustainable future.',
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  Widget _buildImpactHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 21, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            'Your Eco Impact',
            style: AppTextStyles.title.copyWith(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'You are helping keep useful items in circulation.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    value: '$_itemsReused',
                    label: 'Items Reused',
                  ),
                ),
                Container(
                  width: 1,
                  height: 35,
                  color: Colors.white.withOpacity(0.18),
                ),
                Expanded(
                  child: _HeroMetric(
                    value: _formatNumber(_co2Saved),
                    label: 'kg CO₂ Saved',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.recycling_rounded,
            value: '$_itemsReused',
            label: 'Items Reused',
            iconColor: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.volunteer_activism_outlined,
            value: '$_itemsDonated',
            label: 'Items Donated',
            iconColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppTextStyles.title.copyWith(fontSize: 17)),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildImpactGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: [
        _ImpactCard(
          icon: Icons.cloud_outlined,
          title: 'CO₂ Saved',
          value: '${_formatNumber(_co2Saved)} kg',
          description: 'Estimated emissions avoided',
          iconColor: AppColors.success,
        ),
        _ImpactCard(
          icon: Icons.delete_outline_rounded,
          title: 'Waste Diverted',
          value: '${_formatNumber(_wasteDiverted)} kg',
          description: 'Kept away from waste streams',
          iconColor: AppColors.primary,
        ),
        _ImpactCard(
          icon: Icons.recycling_outlined,
          title: 'Items Reused',
          value: '$_itemsReused',
          description: 'Products given another life',
          iconColor: AppColors.secondary,
        ),
        _ImpactCard(
          icon: Icons.eco_outlined,
          title: 'Eco Points',
          value: '$_ecoPoints',
          description: 'Sustainability activity points',
          iconColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildPeriodChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Last 6 months',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildImpactChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sustainable Activity',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Items contributed to reuse',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: _ImpactChartPainter(
                data: _monthlyImpact,
                primaryColor: AppColors.primary,
                secondaryColor: AppColors.secondary,
                gridColor: AppColors.accent.withOpacity(0.24),
                textColor: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              'Monthly activity',
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.42)),
      ),
      child: Column(
        children: [
          _ContributionItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Reusable Purchases',
            subtitle: 'Choosing products that can be reused',
            value: '$_itemsReused',
            valueLabel: 'items',
          ),
          _buildDivider(),
          _ContributionItem(
            icon: Icons.volunteer_activism_outlined,
            title: 'Donations',
            subtitle: 'Items donated to give them another life',
            value: '$_itemsDonated',
            valueLabel: 'items',
          ),
          _buildDivider(),
          _ContributionItem(
            icon: Icons.delete_sweep_outlined,
            title: 'Waste Reduction',
            subtitle: 'Material kept in circulation',
            value: _formatNumber(_wasteDiverted),
            valueLabel: 'kg',
          ),
          _buildDivider(),
          _ContributionItem(
            icon: Icons.cloud_outlined,
            title: 'Carbon Reduction',
            subtitle: 'Estimated emissions avoided',
            value: _formatNumber(_co2Saved),
            valueLabel: 'kg CO₂',
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70),
      child: Divider(height: 1, color: AppColors.accent.withOpacity(0.20)),
    );
  }

  Widget _buildImpactExplanation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.42)),
      ),
      child: Column(
        children: [
          _ExplanationItem(
            icon: Icons.recycling_rounded,
            title: 'Reuse',
            description:
                'Reusing products helps extend their useful life and reduces the need for new resources.',
          ),
          _buildDivider(),
          _ExplanationItem(
            icon: Icons.delete_outline_rounded,
            title: 'Waste Reduction',
            description:
                'Keeping usable items in circulation helps reduce the amount of material sent toward disposal.',
          ),
          _buildDivider(),
          _ExplanationItem(
            icon: Icons.cloud_outlined,
            title: 'Carbon Savings',
            description:
                'Reuse and recycling can reduce the environmental impact associated with producing new goods.',
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColors.accent.withOpacity(0.55)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep Making an Impact',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Every purchase, sale, reuse and donation helps move EcoLoop toward a more circular marketplace.',
                  style: AppTextStyles.caption.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
      children: [
        _skeleton(height: 30, width: 225),
        const SizedBox(height: 9),
        _skeleton(height: 18, width: double.infinity),
        const SizedBox(height: 18),
        _skeleton(height: 270, width: double.infinity),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _skeleton(height: 110, width: double.infinity)),
            const SizedBox(width: 10),
            Expanded(child: _skeleton(height: 110, width: double.infinity)),
          ],
        ),
        const SizedBox(height: 20),
        _skeleton(height: 235, width: double.infinity),
        const SizedBox(height: 20),
        _skeleton(height: 230, width: double.infinity),
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
        border: Border.all(color: AppColors.accent.withOpacity(0.20)),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 30),
      children: [
        Center(
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 17),
        Text(
          'Unable to Load Eco Impact',
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          'Something went wrong while loading your environmental impact.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 18),
        Center(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _loadImpact,
              child: const Text('Try Again'),
            ),
          ),
        ),
      ],
    );
  }

  // Note: Backend endpoint integration will be hooked up using the API manager when ready.
  Future<void> _loadImpact() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;

  const _HeroMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.72)),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
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
              color: AppColors.light,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 11),
          Text(
            value,
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String description;
  final Color iconColor;

  const _ImpactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.title.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 1),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontSize: 9.0, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _ContributionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String valueLabel;

  const _ContributionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
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
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTextStyles.title.copyWith(fontSize: 17)),
              Text(
                valueLabel,
                style: AppTextStyles.caption.copyWith(fontSize: 9.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExplanationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ExplanationItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactMonth {
  final String label;
  final double value;

  const _ImpactMonth({required this.label, required this.value});
}

class _ImpactChartPainter extends CustomPainter {
  final List<_ImpactMonth> data;
  final Color primaryColor;
  final Color secondaryColor;
  final Color gridColor;
  final Color textColor;

  _ImpactChartPainter({
    required this.data,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double leftPadding = 8;
    const double rightPadding = 8;
    const double topPadding = 8;
    const double bottomPadding = 29;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    final double maxValue = math.max(
      data.map((item) => item.value).reduce(math.max),
      1,
    );

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final Paint barPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final Paint highlightPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final double sectionHeight = chartHeight / 4;

    for (int i = 0; i <= 4; i++) {
      final double y = topPadding + (sectionHeight * i);
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    final double slotWidth = chartWidth / data.length;
    final double barWidth = math.min(28, slotWidth * 0.48);

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final double barHeight = (item.value / maxValue) * chartHeight;
      final double centerX = leftPadding + (slotWidth * i) + (slotWidth / 2);
      final double left = centerX - (barWidth / 2);
      final double top = topPadding + chartHeight - barHeight;

      final Rect barRect = Rect.fromLTWH(left, top, barWidth, barHeight);
      final RRect roundedRect = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(7),
        topRight: const Radius.circular(7),
      );

      canvas.drawRRect(
        roundedRect,
        i == data.length - 1 ? highlightPaint : barPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: item.value.toInt().toString(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(centerX - (textPainter.width / 2), top - textPainter.height - 4),
      );

      final monthPainter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: TextStyle(fontSize: 10, color: textColor),
        ),
        textDirection: TextDirection.ltr,
      );
      monthPainter.layout();
      monthPainter.paint(
        canvas,
        Offset(
          centerX - (monthPainter.width / 2),
          size.height - bottomPadding + 9,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ImpactChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}
