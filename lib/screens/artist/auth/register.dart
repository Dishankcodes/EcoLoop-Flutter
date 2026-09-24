import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../app_theme/artist/artist_theme.dart';
import '../../../models/auth/artist/artist_send_otp_request.dart';
import '../../../models/location/city_model.dart';
import '../../../models/location/state_model.dart';
import '../../../widgets/app_message.dart';
import '../../../widgets/back_button.dart';
import 'artist_otp.dart';
import 'login.dart';

class ArtistRegister extends StatefulWidget {
  const ArtistRegister({super.key, required this.title});

  final String title;

  @override
  State<ArtistRegister> createState() => _ArtistRegisterState();
}

class _ArtistRegisterState extends State<ArtistRegister> {
  // Form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  // Message
  String? _message;
  String? _messageTitle;
  AppMessageType? _messageType;

  // Location
  StateModel? _selectedState;
  CityModel? _selectedCity;
  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;

  // City Cache
  final Map<String, List<CityModel>> _citiesCache = {};
  final Map<String, Future<List<CityModel>>> _cityLoadingFutures = {};

  // Form State
  bool _isSendingOtp = false;

  // Init
  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  // Dispose
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // Message
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

  // Error Handling
  String _getReadableError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout) {
        return 'Connection timed out. Please check your internet connection.';
      }

      if (error.type == DioExceptionType.sendTimeout) {
        return 'The request took too long to send. Please try again.';
      }

      if (error.type == DioExceptionType.receiveTimeout) {
        return 'The server took too long to respond. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to the server. Please check your internet connection.';
      }

      final responseData = error.response?.data;

      if (responseData is Map<String, dynamic>) {
        final errorData = responseData['error'];

        if (errorData is Map<String, dynamic>) {
          final message = errorData['message'];

          if (message != null && message.toString().trim().isNotEmpty) {
            return message.toString();
          }
        }

        if (responseData['message'] != null) {
          final message = responseData['message'].toString().trim();

          if (message.isNotEmpty) {
            return message;
          }
        }
      }

      return 'Unable to complete the request. Please try again.';
    }

    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return 'Something went wrong. Please try again.';
  }

  // Load States
  Future<void> _loadStates() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStates = true;
    });

    try {
      final response = await ApiManager().client.getStates('/locations/states');

      if (!mounted) return;

      if (response.success == true && response.data != null) {
        setState(() {
          _states = response.data!;
          _isLoadingStates = false;
        });
      } else {
        setState(() {
          _isLoadingStates = false;
        });

        _showMessage(
          title: 'Unable to load states',
          message: response.error ?? 'Please try again.',
          type: AppMessageType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingStates = false;
      });

      _showMessage(
        title: 'Unable to load states',
        message: _getReadableError(e),
        type: AppMessageType.error,
      );
    }
  }

  // Fetch Cities For State
  Future<List<CityModel>> _fetchCitiesForState(String stateCode) {
    if (_citiesCache.containsKey(stateCode)) {
      return Future.value(_citiesCache[stateCode]!);
    }

    if (_cityLoadingFutures.containsKey(stateCode)) {
      return _cityLoadingFutures[stateCode]!;
    }

    final future = _requestCities(stateCode);
    _cityLoadingFutures[stateCode] = future;

    return future;
  }

  // Request Cities
  Future<List<CityModel>> _requestCities(String stateCode) async {
    try {
      final response = await ApiManager().client.getCities(
        '/locations/cities',
        stateCode,
      );

      if (response.success == true && response.data != null) {
        final cities = response.data!;
        _citiesCache[stateCode] = cities;
        return cities;
      }

      return [];
    } catch (_) {
      return [];
    } finally {
      _cityLoadingFutures.remove(stateCode);
    }
  }

  // Load Cities After State Selection
  Future<void> _loadCities(String stateCode) async {
    if (!mounted) return;

    final cachedCities = _citiesCache[stateCode];

    if (cachedCities != null) {
      setState(() {
        _cities = cachedCities;
        _selectedCity = null;
        _isLoadingCities = false;
      });
      return;
    }

    setState(() {
      _cities = [];
      _selectedCity = null;
      _isLoadingCities = true;
    });

    try {
      final cities = await _fetchCitiesForState(stateCode);

      if (!mounted) return;

      if (_selectedState?.stateCode != stateCode) {
        return;
      }

      if (cities.isNotEmpty) {
        setState(() {
          _cities = cities;
          _isLoadingCities = false;
        });
      } else {
        setState(() {
          _cities = [];
          _isLoadingCities = false;
        });

        _showMessage(
          title: 'No cities available',
          message: 'No cities are currently available for this state.',
          type: AppMessageType.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCities = false;
      });

      _showMessage(
        title: 'Unable to load cities',
        message: _getReadableError(e),
        type: AppMessageType.error,
      );
    }
  }

  // Validation
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }
    return null;
  }

  // Email Validation
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final email = value.trim();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Phone Validation
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    final phone = value.trim();

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      return 'Phone number must be 10 digits';
    }

    return null;
  }

  // Experience Validation
  String? _validateExperience(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your experience';
    }

    final experience = int.tryParse(value.trim());

    if (experience == null) {
      return 'Please enter a valid number';
    }

    if (experience < 0) {
      return 'Experience cannot be negative';
    }

    return null;
  }

  // Send Registration OTP
  Future<void> _createArtistAccount() async {
    FocusScope.of(context).unfocus();
    _clearMessage();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedState == null) {
      _showMessage(
        title: 'Missing information',
        message: 'Please select your state.',
        type: AppMessageType.warning,
      );
      return;
    }

    if (_selectedCity == null) {
      _showMessage(
        title: 'Missing information',
        message: 'Please select your city.',
        type: AppMessageType.warning,
      );
      return;
    }

    if (_isSendingOtp) {
      return;
    }

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() {
      _isSendingOtp = true;
    });

    try {
      final request = ArtistSendOtpRequest(email: email, phone: phone);

      final response = await ApiManager().client.artistRegisterSendOtp(
        '/auth/artist/register/send-otp',
        request,
      );

      if (!mounted) return;

      if (response.success != true || response.data?.sent != true) {
        _showMessage(
          title: 'Unable to continue',
          message:
              response.error ??
              'We could not send the verification code. Please try again.',
          type: AppMessageType.error,
        );
        return;
      }

      final registrationData = <String, dynamic>{
        'userName': _nameController.text.trim(),
        'email': email,
        'phone': phone,
        'city': _selectedCity!.cityName,
        'state': _selectedState!.stateName,
        'stateCode': _selectedState!.stateCode,
        'bio': _bioController.text.trim(),
        'skills': _skillsController.text.trim(),
        'experience': _experienceController.text.trim(),
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtistOtpScreen(
            email: email,
            isRegistration: true,
            registrationData: registrationData,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        title: 'Something went wrong',
        message: _getReadableError(e),
        type: AppMessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  // Build
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ArtistTheme.lightTheme,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: ArtistColors.background,
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      const AppBackButton(),
                      const SizedBox(height: 20),

                      // Title
                      Center(
                        child: Text(
                          'Artist Registration',
                          style: ArtistTextStyles.heading,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Tell us about your creativity',
                          style: ArtistTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Profile Icon
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: ArtistColors.primary.withOpacity(0.10),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ArtistColors.primary.withOpacity(0.12),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                size: 48,
                                color: ArtistColors.primary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.add_a_photo_outlined,
                                size: 18,
                              ),
                              label: Text(
                                'Add Photo',
                                style: ArtistTextStyles.body.copyWith(
                                  color: ArtistColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ArtistColors.primary,
                                backgroundColor: ArtistColors.surface,
                                side: const BorderSide(
                                  color: ArtistColors.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Name
                      _buildLabel('Your Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) => _validateRequired(value, 'name'),
                        onChanged: (_) => _clearMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Enter your name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email
                      _buildLabel('Email'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        autocorrect: false,
                        onChanged: (_) => _clearMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Phone
                      _buildLabel('Phone Number'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: _validatePhone,
                        onChanged: (_) => _clearMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Enter your 10-digit phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // State
                      _buildLabel('State'),
                      const SizedBox(height: 8),
                      DropdownSearch<StateModel>(
                        selectedItem: _selectedState,
                        enabled: !_isLoadingStates && _states.isNotEmpty,
                        items: (filter, loadProps) => _states,
                        itemAsString: (StateModel state) => state.stateName,
                        compareFn: (StateModel a, StateModel b) =>
                            a.stateCode == b.stateCode,
                        onSelected: (StateModel? value) {
                          if (value == null) return;
                          setState(() {
                            _selectedState = value;
                            _selectedCity = null;

                            final cached = _citiesCache[value.stateCode];
                            if (cached != null) {
                              _cities = cached;
                              _isLoadingCities = false;
                            } else {
                              _cities = [];
                              _isLoadingCities = true;
                            }
                          });
                          _loadCities(value.stateCode);
                        },
                        validator: (value) {
                          if (value == null) return 'Please select your state';
                          return null;
                        },
                        decoratorProps: DropDownDecoratorProps(
                          decoration: InputDecoration(
                            hintText: _isLoadingStates
                                ? 'Loading states...'
                                : 'Select your state',
                            prefixIcon: const Icon(Icons.map_outlined),
                            suffixIcon: _isLoadingStates
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ArtistColors.primary,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        popupProps: PopupProps.modalBottomSheet(
                          showSearchBox: true,
                          searchDelay: Duration.zero,
                          title: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                            child: Text(
                              'Select State',
                              style: ArtistTextStyles.title,
                            ),
                          ),
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search state...',
                              hintStyle: ArtistTextStyles.hint,
                              prefixIcon: const Icon(Icons.search_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          itemBuilder:
                              (context, state, isDisabled, isSelected) {
                                return ListTile(
                                  leading: Icon(
                                    Icons.map_outlined,
                                    color: isSelected
                                        ? ArtistColors.primary
                                        : ArtistColors.textSecondary,
                                  ),
                                  title: Text(
                                    state.stateName,
                                    style: ArtistTextStyles.body.copyWith(
                                      color: ArtistColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: ArtistColors.primary,
                                        )
                                      : null,
                                );
                              },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // City
                      _buildLabel('City'),
                      const SizedBox(height: 8),
                      DropdownSearch<CityModel>(
                        selectedItem: _selectedCity,
                        enabled:
                            _selectedState != null &&
                            !_isLoadingCities &&
                            _cities.isNotEmpty,
                        items: (filter, loadProps) => _cities,
                        itemAsString: (CityModel city) => city.cityName,
                        compareFn: (CityModel a, CityModel b) =>
                            a.cityId == b.cityId,
                        onSelected: (CityModel? value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Please select your city';
                          return null;
                        },
                        decoratorProps: DropDownDecoratorProps(
                          decoration: InputDecoration(
                            hintText: _selectedState == null
                                ? 'Select state first'
                                : _isLoadingCities
                                ? 'Loading cities...'
                                : _cities.isEmpty
                                ? 'No cities available'
                                : 'Select your city',
                            prefixIcon: const Icon(
                              Icons.location_city_outlined,
                            ),
                            suffixIcon: _isLoadingCities
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: ArtistColors.primary,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        popupProps: PopupProps.modalBottomSheet(
                          showSearchBox: true,
                          searchDelay: Duration.zero,
                          title: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                            child: Text(
                              _selectedState == null
                                  ? 'Select City'
                                  : 'Select City in ${_selectedState!.stateName}',
                              style: ArtistTextStyles.title,
                            ),
                          ),
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: 'Search city...',
                              hintStyle: ArtistTextStyles.hint,
                              prefixIcon: const Icon(Icons.search_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          itemBuilder: (context, city, isDisabled, isSelected) {
                            return ListTile(
                              leading: Icon(
                                Icons.location_city_outlined,
                                color: isSelected
                                    ? ArtistColors.primary
                                    : ArtistColors.textSecondary,
                              ),
                              title: Text(
                                city.cityName,
                                style: ArtistTextStyles.body.copyWith(
                                  color: ArtistColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: ArtistColors.primary,
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bio
                      _buildLabel('Bio'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText:
                              'Tell us about yourself and your creativity',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 55),
                            child: Icon(Icons.description_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Skills
                      _buildLabel('Skills'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _skillsController,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Example: Painting, Pottery, Woodwork',
                          prefixIcon: Icon(Icons.palette_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Experience
                      _buildLabel('Experience'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        validator: _validateExperience,
                        decoration: const InputDecoration(
                          hintText: 'Experience in years',
                          prefixIcon: Icon(Icons.work_outline),
                          suffixText: 'Years',
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Send OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSendingOtp
                              ? null
                              : _createArtistAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ArtistColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: ArtistColors.primary
                                .withOpacity(0.5),
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSendingOtp
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Continue & Send OTP',
                                  style: ArtistTextStyles.button,
                                ),
                        ),
                      ),

                      // Message
                      if (_message != null &&
                          _messageTitle != null &&
                          _messageType != null) ...[
                        const SizedBox(height: 16),
                        AppMessage(
                          title: _messageTitle!,
                          message: _message!,
                          type: _messageType!,
                          onClose: _clearMessage,
                        ),
                      ],
                      const SizedBox(height: 22),

                      // Login
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Already registered?',
                              style: ArtistTextStyles.caption.copyWith(
                                fontSize: 14,
                                color: ArtistColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),

                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _isSendingOtp
                                  ? null
                                  : () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ArtistLogin(
                                            title: 'Artist Login',
                                          ),
                                        ),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: ArtistColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Login Here',
                                style: ArtistTextStyles.body.copyWith(
                                  color: ArtistColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Label
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: ArtistTextStyles.body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ArtistColors.textPrimary,
      ),
    );
  }
}
