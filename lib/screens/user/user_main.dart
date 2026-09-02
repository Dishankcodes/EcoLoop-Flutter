import 'package:ecoloop/screens/user/orders.dart';
import 'package:flutter/material.dart';

import '../../widgets/bottom_navigation.dart';
import 'user_home.dart';
import 'marketplace.dart';
import 'profile.dart';
import 'add_product.dart';

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
      const Orders(),
      const Profile(),
    ];
  }

  void _onNavigationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProduct()),
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

