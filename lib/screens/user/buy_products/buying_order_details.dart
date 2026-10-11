import 'package:flutter/material.dart';
import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import 'order_tracking.dart';

class BuyingOrderDetails extends StatelessWidget {
  final Map<String, dynamic> order;
  const BuyingOrderDetails({super.key, required this.order});

  String _value(dynamic value, [String fallback = 'Not provided']) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  String _money(dynamic value) {
    final number = value is num ? value : double.tryParse((value ?? '').toString()) ?? 0;
    return '₹${number.round()}';
  }

  @override
  Widget build(BuildContext context) {
    final title = _value(order['productName'] ?? order['product'], 'Product');
    final id = _value(order['orderId']);
    final status = _value(order['status'], 'pending').replaceAll('_', ' ');
    final paymentStatus = _value(order['paymentStatus'], 'pending').replaceAll('_', ' ');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order details'), backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.accent.withValues(alpha: .4))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.title.copyWith(fontSize: 20)),
              const SizedBox(height: 5),
              Text('Order #$id', style: AppTextStyles.caption),
              const SizedBox(height: 16),
              _row('Quantity', _value(order['quantity'], '1')),
              _row('Unit price', _money(order['unitPrice'])),
              _row('Total', _money(order['totalAmount'])),
              _row('Order status', status),
              _row('Payment status', paymentStatus),
              _row('Placed at', _value(order['createdAt'])),
            ]),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTracking(order: order))),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('View tracking'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
      const SizedBox(width: 12),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
    ]),
  );
}
