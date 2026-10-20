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
      'description': 'Confirm that you will prepare the item.',
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'status': 'packed',
      'label': 'Packed',
      'title': 'Item Packed',
      'description': 'The item is packed and ready for dispatch.',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'status': 'shipped',
      'label': 'Shipped',
      'title': 'Order Shipped',
      'description': 'The item has been handed to delivery.',
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
      'description': 'The buyer has received the item.',
      'icon': Icons.home_outlined,
    },
    {
      'status': 'cancelled',
      'label': 'Cancelled',
      'title': 'Order Cancelled',
      'description': 'Cancel this order if it cannot be fulfilled.',
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

  int get _id =>
      int.tryParse('${widget.order['orderId'] ?? widget.order['id'] ?? ''}') ??
      0;

  String get _product =>
      '${widget.order['productName'] ?? widget.order['product'] ?? 'Product #${widget.order['productId'] ?? '—'}'}';

  String get _buyer =>
      '${widget.order['buyerName'] ?? widget.order['buyer'] ?? 'Buyer details unavailable'}';

  double get _amount =>
      double.tryParse(
        '${widget.order['subtotal'] ?? widget.order['totalAmount'] ?? widget.order['priceValue'] ?? 0}',
      ) ??
      0;

  String _normalize(String value) {
    final s = value
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
    if (s == 'completed') return 'delivered';
    if (s == 'new') return 'new_order';
    return s;
  }

  int _index(String status) {
    final index = _statuses.indexWhere((item) => item['status'] == status);
    return index < 0 ? 0 : index;
  }

  String _label(String status) =>
      _statuses.firstWhere(
            (item) => item['status'] == status,
            orElse: () => _statuses.first,
          )['label']
          as String;

  bool get _terminal =>
      _currentStatus == 'delivered' || _currentStatus == 'cancelled';

  bool _canSelect(String status) {
    if (_terminal || status == _currentStatus || status == 'new_order')
      return false;
    if (status == 'cancelled')
      return !['shipped', 'out_for_delivery'].contains(_currentStatus);
    return _index(status) > _index(_currentStatus) && status != 'cancelled';
  }

  @override
  Widget build(BuildContext context) {
    final image = '${widget.order['productImage'] ?? ''}'.trim();
    final current = _statuses.firstWhere(
      (item) => item['status'] == _currentStatus,
      orElse: () => _statuses.first,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Update Order Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          height: 62,
                          width: 62,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: image.isNotEmpty
                              ? Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 30,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 30,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${_amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _panel('Current Status', Icons.flag_outlined, [
                    Row(
                      children: [
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            current['icon'] as IconData,
                            color: AppColors.primary,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _label(_currentStatus),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${current['description']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_terminal)
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                    if (_terminal) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'This order is in a final status and can no longer be changed.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ]),
                  _panel('Order Progress', Icons.timeline_rounded, [
                    ..._statuses
                        .where((s) => s['status'] != 'cancelled')
                        .map(_timeline),
                  ]),
                  _panel('Select New Status', Icons.tune_rounded, [
                    const Text(
                      'Select the next stage. Previous stages cannot be selected again.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._statuses
                        .where((s) => s['status'] != 'new_order')
                        .map(_option),
                  ]),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
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
                            _selectedStatus == _currentStatus ||
                            _terminal
                        ? null
                        : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
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
    final status = '${item['status']}';
    final i = _index(status);
    final currentIndex = _index(_currentStatus);
    final done = i <= currentIndex && _currentStatus != 'cancelled';
    final current = status == _currentStatus;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
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
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item['title']}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: done ? FontWeight.w800 : FontWeight.w500,
                          color: done
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (current)
                      const Text(
                        'CURRENT',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item['description']}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
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
    final status = '${item['status']}';
    final selected = _selectedStatus == status;
    final allowed = _canSelect(status);
    final cancelled = status == 'cancelled';
    final color = cancelled ? AppColors.error : AppColors.primary;
    return Opacity(
      opacity: allowed || selected ? 1 : .48,
      child: InkWell(
        onTap: allowed
            ? () => setState(() {
                _selectedStatus = status;
                _error = null;
              })
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(top: 9),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(.07) : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : AppColors.accent.withOpacity(.35),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: selected ? color : AppColors.surface,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  size: 19,
                  color: selected ? Colors.white : color,
                ),
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
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item['description']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: color)
              else if (!allowed)
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 17,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panel(String title, IconData icon, List<Widget> children) =>
      Container(
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withOpacity(.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      );

  Future<void> _save() async {
    // Guard against rapid taps or a second invocation before the widget rebuilds.
    if (_saving) return;
    if (_id <= 0) {
      setState(() => _error = 'This order does not have a valid order ID.');
      return;
    }
    final next = _selectedStatus;
    if (next == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await EcoLoopApi.instance.post(
        '/selling/orders/$_id/status',
        {'status': next},
      );
      final response = result is Map
          ? Map<String, dynamic>.from(result)
          : <String, dynamic>{};
      if (!mounted) return;
      final returnedStatus = response['status']?.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order status updated successfully.')),
      );
      Navigator.pop(context, true);
      if (returnedStatus != null && returnedStatus.isNotEmpty)
        _currentStatus = _normalize(returnedStatus);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
