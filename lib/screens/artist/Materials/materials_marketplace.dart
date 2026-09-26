import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: MaterialsScreen(),
));

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  int _navIndex = 1;
  String _category = 'All';
  String _search = '';

  final _categories = ['All', 'Wood', 'Metal', 'Fabric', 'Paint', 'Other'];

  final _materials = const [
    {
      'title': 'Reclaimed Wood',
      'price': '₹120',
      'unit': '/ piece',
      'category': 'Wood',
      'icon': Icons.forest_rounded
    },
    {
      'title': 'Metal Pipe',
      'price': '₹180',
      'unit': '/ piece',
      'category': 'Metal',
      'icon': Icons.view_column_rounded
    },
    {
      'title': 'Glass Bottles Pack',
      'price': '₹60',
      'unit': '/ pack',
      'category': 'Other',
      'icon': Icons.local_bar_rounded
    },
    {
      'title': 'Old Fabric Bundle',
      'price': '₹40',
      'unit': '/ pack',
      'category': 'Fabric',
      'icon': Icons.dry_cleaning_rounded
    },
  ];

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB1583E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  List<Map<String, dynamic>> get _filtered => _materials.where((m) {
    final matchCat =
        _category == 'All' || m['category'] == _category;

    final matchSearch = m['title']
        .toString()
        .toLowerCase()
        .contains(_search.toLowerCase());

    return matchCat && matchSearch;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ============================================================
      // ECLOOP ARTIST THEME - BACKGROUND
      // ============================================================

      backgroundColor: const Color(0xFFF7F0E7),

      body: SafeArea(
        child: Column(
          children: [
            // ======================================================
            // SEARCH & FILTER HEADER
            // ======================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: _cardDecoration(),
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => _search = v),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2B2724),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search materials...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9A8D84),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Color(0xFF8C7A70),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                          EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Filter Button
                  InkWell(
                    onTap: () =>
                        _toast('Filter Options Clicked'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: _cardDecoration(radius: 12),
                      child: const Icon(
                        Icons.filter_list_rounded,
                        color: Color(0xFF2B2724),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ======================================================
            // CATEGORY HORIZONTAL SCROLL
            // ======================================================

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _categories.map((cat) {
                  final active = _category == cat;

                  return Padding(
                    padding:
                    const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: active,
                      onSelected: (_) =>
                          setState(() => _category = cat),

                      // -----------------------------
                      // THEME CHANGED
                      // -----------------------------

                      selectedColor:
                      const Color(0xFFB1583E),

                      backgroundColor:
                      const Color(0xFFF2E8DD),

                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: active
                            ? Colors.white
                            : const Color(0xFF6F625A),
                      ),

                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(20),
                        side: BorderSide(
                          color: active
                              ? const Color(0xFFB1583E)
                              : const Color(0xFFE3D7CB),
                        ),
                      ),

                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ======================================================
            // MATERIALS GRID
            // ======================================================

            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                child: Text(
                  'No materials found',
                  style: TextStyle(
                    color: Color(0xFF8C7A70),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
                  : GridView.builder(
                physics:
                const BouncingScrollPhysics(),

                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),

                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),

                itemCount: _filtered.length,

                itemBuilder: (_, i) =>
                    _buildCard(_filtered[i]),
              ),
            ),
          ],
        ),
      ),

      // ============================================================
      // FAB
      // ============================================================

      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,

      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB1583E)
                  .withValues(alpha: 0.30),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,

          // THEME
          backgroundColor: const Color(0xFFB1583E),

          shape: const CircleBorder(),

          onPressed: () =>
              _toast('Add New Item Clicked'),

          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,

        // THEME
        color: const Color(0xFFFFFCF8),

        elevation: 12,

        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceAround,
            children: [
              _navBtn(
                0,
                Icons.home_rounded,
                'Dashboard',
              ),

              _navBtn(
                1,
                Icons.category_outlined,
                'Materials',
              ),

              const SizedBox(width: 40),

              _navBtn(
                2,
                Icons.favorite_border_rounded,
                'Orders',
              ),

              _navBtn(
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
  // MATERIAL CARD
  // ============================================================

  Widget _buildCard(Map<String, dynamic> item) {
    return Container(
      decoration: _cardDecoration(radius: 18),

      child: InkWell(
        onTap: () =>
            _toast('${item['title']} Selected'),

        borderRadius: BorderRadius.circular(18),

        child: Padding(
          padding: const EdgeInsets.all(10),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              // ==================================================
              // IMAGE / ICON AREA
              // ==================================================

              Expanded(
                child: Container(
                  width: double.infinity,

                  decoration: BoxDecoration(
                    // Warm cream instead of purple/grey
                    color: const Color(0xFFF2E8DD),

                    borderRadius:
                    BorderRadius.circular(12),

                    border: Border.all(
                      color: const Color(0xFFE3D7CB),
                    ),
                  ),

                  child: Icon(
                    item['icon'] as IconData,

                    // TERRACOTTA ICON
                    color: const Color(0xFFB1583E),

                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // PRODUCT TITLE
              // ==================================================

              Text(
                item['title'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,

                  // DARK BROWN
                  color: Color(0xFF2B2724),
                ),
              ),

              const SizedBox(height: 4),

              // ==================================================
              // PRICE
              // ==================================================

              Row(
                children: [
                  Text(
                    item['price'],

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,

                      // DARK BROWN
                      color: Color(0xFF2B2724),
                    ),
                  ),

                  Text(
                    ' ${item['unit']}',

                    style: const TextStyle(
                      fontSize: 11,

                      // WARM GREY
                      color: Color(0xFF8C7A70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION ITEM
  // ============================================================

  Widget _navBtn(
      int index,
      IconData icon,
      String label,
      ) {
    final active = _navIndex == index;

    // TERRACOTTA ACTIVE
    final color = active
        ? const Color(0xFFB1583E)
        : const Color(0xFF9A8D84);

    return InkWell(
      onTap: () {
        setState(() => _navIndex = index);

        _toast('$label Clicked');
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
              color: color,
              size: 22,
            ),

            const SizedBox(height: 4),

            Text(
              label,

              style: TextStyle(
                fontSize: 11,

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

  // ============================================================
  // COMMON CARD STYLING
  // ============================================================

  BoxDecoration _cardDecoration({
    double radius = 14,
  }) {
    return BoxDecoration(
      // WHITE / WARM WHITE
      color: const Color(0xFFFFFCF8),

      borderRadius:
      BorderRadius.circular(radius),

      // WARM BORDER
      border: Border.all(
        color: const Color(0xFFE3D7CB),
      ),

      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: 0.025,
          ),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}