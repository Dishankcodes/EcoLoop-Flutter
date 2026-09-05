import '../../artist/artist_data.dart';

class ArtistAuthResponse {
  final String? token;
  final String? tokenType;
  final String? expiresAt;
  final String? role;
  final num? accountId;
  final ArtistData? account;

  ArtistAuthResponse({
    this.token,
    this.tokenType,
    this.expiresAt,
    this.role,
    this.accountId,
    this.account,
  });

  factory ArtistAuthResponse.fromJson(dynamic json) {
    if (json == null) {
      return ArtistAuthResponse();
    }

    return ArtistAuthResponse(
      // Convert everything that should be a String safely.
      token: json['token']?.toString(),

      tokenType: json['tokenType']?.toString(),

      expiresAt: json['expiresAt']?.toString(),

      role: json['role']?.toString(),

      // Handle accountId whether Apps Script returns
      // an int, double, or numeric string.
      accountId: _parseNum(json['accountId']),

      account: json['account'] != null
          ? ArtistData.fromJson(json['account'])
          : null,
    );
  }

  static num? _parseNum(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value;
    }

    return num.tryParse(value.toString());
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
