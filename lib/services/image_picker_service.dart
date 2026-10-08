import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../shared_preferences_util.dart';

class ImagePickerServiceException implements Exception {
  final String message;

  const ImagePickerServiceException(this.message);

  @override
  String toString() => message;
}

class ProfilePhotoUploadResult {
  final Uint8List bytes;
  final String profilePhotoUrl;
  final String fileName;
  final String mimeType;

  const ProfilePhotoUploadResult({
    required this.bytes,
    required this.profilePhotoUrl,
    required this.fileName,
    required this.mimeType,
  });
}

class ImagePickerService {
  ImagePickerService._();

  static final ImagePickerService instance = ImagePickerService._();

  final ImagePicker _imagePicker = ImagePicker();

  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbzvHq06GwL_I8qH2IPyQP36dRlESN62PYF4Ak5WkRE2VjHL5a-tr0Yk_KEtSvU_ZL6IbQ/exec';

  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _sendTimeout = Duration(seconds: 60);
  static const Duration _receiveTimeout = Duration(seconds: 60);

  static const int _maxImageSizeBytes = 5 * 1024 * 1024;

  Dio _createDio() {
    return Dio(
      BaseOptions(
        connectTimeout: _connectTimeout,
        sendTimeout: _sendTimeout,
        receiveTimeout: _receiveTimeout,
        responseType: ResponseType.json,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status >= 200 && status < 400;
        },
      ),
    );
  }

  Future<ProfilePhotoUploadResult?> pickAndUploadProfilePhoto({
    required ImageSource source,
  }) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      return null;
    }

    final Uint8List bytes = await pickedFile.readAsBytes();

    if (bytes.isEmpty) {
      throw const ImagePickerServiceException(
        'The selected image is empty. Please choose another image.',
      );
    }

    if (bytes.length > _maxImageSizeBytes) {
      throw const ImagePickerServiceException(
        'The selected image is larger than 5 MB. Please choose a smaller image.',
      );
    }

    final String fileName = _createFileName(pickedFile.name);
    final String mimeType = _getMimeType(fileName);
    final String base64Image = base64Encode(bytes);

    final String token = Prefs.getString('authToken').trim();

    if (token.isEmpty) {
      throw const ImagePickerServiceException(
        'Your login session has expired. Please login again.',
      );
    }

    return _uploadProfilePhoto(
      token: token,
      bytes: bytes,
      base64Image: base64Image,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<ProfilePhotoUploadResult> _uploadProfilePhoto({
    required String token,
    required Uint8List bytes,
    required String base64Image,
    required String fileName,
    required String mimeType,
  }) async {
    final Dio dio = _createDio();

    try {
      final Uri uri = Uri.parse(
        _baseUrl,
      ).replace(queryParameters: const {'path': '/profile/photo'});

      debugPrint('');
      debugPrint('==========================================');
      debugPrint('ECOLOOP PROFILE PHOTO UPLOAD');
      debugPrint('==========================================');
      debugPrint('POST $uri');
      debugPrint('File: $fileName');
      debugPrint('MIME: $mimeType');
      debugPrint('Bytes: ${bytes.length}');
      debugPrint('Base64 length: ${base64Image.length}');
      debugPrint('Token available: ${token.isNotEmpty}');
      debugPrint('==========================================');

      final Response<dynamic> response = await dio.post<dynamic>(
        uri.toString(),
        data: {
          'token': token,
          'base64': base64Image,
          'fileName': fileName,
          'mimeType': mimeType,
        },
        options: Options(followRedirects: false, maxRedirects: 0),
      );

      debugPrint('');
      debugPrint('========== PROFILE PHOTO RESPONSE ==========');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('URL: ${response.realUri}');
      debugPrint('DATA TYPE: ${response.data.runtimeType}');
      debugPrint('DATA: ${response.data}');
      debugPrint('============================================');

      dynamic responseData = response.data;

      if (_isRedirect(response.statusCode)) {
        final String? location = response.headers.value('location');

        if (location == null || location.trim().isEmpty) {
          throw const ImagePickerServiceException(
            'The upload server returned a redirect without a destination.',
          );
        }

        debugPrint('');
        debugPrint('========== APPS SCRIPT REDIRECT ==========');
        debugPrint('LOCATION: $location');
        debugPrint('==========================================');

        final Response<dynamic> redirectResponse = await dio.get<dynamic>(
          location,
          options: Options(
            followRedirects: false,
            maxRedirects: 0,
            responseType: ResponseType.json,
          ),
        );

        debugPrint('');
        debugPrint('========== REDIRECT RESPONSE ==========');
        debugPrint('STATUS: ${redirectResponse.statusCode}');
        debugPrint('URL: ${redirectResponse.realUri}');
        debugPrint('DATA: ${redirectResponse.data}');
        debugPrint('=======================================');

        responseData = redirectResponse.data;
      }

      return _parsePhotoResponse(
        responseData,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    } on DioException catch (error) {
      debugPrint('');
      debugPrint('========== PROFILE PHOTO DIO ERROR ==========');
      debugPrint('TYPE: ${error.type}');
      debugPrint('MESSAGE: ${error.message}');
      debugPrint('STATUS: ${error.response?.statusCode}');
      debugPrint('DATA: ${error.response?.data}');
      debugPrint('ERROR: ${error.error}');
      debugPrint('=============================================');

      throw ImagePickerServiceException(_readDioError(error));
    } on ImagePickerServiceException {
      rethrow;
    } catch (error) {
      debugPrint('PROFILE PHOTO ERROR: $error');

      throw const ImagePickerServiceException(
        'Unable to upload your profile photo. Please try again.',
      );
    } finally {
      dio.close(force: true);
    }
  }

  ProfilePhotoUploadResult _parsePhotoResponse(
    dynamic responseData, {
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    debugPrint('');
    debugPrint('========== PARSING PHOTO RESPONSE ==========');
    debugPrint('TYPE: ${responseData.runtimeType}');
    debugPrint('DATA: $responseData');
    debugPrint('============================================');

    if (responseData is! Map) {
      throw const ImagePickerServiceException(
        'The server returned an invalid upload response.',
      );
    }

    final dynamic successValue = responseData['success'];

    final bool success =
        successValue == true || successValue.toString().toLowerCase() == 'true';

    if (!success) {
      throw ImagePickerServiceException(
        _extractErrorMessage(responseData) ??
            'The server rejected the profile photo upload.',
      );
    }

    final dynamic dataValue = responseData['data'];

    if (dataValue is! Map) {
      throw const ImagePickerServiceException(
        'The server accepted the upload but returned invalid photo data.',
      );
    }

    final dynamic urlValue = dataValue['profilePhotoUrl'];

    final String profilePhotoUrl = urlValue?.toString().trim() ?? '';

    if (profilePhotoUrl.isEmpty) {
      throw const ImagePickerServiceException(
        'The server accepted the upload but did not return a profile photo URL.',
      );
    }

    final Uri? parsedUrl = Uri.tryParse(profilePhotoUrl);

    if (parsedUrl == null ||
        parsedUrl.host.isEmpty ||
        (parsedUrl.scheme != 'http' && parsedUrl.scheme != 'https')) {
      throw const ImagePickerServiceException(
        'The server returned an invalid profile photo URL.',
      );
    }

    debugPrint('');
    debugPrint('========== PHOTO UPLOAD SUCCESS ==========');
    debugPrint('PROFILE PHOTO URL: $profilePhotoUrl');
    debugPrint('==========================================');

    return ProfilePhotoUploadResult(
      bytes: bytes,
      profilePhotoUrl: profilePhotoUrl,
      fileName: fileName,
      mimeType: mimeType,
    );
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String city,
    required String state,
    String gender = '',
    String stateCode = '',
  }) async {
    final String token = Prefs.getString('authToken').trim();

    if (token.isEmpty) {
      throw const ImagePickerServiceException(
        'Your login session has expired. Please login again.',
      );
    }

    final Dio dio = _createDio();

    try {
      final Uri uri = Uri.parse(
        _baseUrl,
      ).replace(queryParameters: const {'path': '/profile'});

      final Map<String, dynamic> body = {
        'token': token,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
        'gender': gender.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'stateCode': stateCode.trim().toUpperCase(),
      };

      debugPrint('');
      debugPrint('==========================================');
      debugPrint('ECOLOOP PROFILE UPDATE');
      debugPrint('==========================================');
      debugPrint('PUT $uri');
      debugPrint('BODY: $body');
      debugPrint('==========================================');

      final Response<dynamic> response = await dio.put<dynamic>(
        uri.toString(),
        data: body,
        options: Options(followRedirects: false, maxRedirects: 0),
      );

      debugPrint('');
      debugPrint('========== PROFILE UPDATE RESPONSE ==========');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('DATA: ${response.data}');
      debugPrint('==============================================');

      dynamic responseData = response.data;

      if (_isRedirect(response.statusCode)) {
        final String? location = response.headers.value('location');

        if (location == null || location.trim().isEmpty) {
          throw const ImagePickerServiceException(
            'The profile update server returned a redirect without a destination.',
          );
        }

        final Response<dynamic> redirectResponse = await dio.get<dynamic>(
          location,
          options: Options(
            followRedirects: false,
            maxRedirects: 0,
            responseType: ResponseType.json,
          ),
        );

        responseData = redirectResponse.data;

        debugPrint('');
        debugPrint('========== PROFILE UPDATE REDIRECT ==========');
        debugPrint('STATUS: ${redirectResponse.statusCode}');
        debugPrint('DATA: $responseData');
        debugPrint('==============================================');
      }

      _validateSuccessfulResponse(
        responseData,
        defaultError: 'Unable to update your profile.',
      );
    } on DioException catch (error) {
      debugPrint('');
      debugPrint('========== PROFILE UPDATE DIO ERROR ==========');
      debugPrint('TYPE: ${error.type}');
      debugPrint('MESSAGE: ${error.message}');
      debugPrint('STATUS: ${error.response?.statusCode}');
      debugPrint('DATA: ${error.response?.data}');
      debugPrint('===============================================');

      throw ImagePickerServiceException(_readDioError(error));
    } on ImagePickerServiceException {
      rethrow;
    } catch (error) {
      debugPrint('PROFILE UPDATE ERROR: $error');

      throw const ImagePickerServiceException(
        'Unable to update your profile. Please try again.',
      );
    } finally {
      dio.close(force: true);
    }
  }

  void _validateSuccessfulResponse(
    dynamic responseData, {
    required String defaultError,
  }) {
    if (responseData is! Map) {
      throw ImagePickerServiceException(defaultError);
    }

    final dynamic successValue = responseData['success'];

    final bool success =
        successValue == true || successValue.toString().toLowerCase() == 'true';

    if (!success) {
      throw ImagePickerServiceException(
        _extractErrorMessage(responseData) ?? defaultError,
      );
    }
  }

  String? _extractErrorMessage(Map responseData) {
    final dynamic errorValue = responseData['error'];

    if (errorValue is Map) {
      final dynamic message = errorValue['message'];

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
    }

    if (errorValue != null && errorValue.toString().trim().isNotEmpty) {
      return errorValue.toString().trim();
    }

    final dynamic messageValue = responseData['message'];

    if (messageValue != null && messageValue.toString().trim().isNotEmpty) {
      return messageValue.toString().trim();
    }

    return null;
  }

  String _readDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Connection timed out. Please check your internet connection.';
    }

    if (error.type == DioExceptionType.sendTimeout) {
      return 'The photo took too long to upload. Please try again.';
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return 'The server took too long to respond. Please try again.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Unable to connect to EcoLoop. Please check your internet connection.';
    }

    final dynamic data = error.response?.data;

    if (data is Map) {
      final String? message = _extractErrorMessage(data);

      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    return 'Unable to process the request. Please try again.';
  }

  bool _isRedirect(int? statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  }

  String _createFileName(String originalName) {
    String name = originalName.trim();

    if (name.isEmpty) {
      name = 'profile_photo.jpg';
    }

    name = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    String extension = _getExtension(name);

    if (extension.isEmpty) {
      extension = 'jpg';
    }

    final int dotIndex = name.lastIndexOf('.');

    final String baseName = dotIndex > 0 ? name.substring(0, dotIndex) : name;

    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    return 'profile_${timestamp}_$baseName.$extension';
  }

  String _getExtension(String fileName) {
    final int dotIndex = fileName.lastIndexOf('.');

    if (dotIndex <= 0 || dotIndex == fileName.length - 1) {
      return '';
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  String _getMimeType(String fileName) {
    switch (_getExtension(fileName)) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      case 'heic':
      case 'heif':
        return 'image/heic';

      default:
        return 'image/jpeg';
    }
  }
}
