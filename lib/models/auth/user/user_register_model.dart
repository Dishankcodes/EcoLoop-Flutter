class RegisterUserRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String gender;
  final String city;
  final String state;
  final String stateCode;
  final String password;

  RegisterUserRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'city': city,
      'state': state,
      'stateCode': stateCode,
      'password': password,
    };
  }

  factory RegisterUserRequest.fromJson(Map<String, dynamic> json) {
    return RegisterUserRequest(
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      stateCode: json['stateCode']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
    );
  }
}
