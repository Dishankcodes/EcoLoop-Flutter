import 'dart:convert';

import 'package:ecoloop/services/ecoloop_api.dart';
import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../widgets/cart_popup.dart';
import 'order_success.dart';

class Payment extends StatefulWidget {
  const Payment({
    super.key,
    required this.totalAmount,
    this.items,
    this.address,
    this.deliveryMethod = 'Standard Delivery',
    this.savings = 0,
  });

  final double totalAmount;
  final List<Map<String, dynamic>>? items;
  final Map<String, dynamic>? address;
  final String deliveryMethod;
  final double savings;

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  bool _processing = false;
  String _method = 'cod';

  String _money(num n) => '₹${n.round()}';

  double _number(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse((v ?? '').toString()) ?? 0;

  int _quantity(Map<String, dynamic> item) {
    final q = item['quantity'];
    return q is num ? q.toInt() : int.tryParse('$q') ?? 1;
  }

  String _productId(Map<String, dynamic> item) =>
      (item['productId'] ?? item['id'] ?? '').toString();

  Future<void> _placeOrder() async {
    if (_processing) return;
    final items = widget.items ?? const <Map<String, dynamic>>[];
    if (items.isEmpty) {
      _message('No items to order.');
      return;
    }
    if (widget.address == null || widget.address!.isEmpty) {
      _message('Delivery address is missing. Go back to checkout.');
      return;
    }
    if (_method != 'cod') {
      _message(
        'Online payment is unavailable until a real payment gateway is configured.',
      );
      return;
    }
    setState(() => _processing = true);
    final createdOrders = <Map<String, dynamic>>[];
    try {
      final shippingAddress = jsonEncode(widget.address);
      for (final item in items) {
        final id = _productId(item);
        if (id.isEmpty || int.tryParse(id) == null) {
          throw Exception(
            'A cart item is missing a valid product ID. Remove it and add it again from the marketplace.',
          );
        }
        final qty = _quantity(item);
        if (qty < 1)
          throw Exception(
            'Invalid quantity for ${item['title'] ?? 'product'}.',
          );
        final result = await EcoLoopApi.instance.post('/orders', {
          'productId': int.parse(id),
          'quantity': qty,
          'shippingAddress': shippingAddress,
          'paymentMethod': 'cod',
        });
        if (result is! Map || result['order'] is! Map)
          throw Exception('The server did not confirm the order.');
        createdOrders.add(Map<String, dynamic>.from(result['order'] as Map));
      }
      if (!mounted) return;
      CartPopup.clear();
      final ids = createdOrders.map((o) => o['orderId'].toString()).join(', ');
      final amount = createdOrders.fold<double>(
        0,
        (sum, order) => sum + _number(order['totalAmount']),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccess(
            orderId: ids,
            totalAmount: amount > 0 ? amount : widget.totalAmount,
            itemCount: items.fold<int>(0, (sum, item) => sum + _quantity(item)),
            paymentMethod: 'Cash on Delivery',
            address: widget.address,
            deliveryMethod: widget.deliveryMethod,
          ),
        ),
      );
    } catch (e) {
      if (mounted) _message('Order could not be completed: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      title: const Text('Payment'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: 12),
              const Text(
                'Total payable',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                _money(widget.totalAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.items?.length ?? 0} product line(s)',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Choose payment method',
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary, width: 1.4),
          ),
          child: RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            value: 'cod',
            groupValue: _method,
            onChanged: (value) => setState(() => _method = value ?? 'cod'),
            activeColor: AppColors.primary,
            title: const Text(
              'Cash on Delivery',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Pay when your order is delivered. Order details are saved to the live Sheets backend.',
            ),
            secondary: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'UPI and card payments are disabled until a real payment gateway is configured. This app will not show a fake payment success.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Deliver to', style: AppTextStyles.title.copyWith(fontSize: 17)),
        const SizedBox(height: 8),
        if (widget.address != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              [
                    widget.address!['name'],
                    widget.address!['phone'],
                    widget.address!['addressLine'] ??
                        widget.address!['address'],
                    widget.address!['area'],
                    widget.address!['city'],
                    widget.address!['state'],
                    widget.address!['pincode'],
                  ]
                  .where(
                    (value) =>
                        value != null && value.toString().trim().isNotEmpty,
                  )
                  .join('\n'),
            ),
          ),
        const SizedBox(height: 28),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed: _processing ? null : _placeOrder,
            icon: _processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _processing
                  ? 'Creating order…'
                  : 'Place order · ${_money(widget.totalAmount)}',
            ),
          ),
        ),
      ],
    ),
  );
}
