import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
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
  // FORM

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _bioController = TextEditingController();

  final TextEditingController _skillsController = TextEditingController();

  final TextEditingController _experienceController = TextEditingController();

  // MESSAGE

  String? _message;
  String? _messageTitle;
  AppMessageType? _messageType;

  // LOCATION

  StateModel? _selectedState;
  CityModel? _selectedCity;

  List<StateModel> _states = [];
  List<CityModel> _cities = [];

  bool _isLoadingStates = false;
  bool _isLoadingCities = false;

  // CITY CACHE

  final Map<String, List<CityModel>> _citiesCache = {};

  final Map<String, Future<List<CityModel>>> _cityLoadingFutures = {};

  // FORM STATE

  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();

    _loadStates();
  }

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

  // MESSAGE

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

  // ERROR HANDLING

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

          if (message != null && message.toString().isNotEmpty) {
            return message.toString();
          }
        }

        if (responseData['message'] != null) {
          return responseData['message'].toString();
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

  // LOAD STATES

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

        // We don't need to download every city's data here.
        // Cities are loaded when the user selects a state.
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

  // FETCH CITIES

  Future<List<CityModel>> _fetchCitiesForState(String stateCode) {
    // CACHE

    if (_citiesCache.containsKey(stateCode)) {
      return Future.value(_citiesCache[stateCode]!);
    }

    // PREVENT DUPLICATE REQUESTS

    if (_cityLoadingFutures.containsKey(stateCode)) {
      return _cityLoadingFutures[stateCode]!;
    }

    // REQUEST

    final future = _requestCities(stateCode);

    _cityLoadingFutures[stateCode] = future;

    return future;
  }

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

  // LOAD CITIES AFTER STATE SELECTION

  Future<void> _loadCities(String stateCode) async {
    if (!mounted) return;
    // CHECK CACHE FIRST
    final cachedCities = _citiesCache[stateCode];

    if (cachedCities != null) {
      setState(() {
        _cities = cachedCities;
        _selectedCity = null;
        _isLoadingCities = false;
      });

      return;
    }

    // SHOW LOADING

    setState(() {
      _cities = [];
      _selectedCity = null;
      _isLoadingCities = true;
    });

    try {
      final cities = await _fetchCitiesForState(stateCode);

      if (!mounted) return;

      // State may have changed while request was running.
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

  // VALIDATION

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your $fieldName';
    }

    return null;
  }

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

  // SEND REGISTRATION OTP

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

    setState(() {
      _isSendingOtp = true;
    });

    try {
      // --------------------------------------------------------
      // SEND OTP
      // --------------------------------------------------------

      final request = ArtistSendOtpRequest(email: email);

      final response = await ApiManager().client.artistRegisterSendOtp(
        '/auth/artist/register/send-otp',
        request,
      );

      if (!mounted) return;

      if (response.success != true || response.data?.sent != true) {
        _showMessage(
          title: 'Unable to send OTP',
          message:
              response.error ??
              'We could not send the verification code. Please try again.',
          type: AppMessageType.error,
        );

        return;
      }

      // --------------------------------------------------------
      // KEEP ALL REGISTRATION DATA IN MEMORY
      // --------------------------------------------------------

      final registrationData = <String, dynamic>{
        'userName': _nameController.text.trim(),

        'email': email,

        'phone': _phoneController.text.trim(),

        'city': _selectedCity!.cityName,

        'state': _selectedState!.stateName,

        'stateCode': _selectedState!.stateCode,

        'bio': _bioController.text.trim(),

        'skills': _skillsController.text.trim(),

        'experience': _experienceController.text.trim(),
      };

      // --------------------------------------------------------
      // OPEN OTP SCREEN
      // --------------------------------------------------------

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

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // BACK
                // ------------------------------------------------
                const AppBackButton(),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------
                Center(
                  child: Text(
                    'Artist Registration',
                    style: AppTextStyles.heading,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'Tell us about your creativity',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ),

                // ------------------------------------------------
                // MESSAGE
                // ------------------------------------------------
                if (_message != null &&
                    _messageTitle != null &&
                    _messageType != null) ...[
                  const SizedBox(height: 24),

                  AppMessage(
                    title: _messageTitle!,
                    message: _message!,
                    type: _messageType!,
                    onClose: _clearMessage,
                  ),
                ],

                const SizedBox(height: 28),

                // ------------------------------------------------
                // PROFILE ICON
                // ------------------------------------------------
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.10,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: 10),

                      OutlinedButton.icon(
                        onPressed: () {
                          // Profile photo upload
                          // will be connected later.
                        },
                        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: const Text('Add Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // NAME
                _buildLabel('Your Name'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _validateRequired(value, 'name'),
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),

                const SizedBox(height: 20),

                // EMAIL
                _buildLabel('Email'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 20),

                // PHONE
                _buildLabel('Phone Number'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: _validatePhone,
                  decoration: const InputDecoration(
                    hintText: 'Enter your 10-digit phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                    counterText: '',
                  ),
                ),

                const SizedBox(height: 20),

                // STATE
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
                    if (value == null) {
                      return;
                    }

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
                    if (value == null) {
                      return 'Please select your state';
                    }

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
                        style: AppTextStyles.body.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Search state...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    itemBuilder: (context, state, isDisabled, isSelected) {
                      return ListTile(
                        leading: Icon(
                          Icons.map_outlined,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        title: Text(
                          state.stateName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // CITY
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

                  compareFn: (CityModel a, CityModel b) => a.cityId == b.cityId,

                  onSelected: (CityModel? value) {
                    setState(() {
                      _selectedCity = value;
                    });
                  },

                  validator: (value) {
                    if (value == null) {
                      return 'Please select your city';
                    }

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

                      prefixIcon: const Icon(Icons.location_city_outlined),

                      suffixIcon: _isLoadingCities
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
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
                        style: AppTextStyles.body.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Search city...',
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
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        title: Text(
                          city.cityName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // BIO
                _buildLabel('Bio'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Tell us about yourself and your creativity',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 55),
                      child: Icon(Icons.description_outlined),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // SKILLS
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

                // EXPERIENCE
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

                // SEND OTP BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSendingOtp ? null : _createArtistAccount,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.5,
                      ),
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
                            style: AppTextStyles.button,
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                // LOGIN
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Already registered?',
                        style: AppTextStyles.caption.copyWith(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Your artist account is already registered. '
                        'You can login directly.',
                        style: AppTextStyles.caption.copyWith(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),

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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Login Here',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
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
  }

  // LABEL
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
