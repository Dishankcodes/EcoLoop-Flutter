import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: OrderDetailsScreen(),
));

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});

  void _toast(BuildContext context, String msg) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ============================================================
      // ECLOOP ARTIST THEME
      // ============================================================

      backgroundColor: const Color(0xFFF7F0E7),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F0E7),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF2B2724),
          ),
          onPressed: () => _toast(context, 'Back clicked'),
        ),

        title: const Text(
          'Order #ORD12345',
          style: TextStyle(
            color: Color(0xFF2B2724),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          Container(
            margin: const EdgeInsets.only(
              right: 16,
              top: 12,
              bottom: 12,
            ),

            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),

            decoration: BoxDecoration(
              // Warm terracotta status background
              color: const Color(0xFFF0DCD2),
              borderRadius: BorderRadius.circular(12),
            ),

            child: const Center(
              child: Text(
                'Pending',
                style: TextStyle(
                  color: Color(0xFFB1583E),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // PRODUCT CARD
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCF8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE3D7CB),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.025),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),

                          child: Image.network(
                            'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=200&q=80',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [
                            Text(
                              'Wooden Coffee Table',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2B2724),
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              '₹2,499',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFB1583E),
                              ),
                            ),

                            SizedBox(height: 4),

                            Text(
                              'Qty: 1',
                              style: TextStyle(
                                color: Color(0xFF8C7A70),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // CUSTOMER DETAILS
                  // ==================================================

                  Row(
                    children: const [
                      Icon(
                        Icons.person_outline,
                        size: 18,
                        color: Color(0xFF8C7A70),
                      ),

                      SizedBox(width: 6),

                      Text(
                        'Customer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6F625A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCF8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE3D7CB),
                      ),
                    ),

                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,

                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&q=80',
                          ),
                        ),

                        const SizedBox(width: 10),

                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: const [
                            Text(
                              'Sumit Meraiya',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF2B2724),
                              ),
                            ),

                            SizedBox(height: 2),

                            Text(
                              '+91 98765 43210',
                              style: TextStyle(
                                color: Color(0xFF8C7A70),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // ORDER INFO ROW
                  // ==================================================

                  Row(
                    children: [
                      Expanded(
                        child: _infoColumn(
                          'Order Date',
                          '15 May 2025',
                        ),
                      ),

                      Expanded(
                        child: _infoColumn(
                          'Payment Method',
                          'UPI',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // DELIVERY ADDRESS
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCF8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE3D7CB),
                      ),
                    ),

                    child: _infoColumn(
                      'Delivery Address',
                      '21 Green Lane, Ahmedabad,\nGujarat - 380015',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // ORDER TRACKING
                  // ==================================================

                  const Text(
                    'Order Tracking',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF2B2724),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _trackStep(
                    'Order Placed',
                    '15 May 2025',
                    isCompleted: true,
                    isFirst: true,
                  ),

                  _trackStep(
                    'Confirmed',
                    '',
                    isCompleted: false,
                  ),

                  _trackStep(
                    'Shipped',
                    '',
                    isCompleted: false,
                  ),

                  _trackStep(
                    'Delivered',
                    '',
                    isCompleted: false,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),

          // ==========================================================
          // MESSAGE BUYER BUTTON
          // ==========================================================

          Padding(
            padding: const EdgeInsets.all(16.0),

            child: SizedBox(
              width: double.infinity,
              height: 48,

              child: ElevatedButton(
                onPressed: () =>
                    _toast(context, 'Message Buyer clicked'),

                style: ElevatedButton.styleFrom(
                  // ECLOOP TERRACOTTA
                  backgroundColor: const Color(0xFFB1583E),

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: const Text(
                  'Message Buyer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INFO COLUMN
  // ================================================================

  Widget _infoColumn(
      String label,
      String value,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFF2B2724),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF8C7A70),
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // ORDER TRACKING
  // ================================================================

  Widget _trackStep(
      String title,
      String subtitle, {
        required bool isCompleted,
        bool isFirst = false,
        bool isLast = false,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                // Completed = Terracotta
                color: isCompleted
                    ? const Color(0xFFB1583E)
                    : Colors.transparent,

                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFFB1583E)
                      : const Color(0xFFCBBEB4),
                  width: 2,
                ),
              ),

              child: isCompleted
                  ? const Icon(
                Icons.check,
                size: 12,
                color: Colors.white,
              )
                  : null,
            ),

            if (!isLast)
              Container(
                width: 2,
                height: 30,

                color: const Color(0xFFE0D4CA),
              ),
          ],
        ),

        const SizedBox(width: 12),

        Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Text(
              title,

              style: TextStyle(
                fontSize: 12,

                fontWeight: isCompleted
                    ? FontWeight.bold
                    : FontWeight.normal,

                color: isCompleted
                    ? const Color(0xFF2B2724)
                    : const Color(0xFF8C7A70),
              ),
            ),

            if (subtitle.isNotEmpty)
              Text(
                subtitle,

                style: const TextStyle(
                  fontSize: 11,

                  // EcoLoop subtle green accent
                  color: Color(0xFF477A58),
                ),
              ),
          ],
        ),
      ],
    );
  }
}