import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../app_theme/user/app_colors.dart';

class OrderTracking extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderTracking({super.key, required this.order});

  String get _status => (order['status'] ?? 'pending').toString().toLowerCase().replaceAll('_', ' ');
  String get _title => (order['product'] ?? order['productName'] ?? 'Product').toString();
  String get _id => (order['orderId'] ?? '—').toString();
  String get _date => (order['date'] ?? order['createdAt'] ?? 'Date unavailable').toString();
  String get _amount => (order['price'] ?? '₹${order['totalAmount'] ?? 0}').toString();
  String get _payment => (order['paymentStatus'] ?? 'pending').toString().replaceAll('_', ' ');
  Map<String, dynamic>? get _address {
    final raw = order['address'] ?? order['shippingAddress'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) { try { final decoded = jsonDecode(raw); if (decoded is Map) return Map<String, dynamic>.from(decoded); } catch (_) {} }
    return null;
  }
  int get _stage {
    switch (_status) {
      case 'confirmed': return 1;
      case 'packed': return 2;
      case 'shipped': return 3;
      case 'out for delivery': return 4;
      case 'delivered': return 5;
      default: return 0;
    }
  }
  String _pretty(String value) => value.split(' ').map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context) {
    final address = _address;
    final steps = const ['Order placed', 'Confirmed', 'Packed', 'Shipped', 'Out for delivery', 'Delivered'];
    final cancelled = _status == 'cancelled';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order details'), backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary, elevation: 0),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 30), const SizedBox(height: 12),
          Text(_title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)), const SizedBox(height: 6),
          Text('Order #$_id', style: const TextStyle(color: Colors.white70)), const SizedBox(height: 14),
          Text(_pretty(_status), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4), Text('Payment: ${_pretty(_payment)}', style: const TextStyle(color: Colors.white70)),
        ])),
        const SizedBox(height: 18),
        _section('Order progress', Column(children: [
          if (cancelled) const ListTile(leading: Icon(Icons.cancel_outlined, color: Colors.red), title: Text('Order cancelled'), subtitle: Text('This order has been cancelled.'))
          else for (var i = 0; i < steps.length; i++) _step(steps[i], i <= _stage, i == _stage),
          const SizedBox(height: 6), Text('Current order status is taken from your live order record. Delivery event timestamps are shown only when the backend provides them.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])),
        const SizedBox(height: 14),
        _section('Order information', Column(children: [
          _row('Placed on', _date), _row('Quantity', (order['quantity'] ?? 1).toString()), _row('Total', _amount), _row('Payment status', _pretty(_payment)),
        ])),
        const SizedBox(height: 14),
        _section('Delivery address', address == null ? const Text('No address details were returned for this order.') : Text([
          address['name'], address['phone'], address['addressLine'] ?? address['address'], address['area'], address['city'], address['state'], address['pincode']
        ].where((v) => v != null && v.toString().trim().isNotEmpty).join('\n'), style: const TextStyle(height: 1.5))),
      ]),
    );
  }

  Widget _section(String title, Widget child) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 2), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.accent.withValues(alpha: .4))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)), const SizedBox(height: 12), child]));
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))), const SizedBox(width: 12), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)))]));
  Widget _step(String label, bool complete, bool active) => Padding(padding: const EdgeInsets.only(bottom: 13), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(complete ? Icons.check_circle : Icons.radio_button_unchecked, color: complete ? AppColors.success : AppColors.textSecondary, size: 22), const SizedBox(width: 11), Expanded(child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(label, style: TextStyle(fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: complete ? AppColors.textPrimary : AppColors.textSecondary))))]));
}
