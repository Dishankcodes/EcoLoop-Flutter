import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';

class SellingOrderStatus extends StatefulWidget {
  final Map<String, dynamic> order;

  const SellingOrderStatus({super.key, required this.order});

  @override
  State<SellingOrderStatus> createState() => _SellingOrderStatusState();
}

class _SellingOrderStatusState extends State<SellingOrderStatus> {
  // ============================================================
  // STATUS DATA
  // ============================================================

  final List<Map<String, dynamic>> _statuses = [
    {
      'status': 'New Order',
      'title': 'New Order Received',
      'description': 'You have received a new order from the buyer.',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'status': 'Confirmed',
      'title': 'Order Confirmed',
      'description': 'You have confirmed the buyer\'s order.',
      'icon': Icons.check_circle_outline_rounded,
    },
    {
      'status': 'Packed',
      'title': 'Item Packed',
      'description': 'The item has been packed and is ready for pickup.',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'status': 'Shipped',
      'title': 'Order Shipped',
      'description': 'The package has been handed over for delivery.',
      'icon': Icons.local_shipping_outlined,
    },
    {
      'status': 'Out for Delivery',
      'title': 'Out for Delivery',
      'description': 'The package is on its way to the buyer.',
      'icon': Icons.delivery_dining_outlined,
    },
    {
      'status': 'Delivered',
      'title': 'Order Delivered',
      'description': 'The buyer has received the order.',
      'icon': Icons.home_outlined,
    },
  ];

  late String _currentStatus;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();

    _currentStatus = widget.order['status']?.toString() ?? 'New Order';

    _selectedStatus = _currentStatus;
  }

  // ============================================================
  // GETTERS
  // ============================================================

  String get productName =>
      widget.order['product']?.toString() ?? 'Wooden Study Table';

  String get orderId => widget.order['orderId']?.toString() ?? '#EL1001';

  String get buyerName =>
      widget.order['buyerName']?.toString() ??
      widget.order['buyer']?.toString() ??
      'Rahul Sharma';

  String get quantity => widget.order['quantity']?.toString() ?? '1';

  String get price => widget.order['price']?.toString() ?? '₹2,500';

  IconData get productIcon =>
      widget.order['icon'] as IconData? ?? Icons.inventory_2_outlined;

  // ============================================================
  // STATUS INDEX
  // ============================================================

  int _statusIndex(String status) {
    final index = _statuses.indexWhere((item) => item['status'] == status);

    return index == -1 ? 0 : index;
  }

  bool _isCompleted(String status) {
    return _statusIndex(_currentStatus) >= _statusIndex(status);
  }

  bool _isCurrent(String status) {
    return _currentStatus == status;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    _buildCurrentStatusCard(),
                    _buildStatusTimeline(),
                    _buildSelectStatusSection(),
                    _buildSellerNote(),
                  ],
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text(
        'Update Order Status',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      centerTitle: true,
    );
  }

  // ============================================================
  // ORDER HEADER
  // ============================================================

  Widget _buildOrderHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(productIcon, size: 30, color: AppColors.primary),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Order $orderId',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Buyer: $buyerName',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            price,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENT STATUS
  // ============================================================

  Widget _buildCurrentStatusCard() {
    final current = _statuses.firstWhere(
      (item) => item['status'] == _currentStatus,
      orElse: () => _statuses.first,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
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
              color: AppColors.light,
              shape: BoxShape.circle,
            ),
            child: Icon(current['icon'], color: AppColors.primary, size: 25),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  current['title'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  current['description'],
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

  // ============================================================
  // STATUS TIMELINE
  // ============================================================

  Widget _buildStatusTimeline() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.35)),
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

          const SizedBox(height: 20),

          ...List.generate(_statuses.length, (index) {
            final item = _statuses[index];

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
    final String status = item['status'];

    final bool completed = _isCompleted(status);

    final bool current = _isCurrent(status);

    final Color iconColor = completed
        ? AppColors.success
        : AppColors.textSecondary.withOpacity(0.45);

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
                      ? AppColors.primary
                      : completed
                      ? AppColors.light
                      : AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: current
                        ? AppColors.primary
                        : completed
                        ? AppColors.success
                        : AppColors.accent,
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
                      ? AppColors.success.withOpacity(0.35)
                      : AppColors.accent.withOpacity(0.35),
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: current || completed
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: current || completed
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
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
                          color: AppColors.primary.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  item['description'],
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SELECT STATUS
  // ============================================================

  Widget _buildSelectStatusSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Select the latest status of this order.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 16),

          ..._statuses.map((item) => _buildStatusOption(item)),
        ],
      ),
    );
  }

  Widget _buildStatusOption(Map<String, dynamic> item) {
    final String status = item['status'];
    final bool selected = _selectedStatus == status;

    final bool isCurrent = _currentStatus == status;

    final int optionIndex = _statusIndex(status);

    final int currentIndex = _statusIndex(_currentStatus);

    final bool isPrevious = optionIndex < currentIndex;

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
            color: selected ? AppColors.light : AppColors.background,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.accent.withOpacity(0.30),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  item['icon'],
                  size: 19,
                  color: selected ? Colors.white : AppColors.primary,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      item['description'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
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
                    color: AppColors.success.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                )
              else if (isPrevious)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 19,
                  color: AppColors.success,
                )
              else
                Container(
                  height: 21,
                  width: 21,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: AppColors.primary,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELLER NOTE
  // ============================================================

  Widget _buildSellerNote() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.light.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.eco_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EcoLoop Seller Tip',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Keep your buyer updated by changing '
                  'the order status as soon as the item '
                  'moves to the next stage.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.45,
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

  // ============================================================
  // BOTTOM BUTTON
  // ============================================================

  Widget _buildBottomButton() {
    final bool hasChange =
        _selectedStatus != null && _selectedStatus != _currentStatus;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.accent.withOpacity(0.45),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              hasChange ? 'Update to $_selectedStatus' : 'No Status Change',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONFIRM STATUS CHANGE
  // ============================================================

  void _confirmStatusChange() {
    if (_selectedStatus == null || _selectedStatus == _currentStatus) {
      return;
    }

    final String newStatus = _selectedStatus!;

    final selectedData = _statuses.firstWhere(
      (item) => item['status'] == newStatus,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selectedData['icon'],
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Update Order Status?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'Change order $orderId to "$newStatus".',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
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
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(fontWeight: FontWeight.w700),
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

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  void _updateStatus(String newStatus) {
    setState(() {
      _currentStatus = newStatus;
      _selectedStatus = newStatus;

      // Keep the local order map in sync for the
      // current UI flow.
      widget.order['status'] = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
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
                'Order updated to $newStatus',
                style: const TextStyle(
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
}
