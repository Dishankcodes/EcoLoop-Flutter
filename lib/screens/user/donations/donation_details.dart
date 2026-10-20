import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'donation_data_cache.dart';

class DonationDetails extends StatefulWidget {
  final Map<String, dynamic> donation;

  const DonationDetails({super.key, required this.donation});

  @override
  State<DonationDetails> createState() => _DonationDetailsState();
}

class _DonationDetailsState extends State<DonationDetails> {
  late Map<String, dynamic> _donation;
  bool _loading = false;
  bool _detailsRequestInFlight = false;
  bool _requestingPickup = false;
  String? _error;
  Map<String, String> _categoryNames = {};

  @override
  void initState() {
    super.initState();
    _donation = _normalize(widget.donation);
    _loadCategories();
    _refreshDetails();
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final dynamic images = raw['imageUrls'];
    String image = raw['image']?.toString() ?? '';
    if (images is List && images.isNotEmpty) image = images.first.toString();

    final rawStatus = (raw['status'] ?? 'pending').toString();
    return {
      ...raw,
      'id': raw['donationId']?.toString() ?? raw['id']?.toString() ?? '',
      'item':
          raw['title']?.toString() ?? raw['item']?.toString() ?? 'Donated Item',
      'category':
          raw['category']?.toString() ??
          raw['categoryName']?.toString() ??
          _categoryNames[raw['categoryId']?.toString()] ??
          (raw['categoryId'] == null
              ? 'Category unavailable'
              : 'Category ${raw['categoryId']}'),
      'condition': _pretty(raw['condition']?.toString() ?? 'used'),
      'status': _prettyStatus(rawStatus),
      'image': image,
      'date': _displayDate(raw['createdAt']?.toString() ?? ''),
      'location': [
        raw['city']?.toString(),
        raw['state']?.toString(),
      ].where((part) => part != null && part.trim().isNotEmpty).join(', '),
      'address': raw['address']?.toString() ?? '',
      'description': raw['description']?.toString() ?? '',
      'pickupDate': raw['pickupDate']?.toString() ?? '',
      'rewardStatus': raw['rewardStatus']?.toString() ?? 'Pending acceptance',
      'rewardPoints': raw['rewardPoints'] ?? 0,
      'rewardCredited':
          raw['rewardCredited'] == true ||
          '${raw['rewardCredited']}'.toLowerCase() == 'true',
    };
  }

  String _pretty(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  String _prettyStatus(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
      case 'submitted':
        return 'Pending';
      case 'pickup_requested':
      case 'requested':
        return 'Pickup Requested';
      case 'pickup scheduled':
        return 'Pickup Scheduled';
      case 'picked_up':
      case 'collected':
        return 'Collected';
      case 'accepted':
      case 'approved':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return _pretty(value);
    }
  }

  String _displayDate(String raw) {
    if (raw.trim().isEmpty) return 'Recently';
    final text = raw.trim();
    final datePart = text.length >= 10 ? text.substring(0, 10) : text;
    final parsed = DateTime.tryParse(datePart);
    if (parsed == null) return raw;
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

  Future<void> _loadCategories() async {
    try {
      final response = await EcoLoopApi.instance.get('/categories');
      final rows = response is List
          ? response
          : response is Map && response['categories'] is List
          ? response['categories'] as List
          : <dynamic>[];
      final names = <String, String>{};
      for (final row in rows.whereType<Map>()) {
        if (row['categoryId'] != null && row['name'] != null) {
          names[row['categoryId'].toString()] = row['name'].toString();
        }
      }
      if (!mounted) return;
      setState(() {
        _categoryNames = names;
        _donation = _normalize(_donation);
      });
    } catch (_) {
      // Keep the donation visible if the category lookup is temporarily unavailable.
    }
  }

  Future<void> _refreshDetails() async {
    if (_detailsRequestInFlight) return;
    final id = (_donation['id'] ?? '').toString();
    if (id.isEmpty || int.tryParse(id) == null) return;

    _detailsRequestInFlight = true;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await EcoLoopApi.instance.get('/donations/$id');
      Map<String, dynamic>? raw;
      if (response is Map) {
        if (response['donation'] is Map) {
          raw = Map<String, dynamic>.from(response['donation'] as Map);
        } else if (response['data'] is Map) {
          raw = Map<String, dynamic>.from(response['data'] as Map);
        } else {
          raw = Map<String, dynamic>.from(response);
        }
      }
      if (raw != null && mounted) {
        setState(() => _donation = _normalize(raw!));
      }
    } catch (e) {
      // Keep the data passed from history visible if refreshing is unavailable.
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _detailsRequestInFlight = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestPickup() async {
    final id = (_donation['id'] ?? '').toString();
    if (id.isEmpty || int.tryParse(id) == null) {
      _message('This donation has no valid ID.');
      return;
    }

    setState(() => _requestingPickup = true);
    try {
      await EcoLoopApi.instance.post('/donations/$id/pickup-request', {});
      DonationDataCache.clear();
      if (!mounted) return;
      _message('Pickup request submitted successfully.');
      await _refreshDetails();
    } catch (e) {
      if (mounted) {
        _message(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _requestingPickup = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value), behavior: SnackBarBehavior.floating),
    );
  }

  bool get _pickupCanBeRequested {
    final status = (_donation['status'] ?? '').toString().toLowerCase();
    return status == 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final status = (_donation['status'] ?? 'Pending').toString();
    final image = (_donation['image'] ?? '').toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Donation Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refreshDetails,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDetails,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            _buildItemHeader(image),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Showing saved details. Refresh error: $_error',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            _buildStatusSection(status),
            _buildPickupSection(),
            _buildDonationInformation(),
            _buildRewardSection(),
            if (_pickupCanBeRequested)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _requestingPickup ? null : _requestPickup,
                    icon: _requestingPickup
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.local_shipping_outlined),
                    label: Text(
                      _requestingPickup
                          ? 'Requesting pickup...'
                          : 'Request Free Pickup',
                    ),
                  ),
                ),
              ),
            _buildEcoLoopMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemHeader(String image) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: image.startsWith('http')
                ? Image.network(
                    image,
                    height: 105,
                    width: 105,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _donation['item'].toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${_donation['category']} • ${_donation['condition']}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Donation ID: ${_donation['id']}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Submitted: ${_donation['date']}',
                  style: const TextStyle(
                    fontSize: 10,
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

  Widget _imagePlaceholder() => Container(
    height: 105,
    width: 105,
    color: AppColors.light,
    child: const Icon(
      Icons.volunteer_activism_outlined,
      size: 35,
      color: AppColors.primary,
    ),
  );

  Widget _buildStatusSection(String status) {
    final lower = status.toLowerCase();
    final submitted = true;
    final pickupActive =
        lower == 'pickup requested' ||
        lower == 'pickup scheduled' ||
        lower == 'collected' ||
        lower == 'completed';
    final completed = lower == 'completed' || lower == 'collected';

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
            subtitle: _donation['date'].toString(),
            completed: submitted,
            active: false,
          ),
          _timelineLine(),
          _timelineStep(
            icon: Icons.local_shipping_outlined,
            title: 'Pickup requested',
            subtitle: pickupActive
                ? status
                : 'Request pickup when you are ready',
            completed: completed,
            active: pickupActive && !completed,
          ),
          _timelineLine(),
          _timelineStep(
            icon: Icons.check_circle_outline_rounded,
            title: 'Donation completed',
            subtitle: completed
                ? 'Item successfully collected'
                : 'Waiting for pickup',
            completed: completed,
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

  Widget _timelineLine() => Container(
    margin: const EdgeInsets.only(left: 18, top: 3, bottom: 3),
    height: 25,
    width: 2,
    color: AppColors.accent,
  );

  Widget _buildPickupSection() {
    final addressParts = [
      _donation['address']?.toString(),
      _donation['city']?.toString(),
      _donation['state']?.toString(),
    ].where((part) => part != null && part.trim().isNotEmpty).toList();
    final location = addressParts.join(', ');

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
            (_donation['pickupDate']?.toString().isNotEmpty ?? false)
                ? _donation['pickupDate'].toString()
                : 'Not scheduled',
          ),
          _infoRow(
            Icons.location_on_outlined,
            'Pickup Location',
            location.isEmpty ? 'Address not available' : location,
          ),
          _infoRow(
            Icons.local_shipping_outlined,
            'Pickup',
            'Free EcoLoop Pickup',
          ),
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
                    'Pickup timing is confirmed by the EcoLoop team. Please keep the item ready after your pickup request is accepted.',
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

  Widget _buildDonationInformation() {
    final description = (_donation['description'] ?? '').toString();
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
            (_donation['category'] ?? 'Other').toString(),
          ),
          _infoRow(
            Icons.check_circle_outline,
            'Condition',
            (_donation['condition'] ?? 'Used').toString(),
          ),
          _infoRow(
            Icons.calendar_today_outlined,
            'Submitted',
            (_donation['date'] ?? 'Recently').toString(),
          ),
          _infoRow(
            Icons.tag_outlined,
            'Donation ID',
            (_donation['id'] ?? '—').toString(),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 2),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardSection() {
    final status = (_donation['status'] ?? '').toString().toLowerCase();
    final accepted =
        status == 'accepted' || status == 'approved' || status == 'completed';
    final rejected = status == 'rejected';
    final label = rejected
        ? 'Not eligible — donation rejected'
        : accepted
        ? 'Donation accepted. Check Rewards for credited points.'
        : 'Pending review — points are not shown as earned yet.';
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
                accepted
                    ? Icons.card_giftcard_rounded
                    : Icons.card_giftcard_outlined,
                color: accepted ? AppColors.success : AppColors.primary,
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
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: rejected
                          ? Colors.red
                          : accepted
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Donation decisions are updated by the EcoLoop team. Reward eligibility is based on the latest status recorded in your donation.',
                    style: TextStyle(
                      fontSize: 9.5,
                      height: 1.35,
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

  Widget _buildEcoLoopMessage() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.eco_outlined, size: 19, color: AppColors.success),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Thank you for giving your unused item another life. Every donation helps reduce waste and supports a more circular community.',
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

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
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
