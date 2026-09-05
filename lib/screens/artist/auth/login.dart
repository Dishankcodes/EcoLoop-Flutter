import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
import '../../../models/auth/artist/artist_send_otp_request.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/more_menu.dart';
import 'artist_otp.dart';
import 'register.dart';

class ArtistLogin extends StatefulWidget {
  final String title;

  const ArtistLogin({super.key, this.title = 'Artist Login'});

  @override
  State<ArtistLogin> createState() => _ArtistLoginState();
}

class _ArtistLoginState extends State<ArtistLogin> {
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;

  String? _errorMessage;
  String? _successMessage;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND LOGIN OTP
  // ============================================================

  Future<void> _sendLoginOtp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address.';
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiManager().client.artistLoginSendOtp(
        '/auth/artist/login/send-otp',
        ArtistSendOtpRequest(email: email),
      );

      if (!mounted) return;

      // ========================================================
      // ARTIST EXISTS → OTP SENT
      // ========================================================

      if (response.success == true && response.data?.sent == true) {
        setState(() {
          _successMessage = 'OTP sent successfully to $email.';
        });

        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ArtistOtpScreen(email: email, isRegistration: false),
          ),
        );

        return;
      }

      // ========================================================
      // BACKEND RETURNED AN ERROR
      // ========================================================

      setState(() {
        _errorMessage =
            response.error ??
            "You don't have an artist account. "
                "Please create an account first.";
      });
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _getDioErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _getGeneralErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
  }

  // ============================================================
  // DIO ERROR MESSAGE
  // ============================================================

  String _getDioErrorMessage(DioException error) {
    final responseData = error.response?.data;

    // ----------------------------------------------------------
    // Backend response
    // ----------------------------------------------------------

    if (responseData is Map) {
      final backendError = responseData['error'];

      // Example:
      //
      // "error": "You don't have an artist account..."
      //

      if (backendError is String && backendError.trim().isNotEmpty) {
        return backendError.trim();
      }

      // Example:
      //
      // "error": {
      //   "message": "..."
      // }
      //

      if (backendError is Map) {
        final message = backendError['message']?.toString();

        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }

      // Some APIs may return message directly.

      final directMessage = responseData['message']?.toString();

      if (directMessage != null && directMessage.trim().isNotEmpty) {
        return directMessage.trim();
      }
    }

    // ----------------------------------------------------------
    // Network
    // ----------------------------------------------------------

    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. '
          'Please check your network.';
    }

    // ----------------------------------------------------------
    // Timeout
    // ----------------------------------------------------------

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The request timed out. '
          'Please try again.';
    }

    // ----------------------------------------------------------
    // Server error
    // ----------------------------------------------------------

    if (error.response?.statusCode != null) {
      final statusCode = error.response!.statusCode!;

      if (statusCode == 404) {
        return "You don't have an artist account. "
            "Please create an account first.";
      }

      if (statusCode == 403) {
        return 'Your artist account is not active. '
            'Please contact support.';
      }

      if (statusCode >= 500) {
        return 'Server error. '
            'Please try again later.';
      }
    }

    return 'Unable to connect to the server. '
        'Please try again.';
  }

  // ============================================================
  // GENERAL ERROR MESSAGE
  // ============================================================

  String _getGeneralErrorMessage(dynamic error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'No internet connection. '
          'Please check your network.';
    }

    if (message.contains('TimeoutException')) {
      return 'The request timed out. '
          'Please try again.';
    }

    return 'Something went wrong. '
        'Please try again.';
  }

  // ============================================================
  // OPEN ARTIST REGISTRATION
  // ============================================================

  void _openRegistration() {
    if (_isLoading) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ArtistRegister(title: 'Artist Registration'),
      ),
    );
  }

  // ============================================================
  // DUMMY GOOGLE LOGIN
  // ============================================================

  void _continueWithGoogle() {
    if (_isLoading) return;

    setState(() {
      _errorMessage = null;
      _successMessage = 'Google sign-in will be available soon.';
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // TOP BAR
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                crossAxisAlignment: CrossAxisAlignment.center,

                children: const [AppBackButton(), MoreMenu()],
              ),

              const SizedBox(height: 30),

              // ==================================================
              // HEADER ICON
              // ==================================================
              Center(
                child: Container(
                  width: 86,
                  height: 86,

                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    Icons.palette_outlined,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // TITLE
              // ==================================================
              Center(
                child: Text(
                  'Welcome Back, Artist!',
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // SUBTITLE
              // ==================================================
              Center(
                child: Text(
                  'Login to manage your artwork and products.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 35),

              // ==================================================
              // ERROR MESSAGE
              // ==================================================
              if (_errorMessage != null) ...[
                _messageBox(message: _errorMessage!, isError: true),

                const SizedBox(height: 16),
              ],

              // ==================================================
              // SUCCESS MESSAGE
              // ==================================================
              if (_successMessage != null) ...[
                _messageBox(message: _successMessage!, isError: false),

                const SizedBox(height: 16),
              ],

              // ==================================================
              // EMAIL LABEL
              // ==================================================
              Text(
                'Email Address',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // EMAIL FIELD
              // ==================================================
              TextField(
                controller: _emailController,

                keyboardType: TextInputType.emailAddress,

                textInputAction: TextInputAction.done,

                enabled: !_isLoading,

                autocorrect: false,

                onChanged: (_) {
                  if (_errorMessage != null || _successMessage != null) {
                    setState(() {
                      _errorMessage = null;
                      _successMessage = null;
                    });
                  }
                },

                onSubmitted: (_) {
                  if (!_isLoading) {
                    _sendLoginOtp();
                  }
                },

                decoration: InputDecoration(
                  hintText: 'Enter your email address',

                  hintStyle: AppTextStyles.hint,

                  prefixIcon: const Icon(Icons.email_outlined),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),

                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),

                  filled: true,

                  fillColor: theme.colorScheme.surface,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SEND OTP BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,

                height: 54,

                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendLoginOtp,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,

                    foregroundColor: Colors.white,

                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.5,
                    ),

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text('Send OTP', style: AppTextStyles.button),
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // CREATE ACCOUNT
              // ==================================================
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,

                  crossAxisAlignment: WrapCrossAlignment.center,

                  children: [
                    Text(
                      "Don't have an artist account?",
                      style: AppTextStyles.body,
                    ),

                    TextButton(
                      onPressed: _isLoading ? null : _openRegistration,

                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                      ),

                      child: Text(
                        'Create Account',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // OR DIVIDER
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),

                    child: Text(
                      'OR',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // GOOGLE BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,

                height: 54,

                child: OutlinedButton(
                  onPressed: _isLoading ? null : _continueWithGoogle,

                  style: OutlinedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,

                    side: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.15,
                      ),
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      // GOOGLE LETTER
                      Container(
                        width: 22,
                        height: 22,

                        alignment: Alignment.center,

                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        'Continue with Google',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // SECURITY INFORMATION
              // ==================================================
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 15,

                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      'Secure OTP based login',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE BOX
  // ============================================================

  Widget _messageBox({required String message, required bool isError}) {
    final color = isError ? Colors.red.shade700 : Colors.green.shade700;

    final background = isError ? Colors.red.shade50 : Colors.green.shade50;

    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

      decoration: BoxDecoration(
        color: background,

        borderRadius: BorderRadius.circular(12),

        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, size: 20, color: color),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,

              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
