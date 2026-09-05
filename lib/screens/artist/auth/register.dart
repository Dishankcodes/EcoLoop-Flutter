import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
import '../../../shared_preferences_util.dart';
import '../../../widgets/back_button.dart';
import '../../user/login.dart';
import '../artist_dashboard.dart';
import 'login.dart';

class ArtistRegister extends StatefulWidget {
  const ArtistRegister({super.key, required this.title});

  final String title;

  @override
  State<ArtistRegister> createState() => _ArtistRegisterState();
}

class _ArtistRegisterState extends State<ArtistRegister> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your $fieldName";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your password";
    }

    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  Future<void> _createArtistAccount() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedState == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select your state")));
      return;
    }

    await Prefs.setBool('isLoggedIn', true);
    await Prefs.setString('userRole', 'artist');
    await Prefs.setString('artistName', _nameController.text.trim());
    await Prefs.setString('artistEmail', _emailController.text.trim());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Congratulations! You are now an artist on EcoLoop."),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ArtistDashboard()),
      );
    });
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
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "Artist Registration",
                    style: AppTextStyles.heading,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Tell us about your creativity",
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                ),
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
                        label: const Text("Choose Photo"),
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
                _buildLabel("Your Name"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => _validateRequired(value, "name"),
                  decoration: const InputDecoration(
                    hintText: "Enter your name",
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
                _buildLabel("Bio"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: "Tell us about yourself and your creativity",
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 55),
                      child: Icon(Icons.description_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel("Skills"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _skillsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: "Example: Painting, Pottery, Woodwork",
                    prefixIcon: Icon(Icons.palette_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel("Experience"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Experience in years",
                    prefixIcon: Icon(Icons.work_outline),
                    suffixText: "Years",
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel("Certification"),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.attach_file_outlined),
                    label: const Text("Attach Certification"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel("Password"),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
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
                    onPressed: _createArtistAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Create Artist Account",
                      style: AppTextStyles.button,
                    ),
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
                                  const ArtistLogin(title: "Artist Login"),
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
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserLogin(title: "User Login"),
                        ),
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
                      "Become a User →",
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
}
