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
class EcoLoopApi {
  static const String baseUrl = 'https://script.google.com/macros/s/AKfycbzvHq06GwL_I8qH2IPyQP36dRlESN62PYF4Ak5WkRE2VjHL5a-tr0Yk_KEtSvU_ZL6IbQ/exec';

  EcoLoopApi._();
  static final EcoLoopApi instance = EcoLoopApi._();

  String get _token => (Prefs.getString('userRole').toLowerCase() == 'artist' ? Prefs.getString('artistToken') : Prefs.getString('authToken')).trim();

  Future<dynamic> get(String path, {Map<String, dynamic> query = const {}}) async {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, Map<String, dynamic> body) async =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path) async => _send('DELETE', path);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic> body = const {},
    Map<String, dynamic> query = const {},
  }) async {
    final payload = <String, dynamic>{...body};
    if (method != 'GET') {
      if (_token.isNotEmpty) payload['token'] = _token;
      payload['_method'] = method;
    }
    final response = await ApiManager().dio.request<dynamic>(
      baseUrl,
      queryParameters: {'path': path, ...query, if (method == 'GET' && _token.isNotEmpty) 'token': _token},
      data: method == 'GET' || method == 'DELETE' ? null : payload,
      options: Options(method: method == 'GET' ? 'GET' : 'POST'),
    );
    dynamic raw = response.data;
    if (raw is String) {
      try { raw = jsonDecode(raw); } catch (_) {}
    }
    if (raw is! Map) {
      throw const EcoLoopApiException('The backend did not return JSON. Check the Apps Script deployment URL and access permissions.');
    }
    final ok = raw['success'] == true || raw['success'].toString().toLowerCase() == 'true';
    if (!ok) {
      final err = raw['error'];
      final message = err is Map ? err['message']?.toString() : err?.toString();
      throw EcoLoopApiException((message == null || message.isEmpty) ? 'Request failed.' : message);
    }
    return raw['data'];
  }

  static int categoryId(String? label) {
    final value = (label ?? '').trim().toLowerCase();
    if (value.contains('furniture')) return 1;
    if (value.contains('decor') || value.contains('home')) return 2;
    if (value.contains('wood')) return 3;
    if (value.contains('glass')) return 4;
    if (value.contains('paper') || value.contains('craft') || value.contains('book')) return 5;
    if (value.contains('fashion') || value.contains('cloth')) return 6;
    if (value.contains('plant') || value.contains('garden')) return 7;
    return 8;
  }
}
