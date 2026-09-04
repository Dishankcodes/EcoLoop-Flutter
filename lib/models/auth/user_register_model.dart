class RegisterUserRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String gender;
  final String address;
  final String city;
  final String state;
  final String password;

  final String? profilePhotoBase64;
  final String? profilePhotoFileName;
  final String? profilePhotoMimeType;

  RegisterUserRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.address,
    required this.city,
    required this.state,
    required this.password,
    this.profilePhotoBase64,
    this.profilePhotoFileName,
    this.profilePhotoMimeType,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'address': address,
      'city': city,
      'state': state,
      'password': password,
      if (profilePhotoBase64 != null) 'profilePhotoBase64': profilePhotoBase64,
      if (profilePhotoFileName != null)
        'profilePhotoFileName': profilePhotoFileName,
      if (profilePhotoMimeType != null)
        'profilePhotoMimeType': profilePhotoMimeType,
    };
  }

  factory RegisterUserRequest.fromJson(Map<String, dynamic> json) {
    return RegisterUserRequest(
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      profilePhotoBase64: json['profilePhotoBase64']?.toString(),
      profilePhotoFileName: json['profilePhotoFileName']?.toString(),
      profilePhotoMimeType: json['profilePhotoMimeType']?.toString(),
    );
  }
}
