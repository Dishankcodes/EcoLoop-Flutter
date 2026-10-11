import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'selling_order_status.dart';

class SellingOrderDetails extends StatefulWidget {
  final Map<String, dynamic> order;

  const SellingOrderDetails({super.key, required this.order});

  @override
  State<SellingOrderDetails> createState() => _SellingOrderDetailsState();
}

class _SellingOrderDetailsState extends State<SellingOrderDetails> {
  late Map<String, dynamic> _order;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
  }

  int get _id =>
      int.tryParse('${_order['orderId'] ?? _order['id'] ?? ''}') ?? 0;

  String get _status => _pretty('${_order['status'] ?? 'new_order'}');

  String get _product =>
      '${_order['product'] ?? _order['productName'] ?? 'Product #${_order['productId'] ?? '—'}'}';

  String get _buyer =>
      '${_order['buyer'] ?? _order['buyerName'] ?? (_order['buyerId'] == null ? 'Not provided by backend' : 'Buyer #${_order['buyerId']}')}';

  String get _price =>
      '₹${(double.tryParse('${_order['totalAmount'] ?? _order['priceValue'] ?? _order['price'] ?? 0}') ?? 0).toStringAsFixed(2)}';

  bool get _terminal =>
      ['Delivered', 'Completed', 'Cancelled'].contains(_status);

  String _pretty(String s) => s
      .replaceAll('_', ' ')
      .split(' ')
      .where((x) => x.isNotEmpty)
      .map((x) => x[0].toUpperCase() + x.substring(1).toLowerCase())
      .join(' ');

  Future<void> _refresh() async {
    if (_id <= 0) return;
    setState(() => _loading = true);
    try {
      final result = await EcoLoopApi.instance.get('/orders/$_id');
      if (result is Map)
        _order = {..._order, ...Map<String, dynamic>.from(result)};
      if (mounted) setState(() => _error = null);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      title: const Text(
        'Sale Details',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 25),
                children: [
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    child: Row(
                      children: [
                        Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            color: AppColors.primary,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order details',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_order['createdAt'] ?? _order['date'] ?? 'Date unavailable'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
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
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Order ID',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#$_id',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  _section('Sale Status', Icons.local_shipping_outlined, [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _status,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (_loading)
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status and payment information are shown from the order API.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _info(
                      'Payment',
                      _pretty(
                        '${_order['paymentStatus'] ?? _order['payment'] ?? 'unknown'}',
                      ),
                    ),
                  ]),
                  _section('Item Sold', Icons.inventory_2_outlined, [
                    Row(
                      children: [
                        Container(
                          height: 74,
                          width: 74,
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 35,
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'Quantity: ${_order['quantity'] ?? 1}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _price,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    _info(
                      'Product ID',
                      '${_order['productId'] ?? 'Not provided'}',
                    ),
                    _info(
                      'Seller type',
                      '${_order['sellerType'] ?? 'Not provided'}',
                    ),
                  ]),
                  _section('Buyer Information', Icons.person_outline_rounded, [
                    _info('Buyer', _buyer),
                    _info('Buyer ID', '${_order['buyerId'] ?? 'Not provided'}'),
                    const SizedBox(height: 5),
                    const Text(
                      'Phone, email, and buyer address are not returned by the current order endpoint.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ]),
                  _section('Delivery Details', Icons.location_on_outlined, [
                    Text(
                      '${_order['shippingAddress'] ?? 'Shipping address is not available in this response.'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          if (!_terminal)
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
                  child: ElevatedButton.icon(
                    onPressed: _id <= 0
                        ? null
                        : () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SellingOrderStatus(order: _order),
                              ),
                            );
                            if (changed == true) {
                              await _refresh();
                              if (mounted) Navigator.pop(context, true);
                            }
                          },
                    icon: const Icon(Icons.update_rounded),
                    label: const Text('Update Order Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _section(String title, IconData icon, List<Widget> children) =>
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
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
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

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
