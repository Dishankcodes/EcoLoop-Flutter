import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../api/api_manager.dart';
import '../../../app_theme/user/app_colors.dart';
import '../../../models/location/city_model.dart';
import '../../../models/location/state_model.dart';
import '../../../shared_preferences_util.dart';
import '../user_main.dart';

class UserCompleteProfilePage extends StatefulWidget {
  final String idToken;
  final Map<String, dynamic> googleProfile;

  const UserCompleteProfilePage({
    super.key,
    required this.idToken,
    this.googleProfile = const {},
  });

  @override
  State<UserCompleteProfilePage> createState() =>
      _UserCompleteProfilePageState();
}

class _UserCompleteProfilePageState extends State<UserCompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();

  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  StateModel? _selectedState;
  CityModel? _selectedCity;
  String? _gender;
  bool _loadingLocations = true;
  bool _locationsFailed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _firstName.text =
        (widget.googleProfile['firstName'] ??
                widget.googleProfile['givenName'] ??
                '')
            .toString();

    _lastName.text =
        (widget.googleProfile['lastName'] ??
                widget.googleProfile['familyName'] ??
                '')
            .toString();

    _loadStates();
  }

  Future<void> _loadStates() async {
    try {
      final response = await ApiManager().client.getStates('/locations/states');

      if (!mounted) return;

      setState(() {
        _states = response.data ?? [];
        _loadingLocations = false;
        _locationsFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLocations = false;
        _locationsFailed = true;
      });
      _showMessage('Unable to load states. Please try again.');
    }
  }

  Future<void> _loadCities(StateModel state) async {
    setState(() {
      _selectedState = state;
      _selectedCity = null;
      _cities = [];
    });

    try {
      final response = await ApiManager().client.getCities(
        '/locations/cities',
        state.stateCode,
      );

      if (!mounted) return;

      setState(() {
        _cities = response.data ?? [];
      });
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to load cities. Please try again.');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _readableError(Object error) {
    dynamic payload;

    if (error is DioException) {
      payload = error.response?.data;
    }

    if (payload is String) {
      try {
        payload = jsonDecode(payload);
      } catch (_) {
        // Keep the original message fallback below.
      }
    }

    if (payload is Map) {
      final nestedError = payload['error'];
      if (nestedError is Map && nestedError['message'] != null) {
        final message = nestedError['message'].toString().trim();
        if (message.isNotEmpty) return _friendlyAuthError(message);
      }

      if (nestedError is String && nestedError.trim().isNotEmpty) {
        return _friendlyAuthError(nestedError.trim());
      }

      final message = payload['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return _friendlyAuthError(message);
      }
    }

    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isNotEmpty && !raw.contains('DioException')) {
      return _friendlyAuthError(raw);
    }

    return 'Unable to complete your profile. Please try again.';
  }

  String _friendlyAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('already exists') ||
        lower.contains('already registered') ||
        lower.contains('existing method')) {
      return 'This email is already registered using another login method. Please sign in using your existing method.';
    }

    if (lower.contains('phone') &&
        (lower.contains('already') ||
            lower.contains('duplicate') ||
            lower.contains('exists'))) {
      return 'This mobile number is already registered. Please use a different number.';
    }

    return message;
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null || _selectedCity == null) {
      _showMessage('Please select your state and city.');
      return;
    }

    if (_gender == null) {
      _showMessage('Please select your gender.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final response = await ApiManager().client
          .googleCompleteProfile('/auth/google/complete-profile', {
            'idToken': widget.idToken,
            'role': 'user',
            'firstName': _firstName.text.trim(),
            'lastName': _lastName.text.trim(),
            'phone': _phone.text.trim(),
            'gender': _gender,
            'state': _selectedState!.stateName,
            'stateCode': _selectedState!.stateCode,
            'city': _selectedCity!.cityName,
          });

      if (!mounted) return;

      final data = response.data;

      if (response.success != true || data == null) {
        final message = (response.error ?? '').toString().trim();
        _showMessage(
          message.isEmpty
              ? 'Unable to complete your profile. Please try again.'
              : _friendlyAuthError(message),
        );
        return;
      }

      // Support the standard Apps Script {success, data} response.
      final session = data['token'] != null
          ? data
          : data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : <String, dynamic>{};

      final account = session['account'] is Map
          ? Map<String, dynamic>.from(session['account'] as Map)
          : <String, dynamic>{};

      final token = session['token']?.toString() ?? '';

      if (token.isEmpty) {
        _showMessage(
          'Profile was submitted, but the server did not return a login token.',
        );
        return;
      }

      await Prefs.setBool('isLoggedIn', true);
      await Prefs.setString('userRole', 'user');
      await Prefs.setString('authToken', token);
      await Prefs.setString(
        'userEmail',
        account['email']?.toString() ??
            widget.googleProfile['email']?.toString() ??
            '',
      );
      await Prefs.setString(
        'userName',
        '${account['firstName'] ?? _firstName.text.trim()} '
                '${account['lastName'] ?? _lastName.text.trim()}'
            .trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UserMain()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        _showMessage(_readableError(e));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5EE),
      appBar: AppBar(
        title: const Text(
          'Complete your profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFF7F5EE),
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Icon(Icons.eco_rounded, size: 54, color: primary),
              const SizedBox(height: 12),
              Text(
                'Welcome to EcoLoop!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A few more details to set up your account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              if (_loadingLocations)
                const LinearProgressIndicator(minHeight: 2),
              if (_locationsFailed)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _loadStates,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry loading locations'),
                  ),
                ),
              const SizedBox(height: 18),
              _textField(_firstName, 'First name'),
              _textField(_lastName, 'Last name'),
              _textField(
                _phone,
                'Mobile number',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                maxLength: 10,
                decoration: _decoration('Mobile number').copyWith(
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                  prefixText: '+91  ',
                  counterText: '',
                  helperText: 'Enter your 10-digit Indian mobile number',
                ),
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                    return 'Enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: _decoration('Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _gender = value),
                validator: (value) =>
                    value == null ? 'Select your gender' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<StateModel>(
                initialValue: _selectedState,
                isExpanded: true,
                hint: Text(
                  _loadingLocations ? 'Loading states…' : 'Choose your state',
                ),
                onTap: null,
                decoration: _decoration('Select state'),
                items: _states
                    .map(
                      (state) => DropdownMenuItem(
                        value: state,
                        child: Text(state.stateName),
                      ),
                    )
                    .toList(),
                onChanged: _loadingLocations
                    ? null
                    : (state) {
                        if (state != null) _loadCities(state);
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CityModel>(
                initialValue: _selectedCity,
                isExpanded: true,
                hint: Text(
                  _selectedState == null
                      ? 'Choose state first'
                      : 'Choose your city',
                ),
                decoration: _decoration('Select city'),
                items: _cities
                    .map(
                      (city) => DropdownMenuItem(
                        value: city,
                        child: Text(city.cityName),
                      ),
                    )
                    .toList(),
                onChanged: (city) => setState(() => _selectedCity = city),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _completeProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Complete profile',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE4DC), width: 1.1),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    InputDecoration? decoration,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        decoration: decoration ?? _decoration(label),
        validator:
            validator ??
            (value) => value == null || value.trim().isEmpty
                ? 'Please enter $label'
                : null,
      ),
    );
  }
}
