import 'package:flutter/material.dart';

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
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLocations = false);
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
        _showMessage(response.error ?? 'Unable to complete your profile.');
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
        _showMessage('Unable to complete registration. Please try again.');
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
        title: const Text('Complete your profile'),
        backgroundColor: const Color(0xFFF7F5EE),
        foregroundColor: primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loadingLocations
            ? Center(child: CircularProgressIndicator(color: primary))
            : Form(
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
                    const SizedBox(height: 26),
                    _textField(_firstName, 'First name'),
                    _textField(_lastName, 'Last name'),
                    _textField(
                      _phone,
                      'Mobile number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null ||
                            !RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                          return 'Enter a valid 10-digit mobile number';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: _decoration('Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) => setState(() => _gender = value),
                      validator: (value) =>
                          value == null ? 'Select your gender' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<StateModel>(
                      value: _selectedState,
                      isExpanded: true,
                      decoration: _decoration('Select state'),
                      items: _states
                          .map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child: Text(state.stateName),
                            ),
                          )
                          .toList(),
                      onChanged: (state) {
                        if (state != null) _loadCities(state);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<CityModel>(
                      value: _selectedCity,
                      isExpanded: true,
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFDDE4DC)),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: _decoration(label),
        validator:
            validator ??
            (value) => value == null || value.trim().isEmpty
                ? 'Please enter $label'
                : null,
      ),
    );
  }
}
