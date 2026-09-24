import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../app_theme/artist/artist_theme.dart';
import '../../../models/auth/artist/artist_auth_response.dart';
import '../../../models/auth/artist/artist_login_verify_otp_request.dart';
import '../../../models/auth/artist/artist_register_verify_otp_request.dart';
import '../../../models/auth/artist/artist_send_otp_request.dart';
import '../../../shared_preferences_util.dart';
import '../../../widgets/back_button.dart';
import '../artist_dashboard.dart';

class ArtistOtpScreen extends StatefulWidget {
  const ArtistOtpScreen({
    super.key,
    required this.email,
    required this.isRegistration,
    this.registrationData,
  });

  final String email;
  final bool isRegistration;

  /// Used only during registration.
  /// Contains: userName, email, phone, city, state, stateCode, bio, skills, experience
  final Map<String, dynamic>? registrationData;

  @override
  State<ArtistOtpScreen> createState() => _ArtistOtpScreenState();
}

class _ArtistOtpScreenState extends State<ArtistOtpScreen> {
  // Form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();

  // State
  bool _isVerifying = false;
  bool _isResending = false;
  int _secondsRemaining = 60;
  Timer? _timer;
  String? _errorMessage;
  String? _successMessage;

  // Init
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // Dispose
  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  // Timer
  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  // Verify OTP
  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final otp = _otpController.text.trim();

    setState(() {
      _isVerifying = true;
    });

    try {
      if (widget.isRegistration) {
        await _verifyRegistrationOtp(otp);
      } else {
        await _verifyLoginOtp(otp);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // Registration OTP
  Future<void> _verifyRegistrationOtp(String otp) async {
    final data = widget.registrationData;

    if (data == null) {
      throw Exception(
        'Registration information is missing. Please go back and try again.',
      );
    }

    final request = ArtistRegisterVerifyOtpRequest(
      userName: data['userName'].toString(),
      email: data['email'].toString(),
      phone: data['phone'].toString(),
      city: data['city'].toString(),
      state: data['state'].toString(),
      stateCode: data['stateCode'].toString(),
      bio: data['bio'].toString(),
      skills: data['skills'].toString(),
      experience: data['experience'].toString(),
      otp: otp,
    );

    final response = await ApiManager().client.artistRegisterVerifyOtp(
      '/auth/artist/register/verify-otp',
      request,
    );

    if (response.success != true || response.data == null) {
      throw Exception(
        response.error ?? 'Unable to create your artist account.',
      );
    }

    await _saveArtistSession(response.data!);

    if (!mounted) return;

    setState(() {
      _successMessage = 'Account created successfully! Welcome to EcoLoop.';
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ArtistDashboard()),
      (route) => false,
    );
  }

  // Login OTP
  Future<void> _verifyLoginOtp(String otp) async {
    final request = ArtistLoginVerifyOtpRequest(email: widget.email, otp: otp);

    final response = await ApiManager().client.artistLoginVerifyOtp(
      '/auth/artist/login/verify-otp',
      request,
    );

    if (response.success != true || response.data == null) {
      throw Exception(response.error ?? 'Unable to login. Please try again.');
    }

    await _saveArtistSession(response.data!);

    if (!mounted) return;

    setState(() {
      _successMessage = 'Login successful! Welcome back.';
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ArtistDashboard()),
      (route) => false,
    );
  }

  // Save Session
  Future<void> _saveArtistSession(ArtistAuthResponse auth) async {
    await Prefs.setBool('isLoggedIn', true);
    await Prefs.setString('userRole', 'artist');

    if (auth.token != null) {
      await Prefs.setString('artistToken', auth.token!);
    }

    if (auth.tokenType != null) {
      await Prefs.setString('artistTokenType', auth.tokenType!);
    }

    if (auth.expiresAt != null) {
      await Prefs.setString('artistTokenExpiresAt', auth.expiresAt!);
    }

    if (auth.role != null) {
      await Prefs.setString('artistRole', auth.role!);
    }

    if (auth.accountId != null) {
      await Prefs.setInt('artistId', auth.accountId!.toInt());
    }

    final artist = auth.account;

    if (artist != null) {
      if (artist.userName != null) {
        await Prefs.setString('artistName', artist.userName!);
      }

      if (artist.email != null) {
        await Prefs.setString('artistEmail', artist.email!);
      }

      if (artist.phone != null) {
        await Prefs.setString('artistPhone', artist.phone!);
      }

      await Prefs.setObject('artistData', artist.toJson());
    }
  }

  // Resend OTP
  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0 || _isResending || _isVerifying) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isResending = true;
    });

    try {
      final request = ArtistSendOtpRequest(email: widget.email);

      final response = widget.isRegistration
          ? await ApiManager().client.artistRegisterSendOtp(
              '/auth/artist/register/send-otp',
              request,
            )
          : await ApiManager().client.artistLoginSendOtp(
              '/auth/artist/login/send-otp',
              request,
            );

      if (response.success != true || response.data?.sent != true) {
        throw Exception(response.error ?? 'Unable to resend OTP.');
      }

      if (!mounted) return;

      setState(() {
        _successMessage = 'A new OTP has been sent to your email.';
      });

      _startTimer();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // Error Message
  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ArtistTheme.lightTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: ArtistColors.background,
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      const AppBackButton(),
                      const SizedBox(height: 30),

                      // OTP Icon
                      Center(
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: ArtistColors.primary.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            size: 42,
                            color: ArtistColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Title
                      Center(
                        child: Text(
                          widget.isRegistration
                              ? 'Verify Your Email'
                              : 'Verify Login',
                          style: ArtistTextStyles.heading,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Center(
                        child: Text(
                          widget.isRegistration
                              ? 'We sent a verification code to'
                              : 'We sent a login code to',
                          style: ArtistTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Email
                      Center(
                        child: Text(
                          widget.email,
                          style: ArtistTextStyles.body.copyWith(
                            color: ArtistColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 35),

                      // Enter OTP Label
                      Text(
                        'Enter OTP',
                        style: ArtistTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ArtistColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // OTP Field
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        enabled: !_isVerifying,
                        style: GoogleFontsHelper.otpStyle,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the OTP';
                          }

                          if (value.trim().length != 6) {
                            return 'OTP must be 6 digits';
                          }

                          if (!RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) {
                            return 'Please enter a valid OTP';
                          }

                          return null;
                        },
                        onChanged: (_) {
                          if (_errorMessage != null ||
                              _successMessage != null) {
                            setState(() {
                              _errorMessage = null;
                              _successMessage = null;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: '------',
                          counterText: '',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Error Message
                      if (_errorMessage != null)
                        _buildMessage(message: _errorMessage!, isError: true),

                      // Success Message
                      if (_successMessage != null)
                        _buildMessage(
                          message: _successMessage!,
                          isError: false,
                        ),
                      const SizedBox(height: 10),

                      // Timer
                      Center(
                        child: Text(
                          _secondsRemaining > 0
                              ? 'Resend OTP in $_secondsRemaining seconds'
                              : "Didn't receive the OTP?",
                          style: ArtistTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Resend OTP Button
                      Center(
                        child: TextButton(
                          onPressed:
                              (_secondsRemaining == 0 &&
                                  !_isResending &&
                                  !_isVerifying)
                              ? _resendOtp
                              : null,
                          style: TextButton.styleFrom(
                            foregroundColor: ArtistColors.primary,
                          ),
                          child: _isResending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ArtistColors.primary,
                                  ),
                                )
                              : Text(
                                  'Resend OTP',
                                  style: ArtistTextStyles.body.copyWith(
                                    color:
                                        (_secondsRemaining == 0 &&
                                            !_isVerifying)
                                        ? ArtistColors.primary
                                        : ArtistColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ArtistColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: ArtistColors.primary
                                .withOpacity(0.5),
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.isRegistration
                                      ? 'Verify & Create Account'
                                      : 'Verify & Login',
                                  style: ArtistTextStyles.button,
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Change Email Button
                      Center(
                        child: TextButton(
                          onPressed: _isVerifying || _isResending
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: ArtistColors.primary,
                          ),
                          child: Text(
                            'Change Email',
                            style: ArtistTextStyles.body.copyWith(
                              color: ArtistColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Message Box
  Widget _buildMessage({required String message, required bool isError}) {
    final Color color = isError ? ArtistColors.error : ArtistColors.success;
    final Color background = isError
        ? const Color(0xFFFDECEC)
        : const Color(0xFFEAF4EE);
    final IconData icon = isError
        ? Icons.error_outline
        : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: ArtistTextStyles.caption.copyWith(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GoogleFontsHelper {
  GoogleFontsHelper._();

  static const TextStyle otpStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 10,
    color: ArtistColors.textPrimary,
  );
}
