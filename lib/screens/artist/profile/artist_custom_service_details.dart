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
    String? declineAction;
    if (status == 'Declined' && v(row['referenceArtistId']).isNotEmpty) {
      declineAction = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: ArtistColors.background,
          title: const Text('You are not interested in this request'),
          content: const Text('What should happen to this request?'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, 'choose_another_artist'),
              child: const Text('Let user choose another artist'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, 'open_for_all'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open for all artists'),
            ),
          ],
        ),
      );
      if (declineAction == null) return;
    }
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
        if (declineAction != null) 'declineAction': declineAction,
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

  List<String> _photoUrls() {
    final dynamic raw = row['photoUrls'] ?? row['photos'] ?? row['images'];
    if (raw is List) {
      return raw
          .map((item) {
            if (item is Map) return v(item['url'] ?? item['photoUrl']);
            return v(item);
          })
          .where(
            (url) => url.startsWith('http://') || url.startsWith('https://'),
          )
          .toList();
    }
    return <String>[];
  }

  Map<String, dynamic> get _contact =>
      m(row['customerContact'] ?? row['userContact']);

  String _joinedAddress() {
    final contact = _contact;
    final address = m(contact['address']);
    final parts = <String>[
      v(address['addressLine']),
      v(address['area']),
      v(address['city']),
      v(address['state']),
      v(address['pincode']),
    ].where((part) => part.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');
    return <String>[
      v(row['userCity']),
      v(row['userState']),
    ].where((part) => part.isNotEmpty).join(', ');
  }

  void _showCustomerProfile() {
    final contact = _contact;
    final address = m(contact['address']);
    final name = v(contact['name']).isNotEmpty
        ? v(contact['name'])
        : v(row['userName']).isNotEmpty
        ? v(row['userName'])
        : 'Customer';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: ArtistColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ArtistColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: ArtistColors.light,
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: ArtistColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: ArtistTextStyles.title.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Custom service customer',
                            style: ArtistTextStyles.body.copyWith(
                              color: ArtistColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _contactRow(
                  Icons.phone_outlined,
                  'Phone number',
                  v(contact['phone']).isEmpty
                      ? 'Not provided'
                      : v(contact['phone']),
                ),
                _contactRow(
                  Icons.email_outlined,
                  'Email address',
                  v(contact['email']).isEmpty
                      ? 'Not provided'
                      : v(contact['email']),
                ),
                _contactRow(
                  Icons.location_on_outlined,
                  'Address',
                  _joinedAddress().isEmpty
                      ? 'Address not provided'
                      : _joinedAddress(),
                ),
                if (v(address['name']).isNotEmpty)
                  _contactRow(
                    Icons.person_pin_circle_outlined,
                    'Address recipient',
                    v(address['name']),
                  ),
                if (v(address['phone']).isNotEmpty &&
                    v(address['phone']) != v(contact['phone']))
                  _contactRow(
                    Icons.call_outlined,
                    'Address contact',
                    v(address['phone']),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Done'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ArtistColors.primary,
                      side: const BorderSide(color: ArtistColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ArtistColors.light.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: ArtistColors.primary, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: ArtistColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestPhotos() {
    final photos = _photoUrls();
    if (photos.isEmpty) {
      return _card(
        'Reference photos',
        Row(
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: ArtistColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No reference photos were attached to this request.',
                style: ArtistTextStyles.body.copyWith(
                  color: ArtistColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _card(
      'Reference photos (${photos.length})',
      SizedBox(
        height: 176,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 0.95,
              child: Image.network(
                photos[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: ArtistColors.light,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: ArtistColors.primary,
                      size: 32,
                    ),
                  ),
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Container(
                        color: ArtistColors.light,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: ArtistColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
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
                  _requestPhotos(),
                  const SizedBox(height: 12),
                  _card(
                    'Customer contact',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: ArtistColors.light,
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: ArtistColors.primary,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v(_contact['name']).isEmpty
                                        ? (v(row['userName']).isEmpty
                                              ? 'Customer'
                                              : v(row['userName']))
                                        : v(_contact['name']),
                                    style: const TextStyle(
                                      color: ArtistColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'Request posted by customer',
                                    style: ArtistTextStyles.body.copyWith(
                                      color: ArtistColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _contactRow(
                          Icons.phone_outlined,
                          'Phone',
                          v(_contact['phone']).isEmpty
                              ? 'Not provided by customer'
                              : v(_contact['phone']),
                        ),
                        _contactRow(
                          Icons.email_outlined,
                          'Email',
                          v(_contact['email']).isEmpty
                              ? 'Not provided by customer'
                              : v(_contact['email']),
                        ),
                        _contactRow(
                          Icons.location_on_outlined,
                          'Full address',
                          _joinedAddress().isEmpty
                              ? 'No saved address — location shown below'
                              : _joinedAddress(),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showCustomerProfile,
                            icon: const Icon(Icons.account_circle_outlined),
                            label: const Text('View customer profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ArtistColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                  if (v(row['userMessage']).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _card(
                      'Additional details from customer',
                      Text(
                        v(row['userMessage']),
                        style: ArtistTextStyles.body.copyWith(
                          color: ArtistColors.textPrimary,
                          height: 1.5,
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
                  if (int.tryParse(v(row['acceptedArtistId'])) != null) ...[
                    const SizedBox(height: 12),
                    _card(
                      'Project progress',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            int.tryParse(v(row['acceptedArtistId'])) ==
                                    int.tryParse(v(row['respondingArtistId']))
                                ? 'The user accepted your offer. Please coordinate the work with the customer.'
                                : (int.tryParse(v(row['acceptedArtistId'])) ==
                                          int.tryParse(v(row['artistId']))
                                      ? 'Your offer was accepted.'
                                      : 'The user selected another ReMaker for this project.'),
                            style: ArtistTextStyles.body.copyWith(
                              color: ArtistColors.primary,
                              height: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (v(row['status']).toLowerCase() == 'work done' ||
                              v(row['status']).toLowerCase() ==
                                  'completed') ...[
                            const SizedBox(height: 8),
                            const Text(
                              'The user marked this work as done.',
                              style: TextStyle(
                                color: ArtistColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (v(row['artistOfferStatus']).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _card(
                      'Your offer status',
                      Text(
                        v(row['artistOfferStatus']),
                        style: const TextStyle(
                          color: ArtistColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  if (v(row['artistResponse']).isNotEmpty &&
                      int.tryParse(v(row['acceptedArtistId'])) == null &&
                      v(row['artistOfferStatus']).toLowerCase() ==
                          'waiting for user') ...[
                    const SizedBox(height: 12),
                    _card(
                      'Waiting for the user',
                      const Text(
                        'Your offer has been sent. The user can review your response and accept or reject it. You will be notified when they decide.',
                      ),
                    ),
                  ],
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
                  if ((v(row['artistResponse']).isEmpty ||
                          v(row['status']) == 'Need more details') &&
                      int.tryParse(v(row['acceptedArtistId'])) == null &&
                      v(row['status']).toLowerCase() != 'work done' &&
                      v(row['status']).toLowerCase() != 'completed') ...[
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
