class VerifyForgotPasswordOtpRequest {
  final String email;
  final String code;
  final String purpose;

  VerifyForgotPasswordOtpRequest({
    required this.email,
    required this.code,
    this.purpose = 'forgot_password',
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'code': code, 'purpose': purpose};
  }
}
