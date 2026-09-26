import 'package:flutter/material.dart';

void main() {
  runApp(const OrderScreen());
}

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orders Screen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // CHANGED THEME ONLY
        scaffoldBackgroundColor: const Color(0xFFF7F0E7),
        fontFamily: 'Roboto',
      ),
      home: const OrdersScreen(),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedNavIndex = 2; // Orders tab selected
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'Completed'
  ];

  // Dummy Orders Data
  final List<Map<String, dynamic>> _allOrders = [
    {
      'id': 'ORD12345',
      'title': 'Wooden Coffee Table',
      'price': '₹2,499',
      'date': '15 May 2025',
      'status': 'Pending',

      // CHANGED THEME ONLY
      'statusColor': const Color(0xFFF4E5D6),
      'textColor': const Color(0xFFA84F35),

      'icon': Icons.table_restaurant_rounded,
    },
    {
      'id': 'ORD12344',
      'title': 'Vintage Bottle Lamp',
      'price': '₹1,299',
      'date': '14 May 2025',
      'status': 'Confirmed',

      // CHANGED THEME ONLY
      'statusColor': const Color(0xFFE8DED4),
      'textColor': const Color(0xFFB1583E),

      'icon': Icons.light_rounded,
    },
    {
      'id': 'ORD12343',
      'title': 'Recycled Wood Shelf',
      'price': '₹1,899',
      'date': '10 May 2025',
      'status': 'Shipped',

      // CHANGED THEME ONLY
      'statusColor': const Color(0xFFE9DDD2),
      'textColor': const Color(0xFFA84F35),

      'icon': Icons.shelves,
    },
    {
      'id': 'ORD12342',
      'title': 'Planter Stand',
      'price': '₹999',
      'date': '08 May 2025',
      'status': 'Delivered',

      // CHANGED THEME ONLY
      'statusColor': const Color(0xFFE8DED4),
      'textColor': const Color(0xFFB1583E),

      'icon': Icons.local_florist_rounded,
    },
  ];

  void _showMessage(String title) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(title),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'All') return _allOrders;
    if (_selectedFilter == 'Completed') {
      return _allOrders
          .where(
            (o) =>
        o['status'] == 'Shipped' ||
            o['status'] == 'Delivered',
      )
          .toList();
    }
    return _allOrders
        .where((o) => o['status'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CHANGED THEME ONLY
      backgroundColor: const Color(0xFFF7F0E7),

      body: SafeArea(
        child: Column(
          children: [
            // --- Filter Chips Bar ---
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 12,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },

                        // CHANGED THEME ONLY
                        selectedColor: const Color(0xFFEAD8CB),

                        // CHANGED THEME ONLY
                        backgroundColor: const Color(0xFFF4ECE3),

                        labelStyle: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,

                          // CHANGED THEME ONLY
                          color: isSelected
                              ? const Color(0xFFA84F35)
                              : const Color(0xFF8A7C73),
                        ),

                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(

                            // CHANGED THEME ONLY
                            color: isSelected
                                ? const Color(0xFFD8BBA9)
                                : Colors.transparent,

                            width: 1,
                          ),
                        ),
                        elevation: 0,
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // --- Orders List ---
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                itemCount: _filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = _filteredOrders[index];
                  return _buildOrderCard(order);
                },
              ),
            ),
          ],
        ),
      ),

      // --- Custom Floating Center Button & Bottom Nav Bar ---
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,

      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(

              // CHANGED THEME ONLY
              color: const Color(0xFFB1583E)
                  .withValues(alpha: 0.35),

              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,

          // CHANGED THEME ONLY
          backgroundColor: const Color(0xFFB1583E),

          shape: const CircleBorder(),
          onPressed: () =>
              _showMessage('Add New Item Clicked'),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,

        // KEPT WHITE
        color: Colors.white,

        elevation: 16,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.home_rounded,
                'Dashboard',
              ),
              _buildNavItem(
                1,
                Icons.category_outlined,
                'Materials',
              ),
              const SizedBox(width: 40),
              _buildNavItem(
                2,
                Icons.favorite_border_rounded,
                'Orders',
              ),
              _buildNavItem(
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

  // Order Card Item Widget
  Widget _buildOrderCard(
      Map<String, dynamic> order,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        // CHANGED THEME ONLY
        border: Border.all(
          color: const Color(0xFFE3D7CB),
          width: 1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMessage(
            'Order #${order['id']} Selected',
          ),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Product Image Placeholder Box
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(

                    // CHANGED THEME ONLY
                    color: const Color(0xFFF4ECE3),

                    borderRadius: BorderRadius.circular(12),

                    // CHANGED THEME ONLY
                    border: Border.all(
                      color: const Color(0xFFE3D7CB),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    order['icon'] as IconData,

                    // CHANGED THEME ONLY
                    color: const Color(0xFFB1583E),

                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),

                // Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order['id']}',
                        style: const TextStyle(
                          fontSize: 12,

                          // CHANGED THEME ONLY
                          color: Color(0xFF8A7C73),

                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,

                          // CHANGED THEME ONLY
                          color: Color(0xFF2B2724),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order['price'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,

                          // CHANGED THEME ONLY
                          color: Color(0xFF2B2724),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order['date'],
                        style: const TextStyle(
                          fontSize: 11,

                          // CHANGED THEME ONLY
                          color: Color(0xFF9A8D84),

                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: order['statusColor'] as Color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order['status'],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: order['textColor'] as Color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation Item Builder
  Widget _buildNavItem(
      int index,
      IconData icon,
      String label,
      ) {
    final isSelected = _selectedNavIndex == index;

    // CHANGED THEME ONLY
    final color = isSelected
        ? const Color(0xFFB1583E)
        : const Color(0xFF9A8D84);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
        _showMessage('$label Clicked');
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontSize: 11,
                fontWeight: isSelected
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