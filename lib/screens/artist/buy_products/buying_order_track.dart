import 'package:ecoloop/services/ecoloop_api.dart';
import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

/// Screen providing real-time tracking updates,
/// timeline progress, and delivery details for an order.
class OrderTracking extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderTracking({super.key, required this.order});

  @override
  State<OrderTracking> createState() => _OrderTrackingState();
}

class _OrderTrackingState extends State<OrderTracking> {
  late Map<String, dynamic> _order;
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _refreshOrder();
  }

  // ORDER DATA

  String get productName {
    final value =
        _order['productTitle'] ?? _order['productName'] ?? _order['product'];
    return value?.toString().trim().isNotEmpty == true
        ? value.toString()
        : 'Product details unavailable';
  }

  String get orderId => (_order['orderId'] ?? _order['id'])?.toString() ?? '—';

  String get orderDate => _formatOrderDate(
    _order['createdAt'] ?? _order['orderDate'] ?? _order['date'],
  );

  /// Formats order timestamps in Indian Standard Time without changing
  /// the value stored by the backend or in Google Sheets.
  String _formatOrderDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty || raw.toLowerCase() == 'null' || raw == '—') {
      return 'Date unavailable';
    }

    DateTime? parsed;
    final sheetIstPattern = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})$',
    );
    final sheetMatch = sheetIstPattern.firstMatch(raw);

    if (sheetMatch != null) {
      // Apps Script yyyy-MM-dd HH:mm:ss values are already in IST.
      parsed = DateTime(
        int.parse(sheetMatch.group(1)!),
        int.parse(sheetMatch.group(2)!),
        int.parse(sheetMatch.group(3)!),
        int.parse(sheetMatch.group(4)!),
        int.parse(sheetMatch.group(5)!),
        int.parse(sheetMatch.group(6)!),
      );
    } else {
      final hasTimezone = RegExp(
        r'(Z|[+-]\d{2}:?\d{2})$',
        caseSensitive: false,
      ).hasMatch(raw);
      final dateValue = DateTime.tryParse(raw);
      if (dateValue == null) return 'Date unavailable';

      if (hasTimezone) {
        // Normalize UTC/offset timestamps to IST, independent of device zone.
        parsed = dateValue.toUtc().add(const Duration(hours: 5, minutes: 30));
      } else {
        // Timestamps without a timezone are treated as already being in IST.
        parsed = DateTime(
          dateValue.year,
          dateValue.month,
          dateValue.day,
          dateValue.hour,
          dateValue.minute,
          dateValue.second,
        );
      }
    }

    final nowIst = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final today = DateTime(nowIst.year, nowIst.month, nowIst.day);
    final orderDay = DateTime(parsed.year, parsed.month, parsed.day);
    final difference = today.difference(orderDay).inDays;

    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final period = parsed.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $period';

    if (difference == 0) return 'Today, $time';
    if (difference == 1) return 'Yesterday, $time';

    const months = [
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
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}, $time';
  }

  String get price {
    final value = _order['totalAmount'] ?? _order['price'];

    if (value == null) {
      return '—';
    }

    if (value is num) {
      return '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
    }

    return value.toString();
  }

  String get quantity => _order['quantity']?.toString() ?? '—';

  String get currentStatus {
    final status =
        (_order['status'] ?? _order['orderStatus'])?.toString() ?? 'pending';

    return _displayStatus(status);
  }

  String get rawStatus =>
      (_order['status'] ?? _order['orderStatus'])?.toString() ?? 'pending';

  IconData get productIcon => _order['icon'] is IconData
      ? _order['icon'] as IconData
      : Icons.inventory_2_outlined;

  String get expectedDelivery {
    final value =
        (_order['expectedDelivery'] ?? _order['estimatedDelivery'])
            ?.toString()
            .trim() ??
        '';
    return value.isEmpty || value.toLowerCase() == 'null'
        ? 'Estimated delivery: 5–7 days after ordering'
        : value;
  }

  String get sellerName =>
      (_order['sellerName'] ?? _order['seller'])?.toString() ??
      'Seller details unavailable';

  String get shippingAddress =>
      ((_order['shippingAddress'] ?? _order['address'])
              ?.toString()
              .trim()
              .isNotEmpty ??
          false)
      ? (_order['shippingAddress'] ?? _order['address']).toString()
      : 'Address not available';

  String get paymentStatus => _order['paymentStatus']?.toString() ?? 'pending';

  Future<void> _refreshOrder() async {
    final id = _order['orderId'] ?? _order['id'];
    if (id == null || id.toString().trim().isEmpty) return;
    if (mounted)
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    try {
      final response = await EcoLoopApi.instance.get(
        '/orders/${Uri.encodeComponent(id.toString())}',
      );
      final dynamic payload = response is Map
          ? (response['order'] ?? response['data'] ?? response)
          : response;
      if (payload is Map && mounted) {
        setState(() {
          _order = {..._order, ...Map<String, dynamic>.from(payload)};
          _loadError = null;
        });
      }
    } catch (error) {
      if (mounted)
        setState(
          () => _loadError = error.toString().replaceFirst('Exception: ', ''),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: ArtistColors.primary,
              ),
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Could not refresh order status: $_loadError',
                  style: ArtistTextStyles.small.copyWith(
                    color: ArtistColors.error,
                  ),
                ),
              ),
            _buildTrackingHeader(),
            _buildCurrentStatus(),
            _buildTrackingTimeline(),
            _buildProductCard(),
            _buildDeliveryCard(),
            _buildOrderInformation(),
            _buildHelpCard(),
          ],
        ),
      ),
    );
  }

  // APP BAR

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ArtistColors.surface,
      foregroundColor: ArtistColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,

      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),

      title: Text(
        'Track Order',
        style: ArtistTextStyles.title.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      centerTitle: true,

      actions: [
        IconButton(
          onPressed: _showMoreOptions,
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ],
    );
  }

  // TRACKING HEADER

  Widget _buildTrackingHeader() {
    return Container(
      width: double.infinity,
      color: ArtistColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      child: Column(
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              shape: BoxShape.circle,
              border: Border.all(
                color: ArtistColors.accent.withOpacity(0.55),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              size: 37,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            _trackingHeadline(),
            textAlign: TextAlign.center,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text('Order $orderId', style: ArtistTextStyles.caption),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 7,
                  width: 7,
                  decoration: BoxDecoration(
                    color: _statusColor(),
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(width: 7),

                Text(
                  currentStatus,
                  style: ArtistTextStyles.small.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ArtistColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _trackingHeadline() {
    switch (rawStatus.toLowerCase()) {
      case 'pending':
        return 'Your order is being processed';

      case 'confirmed':
        return 'Your order has been confirmed';

      case 'packed':
        return 'Your order has been packed';

      case 'shipped':
        return 'Your order is on the way';

      case 'out_for_delivery':
        return 'Your order is out for delivery';

      case 'delivered':
        return 'Your order has been delivered';

      case 'cancelled':
        return 'Your order has been cancelled';

      default:
        return 'Your order is being processed';
    }
  }

  // CURRENT STATUS

  Widget _buildCurrentStatus() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: ArtistColors.accent.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_statusIcon(), color: ArtistColors.primary, size: 25),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated delivery',
                  style: ArtistTextStyles.small.copyWith(fontSize: 10),
                ),

                const SizedBox(height: 4),

                Text(
                  expectedDelivery,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.calendar_today_outlined,
            size: 19,
            color: ArtistColors.primary,
          ),
        ],
      ),
    );
  }

  // TRACKING TIMELINE

  Widget _buildTrackingTimeline() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Tracking Updates', Icons.timeline_rounded),

          const SizedBox(height: 21),

          _buildTimelineItem(
            icon: Icons.shopping_bag_rounded,
            title: 'Order Placed',
            subtitle: 'Your order was successfully placed',
            date: orderDate,
            completed: true,
          ),

          _buildTimelineItem(
            icon: Icons.verified_rounded,
            title: 'Order Confirmed',
            subtitle: 'Seller confirmed your order',
            date: '—',
            completed: _isStatusAtLeast('confirmed'),
            active: rawStatus.toLowerCase() == 'confirmed',
          ),

          _buildTimelineItem(
            icon: Icons.inventory_2_rounded,
            title: 'Item Packed',
            subtitle: 'Seller packed your item',
            date: '—',
            completed: _isStatusAtLeast('packed'),
            active: rawStatus.toLowerCase() == 'packed',
          ),

          _buildTimelineItem(
            icon: Icons.local_shipping_rounded,
            title: 'Shipped',
            subtitle: 'Your package is on the way',
            date: '—',
            completed: _isStatusAtLeast('shipped'),
            active: rawStatus.toLowerCase() == 'shipped',
          ),

          _buildTimelineItem(
            icon: Icons.delivery_dining_rounded,
            title: 'Out for Delivery',
            subtitle: 'Package will reach you soon',
            date: '—',
            completed: _isStatusAtLeast('out_for_delivery'),
            active: rawStatus.toLowerCase() == 'out_for_delivery',
          ),

          _buildTimelineItem(
            icon: Icons.home_rounded,
            title: 'Delivered',
            subtitle: 'Package delivered successfully',
            date: rawStatus.toLowerCase() == 'delivered' ? '—' : '—',
            completed: rawStatus.toLowerCase() == 'delivered',
            active: rawStatus.toLowerCase() == 'delivered',
            isLast: true,
          ),
        ],
      ),
    );
  }

  // STATUS PROGRESS

  bool _isStatusAtLeast(String status) {
    const statuses = [
      'pending',
      'confirmed',
      'packed',
      'shipped',
      'out_for_delivery',
      'delivered',
    ];

    final currentIndex = statuses.indexOf(rawStatus.toLowerCase());

    final targetIndex = statuses.indexOf(status.toLowerCase());

    if (currentIndex == -1 || targetIndex == -1) {
      return false;
    }

    return currentIndex >= targetIndex;
  }

  // TIMELINE ITEM

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
    required bool completed,
    bool active = false,
    bool isLast = false,
  }) {
    final color = completed
        ? ArtistColors.success
        : active
        ? ArtistColors.primary
        : ArtistColors.accent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.11),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.20)),
                ),
                child: Icon(icon, size: 17, color: color),
              ),

              if (!isLast)
                Container(
                  width: 2,
                  height: 47,
                  margin: const EdgeInsets.only(top: 2),
                  color: completed
                      ? ArtistColors.success.withOpacity(0.35)
                      : ArtistColors.accent.withOpacity(0.55),
                ),
            ],
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: ArtistTextStyles.bodyMedium.copyWith(
                                fontSize: 14,
                                fontWeight: completed || active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: completed || active
                                    ? ArtistColors.textPrimary
                                    : ArtistColors.textSecondary,
                              ),
                            ),
                          ),

                          if (active) ...[
                            const SizedBox(width: 7),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: ArtistColors.primary.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'CURRENT',
                                style: ArtistTextStyles.small.copyWith(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: ArtistColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        style: ArtistTextStyles.small.copyWith(
                          fontSize: 10.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  date,
                  textAlign: TextAlign.right,
                  style: ArtistTextStyles.small.copyWith(
                    fontSize: 9,
                    fontWeight: completed ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // PRODUCT CARD

  Widget _buildProductCard() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Your Item', Icons.shopping_bag_outlined),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ArtistColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ArtistColors.accent.withOpacity(0.30)),
            ),
            child: Row(
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: ArtistColors.light,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      (_order['productImage'] ?? _order['imageUrl'] ?? '')
                          .toString()
                          .trim()
                          .isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            (_order['productImage'] ?? _order['imageUrl'])
                                .toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              productIcon,
                              size: 35,
                              color: ArtistColors.primary,
                            ),
                          ),
                        )
                      : Icon(
                          productIcon,
                          size: 35,
                          color: ArtistColors.primary,
                        ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Quantity: $quantity',
                        style: ArtistTextStyles.small.copyWith(fontSize: 10.5),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        price,
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: ArtistColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // DELIVERY CARD

  Widget _buildDeliveryCard() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Delivery Address', Icons.location_on_outlined),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: ArtistColors.light.withOpacity(0.60),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: ArtistColors.surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.home_outlined,
                    size: 20,
                    color: ArtistColors.primary,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Address',
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        shippingAddress,
                        style: ArtistTextStyles.small.copyWith(
                          fontSize: 10.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: ArtistColors.primary,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  'EcoLoop Standard Delivery',
                  style: ArtistTextStyles.small.copyWith(fontSize: 11.5),
                ),
              ),

              Text(
                expectedDelivery,
                style: ArtistTextStyles.small.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ORDER INFORMATION

  Widget _buildOrderInformation() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Order Information', Icons.receipt_long_outlined),

          const SizedBox(height: 18),

          _infoRow('Order ID', orderId),

          _infoRow('Order Date', orderDate),

          _infoRow('Seller', sellerName),

          _infoRow('Quantity', quantity),

          _infoRow('Payment', _formatPaymentStatus()),

          _infoRow('Total Paid', price),

          _infoRow('Current Status', currentStatus, isLast: true),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: ArtistTextStyles.small.copyWith(fontSize: 11.5),
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: ArtistTextStyles.bodyMedium.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HELP CARD

  Widget _buildHelpCard() {
    return _section(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: ArtistColors.light,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ArtistColors.accent.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: ArtistColors.surface,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: ArtistColors.primary,
                size: 23,
              ),
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need help with your order?',
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Our support team is here to help.',
                    style: ArtistTextStyles.small.copyWith(fontSize: 10.5),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: () {
                _showMessage(
                  'Please use the support option in your account settings.',
                );
              },
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: ArtistColors.primary,
                size: 19,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MORE OPTIONS

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetOption(
                icon: Icons.refresh_rounded,
                title: 'Refresh Tracking',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _refreshOrder();
                },
              ),

              _sheetOption(
                icon: Icons.share_outlined,
                title: 'Share Tracking',
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showMessage(
                    'Use the order ID to identify this order: $orderId',
                  );
                },
              ),

              _sheetOption(
                icon: Icons.receipt_long_outlined,
                title: 'View Order Details',
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showMessage(
                    'Order details are already available on the previous page.',
                  );
                },
              ),

              _sheetOption(
                icon: Icons.help_outline_rounded,
                title: 'Get Help',
                onTap: () {
                  Navigator.pop(sheetContext);

                  _showMessage(
                    'Please use the support option in your account settings.',
                  );
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // SHEET OPTION

  Widget _sheetOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22),
      leading: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: ArtistColors.light,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: ArtistColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: ArtistTextStyles.bodyMedium.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  // SECTION

  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      color: ArtistColors.surface,
      child: child,
    );
  }

  // SECTION TITLE

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ArtistColors.primary),

        const SizedBox(width: 8),

        Text(
          title,
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // STATUS HELPERS

  Color _statusColor() {
    switch (rawStatus.toLowerCase()) {
      case 'pending':
        return ArtistColors.warning;

      case 'confirmed':
        return ArtistColors.info;

      case 'packed':
        return ArtistColors.primary;

      case 'shipped':
        return ArtistColors.info;

      case 'out_for_delivery':
        return ArtistColors.accent;

      case 'delivered':
        return ArtistColors.success;

      case 'cancelled':
        return ArtistColors.error;

      default:
        return ArtistColors.primary;
    }
  }

  IconData _statusIcon() {
    switch (rawStatus.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty_rounded;

      case 'confirmed':
        return Icons.verified_outlined;

      case 'packed':
        return Icons.inventory_2_outlined;

      case 'shipped':
        return Icons.local_shipping_outlined;

      case 'out_for_delivery':
        return Icons.delivery_dining_outlined;

      case 'delivered':
        return Icons.home_rounded;

      case 'cancelled':
        return Icons.cancel_outlined;

      default:
        return Icons.local_shipping_outlined;
    }
  }

  String _displayStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';

      case 'confirmed':
        return 'Confirmed';

      case 'packed':
        return 'Packed';

      case 'shipped':
        return 'Shipped';

      case 'out_for_delivery':
        return 'Out for Delivery';

      case 'delivered':
        return 'Delivered';

      case 'cancelled':
        return 'Cancelled';

      default:
        return status;
    }
  }

  String _formatPaymentStatus() {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return 'Paid';

      case 'pending':
        return 'Payment Pending';

      case 'refunded':
        return 'Refunded';

      case 'failed':
        return 'Failed';

      default:
        return _capitalize(paymentStatus);
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;

    return value[0].toUpperCase() + value.substring(1);
  }

  // MESSAGE

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: ArtistTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ArtistColors.textPrimary,
      ),
    );
  }
}
