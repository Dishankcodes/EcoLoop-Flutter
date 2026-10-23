import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_theme.dart';
import '../../../models/location/city_model.dart';
import '../../../models/location/state_model.dart';
import '../../../shared_preferences_util.dart';
import '../artist_main.dart';

class ArtistCompleteProfilePage extends StatefulWidget {
  final String idToken;
  final Map<String, dynamic> googleProfile;

  const ArtistCompleteProfilePage({
    super.key,
    required this.idToken,
    this.googleProfile = const {},
  });

  @override
  State<ArtistCompleteProfilePage> createState() =>
      _ArtistCompleteProfilePageState();
}

class _ArtistCompleteProfilePageState extends State<ArtistCompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _bio = TextEditingController();
  final _skills = TextEditingController();
  final _experience = TextEditingController();

  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  StateModel? _selectedState;
  CityModel? _selectedCity;

  bool _loadingLocations = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _name.text =
        (widget.googleProfile['name'] ?? widget.googleProfile['userName'] ?? '')
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

      setState(() => _cities = response.data ?? []);
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

  String _getReadableError(Object error) {
    if (error is DioException) {
      final responseData = error.response?.data;

      if (responseData is Map) {
        final backendError = responseData['error'];

        if (backendError is Map) {
          final message = backendError['message']?.toString().trim();
          if (message != null && message.isNotEmpty) return message;
        } else if (backendError is String && backendError.trim().isNotEmpty) {
          return backendError.trim();
        }

        final directMessage = responseData['message']?.toString().trim();
        if (directMessage != null && directMessage.isNotEmpty) {
          return directMessage;
        }
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to the server. Please check your internet connection.';
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'The request timed out. Please try again.';
      }

      return 'Unable to complete the request. Please try again.';
    }

    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    if (message.isNotEmpty && message != 'null') return message;
    return 'Unable to complete registration. Please try again.';
  }

  Future<void> _completeProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedState == null || _selectedCity == null) {
      _showMessage('Please select your state and city.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final response = await ApiManager().client
          .googleCompleteProfile('/auth/google/complete-profile', {
            'idToken': widget.idToken,
            'role': 'artist',
            'userName': _name.text.trim(),
            'phone': _phone.text.trim(),
            'state': _selectedState!.stateName,
            'stateCode': _selectedState!.stateCode,
            'city': _selectedCity!.cityName,
            'bio': _bio.text.trim(),
            'skills': _skills.text.trim(),
            'experience': _experience.text.trim(),
          });

      if (!mounted) return;

      final data = response.data;

      if (response.success != true || data == null) {
        _showMessage(
          _getReadableError(
            Exception(response.error ?? 'Unable to complete your profile.'),
          ),
        );
        return;
      }

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
      await Prefs.setString('userRole', 'artist');
      await Prefs.setString('artistToken', token);
      await Prefs.setString(
        'artistTokenType',
        session['tokenType']?.toString() ?? 'Bearer',
      );
      await Prefs.setString(
        'artistTokenExpiresAt',
        session['expiresAt']?.toString() ?? '',
      );
      await Prefs.setString(
        'artistRole',
        session['role']?.toString() ?? 'artist',
      );
      await Prefs.setString(
        'artistId',
        (session['accountId'] ?? account['artistId'] ?? '').toString(),
      );
      await Prefs.setString(
        'artistName',
        account['userName']?.toString() ?? _name.text.trim(),
      );
      await Prefs.setString(
        'artistEmail',
        account['email']?.toString() ??
            widget.googleProfile['email']?.toString() ??
            '',
      );
      await Prefs.setString(
        'artistPhone',
        account['phone']?.toString() ?? _phone.text.trim(),
      );
      await Prefs.setObject('artistData', account);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ArtistMain()),
        (route) => false,
      );
    } catch (error) {
      if (mounted) {
        _showMessage(_getReadableError(error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    _skills.dispose();
    _experience.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = ArtistColors.primary;

    return Theme(
      data: ArtistTheme.lightTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F7),
        appBar: AppBar(
          title: const Text('Complete ReMaker Profile'),
          backgroundColor: const Color(0xFFFAF9F7),
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
                      Icon(Icons.palette_outlined, size: 52, color: primary),
                      const SizedBox(height: 12),
                      Text(
                        'Your creative journey starts here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tell us a little about yourself and your craft.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 26),
                      _textField(_name, 'Artist name'),
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
                        onChanged: (city) =>
                            setState(() => _selectedCity = city),
                      ),
                      const SizedBox(height: 16),
                      _textField(_bio, 'About you', maxLines: 3),
                      _textField(
                        _skills,
                        'Skills and crafts',
                        hint: 'e.g. Lippan art, upcycling, painting',
                        maxLines: 2,
                      ),
                      _textField(
                        _experience,
                        'Experience',
                        hint: 'e.g. Beginner, 2 years, or professional',
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
        borderSide: const BorderSide(color: Color(0xFFDADBD7)),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: _decoration(label).copyWith(hintText: hint),
        validator:
            validator ??
            (value) => value == null || value.trim().isEmpty
                ? 'Please enter $label'
                : null,
      ),
    );
  }
}
