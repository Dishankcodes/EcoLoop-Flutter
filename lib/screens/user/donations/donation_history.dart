import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'donation_details.dart';

class DonationHistory extends StatefulWidget {
  const DonationHistory({super.key});

  @override
  State<DonationHistory> createState() => _DonationHistoryState();
}

class _DonationHistoryState extends State<DonationHistory> {
  String _selectedFilter = 'All';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _donations = [];

  @override
  void initState() {
    super.initState();
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await EcoLoopApi.instance.get('/donations');
      final List<dynamic> rows;

      if (response is List) {
        rows = response;
      } else if (response is Map && response['donations'] is List) {
        rows = response['donations'] as List;
      } else if (response is Map && response['data'] is List) {
        rows = response['data'] as List;
      } else {
        throw Exception('The server returned an unexpected donations response.');
      }

      final parsed = rows
          .whereType<Map>()
          .map((row) => _normalizeDonation(Map<String, dynamic>.from(row)))
          .toList();

      if (!mounted) return;
      setState(() {
        _donations = parsed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _normalizeDonation(Map<String, dynamic> raw) {
    final images = raw['imageUrls'];
    String image = '';
    if (images is List && images.isNotEmpty) {
      image = images.first.toString();
    } else if (raw['image'] != null) {
      image = raw['image'].toString();
    }

    final createdAt = raw['createdAt']?.toString() ?? '';
    return {
      ...raw,
      'id': raw['donationId']?.toString() ?? raw['id']?.toString() ?? '',
      'item': raw['title']?.toString() ?? raw['item']?.toString() ?? 'Donated Item',
      'category': raw['category']?.toString() ?? raw['categoryName']?.toString() ?? 'Other',
      'condition': _prettyCondition(raw['condition']?.toString() ?? 'used'),
      'date': _displayDate(createdAt.isNotEmpty ? createdAt : raw['date']?.toString()),
      'status': _prettyStatus(raw['status']?.toString() ?? 'pending'),
      'pickupDate': raw['pickupDate']?.toString() ?? '',
      'location': [
        raw['city']?.toString(),
        raw['state']?.toString(),
      ].where((part) => part != null && part.trim().isNotEmpty).join(', '),
      'address': raw['address']?.toString() ?? '',
      'image': image,
      'rewardStatus': raw['rewardStatus']?.toString() ?? 'Under Review',
    };
  }

  String _prettyCondition(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _prettyStatus(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
      case 'submitted':
        return 'Pending';
      case 'pickup_requested':
      case 'requested':
      case 'pickup scheduled':
        return 'Pickup Scheduled';
      case 'picked_up':
      case 'collected':
        return 'Collected';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return _prettyCondition(value);
    }
  }

  String _displayDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Date unavailable';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  List<Map<String, dynamic>> get _filteredDonations {
    if (_selectedFilter == 'All') return _donations;
    if (_selectedFilter == 'Active') {
      return _donations.where((d) {
        final s = d['status'].toString().toLowerCase();
        return s == 'pending' || s == 'pickup scheduled';
      }).toList();
    }
    if (_selectedFilter == 'Completed') {
      return _donations.where((d) {
        final s = d['status'].toString().toLowerCase();
        return s == 'completed' || s == 'collected';
      }).toList();
    }
    return _donations;
  }

  int get _completedCount => _donations.where((d) {
        final s = d['status'].toString().toLowerCase();
        return s == 'completed' || s == 'collected';
      }).length;

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
        actions: [
          IconButton(
            tooltip: 'Refresh donations',
            onPressed: _loadDonations,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeaderSummary(),
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredDonations.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadDonations,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 25),
                              itemCount: _filteredDonations.length,
                              itemBuilder: (context, index) =>
                                  _buildDonationCard(_filteredDonations[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

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
          Expanded(child: _summaryItem(Icons.volunteer_activism_outlined, 'Donated', '${_donations.length}')),
          Container(height: 42, width: 1, color: Colors.white.withOpacity(0.25)),
          Expanded(child: _summaryItem(Icons.check_circle_outline, 'Completed', '$_completedCount')),
          Container(height: 42, width: 1, color: Colors.white.withOpacity(0.25)),
          Expanded(child: _summaryItem(Icons.eco_outlined, 'Impact', _donations.isEmpty ? '—' : 'Active')),
        ],
      ),
    );
  }

  Widget _summaryItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 2),
        Text(title, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

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
            onSelected: (_) => setState(() => _selectedFilter = filter),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            labelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.accent.withOpacity(0.6),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final status = donation['status'].toString();
    final image = donation['image'].toString();

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DonationDetails(donation: donation)),
        );
        if (mounted) _loadDonations();
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
              child: image.startsWith('http')
                  ? Image.network(
                      image,
                      height: 82,
                      width: 82,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
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
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${donation['category']} • ${donation['condition']}',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 7),
                  _buildStatusBadge(status),
                  const SizedBox(height: 6),
                  Text(
                    '${donation['date']} · ID ${donation['id']}',
                    style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        height: 82,
        width: 82,
        color: AppColors.light,
        child: const Icon(Icons.volunteer_activism_outlined, color: AppColors.primary),
      );

  Widget _buildStatusBadge(String status) {
    final active = status == 'Pickup Scheduled' || status == 'Pending';
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
            active ? Icons.schedule_rounded : Icons.check_circle_outline_rounded,
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text('Could not load donation history', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDonations,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

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
              decoration: const BoxDecoration(color: AppColors.light, shape: BoxShape.circle),
              child: const Icon(Icons.volunteer_activism_outlined, size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            const Text(
              'No donations found',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your submitted donations and pickup updates from EcoLoop will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
