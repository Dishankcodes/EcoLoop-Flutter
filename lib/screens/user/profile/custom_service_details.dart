import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../buy_products/artist_profile.dart';

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
  Map<String, dynamic> _row = {};

  String _v(dynamic value) => (value ?? '').toString().trim();

  Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.fromEntries(
          value.entries.map((e) => MapEntry(e.key.toString(), e.value)),
        )
      : <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final result = await _api.get('/custom-services/${widget.serviceId}');
      if (!mounted) return;
      setState(() {
        _row = _map(result);
        _error = null;
      });
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _photos() {
    final raw = _row['photoUrls'];
    if (raw is List)
      return raw.map(_v).where((x) => x.startsWith('http')).toList();
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List)
          return decoded.map(_v).where((x) => x.startsWith('http')).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> _openArtist() async {
    final id = int.tryParse(_v(_row['respondingArtistId']));
    if (id == null) return;
    final profile = _map(_row['respondingArtist']);
    final artist = <String, dynamic>{
      ...profile,
      'artistId': id,
      'id': id,
      'name': _v(_row['respondingArtistName']).isEmpty
          ? 'ReMaker'
          : _v(_row['respondingArtistName']),
      'city': _v(profile['city']),
      'state': _v(profile['state']),
      'profileImageUrl': _v(profile['profilePhotoUrl']),
    };
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ArtistProfile(artist: artist)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
          onPressed: _load,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 46,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CUSTOM SERVICE  ·  #${_v(_row['serviceId'])}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withOpacity(.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹${_v(_row['budget'])}',
                        style: AppTextStyles.title.copyWith(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Color(0xFFBFE3C7),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              _v(_row['status']).isEmpty
                                  ? 'Open'
                                  : _v(_row['status']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  'Project brief',
                  Icons.notes_rounded,
                  Text(
                    _v(_row['description']).isEmpty
                        ? 'No description provided.'
                        : _v(_row['description']),
                    style: AppTextStyles.body.copyWith(
                      height: 1.55,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  'Request details',
                  Icons.info_outline_rounded,
                  Column(
                    children: [
                      _detail('Submitted', _date(_v(_row['createdAt']))),
                      _detail('Budget', '₹${_v(_row['budget'])}'),
                      _detail(
                        'Preferred artist',
                        _v(_row['referenceArtistName']).isEmpty
                            ? 'No preference — open to interested artists'
                            : _v(_row['referenceArtistName']),
                      ),
                      _detail(
                        'Location',
                        [
                          _v(_row['userCity']),
                          _v(_row['userState']),
                        ].where((x) => x.isNotEmpty).join(', '),
                      ),
                    ],
                  ),
                ),
                if (_photos().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _section(
                    'Reference photos',
                    Icons.photo_library_outlined,
                    SizedBox(
                      height: 108,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos().length,
                        separatorBuilder: (_, __) => const SizedBox(width: 9),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _photos()[i],
                            width: 108,
                            height: 108,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 108,
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
                ],
                if (_v(_row['artistResponse']).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(17),
                    child: InkWell(
                      onTap: _v(_row['respondingArtistId']).isNotEmpty
                          ? _openArtist
                          : null,
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: AppColors.light),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.mark_chat_unread_outlined,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_v(_row['respondingArtistName']).isEmpty ? 'An artist' : _v(_row['respondingArtistName'])} contacted you',
                                    style: AppTextStyles.title.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                if (_v(_row['respondingArtistId']).isNotEmpty)
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _v(_row['artistResponse']),
                              style: AppTextStyles.body.copyWith(
                                height: 1.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (_v(_row['respondingArtistId']).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 19,
                                    backgroundColor: AppColors.light,
                                    backgroundImage:
                                        _v(
                                          _map(
                                            _row['respondingArtist'],
                                          )['profilePhotoUrl'],
                                        ).startsWith('http')
                                        ? NetworkImage(
                                            _v(
                                              _map(
                                                _row['respondingArtist'],
                                              )['profilePhotoUrl'],
                                            ),
                                          )
                                        : null,
                                    child:
                                        !_v(
                                          _map(
                                            _row['respondingArtist'],
                                          )['profilePhotoUrl'],
                                        ).startsWith('http')
                                        ? const Icon(
                                            Icons.person_outline,
                                            color: AppColors.primary,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'View artist profile',
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          [
                                                _v(
                                                  _map(
                                                    _row['respondingArtist'],
                                                  )['city'],
                                                ),
                                                _v(
                                                  _map(
                                                    _row['respondingArtist'],
                                                  )['state'],
                                                ),
                                              ]
                                              .where((x) => x.isNotEmpty)
                                              .join(', '),
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 17,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  _section(
                    'What happens next?',
                    Icons.info_outline_rounded,
                    const Text(
                      'Your request is saved. If you selected an artist, they can respond directly. If you chose no preference, interested artists can review the request and contact you. Their replies will appear here.',
                      style: TextStyle(
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
  );

  Widget _section(String title, IconData icon, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.light),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 9),
            Text(
              title,
              style: AppTextStyles.title.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        child,
      ],
    ),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 112, child: Text(label, style: AppTextStyles.caption)),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );

  String _date(String raw) {
    final date = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (date == null) return raw.isEmpty ? '—' : raw;
    final d = date.toLocal();
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  static const _months = [
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
}
