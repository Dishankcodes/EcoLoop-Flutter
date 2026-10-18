import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../auth/forgot_password.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loadingEmail = true;
  bool _saving = false;
  String _email = '';
  String? _pageError;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _findEmail(dynamic value) {
    if (value is Map) {
      for (final key in const ['email', 'userEmail']) {
        final v = value[key];
        if (v is String && v.trim().contains('@')) return v.trim();
      }
      for (final key in const ['account', 'profile', 'user', 'data']) {
        final found = _findEmail(value[key]);
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<void> _loadEmail() async {
    try {
      final response = await EcoLoopApi.instance.get('/profile');
      final email = _findEmail(response);
      if (!mounted) return;
      setState(() {
        _email = email ?? '';
        _loadingEmail = false;
        if (_email.isEmpty) {
          _pageError =
              'Could not load your account email. Please refresh or try again.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingEmail = false;
        _pageError = e.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.error : AppColors.primary,
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    if (_newController.text == _currentController.text) {
      _showMessage(
        'New password must be different from your current password.',
        error: true,
      );
      return;
    }
    if (_newController.text != _confirmController.text) {
      _showMessage('New password and confirmation do not match.', error: true);
      return;
    }
    if (_email.isEmpty) {
      _showMessage(
        'Your account email has not loaded. Please try again.',
        error: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await EcoLoopApi.instance.put('/profile/password', <String, dynamic>{
        'currentPassword': _currentController.text,
        'newPassword': _newController.text,
      });
      if (!mounted) return;
      _showMessage('Password changed successfully.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        e.toString().replaceFirst('Exception: ', '').trim().isEmpty
            ? 'Could not change your password. Please try again.'
            : e.toString().replaceFirst('Exception: ', '').trim(),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(
    String label,
    bool obscure,
    VoidCallback toggle,
  ) => InputDecoration(
    labelText: label,
    prefixIcon: const Icon(Icons.lock_outline_rounded),
    suffixIcon: IconButton(
      tooltip: obscure ? 'Show password' : 'Hide password',
      onPressed: toggle,
      icon: Icon(
        obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
    ),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: BorderSide(color: AppColors.accent.withOpacity(.45)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );

  Widget _passwordInput({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: TextInputAction.next,
      validator: validator,
      decoration: _decoration(label, obscure, toggle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text('Change Password', style: AppTextStyles.title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.accent.withOpacity(.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.light,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Secure your account', style: AppTextStyles.title),
                    const SizedBox(height: 5),
                    Text(
                      'Enter your current password and choose a new one.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Account email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    TextFormField(
                      key: ValueKey(_email),
                      initialValue: _loadingEmail
                          ? 'Loading email…'
                          : (_email.isEmpty ? 'Email unavailable' : _email),
                      readOnly: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    if (_pageError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _pageError!,
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _loadingEmail = true;
                              _pageError = null;
                            });
                            _loadEmail();
                          },
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _passwordInput(
                      controller: _currentController,
                      label: 'Current password',
                      obscure: _obscureCurrent,
                      toggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter your current password'
                          : null,
                    ),
                    const SizedBox(height: 15),
                    _passwordInput(
                      controller: _newController,
                      label: 'New password',
                      obscure: _obscureNew,
                      toggle: () => setState(() => _obscureNew = !_obscureNew),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter a new password'
                          : null,
                    ),
                    const SizedBox(height: 15),
                    _passwordInput(
                      controller: _confirmController,
                      label: 'Confirm new password',
                      obscure: _obscureConfirm,
                      toggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Confirm your new password'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPassword(),
                          ),
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _saving || _loadingEmail || _email.isEmpty
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 21,
                                width: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Update Password',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
