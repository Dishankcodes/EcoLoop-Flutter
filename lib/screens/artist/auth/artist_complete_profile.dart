import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _locationsFailed = false;
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
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Theme(
      data: ArtistTheme.lightTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F3),
        appBar: AppBar(
          title: const Text(
            'Complete your profile',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          backgroundColor: const Color(0xFFF6F7F3),
          foregroundColor: const Color(0xFF202A23),
          elevation: 0,
          centerTitle: false,
        ),
        body: SafeArea(
          child: _loadingLocations
              ? Center(child: CircularProgressIndicator(color: primary))
              : _locationsFailed
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 48,
                          color: primary,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'We couldn’t load locations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Check your connection and try again to choose your state and city.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _loadingLocations = true;
                              _locationsFailed = false;
                            });
                            _loadStates();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      screenWidth < 360 ? 16 : 20,
                      8,
                      screenWidth < 360 ? 16 : 20,
                      28,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primary,
                                      Color.lerp(primary, Colors.black, .18)!,
                                    ],
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(.16),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(.22),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.palette_outlined,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Let’s make it official',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Complete your ReMaker profile to showcase your craft.',
                                            style: TextStyle(
                                              color: Colors.white,
                                              height: 1.35,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              const _SectionHeading(
                                title: 'Basic information',
                                subtitle:
                                    'How buyers can identify and contact you.',
                              ),
                              const SizedBox(height: 14),
                              _textField(
                                _name,
                                'Artist name',
                                hint: 'Enter your name or studio name',
                                prefixIcon: Icons.person_outline,
                                textCapitalization: TextCapitalization.words,
                              ),
                              _textField(
                                _phone,
                                'Mobile number',
                                hint: '10-digit mobile number',
                                prefixIcon: Icons.phone_iphone_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: (value) {
                                  final phone = value?.trim() ?? '';
                                  if (phone.isEmpty)
                                    return 'Please enter your mobile number';
                                  if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                                    return 'Enter exactly 10 digits';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 4),
                              const _SectionHeading(
                                title: 'Your location',
                                subtitle:
                                    'Help people find ReMakers in their area.',
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<StateModel>(
                                initialValue: _selectedState,
                                isExpanded: true,
                                decoration: _decoration('State').copyWith(
                                  prefixIcon: const Icon(Icons.map_outlined),
                                ),
                                hint: const Text('Choose your state'),
                                items: _states
                                    .map(
                                      (state) => DropdownMenuItem<StateModel>(
                                        value: state,
                                        child: Text(
                                          state.stateName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                validator: (state) => state == null
                                    ? 'Please select your state'
                                    : null,
                                onChanged: (state) {
                                  if (state != null) _loadCities(state);
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<CityModel>(
                                initialValue: _selectedCity,
                                isExpanded: true,
                                decoration: _decoration('City').copyWith(
                                  prefixIcon: const Icon(
                                    Icons.location_city_outlined,
                                  ),
                                ),
                                hint: Text(
                                  _selectedState == null
                                      ? 'Select a state first'
                                      : 'Choose your city',
                                ),
                                items: _cities
                                    .map(
                                      (city) => DropdownMenuItem<CityModel>(
                                        value: city,
                                        child: Text(
                                          city.cityName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                validator: (city) => city == null
                                    ? 'Please select your city'
                                    : null,
                                onChanged: _selectedState == null
                                    ? null
                                    : (city) =>
                                          setState(() => _selectedCity = city),
                              ),
                              const SizedBox(height: 22),
                              const _SectionHeading(
                                title: 'About your craft',
                                subtitle:
                                    'Share what you create and the experience you bring.',
                              ),
                              const SizedBox(height: 14),
                              _textField(
                                _bio,
                                'About you',
                                hint: 'Tell buyers a little about yourself',
                                prefixIcon: Icons.auto_awesome_outlined,
                                maxLines: 3,
                              ),
                              _textField(
                                _skills,
                                'Skills and crafts',
                                hint: 'e.g. Lippan art, upcycling, painting',
                                prefixIcon: Icons.handyman_outlined,
                                maxLines: 2,
                              ),
                              _textField(
                                _experience,
                                'Experience',
                                hint: 'e.g. Beginner, 2 years, professional',
                                prefixIcon: Icons.workspace_premium_outlined,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 54,
                                child: FilledButton(
                                  onPressed: _submitting
                                      ? null
                                      : _completeProfile,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: primary
                                        .withOpacity(.55),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
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
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              size: 20,
                                            ),
                                            SizedBox(width: 10),
                                            Text('Complete profile'),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Your details help us set up your ReMaker account.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF747B74),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
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
    const borderColor = Color(0xFFE0E4DC);
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: ArtistColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
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
    IconData? prefixIcon,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        // Flutter requires a multiline keyboard when a multiline field uses
        // TextInputAction.newline. Preserve explicitly requested keyboard types.
        keyboardType: maxLines > 1 && keyboardType == TextInputType.text
            ? TextInputType.multiline
            : keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        minLines: maxLines == 1 ? 1 : null,
        textInputAction: maxLines == 1
            ? TextInputAction.next
            : TextInputAction.newline,
        decoration: _decoration(label).copyWith(
          hintText: hint,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          alignLabelWithHint: maxLines > 1,
          counterText: label == 'Mobile number'
              ? '${controller.text.length}/10'
              : null,
        ),
        onChanged: label == 'Mobile number' ? (_) => setState(() {}) : null,
        validator:
            validator ??
            (value) => value == null || value.trim().isEmpty
                ? 'Please enter $label'
                : null,
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF202A23),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: Color(0xFF737B72),
          ),
        ),
      ],
    );
  }
}
