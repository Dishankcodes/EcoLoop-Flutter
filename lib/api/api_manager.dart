import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'client.dart';

class ApiManager {
  ApiManager._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 25),
        responseType: ResponseType.json,

        // Google Apps Script often responds with a 302 redirect.
        // Handle it below so the response is available to Retrofit
        // and EcoLoopApi in the expected format.
        followRedirects: false,
        maxRedirects: 0,

        // Allow 302 through to the response interceptor.
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,

        headers: const {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint(
              '[EcoLoop API] ${options.method} '
              '${_safeUrl(options.uri)}',
            );
          }
          handler.next(options);
        },

        onResponse: (response, handler) async {
          final status = response.statusCode ?? 0;

          if (kDebugMode) {
            debugPrint(
              '[EcoLoop API] Response: $status '
              '${_safeUrl(response.requestOptions.uri)}',
            );
          }

          // Google Apps Script may redirect its response to
          // script.googleusercontent.com. Follow that redirect
          // manually to preserve predictable Dio/Retrofit behaviour.
          if (status == 301 ||
              status == 302 ||
              status == 303 ||
              status == 307 ||
              status == 308) {
            final location = response.headers.value('location');

            if (location == null || location.trim().isEmpty) {
              handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.badResponse,
                  message:
                      'Google Apps Script returned a redirect '
                      'without a Location header.',
                ),
              );
              return;
            }

            try {
              final redirectUri = response.requestOptions.uri.resolve(location);

              // Apps Script response redirects should be read using
              // GET. The redirect URL contains the response payload
              // reference; do not append the original query again.
              final redirectedResponse = await dio.get<dynamic>(
                redirectUri.toString(),
                options: Options(
                  responseType: ResponseType.json,
                  followRedirects: true,
                  maxRedirects: 5,
                  extra: const {'appsScriptRedirect': true},
                ),
              );

              handler.resolve(redirectedResponse);
              return;
            } on DioException catch (error) {
              handler.reject(error);
              return;
            } catch (error) {
              handler.reject(
                DioException(
                  requestOptions: response.requestOptions,
                  response: response,
                  type: DioExceptionType.unknown,
                  message: 'Unable to follow Apps Script redirect.',
                  error: error,
                ),
              );
              return;
            }
          }

          handler.next(response);
        },

        onError: (error, handler) {
          if (kDebugMode) {
            // Do not print the full URL, query parameters, request
            // body, or headers because they may contain auth tokens.
            debugPrint(
              '[EcoLoop API] Error: ${error.type} | '
              '${_safeUrl(error.requestOptions.uri)} | '
              'Status: ${error.response?.statusCode ?? 'N/A'}',
            );

            if (error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.sendTimeout) {
              debugPrint(
                '[EcoLoop API] Request timed out. '
                'Check network connectivity and Apps Script response time.',
              );
            } else if (error.type == DioExceptionType.connectionError) {
              debugPrint(
                '[EcoLoop API] Connection failed. '
                'Check internet access and DNS resolution.',
              );
            }
          }

          handler.next(error);
        },
      ),
    );

    // Keep the existing Retrofit client compatible.
    client = RestClient(dio);
  }

  static final ApiManager _instance = ApiManager._internal();

  factory ApiManager() => _instance;

  late final Dio dio;
  late final RestClient client;

  /// Produces a safe URL for logs without exposing query parameters.
  String _safeUrl(Uri uri) {
    return '${uri.scheme}://${uri.host}${uri.path}';
  }
}
