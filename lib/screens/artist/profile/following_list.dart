import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import 'artist_profile.dart';

/// Shows the live artist accounts followed by the signed-in artist.
class FollowingList extends StatefulWidget {
  const FollowingList({super.key});

  @override
  State<FollowingList> createState() => _FollowingListState();
}

class _FollowingListState extends State<FollowingList> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _artists = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  final Set<int> _updatingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadFollowing();
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
    final result = (value ?? '').toString().trim();
    return result.isEmpty ? fallback : result;
  }

  List<Map<String, dynamic>> get _filteredArtists {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _artists;
    return _artists.where((artist) {
      final name = _text(artist['name'] ?? artist['userName']).toLowerCase();
      final username = _text(artist['username']).toLowerCase();
      final city = _text(artist['city']).toLowerCase();
      return name.contains(query) ||
          username.contains(query) ||
          city.contains(query);
    }).toList();
  }

  Future<void> _loadFollowing({bool refresh = false}) async {
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
      final response = _asMap(await _api.get('/my/following'));
      dynamic rows = response['artists'] ??
          response['following'] ??
          response['data'];

      if (rows is Map) {
        rows = rows['artists'] ?? rows['following'] ?? rows['items'];
      }

      final artists = rows is List
          ? rows
              .whereType<Map>()
              .map((item) => _asMap(item))
              .where((item) => item.isNotEmpty)
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _artists = artists;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _unfollow(Map<String, dynamic> artist) async {
    final id = _toInt(artist['artistId'] ?? artist['id']);
    if (id <= 0 || _updatingIds.contains(id)) return;

    setState(() => _updatingIds.add(id));
    try {
      await _api.delete('/artists/$id/follow');
      if (!mounted) return;
      setState(() {
        _artists.removeWhere(
          (item) => _toInt(item['artistId'] ?? item['id']) == id,
        );
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'You unfollowed ${_text(artist['name'] ?? artist['userName'], fallback: 'this artist')}.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _updatingIds.remove(id));
    }
  }

  void _openArtist(Map<String, dynamic> artist) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArtistProfile(artist: artist)),
    ).then((_) => _loadFollowing(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    final visibleArtists = _filteredArtists;

    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: ArtistColors.textPrimary),
        title: Text('Following', style: ArtistTextStyles.title),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: ArtistColors.primary),
              )
            : RefreshIndicator(
                color: ArtistColors.primary,
                onRefresh: () => _loadFollowing(refresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: ArtistColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: ArtistColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: ArtistColors.light,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: ArtistColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_artists.length} ${_artists.length == 1 ? 'artist' : 'artists'}',
                                  style: ArtistTextStyles.title.copyWith(
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Artists whose work you follow',
                                  style: ArtistTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          if (_refreshing)
                            const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ArtistColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search artists...',
                        hintStyle: ArtistTextStyles.caption,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: ArtistColors.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: _searchController.clear,
                                icon: const Icon(Icons.close_rounded),
                              ),
                        filled: true,
                        fillColor: ArtistColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: ArtistColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: ArtistColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(
                            color: ArtistColors.primary,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _StatusPanel(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load following',
                        message: _error!,
                        actionLabel: 'Try again',
                        onAction: () => _loadFollowing(refresh: true),
                      ),
                    ] else if (visibleArtists.isEmpty) ...[
                      const SizedBox(height: 24),
                      _StatusPanel(
                        icon: _searchController.text.trim().isEmpty
                            ? Icons.people_outline_rounded
                            : Icons.search_off_rounded,
                        title: _searchController.text.trim().isEmpty
                            ? 'You are not following anyone yet'
                            : 'No artists found',
                        message: _searchController.text.trim().isEmpty
                            ? 'Explore the marketplace and follow artists whose creations you like.'
                            : 'Try searching with another name or city.',
                        actionLabel: _searchController.text.trim().isEmpty
                            ? 'Refresh list'
                            : 'Clear search',
                        onAction: _searchController.text.trim().isEmpty
                            ? () => _loadFollowing(refresh: true)
                            : _searchController.clear,
                      ),
                    ] else ...[
                      const SizedBox(height: 15),
                      Text(
                        'ARTISTS YOU FOLLOW',
                        style: ArtistTextStyles.small.copyWith(
                          color: ArtistColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...visibleArtists.map(_buildArtistCard),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildArtistCard(Map<String, dynamic> artist) {
    final id = _toInt(artist['artistId'] ?? artist['id']);
    final name = _text(
      artist['name'] ?? artist['userName'] ?? artist['username'],
      fallback: 'Artist',
    );
    final photo = _text(
      artist['image'] ?? artist['profilePhotoUrl'] ?? artist['profileImage'],
    );
    final city = _text(artist['city']);
    final state = _text(artist['state']);
    final location = [city, state].where((part) => part.isNotEmpty).join(', ');
    final followers = _toInt(artist['followerCount'] ?? artist['followers']);
    final updating = _updatingIds.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openArtist(artist),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: ArtistColors.light,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ArtistColors.primary.withOpacity(0.18),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: photo.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          size: 29,
                          color: ArtistColors.primary,
                        )
                      : Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 29,
                            color: ArtistColors.primary,
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
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ArtistColors.textPrimary,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: ArtistColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ArtistTextStyles.caption,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '$followers ${followers == 1 ? 'follower' : 'followers'}',
                        style: ArtistTextStyles.small.copyWith(
                          color: ArtistColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        onPressed: updating ? null : () => _unfollow(artist),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ArtistColors.primary,
                          side: BorderSide(
                            color: ArtistColors.primary.withOpacity(0.45),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: updating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ArtistColors.primary,
                                ),
                              )
                            : Text(
                                'Following',
                                style: ArtistTextStyles.small.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: ArtistColors.primary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: ArtistColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: ArtistColors.primary),
          const SizedBox(height: 11),
          Text(
            title,
            textAlign: TextAlign.center,
            style: ArtistTextStyles.title.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption.copyWith(height: 1.45),
          ),
          const SizedBox(height: 15),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: ArtistColors.primary,
              side: const BorderSide(color: ArtistColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
