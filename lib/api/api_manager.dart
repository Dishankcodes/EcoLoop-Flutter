import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'client.dart';

class ApiManager {
  static final ApiManager _instance = ApiManager._internal();

  factory ApiManager() => _instance;

  late final Dio dio;
  late final RestClient client;

  ApiManager._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),

        // Google Apps Script returns a 302 redirect.
        // We handle it manually in the interceptor.
        followRedirects: false,
        maxRedirects: 0,

        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,

        headers: {
          Headers.acceptHeader: Headers.jsonContentType,
          Headers.contentTypeHeader: Headers.jsonContentType,
        },

        // Allow 3xx responses to reach our interceptor.
        validateStatus: (status) {
          return status != null && status >= 200 && status < 400;
        },

        receiveDataWhenStatusError: true,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        // ------------------------------------------------------------
        // REQUEST
        // ------------------------------------------------------------
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint('');
            debugPrint('========== API REQUEST ==========');
            debugPrint('${options.method} ${options.uri}');

            // Do not print passwords/tokens.
            if (options.data != null) {
              final data = options.data;

              if (data is Map) {
                final safeData = Map<String, dynamic>.from(data);

                if (safeData.containsKey('password')) {
                  safeData['password'] = '********';
                }

                if (safeData.containsKey('token')) {
                  safeData['token'] = '********';
                }

                debugPrint('BODY: $safeData');
              } else {
                debugPrint('BODY: $data');
              }
            }

            debugPrint('=================================');
          }

          handler.next(options);
        },

        // ------------------------------------------------------------
        // RESPONSE
        // ------------------------------------------------------------
        onResponse: (response, handler) async {
          if (kDebugMode) {
            debugPrint('');
            debugPrint('========== API RESPONSE ==========');
            debugPrint('STATUS: ${response.statusCode}');
            debugPrint('URL: ${response.requestOptions.uri}');
            debugPrint('==================================');
          }

          // ----------------------------------------------------------
          // GOOGLE APPS SCRIPT 302 REDIRECT
          // ----------------------------------------------------------
          if (response.statusCode == 302) {
            final location = response.headers.value('location');

            if (kDebugMode) {
              debugPrint('');
              debugPrint('====== APPS SCRIPT REDIRECT ======');
              debugPrint('LOCATION: $location');
              debugPrint('==================================');
            }

            // No redirect URL.
            if (location == null || location.isEmpty) {
              return handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  error: 'Apps Script returned 302 without Location header.',
                ),
              );
            }

            try {
              // Apps Script has already processed the POST request.
              // The Location URL contains the generated response.
              final redirectedResponse = await dio.get(
                location,
                options: Options(
                  responseType: ResponseType.json,

                  // Do not automatically follow another redirect.
                  followRedirects: false,

                  validateStatus: (status) {
                    return status != null && status >= 200 && status < 400;
                  },

                  headers: {Headers.acceptHeader: Headers.jsonContentType},

                  // Used to identify this request as our redirect GET.
                  extra: {'appsScriptRedirect': true},
                ),
              );

              if (kDebugMode) {
                debugPrint('');
                debugPrint('======= REDIRECT RESPONSE =======');
                debugPrint('STATUS: ${redirectedResponse.statusCode}');
                debugPrint('URL: ${redirectedResponse.requestOptions.uri}');
                debugPrint('DATA: ${redirectedResponse.data}');
                debugPrint('=================================');
              }

              // --------------------------------------------------------
              // If Dio returned the JSON as a String, decode it.
              // --------------------------------------------------------
              if (redirectedResponse.data is String) {
                final raw = redirectedResponse.data as String;

                if (raw.trim().isNotEmpty) {
                  try {
                    redirectedResponse.data = jsonDecode(raw);
                  } catch (_) {
                    // Leave the original response untouched.
                  }
                }
              }

              // Give the final 200 response to Retrofit.
              return handler.resolve(redirectedResponse);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('');
                debugPrint('===== REDIRECT REQUEST FAILED =====');
                debugPrint('$e');
                debugPrint('====================================');
              }

              return handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  error: 'Failed to read Apps Script redirect.',
                ),
              );
            }
          }

          // ------------------------------------------------------------
          // NORMAL JSON RESPONSE
          // ------------------------------------------------------------
          if (response.data is String) {
            final raw = response.data as String;

            if (raw.trim().isNotEmpty) {
              try {
                response.data = jsonDecode(raw);
              } catch (_) {
                // Keep original response if it isn't valid JSON.
              }
            }
          }

          handler.next(response);
        },

        // ------------------------------------------------------------
        // ERROR
        // ------------------------------------------------------------
        onError: (DioException error, handler) {
          if (kDebugMode) {
            debugPrint('');
            debugPrint('============ API ERROR ============');
            debugPrint('TYPE: ${error.type}');
            debugPrint('MESSAGE: ${error.message}');
            debugPrint('URL: ${error.requestOptions.uri}');
            debugPrint('STATUS: ${error.response?.statusCode}');
            debugPrint('DATA: ${error.response?.data}');
            debugPrint('===================================');
          }

          handler.next(error);
        },
      ),
    );

    // Dio's normal logging interceptor.
    // Sensitive request/response bodies are disabled.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: false,
          responseHeader: false,
          responseBody: false,
        ),
      );
    }

    // Retrofit client.
    client = RestClient(dio);
  }
}
