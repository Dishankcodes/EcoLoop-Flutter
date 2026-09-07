class ForgotPasswordResponse {
  final bool sent;
  final String? expiresAt;

  ForgotPasswordResponse({required this.sent, this.expiresAt});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      sent: json['sent'] == true,
      expiresAt: json['expiresAt']?.toString(),
    );
  }
}
