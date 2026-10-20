import 'dart:convert';

import 'package:dio/dio.dart';

import '../api/api_manager.dart';
import '../shared_preferences_util.dart';

class EcoLoopApiException implements Exception {
  final String message;

  const EcoLoopApiException(this.message);

  @override
  String toString() => message;
}

/// Thin typed-enough wrapper around the routes implemented in Code.gs.
/// All writes go through the same Dio instance as the existing Retrofit client,
/// so the Apps Script redirect interceptor is reused.
class _CachedGet {
  const _CachedGet(this.value, this.expiresAt);

  final dynamic value;
  final DateTime expiresAt;
}

class EcoLoopApi {
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbzvHq06GwL_I8qH2IPyQP36dRlESN62PYF4Ak5WkRE2VjHL5a-tr0Yk_KEtSvU_ZL6IbQ/exec';

  EcoLoopApi._();

  static final EcoLoopApi instance = EcoLoopApi._();

  // In-memory cache for safe reference/discovery data and selected account snapshots.
  // Transaction-critical endpoints remain fresh on every new call.
  static const Duration _categoriesTtl = Duration(minutes: 10);
  static const Duration _locationsTtl = Duration(hours: 6);
  static const Duration _publicDiscoveryTtl = Duration(minutes: 5);
  static const Duration _privateSnapshotTtl = Duration(minutes: 5);
  static const int _maxCacheEntries = 160;

  final Map<String, _CachedGet> _getCache = <String, _CachedGet>{};
  final Map<String, Future<dynamic>> _inFlightGets =
      <String, Future<dynamic>>{};

  int _cacheGeneration = 0;

  /// Clear cached GET data after a successful write or when the caller knows
  /// that server-side data changed. This is deliberately broad and safe.
  void invalidateCache() {
    _cacheGeneration++;
    _getCache.clear();

    // Existing requests cannot be cancelled, but new callers must not join a
    // request that started before the write/invalidation.
    _inFlightGets.clear();
  }

  String get _token =>
      (Prefs.getString('userRole').toLowerCase() == 'artist'
              ? Prefs.getString('artistToken')
              : Prefs.getString('authToken'))
          .trim();

  Future<dynamic> get(
    String path, {
    Map<String, dynamic> query = const {},
  }) async {
    final ttl = _cacheTtlFor(path, query);
    final cacheKey = _cacheKey(path, query);

    // Cache only explicit read-only snapshots. Account-scoped cache keys include
    // the active token, and every successful write invalidates the whole cache.
    // Transaction-critical reads (checkout validation, order/payment/tracking
    // details and product details that increment views) remain uncached.
    if (ttl != null) {
      final cached = _getCache[cacheKey];
      if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
        return _copyJsonValue(cached.value);
      }
      if (cached != null) _getCache.remove(cacheKey);
    }

    // Coalesce duplicate GETs while the same request is already in flight.
    // This applies to private reads too, but the in-memory key includes the
    // active token so two accounts/roles can never share a response. Tokens
    // are not persisted or printed.
    final sortedQueryKeys = query.keys.toList()..sort();
    final normalizedQuery = <String, dynamic>{
      for (final key in sortedQueryKeys) key: query[key],
    };
    final requestKey = ttl != null
        ? 'cached:$cacheKey'
        : 'fresh:$path?${jsonEncode(normalizedQuery)}#${_token}';

    final existing = _inFlightGets[requestKey];
    if (existing != null) return _copyFutureValue(existing);

    final generationAtStart = _cacheGeneration;
    late final Future<dynamic> request;
    request = _send('GET', path, query: query)
        .then((value) {
          if (ttl != null && generationAtStart == _cacheGeneration) {
            _pruneCache();
            _getCache[cacheKey] = _CachedGet(
              _copyJsonValue(value),
              DateTime.now().add(ttl),
            );
          }
          return value;
        })
        .whenComplete(() {
          if (identical(_inFlightGets[requestKey], request)) {
            _inFlightGets.remove(requestKey);
          }
        });

    _inFlightGets[requestKey] = request;
    return _copyFutureValue(request);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final result = await _send('POST', path, body: body);
    invalidateCache();
    return result;
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final result = await _send('PUT', path, body: body);
    invalidateCache();
    return result;
  }

  Future<dynamic> delete(String path) async {
    final result = await _send('DELETE', path);
    invalidateCache();
    return result;
  }

  Duration? _cacheTtlFor(String path, Map<String, dynamic> query) {
    final normalized = path.split('?').first.trim();

    if (normalized == '/categories' || normalized == '/locations/states') {
      return normalized == '/categories' ? _categoriesTtl : _locationsTtl;
    }

    if (normalized == '/locations/cities' &&
        (query['stateCode']?.toString().trim().isNotEmpty ?? false)) {
      return _locationsTtl;
    }

    // Public marketplace discovery can be cached while browsing; checkout
    // always validates product availability and stock server-side.
    if (normalized == '/products') {
      return _publicDiscoveryTtl;
    }

    // Account-specific screens commonly reopen the same read-only snapshot.
    // These routes are deliberately whitelisted rather than caching every GET.
    // Order/payment/tracking and item-detail endpoints are intentionally absent.
    const privateSnapshotPaths = <String>{
      '/profile',
      '/auth/me',
      '/addresses',
      '/wishlist',
      '/cart',
      '/my/products',
      '/my/reviews',
      '/rewards',
      '/rewards/history',
      '/rewards/claims',
      '/eco-impact',
      '/notifications',
      '/settings',
      '/my/following',
      '/custom-services/mine',
      '/custom-services/artists',
      '/selling/earnings',
    };
    if (privateSnapshotPaths.contains(normalized)) {
      return _privateSnapshotTtl;
    }

    // Donation history is useful to reuse when revisiting the history screen;
    // create/update/pickup actions invalidate the cache through write methods.
    if (normalized == '/donations') {
      return _privateSnapshotTtl;
    }

    // Public seller summaries and review lists are read-only. A successful
    // review/product/follow write invalidates cached data globally.
    if (RegExp(
          r'^/public/seller/(user|artist|remaker|re_maker)/\d+/profile$',
        ).hasMatch(normalized) ||
        RegExp(r'^/artists/\d+/reviews$').hasMatch(normalized) ||
        RegExp(r'^/sellers/user/\d+/reviews$').hasMatch(normalized) ||
        RegExp(r'^/products/\d+/reviews$').hasMatch(normalized)) {
      return _publicDiscoveryTtl;
    }

    // Public portfolio LISTS are read-only discovery data. Reuse them briefly
    // when a user opens the same artist/product portfolio more than once.
    // Successful writes call invalidateCache(), so the artist's own list is
    // refreshed after create/edit/delete. Portfolio DETAIL is intentionally
    // excluded because its GET increments the view count on the backend.
    if (RegExp(r'^/artists/\d+/portfolio$').hasMatch(normalized) ||
        RegExp(r'^/products/\d+/portfolio$').hasMatch(normalized)) {
      return _publicDiscoveryTtl;
    }

    return null;
  }

  String _cacheKey(String path, Map<String, dynamic> query) {
    final sortedQuery = query.keys.toList()..sort();
    final normalizedQuery = <String, dynamic>{
      for (final key in sortedQuery) key: query[key],
    };
    final queryString = jsonEncode(normalizedQuery);
    final normalizedPath = path.split('?').first.trim();
    final isPrivateSnapshot = _isPrivateSnapshotPath(normalizedPath);

    // Private responses are isolated by the current session token in memory.
    // Tokens are never persisted or printed. Public reference data stays shared.
    return isPrivateSnapshot
        ? '$path?$queryString#${Prefs.getString('userRole').toLowerCase()}:$_token'
        : '$path?$queryString';
  }

  bool _isPrivateSnapshotPath(String path) {
    const paths = <String>{
      '/profile',
      '/auth/me',
      '/addresses',
      '/wishlist',
      '/cart',
      '/my/products',
      '/my/reviews',
      '/rewards',
      '/rewards/history',
      '/rewards/claims',
      '/eco-impact',
      '/notifications',
      '/settings',
      '/my/following',
      '/custom-services/mine',
      '/custom-services/artists',
      '/selling/earnings',
      '/donations',
    };
    return paths.contains(path);
  }

  void _pruneCache() {
    final now = DateTime.now();
    _getCache.removeWhere((_, entry) => !entry.expiresAt.isAfter(now));
    if (_getCache.length >= _maxCacheEntries) {
      // Map iteration order is insertion order; remove the oldest entries first.
      final removeCount = _getCache.length - _maxCacheEntries + 1;
      final keys = _getCache.keys.take(removeCount).toList();
      for (final key in keys) {
        _getCache.remove(key);
      }
    }
  }

  dynamic _copyJsonValue(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }

    try {
      return jsonDecode(jsonEncode(value));
    } catch (_) {
      return value;
    }
  }

  Future<dynamic> _copyFutureValue(Future<dynamic> future) async {
    return _copyJsonValue(await future);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
  }) async {
    final payload = <String, dynamic>{...body};

    if (method != 'GET') {
      if (_token.isNotEmpty) {
        payload['token'] = _token;
      }

      payload['_method'] = method;
    }

    final response = await ApiManager().dio.request<dynamic>(
      baseUrl,
      queryParameters: {
        'path': path,
        ...query,
        if ((method == 'GET' || method == 'DELETE') && _token.isNotEmpty)
          'token': _token,

        // Apps Script receives DELETE via doPost; pass method override in query
        // because DELETE requests intentionally have no request body here.
        if (method == 'DELETE') '_method': 'DELETE',
      },
      data: method == 'GET' || method == 'DELETE' ? null : payload,
      options: Options(method: method == 'GET' ? 'GET' : 'POST'),
    );

    dynamic raw = response.data;

    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }

    if (raw is! Map) {
      throw const EcoLoopApiException(
        'The backend did not return JSON. Check the Apps Script deployment URL and access permissions.',
      );
    }

    final ok =
        raw['success'] == true ||
        raw['success'].toString().toLowerCase() == 'true';

    if (!ok) {
      final err = raw['error'];
      final message = err is Map ? err['message']?.toString() : err?.toString();

      throw EcoLoopApiException(
        (message == null || message.isEmpty) ? 'Request failed.' : message,
      );
    }

    return raw['data'];
  }

  static int categoryId(String? label) {
    final value = (label ?? '').trim().toLowerCase();

    if (value.contains('furniture')) return 1;
    if (value.contains('decor') || value.contains('home')) return 2;
    if (value.contains('wood')) return 3;
    if (value.contains('glass')) return 4;

    if (value.contains('paper') ||
        value.contains('craft') ||
        value.contains('book')) {
      return 5;
    }

    if (value.contains('fashion') || value.contains('cloth')) {
      return 6;
    }

    if (value.contains('plant') || value.contains('garden')) {
      return 7;
    }

    return 8;
  }
}
