class LoginRequest {
  final String email;
  final String password;
  final String? role;

  LoginRequest({required this.email, required this.password, this.role});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (role != null) 'role': role,
    };
  }

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString(),
    );
  }
}
