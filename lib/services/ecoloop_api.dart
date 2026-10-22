import 'dart:convert';

import 'package:dio/dio.dart';

import '../api/api_manager.dart';
import '../shared_preferences_util.dart';
import 'package:flutter/foundation.dart';
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
        : 'fresh:$path?${jsonEncode(normalizedQuery)}#$_token';

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

  /// Sends a message to the authenticated EcoLoop AI support endpoint.
  /// This is intentionally not routed through [post], because an AI chat
  /// request does not change marketplace data and should not clear GET caches.
  Future<Map<String, dynamic>> chatWithAi({
    required String message,
    List<Map<String, String>> history = const <Map<String, String>>[],
  }) async {
    debugPrint('[EcoLoop AI] Sending chat request.');

    try {
      final result = await _send(
        'POST',
        '/ai/chat',
        body: <String, dynamic>{'message': message, 'history': history},
      );

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);

        debugPrint('[EcoLoop AI] Response keys: ${response.keys.toList()}');
        debugPrint(
          '[EcoLoop AI] Reply received: '
          '${(response['reply']?.toString().isNotEmpty ?? false)}',
        );
        debugPrint(
          '[EcoLoop AI] Model: ${response['model'] ?? 'not provided'}',
        );

        return response;
      }

      debugPrint('[EcoLoop AI] Unexpected result type: ${result.runtimeType}');

      throw const EcoLoopApiException(
        'The AI response format was not recognised.',
      );
    } catch (error) {
      debugPrint('[EcoLoop AI] Chat request failed: ${error.runtimeType}');
      debugPrint('[EcoLoop AI] Error: $error');
      rethrow;
    }
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
    final normalizedMethod = method.trim().toUpperCase();
    const supportedMethods = <String>{'GET', 'POST', 'PUT', 'DELETE'};

    if (!supportedMethods.contains(normalizedMethod)) {
      throw EcoLoopApiException('Unsupported API method: $normalizedMethod');
    }

    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty || !normalizedPath.startsWith('/')) {
      throw const EcoLoopApiException(
        'Invalid API path. Paths must start with "/".',
      );
    }

    final isGet = normalizedMethod == 'GET';
    final payload = <String, dynamic>{...body};

    // Google Apps Script web apps expose doGet/doPost rather than general
    // HTTP PUT/DELETE handlers. Send every write through doPost and tell the
    // router the intended method in the JSON body. processRequest_ reads
    // body._method before the query-string override, so DELETE routes work
    // consistently without relying on a DELETE request body.
    if (!isGet) {
      final token = _token;
      if (token.isNotEmpty) payload['token'] = token;
      payload['_method'] = normalizedMethod;
    }

    final queryParameters = <String, dynamic>{
      ...query,
      // Keep the route and authentication values authoritative if a caller
      // accidentally supplies keys with the same names in `query`.
      'path': normalizedPath,
      if (isGet && _token.isNotEmpty) 'token': _token,
    };

    late final Response<dynamic> response;
    try {
      response = await ApiManager().dio.request<dynamic>(
        baseUrl,
        queryParameters: queryParameters,
        data: isGet ? null : payload,
        options: Options(
          // Apps Script supports doGet and doPost. PUT/DELETE are tunneled
          // through POST and dispatched by the _method override above.
          method: isGet ? 'GET' : 'POST',
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );
    } on DioException catch (error) {
      throw EcoLoopApiException(_dioErrorMessage(error));
    }

    dynamic raw = response.data;

    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } on FormatException {
        throw const EcoLoopApiException(
          'The backend returned a non-JSON response. Check the Apps Script deployment URL, permissions, and redirect handling.',
        );
      }
    }

    if (raw is! Map) {
      throw const EcoLoopApiException(
        'The backend returned an unexpected response. Check the Apps Script deployment URL and access permissions.',
      );
    }

    final successValue = raw['success'];
    final ok =
        successValue == true ||
        successValue?.toString().toLowerCase() == 'true';

    if (!ok) {
      final err = raw['error'];
      final message = err is Map ? err['message']?.toString() : err?.toString();

      throw EcoLoopApiException(
        (message == null || message.trim().isEmpty)
            ? 'The request failed. Please try again.'
            : message.trim(),
      );
    }

    return raw['data'];
  }

  String _dioErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    if (responseData is Map) {
      final err = responseData['error'];
      final message = err is Map ? err['message']?.toString() : err?.toString();

      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Check your internet connection and try again.';
      case DioExceptionType.sendTimeout:
        return 'The request took too long to send. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.transformTimeout:
        return 'The response took too long to process. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to EcoLoop. Check your internet connection.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'A secure connection to EcoLoop could not be established.';
      case DioExceptionType.badResponse:
        if (statusCode == 401 || statusCode == 403) {
          return 'Your session may have expired. Please log in again.';
        }
        if (statusCode == 404) {
          return 'The requested API endpoint was not found.';
        }
        if (statusCode != null && statusCode >= 500) {
          return 'EcoLoop server error. Please try again later.';
        }
        return statusCode == null
            ? 'The server returned an invalid response.'
            : 'Request failed (HTTP $statusCode).';
      case DioExceptionType.unknown:
        return 'A network error occurred. Please try again.';
    }
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
