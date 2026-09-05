import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import 'donation_details.dart';

class DonationHistory extends StatefulWidget {
  const DonationHistory({super.key});

  @override
  State<DonationHistory> createState() => _DonationHistoryState();
}

class _DonationHistoryState extends State<DonationHistory> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _donations = [
    {
      'id': 'DN1024',
      'item': 'Wooden Study Table',
      'category': 'Furniture',
      'condition': 'Good',
      'date': '28 Aug 2026',
      'status': 'Pickup Scheduled',
      'statusColor': 'orange',
      'pickupDate': '30 Aug 2026',
      'location': 'Ahmedabad, Gujarat',
      'image':
          'https://images.unsplash.com/photo-1518455027359-f3f8164ba6b0?auto=format&fit=crop&w=700&q=80',
      'rewardStatus': 'Eligible',
    },
    {
      'id': 'DN1018',
      'item': 'Old Books Bundle',
      'category': 'Books',
      'condition': 'Good',
      'date': '18 Aug 2026',
      'status': 'Collected',
      'statusColor': 'green',
      'pickupDate': '20 Aug 2026',
      'location': 'Vadodara, Gujarat',
      'image':
          'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?auto=format&fit=crop&w=700&q=80',
      'rewardStatus': 'Reward Earned',
    },
    {
      'id': 'DN1007',
      'item': 'Glass Decoration Set',
      'category': 'Decor',
      'condition': 'Good',
      'date': '05 Aug 2026',
      'status': 'Completed',
      'statusColor': 'green',
      'pickupDate': '07 Aug 2026',
      'location': 'Surat, Gujarat',
      'image':
          'https://images.unsplash.com/photo-1610701596007-11502861dcfa?auto=format&fit=crop&w=700&q=80',
      'rewardStatus': 'Gift Received',
    },
    {
      'id': 'DN0992',
      'item': 'Old Bluetooth Speaker',
      'category': 'Electronics',
      'condition': 'Used',
      'date': '27 Jul 2026',
      'status': 'Completed',
      'statusColor': 'green',
      'pickupDate': '29 Jul 2026',
      'location': 'Ahmedabad, Gujarat',
      'image':
          'https://images.unsplash.com/photo-1589003077984-894e133dabab?auto=format&fit=crop&w=700&q=80',
      'rewardStatus': 'Not Eligible',
    },
  ];

  List<Map<String, dynamic>> get _filteredDonations {
    if (_selectedFilter == 'All') {
      return _donations;
    }

    return _donations.where((donation) {
      final status = donation['status'].toString();

      if (_selectedFilter == 'Active') {
        return status == 'Pickup Scheduled';
      }

      if (_selectedFilter == 'Completed') {
        return status == 'Completed' || status == 'Collected';
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          'Donation History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeaderSummary(),
          _buildFilters(),
          Expanded(
            child: _filteredDonations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 25),
                    itemCount: _filteredDonations.length,
                    itemBuilder: (context, index) {
                      return _buildDonationCard(_filteredDonations[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildHeaderSummary() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              Icons.volunteer_activism_outlined,
              'Donated',
              '${_donations.length}',
            ),
          ),
          Container(
            height: 42,
            width: 1,
            color: Colors.white.withOpacity(0.25),
          ),
          Expanded(child: _summaryItem(Icons.eco_outlined, 'Impact', 'High')),
          Container(
            height: 42,
            width: 1,
            color: Colors.white.withOpacity(0.25),
          ),
          Expanded(
            child: _summaryItem(Icons.card_giftcard_outlined, 'Rewards', '2'),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    const filters = ['All', 'Active', 'Completed'];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = _selectedFilter == filter;

          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            side: BorderSide(
              color: selected
                  ? AppColors.primary
                  : AppColors.accent.withOpacity(0.6),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // DONATION CARD
  // ============================================================

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final status = donation['status'].toString();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DonationDetails(donation: donation),
          ),
        );
      },
      borderRadius: BorderRadius.circular(17),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.accent.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                donation['image'].toString(),
                height: 82,
                width: 82,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 82,
                    width: 82,
                    color: AppColors.light,
                    child: const Icon(
                      Icons.volunteer_activism_outlined,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          donation['item'].toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '${donation['category']} • ${donation['condition']}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 7),

                  _buildStatusBadge(status),

                  const SizedBox(height: 6),

                  Text(
                    donation['date'].toString(),
                    style: const TextStyle(
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
  // STATUS
  // ============================================================

  Widget _buildStatusBadge(String status) {
    final bool active = status == 'Pickup Scheduled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: active ? Colors.orange.withOpacity(0.10) : AppColors.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active
                ? Icons.schedule_rounded
                : Icons.check_circle_outline_rounded,
            size: 12,
            color: active ? Colors.orange.shade700 : AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: active ? Colors.orange.shade700 : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: const BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volunteer_activism_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No donations found',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Your donated items and pickup history\n'
              'will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
