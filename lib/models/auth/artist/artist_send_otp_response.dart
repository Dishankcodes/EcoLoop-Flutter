class ArtistSendOtpData {
  final bool? sent;
  final String? expiresAt;

  ArtistSendOtpData({this.sent, this.expiresAt});

  factory ArtistSendOtpData.fromJson(dynamic json) {
    return ArtistSendOtpData(sent: json['sent'], expiresAt: json['expiresAt']);
  }

  Map<String, dynamic> toJson() {
    return {'sent': sent, 'expiresAt': expiresAt};
  }
}
