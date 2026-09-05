class ArtistSendOtpRequest {
  final String email;
  final String? phone;

  ArtistSendOtpRequest({required this.email, this.phone});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
    };
  }
}
