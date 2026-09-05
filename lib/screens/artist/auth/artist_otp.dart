import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
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
  ///
  /// Contains:
  /// userName
  /// email
  /// phone
  /// city
  /// state
  /// stateCode
  /// bio
  /// skills
  /// experience
  final Map<String, dynamic>? registrationData;

  @override
  State<ArtistOtpScreen> createState() => _ArtistOtpScreenState();
}

class _ArtistOtpScreenState extends State<ArtistOtpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _otpController = TextEditingController();

  bool _isVerifying = false;
  bool _isResending = false;

  int _secondsRemaining = 60;
  Timer? _timer;

  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // TIMER
  // ============================================================

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

  // ============================================================
  // VERIFY OTP
  // ============================================================

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

  // ============================================================
  // REGISTRATION OTP
  // ============================================================

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

  // ============================================================
  // LOGIN OTP
  // ============================================================

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

  // ============================================================
  // SAVE SESSION
  // ============================================================

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

  // ============================================================
  // RESEND OTP
  // ============================================================

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

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBackButton(),

                const SizedBox(height: 30),

                Center(
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Center(
                  child: Text(
                    widget.isRegistration
                        ? 'Verify Your Email'
                        : 'Verify Login',
                    style: AppTextStyles.heading,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: Text(
                    widget.isRegistration
                        ? 'We sent a verification code to'
                        : 'We sent a login code to',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 5),

                Center(
                  child: Text(
                    widget.email,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 35),

                Text(
                  'Enter OTP',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 10,
                  ),
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
                  decoration: const InputDecoration(
                    hintText: '------',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 15),

                if (_errorMessage != null)
                  _buildMessage(message: _errorMessage!, isError: true),

                if (_successMessage != null)
                  _buildMessage(message: _successMessage!, isError: false),

                const SizedBox(height: 10),

                Center(
                  child: Text(
                    _secondsRemaining > 0
                        ? 'Resend OTP in $_secondsRemaining seconds'
                        : "Didn't receive the OTP?",
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: TextButton(
                    onPressed:
                        (_secondsRemaining == 0 &&
                            !_isResending &&
                            !_isVerifying)
                        ? _resendOtp
                        : null,
                    child: _isResending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Resend OTP',
                            style: AppTextStyles.body.copyWith(
                              color: (_secondsRemaining == 0 && !_isVerifying)
                                  ? AppColors.primary
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.5,
                      ),
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
                            style: AppTextStyles.button,
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: _isVerifying || _isResending
                        ? null
                        : () => Navigator.pop(context),
                    child: Text(
                      'Change Email',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
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
  }

  Widget _buildMessage({required String message, required bool isError}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.withValues(alpha: 0.08)
            : Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError
              ? Colors.red.withValues(alpha: 0.25)
              : Colors.green.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 20,
            color: isError ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: isError ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
