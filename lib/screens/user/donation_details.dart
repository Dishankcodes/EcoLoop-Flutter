import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';

class DonationDetails extends StatelessWidget {
  final Map<String, dynamic> donation;

  const DonationDetails({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    final status = donation['status']?.toString() ?? 'Pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Donation Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildItemHeader(),
            _buildStatusSection(status),
            _buildPickupSection(),
            _buildDonationInformation(),
            _buildRewardSection(),
            _buildEcoLoopMessage(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ITEM HEADER
  // ============================================================

  Widget _buildItemHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              donation['image'].toString(),
              height: 105,
              width: 105,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  height: 105,
                  width: 105,
                  color: AppColors.light,
                  child: const Icon(
                    Icons.volunteer_activism_outlined,
                    size: 35,
                    color: AppColors.primary,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  donation['item']?.toString() ?? 'Donated Item',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  '${donation['category']} • ${donation['condition']}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  'Donation ID: ${donation['id']}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
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

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusSection(String status) {
    final isScheduled = status == 'Pickup Scheduled';
    final isCompleted = status == 'Completed' || status == 'Collected';

    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Donation Status',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          _timelineStep(
            icon: Icons.volunteer_activism_outlined,
            title: 'Donation submitted',
            subtitle: donation['date']?.toString() ?? 'Recently',
            completed: true,
            active: false,
          ),

          _timelineLine(),

          _timelineStep(
            icon: Icons.local_shipping_outlined,
            title: 'Pickup scheduled',
            subtitle:
                donation['pickupDate']?.toString() ??
                'Pickup date will be confirmed',
            completed: isCompleted,
            active: isScheduled,
          ),

          _timelineLine(),

          _timelineStep(
            icon: Icons.check_circle_outline_rounded,
            title: 'Donation completed',
            subtitle: isCompleted
                ? 'Item successfully collected'
                : 'Waiting for pickup',
            completed: isCompleted,
            active: false,
          ),
        ],
      ),
    );
  }

  Widget _timelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool completed,
    required bool active,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: completed || active ? AppColors.light : AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 19,
            color: completed || active
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: completed || active
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: completed || active
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineLine() {
    return Container(
      margin: const EdgeInsets.only(left: 18, top: 3, bottom: 3),
      height: 25,
      width: 2,
      color: AppColors.accent,
    );
  }

  // ============================================================
  // PICKUP
  // ============================================================

  Widget _buildPickupSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 15),

          _infoRow(
            Icons.calendar_today_outlined,
            'Pickup Date',
            donation['pickupDate']?.toString() ?? 'Not scheduled',
          ),

          _infoRow(
            Icons.location_on_outlined,
            'Pickup Location',
            donation['location']?.toString() ?? 'Ahmedabad, Gujarat',
          ),

          _infoRow(
            Icons.local_shipping_outlined,
            'Pickup',
            'Free EcoLoop Pickup',
          ),

          const SizedBox(height: 5),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.light.withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Our pickup partner will contact you before '
                    'arriving at the pickup location.',
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.4,
                      color: AppColors.textSecondary,
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

  // ============================================================
  // DONATION INFORMATION
  // ============================================================

  Widget _buildDonationInformation() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Donation Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          _infoRow(
            Icons.category_outlined,
            'Category',
            donation['category']?.toString() ?? 'Other',
          ),

          _infoRow(
            Icons.check_circle_outline,
            'Condition',
            donation['condition']?.toString() ?? 'Good',
          ),

          _infoRow(
            Icons.calendar_today_outlined,
            'Submitted',
            donation['date']?.toString() ?? 'Recently',
          ),

          _infoRow(
            Icons.tag_outlined,
            'Donation ID',
            donation['id']?.toString() ?? 'DN0000',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REWARD
  // ============================================================

  Widget _buildRewardSection() {
    final reward = donation['rewardStatus']?.toString() ?? 'Under Review';

    final earned = reward == 'Reward Earned' || reward == 'Gift Received';

    return _section(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.light.withOpacity(0.7),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.accent.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                earned
                    ? Icons.card_giftcard_rounded
                    : Icons.card_giftcard_outlined,
                color: AppColors.primary,
                size: 23,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EcoLoop Reward',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    reward,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: earned
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 3),

                  const Text(
                    'Reward eligibility and gifts will be '
                    'handled by EcoLoop.',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ECOLOOP MESSAGE
  // ============================================================

  Widget _buildEcoLoopMessage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco_outlined, size: 19, color: AppColors.success),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Thank you for giving your unused item another life. '
              'Every donation helps reduce waste and supports a '
              'more circular community. 🌱',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),

          const SizedBox(width: 10),

          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),

          const Spacer(),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SECTION

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: child,
    );
  }
}
