import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
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
    if (s == 'pending' || s == 'processing' || s == 'new') return 'new_order';
    return s;
  }

  int get _id =>
      int.tryParse('${widget.order['orderId'] ?? widget.order['id'] ?? ''}') ??
      0;

  String get _product {
    final candidates = [
      widget.order['productName'],
      widget.order['productTitle'],
      widget.order['title'],
      widget.order['product'],
      widget.order['name'],
    ];
    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    final productId = widget.order['productId'];
    return productId == null
        ? 'Product name unavailable'
        : 'Product #$productId';
  }

  String get _buyer {
    final candidates = [widget.order['buyerName'], widget.order['buyer']];
    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    final buyerId = widget.order['buyerId'];
    return buyerId == null ? 'Buyer details unavailable' : 'Buyer #$buyerId';
  }

  String get _price {
    final value =
        widget.order['totalAmount'] ??
        widget.order['unitPrice'] ??
        widget.order['price'];
    if (value == null) return 'Price unavailable';
    final amount = value is num ? value : num.tryParse(value.toString());
    if (amount == null) return value.toString();
    return '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final currentLabel =
        _statuses.firstWhere(
              (s) => s['status'] == _currentStatus,
              orElse: () => _statuses.first,
            )['label']
            as String;
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.surface,
        foregroundColor: ArtistColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Update Order Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ArtistColors.textPrimary,
          ),
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
                    color: ArtistColors.surface,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: ArtistColors.light,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 29,
                            color: ArtistColors.primary,
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
                                  color: ArtistColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Order #$_id',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ArtistColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Buyer: $_buyer',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ArtistColors.textSecondary,
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
                      color: ArtistColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ArtistColors.accent.withValues(alpha: .4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Status',
                          style: TextStyle(
                            fontSize: 11,
                            color: ArtistColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          currentLabel,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: ArtistColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose the next status to update the order for the buyer.',
                          style: TextStyle(
                            fontSize: 12,
                            color: ArtistColors.textSecondary,
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
                      color: ArtistColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ArtistColors.accent.withValues(alpha: .35),
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
                            color: ArtistColors.textPrimary,
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
                      color: ArtistColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ArtistColors.accent.withValues(alpha: .35),
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
                            color: ArtistColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Statuses cannot be moved backwards.',
                          style: TextStyle(
                            fontSize: 11,
                            color: ArtistColors.textSecondary,
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
                        style: const TextStyle(color: ArtistColors.error),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              decoration: BoxDecoration(
                color: ArtistColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
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
                      backgroundColor: ArtistColors.primary,
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
              color: done ? ArtistColors.light : ArtistColors.background,
              border: Border.all(
                color: done ? ArtistColors.success : ArtistColors.accent,
              ),
            ),
            child: Icon(
              done ? Icons.check_rounded : item['icon'] as IconData,
              size: 16,
              color: done ? ArtistColors.success : ArtistColors.textSecondary,
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
                        ? ArtistColors.textPrimary
                        : ArtistColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item['description']}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: ArtistColors.textSecondary,
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
            color: selected ? ArtistColors.light : ArtistColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? ArtistColors.primary
                  : ArtistColors.accent.withValues(alpha: .3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                item['icon'] as IconData,
                color: selected
                    ? ArtistColors.primary
                    : ArtistColors.textSecondary,
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
                        color: ArtistColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item['description']}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: ArtistColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: ArtistColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  dynamic _unwrapApiData(dynamic value) {
    dynamic result = value;
    // EcoLoopApi versions may return either the decoded data directly or
    // the Apps Script {success:true, data:...} envelope.
    for (var i = 0; i < 3; i++) {
      if (result is Map && result.containsKey('data')) {
        result = result['data'];
      } else {
        break;
      }
    }
    return result;
  }

  Future<void> _save() async {
    if (_id <= 0) {
      setState(
        () => _error =
            'This order has no valid order ID. Please reopen it from Selling Orders.',
      );
      return;
    }
    final nextStatus = _selectedStatus;
    if (nextStatus == null || nextStatus == _currentStatus) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final raw = await EcoLoopApi.instance.post('/artist/orders/$_id/status', {
        'status': nextStatus,
      });
      final response = _unwrapApiData(raw);
      String? savedStatus;
      if (response is Map) {
        final value = response['status'];
        if (value != null) savedStatus = _normalize(value.toString());
      }

      // Some API wrapper versions don't unwrap the response. Verify against
      // the persisted list before showing success so we never fake a save.
      if (savedStatus != nextStatus) {
        final listRaw = await EcoLoopApi.instance.get('/artist/orders');
        final orders = _unwrapApiData(listRaw);
        if (orders is List) {
          for (final item in orders) {
            if (item is Map &&
                int.tryParse('${item['orderId'] ?? item['id'] ?? ''}') == _id) {
              final value = item['status'];
              if (value != null) savedStatus = _normalize(value.toString());
              break;
            }
          }
        }
      }

      if (savedStatus != nextStatus) {
        throw Exception(
          'The server did not confirm this status update. Refresh Selling Orders and try again. '
          'If it continues, check that the latest Code.gs deployment is active.',
        );
      }

      if (!mounted) return;
      setState(() {
        _currentStatus = savedStatus!;
        _selectedStatus = savedStatus;
        widget.order['status'] = savedStatus;
      });

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Order status saved successfully.')),
        );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
