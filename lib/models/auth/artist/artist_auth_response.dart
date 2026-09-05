import '../../artist/artist_data.dart';

class ArtistAuthResponse {
  final bool? success;
  final ArtistAuthData? data;

  ArtistAuthResponse({this.success, this.data});

  factory ArtistAuthResponse.fromJson(dynamic json) {
    return ArtistAuthResponse(
      success: json['success'],
      data: json['data'] != null ? ArtistAuthData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'data': data?.toJson()};
  }
}

class ArtistAuthData {
  final String? token;
  final String? tokenType;
  final String? expiresAt;
  final String? role;
  final num? accountId;
  final ArtistData? account;

  ArtistAuthData({
    this.token,
    this.tokenType,
    this.expiresAt,
    this.role,
    this.accountId,
    this.account,
  });

  factory ArtistAuthData.fromJson(dynamic json) {
    return ArtistAuthData(
      token: json['token'],
      tokenType: json['tokenType'],
      expiresAt: json['expiresAt'],
      role: json['role'],
      accountId: json['accountId'],
      account: json['account'] != null
          ? ArtistData.fromJson(json['account'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tokenType': tokenType,
      'expiresAt': expiresAt,
      'role': role,
      'accountId': accountId,
      'account': account?.toJson(),
    };
  }
}
