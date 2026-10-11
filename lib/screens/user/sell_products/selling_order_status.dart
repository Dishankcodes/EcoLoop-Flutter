import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';

class SellingOrderStatus extends StatefulWidget {
  final Map<String, dynamic> order;

  const SellingOrderStatus({super.key, required this.order});

  @override
  State<SellingOrderStatus> createState() => _SellingOrderStatusState();
}

class _SellingOrderStatusState extends State<SellingOrderStatus> {
  static const List<Map<String, dynamic>> _statuses = [
    {
      'status': 'new_order',
      'label': 'New Order',
      'title': 'Order Received',
      'description': 'A buyer placed this order.',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'status': 'confirmed',
      'label': 'Confirmed',
      'title': 'Order Confirmed',
      'description': 'You have confirmed the order.',
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'status': 'packed',
      'label': 'Packed',
      'title': 'Item Packed',
      'description': 'The item is ready for pickup.',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'status': 'shipped',
      'label': 'Shipped',
      'title': 'Order Shipped',
      'description': 'The item has been handed over for delivery.',
      'icon': Icons.local_shipping_outlined,
    },
    {
      'status': 'out_for_delivery',
      'label': 'Out for Delivery',
      'title': 'Out for Delivery',
      'description': 'The package is on its way to the buyer.',
      'icon': Icons.delivery_dining_outlined,
    },
    {
      'status': 'delivered',
      'label': 'Delivered',
      'title': 'Order Delivered',
      'description': 'The buyer has received the order.',
      'icon': Icons.home_outlined,
    },
    {
      'status': 'cancelled',
      'label': 'Cancelled',
      'title': 'Order Cancelled',
      'description': 'This order has been cancelled.',
      'icon': Icons.cancel_outlined,
    },
  ];
  late String _currentStatus;
  String? _selectedStatus;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentStatus = _normalize('${widget.order['status'] ?? 'new_order'}');
    _selectedStatus = _currentStatus;
  }

  int _index(String status) {
    final i = _statuses.indexWhere((x) => x['status'] == status);
    return i < 0 ? 0 : i;
  }

  String _normalize(String value) {
    final s = value.trim().toLowerCase().replaceAll(' ', '_');
    if (s == 'completed') return 'delivered';
    return s;
  }

  int get _id =>
      int.tryParse('${widget.order['orderId'] ?? widget.order['id'] ?? ''}') ??
      0;

  String get _product =>
      '${widget.order['product'] ?? widget.order['productName'] ?? 'Product #${widget.order['productId'] ?? '—'}'}';

  String get _buyer =>
      '${widget.order['buyer'] ?? widget.order['buyerName'] ?? 'Buyer #${widget.order['buyerId'] ?? '—'}'}';

  @override
  Widget build(BuildContext context) {
    final currentLabel =
        _statuses.firstWhere(
              (s) => s['status'] == _currentStatus,
              orElse: () => _statuses.first,
            )['label']
            as String;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Update Order Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 25),
                children: [
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 29,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _product,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Order #$_id',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Buyer: $_buyer',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Status',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          currentLabel,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose the next status to update the order for the buyer.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._statuses
                            .where((s) => s['status'] != 'cancelled')
                            .map(_timeline),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select New Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Statuses cannot be moved backwards.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ..._statuses
                            .where((s) => s['status'] != 'new_order')
                            .map(_option),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _saving ||
                            _selectedStatus == null ||
                            _selectedStatus == _currentStatus
                        ? null
                        : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 19,
                            width: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Status Update'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeline(Map<String, dynamic> item) {
    final s = '${item['status']}';
    final i = _index(s);
    final current = _index(_currentStatus);
    final done = i <= current;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.light : AppColors.background,
              border: Border.all(
                color: done ? AppColors.success : AppColors.accent,
              ),
            ),
            child: Icon(
              done ? Icons.check_rounded : item['icon'] as IconData,
              size: 16,
              color: done ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['title']}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                    color: done
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item['description']}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(Map<String, dynamic> item) {
    final s = '${item['status']}';
    final selected = _selectedStatus == s;
    final terminal =
        _currentStatus == 'delivered' || _currentStatus == 'cancelled';
    final isCancel = s == 'cancelled';
    final allowed = isCancel
        ? _currentStatus != 'delivered' && !terminal
        : s == 'delivered' ||
              s == 'out_for_delivery' ||
              s == 'shipped' ||
              s == 'packed' ||
              s == 'confirmed'
        ? (_index(s) > _index(_currentStatus) && !terminal)
        : false;
    return Opacity(
      opacity: allowed || selected ? 1 : .5,
      child: InkWell(
        onTap: allowed ? () => setState(() => _selectedStatus = s) : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.light : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.accent.withOpacity(.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                item['icon'] as IconData,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['label']}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item['description']}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_id <= 0) {
      setState(() => _error = 'This order does not have a valid order ID.');
      return;
    }
    setState(() => _saving = true);
    setState(() => _error = null);
    try {
      final result = await EcoLoopApi.instance.post(
        '/selling/orders/$_id/status',
        {'status': _selectedStatus},
      );
      if (result is Map) {
        _currentStatus = _normalize('${result['status'] ?? _selectedStatus}');
      } else {
        _currentStatus = _selectedStatus!;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated successfully.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
