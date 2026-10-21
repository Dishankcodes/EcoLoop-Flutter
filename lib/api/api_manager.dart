import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'client.dart';

class ApiManager {
  ApiManager._internal() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 90),
        responseType: ResponseType.json,
        followRedirects: false,
        maxRedirects: 0,
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

          final isRedirect =
              status == 301 ||
              status == 302 ||
              status == 303 ||
              status == 307 ||
              status == 308;

          if (!isRedirect) {
            handler.next(response);
            return;
          }

          final location = response.headers.value('location');

          if (location == null || location.trim().isEmpty) {
            debugPrint(
              '[EcoLoop API] Redirect failed: '
              'Location header is missing.',
            );

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
            final redirectUri = response.requestOptions.uri.resolve(
              location.trim(),
            );

            if (!redirectUri.hasScheme ||
                (redirectUri.scheme != 'https' &&
                    redirectUri.scheme != 'http')) {
              throw const FormatException(
                'The redirect URL has an unsupported scheme.',
              );
            }

            if (kDebugMode) {
              debugPrint(
                '[EcoLoop API] Following redirect to '
                '${_safeUrl(redirectUri)}',
              );
            }

            final redirectedResponse = await dio.get<dynamic>(
              redirectUri.toString(),
              options: Options(
                responseType: ResponseType.json,
                followRedirects: true,
                maxRedirects: 5,
                receiveTimeout: const Duration(seconds: 90),
                extra: const {'appsScriptRedirect': true},
              ),
            );

            if (kDebugMode) {
              debugPrint(
                '[EcoLoop API] Redirect response: '
                '${redirectedResponse.statusCode} '
                '${_safeUrl(redirectedResponse.requestOptions.uri)}',
              );
            }

            handler.resolve(redirectedResponse);
          } on DioException catch (error) {
            if (kDebugMode) {
              debugPrint(
                '[EcoLoop API] Redirect request failed: '
                '${error.type}',
              );
              debugPrint(
                '[EcoLoop API] Redirect HTTP status: '
                '${error.response?.statusCode ?? 'N/A'}',
              );
              debugPrint(
                '[EcoLoop API] Redirect error: '
                '${error.message ?? 'No additional details'}',
              );
            }

            handler.reject(error);
          } catch (error) {
            if (kDebugMode) {
              debugPrint(
                '[EcoLoop API] Redirect handling failed: '
                '$error',
              );
            }

            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.unknown,
                message: 'Unable to follow Apps Script redirect.',
                error: error,
              ),
            );
          }
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('[EcoLoop API] Error type: ${error.type}');
            debugPrint(
              '[EcoLoop API] Request: '
              '${error.requestOptions.method} '
              '${_safeUrl(error.requestOptions.uri)}',
            );
            debugPrint(
              '[EcoLoop API] HTTP status: '
              '${error.response?.statusCode ?? 'N/A'}',
            );
            debugPrint(
              '[EcoLoop API] Error message: '
              '${error.message ?? 'No additional details'}',
            );

            if (error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.sendTimeout) {
              debugPrint(
                '[EcoLoop API] Request timed out. '
                'Check network connectivity and backend response time.',
              );
            } else if (error.type == DioExceptionType.connectionError) {
              debugPrint(
                '[EcoLoop API] Connection failed. '
                'Check internet access and DNS resolution.',
              );
            }

            final data = error.response?.data;

            if (data != null) {
              final preview = data.toString();
              debugPrint(
                '[EcoLoop API] Error response preview: '
                '${preview.length > 800 ? preview.substring(0, 800) : preview}',
              );
            }
          }

          handler.next(error);
        },
      ),
    );

    client = RestClient(dio);
  }

  static final ApiManager _instance = ApiManager._internal();

  factory ApiManager() => _instance;

  late final Dio dio;
  late final RestClient client;

  String _safeUrl(Uri uri) {
    return '${uri.scheme}://${uri.host}${uri.path}';
  }
}
