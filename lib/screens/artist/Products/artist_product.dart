import 'package:flutter/material.dart';

void main() {
  runApp(const MyProductScreen());
}

class MyProductScreen extends StatelessWidget {
  const MyProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoLoop Artist',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F0E7),
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB1583E),
        ),
      ),
      home: const MyProductsScreen(),
    );
  }
}

// ============================================================
// COLORS
// ============================================================

class ArtistColors {
  static const Color background = Color(0xFFF7F0E7);
  static const Color card = Colors.white;
  static const Color softCream = Color(0xFFF4ECE3);

  static const Color primary = Color(0xFFB1583E);
  static const Color darkPrimary = Color(0xFFA84F35);

  static const Color darkText = Color(0xFF2B2724);
  static const Color secondaryText = Color(0xFF6F625A);
  static const Color mutedText = Color(0xFF9A8D84);

  static const Color border = Color(0xFFE3D7CB);

  static const Color successBackground = Color(0xFFE4F0E4);
  static const Color successText = Color(0xFF35613C);

  static const Color outStockBackground = Color(0xFFFBE8E4);
  static const Color outStockText = Color(0xFFA84F35);
}

// ============================================================
// PRODUCT MODEL
// ============================================================

class Product {
  final String name;
  final String price;
  final int stock;
  final String status;
  final IconData icon;

  Product({
    required this.name,
    required this.price,
    required this.stock,
    required this.status,
    required this.icon,
  });
}

// ============================================================
// MY PRODUCTS SCREEN
// ============================================================

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  int selectedTab = 0;
  int selectedNavIndex = 0;

  final List<String> tabs = [
    'All',
    'Published',
    'Draft',
    'Out of Stock',
  ];

  final List<Product> products = [
    Product(
      name: 'Recycled Wood Table',
      price: '₹2,499',
      stock: 12,
      status: 'Published',
      icon: Icons.table_restaurant_rounded,
    ),

    Product(
      name: 'Vintage Bottle Lamp',
      price: '₹1,299',
      stock: 8,
      status: 'Published',
      icon: Icons.light_rounded,
    ),

    // ========================================================
    // CHANGED TO OUT OF STOCK
    // ========================================================

    Product(
      name: 'Recycled Wood Shelf',
      price: '₹1,899',
      stock: 0,
      status: 'Out of Stock',
      icon: Icons.shelves,
    ),

    Product(
      name: 'Planter Stand',
      price: '₹999',
      stock: 10,
      status: 'Published',
      icon: Icons.local_florist_rounded,
    ),
  ];

  List<Product> get filteredProducts {
    if (selectedTab == 0) {
      return products;
    }

    if (selectedTab == 1) {
      return products
          .where((product) => product.status == 'Published')
          .toList();
    }

    if (selectedTab == 2) {
      return products
          .where((product) => product.status == 'Draft')
          .toList();
    }

    return products
        .where((product) => product.status == 'Out of Stock')
        .toList();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.darkPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                14,
                20,
                8,
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: ArtistColors.softCream,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ArtistColors.border,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: ArtistColors.darkText,
                      ),
                      onPressed: () {
                        showMessage('Back Navigation');
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  const Expanded(
                    child: Text(
                      'My Products',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: ArtistColors.darkText,
                      ),
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: () {
                      showMessage('Add Product');
                    },
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 22,
                    ),
                    label: const Text(
                      'Add Product',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtistColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // SELL YOUR CREATIONS
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9F1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ArtistColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF4E6DA),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.spa_outlined,
                              size: 38,
                              color: ArtistColors.primary,
                            ),
                          ),

                          const SizedBox(width: 18),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sell your creations',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: ArtistColors.darkText,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Manage your products and track sales easily.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: ArtistColors.secondaryText,
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
                    // STATISTICS
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            icon: Icons.inventory_2_outlined,
                            number: '12',
                            title: 'Total Products',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _statCard(
                            icon: Icons.shopping_bag_outlined,
                            number: '56',
                            title: 'Items Sold',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // FILTER TABS
                    // ==================================================

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          tabs.length,
                              (index) {
                            final selected =
                                selectedTab == index;

                            return Padding(
                              padding: const EdgeInsets.only(
                                right: 10,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedTab = index;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration:
                                  const Duration(
                                    milliseconds: 200,
                                  ),
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 13,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? ArtistColors.primary
                                        : ArtistColors.softCream,
                                    borderRadius:
                                    BorderRadius.circular(30),
                                    border: Border.all(
                                      color: selected
                                          ? ArtistColors.primary
                                          : ArtistColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    tabs[index],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : ArtistColors.darkText,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // PRODUCTS
                    // ==================================================

                    if (filteredProducts.isEmpty)
                      _emptyProducts()
                    else
                      ...filteredProducts.map(
                            (product) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: 14,
                          ),
                          child: _productCard(product),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ============================================================
      // FLOATING BUTTON
      // ============================================================

      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,

      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: ArtistColors.primary.withValues(
                alpha: 0.30,
              ),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: ArtistColors.primary,
          shape: const CircleBorder(),
          onPressed: () {
            showMessage('Add New Product');
          },
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 15,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                0,
                Icons.home_outlined,
                'Dashboard',
              ),
              _navItem(
                1,
                Icons.grid_view_rounded,
                'Materials',
              ),

              const SizedBox(width: 45),

              _navItem(
                2,
                Icons.receipt_long_outlined,
                'Orders',
              ),
              _navItem(
                3,
                Icons.person_outline_rounded,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard({
    required IconData icon,
    required String number,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ArtistColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF4E6DA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: ArtistColors.primary,
              size: 26,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: ArtistColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ArtistColors.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _productCard(Product product) {
    final bool isOutOfStock =
        product.status == 'Out of Stock';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOutOfStock
              ? ArtistColors.primary.withValues(alpha: 0.35)
              : ArtistColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ==================================================
          // PRODUCT IMAGE
          // ==================================================

          Container(
            width: 125,
            height: 125,
            decoration: BoxDecoration(
              color: ArtistColors.softCream,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: ArtistColors.border,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    product.icon,
                    size: 55,
                    color: ArtistColors.primary,
                  ),
                ),

                // OUT OF STOCK OVERLAY
                if (isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.remove_shopping_cart_outlined,
                          size: 32,
                          color: ArtistColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ==================================================
          // PRODUCT INFORMATION
          // ==================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: ArtistColors.darkText,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        showMessage(
                          '${product.name} Options',
                        );
                      },
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        color: ArtistColors.darkText,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  product.price,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: ArtistColors.primary,
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // STATUS
                // ==================================================

                Row(
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOutOfStock
                            ? ArtistColors.outStockBackground
                            : ArtistColors.successBackground,
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          Icon(
                            isOutOfStock
                                ? Icons
                                .remove_circle_outline
                                : Icons.check_circle_rounded,
                            size: 15,
                            color: isOutOfStock
                                ? ArtistColors.outStockText
                                : ArtistColors.successText,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            product.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                              FontWeight.w700,
                              color: isOutOfStock
                                  ? ArtistColors.outStockText
                                  : ArtistColors.successText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    Icon(
                      Icons.inventory_2_outlined,
                      size: 17,
                      color: isOutOfStock
                          ? ArtistColors.outStockText
                          : ArtistColors.primary,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      isOutOfStock
                          ? 'Out of stock'
                          : '${product.stock} in stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOutOfStock
                            ? ArtistColors.outStockText
                            : ArtistColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ==================================================
                // BUTTONS
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          showMessage(
                            'Edit ${product.name}',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                          ArtistColors.primary,
                          side: const BorderSide(
                            color: ArtistColors.primary,
                            width: 1.2,
                          ),
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Edit Product',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          showMessage(
                            'View ${product.name}',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          ArtistColors.primary,
                          foregroundColor:
                          Colors.white,
                          elevation: 0,
                          padding:
                          const EdgeInsets.symmetric(
                            vertical: 11,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Product',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY PRODUCTS
  // ============================================================

  Widget _emptyProducts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 50,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ArtistColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFF4E6DA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 35,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'No Products Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ArtistColors.darkText,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Start selling your creations by adding a product.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: ArtistColors.secondaryText,
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: () {
              showMessage('Add Product');
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtistColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV ITEM
  // ============================================================

  Widget _navItem(
      int index,
      IconData icon,
      String label,
      ) {
    final bool active =
        selectedNavIndex == index;

    final Color color = active
        ? ArtistColors.primary
        : ArtistColors.mutedText;

    return InkWell(
      onTap: () {
        setState(() {
          selectedNavIndex = index;
        });

        showMessage('$label Clicked');
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}