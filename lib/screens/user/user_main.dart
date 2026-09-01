import 'package:flutter/material.dart';

import '../../widgets/bottom_navigation.dart';
import 'user_home.dart';
import 'marketplace.dart';
import 'profile.dart';

class UserMain extends StatefulWidget {
  const UserMain({super.key});

  @override
  State<UserMain> createState() => _UserMainState();
}

class _UserMainState extends State<UserMain> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const UserHome(),
      const Marketplace(),

      // Orders - temporary
      const _ComingSoonPage(title: 'Orders', icon: Icons.receipt_long_rounded),

      // Profile - REAL PAGE
      const Profile(),
    ];
  }

  void _onNavigationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onAddProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Product screen is coming in the next phase.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: UserBottomNavigation(
        currentIndex: _currentIndex,
        onItemSelected: _onNavigationSelected,
        onAddProduct: _onAddProduct,
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ComingSoonPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 55, color: const Color(0xFF1B5E20)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coming in the next phase.',
              style: TextStyle(fontSize: 13, color: Color(0xFF5F6F64)),
            ),
          ],
        ),
      ),
    );
  }
}
