import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../widgets/app_message.dart';
import '../../../models/auth/user/forget_password/forgot_password_request.dart';
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

      if (response.success == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ForgotPasswordOtp(email: email)),
        );
      } else {
        _showMessage(
          title: 'Unable to send OTP',
          message: response.error ?? 'Unable to send OTP. Please try again.',
          type: AppMessageType.error,
        );
      }
    } catch (e) {
      _showMessage(
        title: 'Something went wrong',
        message: _getReadableError(e),
        type: AppMessageType.error,
      );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              const Icon(Icons.lock_reset, size: 70),

              const SizedBox(height: 24),

              const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                'Enter your registered email address and we will send you an OTP to reset your password.',
                style: TextStyle(fontSize: 15, height: 1.5),
              ),

              const SizedBox(height: 30),

              if (_message != null)
                AppMessage(
                  title: _messageTitle ?? '',
                  message: _message!,
                  type: _messageType ?? AppMessageType.error,
                  onClose: _clearMessage,
                ),

              if (_message != null) const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _clearMessage(),
                onSubmitted: (_) {
                  if (!_isLoading) {
                    _sendOtp();
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your registered email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
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

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Back to Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
