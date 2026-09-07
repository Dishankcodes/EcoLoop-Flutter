class VerifyForgotPasswordOtpResponse {
  final bool verified;
  final String? resetToken;
  final String? expiresAt;

  VerifyForgotPasswordOtpResponse({
    required this.verified,
    this.resetToken,
    this.expiresAt,
  });

  factory VerifyForgotPasswordOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyForgotPasswordOtpResponse(
      verified: json['verified'] == true,
      resetToken: json['resetToken']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
    );
  }
}
