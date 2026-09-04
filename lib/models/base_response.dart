class BaseResponse<T> {
  final bool? success;
  final T? data;
  final String? error;

  BaseResponse({this.success, this.data, this.error});

  factory BaseResponse.fromJson(
    Map<String, dynamic>? json,
    T Function(Object? json) fromJsonT,
  ) {
    if (json == null) {
      return BaseResponse<T>(
        success: false,
        error: "Server returned an empty response.",
      );
    }

    String? errorMessage;
    if (json['error'] != null) {
      if (json['error'] is String) {
        errorMessage = json['error'] as String;
      } else if (json['error'] is Map) {
        errorMessage = json['error']['message']?.toString();
      }
    }

    return BaseResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: errorMessage,
    );
  }
}
