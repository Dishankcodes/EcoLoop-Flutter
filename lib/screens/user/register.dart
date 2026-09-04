import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../api/api_manager.dart';
import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../../models/auth/user_register_model.dart';
import '../../shared_preferences_util.dart';
import '../../widgets/app_message.dart';
import '../../widgets/back_button.dart';
import '../artist/artist_intro.dart';
import 'login.dart';
import 'user_home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.title});

  final String title;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _message;
  String? _messageTitle;
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

  String _getReadableError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout) {
        return 'Connection timed out. Please check your internet connection.';
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

      return 'Unable to complete Register. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  String? _selectedGender;
  String? _selectedState;

  bool _obscurePassword = true;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> _states = [
    "Andhra Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Delhi",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Tamil Nadu",
    "Telangana",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your $fieldName";
    }
    return null;
  }

  String? _validateGender() {
    if (_selectedGender == null) {
      return "Please select your gender";
    }
    return null;
  }

  String? _validateState() {
    if (_selectedState == null) {
      return "Please select your state";
    }
    return null;
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    _clearMessage();

    if (!_formKey.currentState!.validate()) {
      return;
    }

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
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _selectedState!,
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

        // ----------------------------------------------------------
        // SAVE USER SESSION
        // ----------------------------------------------------------

        await Prefs.setBool('isLoggedIn', true);

        await Prefs.setString('userRole', data.role ?? 'user');

        await Prefs.setString('authToken', data.token ?? '');

        await Prefs.setString('userEmail', account?.email ?? '');

        final firstName = account?.firstName ?? '';
        final lastName = account?.lastName ?? '';

        await Prefs.setString('userName', '$firstName $lastName'.trim());

        // ----------------------------------------------------------
        // GO TO HOME
        // ----------------------------------------------------------

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserHome()),
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
                _buildLabel("Address"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => _validateRequired(value, "address"),
                  decoration: const InputDecoration(
                    hintText: "Enter your address",
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 35),
                      child: Icon(Icons.location_on_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel("City"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _validateRequired(value, "city"),
                  decoration: const InputDecoration(
                    hintText: "Enter your city",
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel("State"),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedState,
                  isExpanded: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please select your state";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: "Select your state",
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: _states.map((state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedState = value;
                    });
                  },
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
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
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
          setState(() {
            _selectedGender = selectedValue;
          });
        },
      ),
    );
  }
}
