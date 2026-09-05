class ArtistLoginVerifyOtpRequest {
  final String email;
  final String otp;

  ArtistLoginVerifyOtpRequest({required this.email, required this.otp});

  Map<String, dynamic> toJson() {
    return {'email': email, 'otp': otp};
  }
}
