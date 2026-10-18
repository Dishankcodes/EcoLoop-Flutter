import 'package:flutter/material.dart';

import '../../widgets/artist_bottom_navigation.dart';
import 'artist_dashboard.dart';
import 'buy_products/marketplace.dart';
import 'my_products/add_product.dart';
import 'my_products/selling_orders.dart';
import 'profile/profile.dart';

class ArtistMain extends StatefulWidget {
  /// Tab to show when opening the main artist area.
  /// 0 = Home, 1 = Marketplace, 2 = Selling Orders, 3 = Profile.
  final int initialIndex;

  const ArtistMain({super.key, this.initialIndex = 0});

  @override
  State<ArtistMain> createState() => _ArtistMainState();
}

class _ArtistMainState extends State<ArtistMain> {
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
      const ArtistHome(),
      const Marketplace(),
      const SellingOrders(),
      const Profile(),
    ];
  }

  void _onNavigationSelected(int index) {
    if (index < 0 || index > 3) return;
    setState(() => _currentIndex = index);
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
      bottomNavigationBar: ArtistBottomNavigation(
        currentIndex: _currentIndex,
        onItemSelected: _onNavigationSelected,
        onAddProduct: _onAddProduct,
      ),
    );
  }
}
