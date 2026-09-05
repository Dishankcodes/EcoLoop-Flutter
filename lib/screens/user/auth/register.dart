import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
import '../../../models/auth/user_register_model.dart';
import '../../../models/location/city_model.dart';
import '../../../models/location/state_model.dart';
import '../../../shared_preferences_util.dart';
import '../../../widgets/app_message.dart';
import '../../../widgets/back_button.dart';
import '../../artist/artist_intro.dart';
import 'login.dart';
import '../user_main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.title});

  final String title;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Form Key & Text Controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Application Message Notification State
  String? _message;
  String? _messageTitle;
  AppMessageType? _messageType;

  // Selected Form Fields
  String? _selectedGender;
  StateModel? _selectedState;
  CityModel? _selectedCity;

  // Location Data State
  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;

  // City Caching & Concurrency Management
  final Map<String, List<CityModel>> _citiesCache = {};
  final Map<String, Future<List<CityModel>>> _cityLoadingFutures = {};

  // Form Controls
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  /// Extracts user-friendly error messages from API or network failures.
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
      return 'Unable to complete registration. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Loads available states from the backend and initiates background prefetching for cities.
  Future<void> _loadStates() async {
    if (!mounted) return;
    setState(() => _isLoadingStates = true);

    try {
      final response = await ApiManager().client.getStates('/locations/states');
      if (!mounted) return;

      if (response.success == true && response.data != null) {
        setState(() {
          _states = response.data!;
          _isLoadingStates = false;
        });
        _prefetchCitiesInBackground();
      } else {
        setState(() => _isLoadingStates = false);
        _showMessage(
          title: 'Unable to load states',
          message: response.error ?? 'Please try again.',
          type: AppMessageType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStates = false);
      _showMessage(
        title: 'Unable to load states',
        message: _getReadableError(e),
        type: AppMessageType.error,
      );
    }
  }

  /// Retrieves cities for a given state code using cache or in-flight futures if available.
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

  /// Executes the network request to fetch cities for a specific state code.
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

  /// Prefetches city data in small batches to optimize performance without overloading network requests.
  Future<void> _prefetchCitiesInBackground() async {
    if (_states.isEmpty) return;
    const batchSize = 4;

    for (int i = 0; i < _states.length; i += batchSize) {
      if (!mounted) return;
      final batch = _states.skip(i).take(batchSize);

      await Future.wait(
        batch.map((state) => _fetchCitiesForState(state.stateCode)),
      );

      if (mounted && _selectedState != null) {
        final selectedCode = _selectedState!.stateCode;
        if (_citiesCache.containsKey(selectedCode)) {
          setState(() {
            _cities = _citiesCache[selectedCode]!;
            _isLoadingCities = false;
          });
        }
      }
    }
  }

  /// Fetches and displays cities based on the user's selected state.
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

      if (_selectedState?.stateCode != stateCode) return;

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
      setState(() => _isLoadingCities = false);
      _showMessage(
        title: 'Unable to load cities',
        message: _getReadableError(e),
        type: AppMessageType.error,
      );
    }
  }

  // Field Validation Helpers
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your $fieldName";
    }
    return null;
  }

  String? _validateGender() =>
      _selectedGender == null ? "Please select your gender" : null;

  String? _validateState() =>
      _selectedState == null ? "Please select your state" : null;

  String? _validateCity() =>
      _selectedCity == null ? "Please select your city" : null;

  /// Validates input and triggers account registration API request.
  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    _clearMessage();

    if (!_formKey.currentState!.validate()) return;

    final genderError = _validateGender();
    if (genderError != null) {
      _showMessage(
        title: 'Missing information',
        message: genderError,
        type: AppMessageType.warning,
      );
      return;
    }

    final stateError = _validateState();
    if (stateError != null) {
      _showMessage(
        title: 'Missing information',
        message: stateError,
        type: AppMessageType.warning,
      );
      return;
    }

    final cityError = _validateCity();
    if (cityError != null) {
      _showMessage(
        title: 'Missing information',
        message: cityError,
        type: AppMessageType.warning,
      );
      return;
    }

    if (_selectedState == null || _selectedCity == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final userModel = RegisterUserRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _selectedGender!,
        city: _selectedCity!.cityName,
        state: _selectedState!.stateName,
        stateCode: _selectedState!.stateCode,
        password: _passwordController.text,
      );

      final response = await ApiManager().client.registerUser(
        '/auth/register/user',
        userModel.toJson(),
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (response.success == true && response.data != null) {
        final data = response.data!;
        final account = data.account;

        await Prefs.setBool('isLoggedIn', true);
        await Prefs.setString('userRole', data.role ?? 'user');
        await Prefs.setString('authToken', data.token ?? '');
        await Prefs.setString('userEmail', account?.email ?? '');

        final firstName = account?.firstName ?? '';
        final lastName = account?.lastName ?? '';
        await Prefs.setString('userName', '$firstName $lastName'.trim());

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserMain()),
        );
      } else {
        _showMessage(
          title: 'Registration failed',
          message: response.error ?? 'Unable to create your account.',
          type: AppMessageType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showMessage(
        title: 'Something went wrong',
        message: _getReadableError(e),
        type: AppMessageType.error,
      );
    }
  }

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
                const AppBackButton(),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    "Create Account",
                    style: AppTextStyles.heading,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Join the EcoLoop community",
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ),
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
                        onPressed: () {},
                        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                        label: const Text("Add Photo"),
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
                _buildLabel("First Name"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _validateRequired(value, "first name"),
                  decoration: const InputDecoration(
                    hintText: "Enter your first name",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel("Last Name"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _validateRequired(value, "last name"),
                  decoration: const InputDecoration(
                    hintText: "Enter your last name",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel("Email"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => _validateRequired(value, "email"),
                  decoration: const InputDecoration(
                    hintText: "Enter your email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel("Phone Number"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      _validateRequired(value, "phone number"),
                  decoration: const InputDecoration(
                    hintText: "Enter your phone number",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                _buildLabel("Gender"),
                const SizedBox(height: 6),
                _buildGenderOption("Male"),
                _buildGenderOption("Female"),
                _buildGenderOption("Other"),
                const SizedBox(height: 20),
                _buildLabel("State"),
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
                  validator: (value) =>
                      value == null ? "Please select your state" : null,
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      hintText: _isLoadingStates
                          ? "Loading states..."
                          : "Select your state",
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
                        "Select State",
                        style: AppTextStyles.body.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: "Search state...",
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
                _buildLabel("City"),
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
                    setState(() => _selectedCity = value);
                  },
                  validator: (value) =>
                      value == null ? "Please select your city" : null,
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      hintText: _selectedState == null
                          ? "Select state first"
                          : _isLoadingCities
                          ? "Loading cities..."
                          : _cities.isEmpty
                          ? "No cities available"
                          : "Select your city",
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
                            ? "Select City"
                            : "Select City in ${_selectedState!.stateName}",
                        style: AppTextStyles.body.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: "Search city...",
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
                _buildLabel("Password"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (value) => _validateRequired(value, "password"),
                  decoration: InputDecoration(
                    hintText: "Create a password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _createAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text("Create Account", style: AppTextStyles.button),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: AppTextStyles.caption.copyWith(fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const UserLogin(title: "User Login"),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Login",
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ArtistIntro()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      "Become an Artist →",
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

  Widget _buildGenderOption(String value) {
    return SizedBox(
      height: 42,
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedGender,
        contentPadding: EdgeInsets.zero,
        dense: true,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        title: Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        activeColor: AppColors.primary,
        onChanged: (selectedValue) {
          setState(() => _selectedGender = selectedValue);
        },
      ),
    );
  }
}
