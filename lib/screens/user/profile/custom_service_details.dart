import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../buy_products/artist_profile.dart';

/// User-side details screen for a submitted custom-service request.
/// Uses the existing EcoLoop user theme and live CustomServices API data.
class CustomServiceDetails extends StatefulWidget {
  const CustomServiceDetails({super.key, required this.serviceId});

  final int serviceId;

  @override
  State<CustomServiceDetails> createState() => _CustomServiceDetailsState();
}

class _CustomServiceDetailsState extends State<CustomServiceDetails> {
  final EcoLoopApi _api = EcoLoopApi.instance;

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _row = <String, dynamic>{};

  String _value(dynamic value) => (value ?? '').toString().trim();

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      dynamic result = await _api.get('/custom-services/${widget.serviceId}');

      // Support both the Apps Script's direct object and common response envelopes.
      for (var depth = 0; depth < 4 && result is Map; depth++) {
        final envelope = _asMap(result);
        dynamic nested;
        for (final key in const [
          'service',
          'request',
          'data',
          'result',
          'item',
        ]) {
          if (envelope[key] is Map) {
            nested = envelope[key];
            break;
          }
        }
        if (nested is Map) {
          result = nested;
        } else {
          result = envelope;
          break;
        }
      }

      if (result is! Map) {
        throw Exception('The server returned invalid custom-service details.');
      }

      final row = _asMap(result);
      if (row.isEmpty || _value(row['serviceId']).isEmpty) {
        throw Exception(
          'Request details could not be found. Please refresh and try again.',
        );
      }

      if (!mounted) return;
      setState(() {
        _row = row;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _photos() {
    final raw = _row['photoUrls'];
    dynamic decoded = raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        decoded = <dynamic>[];
      }
    }
    if (decoded is! List) return <String>[];
    return decoded
        .map(_value)
        .where((url) => url.startsWith('https://') || url.startsWith('http://'))
        .toList();
  }

  String get _status =>
      _value(_row['status']).isEmpty ? 'Open' : _value(_row['status']);

  Color get _statusColor {
    final status = _status.toLowerCase();
    if (status.contains('declin') || status.contains('cancel'))
      return AppColors.error;
    if (status.contains('interested') ||
        status.contains('respond') ||
        status.contains('sent')) {
      return const Color(0xFF8A6A12);
    }
    if (status.contains('complete') || status.contains('accept'))
      return AppColors.primary;
    return AppColors.textSecondary;
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return 'Not available';
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed == null) return raw;
    final date = parsed.toLocal();
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
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year} · $hour:$minute $period';
  }

  Future<void> _openArtist() async {
    final profile = _asMap(_row['respondingArtist']);
    final id = int.tryParse(
      _value(profile['artistId']).isNotEmpty
          ? _value(profile['artistId'])
          : _value(_row['respondingArtistId']),
    );
    if (id == null) return;

    final name = _value(profile['userName']).isNotEmpty
        ? _value(profile['userName'])
        : (_value(_row['respondingArtistName']).isNotEmpty
              ? _value(_row['respondingArtistName'])
              : 'ReMaker');
    final artist = <String, dynamic>{
      ...profile,
      'artistId': id,
      'id': id,
      'name': name,
      'userName': name,
      'city': _value(profile['city']),
      'state': _value(profile['state']),
      'profileImageUrl': _value(profile['profilePhotoUrl']),
    };

    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => ArtistProfile(artist: artist)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Request details',
          style: AppTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh request',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 14),
                  _section(
                    'Project brief',
                    Icons.description_outlined,
                    Text(
                      _value(_row['description']).isEmpty
                          ? 'No description was provided.'
                          : _value(_row['description']),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.65,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _section(
                    'Request information',
                    Icons.info_outline_rounded,
                    Column(
                      children: [
                        _detail(
                          'Request ID',
                          '#${_value(_row['serviceId']).isEmpty ? widget.serviceId : _value(_row['serviceId'])}',
                        ),
                        _detail(
                          'Submitted',
                          _formatDate(_value(_row['createdAt'])),
                        ),
                        _detail(
                          'Last updated',
                          _formatDate(_value(_row['updatedAt'])),
                        ),
                        _detail('Budget', _money(_row['budget'])),
                        _detail(
                          'Preferred ReMaker',
                          _value(_row['referenceArtistName']).isEmpty
                              ? 'No preference'
                              : _value(_row['referenceArtistName']),
                        ),
                        _detail(
                          'Location',
                          [
                            _value(_row['userCity']),
                            _value(_row['userState']),
                          ].where((part) => part.isNotEmpty).join(', '),
                        ),
                      ],
                    ),
                  ),
                  if (_photos().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildPhotos(),
                  ],
                  const SizedBox(height: 12),
                  if (_value(_row['artistResponse']).isNotEmpty)
                    _buildArtistResponse()
                  else
                    _buildNextSteps(),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: const BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load request',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.handyman_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'CUSTOM SERVICE',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(.82),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Text(
                '#${_value(_row['serviceId']).isEmpty ? widget.serviceId : _value(_row['serviceId'])}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          Text(
            'Your project budget',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withOpacity(.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _money(_row['budget']),
            style: AppTextStyles.heading.copyWith(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _statusColor == AppColors.error
                        ? const Color(0xFFFFB4AB)
                        : const Color(0xFFC8E6C9),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  _status,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotos() {
    final photos = _photos();
    return _section(
      'Reference photos',
      Icons.photo_library_outlined,
      SizedBox(
        height: 116,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => _showPhoto(photos, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                photos[index],
                width: 116,
                height: 116,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 116,
                  color: AppColors.light,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPhoto(List<String> photos, int initialIndex) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.network(photos[initialIndex], fit: BoxFit.contain),
            ),
            IconButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistResponse() {
    final profile = _asMap(_row['respondingArtist']);
    final photoUrl = _value(profile['profilePhotoUrl']);
    final artistName = _value(_row['respondingArtistName']).isEmpty
        ? 'A ReMaker'
        : _value(_row['respondingArtistName']);
    final hasArtist = _value(_row['respondingArtistId']).isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.mark_chat_unread_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ReMaker response',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _value(_row['artistResponse']),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          if (hasArtist) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.light),
            const SizedBox(height: 13),
            InkWell(
              onTap: _openArtist,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.light,
                      backgroundImage: photoUrl.startsWith('http')
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.startsWith('http')
                          ? null
                          : const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primary,
                            ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artistName,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'View ReMaker profile',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
    final directArtist = _value(_row['referenceArtistName']);
    final message = directArtist.isNotEmpty
        ? 'Your request has been sent to $directArtist. Their reply will appear here when they respond.'
        : 'Your request is saved. ReMakers can review your brief and budget. When a ReMaker responds, their message and profile will appear here.';

    return _section(
      'What happens next?',
      Icons.lightbulb_outline_rounded,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: AppColors.primary,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.light),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(fontSize: 11.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not available' : value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(dynamic value) {
    final amount = double.tryParse(_value(value));
    if (amount == null) return '₹0';
    return '₹${amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2)}';
  }
}
