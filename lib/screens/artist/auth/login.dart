import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../app_theme/artist/artist_theme.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Send Login OTP
  Future<void> _sendLoginOtp() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text.trim();

    // Validate Email
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

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiManager().client.artistLoginSendOtp(
        '/auth/artist/login/send-otp',
        ArtistSendOtpRequest(email: email),
      );

      if (!mounted) return;

      // Success -> Open OTP
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

      // Normal API Error (Do Not Open OTP)
      final error = response.error?.trim();

      setState(() {
        _errorMessage = error != null && error.isNotEmpty
            ? error
            : "You don't have an artist account. Please create an account first.";
      });
    } on DioException catch (e) {
      if (!mounted) return;

      final statusCode = e.response?.statusCode;

      // Account Does Not Exist
      if (statusCode == 404) {
        setState(() {
          _errorMessage =
              "You don't have an artist account. Please create an account first.";
        });
        return;
      }

      // Account Exists But Not Active
      if (statusCode == 403) {
        setState(() {
          _errorMessage =
              'Your artist account is not active. Please contact support.';
        });
        return;
      }

      // Other Dio Error
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

  // Email Validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email);
  }

  // Dio Error Message
  String _getDioErrorMessage(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final backendError = responseData['error'];

      // error: "message"
      if (backendError is String && backendError.trim().isNotEmpty) {
        return backendError.trim();
      }

      // error: { message: "..." }
      if (backendError is Map) {
        final message = backendError['message']?.toString();

        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }

      // message: "..."
      final directMessage = responseData['message']?.toString();

      if (directMessage != null && directMessage.trim().isNotEmpty) {
        return directMessage.trim();
      }
    }

    // Connection Error
    if (error.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }

    // Timeout
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The request timed out. Please try again.';
    }

    // Server Error
    final statusCode = error.response?.statusCode;

    if (statusCode != null) {
      if (statusCode == 404) {
        return "You don't have an artist account. Please create an account first.";
      }

      if (statusCode == 403) {
        return 'Your artist account is not active. Please contact support.';
      }

      if (statusCode >= 500) {
        return 'Server error. Please try again later.';
      }
    }

    return 'Unable to connect to the server. Please try again.';
  }

  // General Error
  String _getGeneralErrorMessage(dynamic error) {
    final message = error.toString();

    if (message.contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    }

    if (message.contains('TimeoutException')) {
      return 'The request timed out. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  // Open Registration
  void _openRegistration() {
    if (_isLoading) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ArtistRegister(title: 'Artist Registration'),
      ),
    );
  }

  // Google Button
  void _continueWithGoogle() {
    if (_isLoading) return;

    setState(() {
      _errorMessage = null;
      _successMessage = 'Google sign-in will be available soon.';
    });
  }

  // Build
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ArtistTheme.lightTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: ArtistColors.background,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [AppBackButton(), MoreMenu()],
                    ),
                    const SizedBox(height: 30),

                    // Artist Icon
                    Center(
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: ArtistColors.primary.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          size: 42,
                          color: ArtistColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Title
                    Center(
                      child: Text(
                        'Welcome Back, Artist!',
                        style: ArtistTextStyles.heading,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    Center(
                      child: Text(
                        'Login to manage your artwork and products.',
                        style: ArtistTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Error Message
                    if (_errorMessage != null) ...[
                      _messageBox(message: _errorMessage!, isError: true),
                      const SizedBox(height: 16),

                      // Create Account
                      if (_isAccountNotFoundMessage(_errorMessage!)) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _openRegistration,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ArtistColors.primary,
                              side: const BorderSide(
                                color: ArtistColors.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Create Account',
                              style: ArtistTextStyles.body.copyWith(
                                color: ArtistColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ],

                    // Success Message
                    if (_successMessage != null) ...[
                      _messageBox(message: _successMessage!, isError: false),
                      const SizedBox(height: 16),
                    ],

                    // Email Label
                    Text(
                      'Email Address',
                      style: ArtistTextStyles.body.copyWith(
                        color: ArtistColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Email Field
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
                        hintStyle: ArtistTextStyles.hint,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: ArtistColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: ArtistColors.primary.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: ArtistColors.surface,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Send OTP Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendLoginOtp,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Send OTP'),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Register
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an artist account?",
                            style: ArtistTextStyles.body,
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : _openRegistration,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                            ),
                            child: Text(
                              'Create Account',
                              style: ArtistTextStyles.body.copyWith(
                                color: ArtistColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // OR Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: ArtistColors.border),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OR',
                            style: ArtistTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: ArtistColors.border),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Google Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _continueWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: ArtistColors.surface,
                          foregroundColor: ArtistColors.textPrimary,
                          minimumSize: const Size(double.infinity, 52),
                          side: const BorderSide(color: ArtistColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: ArtistColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Continue with Google',
                              style: ArtistTextStyles.body.copyWith(
                                color: ArtistColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Security Text
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 15,
                            color: ArtistColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Secure OTP based login',
                            style: ArtistTextStyles.caption,
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
        },
      ),
    );
  }

  // Account Not Found Check
  bool _isAccountNotFoundMessage(String message) {
    final text = message.toLowerCase();

    return text.contains("don't have an artist account") ||
        text.contains('artist account not found') ||
        text.contains('account not found');
  }

  // Message Box
  Widget _messageBox({required String message, required bool isError}) {
    final Color color = isError ? ArtistColors.error : ArtistColors.success;
    final Color background = isError
        ? const Color(0xFFFDECEC)
        : const Color(0xFFEAF4EE);
    final IconData icon = isError
        ? Icons.error_outline
        : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
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
