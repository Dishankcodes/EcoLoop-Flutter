import 'package:flutter/material.dart';

import '../../widgets/artist_bottom_navigation.dart';
import 'artist_dashboard.dart';
import 'buy_products/marketplace.dart';
import 'profile/profile.dart';
import 'my_products/add_product.dart';
import 'my_products/selling_orders.dart';

class ArtistMain extends StatefulWidget {
  const ArtistMain({super.key});

  @override
  State<ArtistMain> createState() => _ArtistMainState();
}

class _ArtistMainState extends State<ArtistMain> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const ArtistHome(),
      const Marketplace(),
      const SellingOrders(),
      const Profile(),
    ];
  }

  // BOTTOM NAVIGATION

  void _onNavigationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // ADD PRODUCT

  void _onAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProduct()),
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),

      // IMPORTANT:
      // ArtistBottomNavigation belongs here.
      bottomNavigationBar: ArtistBottomNavigation(
        currentIndex: _currentIndex,
        onItemSelected: _onNavigationSelected,
        onAddProduct: _onAddProduct,
      ),
    );
  }
}
