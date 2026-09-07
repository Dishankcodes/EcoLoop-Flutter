import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../models/auth/user/forget_password/reset_password_request.dart';
import '../../../widgets/app_message.dart';

class ResetPassword extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPassword({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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

  Future<void> _resetPassword() async {
    _clearMessage();

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Only check whether password is entered.
    // No password length/format validation for now.
    if (password.isEmpty) {
      _showMessage(
        title: 'Password required',
        message: 'Please enter a new password.',
        type: AppMessageType.error,
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage(
        title: 'Confirm password',
        message: 'Please confirm your new password.',
        type: AppMessageType.error,
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        title: 'Passwords do not match',
        message: 'New password and confirm password must be the same.',
        type: AppMessageType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiManager().client.resetPassword(
        '/auth/reset-password',
        ResetPasswordRequest(
          email: widget.email,
          resetToken: widget.resetToken,
          newPassword: password,
          role: 'user',
        ),
      );

      if (!mounted) return;

      if (response.success == true &&
          response.data != null &&
          response.data!.passwordReset == true) {
        _showMessage(
          title: 'Password reset successful',
          message:
              'Your password has been changed successfully. Please login with your new password.',
          type: AppMessageType.success,
        );

        await Future.delayed(const Duration(milliseconds: 1200));

        if (!mounted) return;

        // Remove all forgot-password screens and return to Login.
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        _showMessage(
          title: 'Password reset failed',
          message:
              response.error ??
              'Unable to reset your password. Please try again.',
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ICON
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.10),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // TITLE
              const Center(
                child: Text(
                  'Create New Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              // DESCRIPTION
              const Center(
                child: Text(
                  'Your identity has been verified. Create a new password for your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
              ),

              const SizedBox(height: 30),

              // EMAIL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // MESSAGE
              if (_message != null)
                AppMessage(
                  title: _messageTitle ?? '',
                  message: _message!,
                  type: _messageType ?? AppMessageType.error,
                  onClose: _clearMessage,
                ),

              if (_message != null) const SizedBox(height: 20),

              // NEW PASSWORD
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _clearMessage(),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter your new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 18),

              // CONFIRM PASSWORD
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _clearMessage(),
                onSubmitted: (_) {
                  if (!_isLoading) {
                    _resetPassword();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 28),

              // RESET BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // BACK TO LOGIN
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.popUntil(context, (route) => route.isFirst);
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
