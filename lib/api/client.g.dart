// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main,avoid_redundant_argument_values

class _RestClient implements RestClient {
  _RestClient(this._dio, {this.baseUrl, this.errorLogger}) {
    baseUrl ??=
        'https://script.google.com/macros/s/AKfycbzvHq06GwL_I8qH2IPyQP36dRlESN62PYF4Ak5WkRE2VjHL5a-tr0Yk_KEtSvU_ZL6IbQ/exec';
  }

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<BaseResponse<UserData>> loginUser(
    String path,
    Map<String, dynamic> request,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'path': path};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(request);
    final _options = _setStreamType<BaseResponse<UserData>>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BaseResponse<UserData> _value;
    try {
      _value = BaseResponse<UserData>.fromJson(
        _result.data!,
        (json) => UserData.fromJson(json as Map<String, dynamic>),
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<BaseResponse<UserData>> registerUser(
    String path,
    Map<String, dynamic> request,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'path': path};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(request);
    final _options = _setStreamType<BaseResponse<UserData>>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BaseResponse<UserData> _value;
    try {
      _value = BaseResponse<UserData>.fromJson(
        _result.data!,
        (json) => UserData.fromJson(json as Map<String, dynamic>),
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<BaseResponse<List<StateModel>>> getStates(String path) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'path': path};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<BaseResponse<List<StateModel>>>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BaseResponse<List<StateModel>> _value;
    try {
      _value = BaseResponse<List<StateModel>>.fromJson(
        _result.data!,
        (json) => json is List<dynamic>
            ? json
                  .map<StateModel>(
                    (i) => StateModel.fromJson(i as Map<String, dynamic>),
                  )
                  .toList()
            : List.empty(),
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<BaseResponse<List<CityModel>>> getCities(
    String path,
    String stateCode,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'path': path,
      r'stateCode': stateCode,
    };
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<BaseResponse<List<CityModel>>>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BaseResponse<List<CityModel>> _value;
    try {
      _value = BaseResponse<List<CityModel>>.fromJson(
        _result.data!,
        (json) => json is List<dynamic>
            ? json
                  .map<CityModel>(
                    (i) => CityModel.fromJson(i as Map<String, dynamic>),
                  )
                  .toList()
            : List.empty(),
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<BaseResponse<ArtistSendOtpData>> artistRegisterSendOtp(
    String path,
    ArtistSendOtpRequest request,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'path': path};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(request.toJson());
    final _options = _setStreamType<BaseResponse<ArtistSendOtpData>>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BaseResponse<ArtistSendOtpData> _value;
    try {
      _value = BaseResponse<ArtistSendOtpData>.fromJson(
        _result.data!,
        (json) => ArtistSendOtpData.fromJson(json as Map<String, dynamic>),
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<BaseResponse<ArtistAuthResponse>> artistRegisterVerifyOtp(
    String path,
    ArtistRegisterVerifyOtpRequest request,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'path': path};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(request.toJson());
    final _options = _setStreamType<BaseResponse<ArtistAuthResponse>>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BaseResponse<ArtistAuthResponse> _value;
    try {
      _value = BaseResponse<ArtistAuthResponse>.fromJson(
        _result.data!,
        (json) => ArtistAuthResponse.fromJson(json as Map<String, dynamic>),
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<BaseResponse<ArtistSendOtpData>> artistLoginSendOtp(
    String path,
    ArtistSendOtpRequest request,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'path': path};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(request.toJson());
    final _options = _setStreamType<BaseResponse<ArtistSendOtpData>>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BaseResponse<ArtistSendOtpData> _value;
    try {
      _value = BaseResponse<ArtistSendOtpData>.fromJson(
        _result.data!,
        (json) => ArtistSendOtpData.fromJson(json as Map<String, dynamic>),
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<BaseResponse<ArtistAuthResponse>> artistLoginVerifyOtp(
    String path,
    ArtistLoginVerifyOtpRequest request,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'path': path};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(request.toJson());
    final _options = _setStreamType<BaseResponse<ArtistAuthResponse>>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late BaseResponse<ArtistAuthResponse> _value;
    try {
      _value = BaseResponse<ArtistAuthResponse>.fromJson(
        _result.data!,
        (json) => ArtistAuthResponse.fromJson(json as Map<String, dynamic>),
      );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}

// dart format on
