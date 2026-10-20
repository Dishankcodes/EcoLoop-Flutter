import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import 'artist_profile.dart';

class Followers extends StatefulWidget {
  const Followers({super.key});

  @override
  State<Followers> createState() => _FollowersState();
}

class _FollowersState extends State<Followers> {
  final TextEditingController _searchController = TextEditingController();

  final EcoLoopApi _api = EcoLoopApi.instance;

  // Reuse the signed-in artist ID while this app session is alive so opening
  // this screen again does not need to fetch /profile before fetching followers.
  static int _cachedArtistId = 0;
  static List<Map<String, dynamic>>? _cachedFollowers;
  static int _cachedTotalFollowers = 0;
  static DateTime? _followersCachedAt;
  static const Duration _followersCacheDuration = Duration(minutes: 2);
  Timer? _liveRefreshTimer;
  bool _requestInFlight = false;

  List<Map<String, dynamic>> _followers = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  int _artistId = 0;
  int _totalFollowers = 0;

  List<Map<String, dynamic>> get _filteredFollowers {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _followers;
    }

    return _followers.where((follower) {
      final name = follower['name']?.toString().toLowerCase() ?? '';
      final username = follower['username']?.toString().toLowerCase() ?? '';

      return name.contains(query) || username.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    final cached = _cachedFollowers;
    final cachedAt = _followersCachedAt;
    final cacheIsFresh =
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _followersCacheDuration;

    // Show the previous result synchronously; don't block the UI on Sheets.
    if (cached != null) {
      _followers = cached
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      _totalFollowers = _cachedTotalFollowers;
      _loading = false;
    }
    // A fresh cache avoids another Apps Script round trip on quick revisits.
    // Stale cache remains visible while a quiet refresh happens in background.
    _loadFollowers(silent: cached != null, skipIfFresh: cacheIsFresh);
    // No aggressive polling: refresh manually or when this screen is reopened.
    // Repeated Apps Script requests every few seconds make the app slower.
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // OPEN PUBLIC ARTIST PROFILE
  // ============================================================

  void _openArtistProfile(Map<String, dynamic> follower) {
    if (_normaliseRole(
          follower['role'] ?? follower['accountType'] ?? follower['sellerType'],
        ) !=
        'artist') {
      _showMessage('This follower has a user account.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArtistProfile(artist: follower)),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    return value is List ? value : <dynamic>[];
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  String _normaliseRole(dynamic value) {
    final role = (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    if (const {'artist', 'remaker', 're_maker'}.contains(role)) return 'artist';
    if (const {'user', 'seller', 'customer'}.contains(role)) return 'user';
    return role;
  }

  Future<void> _loadFollowers({
    bool refresh = false,
    bool silent = false,
    bool skipIfFresh = false,
    bool force = false,
  }) async {
    if (!mounted || _requestInFlight) return;
    final cachedAt = _followersCachedAt;
    final cacheIsFresh =
        _cachedFollowers != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _followersCacheDuration;
    if (!force && (skipIfFresh || cacheIsFresh)) return;
    _requestInFlight = true;

    if (!silent) {
      setState(() {
        if (refresh && _followers.isNotEmpty) {
          _refreshing = true;
        } else if (_followers.isEmpty) {
          _loading = true;
        }
        _error = null;
      });
    }

    try {
      var artistId = _artistId > 0 ? _artistId : _cachedArtistId;

      // The profile request is needed only once per app session. Reusing this
      // ID removes one serial network round trip from subsequent page opens.
      if (artistId <= 0) {
        final profile = _asMap(await _api.get('/profile'));
        artistId = _toInt(profile['artistId'] ?? profile['id']);
        if (artistId <= 0) {
          throw const EcoLoopApiException(
            'Could not identify the signed-in artist account.',
          );
        }
        _cachedArtistId = artistId;
      }

      final response = _asMap(await _api.get('/artists/$artistId/followers'));
      final rawList = _asList(response['followers']);
      final seen = <String>{};
      final list = <Map<String, dynamic>>[];
      for (final item in rawList) {
        final follower = _asMap(item);
        if (follower.isEmpty) continue;
        final id = _toInt(
          follower['userId'] ??
              follower['followerId'] ??
              follower['artistId'] ??
              follower['id'],
        );
        final key = id > 0
            ? '$id'
            : '${follower['email'] ?? follower['username'] ?? follower['name']}';
        if (seen.add(key)) list.add(follower);
      }

      if (!mounted) return;
      setState(() {
        _artistId = artistId;
        // Use the returned count when present; otherwise keep the displayed
        // count consistent with the unique rows we actually render.
        _totalFollowers = response.containsKey('count')
            ? _toInt(response['count'])
            : list.length;
        _followers = list;
        _cachedFollowers = list
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _cachedTotalFollowers = _totalFollowers;
        _followersCachedAt = DateTime.now();
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      // Background refresh failures should not blank an already-loaded list.
      if (!silent || _followers.isEmpty) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      _requestInFlight = false;
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _toggleFollow(Map<String, dynamic> follower) async {
    final role = _normaliseRole(
      follower['role'] ?? follower['accountType'] ?? follower['sellerType'],
    );
    final targetId = _toInt(follower['artistId'] ?? follower['id']);
    if (role != 'artist' || targetId <= 0) {
      _showMessage('Only artist accounts can be followed.');
      return;
    }
    if (targetId == _artistId) {
      _showMessage('You cannot follow your own profile.');
      return;
    }

    final wasFollowing = follower['following'] == true;
    try {
      if (wasFollowing) {
        await _api.delete('/artists/$targetId/follow');
      } else {
        await _api.post('/artists/$targetId/follow', <String, dynamic>{});
      }
      await _loadFollowers(refresh: true, force: true);
      if (mounted) {
        final name = (follower['name'] ?? follower['userName'] ?? 'artist')
            .toString();
        _showMessage(wasFollowing ? 'Unfollowed $name' : 'Following $name');
      }
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFollowers;

    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
            size: 23,
          ),
        ),
        title: Text(
          'Followers',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'More',
            onPressed: _showMoreOptions,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: ArtistColors.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 5, 20, 24),
          child: _error != null && _followers.isEmpty && !_loading
              ? _buildLoadError()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildFollowerSummary(),
                    const SizedBox(height: 14),
                    _buildSearch(),
                    const SizedBox(height: 18),
                    _buildFollowerTitle(filtered.length),
                    const SizedBox(height: 10),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _error!,
                          style: ArtistTextStyles.caption.copyWith(
                            color: ArtistColors.textSecondary,
                          ),
                        ),
                      ),
                    filtered.isEmpty
                        ? _buildEmptyState()
                        : _buildFollowerList(filtered),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Community',
                style: ArtistTextStyles.heading.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'People who follow your artwork and creations.',
                style: ArtistTextStyles.body.copyWith(
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: ArtistColors.light,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.groups_rounded,
            color: ArtistColors.primary,
            size: 27,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FOLLOWER SUMMARY
  // ============================================================

  Widget _buildFollowerSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withOpacity(0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
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
              Icons.people_alt_rounded,
              color: ArtistColors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_totalFollowers',
                style: ArtistTextStyles.heading.copyWith(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Total Followers',
                style: ArtistTextStyles.caption.copyWith(fontSize: 10),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      style: ArtistTextStyles.body.copyWith(
        color: ArtistColors.textPrimary,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: 'Search followers...',
        hintStyle: ArtistTextStyles.hint.copyWith(fontSize: 13),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: ArtistColors.primary,
          size: 22,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: ArtistColors.textSecondary,
                  size: 19,
                ),
              )
            : null,
        filled: true,
        fillColor: ArtistColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
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
          borderSide: const BorderSide(color: ArtistColors.primary, width: 1.2),
        ),
      ),
    );
  }

  // ============================================================
  // FOLLOWER TITLE
  // ============================================================

  Widget _buildFollowerTitle(int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'All Followers',
            style: ArtistTextStyles.title.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$count ${count == 1 ? 'person' : 'people'}',
          style: ArtistTextStyles.caption.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FOLLOWER LIST
  // ============================================================

  Widget _buildFollowerList(List<Map<String, dynamic>> followers) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: followers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        return _buildFollowerCard(followers[index]);
      },
    );
  }

  // ============================================================
  // FOLLOWER CARD
  // ============================================================

  Widget _buildFollowerCard(Map<String, dynamic> follower) {
    final bool isFollowing = follower['following'] == true;

    final String name =
        follower['name']?.toString() ??
        follower['userName']?.toString() ??
        'EcoLoop User';

    final String username = _displayUsername(follower);

    final String followerCount = follower['followers']?.toString() ?? '';

    final String image =
        follower['image']?.toString() ??
        follower['profilePhotoUrl']?.toString() ??
        '';

    final bool canFollow =
        follower['canFollow'] == true &&
        _normaliseRole(
              follower['role'] ??
                  follower['accountType'] ??
                  follower['sellerType'],
            ) ==
            'artist';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),

        // ======================================================
        // THIS OPENS THE PUBLIC ARTIST PROFILE
        // ======================================================
        onTap: () {
          _openArtistProfile(follower);
        },

        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ArtistColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ArtistColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 7,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildProfileImage(image, name),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ArtistTextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),

                        if (follower['verified'] == true)
                          const Icon(
                            Icons.verified_rounded,
                            color: ArtistColors.primary,
                            size: 14,
                          ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.caption.copyWith(fontSize: 10),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          color: ArtistColors.textMuted,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          followerCount,
                          style: ArtistTextStyles.caption.copyWith(
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Keep button separate so tapping it does NOT
              // open the artist profile.
              _buildFollowButton(follower, isFollowing, canFollow),

              const SizedBox(width: 3),

              const Icon(
                Icons.chevron_right_rounded,
                color: ArtistColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayUsername(Map<String, dynamic> follower) {
    final raw = (follower['username'] ?? follower['userName'] ?? '')
        .toString()
        .trim();
    if (raw.isEmpty) return '';
    return raw.startsWith('@') ? raw : '@$raw';
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: ArtistColors.primary,
              size: 38,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load followers',
              style: ArtistTextStyles.title.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => _loadFollowers(force: true),
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  Widget _buildProfileImage(String image, String name) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: image.isEmpty
          ? _profileFallback(name)
          : Image.network(
              image,
              width: 56,
              height: 56,
              cacheWidth: 112,
              cacheHeight: 112,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _profileFallback(name);
              },
            ),
    );
  }

  // ============================================================
  // PROFILE FALLBACK
  // ============================================================

  Widget _profileFallback(String name) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';

    return Container(
      width: 56,
      height: 56,
      color: ArtistColors.light,
      child: Center(
        child: Text(
          initial,
          style: ArtistTextStyles.title.copyWith(
            color: ArtistColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FOLLOW BUTTON
  // ============================================================

  Widget _buildFollowButton(
    Map<String, dynamic> follower,
    bool isFollowing,
    bool canFollow,
  ) {
    final bool enabled = canFollow || isFollowing;
    final String label =
        _normaliseRole(
              follower['role'] ??
                  follower['accountType'] ??
                  follower['sellerType'],
            ) ==
            'artist'
        ? (isFollowing ? 'Following' : 'Follow')
        : 'User';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? () => _toggleFollow(follower) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: isFollowing ? ArtistColors.light : ArtistColors.primary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ArtistColors.primary),
          ),
          child: Text(
            label,
            style: ArtistTextStyles.caption.copyWith(
              color: isFollowing ? ArtistColors.primary : Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: ArtistColors.light,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              color: ArtistColors.primary,
              size: 33,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'No followers found',
            style: ArtistTextStyles.title.copyWith(fontSize: 17),
          ),

          const SizedBox(height: 5),

          Text(
            'Try searching with a different name or username.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.body.copyWith(fontSize: 11.5),
          ),

          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 14),

            OutlinedButton(
              onPressed: () {
                _searchController.clear();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ArtistColors.primary,
                side: const BorderSide(color: ArtistColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
              ),
              child: Text(
                'Clear Search',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.primary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // MORE OPTIONS
  // ============================================================

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ArtistColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 17),

                _buildMoreOption(
                  icon: Icons.people_outline_rounded,
                  title: 'Follower Overview',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage('Follower overview is available here.');
                  },
                ),

                _buildMoreOption(
                  icon: Icons.refresh_rounded,
                  title: 'Refresh Followers',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _loadFollowers(refresh: true, force: true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MORE OPTION
  // ============================================================

  Widget _buildMoreOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ArtistColors.light,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: ArtistColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: ArtistTextStyles.bodyMedium.copyWith(
          color: ArtistColors.textPrimary,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: ArtistColors.textMuted,
      ),
      onTap: onTap,
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: ArtistTextStyles.body.copyWith(
              color: Colors.white,
              fontSize: 11.5,
            ),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.accent,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      );
  }
}
