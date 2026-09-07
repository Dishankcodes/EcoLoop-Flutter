import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api/api_manager.dart';
import '../../../widgets/app_message.dart';
import '../../../models/auth/user/forget_password/verify_forgot_password_otp_request.dart';
import 'reset_password.dart';

class ForgotPasswordOtp extends StatefulWidget {
  final String email;

  const ForgotPasswordOtp({super.key, required this.email});

  @override
  State<ForgotPasswordOtp> createState() => _ForgotPasswordOtpState();
}

class _ForgotPasswordOtpState extends State<ForgotPasswordOtp> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

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

  String get _otp {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _onOtpChanged(String value, int index) {
    _clearMessage();

    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

      if (digits.isEmpty) return;

      for (int i = 0; i < digits.length && index + i < 6; i++) {
        _otpControllers[index + i].text = digits[i];
      }

      final nextIndex = index + digits.length;

      if (nextIndex < 6) {
        _focusNodes[nextIndex].requestFocus();
      } else {
        _focusNodes[5].unfocus();
      }

      setState(() {});
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {});
  }

  void _onOtpKeyPressed(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].clear();
    }
  }

  Future<void> _verifyOtp() async {
    _clearMessage();

    final otp = _otp;

    if (otp.length != 6) {
      _showMessage(
        title: 'Invalid OTP',
        message: 'Please enter the complete 6-digit OTP.',
        type: AppMessageType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiManager().client.verifyForgotPasswordOtp(
        '/auth/verify-otp',
        VerifyForgotPasswordOtpRequest(
          email: widget.email,
          code: otp,
          purpose: 'forgot_password',
        ),
      );

      if (!mounted) return;

      if (response.success == true &&
          response.data != null &&
          response.data!.verified == true) {
        final resetToken = response.data!.resetToken;

        if (resetToken == null || resetToken.isEmpty) {
          _showMessage(
            title: 'Verification failed',
            message:
                'OTP was verified, but the password reset session could not be created. Please try again.',
            type: AppMessageType.error,
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ResetPassword(email: widget.email, resetToken: resetToken),
          ),
        );
      } else {
        _showMessage(
          title: 'Invalid OTP',
          message:
              response.error ??
              'The OTP you entered is invalid or has expired. Please try again.',
          type: AppMessageType.error,
        );
      }
    } catch (e) {
      _showMessage(
        title: 'Verification failed',
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

  String _getReadableError(dynamic error) {
    final message = error.toString().toLowerCase();

    if (message.contains('socketexception') || message.contains('connection')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    if (message.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }

    return 'Something went wrong while verifying the OTP. Please try again.';
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // OTP ICON
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.10),
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Text(
                'We have sent a 6-digit verification code to',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5),
              ),

              const SizedBox(height: 6),

              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 30),

              // MESSAGE
              if (_message != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppMessage(
                    title: _messageTitle ?? '',
                    message: _message!,
                    type: _messageType ?? AppMessageType.error,
                    onClose: _clearMessage,
                  ),
                ),

              if (_message != null) const SizedBox(height: 20),

              // OTP BOXES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 58,
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) {
                        _onOtpKeyPressed(event, index);
                      },
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _onOtpChanged(value, index);
                        },
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 30),

              // VERIFY BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // CHANGE EMAIL
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: const Text('Change Email'),
              ),

              const SizedBox(height: 10),

              // OTP EXPIRY INFO
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.info_outline, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'OTP is valid for 10 minutes',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
