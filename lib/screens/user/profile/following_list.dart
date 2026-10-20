import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../buy_products/artist_profile.dart';

/// Shows only artists/ReMakers the signed-in user currently follows.
class FollowingList extends StatefulWidget {
  const FollowingList({super.key});

  @override
  State<FollowingList> createState() => _FollowingListState();
}

class _FollowingListState extends State<FollowingList> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _following = [];
  bool _loading = true;
  String? _error;
  final Set<String> _unfollowingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _rowsFrom(dynamic value) {
    dynamic rows = value;
    if (rows is Map) {
      rows =
          rows['following'] ??
          rows['artists'] ??
          rows['results'] ??
          rows['data'] ??
          rows['items'];
      if (rows is Map) {
        rows =
            rows['following'] ??
            rows['artists'] ??
            rows['results'] ??
            rows['items'];
      }
    }
    if (rows is! List) return <Map<String, dynamic>>[];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .where((row) => _artistId(row).isNotEmpty)
        .toList();
  }

  String _firstValue(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  String _artistId(Map<String, dynamic> row) =>
      _firstValue(row, ['artistId', 'artist_id', 'id']);

  String _artistName(Map<String, dynamic> row) => _firstValue(row, [
    'name',
    'userName',
    'username',
    'artistName',
  ]).ifEmpty('ReMaker');

  String _avatar(Map<String, dynamic> row) => _firstValue(row, [
    'profilePhotoUrl',
    'image',
    'profileImageUrl',
    'avatarUrl',
  ]);

  String _location(Map<String, dynamic> row) {
    final direct = _firstValue(row, ['location', 'address']);
    if (direct.isNotEmpty) return direct;
    final city = _firstValue(row, ['city']);
    final state = _firstValue(row, ['state']);
    if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
    return city.isNotEmpty ? city : state;
  }

  String _normaliseImageUrl(String raw) {
    final url = raw.trim();
    if (url.isEmpty) return '';
    final match =
        RegExp(
          r'(?:drive\.google\.com|docs\.google\.com)/(?:file/d/|open\?id=|uc\?[^#]*?id=)([A-Za-z0-9_-]+)',
          caseSensitive: false,
        ).firstMatch(url) ??
        RegExp(r'[?&]id=([A-Za-z0-9_-]+)').firstMatch(url);
    if (match != null &&
        (url.contains('drive.google.com') || url.contains('docs.google.com'))) {
      return 'https://drive.google.com/uc?export=view&id=${match.group(1)}';
    }
    return url;
  }

  Future<void> _loadFollowing({bool showLoader = true}) async {
    if (showLoader && mounted && _following.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() => _error = null);
    }
    try {
      final result = await _api.get('/my/following');
      final rows = _rowsFrom(result);
      if (!mounted) return;
      setState(() {
        _following = rows;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  List<Map<String, dynamic>> get _filteredFollowing {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _following;
    return _following.where((artist) {
      final searchable = [
        _artistName(artist),
        _location(artist),
        _firstValue(artist, ['bio', 'skills', 'category']),
        _firstValue(artist, ['username', 'userName']),
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Future<void> _unfollow(Map<String, dynamic> artist) async {
    final id = _artistId(artist);
    if (id.isEmpty || _unfollowingIds.contains(id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Unfollow ${_artistName(artist)}?',
          style: AppTextStyles.title,
        ),
        content: Text(
          'Their profile will be removed from your following list. You can follow them again anytime.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _unfollowingIds.add(id));
    try {
      await _api.delete('/artists/$id/follow');
      if (!mounted) return;
      setState(() {
        _following.removeWhere((item) => _artistId(item) == id);
        _unfollowingIds.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unfollowed ${_artistName(artist)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _unfollowingIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not unfollow this artist: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openArtist(Map<String, dynamic> artist) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ArtistProfile(artist: artist)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filteredFollowing;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text('My Following', style: AppTextStyles.title),
        actions: [
          IconButton(
            tooltip: 'Refresh following list',
            onPressed: () => _loadFollowing(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search artists or locations...',
                    hintStyle: AppTextStyles.caption,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people_alt_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Artists & ReMakers',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_following.length} ${_following.length == 1 ? 'artist' : 'artists'} followed',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _following.isEmpty
                  ? _stateMessage(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load your following list',
                      message: _error!,
                      actionLabel: 'Try again',
                      onAction: () => _loadFollowing(),
                    )
                  : _following.isEmpty
                  ? _stateMessage(
                      icon: Icons.person_add_alt_1_outlined,
                      title: 'No artists followed yet',
                      message:
                          'When you follow an artist or ReMaker, they will appear here.',
                      actionLabel: 'Explore marketplace',
                      onAction: () => Navigator.pop(context),
                    )
                  : visible.isEmpty
                  ? _stateMessage(
                      icon: Icons.search_off_rounded,
                      title: 'No matching artists',
                      message: 'Try another name, skill, or location.',
                      actionLabel: 'Clear search',
                      onAction: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadFollowing(showLoader: false),
                      color: AppColors.primary,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _followingCard(visible[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _followingCard(Map<String, dynamic> artist) {
    final id = _artistId(artist);
    final name = _artistName(artist);
    final imageUrl = _normaliseImageUrl(_avatar(artist));
    final location = _location(artist);
    final skills = _firstValue(artist, ['skills', 'category']);
    final busy = _unfollowingIds.contains(id);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _openArtist(artist),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accent.withOpacity(0.48)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  width: 66,
                  height: 66,
                  color: AppColors.light,
                  child: imageUrl.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          size: 34,
                          color: AppColors.primary,
                        )
                      : Image.network(
                          imageUrl,
                          key: ValueKey(imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 34,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 13),
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
                      const SizedBox(height: 4),
                      Text(
                        skills,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ],
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_firstValue(artist, ['followerCount', 'followers']).ifEmpty('0')} followers',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _unfollow(artist),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.6),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Unfollow',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stateMessage({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

extension _StringFallback on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
