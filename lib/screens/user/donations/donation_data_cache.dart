/// Short-lived in-memory cache for the signed-in user's donation history.
/// This cache is never written to disk and is cleared after donation mutations.
class DonationHistorySnapshot {
  const DonationHistorySnapshot({
    required this.donations,
    required this.categoryNames,
    required this.savedAt,
  });

  final List<Map<String, dynamic>> donations;
  final Map<String, String> categoryNames;
  final DateTime savedAt;
}

class DonationDataCache {
  DonationDataCache._();

  static const Duration ttl = Duration(minutes: 5);
  static final Map<String, DonationHistorySnapshot> _history = {};

  static DonationHistorySnapshot? read(String key) {
    final value = _history[key];
    if (value == null) return null;
    if (DateTime.now().difference(value.savedAt) >= ttl) {
      _history.remove(key);
      return null;
    }
    return DonationHistorySnapshot(
      donations: value.donations
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      categoryNames: Map<String, String>.from(value.categoryNames),
      savedAt: value.savedAt,
    );
  }

  static void write(
    String key,
    List<Map<String, dynamic>> donations,
    Map<String, String> categoryNames,
  ) {
    _history[key] = DonationHistorySnapshot(
      donations: donations
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      categoryNames: Map<String, String>.from(categoryNames),
      savedAt: DateTime.now(),
    );
  }

  static void clear() => _history.clear();
}
