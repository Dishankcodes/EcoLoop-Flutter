import 'dart:convert';

import 'package:ecoloop/services/ecoloop_api.dart';
import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import 'buying_order_details.dart';
import 'order_tracking.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final dynamic data = await EcoLoopApi.instance.get('/orders');
      final List<Map<String, dynamic>> rows = data is List
          ? data
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _orders = rows;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  String _money(dynamic value) => '₹${_number(value).round()}';

  String _date(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Date unavailable';
    }

    final DateTime? parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    final DateTime local = parsed.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    return '$day ${_month(local.month)} ${local.year}';
  }

  String _month(int month) => const <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  String _status(String? status) {
    final String value = (status ?? 'pending')
        .toLowerCase()
        .replaceAll('_', ' ')
        .trim();

    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  bool _reviewEligible(Map<String, dynamic> order) {
    final status = (order['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ');
    final payment = (order['paymentStatus'] ?? order['payment'] ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ');
    final statusAllowed = status == 'delivered' || status == 'confirmed';
    final paid = const {
      'paid',
      'completed',
      'success',
      'successful',
      'captured',
      'cod paid',
    }.contains(payment);
    return statusAllowed && paid;
  }

  bool _paymentPending(Map<String, dynamic> order) {
    final String value = (order['paymentStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ');

    return value == 'pending' ||
        value == 'unpaid' ||
        value == 'failed' ||
        value == 'payment pending';
  }

  void _showPaymentNotReady() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Payment gateway required'),
          content: const Text(
            'This order is still unpaid. The current backend supports order '
            'creation with Cash on Delivery, but it does not yet provide an '
            'order-specific online payment endpoint or verified payment '
            'gateway. No payment will be collected or marked as paid from '
            'this screen yet.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(String status) {
    final String value = status.toLowerCase();

    if (value == 'delivered' || value == 'completed') {
      return AppColors.success;
    }
    if (value == 'cancelled' || value == 'rejected') {
      return Colors.red;
    }
    if (value == 'shipped' || value == 'out for delivery') {
      return Colors.orange;
    }
    return AppColors.primary;
  }

  Map<String, dynamic> _trackingData(Map<String, dynamic> order) {
    dynamic address = order['shippingAddress'];

    if (address is String) {
      try {
        address = jsonDecode(address);
      } catch (_) {
        // Keep the original address when it is not JSON.
      }
    }

    return <String, dynamic>{
      ...order,
      'product': order['productName'] ?? 'Product',
      'price': _money(order['totalAmount']),
      'date': _date(order['createdAt']),
      'orderId': '#ECO-${order['orderId'] ?? ''}',
      'status': _status(order['status']?.toString()),
      'address': address,
    };
  }

  void _openTracking(Map<String, dynamic> order) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            OrderTracking(order: _trackingData(order)),
      ),
    );
  }

  void _openDetails(Map<String, dynamic> order) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            BuyingOrderDetails(order: _trackingData(order)),
      ),
    ).then((_) {
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('My Orders', style: AppTextStyles.title),
        actions: <Widget>[
          IconButton(
            onPressed: _load,
            tooltip: 'Refresh orders',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        children: const <Widget>[
          SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          Text('Could not load orders\n$_error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Center(
            child: FilledButton(onPressed: _load, child: const Text('Retry')),
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(28),
        children: <Widget>[
          const SizedBox(height: 70),
          const Icon(
            Icons.receipt_long_outlined,
            size: 58,
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          Text(
            'No orders yet',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 6),
          Text(
            'Orders you place will appear here from your EcoLoop account.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      itemCount: _orders.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) =>
          _orderCard(_orders[index]),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final String status = _status(order['status']?.toString());
    final Color color = _statusColor(status);
    final String title = (order['productName'] ?? 'Product').toString();
    final String id = (order['orderId'] ?? '').toString();
    final bool paymentPending = _paymentPending(order);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Order #$id', style: AppTextStyles.caption),
                    Text(
                      _date(order['createdAt']),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _money(order['totalAmount']),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Payment: ${_status(order['paymentStatus']?.toString())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Qty ${order['quantity'] ?? 1}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openDetails(order),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _openTracking(order),
                  child: const Text('Track order'),
                ),
              ),
            ],
          ),
          if (_reviewEligible(order)) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openDetails(order),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Write Product & Seller Reviews'),
              ),
            ),
          ],
          if (paymentPending) ...<Widget>[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _showPaymentNotReady,
                icon: const Icon(Icons.payment_rounded),
                label: const Text('Complete Payment'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
