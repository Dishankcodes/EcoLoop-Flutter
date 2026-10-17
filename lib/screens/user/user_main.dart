import 'package:flutter/material.dart';

import '../../widgets/bottom_navigation.dart';
import 'buy_products/marketplace.dart';
import 'buy_products/orders.dart';
import 'profile/profile.dart';
import 'sell_products/add_product.dart';
import 'user_home.dart';

class UserMain extends StatefulWidget {
  /// The tab to show when opening the main user area.
  /// 0 = Home, 1 = Marketplace, 2 = Orders, 3 = Profile.
  final int initialIndex;

  const UserMain({super.key, this.initialIndex = 0});

  @override
  State<UserMain> createState() => _UserMainState();
}

class _UserMainState extends State<UserMain> {
  late int _currentIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    final requestedIndex = widget.initialIndex;
    _currentIndex = requestedIndex < 0
        ? 0
        : (requestedIndex > 3 ? 3 : requestedIndex);

    _pages = [
      const UserHome(),
      const Marketplace(),
      const Orders(),
      const Profile(),
    ];
  }

  void _onNavigationSelected(int index) {
    if (index < 0 || index > 3) return;

    setState(() {
      _currentIndex = index;
    });
  }

  void _onAddProduct() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddProduct()));
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
