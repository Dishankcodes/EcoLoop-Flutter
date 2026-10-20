import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'all_artist.dart';
import 'custom_service_history.dart';

class CustomService extends StatefulWidget {
  const CustomService({
    super.key,
    this.referenceArtistId,
    this.referenceArtistName,
  });

  final int? referenceArtistId;
  final String? referenceArtistName;

  @override
  State<CustomService> createState() => _CustomServiceState();
}

class _CustomServiceState extends State<CustomService> {
  final api = EcoLoopApi.instance;
  final description = TextEditingController();
  final budget = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _artistSearchController = TextEditingController();
  final List<XFile> _photos = [];
  bool loadingArtists = true, submitting = false;
  bool _loadingArtistsRequest = false;
  int _artistLoadGeneration = 0;
  String artistSearchQuery = '';
  String? error;
  List<Map<String, dynamic>> artists = [];
  int? selectedArtist;
  String userCity = '', userState = '';

  @override
  void initState() {
    super.initState();
    selectedArtist = widget.referenceArtistId;
    _loadArtists();
  }

  @override
  void dispose() {
    description.dispose();
    budget.dispose();
    _artistSearchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> map(dynamic x) =>
      x is Map ? x.map((k, v) => MapEntry(k.toString(), v)) : {};

  String val(dynamic x) => (x ?? '').toString().trim();

  Future<void> _loadArtists() async {
    if (_loadingArtistsRequest) return;
    _loadingArtistsRequest = true;
    final generation = ++_artistLoadGeneration;
    try {
      dynamic response = await api.get('/custom-services/artists');
      Map<String, dynamic> payload = map(response);
      // Be tolerant of API wrappers while preserving the backend's city/state ranking.
      for (var depth = 0; depth < 3; depth++) {
        if (payload['data'] is Map) {
          payload = map(payload['data']);
        } else if (payload['result'] is Map) {
          payload = map(payload['result']);
        } else {
          break;
        }
      }
      dynamic rawArtists =
          payload['artists'] ?? payload['items'] ?? payload['results'];
      if (rawArtists is Map) {
        rawArtists =
            rawArtists['artists'] ??
            rawArtists['items'] ??
            rawArtists['results'];
      }
      final loaded = rawArtists is List
          ? rawArtists.whereType<Map>().map((e) => map(e)).toList()
          : <Map<String, dynamic>>[];

      // A profile can preselect an artist who is not in the top-10 recommendations.
      // Keep that selected artist visible so the user understands who will receive the request.
      final selectedId = widget.referenceArtistId;
      if (selectedId != null &&
          !loaded.any(
            (a) => int.tryParse(val(a['artistId'] ?? a['id'])) == selectedId,
          )) {
        loaded.insert(0, <String, dynamic>{
          'artistId': selectedId,
          'name': (widget.referenceArtistName ?? '').trim().isEmpty
              ? 'Selected ReMaker'
              : widget.referenceArtistName!.trim(),
          'city': '',
          'state': '',
          'profilePhotoUrl': '',
          'isPreselected': true,
        });
      }
      if (!mounted || generation != _artistLoadGeneration) return;
      setState(() {
        artists = loaded;
        userCity = val(payload['userCity']);
        userState = val(payload['userState']);
        error = null;
      });
    } catch (e) {
      if (mounted && generation == _artistLoadGeneration) {
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _loadingArtistsRequest = false;
      if (mounted && generation == _artistLoadGeneration) {
        setState(() => loadingArtists = false);
      }
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 78,
        maxWidth: 1600,
      );
      if (!mounted) return;
      setState(() {
        for (final p in picked) {
          if (_photos.length >= 3) break;
          if (!_photos.any((x) => x.path == p.path)) _photos.add(p);
        }
      });
    } catch (e) {
      _message('Could not open photos. Please check photo permissions.');
    }
  }

  Future<void> _submit() async {
    if (submitting) return;
    final d = description.text.trim();
    final b = double.tryParse(budget.text.trim());
    if (d.length < 10) {
      _message('Please describe your project in at least 10 characters.');
      return;
    }
    if (b == null || b <= 0) {
      _message('Enter a valid budget.');
      return;
    }
    setState(() => submitting = true);
    try {
      // Read the selected (maximum three) images concurrently to reduce wait time.
      final photoPayload = await Future.wait(
        _photos.map(
          (photo) async => <String, dynamic>{
            'base64': base64Encode(await photo.readAsBytes()),
            'fileName': photo.name,
            'mimeType': photo.mimeType ?? 'image/jpeg',
          },
        ),
      );
      await api.post('/custom-services', {
        'description': d,
        'budget': b,
        'referenceArtistId': selectedArtist,
        'photoBase64': photoPayload,
      });
      if (!mounted) return;
      _message('Your custom service request has been submitted.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomServiceHistory()),
      );
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _message(String s) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(s),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primary,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      title: const Text(
        'Custom Service',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: [
        IconButton(
          tooltip: 'My requests',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomServiceHistory()),
          ),
          icon: const Icon(Icons.history_rounded),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.handyman_outlined, color: Colors.white, size: 28),
              SizedBox(height: 14),
              Text(
                'Bring your idea to life',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Tell us what you want to create. We’ll help connect you with a suitable ReMaker.',
                style: TextStyle(color: Color(0xFFE1EAE2), height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _heading('Project details', 'Describe your idea clearly'),
        _label('What would you like to make? *'),
        TextField(
          controller: description,
          minLines: 4,
          maxLines: 7,
          maxLength: 1200,
          decoration: _input(
            'Describe your project, size, materials, purpose and any special requirements…',
            Icons.edit_note_rounded,
          ),
        ),
        const SizedBox(height: 14),
        _label('Your budget (₹) *'),
        TextField(
          controller: budget,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _input('e.g. 1500', Icons.currency_rupee_rounded),
        ),
        const SizedBox(height: 7),
        const Text(
          'Share a realistic budget so artists can assess your request.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 18),
        _label('Reference photos (optional)'),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.accent),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add up to 3 inspiration photos',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _photos.length >= 3 ? null : _pickPhotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add photos'),
                  ),
                ],
              ),
              if (_photos.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _photos
                      .map(
                        (p) => Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(p.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _photos.remove(p)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 17,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (widget.referenceArtistId != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'You are requesting a custom service from ${widget.referenceArtistName?.isNotEmpty == true ? widget.referenceArtistName : 'your selected artist'}. You can change this below if you prefer.',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _heading(
          'Choose an artist',
          'Optional — you can also let artists contact you',
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.accent),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              RadioListTile<int?>(
                contentPadding: EdgeInsets.zero,
                value: null,
                groupValue: selectedArtist,
                onChanged: (v) => setState(() => selectedArtist = v),
                activeColor: AppColors.primary,
                title: const Text(
                  'No preference',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Let interested artists contact me',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.accent),
              if (loadingArtists)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else if (artists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No artists are available right now. You can still submit without a reference.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Choose an artist',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (userCity.isNotEmpty)
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
                if (userCity.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Artists in $userCity are shown first for faster service.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _artistSearchController,
                  onChanged: (value) => setState(
                    () => artistSearchQuery = value.trim().toLowerCase(),
                  ),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search artist name or city...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                    ),
                    suffixIcon: artistSearchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _artistSearchController.clear();
                              setState(() => artistSearchQuery = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final query = artistSearchQuery;
                    final filteredArtists = artists
                        .where((a) {
                          if (query.isEmpty) return true;
                          final name = val(
                            a['name'] ?? a['userName'],
                          ).toLowerCase();
                          final city = val(a['city']).toLowerCase();
                          final state = val(a['state']).toLowerCase();
                          return name.contains(query) ||
                              city.contains(query) ||
                              state.contains(query);
                        })
                        .take(10)
                        .toList();
                    if (filteredArtists.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          'No artists match your search. Try another name or location.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        ...filteredArtists.map((a) {
                          final id = int.tryParse(val(a['artistId'])) ?? 0;
                          final city = val(a['city']);
                          final state = val(a['state']);
                          final photo = val(a['profilePhotoUrl']);
                          final same = a['sameCity'] == true;
                          return RadioListTile<int?>(
                            value: id,
                            groupValue: selectedArtist,
                            onChanged: (v) =>
                                setState(() => selectedArtist = v),
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    val(a['name']).isEmpty
                                        ? 'ReMaker'
                                        : val(a['name']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (same)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.light,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Nearby',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              [
                                city,
                                state,
                              ].where((x) => x.isNotEmpty).join(', '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            secondary: CircleAvatar(
                              radius: 23,
                              backgroundColor: AppColors.light,
                              backgroundImage: photo.isNotEmpty
                                  ? NetworkImage(photo)
                                  : null,
                              child: photo.isEmpty
                                  ? const Icon(
                                      Icons.person_outline,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AllArtist(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                            ),
                            label: const Text('View all artists'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.light.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Photos and references are optional. Add clear project details and a budget to help artists understand what you need.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.4,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              submitting ? 'Submitting…' : 'Submit custom request',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomServiceHistory()),
            ),
            icon: const Icon(Icons.history_rounded),
            label: const Text('View my requests'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
      ],
    ),
  );

  Widget _heading(String a, String b) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          a,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          b,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _label(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      s,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  );

  InputDecoration _input(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: AppColors.accent),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: AppColors.accent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.all(14),
  );
}
