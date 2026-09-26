import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: ArtistDashboardScreen(),
));

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  int _selectedIndex = 0;

  final _stats = [
    {'title': 'Total Sales', 'count': '56'},
    {'title': 'Total Products', 'count': '12'},
    {'title': 'Orders', 'count': '18'},
    {'title': 'Portfolio Views', 'count': '2,450'},
  ];

  final _overview = [
    {'icon': Icons.inventory_2_outlined, 'title': 'Pending Orders', 'count': '6'},
    {'icon': Icons.chat_bubble_outline_rounded, 'title': 'Unread Messages', 'count': '3'},
    {'icon': Icons.shopping_bag_outlined, 'title': 'Low Stock Items', 'count': '2'},
  ];

  final _quickActions = [
    {'icon': Icons.add_rounded, 'label': 'Add Product'},
    {'icon': Icons.category_outlined, 'label': 'Materials'},
    {'icon': Icons.assignment_outlined, 'label': 'Orders'},
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Earnings'},
  ];

  void _toast(String title) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('$title clicked'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0E7),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Hi, Creative Studio ',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF2B2724)),
                      ),
                      Text('👋', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () => _toast('Options Menu'),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.more_horiz, color: Color(0xFF2B2724)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text("Let's create something amazing.", style: TextStyle(fontSize: 14, color: Color(0xFF8A7C73))),
              const SizedBox(height: 20),

              // Total Earnings Card
              InkWell(
                onTap: () => _toast('Total Earnings'),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0E2D6), Color(0xFFF8F1E9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2D2C5)),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFB1583E).withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Earnings', style: TextStyle(fontSize: 13, color: Color(0xFFB1583E), fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                          const SizedBox(height: 8),
                          const Text('₹24,850', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: Color(0xFF2B2724))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(6)),
                                child: const Text('+12%', style: TextStyle(fontSize: 12, color: Color(0xFF2B2724), fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 6),
                              const Text('this month', style: TextStyle(fontSize: 12, color: Color(0xFF8A7C73), fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFB1583E), Color(0xFFA84F35)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFA84F35).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stat Badges
              Row(
                children: _stats.map((s) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: s == _stats.last ? 0 : 10),
                    child: InkWell(
                      onTap: () => _toast(s['title']!),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4ECE3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE3D7CB)),
                        ),
                        child: Column(
                          children: [
                            Text(s['title']!, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 10.5, color: Color(0xFF8A7C73), fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(s['count']!, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFFA84F35))),
                          ],
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 28),

              // Overview Section
              _sectionTitle('Overview'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE3D7CB)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: List.generate(_overview.length, (index) {
                    final item = _overview[index];
                    final isFirst = index == 0;
                    final isLast = index == _overview.length - 1;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () => _toast(item['title'] as String),
                          borderRadius: BorderRadius.vertical(
                            top: isFirst ? const Radius.circular(20) : Radius.zero,
                            bottom: isLast ? const Radius.circular(20) : Radius.zero,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFFF0E7DE), borderRadius: BorderRadius.circular(10)),
                                  child: Icon(item['icon'] as IconData, size: 18, color: const Color(0xFF2B2724)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Text(item['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2B2724)))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFE9DED4), borderRadius: BorderRadius.circular(8)),
                                  child: Text(item['count'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2B2724))),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast) const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: Color(0xFFE9DED4))),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 28),

              // Quick Actions Section
              _sectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _quickActions.map((action) => InkWell(
                  onTap: () => _toast(action['label'] as String),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 80,
                    height: 82,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4ECE3),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE3D7CB)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(action['icon'] as IconData, color: const Color(0xFFA84F35), size: 24),
                        const SizedBox(height: 8),
                        Text(action['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2B2724))),
                      ],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // FAB & Bottom Nav
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFFB1583E).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: const Color(0xFFB1583E),
          shape: const CircleBorder(),
          onPressed: () => _toast('Add New Item'),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 16,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navBtn(0, Icons.home_rounded, 'Dashboard'),
              _navBtn(1, Icons.category_outlined, 'Materials'),
              const SizedBox(width: 40),
              _navBtn(2, Icons.assignment_outlined, 'Orders'),
              _navBtn(3, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Color(0xFF2B2724)));
  }

  Widget _navBtn(int index, IconData icon, String label) {
    final active = _selectedIndex == index;
    final color = active ? const Color(0xFFA84F35) : const Color(0xFF9A8D84);

    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
        _toast(label);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
