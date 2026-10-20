import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';

class ArtistCustomServiceDetails extends StatefulWidget {
  final int serviceId;

  const ArtistCustomServiceDetails({super.key, required this.serviceId});

  @override
  State<ArtistCustomServiceDetails> createState() =>
      _ArtistCustomServiceDetailsState();
}

class _ArtistCustomServiceDetailsState
    extends State<ArtistCustomServiceDetails> {
  final EcoLoopApi api = EcoLoopApi.instance;
  final TextEditingController response = TextEditingController();

  bool loading = true;
  bool saving = false;

  Map<String, dynamic> row = <String, dynamic>{};

  String? error;
  String? status = 'Interested';

  String v(dynamic value) => (value ?? '').toString().trim();

  Map<String, dynamic> m(dynamic value) {
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    response.dispose();
    super.dispose();
  }

  Future<void> load() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      dynamic result = await api.get('/custom-services/${widget.serviceId}');

      for (var depth = 0; depth < 3 && result is Map; depth++) {
        final envelope = m(result);

        if (envelope['service'] is Map) {
          result = envelope['service'];
        } else if (envelope['request'] is Map) {
          result = envelope['request'];
        } else if (envelope['data'] is Map) {
          result = envelope['data'];
        } else {
          break;
        }
      }

      if (result is! Map) {
        throw Exception('The server returned invalid request details.');
      }

      final parsed = m(result);

      if (!mounted) return;

      setState(() {
        row = parsed;
        error = null;

        final currentStatus = v(parsed['status']);

        if (response.text.trim().isEmpty &&
            currentStatus == 'Need more details') {
          final previousResponse = v(parsed['artistResponse']);

          // TextEditingController.value accepts TextEditingValue.
          response.value = TextEditingValue(
            text: previousResponse,
            selection: TextSelection.collapsed(offset: previousResponse.length),
          );
        }

        status =
            <String>[
              'Interested',
              'Need more details',
              'Declined',
            ].contains(currentStatus)
            ? currentStatus
            : 'Interested';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> send() async {
    if (response.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a little more in your response.'),
        ),
      );
      return;
    }

    if (saving) return;

    setState(() => saving = true);

    try {
      await api.post('/artist/custom-services/${widget.serviceId}/respond', {
        'response': response.text.trim(),
        'status': status,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your response has been sent.')),
      );

      await load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        foregroundColor: ArtistColors.primary,
        elevation: 0,
        title: Text(
          'Request details',
          style: ArtistTextStyles.title.copyWith(fontWeight: FontWeight.w800),
        ),
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
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 42,
                      color: ArtistColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: ArtistTextStyles.body,
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: ArtistColors.primary,
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ArtistColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CUSTOM REQUEST #${v(row['serviceId']).isEmpty ? widget.serviceId : v(row['serviceId'])}',
                          style: const TextStyle(
                            color: ArtistColors.light,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₹${v(row['budget']).isEmpty ? '—' : v(row['budget'])}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Budget shared by ${v(row['userName']).isEmpty ? 'Customer' : v(row['userName'])}',
                          style: ArtistTextStyles.body.copyWith(
                            color: ArtistColors.light,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _card(
                    'Project brief',
                    Text(
                      v(row['description']).isEmpty
                          ? 'No description provided.'
                          : v(row['description']),
                      style: ArtistTextStyles.body.copyWith(
                        color: ArtistColors.textPrimary,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    'Customer location',
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: ArtistColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            [v(row['userCity']), v(row['userState'])]
                                    .where((value) => value.isNotEmpty)
                                    .join(', ')
                                    .isEmpty
                                ? 'Location not provided'
                                : [v(row['userCity']), v(row['userState'])]
                                      .where((value) => value.isNotEmpty)
                                      .join(', '),
                            style: const TextStyle(
                              color: ArtistColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (v(row['referenceArtistName']).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _card(
                      'Preferred artist',
                      Text(
                        v(row['referenceArtistName']),
                        style: const TextStyle(
                          color: ArtistColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _card(
                    'Request status',
                    Text(
                      v(row['status']).isEmpty
                          ? 'Status unavailable'
                          : v(row['status']),
                      style: const TextStyle(
                        color: ArtistColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (v(row['artistResponse']).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _card(
                      'Your previous response',
                      Text(
                        v(row['artistResponse']),
                        style: ArtistTextStyles.body.copyWith(
                          color: ArtistColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  if (v(row['artistResponse']).isEmpty ||
                      v(row['status']) == 'Need more details') ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Respond to customer',
                      style: TextStyle(
                        color: ArtistColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      // Flutter 3.33+: use initialValue, not value.
                      initialValue: status,
                      decoration: _dec('Response type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Interested',
                          child: Text('I’m interested'),
                        ),
                        DropdownMenuItem(
                          value: 'Need more details',
                          child: Text('Need more details'),
                        ),
                        DropdownMenuItem(
                          value: 'Declined',
                          child: Text('Unable to take this project'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (newStatus) {
                              if (newStatus == null) return;
                              setState(() => status = newStatus);
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: response,
                      minLines: 3,
                      maxLines: 6,
                      enabled: !saving,
                      decoration: _dec(
                        'Write your response, questions or next steps…',
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: saving ? null : send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtistColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Send response',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ArtistColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: ArtistColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: ArtistColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: ArtistColors.primary, width: 1.5),
      ),
    );
  }
}
