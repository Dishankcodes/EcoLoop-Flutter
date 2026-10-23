import 'package:flutter/foundation.dart';

/// In-memory account snapshot shared by Home, Profile, and Edit Profile.
///
/// Publishes successful account updates immediately so mounted screens refresh
/// without waiting for navigation, a manual refresh, or another API request.
class ProfileSnapshot {
  ProfileSnapshot._();

  static final ValueNotifier<Map<String, dynamic>?> account =
      ValueNotifier<Map<String, dynamic>?>(null);

  static int revision = 0;

  static void publish(Map<String, dynamic> update) {
    if (update.isEmpty) return;
    revision++;
    account.value = <String, dynamic>{...?account.value, ...update};
  }

  static void clear() {
    revision++;
    account.value = null;
  }
}
