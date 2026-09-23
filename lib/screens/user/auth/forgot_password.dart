import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../models/auth/user/forget_password/forgot_password_request.dart';
import '../../../widgets/app_message.dart';
import '../../../widgets/more_menu.dart';
import 'forgot_password_otp.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;

  String? _messageTitle;
  String? _message;
  AppMessageType? _messageType;

  void _showMessage({
    required String title,
    required String message,
    required AppMessageType type,
  }) {
    if (!mounted) return;

    setState(() {
      _messageTitle = title;
      _message = message;
      _messageType = type;
    });
  }

  void _clearMessage() {
    if (!mounted) return;

    setState(() {
      _messageTitle = null;
      _message = null;
      _messageType = null;
    });
  }

  String _getReadableError(dynamic error) {
    final message = error.toString().toLowerCase();

    if (message.contains('socketexception') || message.contains('connection')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    if (message.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  Future<void> _sendOtp() async {
    _clearMessage();

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        title: 'Email required',
        message: 'Please enter your email address.',
        type: AppMessageType.error,
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage(
        title: 'Invalid email',
        message: 'Please enter a valid email address.',
        type: AppMessageType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiManager().client.forgotPassword(
        '/auth/forgot-password',
        ForgotPasswordRequest(email: email, role: 'user'),
      );

      if (!mounted) return;

      if (response.success == true &&
          response.data != null &&
          response.data!.sent == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ForgotPasswordOtp(email: email)),
        );
      } else {
        final errorMessage = (response.error ?? '').trim().toLowerCase();

        if (errorMessage.contains('email is not registered') ||
            errorMessage.contains('not registered')) {
          _showMessage(
            title: 'Email not registered',
            message:
                'This email is not registered. Please enter your registered email address.',
            type: AppMessageType.error,
          );
        } else {
          _showMessage(
            title: 'Unable to send OTP',
            message:
                response.error ??
                'Unable to send OTP. Please try again later or contact support.',
            type: AppMessageType.error,
          );
        }
      }
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('email is not registered') ||
          errorMessage.contains('not registered')) {
        _showMessage(
          title: 'Email not registered',
          message:
              'This email is not registered. Please enter your registered email address.',
          type: AppMessageType.error,
        );
      } else {
        _showMessage(
          title: 'Something went wrong',
          message: _getReadableError(e),
          type: AppMessageType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: const [MoreMenu()],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight - 32, // Adjust for vertical padding
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),

                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.10),
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 42,
                          color: primaryColor,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Forgot Password?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Enter your registered email address and we will send you an OTP code to reset your password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color:
                              theme.textTheme.bodyMedium?.color?.withOpacity(
                                0.7,
                              ) ??
                              Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 28),

                      if (_message != null) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppMessage(
                            title: _messageTitle ?? '',
                            message: _message!,
                            type: _messageType ?? AppMessageType.error,
                            onClose: _clearMessage,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (_message != null) _clearMessage();
                          setState(() {});
                        },
                        onFieldSubmitted: (_) {
                          if (!_isLoading) {
                            _sendOtp();
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'name@example.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          suffixIcon: _emailController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _emailController.clear();
                                    _clearMessage();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: theme.cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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
                              : const Text(
                                  'Send OTP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text(
                          'Back to Login',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      const Spacer(),

                      // FOOTER BRANDING
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'Small Actions, Big Impact.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: primaryColor.withOpacity(0.85),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@ecoloop',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
