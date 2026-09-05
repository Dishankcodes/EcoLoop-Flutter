class ArtistSendOtpRequest {
  final String email;

  ArtistSendOtpRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}
