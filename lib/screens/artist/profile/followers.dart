import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class Followers extends StatefulWidget {
  const Followers({super.key});

  @override
  State<Followers> createState() => _FollowersState();
}

class _FollowersState extends State<Followers> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _followers = [
    {
      'name': 'Sumit Meraiya',
      'username': '@sumiitmeraiiya',
      'followers': '128 followers',
      'image':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
      'following': true,
    },
    {
      'name': 'Dishank Prajapati',
      'username': '@dishank.prajapati',
      'followers': '94 followers',
      'image':
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&q=80',
      'following': true,
    },
    {
      'name': 'Nivya Maniyar',
      'username': '@nivyaa07',
      'followers': '76 followers',
      'image':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
      'following': false,
    },
    {
      'name': 'Isha Mehta',
      'username': '@isha.mehta',
      'followers': '61 followers',
      'image':
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80',
      'following': true,
    },
    {
      'name': 'Kunal Joshi',
      'username': '@kunal.joshi',
      'followers': '53 followers',
      'image':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
      'following': false,
    },
    {
      'name': 'Nisha Patel',
      'username': '@nisha.patel',
      'followers': '47 followers',
      'image':
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&q=80',
      'following': true,
    },
  ];

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
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildFollowerSummary(),
              const SizedBox(height: 14),
              _buildSearch(),
              const SizedBox(height: 18),
              _buildFollowerTitle(filtered.length),
              const SizedBox(height: 10),
              filtered.isEmpty
                  ? _buildEmptyState()
                  : _buildFollowerList(filtered),
            ],
          ),
        ),
      ),
    );
  }

  // Page header.
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

  // Follower summary.
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
                '${_followers.length}',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: ArtistColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '+12%',
                  style: ArtistTextStyles.caption.copyWith(
                    color: ArtistColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Search field.
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

  // Follower count.
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

  // Followers list.
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

  // Follower card.
  Widget _buildFollowerCard(Map<String, dynamic> follower) {
    final bool isFollowing = follower['following'] == true;

    final String name = follower['name']?.toString() ?? 'User';

    final String username = follower['username']?.toString() ?? '';

    final String followerCount = follower['followers']?.toString() ?? '';

    final String image = follower['image']?.toString() ?? '';

    return Container(
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
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
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
                      style: ArtistTextStyles.caption.copyWith(fontSize: 9.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildFollowButton(follower, isFollowing),
        ],
      ),
    );
  }

  // Profile image.
  Widget _buildProfileImage(String image, String name) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: image.isEmpty
          ? _profileFallback(name)
          : Image.network(
              image,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _profileFallback(name);
              },
            ),
    );
  }

  // Profile fallback.
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

  // Follow button.
  Widget _buildFollowButton(Map<String, dynamic> follower, bool isFollowing) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            follower['following'] = !isFollowing;
          });

          final name = follower['name']?.toString() ?? 'user';

          _showMessage(isFollowing ? 'Unfollowed $name' : 'Following $name');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: isFollowing ? ArtistColors.light : ArtistColors.primary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ArtistColors.primary),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
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

  // Empty state.
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

  // More options.
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
                    setState(() {});
                    _showMessage('Followers refreshed.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // More option.
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

  // Snackbar.
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
