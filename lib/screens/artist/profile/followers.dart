import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Followers(),
));

class Followers extends StatefulWidget {
  const Followers({super.key});

  @override
  State<Followers> createState() => _FollowersState();
}

class _FollowersState extends State<Followers> {
  final Color primary = const Color(0xFFAD563E);
  final Color background = const Color(0xFFF7F0E7);
  final Color cardColor = const Color(0xFFFFFCF8);
  final Color borderColor = const Color(0xFFE2D5C8);
  final Color textColor = const Color(0xFF292522);
  final Color mutedColor = const Color(0xFF8B817A);

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

  List<Map<String, dynamic>> get filteredFollowers {
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      return _followers;
    }

    return _followers.where((follower) {
      return follower['name']
          .toString()
          .toLowerCase()
          .contains(query) ||
          follower['username']
              .toString()
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textColor,
            size: 25,
          ),
          onPressed: () => _toast('Back clicked'),
        ),

        title: Text(
          'Followers',
          style: TextStyle(
            color: textColor,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),

        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: textColor,
              size: 25,
            ),
            onPressed: () => _toast('More options'),
          ),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Community',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'People who follow your artwork and creations.',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Followers icon
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0DED4),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Icon(
                            Icons.groups_rounded,
                            color: primary,
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // FOLLOWER STAT CARD
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: borderColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0DED4),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.people_alt_rounded,
                              color: primary,
                              size: 26,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_followers.length}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Total Followers',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0DED4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  color: primary,
                                  size: 17,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '+12%',
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // SEARCH
                    // ==================================================

                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: borderColor,
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: primary,
                            size: 25,
                          ),
                          hintText: 'Search followers...',
                          hintStyle: TextStyle(
                            color:
                            mutedColor.withValues(alpha: 0.75),
                            fontSize: 14,
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // FOLLOWER COUNT
                    // ==================================================

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Followers',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${filteredFollowers.length} people',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // FOLLOWERS LIST
                    // ==================================================

                    filteredFollowers.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      itemCount: filteredFollowers.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _followerCard(
                          filteredFollowers[index],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ========================================================
            // BOTTOM NAV
            // ========================================================

            _bottomNavigation(),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // FOLLOWER CARD
  // ================================================================

  Widget _followerCard(
      Map<String, dynamic> follower,
      ) {
    final bool isFollowing = follower['following'];

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ==========================================================
          // PROFILE IMAGE
          // ==========================================================

          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              follower['image'],
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) {
                return Container(
                  width: 58,
                  height: 58,
                  color: const Color(0xFFF0DED4),
                  child: Icon(
                    Icons.person_rounded,
                    color: primary,
                    size: 30,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 13),

          // ==========================================================
          // NAME + USERNAME
          // ==========================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  follower['name'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  follower['username'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      color: mutedColor,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      follower['followers'],
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ==========================================================
          // FOLLOW BUTTON
          // ==========================================================

          InkWell(
            onTap: () {
              setState(() {
                follower['following'] = !isFollowing;
              });

              _toast(
                isFollowing
                    ? 'Unfollowed ${follower['name']}'
                    : 'Following ${follower['name']}',
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: isFollowing
                    ? const Color(0xFFF0DED4)
                    : primary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: primary,
                  width: 1,
                ),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  color: isFollowing
                      ? primary
                      : Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 55,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFF0DED4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              color: primary,
              size: 34,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'No followers found',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Try searching with a different name.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BOTTOM NAVIGATION
  // ================================================================

  Widget _bottomNavigation() {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            Icons.home_outlined,
            'Dashboard',
            false,
          ),

          _navItem(
            Icons.search_outlined,
            'Materials',
            false,
          ),

          // Center Add Button
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () =>
                  _toast('Add New Item'),
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          _navItem(
            Icons.receipt_long_outlined,
            'Orders',
            false,
          ),

          _navItem(
            Icons.person_outline_rounded,
            'Profile',
            false,
          ),
        ],
      ),
    );
  }

  Widget _navItem(
      IconData icon,
      String label,
      bool active,
      ) {
    final color = active ? primary : mutedColor;

    return InkWell(
      onTap: () => _toast('$label clicked'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: active
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
