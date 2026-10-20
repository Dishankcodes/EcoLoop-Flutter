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
  final TextEditingController _messageController = TextEditingController();
  bool _sendingMessage = false;
  bool _loadingArtists = false;
  bool _reassigningArtist = false;
  bool _decidingOffer = false;
  bool _markingWorkDone = false;
  int? _selectedArtistId;
  List<Map<String, dynamic>> _availableArtists = <Map<String, dynamic>>[];

  bool _loading = true;
  bool _hasLoadedOnce = false;
  int _loadGeneration = 0;
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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendAdditionalDetails() async {
    if (_sendingMessage) return;
    final message = _messageController.text.trim();
    if (message.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least 5 characters.')),
      );
      return;
    }
    if (_sendingMessage) return;
    setState(() => _sendingMessage = true);
    try {
      await _api.post('/custom-services/${widget.serviceId}/message', {
        'message': message,
      });
      if (!mounted) return;
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Additional details sent to the ReMaker.'),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final generation = ++_loadGeneration;
    setState(() {
      // On refresh, keep the current details visible instead of replacing the
      // whole screen with a spinner. The first load still shows the loader.
      _loading = !_hasLoadedOnce;
      _error = null;
    });

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

      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _row = row;
        _error = null;
        _hasLoadedOnce = true;
      });
      if (_value(row['status']).toLowerCase() ==
          'waiting for user to choose another artist') {
        await _loadAlternativeArtists();
      }
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  List<Map<String, dynamic>> _offers() {
    final raw = _row['artistResponses'];
    dynamic decoded = raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(raw);
      } catch (_) {
        decoded = <dynamic>[];
      }
    }
    if (decoded is List) {
      final parsed = decoded
          .whereType<Map>()
          .map((item) => _asMap(item))
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }
    final legacyArtistId = int.tryParse(_value(_row['respondingArtistId']));
    if (legacyArtistId != null && _value(_row['artistResponse']).isNotEmpty) {
      return <Map<String, dynamic>>[
        {
          'artistId': legacyArtistId,
          'artistName': _value(_row['respondingArtistName']).isEmpty
              ? 'ReMaker'
              : _value(_row['respondingArtistName']),
          'response': _value(_row['artistResponse']),
          'status': _value(_row['acceptedArtistId']).isNotEmpty
              ? 'Accepted'
              : 'Waiting for user',
        },
      ];
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> _decideOffer(int artistId, String decision) async {
    if (_decidingOffer) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          decision == 'accept' ? 'Accept this ReMaker?' : 'Reject this offer?',
        ),
        content: Text(
          decision == 'accept'
              ? 'Accepting this offer selects this ReMaker for your project. Other offers will be closed.'
              : 'You can continue reviewing other ReMaker offers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(decision == 'accept' ? 'Yes, accept' : 'Reject offer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _decidingOffer = true);
    try {
      await _api.post('/custom-services/${widget.serviceId}/offer-decision', {
        'artistId': artistId,
        'decision': decision,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == 'accept'
                ? 'ReMaker accepted. You can now coordinate your project.'
                : 'Offer rejected.',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) setState(() => _decidingOffer = false);
    }
  }

  Future<void> _markWorkDone() async {
    if (_markingWorkDone) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Mark work as done?'),
        content: const Text(
          'Only confirm this when the custom work has been completed. This will close the request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Work Done'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _markingWorkDone = true);
    try {
      await _api.post(
        '/custom-services/${widget.serviceId}/work-done',
        <String, dynamic>{},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project marked as work done.')),
      );
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) setState(() => _markingWorkDone = false);
    }
  }

  Widget _buildOffers() {
    final offers = _offers();
    final acceptedId = int.tryParse(_value(_row['acceptedArtistId'])) ?? 0;
    final status = _value(_row['status']).toLowerCase();
    final completed = status == 'work done' || status == 'completed';
    if (offers.isEmpty && acceptedId == 0) return _buildNextSteps();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          'ReMaker responses (${offers.length})',
          Icons.groups_2_outlined,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                acceptedId > 0
                    ? 'You have selected a ReMaker. Coordinate the work and mark it done when the project is complete.'
                    : 'Review the offers below. You can accept one ReMaker or reject an offer and continue reviewing others.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ...offers.map((offer) {
                final id = int.tryParse(_value(offer['artistId'])) ?? 0;
                final name = _value(offer['artistName']).isEmpty
                    ? 'ReMaker'
                    : _value(offer['artistName']);
                final response = _value(offer['response']);
                final offerStatus = _value(offer['status']);
                final isAccepted =
                    id == acceptedId || offerStatus.toLowerCase() == 'accepted';
                final pending = offerStatus.toLowerCase() == 'waiting for user';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: isAccepted
                        ? AppColors.light.withValues(alpha: .55)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isAccepted ? AppColors.primary : AppColors.light,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _offerStatusBadge(offerStatus),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        response,
                        style: AppTextStyles.body.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 10),
                      if (id > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              final profile = <String, dynamic>{
                                'artistId': id,
                                'id': id,
                                'name': name,
                                'userName': name,
                              };
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ArtistProfile(artist: profile),
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_outline_rounded),
                            label: const Text('View ReMaker profile'),
                          ),
                        ),
                      if (pending && acceptedId == 0 && !completed) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _decidingOffer
                                    ? null
                                    : () => _decideOffer(id, 'reject'),
                                child: const Text('No, reject'),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: FilledButton(
                                onPressed: _decidingOffer
                                    ? null
                                    : () => _decideOffer(id, 'accept'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                child: const Text('Yes, accept'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (acceptedId > 0 && !completed) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _markingWorkDone ? null : _markWorkDone,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _markingWorkDone
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.task_alt_rounded),
                    label: Text(_markingWorkDone ? 'Updating...' : 'Work Done'),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use this only after the ReMaker has completed the work.',
                  style: AppTextStyles.caption,
                ),
              ],
              if (completed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Project completed on ${_formatDate(_value(_row['workCompletedAt']))}.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _offerStatusBadge(String status) {
    final normalized = status.trim().toLowerCase();
    final isAccepted = normalized == 'accepted';
    final isRejected = normalized == 'rejected' || normalized == 'declined';
    final color = isAccepted
        ? AppColors.primary
        : isRejected
        ? AppColors.error
        : const Color(0xFF8A6A12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty ? 'Waiting for user' : status,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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
    if (status.contains('declined') || status.contains('cancel')) {
      return AppColors.error;
    }
    if (status.contains('interested') ||
        status.contains('respond') ||
        status.contains('sent')) {
      return const Color(0xFF8A6A12);
    }
    if (status.contains('complete') || status.contains('accept')) {
      return AppColors.primary;
    }
    return AppColors.textSecondary;
  }

  DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    final value = raw.trim();
    // Apps Script may append a display-only timezone name, e.g.
    // '(India Standard Time)'. Never show that suffix in the UI.
    final cleanValue = value
        .replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '')
        .trim();

    // First handle ISO timestamps and common Apps Script date strings.
    final iso = DateTime.tryParse(cleanValue.replaceFirst(' ', 'T'));
    if (iso != null) {
      final hasZone = RegExp(
        r'(Z|[+-]\d{2}:?\d{2})$',
        caseSensitive: false,
      ).hasMatch(cleanValue);
      return hasZone ? iso.toLocal() : iso;
    }

    // Example: Tue Oct 20 2026 22:10:31 GMT+0530 (India Standard Time)
    final match = RegExp(
      r'^(?:\w{3}\s+)?(\w{3})\s+(\d{1,2})\s+(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s+GMT([+-])(\d{2}):?(\d{2})',
      caseSensitive: false,
    ).firstMatch(cleanValue);
    if (match != null) {
      const monthNumbers = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };
      final month = monthNumbers[match.group(1)!.toLowerCase()];
      if (month == null) return null;
      final day = int.tryParse(match.group(2)!);
      final year = int.tryParse(match.group(3)!);
      final hour = int.tryParse(match.group(4)!);
      final minute = int.tryParse(match.group(5)!);
      final second = int.tryParse(match.group(6) ?? '0');
      final offsetHour = int.tryParse(match.group(8)!);
      final offsetMinute = int.tryParse(match.group(9)!);
      if ([
        day,
        year,
        hour,
        minute,
        second,
        offsetHour,
        offsetMinute,
      ].any((n) => n == null))
        return null;

      final sign = match.group(7) == '-' ? -1 : 1;
      final offset = Duration(
        hours: sign * offsetHour!,
        minutes: sign * offsetMinute!,
      );
      final local = DateTime(year!, month, day!, hour!, minute!, second!);
      return DateTime.fromMillisecondsSinceEpoch(
        local.millisecondsSinceEpoch - offset.inMilliseconds,
        isUtc: true,
      ).toLocal();
    }

    // Fallback for a timestamp without a timezone.
    return DateTime.tryParse(cleanValue);
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return 'Not available';
    final date = _parseDate(raw);
    if (date == null) {
      return raw.replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final time = _formatTime(date);

    if (day == today) return 'Today, $time';
    if (day == yesterday) return 'Yesterday, $time';

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
    return '${date.day} ${months[date.month - 1]} ${date.year} · $time';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<void> _loadAlternativeArtists() async {
    if (mounted) setState(() => _loadingArtists = true);
    try {
      final result = await _api.get('/custom-services/artists');
      dynamic value = result;
      if (value is Map) {
        value = value['artists'] ?? value['data'] ?? value['items'];
      }
      final parsed = value is List
          ? value.whereType<Map>().map((item) => _asMap(item)).toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _availableArtists = parsed
            .where(
              (artist) =>
                  _value(artist['artistId']).isNotEmpty &&
                  _value(artist['artistId']) !=
                      _value(_row['declinedArtistId']),
            )
            .toList();
        _selectedArtistId = null;
      });
    } catch (_) {
      // Keep the request details usable even if artist discovery temporarily fails.
    } finally {
      if (mounted) setState(() => _loadingArtists = false);
    }
  }

  Future<void> _assignAlternativeArtist() async {
    if (_reassigningArtist) return;
    final id = _selectedArtistId;
    if (id == null || _reassigningArtist) return;
    setState(() => _reassigningArtist = true);
    try {
      await _api.post('/custom-services/${widget.serviceId}/reassign', {
        'referenceArtistId': id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your request has been sent to the selected ReMaker.'),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _reassigningArtist = false);
    }
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
                  _buildOffers(),
                  if (_value(_row['status']).toLowerCase() ==
                      'waiting for user to choose another artist') ...[
                    const SizedBox(height: 12),
                    _buildAlternativeArtistPicker(),
                  ],
                  const SizedBox(height: 12),
                  _buildAdditionalDetailsBox(),
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
            color: AppColors.primary.withValues(alpha: .14),
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
                  color: Colors.white.withValues(alpha: .14),
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
                    color: Colors.white.withValues(alpha: .82),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Text(
                '#${_value(_row['serviceId']).isEmpty ? widget.serviceId : _value(_row['serviceId'])}',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withValues(alpha: .9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 21),
          Text(
            'Your project budget',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: .8),
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
              color: Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: .18)),
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
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => _showPhoto(photos, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                photos[index],
                width: 116,
                height: 116,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
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

  Widget _buildAlternativeArtistPicker() {
    return _section(
      'Choose another ReMaker',
      Icons.person_search_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The preferred ReMaker is unavailable for this request. Select another ReMaker, or use the message box below to add details.',
            style: AppTextStyles.body.copyWith(height: 1.5),
          ),
          const SizedBox(height: 12),
          if (_loadingArtists)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_availableArtists.isEmpty)
            Text(
              'No alternative ReMakers are available right now. Please refresh and try again.',
              style: AppTextStyles.caption,
            )
          else
            DropdownButtonFormField<int>(
              initialValue: _selectedArtistId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Select a ReMaker',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _availableArtists
                  .map((artist) {
                    final id = int.tryParse(_value(artist['artistId']));
                    final name = _value(artist['name']).isNotEmpty
                        ? _value(artist['name'])
                        : 'ReMaker';
                    final location = [
                      _value(artist['city']),
                      _value(artist['state']),
                    ].where((x) => x.isNotEmpty).join(', ');
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(
                        location.isEmpty ? name : '$name · $location',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  })
                  .where((item) => item.value != null)
                  .toList(),
              onChanged: _reassigningArtist
                  ? null
                  : (id) => setState(() => _selectedArtistId = id),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _selectedArtistId == null || _reassigningArtist
                  ? null
                  : _assignAlternativeArtist,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _reassigningArtist
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _reassigningArtist
                    ? 'Sending…'
                    : 'Send request to this ReMaker',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetailsBox() {
    final previous = _value(_row['userMessage']);
    return _section(
      'Need to add more details?',
      Icons.edit_note_rounded,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (previous.isNotEmpty) ...[
            Text(
              'Previously sent details',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(previous, style: AppTextStyles.body.copyWith(height: 1.5)),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _messageController,
            minLines: 3,
            maxLines: 6,
            enabled: !_sendingMessage,
            decoration: InputDecoration(
              hintText:
                  'Share measurements, colours, references, deadline or any other details…',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: AppColors.light),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: AppColors.light),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sendingMessage ? null : _sendAdditionalDetails,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: _sendingMessage
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _sendingMessage ? 'Sending…' : 'Send additional details',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextSteps() {
    final directArtist = _value(_row['referenceArtistName']);
    final currentStatus = _value(_row['status']).toLowerCase();
    final message = currentStatus == 'waiting for user to choose another artist'
        ? 'The preferred ReMaker cannot take this request. You can add more details below and contact another ReMaker from the Choose an artist screen.'
        : directArtist.isNotEmpty
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
            width: 92,
            child: Text(
              label,
              softWrap: true,
              style: AppTextStyles.caption.copyWith(fontSize: 11.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not available' : value,
              softWrap: true,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(dynamic value) {
    final raw = _value(value).replaceAll(',', '').replaceAll('₹', '').trim();
    final amount = double.tryParse(raw);
    if (amount == null) return raw.isEmpty ? '₹0' : '₹$raw';
    final whole = amount == amount.roundToDouble();
    final fixed = whole ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final digits = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '₹${buffer.toString()}${parts.length > 1 ? '.${parts[1]}' : ''}';
  }
}
