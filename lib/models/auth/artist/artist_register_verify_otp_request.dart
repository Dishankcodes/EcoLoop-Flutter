class ArtistRegisterVerifyOtpRequest {
  final String userName;
  final String email;
  final String phone;
  final String city;
  final String state;
  final String stateCode;
  final String bio;
  final String skills;
  final String experience;
  final String otp;

  ArtistRegisterVerifyOtpRequest({
    required this.userName,
    required this.email,
    required this.phone,
    required this.city,
    required this.state,
    required this.stateCode,
    required this.bio,
    required this.skills,
    required this.experience,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'email': email,
      'phone': phone,
      'city': city,
      'state': state,
      'stateCode': stateCode,
      'bio': bio,
      'skills': skills,
      'experience': experience,
      'otp': otp,
    };
  }
}
