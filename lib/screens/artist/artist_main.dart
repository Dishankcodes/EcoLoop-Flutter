import 'package:flutter/material.dart';

import '../../widgets/artist_bottom_navigation.dart';
import 'artist_dashboard.dart';
import 'buy_products/marketplace.dart';
import 'sell_products/selling_orders.dart';
import 'profile/profile.dart';
import 'sell_products/add_product.dart';

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

  void _onNavigationSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onAddProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddProduct(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ArtistBottomNavigation(
        currentIndex: _currentIndex,
        onItemSelected: _onNavigationSelected,
        onAddProduct: _onAddProduct,
      ),
    );
  }
}