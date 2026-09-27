import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  // DUMMY ARTIST NOTIFICATIONS
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'type': 'order',
      'title': 'New order received',
      'message': 'Your Handmade Wooden Lamp has been purchased by a buyer.',
      'time': '10 min ago',
      'isRead': false,
    },
    {
      'id': 2,
      'type': 'wishlist',
      'title': 'Your product was liked',
      'message': 'Someone added your Recycled Wall Decor to their wishlist.',
      'time': '25 min ago',
      'isRead': false,
    },
    {
      'id': 3,
      'type': 'follower',
      'title': 'New follower',
      'message': 'A user started following your artist profile.',
      'time': '1 hour ago',
      'isRead': false,
    },
    {
      'id': 4,
      'type': 'review',
      'title': 'New review received',
      'message': 'A buyer left a 5-star review on your Wooden Chair.',
      'time': '2 hours ago',
      'isRead': false,
    },
    {
      'id': 5,
      'type': 'payment',
      'title': 'Payment received',
      'message': '₹1,499 has been added to your earnings from Order #EL1024.',
      'time': 'Yesterday',
      'isRead': true,
    },
    {
      'id': 6,
      'type': 'delivery',
      'title': 'Order delivered',
      'message': 'Order #EL1019 has been successfully delivered to the buyer.',
      'time': 'Yesterday',
      'isRead': true,
    },
    {
      'id': 7,
      'type': 'product',
      'title': 'Product approved',
      'message': 'Your product "Upcycled Wooden Shelf" is now live on EcoLoop.',
      'time': '2 days ago',
      'isRead': true,
    },
    {
      'id': 8,
      'type': 'eco',
      'title': 'Keep creating an impact',
      'message':
          'Your products are helping give pre-loved materials a new life.',
      'time': '3 days ago',
      'isRead': true,
    },
    {
      'id': 9,
      'type': 'message',
      'title': 'New buyer message',
      'message': 'A buyer sent you a message about one of your listings.',
      'time': '4 days ago',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((notification) => !notification['isRead'])
        .length;

    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ArtistColors.textPrimary,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Notifications',
          style: ArtistTextStyles.title.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Read all',
                style: ArtistTextStyles.small.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.primary,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 25),
              children: [
                if (unreadCount > 0) ...[
                  _buildSectionTitle('New', '$unreadCount unread'),
                  const SizedBox(height: 8),
                ],
                ..._buildUnreadNotifications(),
                if (_hasReadNotifications()) ...[
                  const SizedBox(height: 10),
                  _buildSectionTitle('Earlier'),
                  const SizedBox(height: 8),
                  ..._buildReadNotifications(),
                ],
              ],
            ),
    );
  }

  // UNREAD NOTIFICATIONS
  List<Widget> _buildUnreadNotifications() {
    final unread = _notifications
        .where((notification) => !notification['isRead'])
        .toList();

    return unread
        .map((notification) => _buildNotificationCard(notification))
        .toList();
  }

  // READ NOTIFICATIONS
  List<Widget> _buildReadNotifications() {
    final read = _notifications
        .where((notification) => notification['isRead'])
        .toList();

    return read
        .map((notification) => _buildNotificationCard(notification))
        .toList();
  }

  // CHECK READ NOTIFICATIONS
  bool _hasReadNotifications() {
    return _notifications.any((notification) => notification['isRead']);
  }

  // SECTION TITLE
  Widget _buildSectionTitle(String title, [String? subtitle]) {
    return Row(
      children: [
        Text(
          title,
          style: ArtistTextStyles.title.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle,
              style: ArtistTextStyles.small.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: ArtistColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // NOTIFICATION CARD
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
          color: ArtistColors.error,
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
                ? ArtistColors.surface
                : ArtistColors.light.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? ArtistColors.border
                  : ArtistColors.primary.withOpacity(0.55),
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
                            style: ArtistTextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            height: 7,
                            width: 7,
                            decoration: const BoxDecoration(
                              color: ArtistColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification['message'].toString(),
                      style: ArtistTextStyles.caption.copyWith(
                        fontSize: 11.5,
                        height: 1.45,
                        color: ArtistColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      notification['time'].toString(),
                      style: ArtistTextStyles.small.copyWith(
                        fontSize: 9.5,
                        color: ArtistColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: ArtistColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NOTIFICATION ICON
  Widget _buildNotificationIcon(String type) {
    IconData icon;

    switch (type) {
      case 'order':
        icon = Icons.shopping_bag_outlined;
        break;
      case 'wishlist':
        icon = Icons.favorite_outline_rounded;
        break;
      case 'follower':
        icon = Icons.people_outline_rounded;
        break;
      case 'review':
        icon = Icons.star_outline_rounded;
        break;
      case 'payment':
        icon = Icons.account_balance_wallet_outlined;
        break;
      case 'delivery':
        icon = Icons.local_shipping_outlined;
        break;
      case 'product':
        icon = Icons.inventory_2_outlined;
        break;
      case 'message':
        icon = Icons.chat_bubble_outline_rounded;
        break;
      case 'eco':
        icon = Icons.eco_outlined;
        break;
      default:
        icon = Icons.notifications_none_rounded;
    }

    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, size: 21, color: ArtistColors.primary),
    );
  }

  // MARK ALL AS READ
  void _markAllAsRead() {
    setState(() {
      for (final notification in _notifications) {
        notification['isRead'] = true;
      }
    });

    _showMessage('All notifications marked as read.');
  }

  // OPEN NOTIFICATION
  void _openNotification(Map<String, dynamic> notification) {
    setState(() {
      notification['isRead'] = true;
    });

    _showMessage('${notification['title']} will be connected later.');
  }

  // EMPTY STATE
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
              decoration: const BoxDecoration(
                color: ArtistColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 42,
                color: ArtistColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No notifications yet',
              style: ArtistTextStyles.title.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you receive updates about orders,\n'
              'products, followers or earnings, they will appear here.',
              textAlign: TextAlign.center,
              style: ArtistTextStyles.caption.copyWith(
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SHOW MESSAGE
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
