class ForgotPasswordRequest {
  final String email;
  final String role;

  ForgotPasswordRequest({required this.email, this.role = 'user'});

  Map<String, dynamic> toJson() {
    return {'email': email, 'role': role};
  }
}
