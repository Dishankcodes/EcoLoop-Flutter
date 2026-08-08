import 'package:flutter/material.dart';

import '../../app_theme/app_colors.dart';
import '../../app_theme/app_text_styles.dart';
import '../../widgets/back_button.dart';
import '../artist/artist_intro.dart';
import 'login.dart';

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
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedGender;
  String? _selectedState;

  bool _obscurePassword = true;

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
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
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

              // ==========================================
              // SUBTITLE
              // ==========================================
              Center(
                child: Text(
                  "Join the EcoLoop community",
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 28),

              // ==========================================
              // PROFILE PHOTO
              // ==========================================
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

              // ==========================================
              // FIRST NAME
              // ==========================================
              _buildLabel("First Name"),

              const SizedBox(height: 8),

              TextField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: "Enter your first name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // LAST NAME
              // ==========================================
              _buildLabel("Last Name"),

              const SizedBox(height: 8),

              TextField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: "Enter your last name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // EMAIL
              // ==========================================
              _buildLabel("Email"),

              const SizedBox(height: 8),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "Enter your email",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // PHONE
              // ==========================================
              _buildLabel("Phone Number"),

              const SizedBox(height: 8),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "Enter your phone number",
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),

              const SizedBox(height: 24),

              // ==========================================
              // GENDER
              // ==========================================
              _buildLabel("Gender"),

              const SizedBox(height: 6),

              _buildGenderOption("Male"),

              _buildGenderOption("Female"),

              _buildGenderOption("Other"),

              const SizedBox(height: 20),

              // ==========================================
              // ADDRESS
              // ==========================================
              _buildLabel("Address"),

              const SizedBox(height: 8),

              TextField(
                controller: _addressController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: "Enter your address",
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 35),
                    child: Icon(Icons.location_on_outlined),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // STATE
              // ==========================================
              _buildLabel("State"),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _selectedState,
                isExpanded: true,

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

              // ==========================================
              // PASSWORD
              // ==========================================
              _buildLabel("Password"),

              const SizedBox(height: 8),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,

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

              // ==========================================
              // CREATE ACCOUNT BUTTON
              // ==========================================
              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton(
                  onPressed: () {},

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

              // ==========================================
              // LOGIN
              // ==========================================
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

              // ==========================================
              // ARTIST
              // ==========================================
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

              // ==========================================
              // BOTTOM SPACE
              // ==========================================
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LABEL
  // ==========================================================

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

  // ==========================================================
  // GENDER RADIO OPTION
  // ==========================================================

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
