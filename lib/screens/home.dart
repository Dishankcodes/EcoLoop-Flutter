import 'package:flutter/material.dart';

import '../app_theme/app_text_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeContent(),
    ExplorePage(),
    ActivityPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7FAF5),

      body: SafeArea(child: _pages[_selectedIndex]),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 15,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,

          type: BottomNavigationBarType.fixed,

          backgroundColor: Colors.white,

          selectedItemColor: const Color(0xff2A4D3A),
          unselectedItemColor: const Color(0xff9AA69D),

          selectedFontSize: 12,
          unselectedFontSize: 12,

          elevation: 0,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Activity',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME CONTENT
// ============================================================

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // HEADER
          // --------------------------------------------------
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning 👋',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Welcome to EcoLoop',
                      style: AppTextStyles.heading.copyWith(
                        color: const Color(0xff2A4D3A),
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xffE3F0E5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xff2A4D3A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // --------------------------------------------------
          // IMPACT CARD
          // --------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff2A4D3A), Color(0xff416B51)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    const Spacer(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: Color(0xffD4E4D8),
                            size: 17,
                          ),
                          SizedBox(width: 5),
                          Text(
                            '0 Points',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                const Text(
                  'Your Impact',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Start your sustainable journey',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    _ImpactItem(value: '0', label: 'Items Saved'),

                    const SizedBox(width: 30),

                    _ImpactItem(value: '0', label: 'Items Reused'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // --------------------------------------------------
          // QUICK ACTIONS
          // --------------------------------------------------
          const Text(
            'What would you like to do?',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xff24382C),
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_circle_outline,
                  title: 'List Item',
                  subtitle: 'Give it a new purpose',
                  onTap: () {},
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: _ActionCard(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Explore',
                  subtitle: 'Find something useful',
                  onTap: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'Donate',
                  subtitle: 'Make a difference',
                  onTap: () {},
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: _ActionCard(
                  icon: Icons.recycling_outlined,
                  title: 'Reuse',
                  subtitle: 'Keep items in use',
                  onTap: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // --------------------------------------------------
          // CATEGORIES
          // --------------------------------------------------
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Explore Categories',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff24382C),
                  ),
                ),
              ),

              TextButton(
                onPressed: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xff2A4D3A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 105,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: const [
                _CategoryItem(icon: Icons.chair_outlined, title: 'Furniture'),
                _CategoryItem(
                  icon: Icons.checkroom_outlined,
                  title: 'Clothing',
                ),
                _CategoryItem(
                  icon: Icons.devices_outlined,
                  title: 'Electronics',
                ),
                _CategoryItem(icon: Icons.menu_book_outlined, title: 'Books'),
                _CategoryItem(icon: Icons.home_outlined, title: 'Home'),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --------------------------------------------------
          // ECOLOOP TIP
          // --------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xffEAF3EB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xffD4E4D8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xff2A4D3A),
                  ),
                ),

                const SizedBox(width: 14),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EcoLoop Tip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff2A4D3A),
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Before buying something new, check if you can reuse or restore something you already have.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Color(0xff53665A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// IMPACT ITEM
// ============================================================

class _ImpactItem extends StatelessWidget {
  final String value;
  final String label;

  const _ImpactItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

// ============================================================
// ACTION CARD
// ============================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffE1E9E2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xffEAF3EB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xff2A4D3A), size: 23),
            ),

            const SizedBox(height: 13),

            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xff24382C),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(fontSize: 10.5, color: Color(0xff7A877E)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CATEGORY ITEM
// ============================================================

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CategoryItem({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE1E9E2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xffEAF3EB),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xff2A4D3A), size: 22),
          ),

          const SizedBox(height: 7),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xff435348),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EXPLORE PAGE
// ============================================================

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Explore',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xff2A4D3A),
        ),
      ),
    );
  }
}

// ============================================================
// ACTIVITY PAGE
// ============================================================

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Activity',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xff2A4D3A),
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xff2A4D3A),
        ),
      ),
    );
  }
}
