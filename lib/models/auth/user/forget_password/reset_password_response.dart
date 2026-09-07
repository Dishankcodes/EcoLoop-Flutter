class ResetPasswordResponse {
  final bool passwordReset;

  ResetPasswordResponse({required this.passwordReset});

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(passwordReset: json['passwordReset'] == true);
  }
}
