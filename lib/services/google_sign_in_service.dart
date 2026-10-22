import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignInService instance = GoogleSignInService._();

  static const String _webClientId =
      '97248436975-09t4342eugc0sdu6rh45psanple082n3.apps.googleusercontent.com';

  Future<void>? _initialization;

  Future<String?> getIdToken() async {
    await (_initialization ??= GoogleSignIn.instance.initialize(
      serverClientId: _webClientId,
    ));

    final account = await GoogleSignIn.instance.authenticate();
    return account.authentication.idToken;
  }
}
