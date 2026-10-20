import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import 'custom_service_details.dart';

class CustomServiceHistory extends StatefulWidget {
  const CustomServiceHistory({super.key});

  @override
  State<CustomServiceHistory> createState() => _CustomServiceHistoryState();
}

class _CustomServiceHistoryState extends State<CustomServiceHistory> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  String _v(dynamic value) => (value ?? '').toString().trim();

  Map<String, dynamic> _map(dynamic value) {
    if (value is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.fromEntries(
      value.entries.map((e) => MapEntry(e.key.toString(), e.value)),
    );
  }

  List<Map<String, dynamic>> _extractRows(dynamic response) {
    dynamic value = response;
    // Apps Script routes normally return a List directly. Also accept common
    // response envelopes so a wrapper change cannot crash this screen.
    for (var i = 0; i < 3 && value is Map; i++) {
      final map = _map(value);
      value =
          map['services'] ??
          map['items'] ??
          map['results'] ??
          map['data'] ??
          map['requests'];
    }
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map<Map<String, dynamic>>((item) => _map(item))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Keep previous request cards on screen while refreshing after details.
    if (mounted && _rows.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() => _error = null);
    }
    try {
      final response = await _api.get('/custom-services/mine');
      final rows = _extractRows(response);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _error = null;
      });
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetails(Map<String, dynamic> row) async {
    final id = int.tryParse(_v(row['serviceId']));
    if (id == null) {
      _message('Request details are unavailable for this item.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomServiceDetails(serviceId: id),
      ),
    );
    if (mounted) _load();
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        'My custom requests',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.title.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh requests',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 90),
                      const Icon(
                        Icons.cloud_off_outlined,
                        size: 54,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Could not load your requests',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption,
                      ),
                      Center(
                        child: TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ),
                    ],
                  )
                : _rows.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(26, 72, 26, 30),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.light),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: AppColors.light,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: const Icon(
                                Icons.design_services_outlined,
                                size: 42,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Your next idea starts here',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.title.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'You haven’t submitted a custom service request yet. Tell us what you’d like an artist to create, and your request and artist replies will appear here.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Go back'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final row = _rows[index];
                      final response = _v(row['artistResponse']);
                      final contacted =
                          _v(row['respondingArtistId']).isNotEmpty &&
                          response.isNotEmpty;
                      final artistName = _v(row['respondingArtistName']);
                      return Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(17),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(17),
                          onTap: () => _openDetails(row),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(color: AppColors.light),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Request #${_v(row['serviceId'])}',
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    _status(_v(row['status'])),
                                  ],
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  _v(row['description']).isEmpty
                                      ? 'Custom project request'
                                      : _v(row['description']),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                                if (row['artistResponses'] is List &&
                                    (row['artistResponses'] as List).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.groups_2_outlined,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${(row['artistResponses'] as List).length} ReMaker response(s)',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 11),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.currency_rupee_rounded,
                                        size: 17,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        _v(row['budget']).isEmpty
                                            ? 'Not specified'
                                            : _v(row['budget']),
                                        softWrap: true,
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 1),
                                      child: Icon(
                                        Icons.schedule_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        _date(
                                          _v(
                                            row['createdAt'] ??
                                                row['created_at'],
                                          ),
                                        ),
                                        softWrap: true,
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 11,
                                          height: 1.4,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                                if (_v(row['referenceArtistName']).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Preferred artist: ${_v(row['referenceArtistName'])}',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                if (contacted) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.light.withValues(
                                        alpha: 0.65,
                                      ),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.mark_chat_unread_outlined,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 9),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$artistName contacted you',
                                                style: AppTextStyles.body
                                                    .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                response,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                      color:
                                                          AppColors.textPrimary,
                                                      height: 1.4,
                                                    ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                'Tap to view details and artist profile',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                      fontSize: 11,
                                                      color: AppColors.primary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
  );

  DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    // Prefer ISO timestamps (including an explicit timezone/offset).
    final iso = DateTime.tryParse(value.replaceFirst(' ', 'T'));
    if (iso != null) {
      final hasZone = RegExp(
        r'(Z|[+-]\d{2}:?\d{2})$',
        caseSensitive: false,
      ).hasMatch(value);
      return hasZone ? iso.toLocal() : iso;
    }

    // Apps Script can also return JavaScript-style dates, e.g.
    // Tue Oct 20 2026 22:10:31 GMT+0530.
    final js = RegExp(
      r'^(?:[A-Za-z]{3},?\s+)?[A-Za-z]{3}\s+(\d{1,2})\s+(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\s+GMT([+-])(\d{2}):?(\d{2}))?(?:\s*\([^)]*\))?$',
      caseSensitive: false,
    ).firstMatch(value);

    if (js != null) {
      final day = int.tryParse(js.group(1)!);
      final year = int.tryParse(js.group(2)!);
      final hour = int.tryParse(js.group(3)!);
      final minute = int.tryParse(js.group(4)!);
      final second = int.tryParse(js.group(5) ?? '0') ?? 0;
      final offsetSign = js.group(6);
      final offsetHour = int.tryParse(js.group(7) ?? '0') ?? 0;
      final offsetMinute = int.tryParse(js.group(8) ?? '0') ?? 0;
      const monthNames = {
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
      final monthMatch = RegExp(
        r'^(?:[A-Za-z]{3},?\s+)?([A-Za-z]{3})\s+',
        caseSensitive: false,
      ).firstMatch(value);
      final month = monthNames[(monthMatch?.group(1) ?? '').toLowerCase()];

      if (day != null &&
          year != null &&
          month != null &&
          hour != null &&
          minute != null) {
        final localLike = DateTime(year, month, day, hour, minute, second);
        if (offsetSign == null) return localLike;
        var offset = Duration(hours: offsetHour, minutes: offsetMinute);
        if (offsetSign == '-') offset = -offset;
        return DateTime.utc(
          year,
          month,
          day,
          hour,
          minute,
          second,
        ).subtract(offset).toLocal();
      }
    }

    // Fallback for common sheet date strings such as 20/10/2026 22:10:31.
    final dmy = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
    ).firstMatch(value);
    if (dmy != null) {
      return DateTime(
        int.parse(dmy.group(3)!),
        int.parse(dmy.group(2)!),
        int.parse(dmy.group(1)!),
        int.tryParse(dmy.group(4) ?? '0') ?? 0,
        int.tryParse(dmy.group(5) ?? '0') ?? 0,
        int.tryParse(dmy.group(6) ?? '0') ?? 0,
      );
    }
    return null;
  }

  String _date(String raw) {
    final date = _parseDate(raw);
    if (date == null) return raw.isEmpty ? 'Date unavailable' : raw;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final time = _formatTime(date);

    if (day == today) return 'Today, $time';
    if (day == today.subtract(const Duration(days: 1)))
      return 'Yesterday, $time';
    return '${date.day} ${_month(date.month)} ${date.year}, $time';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _month(int month) {
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
    return month >= 1 && month <= 12 ? months[month - 1] : '';
  }

  Widget _status(String value) {
    final label = value.isEmpty ? 'Open' : value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
