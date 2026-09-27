import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class SellingOrderStatus extends StatefulWidget {
  final Map<String, dynamic> order;

  const SellingOrderStatus({super.key, required this.order});

  @override
  State<SellingOrderStatus> createState() => _SellingOrderStatusState();
}

class _SellingOrderStatusState extends State<SellingOrderStatus> {
  // STATUS DATA

  final List<Map<String, dynamic>> _statuses = [
    {
      'status': 'pending',
      'title': 'New Order Received',
      'description': 'You have received a new order from the buyer.',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'status': 'confirmed',
      'title': 'Order Confirmed',
      'description': 'You have confirmed the buyer\'s order.',
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'status': 'packed',
      'title': 'Item Packed',
      'description': 'The item has been packed and is ready for pickup.',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'status': 'shipped',
      'title': 'Order Shipped',
      'description': 'The package has been handed over for delivery.',
      'icon': Icons.local_shipping_outlined,
    },
    {
      'status': 'out_for_delivery',
      'title': 'Out for Delivery',
      'description': 'The package is on its way to the buyer.',
      'icon': Icons.delivery_dining_outlined,
    },
    {
      'status': 'delivered',
      'title': 'Order Delivered',
      'description': 'The buyer has received the order.',
      'icon': Icons.home_outlined,
    },
  ];

  late String _currentStatus;

  String? _selectedStatus;

  // INIT

  @override
  void initState() {
    super.initState();

    _currentStatus =
        widget.order['status']?.toString().toLowerCase() ?? 'pending';

    // Backend uses cancelled separately.
    // It is not part of the normal forward-progress timeline.
    if (_currentStatus == 'cancelled') {
      _selectedStatus = null;
    } else {
      _selectedStatus = _currentStatus;
    }
  }

  // GETTERS

  String get productName {
    return widget.order['productTitle']?.toString() ??
        widget.order['product']?.toString() ??
        'Product';
  }

  String get orderId {
    return widget.order['orderId']?.toString() ?? '-';
  }

  String get buyerName {
    if (widget.order['buyerName'] != null) {
      return widget.order['buyerName'].toString();
    }

    if (widget.order['buyer'] != null) {
      return widget.order['buyer'].toString();
    }

    final dynamic buyerId = widget.order['buyerId'];

    return buyerId != null ? 'Buyer #$buyerId' : 'Buyer';
  }

  String get quantity {
    return widget.order['quantity']?.toString() ?? '1';
  }

  String get price {
    final dynamic total = widget.order['totalAmount'];

    if (total == null) {
      final dynamic oldPrice = widget.order['price'];

      return oldPrice?.toString() ?? '₹0';
    }

    return '₹${_formatPrice(total)}';
  }

  IconData get productIcon {
    return widget.order['icon'] as IconData? ?? Icons.inventory_2_outlined;
  }

  // STATUS INDEX

  int _statusIndex(String status) {
    final int index = _statuses.indexWhere((item) => item['status'] == status);

    return index == -1 ? 0 : index;
  }

  bool _isCompleted(String status) {
    if (_currentStatus == 'cancelled') {
      return false;
    }

    return _statusIndex(_currentStatus) >= _statusIndex(status);
  }

  bool _isCurrent(String status) {
    return _currentStatus == status;
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: _buildAppBar(),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 25),
                child: Column(
                  children: [
                    _buildOrderHeader(),

                    if (_currentStatus == 'cancelled') _buildCancelledCard(),

                    _buildCurrentStatusCard(),

                    _buildStatusTimeline(),

                    if (_currentStatus != 'cancelled' &&
                        _currentStatus != 'delivered')
                      _buildSelectStatusSection(),

                    _buildSellerNote(),
                  ],
                ),
              ),
            ),

            if (_currentStatus != 'cancelled' && _currentStatus != 'delivered')
              _buildBottomButton(),
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
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_rounded),
      ),

      title: Text(
        'Update Order Status',
        style: ArtistTextStyles.title.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      centerTitle: true,
    );
  }

  // ORDER HEADER

  Widget _buildOrderHeader() {
    return Container(
      width: double.infinity,
      color: ArtistColors.surface,

      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),

      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,

            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(16),
            ),

            child: Icon(productIcon, size: 30, color: ArtistColors.primary),
          ),

          const SizedBox(width: 13),

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

                const SizedBox(height: 5),

                Text(
                  'Order #$orderId',
                  style: ArtistTextStyles.small.copyWith(fontSize: 10.5),
                ),

                const SizedBox(height: 3),

                Text(
                  'Buyer: $buyerName',
                  style: ArtistTextStyles.small.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            price,
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: ArtistColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // CANCELLED CARD

  Widget _buildCancelledCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: ArtistColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.error.withOpacity(0.25)),
      ),

      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,

            decoration: BoxDecoration(
              color: ArtistColors.error.withOpacity(0.10),
              shape: BoxShape.circle,
            ),

            child: const Icon(Icons.cancel_outlined, color: ArtistColors.error),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Cancelled',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    color: ArtistColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'This order has been cancelled and cannot be updated.',
                  style: ArtistTextStyles.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CURRENT STATUS

  Widget _buildCurrentStatusCard() {
    final Map<String, dynamic> current = _statuses.firstWhere(
      (item) => item['status'] == _currentStatus,
      orElse: () => {
        'status': 'cancelled',
        'title': 'Order Cancelled',
        'description': 'This order has been cancelled.',
        'icon': Icons.cancel_outlined,
      },
    );

    final bool cancelled = _currentStatus == 'cancelled';

    final Color statusColor = cancelled
        ? ArtistColors.error
        : ArtistColors.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,

            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),

            child: Icon(current['icon'], color: statusColor, size: 25),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: ArtistTextStyles.small.copyWith(fontSize: 10),
                ),

                const SizedBox(height: 4),

                Text(
                  current['title'],
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  current['description'],
                  style: ArtistTextStyles.small.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STATUS TIMELINE

  Widget _buildStatusTimeline() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArtistColors.accent.withOpacity(0.35)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress',
            style: ArtistTextStyles.title.copyWith(fontSize: 18),
          ),

          const SizedBox(height: 20),

          ...List.generate(_statuses.length, (index) {
            final Map<String, dynamic> item = _statuses[index];

            return _buildTimelineItem(
              item: item,
              index: index,
              isLast: index == _statuses.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required Map<String, dynamic> item,
    required int index,
    required bool isLast,
  }) {
    final String status = item['status'].toString();

    final bool completed = _isCompleted(status);

    final bool current = _isCurrent(status);

    final Color iconColor = completed
        ? ArtistColors.success
        : ArtistColors.textSecondary.withOpacity(0.45);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 35,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),

                height: 32,
                width: 32,

                decoration: BoxDecoration(
                  color: current
                      ? ArtistColors.primary
                      : completed
                      ? ArtistColors.light
                      : ArtistColors.background,

                  shape: BoxShape.circle,

                  border: Border.all(
                    color: current
                        ? ArtistColors.primary
                        : completed
                        ? ArtistColors.success
                        : ArtistColors.accent,
                    width: current ? 2 : 1,
                  ),
                ),

                child: Icon(
                  current
                      ? Icons.radio_button_checked_rounded
                      : completed
                      ? Icons.check_rounded
                      : item['icon'],
                  size: current ? 17 : 16,
                  color: current ? Colors.white : iconColor,
                ),
              ),

              if (!isLast)
                Container(
                  height: 45,
                  width: 2,
                  color: completed
                      ? ArtistColors.success.withOpacity(0.35)
                      : ArtistColors.accent.withOpacity(0.35),
                ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['title'],
                        style: ArtistTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: current || completed
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: current || completed
                              ? ArtistColors.textPrimary
                              : ArtistColors.textSecondary,
                        ),
                      ),
                    ),

                    if (current)
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
                ),

                const SizedBox(height: 4),

                Text(
                  item['description'],
                  style: ArtistTextStyles.small.copyWith(
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // SELECT STATUS

  Widget _buildSelectStatusSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArtistColors.accent.withOpacity(0.35)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Status',
            style: ArtistTextStyles.title.copyWith(fontSize: 18),
          ),

          const SizedBox(height: 5),

          Text(
            'Select the latest status of this order.',
            style: ArtistTextStyles.small.copyWith(fontSize: 11),
          ),

          const SizedBox(height: 16),

          ..._statuses.map((item) => _buildStatusOption(item)),
        ],
      ),
    );
  }

  // STATUS OPTION

  Widget _buildStatusOption(Map<String, dynamic> item) {
    final String status = item['status'].toString();

    final bool selected = _selectedStatus == status;

    final bool isCurrent = _currentStatus == status;

    final int optionIndex = _statusIndex(status);

    final int currentIndex = _statusIndex(_currentStatus);

    final bool isPrevious = optionIndex < currentIndex;

    // Statuses should move forward only.
    final bool canSelect = !isPrevious && !isCurrent;

    return Opacity(
      opacity: isPrevious ? 0.55 : 1,

      child: InkWell(
        borderRadius: BorderRadius.circular(15),

        onTap: canSelect
            ? () {
                setState(() {
                  _selectedStatus = status;
                });
              }
            : null,

        child: Container(
          margin: const EdgeInsets.only(bottom: 9),

          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            color: selected ? ArtistColors.light : ArtistColors.background,

            borderRadius: BorderRadius.circular(15),

            border: Border.all(
              color: selected
                  ? ArtistColors.primary
                  : ArtistColors.accent.withOpacity(0.30),
              width: selected ? 1.5 : 1,
            ),
          ),

          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,

                decoration: BoxDecoration(
                  color: selected ? ArtistColors.primary : ArtistColors.surface,
                  borderRadius: BorderRadius.circular(11),
                ),

                child: Icon(
                  item['icon'],
                  size: 19,
                  color: selected ? Colors.white : ArtistColors.primary,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        fontSize: 12.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      item['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.small.copyWith(fontSize: 9.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: ArtistColors.success.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),

                  child: Text(
                    'Current',
                    style: ArtistTextStyles.small.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: ArtistColors.success,
                    ),
                  ),
                )
              else if (isPrevious)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 19,
                  color: ArtistColors.success,
                )
              else
                Container(
                  height: 21,
                  width: 21,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? ArtistColors.primary
                          : ArtistColors.textSecondary.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),

                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: ArtistColors.primary,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // SELLER NOTE

  Widget _buildSellerNote() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: ArtistColors.light.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,

            decoration: BoxDecoration(
              color: ArtistColors.surface,
              borderRadius: BorderRadius.circular(11),
            ),

            child: const Icon(
              Icons.eco_outlined,
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
                  'EcoLoop Seller Tip',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Keep your buyer updated by changing '
                  'the order status as soon as the item '
                  'moves to the next stage.',
                  style: ArtistTextStyles.small.copyWith(
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // BOTTOM BUTTON

  Widget _buildBottomButton() {
    final bool hasChange =
        _selectedStatus != null && _selectedStatus != _currentStatus;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),

      decoration: BoxDecoration(
        color: ArtistColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: SizedBox(
          width: double.infinity,
          height: 50,

          child: ElevatedButton(
            onPressed: hasChange ? _confirmStatusChange : null,

            style: ElevatedButton.styleFrom(
              backgroundColor: ArtistColors.primary,

              disabledBackgroundColor: ArtistColors.accent.withOpacity(0.45),

              foregroundColor: Colors.white,

              disabledForegroundColor: Colors.white.withOpacity(0.75),

              elevation: 0,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),

            child: Text(
              hasChange
                  ? 'Update to ${_formatStatus(_selectedStatus!)}'
                  : 'No Status Change',
              style: ArtistTextStyles.button.copyWith(fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  // CONFIRM STATUS CHANGE

  void _confirmStatusChange() {
    if (_selectedStatus == null || _selectedStatus == _currentStatus) {
      return;
    }

    final String newStatus = _selectedStatus!;

    final Map<String, dynamic> selectedData = _statuses.firstWhere(
      (item) => item['status'] == newStatus,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),

      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  height: 4,
                  width: 42,

                  decoration: BoxDecoration(
                    color: ArtistColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  height: 58,
                  width: 58,

                  decoration: const BoxDecoration(
                    color: ArtistColors.light,
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    selectedData['icon'],
                    color: ArtistColors.primary,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Update Order Status?',
                  style: ArtistTextStyles.title.copyWith(fontSize: 19),
                ),

                const SizedBox(height: 7),

                Text(
                  'Change order #$orderId to '
                  '"${_formatStatus(newStatus)}".',
                  textAlign: TextAlign.center,
                  style: ArtistTextStyles.body.copyWith(fontSize: 11.5),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },

                        style: OutlinedButton.styleFrom(
                          foregroundColor: ArtistColors.primary,

                          side: const BorderSide(color: ArtistColors.primary),

                          minimumSize: const Size.fromHeight(48),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),

                        child: Text(
                          'Cancel',
                          style: ArtistTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);

                          _updateStatus(newStatus);
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtistColors.primary,

                          foregroundColor: Colors.white,

                          elevation: 0,

                          minimumSize: const Size.fromHeight(48),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),

                        child: Text(
                          'Confirm',
                          style: ArtistTextStyles.button.copyWith(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // UPDATE STATUS

  void _updateStatus(String newStatus) {
    setState(() {
      _currentStatus = newStatus;
      _selectedStatus = newStatus;

      // Keep local order data synchronized
      // until API integration is added.
      widget.order['status'] = newStatus;

      widget.order['updatedAt'] = DateTime.now().toIso8601String();
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,

          backgroundColor: ArtistColors.primary,

          margin: const EdgeInsets.all(16),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),

          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  'Order updated to '
                  '${_formatStatus(newStatus)}',
                  style: ArtistTextStyles.body.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // FORMAT STATUS

  String _formatStatus(String status) {
    if (status.trim().isEmpty) {
      return '-';
    }

    return status
        .split('_')
        .map((part) {
          if (part.isEmpty) {
            return '';
          }

          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
  }

  // PRICE FORMAT

  String _formatPrice(dynamic value) {
    double amount = 0;

    if (value is num) {
      amount = value.toDouble();
    } else {
      amount = double.tryParse('${value ?? ''}') ?? 0;
    }

    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }

    return amount.toStringAsFixed(2);
  }
}
