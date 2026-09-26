import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: AddProductScreen(),
));

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  int _selectedIndex = 0;
  String? _selectedCategory;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descController = TextEditingController();

  final _categories = [
    'Woodwork',
    'Upcycled Art',
    'Home Decor',
    'Furniture',
    'Paintings'
  ];

  void _toast(String title) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
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

  void _publishProduct() {
    FocusScope.of(context).unfocus();
    _toast('Product Published Successfully!');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // CHANGED: App background
      backgroundColor: const Color(0xFFF7F0E7),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () => _toast('Back Navigation'),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_rounded,

                    // CHANGED: Main text/icon color
                    color: Color(0xFF2B2724),

                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add Photos Box
              InkWell(
                onTap: () => _toast('Add Photos'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(

                    // CHANGED: Soft cream background
                    color: const Color(0xFFF4ECE3),

                    borderRadius: BorderRadius.circular(16),

                    // CHANGED: Beige border
                    border: Border.all(
                      color: const Color(0xFFE3D7CB),
                      width: 1.5,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,

                        // CHANGED: Terracotta
                        color: Color(0xFFB1583E),

                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add Photos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,

                          // CHANGED
                          color: Color(0xFF2B2724),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Up to 5 images',
                        style: TextStyle(
                          fontSize: 12,

                          // CHANGED
                          color: Color(0xFF8A7C73),

                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Input Fields
              _label('Product Name'),
              const SizedBox(height: 6),
              _textField(
                _nameController,
                'Enter product name',
              ),
              const SizedBox(height: 16),

              _label('Category'),
              const SizedBox(height: 6),
              _dropdownField(),
              const SizedBox(height: 16),

              _label('Price (₹)'),
              const SizedBox(height: 6),
              _textField(
                _priceController,
                'Enter price',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              _label('Stock Quantity'),
              const SizedBox(height: 6),
              _textField(
                _stockController,
                'Enter stock quantity',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              _label('Description'),
              const SizedBox(height: 6),
              _textField(
                _descController,
                'Describe your product',
                maxLines: 4,
              ),
              const SizedBox(height: 28),

              // Publish Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _publishProduct,
                  style: ElevatedButton.styleFrom(

                    // CHANGED: Deep terracotta
                    backgroundColor: const Color(0xFFA84F35),

                    elevation: 2,

                    // CHANGED: Terracotta shadow
                    shadowColor: const Color(0xFFA84F35)
                        .withValues(alpha: 0.3),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Publish Product',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // FAB & Bottom Nav
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,

      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,

          // CHANGED: Terracotta FAB shadow
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB1583E)
                  .withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,

          // CHANGED: Terracotta
          backgroundColor: const Color(0xFFB1583E),

          shape: const CircleBorder(),
          onPressed: () => _toast('Add New Item'),
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

        // Kept white like your dashboard theme
        color: Colors.white,

        elevation: 16,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                Icons.assignment_outlined,
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

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,

        // CHANGED: Main text
        color: Color(0xFF2B2724),
      ),
    );
  }

  Widget _textField(
      TextEditingController controller,
      String hint, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Container(
      decoration: _inputBoxDecoration(),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,

        // CHANGED: Input text
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF2B2724),
        ),

        decoration: InputDecoration(
          hintText: hint,

          // CHANGED: Hint text
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9A8D84),
            fontWeight: FontWeight.w400,
          ),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _dropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _inputBoxDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,

          hint: const Text(
            'Select category',
            style: TextStyle(
              fontSize: 14,

              // CHANGED
              color: Color(0xFF9A8D84),

              fontWeight: FontWeight.w400,
            ),
          ),

          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,

            // CHANGED
            color: Color(0xFF8A7C73),
          ),

          isExpanded: true,

          style: const TextStyle(
            fontSize: 14,

            // CHANGED
            color: Color(0xFF2B2724),
          ),

          items: _categories
              .map(
                (c) => DropdownMenuItem(
              value: c,
              child: Text(c),
            ),
          )
              .toList(),

          onChanged: (v) => setState(
                () => _selectedCategory = v,
          ),
        ),
      ),
    );
  }

  Widget _navBtn(
      int index,
      IconData icon,
      String label,
      ) {
    final active = _selectedIndex == index;

    // CHANGED: Active = terracotta
    // Inactive = muted brown
    final color = active
        ? const Color(0xFFB1583E)
        : const Color(0xFF9A8D84);

    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
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

  BoxDecoration _inputBoxDecoration() {
    return BoxDecoration(

      // Kept white for the input fields
      color: Colors.white,

      borderRadius: BorderRadius.circular(12),

      // CHANGED: Beige border
      border: Border.all(
        color: const Color(0xFFE3D7CB),
      ),

      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.015),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}