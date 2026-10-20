import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../buy_products/artist_profile.dart';

/// Live directory of EcoLoop artists/ReMakers.
/// All artist records and follow state are loaded from the Apps Script API.
class AllArtist extends StatefulWidget {
  const AllArtist({super.key});

  @override
  State<AllArtist> createState() => _AllArtistState();
}

class _AllArtistState extends State<AllArtist> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _artists = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  final Set<int> _updatingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadArtists();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  String _text(dynamic value, {String fallback = ''}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _isFollowing(Map<String, dynamic> artist) {
    final value =
        artist['isFollowing'] ?? artist['following'] ?? artist['is_following'];
    if (value is bool) return value;
    return const {'true', '1', 'yes'}.contains(_text(value).toLowerCase());
  }

  List<Map<String, dynamic>> _extractArtists(dynamic response) {
    dynamic current = response;
    for (var depth = 0; depth < 4; depth++) {
      if (current is List) {
        return current
            .whereType<Map>()
            .map(_asMap)
            .where(_validArtist)
            .toList();
      }
      if (current is! Map) return <Map<String, dynamic>>[];
      final map = _asMap(current);
      dynamic next;
      for (final key in ['artists', 'data', 'results', 'items']) {
        if (map[key] is List) {
          next = map[key];
          break;
        }
        if (map[key] is Map) {
          final nested = _asMap(map[key]);
          for (final nestedKey in ['artists', 'data', 'results', 'items']) {
            if (nested[nestedKey] is List) {
              next = nested[nestedKey];
              break;
            }
          }
          if (next != null) break;
        }
      }
      if (next == null) return <Map<String, dynamic>>[];
      current = next;
    }
    return <Map<String, dynamic>>[];
  }

  bool _validArtist(Map<String, dynamic> artist) {
    final id = _toInt(
      artist['artistId'] ?? artist['artist_id'] ?? artist['id'],
    );
    final name = _text(
      artist['userName'] ?? artist['name'] ?? artist['username'],
    );
    return id > 0 && name.isNotEmpty;
  }

  Future<void> _loadArtists({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      if (refresh) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _error = null;
    });

    try {
      final response = await _api.get('/artists');
      final artists = _extractArtists(response);
      if (!mounted) return;
      setState(() {
        _artists = artists;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredArtists {
    final query = _searchController.text.trim().toLowerCase();
    final list = _artists.where((artist) {
      if (query.isEmpty) return true;
      final fields = <String>[
        _text(artist['userName'] ?? artist['name'] ?? artist['username']),
        _text(artist['city']),
        _text(artist['state']),
        _text(artist['bio']),
        _text(artist['skills']),
      ];
      return fields.any((field) => field.toLowerCase().contains(query));
    }).toList();
    list.sort(
      (a, b) => _text(a['userName'] ?? a['name']).toLowerCase().compareTo(
        _text(b['userName'] ?? b['name']).toLowerCase(),
      ),
    );
    return list;
  }

  String _photoUrl(Map<String, dynamic> artist) {
    final raw = _text(
      artist['profilePhotoUrl'] ??
          artist['profile_photo_url'] ??
          artist['photoUrl'],
    );
    if (raw.isEmpty) return '';
    final match =
        RegExp(
          r'(?:drive\.google\.com|docs\.google\.com)/(?:file/d/|open\?id=|uc\?[^#]*?id=)([A-Za-z0-9_-]+)',
          caseSensitive: false,
        ).firstMatch(raw) ??
        RegExp(r'[?&]id=([A-Za-z0-9_-]+)').firstMatch(raw);
    if (match != null &&
        (raw.contains('drive.google.com') || raw.contains('docs.google.com'))) {
      return 'https://drive.google.com/uc?export=view&id=${match.group(1)}';
    }
    return raw;
  }

  Future<void> _toggleFollow(Map<String, dynamic> artist) async {
    final id = _toInt(
      artist['artistId'] ?? artist['artist_id'] ?? artist['id'],
    );
    if (id <= 0 || _updatingIds.contains(id)) return;
    final wasFollowing = _isFollowing(artist);
    setState(() => _updatingIds.add(id));
    try {
      if (wasFollowing) {
        await _api.delete('/artists/$id/follow');
      } else {
        await _api.post('/artists/$id/follow', <String, dynamic>{});
      }
      if (!mounted) return;
      setState(() {
        final index = _artists.indexWhere(
          (item) =>
              _toInt(item['artistId'] ?? item['artist_id'] ?? item['id']) == id,
        );
        if (index >= 0) {
          _artists[index] = <String, dynamic>{
            ..._artists[index],
            'isFollowing': !wasFollowing,
          };
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFollowing
                ? 'You unfollowed this artist.'
                : 'You are now following this artist.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingIds.remove(id));
    }
  }

  Future<void> _openArtist(Map<String, dynamic> artist) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => ArtistProfile(artist: artist)),
    );
    if (mounted) _loadArtists(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final artists = _filteredArtists;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('All EcoLoop Artists', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.diversity_3_outlined,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Meet our creative community',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Discover ReMakers, explore their work and follow your favourites.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.82),
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by name, city or skill...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.accent.withOpacity(0.45),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.accent.withOpacity(0.45),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        _loading
                            ? 'Loading artists...'
                            : '${artists.length} ${artists.length == 1 ? 'artist' : 'artists'}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (_refreshing)
                        const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      IconButton(
                        onPressed: _loading
                            ? null
                            : () => _loadArtists(refresh: true),
                        tooltip: 'Refresh artists',
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 21,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _error != null
                  ? _messageState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load artists',
                      message: _error!,
                      action: TextButton.icon(
                        onPressed: () => _loadArtists(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    )
                  : artists.isEmpty
                  ? _messageState(
                      icon: _searchController.text.trim().isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.people_outline_rounded,
                      title: _searchController.text.trim().isNotEmpty
                          ? 'No matching artists'
                          : 'No artists available yet',
                      message: _searchController.text.trim().isNotEmpty
                          ? 'Try another name, city or skill.'
                          : 'Artist profiles will appear here when they are available on EcoLoop.',
                      action: _searchController.text.trim().isNotEmpty
                          ? TextButton(
                              onPressed: _searchController.clear,
                              child: const Text('Clear search'),
                            )
                          : null,
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _loadArtists(refresh: true),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        itemCount: artists.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 11),
                        itemBuilder: (context, index) =>
                            _artistCard(artists[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artistCard(Map<String, dynamic> artist) {
    final name = _text(
      artist['userName'] ?? artist['name'] ?? artist['username'],
      fallback: 'EcoLoop Artist',
    );
    final city = _text(artist['city']);
    final state = _text(artist['state']);
    final location = [city, state].where((part) => part.isNotEmpty).join(', ');
    final bio = _text(artist['bio']);
    final skills = _text(artist['skills']);
    final following = _isFollowing(artist);
    final id = _toInt(
      artist['artistId'] ?? artist['artist_id'] ?? artist['id'],
    );
    final photo = _photoUrl(artist);
    final followerCount =
        artist['followerCount'] ??
        artist['followersCount'] ??
        artist['followers'];

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: () => _openArtist(artist),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppColors.accent.withOpacity(0.42)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.light,
                  border: Border.all(color: AppColors.accent.withOpacity(0.7)),
                ),
                clipBehavior: Clip.antiAlias,
                child: photo.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: AppColors.primary,
                      )
                    : Image.network(
                        photo,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          size: 34,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (skills.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        skills,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (followerCount != null &&
                        _text(followerCount).isNotEmpty &&
                        followerCount is! List &&
                        followerCount is! Map) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_toInt(followerCount)} followers',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton(
                        onPressed: _updatingIds.contains(id)
                            ? null
                            : () => _toggleFollow(artist),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: following
                              ? AppColors.primary
                              : Colors.white,
                          backgroundColor: following
                              ? AppColors.surface
                              : AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 7,
                          ),
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _updatingIds.contains(id)
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                following ? 'Following' : 'Follow',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Padding(
                padding: EdgeInsets.only(top: 22),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 10), action],
          ],
        ),
      ),
    );
  }
}
