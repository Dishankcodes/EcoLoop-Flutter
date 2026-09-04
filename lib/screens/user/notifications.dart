import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  // ============================================================
  // DUMMY NOTIFICATIONS
  // ============================================================

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'type': 'wishlist',
      'title': 'Your item was liked',
      'message': 'Someone added your Wooden Study Table to their wishlist.',
      'time': '10 min ago',
      'isRead': false,
    },
    {
      'id': 2,
      'type': 'order',
      'title': 'New order received',
      'message': 'Your Wooden Chair has been purchased by a buyer.',
      'time': '25 min ago',
      'isRead': false,
    },
    {
      'id': 3,
      'type': 'order',
      'title': 'Order confirmed',
      'message': 'Your order #EL1024 has been confirmed by the seller.',
      'time': '1 hour ago',
      'isRead': false,
    },
    {
      'id': 4,
      'type': 'delivery',
      'title': 'Order shipped',
      'message': 'Your order #EL1019 is on its way.',
      'time': 'Yesterday',
      'isRead': true,
    },
    {
      'id': 5,
      'type': 'donation',
      'title': 'Donation pickup scheduled',
      'message': 'Your donated item will be picked up tomorrow.',
      'time': 'Yesterday',
      'isRead': true,
    },
    {
      'id': 6,
      'type': 'reward',
      'title': 'You earned an EcoLoop reward',
      'message': 'Your recent activity earned you EcoPoints.',
      'time': '2 days ago',
      'isRead': true,
    },
    {
      'id': 7,
      'type': 'message',
      'title': 'New message',
      'message': 'Rahul sent you a message about your listing.',
      'time': '3 days ago',
      'isRead': true,
    },
    {
      'id': 8,
      'type': 'eco',
      'title': 'Make a bigger impact 🌱',
      'message': 'Donate unused items and give them a second life.',
      'time': '5 days ago',
      'isRead': true,
    },
  ];

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((notification) => !notification['isRead'])
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Read all',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 25),
              children: [
                if (unreadCount > 0) ...[
                  _buildSectionTitle('New', '$unreadCount unread'),
                  const SizedBox(height: 8),
                ],

                ..._buildUnreadNotifications(),

                const SizedBox(height: 20),

                if (_hasReadNotifications()) ...[
                  _buildSectionTitle('Earlier'),
                  const SizedBox(height: 8),
                  ..._buildReadNotifications(),
                ],
              ],
            ),
    );
  }

  // ============================================================
  // UNREAD
  // ============================================================

  List<Widget> _buildUnreadNotifications() {
    final unread = _notifications
        .where((notification) => !notification['isRead'])
        .toList();

    return unread
        .map((notification) => _buildNotificationCard(notification))
        .toList();
  }

  // ============================================================
  // READ
  // ============================================================

  List<Widget> _buildReadNotifications() {
    final read = _notifications
        .where((notification) => notification['isRead'])
        .toList();

    return read
        .map((notification) => _buildNotificationCard(notification))
        .toList();
  }

  bool _hasReadNotifications() {
    return _notifications.any((notification) => notification['isRead']);
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title, [String? subtitle]) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] == true;

    return Dismissible(
      key: ValueKey(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() {
          _notifications.removeWhere(
            (item) => item['id'] == notification['id'],
          );
        });
      },
      child: InkWell(
        onTap: () => _openNotification(notification),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead
                ? AppColors.surface
                : AppColors.light.withOpacity(0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? Colors.transparent
                  : AppColors.accent.withOpacity(0.7),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification['type'].toString()),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'].toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            height: 7,
                            width: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      notification['message'].toString(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      notification['time'].toString(),
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION ICON
  // ============================================================

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color backgroundColor;

    switch (type) {
      case 'wishlist':
        icon = Icons.favorite_rounded;
        backgroundColor = AppColors.light;
        break;

      case 'order':
        icon = Icons.shopping_bag_outlined;
        backgroundColor = AppColors.light;
        break;

      case 'delivery':
        icon = Icons.local_shipping_outlined;
        backgroundColor = AppColors.light;
        break;

      case 'donation':
        icon = Icons.volunteer_activism_outlined;
        backgroundColor = AppColors.light;
        break;

      case 'reward':
        icon = Icons.card_giftcard_outlined;
        backgroundColor = AppColors.light;
        break;

      case 'message':
        icon = Icons.chat_bubble_outline_rounded;
        backgroundColor = AppColors.light;
        break;

      case 'eco':
        icon = Icons.eco_outlined;
        backgroundColor = AppColors.light;
        break;

      default:
        icon = Icons.notifications_none_rounded;
        backgroundColor = AppColors.light;
    }

    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 21, color: AppColors.primary),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _markAllAsRead() {
    setState(() {
      for (final notification in _notifications) {
        notification['isRead'] = true;
      }
    });

    _showMessage('All notifications marked as read.');
  }

  void _openNotification(Map<String, dynamic> notification) {
    setState(() {
      notification['isRead'] = true;
    });

    _showMessage('Notification details will be connected later.');
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'When you receive updates about orders,\n'
              'listings or donations, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
