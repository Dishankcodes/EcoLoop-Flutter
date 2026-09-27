import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WishlistScreen(),
    ),
  );
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _items = [
    {
      'name': 'Reclaimed Wood Table',
      'price': '₹2,499',
      'condition': 'Good',
      'category': 'Furniture',
      'image':
      'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=700&q=80',
      'liked': true,
    },
    {
      'name': 'Vintage Metal Lamp',
      'price': '₹899',
      'condition': 'Like New',
      'category': 'Decor',
      'image':
      'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=700&q=80',
      'liked': true,
    },
    {
      'name': 'Upcycled Wooden Shelf',
      'price': '₹1,299',
      'condition': 'Good',
      'category': 'Furniture',
      'image':
      'https://images.unsplash.com/photo-1594620302200-9a762244a156?w=700&q=80',
      'liked': true,
    },
    {
      'name': 'Recycled Glass Bottle Set',
      'price': '₹499',
      'condition': 'Like New',
      'category': 'Home Decor',
      'image':
      'https://images.unsplash.com/photo-1521133573892-e44906baee46?w=700&q=80',
      'liked': true,
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      return item['name'].toString().toLowerCase().contains(query) ||
          item['category'].toString().toLowerCase().contains(query);
    }).toList();
  }

  void _removeItem(int index) {
    final item = _filteredItems[index];
    final originalIndex = _items.indexOf(item);

    setState(() {
      _items.removeAt(originalIndex);
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${item['name']} removed from wishlist',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF7F3F32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF7F3F32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFFCF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9CFC4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Wishlist Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7F3F32),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFA6533C),
                  ),
                  title: const Text(
                    'Clear Wishlist',
                    style: TextStyle(
                      color: Color(0xFF302923),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      _items.clear();
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.share_outlined,
                    color: Color(0xFFA6533C),
                  ),
                  title: const Text(
                    'Share Wishlist',
                    style: TextStyle(
                      color: Color(0xFF302923),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showMessage('Share Wishlist clicked');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F0E7),
      body: SafeArea(
        child: Column(
          children: [
            // =========================================================
            // TOP BAR
            // =========================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 0),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => _showMessage('Back clicked'),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 27,
                        color: Color(0xFF302923),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(-10, 0),
                        child: const Text(
                          'Wishlist',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7F3F32),
                          ),
                        ),
                      ),
                    ),
                  ),

                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _showMenu,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 27,
                        color: Color(0xFF302923),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =========================================================
            // CONTENT
            // =========================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // HEADER
                    // =================================================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Saved for later',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7F3F32),
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Keep your favourite finds in one place.',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF81766E),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0DED2),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Color(0xFFA6533C),
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // =================================================
                    // SEARCH
                    // =================================================
                    Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFCF8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE0D3C7),
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF302923),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Color(0xFFA6533C),
                            size: 29,
                          ),
                          hintText: 'Search saved items...',
                          hintStyle: TextStyle(
                            color: Color(0xFFA69B92),
                            fontSize: 16,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 17,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // ITEM COUNT
                    // =================================================
                    Text(
                      '${items.length} saved items',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF81766E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =================================================
                    // PRODUCT GRID
                    // =================================================
                    if (items.isEmpty)
                      _emptyWishlist()
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 700;

                          return GridView.builder(
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide ? 2 : 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 18,
                              childAspectRatio:
                              isWide ? 0.92 : 0.72,
                            ),
                            itemBuilder: (context, index) {
                              return _wishlistCard(
                                item: items[index],
                                index: index,
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // PRODUCT CARD
  // ================================================================

  Widget _wishlistCard({
    required Map<String, dynamic> item,
    required int index,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2D5C9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E4638).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // IMAGE
          // ==========================================================
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    item['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (
                        context,
                        error,
                        stackTrace,
                        ) {
                      return Container(
                        color: const Color(0xFFF0DED2),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 42,
                            color: Color(0xFFA6533C),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Condition badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCF8),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      item['condition'],
                      style: const TextStyle(
                        color: Color(0xFF7F3F32),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Heart button
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: const Color(0xFFFFFCF8),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _removeItem(index),
                      child: const SizedBox(
                        width: 43,
                        height: 43,
                        child: Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFA6533C),
                          size: 23,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================================
          // PRODUCT DETAILS
          // ==========================================================
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                11,
                14,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF302923),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    item['price'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFA6533C),
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    item['category'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF81766E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EMPTY WISHLIST
  // ================================================================

  Widget _emptyWishlist() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 50,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2D5C9),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFF0DED2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 40,
              color: Color(0xFFA6533C),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF302923),
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Save items you love and find them here later.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF81766E),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () =>
                _showMessage('Explore Marketplace clicked'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA6533C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Explore Marketplace',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
