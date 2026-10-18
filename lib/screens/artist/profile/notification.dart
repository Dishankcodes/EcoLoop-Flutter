import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../services/ecoloop_api.dart';

/// Account-scoped, sheet-backed EcoLoop notifications.
class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  final EcoLoopApi _api = EcoLoopApi.instance;

  List<Map<String, dynamic>> _notifications = <Map<String, dynamic>>[];
  bool _isLoading = true;
  bool _isMarkingAllRead = false;
  String? _error;

  int get _unreadCount =>
      _notifications.where((item) => item['isRead'] != true).length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final dynamic response = await _api.get('/notifications');
      final List<dynamic> rows = response is List ? response : <dynamic>[];
      final notifications =
          rows
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList()
            ..sort((a, b) => _createdAt(b).compareTo(_createdAt(a)));

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _markNotificationRead(Map<String, dynamic> notification) async {
    if (notification['isRead'] == true) {
      _showDetails(notification);
      return;
    }

    final int id = _asInt(notification['notificationId'] ?? notification['id']);
    if (id <= 0) {
      _showMessage(
        'This notification has an invalid ID. Refresh and try again.',
      );
      return;
    }

    try {
      await _api.post('/notifications/$id/read', <String, dynamic>{});
      if (!mounted) return;
      setState(() {
        final index = _notifications.indexWhere(
          (item) => _asInt(item['notificationId'] ?? item['id']) == id,
        );
        if (index >= 0) _notifications[index]['isRead'] = true;
      });
      final updated = _notifications.firstWhere(
        (item) => _asInt(item['notificationId'] ?? item['id']) == id,
        orElse: () => notification,
      );
      _showDetails(updated);
    } catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _markAllAsRead() async {
    final unread = _notifications
        .where((item) => item['isRead'] != true)
        .toList(growable: false);
    if (unread.isEmpty || _isMarkingAllRead) return;

    setState(() => _isMarkingAllRead = true);
    int succeeded = 0;
    String? firstError;

    for (final notification in unread) {
      final id = _asInt(notification['notificationId'] ?? notification['id']);
      if (id <= 0) continue;
      try {
        await _api.post('/notifications/$id/read', <String, dynamic>{});
        succeeded++;
      } catch (error) {
        firstError ??= _friendlyError(error);
      }
    }

    if (!mounted) return;
    setState(() {
      for (final notification in _notifications) {
        final id = _asInt(notification['notificationId'] ?? notification['id']);
        if (unread.any(
          (item) => _asInt(item['notificationId'] ?? item['id']) == id,
        )) {
          // The server is the source of truth; reload below corrects any failures.
          notification['isRead'] = true;
        }
      }
      _isMarkingAllRead = false;
    });

    await _loadNotifications(showLoader: false);
    if (!mounted) return;

    if (firstError != null) {
      _showMessage(
        'Some notifications could not be marked as read. $firstError',
      );
    } else {
      _showMessage(
        '$succeeded notification${succeeded == 1 ? '' : 's'} marked as read.',
      );
    }
  }

  void _showDetails(Map<String, dynamic> notification) {
    if (!mounted) return;
    final title = _string(notification['title'], fallback: 'EcoLoop update');
    final message = _string(notification['message']);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ArtistColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ArtistColors.textSecondary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _buildNotificationIcon(_string(notification['type'])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: ArtistColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  style: const TextStyle(
                    color: ArtistColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _formatDate(
                    notification['createdAt'] ?? notification['time'],
                  ),
                  style: const TextStyle(
                    color: ArtistColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: ArtistColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unreadCount;

    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.surface,
        elevation: 0,
        foregroundColor: ArtistColors.textPrimary,
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
          IconButton(
            tooltip: 'Refresh notifications',
            onPressed: _isLoading ? null : () => _loadNotifications(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (unreadCount > 0)
            TextButton(
              onPressed: _isMarkingAllRead ? null : _markAllAsRead,
              child: _isMarkingAllRead
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Read all',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ArtistColors.primary,
                      ),
                    ),
            ),
        ],
      ),
      body: _buildBody(unreadCount),
    );
  }

  Widget _buildBody(int unreadCount) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ArtistColors.primary),
      );
    }

    if (_error != null && _notifications.isEmpty) {
      return _buildErrorState();
    }

    if (_notifications.isEmpty) return _buildEmptyState();

    final unread = _notifications
        .where((item) => item['isRead'] != true)
        .toList();
    final read = _notifications
        .where((item) => item['isRead'] == true)
        .toList();

    return RefreshIndicator(
      color: ArtistColors.primary,
      onRefresh: () => _loadNotifications(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (_error != null) ...[_inlineError(), const SizedBox(height: 12)],
          if (unread.isNotEmpty) ...[
            _buildSectionTitle('New', '$unreadCount unread'),
            const SizedBox(height: 9),
            ...unread.map(_buildNotificationCard),
            const SizedBox(height: 14),
          ],
          if (read.isNotEmpty) ...[
            _buildSectionTitle('Earlier'),
            const SizedBox(height: 9),
            ...read.map(_buildNotificationCard),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] == true;
    final title = _string(notification['title'], fallback: 'EcoLoop update');
    final message = _string(notification['message']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isRead
            ? ArtistColors.surface
            : ArtistColors.light.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _markNotificationRead(notification),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead
                    ? ArtistColors.textSecondary.withValues(alpha: 0.08)
                    : ArtistColors.accent.withValues(alpha: 0.75),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(_string(notification['type'])),
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
                              title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: ArtistColors.textPrimary,
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
                        message,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.45,
                          color: ArtistColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(
                          notification['createdAt'] ?? notification['time'],
                        ),
                        style: const TextStyle(
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
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    final normalized = type.toLowerCase();
    IconData icon;

    if (normalized.contains('wishlist')) {
      icon = Icons.favorite_rounded;
    } else if (normalized.contains('order') ||
        normalized.contains('delivery')) {
      icon = Icons.shopping_bag_outlined;
    } else if (normalized.contains('donation') ||
        normalized.contains('pickup')) {
      icon = Icons.volunteer_activism_outlined;
    } else if (normalized.contains('review')) {
      icon = Icons.star_outline_rounded;
    } else if (normalized.contains('report')) {
      icon = Icons.flag_outlined;
    } else if (normalized.contains('voucher') || normalized.contains('promo')) {
      icon = Icons.card_giftcard_outlined;
    } else if (normalized.contains('reward') || normalized.contains('eco')) {
      icon = Icons.eco_outlined;
    } else if (normalized.contains('address')) {
      icon = Icons.location_on_outlined;
    } else {
      icon = Icons.notifications_active_outlined;
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

  Widget _buildSectionTitle(String title, [String? subtitle]) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ArtistColors.textPrimary,
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
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: ArtistColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: ArtistColors.textSecondary,
            ),
            const SizedBox(height: 14),
            const Text(
              'Could not load notifications',
              style: TextStyle(
                color: ArtistColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _error ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ArtistColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _loadNotifications(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArtistColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: ArtistColors.error,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? 'Could not refresh notifications.',
              style: const TextStyle(
                color: ArtistColors.textPrimary,
                fontSize: 11,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _loadNotifications(showLoader: false),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: ArtistColors.primary,
      onRefresh: () => _loadNotifications(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: Center(
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
                    const Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: ArtistColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'New orders, order status changes, stock alerts, reviews, followers and account updates will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: ArtistColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _createdAt(Map<String, dynamic> item) {
    final value = item['createdAt'] ?? item['time'];
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return 'Just now';
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value.toString().replaceFirst(' ', 'T'));
    if (date == null) return value.toString();

    final local = date.toLocal();
    final difference = DateTime.now().difference(local);
    if (difference.inSeconds < 60 && !difference.isNegative) return 'Just now';
    if (difference.inMinutes < 60 && !difference.isNegative) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inHours < 24 && !difference.isNegative) {
      return '${difference.inHours} hr ago';
    }
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7 && difference.inDays >= 0) {
      return '${difference.inDays} days ago';
    }

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  String _friendlyError(Object error) {
    if (error is EcoLoopApiException) return error.message;
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
