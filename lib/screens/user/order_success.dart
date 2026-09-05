import 'package:flutter/material.dart';
import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import 'orders.dart';
import 'user_main.dart';

class OrderSuccess extends StatelessWidget {
  const OrderSuccess({
    super.key,
    required this.orderId,
    required this.total,
    required this.itemCount,
  });

  final String orderId;
  final double total;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Container(
                  width: 108,
                  height: 108,
                  decoration: const BoxDecoration(color: AppColors.light, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 72),
                ),
                const SizedBox(height: 28),
                Text('Order Confirmed!', style: AppTextStyles.heading.copyWith(fontSize: 27), textAlign: TextAlign.center),
                const SizedBox(height: 9),
                Text('Your order has been placed successfully.', style: AppTextStyles.body, textAlign: TextAlign.center),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accent.withOpacity(.5))),
                  child: Column(children: [
                    _row('Order ID', orderId),
                    const SizedBox(height: 11),
                    _row('Items', '$itemCount'),
                    const SizedBox(height: 11),
                    _row('Amount', '₹${total.toStringAsFixed(0)}', bold: true),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),
                    Row(children: [const Icon(Icons.local_shipping_outlined, color: AppColors.success, size: 20), const SizedBox(width: 8), Expanded(child: Text('Expected delivery in 3–5 business days', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)))]),
                  ]),
                ),
                const SizedBox(height: 24),
                Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.light, borderRadius: BorderRadius.circular(15)), child: const Row(children: [Icon(Icons.eco_outlined, color: AppColors.primary), SizedBox(width: 9), Expanded(child: Text('Thank you for giving useful products a second life.'))])),
                const SizedBox(height: 28),
                SizedBox(width: double.infinity, height: 50, child: FilledButton.icon(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Orders())), icon: const Icon(Icons.receipt_long_outlined), label: const Text('View My Orders'))),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const UserMain()), (route) => false), icon: const Icon(Icons.storefront_outlined), label: const Text('Continue Shopping'))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Row(children: [Expanded(child: Text(label, style: AppTextStyles.caption)), Text(value, style: AppTextStyles.body.copyWith(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? AppColors.primary : AppColors.textPrimary))]);
}
