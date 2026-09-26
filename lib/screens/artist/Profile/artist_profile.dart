import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: ProfileScreen(),
));

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 3;

  final _skills = ['Woodwork', 'Upcycling', 'Home Decor'];
  final _stats = [
    {'count': '12', 'label': 'Products'},
    {'count': '56', 'label': 'Orders'},
    {'count': '4.8', 'label': 'Rating'},
    {'count': '2.4K', 'label': 'Followers'},
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
// Avatar & Name Info
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2B2724),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: Color(0xFFB1583E), shape: BoxShape.circle),
                        child: const Icon(Icons.eco, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Creative Studio',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2B2724), letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE9DED4), borderRadius: BorderRadius.circular(20)),
                        child: const Text(
                          'Verified Artist',
                          style: TextStyle(fontSize: 11, color: Color(0xFF8A7C73), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

// Metrics Bar
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: _cardDecoration(),
                child: Row(
                  children: _stats.map((s) => Expanded(
                    child: InkWell(
                      onTap: () => _toast(s['label']!),
                      child: Column(
                        children: [
                          Text(s['count']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2B2724))),
                          const SizedBox(height: 4),
                          Text(s['label']!, style: const TextStyle(fontSize: 12, color: Color(0xFF8A7C73), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 28),

// Bio
              _sectionTitle('Bio'),
              const SizedBox(height: 8),
              const Text(
                'We create unique upcycled products that bring new life to old materials.',
                style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF8A7C73), fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 24),

// Skills
              _sectionTitle('Skills'),
              const SizedBox(height: 12),
              Row(
                children: _skills.map((skill) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => _toast(skill),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4ECE3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE3D7CB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2B2724))),
                          Text(skill, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2B2724))),
                        ],
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),

// Location
              _sectionTitle('Location'),
              const SizedBox(height: 8),
              const Text('Ahmedabad, Gujarat', style: TextStyle(fontSize: 14, color: Color(0xFF8A7C73), fontWeight: FontWeight.w500)),
              const SizedBox(height: 32),

// Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _toast('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFA84F35), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Edit Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFA84F35))),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _toast('View Portfolio'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFFA84F35),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('View Portfolio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

// FAB & Bottom Navigation
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFFA84F35).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: const Color(0xFFA84F35),
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
              _navBtn(2, Icons.favorite_border_rounded, 'Orders'),
              _navBtn(3, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2B2724), letterSpacing: -0.3));
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE3D7CB)),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    );
  }
}
