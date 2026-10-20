import 'dart:async';
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

/// API wrapper for the EcoLoop Google Apps Script backend.
///
/// Optimizations:
/// - Caches only public/reference catalogue data for a short time.
/// - Shares identical concurrent GET requests.
/// - Clears cached data after successful write requests.
/// - Does not log or persist authentication tokens in this class.
class EcoLoopApi {
  static const String baseUrl =
      'https://script.google.com/macros/s/AKfycbzvHq06GwL_I8qH2IPyQP36dRlESN62PYF4Ak5WkRE2VjHL5a-tr0Yk_KEtSvU_ZL6IbQ/exec';

  EcoLoopApi._();

  static final EcoLoopApi instance = EcoLoopApi._();

  static const Duration _catalogueTtl = Duration(minutes: 5);
  static const Duration _locationTtl = Duration(minutes: 10);
  static const Duration _productsTtl = Duration(seconds: 15);

  static final Map<String, _CacheEntry> _cache = {};
  static final Map<String, Future<dynamic>> _inFlightGets = {};

  String get _token {
    final role = Prefs.getString('userRole').toLowerCase();
    return (role == 'artist'
            ? Prefs.getString('artistToken')
            : Prefs.getString('authToken'))
        .trim();
  }

  Future<dynamic> get(String path, {Map<String, dynamic> query = const {}}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) {
    return _send('POST', path, body: body);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> delete(String path) {
    return _send('DELETE', path);
  }

  Duration? _cacheDuration(String path) {
    final normalized = _normalizePath(path);

    if (normalized == '/categories') return _catalogueTtl;
    if (normalized == '/locations/states') return _locationTtl;
    if (normalized == '/locations/cities') return _locationTtl;
    if (normalized == '/products') return _productsTtl;

    // Do not cache profiles, orders, wishlist, analytics, followers,
    // notifications, or other account-specific responses.
    return null;
  }

  String _normalizePath(String path) {
    final value = path.trim();
    if (value.isEmpty) return '/';
    return value.startsWith('/') ? value : '/$value';
  }

  String _stableQuery(Map<String, dynamic> query) {
    final keys = query.keys.toList()..sort();
    final sorted = <String, dynamic>{};
    for (final key in keys) {
      sorted[key] = query[key];
    }
    return jsonEncode(sorted);
  }

  String _requestKey({
    required String path,
    required Map<String, dynamic> query,
    required String token,
  }) {
    // Token is used only as an in-memory partition so one account cannot
    // reuse another account's in-flight response. Never log this key.
    return '${_normalizePath(path)}|${_stableQuery(query)}|${token.hashCode}';
  }

  dynamic _copyJsonValue(dynamic value) {
    // Prevent callers from mutating objects held in the cache.
    try {
      return jsonDecode(jsonEncode(value));
    } catch (_) {
      return value;
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
  }) async {
    final normalizedPath = _normalizePath(path);
    final token = _token;
    final isGet = method == 'GET';
    final cacheDuration = isGet ? _cacheDuration(normalizedPath) : null;

    final requestKey = _requestKey(
      path: normalizedPath,
      query: query,
      token: token,
    );

    if (isGet && cacheDuration != null) {
      final cached = _cache[requestKey];
      if (cached != null &&
          DateTime.now().difference(cached.createdAt) < cacheDuration) {
        return _copyJsonValue(cached.value);
      }
    }

    if (isGet) {
      final existingRequest = _inFlightGets[requestKey];
      if (existingRequest != null) {
        final result = await existingRequest;
        return _copyJsonValue(result);
      }
    }

    final request = _performRequest(
      method: method,
      path: normalizedPath,
      body: body,
      query: query,
      token: token,
    );

    if (isGet) {
      _inFlightGets[requestKey] = request;
    }

    try {
      final result = await request;

      if (isGet && cacheDuration != null) {
        _cache[requestKey] = _CacheEntry(
          value: _copyJsonValue(result),
          createdAt: DateTime.now(),
        );
      }

      if (!isGet) {
        _invalidateAfterWrite(normalizedPath);
      }

      return _copyJsonValue(result);
    } finally {
      if (isGet && identical(_inFlightGets[requestKey], request)) {
        _inFlightGets.remove(requestKey);
      }
    }
  }

  Future<dynamic> _performRequest({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required Map<String, dynamic> query,
    required String token,
  }) async {
    final payload = <String, dynamic>{...body};

    if (method != 'GET') {
      if (token.isNotEmpty) payload['token'] = token;
      payload['_method'] = method;
    }

    final queryParameters = <String, dynamic>{
      'path': path,
      ...query,
      if ((method == 'GET' || method == 'DELETE') && token.isNotEmpty)
        'token': token,
      // Apps Script handles DELETE through doPost with a method override.
      if (method == 'DELETE') '_method': 'DELETE',
    };

    final response = await ApiManager().dio.request<dynamic>(
      baseUrl,
      queryParameters: queryParameters,
      data: method == 'GET' || method == 'DELETE' ? null : payload,
      options: Options(method: method == 'GET' ? 'GET' : 'POST'),
    );

    dynamic raw = response.data;

    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } on FormatException {
        throw const EcoLoopApiException(
          'The backend returned an unreadable response. '
          'Check the Apps Script deployment URL and access permissions.',
        );
      }
    }

    if (raw is! Map) {
      throw const EcoLoopApiException(
        'The backend did not return JSON. Check the Apps Script deployment '
        'URL and access permissions.',
      );
    }

    final successValue = raw['success'];
    final ok =
        successValue == true ||
        successValue?.toString().toLowerCase() == 'true';

    if (!ok) {
      final error = raw['error'];
      final message = error is Map
          ? error['message']?.toString()
          : error?.toString();

      throw EcoLoopApiException(
        (message == null || message.trim().isEmpty)
            ? 'Request failed.'
            : message,
      );
    }

    return raw['data'];
  }

  void _invalidateAfterWrite(String path) {
    final normalized = _normalizePath(path);

    // A product write can change the marketplace listing.
    if (normalized == '/products' || normalized.startsWith('/products/')) {
      _removeCachedPaths({'/products', '/categories'});
      return;
    }

    if (normalized.startsWith('/categories')) {
      _removeCachedPaths({'/categories'});
      return;
    }

    if (normalized.startsWith('/locations/')) {
      _removeCachedPaths({'/locations/states', '/locations/cities'});
    }
  }

  void _removeCachedPaths(Set<String> paths) {
    _cache.removeWhere((key, _) {
      final cachedPath = key.split('|').first;
      return paths.contains(cachedPath);
    });
  }

  /// Call this after changing accounts or roles if your app changes session
  /// without restarting. It clears only in-memory API cache entries.
  void clearCache() {
    _cache.clear();
  }
}

class _CacheEntry {
  final dynamic value;
  final DateTime createdAt;

  const _CacheEntry({required this.value, required this.createdAt});
}
