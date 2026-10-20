import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import 'artist_custom_service_details.dart';

class ArtistCustomServices extends StatefulWidget {
  const ArtistCustomServices({super.key});

  @override
  State<ArtistCustomServices> createState() => _ArtistCustomServicesState();
}

class _ArtistCustomServicesState extends State<ArtistCustomServices> {
  final api = EcoLoopApi.instance;
  bool loading = true;
  String? error, filter = 'All';
  List<Map<String, dynamic>> rows = [];

  String v(dynamic x) => (x ?? '').toString();

  Map<String, dynamic> m(dynamic x) {
    if (x is! Map) return <String, dynamic>{};
    return x.map<String, dynamic>(
      (dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value),
    );
  }

  /// Apps Script responses may wrap arrays in data/results/items/services.
  /// Convert each row explicitly to avoid runtime List<dynamic> casts.
  List<Map<String, dynamic>> _asServiceRows(dynamic response) {
    dynamic value = response;
    const wrappers = <String>['services', 'items', 'results', 'data'];
    for (var depth = 0; depth < 4; depth++) {
      if (value is List) {
        return value
            .where((item) => item is Map)
            .map<Map<String, dynamic>>((item) => m(item))
            .toList(growable: false);
      }
      if (value is Map) {
        dynamic next;
        var found = false;
        for (final key in wrappers) {
          if (value.containsKey(key)) {
            next = value[key];
            found = true;
            break;
          }
        }
        if (found) {
          value = next;
          continue;
        }
      }
      break;
    }
    return <Map<String, dynamic>>[];
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      final response = await api.get('/artist/custom-services');
      final parsedRows = _asServiceRows(response);
      if (!mounted) return;
      setState(() {
        rows = parsedRows;
        error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) {
      final status = v(r['status']).trim().toLowerCase();
      final referenceId = int.tryParse(v(r['referenceArtistId'])) ?? 0;
      final respondingId = int.tryParse(v(r['respondingArtistId'])) ?? 0;
      // The backend should filter these too; this client-side guard avoids showing
      // another artist's already-claimed open request if an older deployment returns it.
      if (referenceId == 0 && respondingId != 0) return false;
      if (filter == 'New')
        return status == 'open' || status == 'sent to artist';
      if (filter == 'Responded')
        return v(r['artistResponse']).trim().isNotEmpty;
      return true;
    }).toList();
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        foregroundColor: ArtistColors.primary,
        elevation: 0,
        title: Text(
          'Custom services',
          style: ArtistTextStyles.title.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: ArtistColors.primary),
            )
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: ArtistTextStyles.body,
                    ),
                    TextButton(
                      onPressed: load,
                      child: Text(
                        'Retry',
                        style: ArtistTextStyles.button.copyWith(
                          color: ArtistColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: ArtistColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create something meaningful',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Review briefs and connect with people who need your skills.',
                              style: TextStyle(
                                color: ArtistColors.light,
                                height: 1.35,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ArtistColors.light.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.design_services_outlined,
                          color: ArtistColors.light,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['All', 'New', 'Responded']
                        .map(
                          (x) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(x),
                              selected: filter == x,
                              onSelected: (_) => setState(() => filter = x),
                              selectedColor: ArtistColors.light,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: filter == x
                                    ? ArtistColors.primary
                                    : ArtistColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                              side: BorderSide(color: ArtistColors.border),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: ArtistColors.primary,
                    onRefresh: load,
                    child: visible.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 90),
                              Icon(
                                Icons.inbox_outlined,
                                size: 60,
                                color: ArtistColors.light,
                              ),
                              const SizedBox(height: 14),
                              const Center(
                                child: Text(
                                  'No custom requests here yet',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: ArtistColors.textPrimary,
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(18),
                                child: Text(
                                  'New requests will appear here. Requests addressed to you are prioritised and notified.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: ArtistColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: visible.length,
                            itemBuilder: (c, i) {
                              final r = visible[i];
                              final direct = v(
                                r['referenceArtistId'],
                              ).isNotEmpty;
                              final serviceId = int.tryParse(v(r['serviceId']));
                              return InkWell(
                                borderRadius: BorderRadius.circular(17),
                                onTap: serviceId == null || serviceId <= 0
                                    ? null
                                    : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ArtistCustomServiceDetails(
                                                serviceId: serviceId,
                                              ),
                                        ),
                                      ).then((_) => load()),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(17),
                                    border: Border.all(
                                      color: ArtistColors.border,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Request #${v(r['serviceId'])}',
                                              style: ArtistTextStyles.body
                                                  .copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: ArtistColors.primary,
                                                  ),
                                            ),
                                          ),
                                          if (direct)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF4E6E5),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'Direct request',
                                                style: TextStyle(
                                                  color: ArtistColors.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.chevron_right,
                                            color: ArtistColors.textSecondary,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        v(r['description']),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: ArtistTextStyles.body.copyWith(
                                          color: ArtistColors.textPrimary,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.currency_rupee,
                                            size: 17,
                                            color: ArtistColors.primary,
                                          ),
                                          Text(
                                            v(r['budget']),
                                            style: ArtistTextStyles.body
                                                .copyWith(
                                                  color: ArtistColors.primary,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 15,
                                            color: ArtistColors.textSecondary,
                                          ),
                                          Expanded(
                                            child: Text(
                                              [
                                                    v(r['userCity']),
                                                    v(r['userState']),
                                                  ]
                                                  .where((x) => x.isNotEmpty)
                                                  .join(', '),
                                              style: ArtistTextStyles.caption
                                                  .copyWith(
                                                    color: ArtistColors
                                                        .textSecondary,
                                                    fontSize: 12,
                                                  ),
                                            ),
                                          ),
                                          _status(v(r['status'])),
                                        ],
                                      ),
                                      if (v(
                                        r['referenceArtistName'],
                                      ).isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            'Preferred: ${v(r['referenceArtistName'])}',
                                            style: ArtistTextStyles.caption
                                                .copyWith(
                                                  color: ArtistColors.primary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _status(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: ArtistColors.light.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      s,
      style: ArtistTextStyles.caption.copyWith(
        color: ArtistColors.primary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
