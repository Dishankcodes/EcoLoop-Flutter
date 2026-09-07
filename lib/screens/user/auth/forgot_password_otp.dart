import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api/api_manager.dart';
import '../../../models/auth/user/forget_password/forgot_password_request.dart';
import '../../../models/auth/user/forget_password/verify_forgot_password_otp_request.dart';
import '../../../widgets/app_message.dart';
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

  Timer? _expiryTimer;
  Timer? _resendTimer;

  bool _isLoading = false;
  bool _isResending = false;

  int _remainingSeconds = 600;
  int _resendRemainingSeconds = 30;

  bool _canResend = false;
  bool _otpExpired = false;

  String? _messageTitle;
  String? _message;
  AppMessageType? _messageType;

  @override
  void initState() {
    super.initState();

    _startExpiryTimer();
    _startResendTimer();

    // Rebuild when focus changes so the active OTP box
    // can update its border.
    for (final node in _focusNodes) {
      node.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

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

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  String _getReadableError(dynamic error) {
    final message = error.toString().toLowerCase();

    if (message.contains('socketexception') || message.contains('connection')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    if (message.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }

    if (message.contains('expired')) {
      return 'The OTP has expired. Please request a new OTP.';
    }

    if (message.contains('invalid') || message.contains('incorrect')) {
      return 'The OTP you entered is incorrect. Please try again.';
    }

    return 'Something went wrong while verifying the OTP. Please try again.';
  }

  // ============================================================
  // OTP
  // ============================================================

  String get _otp {
    return _otpControllers.map((controller) => controller.text).join();
  }

  bool get _isOtpComplete {
    return _otp.length == 6;
  }

  void _onOtpChanged(String value, int index) {
    _clearMessage();

    if (_otpExpired) {
      return;
    }

    // Handle pasted OTP
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

      if (digits.isEmpty) {
        return;
      }

      for (int i = 0; i < digits.length && index + i < 6; i++) {
        _otpControllers[index + i].text = digits[i];
      }

      final lastIndex = index + digits.length - 1;

      if (lastIndex < 5) {
        _focusNodes[lastIndex + 1].requestFocus();
      } else {
        _focusNodes[5].unfocus();
      }

      setState(() {});
      return;
    }

    // Move forward automatically
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  void _handleBackspace(KeyEvent event, int index) {
    if (event is! KeyDownEvent) {
      return;
    }

    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return;
    }

    if (_otpControllers[index].text.isEmpty && index > 0) {
      _otpControllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();

      setState(() {});
    }
  }

  void _clearOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }

    _focusNodes[0].requestFocus();

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // OTP EXPIRY TIMER
  // ============================================================

  void _startExpiryTimer() {
    _expiryTimer?.cancel();

    _remainingSeconds = 600;
    _otpExpired = false;

    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 0) {
        timer.cancel();

        setState(() {
          _otpExpired = true;
        });

        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // RESEND TIMER
  // ============================================================

  void _startResendTimer() {
    _resendTimer?.cancel();

    _resendRemainingSeconds = 30;
    _canResend = false;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendRemainingSeconds <= 0) {
        timer.cancel();

        setState(() {
          _canResend = true;
        });

        return;
      }

      setState(() {
        _resendRemainingSeconds--;
      });
    });
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    _clearMessage();

    if (_otpExpired) {
      _showMessage(
        title: 'OTP expired',
        message: 'This OTP has expired. Please request a new OTP.',
        type: AppMessageType.error,
      );
      return;
    }

    final otp = _otp;

    if (otp.length != 6) {
      _showMessage(
        title: 'Invalid OTP',
        message: 'Please enter the complete 6-digit OTP.',
        type: AppMessageType.error,
      );
      return;
    }

    if (_isLoading) {
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

        // Stop timers because OTP verification succeeded.
        _expiryTimer?.cancel();
        _resendTimer?.cancel();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ResetPassword(email: widget.email, resetToken: resetToken),
          ),
        );
      } else {
        final errorMessage = (response.error ?? '').trim().toLowerCase();

        if (errorMessage.contains('expired')) {
          setState(() {
            _otpExpired = true;
          });

          _showMessage(
            title: 'OTP expired',
            message: 'This OTP has expired. Please request a new OTP.',
            type: AppMessageType.error,
          );
        } else {
          _showMessage(
            title: 'Invalid OTP',
            message:
                response.error ??
                'The OTP you entered is incorrect. Please try again.',
            type: AppMessageType.error,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('expired')) {
        setState(() {
          _otpExpired = true;
        });

        _showMessage(
          title: 'OTP expired',
          message: 'This OTP has expired. Please request a new OTP.',
          type: AppMessageType.error,
        );
      } else {
        _showMessage(
          title: 'Verification failed',
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

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    _clearMessage();

    if (!_canResend || _isResending || _isLoading) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final response = await ApiManager().client.forgotPassword(
        '/auth/forgot-password',
        ForgotPasswordRequest(email: widget.email, role: 'user'),
      );

      if (!mounted) return;

      if (response.success == true &&
          response.data != null &&
          response.data!.sent == true) {
        _clearOtp();

        _startExpiryTimer();
        _startResendTimer();

        _showMessage(
          title: 'OTP sent',
          message: 'A new OTP has been sent to your registered email address.',
          type: AppMessageType.success,
        );
      } else {
        final errorMessage = (response.error ?? '').trim().toLowerCase();

        if (errorMessage.contains('not registered')) {
          _showMessage(
            title: 'Email not registered',
            message:
                'This email is not registered. Please go back and enter your registered email address.',
            type: AppMessageType.error,
          );
        } else {
          _showMessage(
            title: 'Unable to resend OTP',
            message:
                response.error ??
                'Unable to resend OTP. Please try again later.',
            type: AppMessageType.error,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        title: 'Unable to resend OTP',
        message: _getReadableError(e),
        type: AppMessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _resendTimer?.cancel();

    for (final controller in _otpControllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final isComplete = _isOtpComplete;

    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // ==================================================
              // ICON
              // ==================================================
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.10),
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 40,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // TITLE
              // ==================================================
              const Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // EMAIL TEXT
              // ==================================================
              Text.rich(
                TextSpan(
                  text: 'We have sent a 6-digit verification code to\n',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ==================================================
              // APP MESSAGE
              // ==================================================
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

              // ==================================================
              // OTP BOXES
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final isFocused = _focusNodes[index].hasFocus;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AspectRatio(
                        aspectRatio: 0.85,
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) {
                            _handleBackspace(event, index);
                          },
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            enabled: !_otpExpired && !_isLoading,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            textInputAction: index == 5
                                ? TextInputAction.done
                                : TextInputAction.next,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              filled: _otpExpired,
                              fillColor: _otpExpired
                                  ? Colors.grey.shade100
                                  : null,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              _onOtpChanged(value, index);
                            },
                            onSubmitted: (_) {
                              if (index == 5 && !_isLoading && !_otpExpired) {
                                _verifyOtp();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // COUNTDOWN
              // ==================================================
              if (!_otpExpired)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'OTP expires in ${_formatTime(_remainingSeconds)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'OTP has expired',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 28),

              // ==================================================
              // VERIFY BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || _otpExpired || !isComplete)
                      ? null
                      : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _otpExpired ? 'OTP Expired' : 'Verify OTP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // RESEND OTP
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the OTP?",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 5),
                  TextButton(
                    onPressed: (_canResend && !_isResending && !_isLoading)
                        ? _resendOtp
                        : null,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _canResend
                                ? 'Resend OTP'
                                : 'Resend in ${_resendRemainingSeconds}s',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ==================================================
              // CHANGE EMAIL
              // ==================================================
              TextButton(
                onPressed: (_isLoading || _isResending)
                    ? null
                    : () {
                        Navigator.pop(context);
                      },
                child: const Text('Change Email'),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // INFO
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'For security, the OTP is valid for 10 minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
