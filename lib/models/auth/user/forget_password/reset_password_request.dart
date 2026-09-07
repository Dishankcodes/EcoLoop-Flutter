class ResetPasswordRequest {
  final String email;
  final String resetToken;
  final String newPassword;
  final String role;

  ResetPasswordRequest({
    required this.email,
    required this.resetToken,
    required this.newPassword,
    this.role = 'user',
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'resetToken': resetToken,
      'newPassword': newPassword,
      'role': role,
    };
  }
}
