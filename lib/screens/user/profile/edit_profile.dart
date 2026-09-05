import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
import '../../../models/location/city_model.dart';
import '../../../models/location/state_model.dart';
import '../../../widgets/app_message.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _nameController = TextEditingController(
    text: 'Dishank Prajapati',
  );

  final TextEditingController _emailController = TextEditingController(
    text: 'dishank@example.com',
  );

  final TextEditingController _phoneController = TextEditingController(
    text: '+91 98765 43210',
  );

  final TextEditingController _bioController = TextEditingController(
    text: 'EcoLoop user who believes unused things deserve a new life.',
  );

  // ============================================================
  // LOCATION & PREFERENCES
  // ============================================================

  String? _initialStateName = 'Gujarat';
  String? _initialCityName = 'Ahmedabad';

  StateModel? _selectedState;
  CityModel? _selectedCity;

  List<StateModel> _states = [];
  List<CityModel> _cities = [];

  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  bool _isSaving = false;

  final Map<String, List<CityModel>> _citiesCache = {};
  final Map<String, Future<List<CityModel>>> _cityLoadingFutures = {};

  String _selectedCategory = 'Furniture';
  bool _showPhoneNumber = false;

  // Application Message Notification State
  String? _message;
  String? _messageTitle;
  AppMessageType? _messageType;

  final List<String> _categories = [
    'Furniture',
    'Decor',
    'Electronics',
    'Materials',
    'Fashion',
    'Books',
  ];

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
    super.dispose();
  }

  // ============================================================
  // MESSAGE HELPERS
  // ============================================================

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
      return 'Unable to process request. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  // ============================================================
  // LOCATION API & CACHING
  // ============================================================

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

          if (_initialStateName != null && _states.isNotEmpty) {
            try {
              _selectedState = _states.firstWhere(
                (s) =>
                    s.stateName.toLowerCase() ==
                    _initialStateName!.toLowerCase(),
              );
            } catch (_) {
              _selectedState = _states.first;
            }
          }
        });

        if (_selectedState != null) {
          await _loadCities(_selectedState!.stateCode);
        }

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

  Future<void> _loadCities(String stateCode) async {
    if (!mounted) return;

    final cachedCities = _citiesCache[stateCode];
    if (cachedCities != null) {
      setState(() {
        _cities = cachedCities;
        _isLoadingCities = false;
        _matchAndSetInitialCity();
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
          _matchAndSetInitialCity();
        });
      } else {
        setState(() {
          _cities = [];
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCities = false);
    }
  }

  void _matchAndSetInitialCity() {
    if (_initialCityName != null && _cities.isNotEmpty) {
      try {
        _selectedCity = _cities.firstWhere(
          (c) => c.cityName.toLowerCase() == _initialCityName!.toLowerCase(),
        );
      } catch (_) {
        _selectedCity = null;
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          'Edit Profile',
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? AppColors.textSecondary : AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_message != null &&
                  _messageTitle != null &&
                  _messageType != null) ...[
                AppMessage(
                  title: _messageTitle!,
                  message: _message!,
                  type: _messageType!,
                  onClose: _clearMessage,
                ),
                const SizedBox(height: 16),
              ],

              _buildProfilePhoto(),

              const SizedBox(height: 28),

              _buildSectionTitle(
                'Personal Information',
                Icons.person_outline_rounded,
              ),

              const SizedBox(height: 12),

              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'Enter your email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _bioController,
                label: 'About You',
                hint: 'Tell people a little about yourself',
                icon: Icons.edit_note_rounded,
                maxLines: 4,
                maxLength: 150,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 28),

              _buildSectionTitle('Location', Icons.location_on_outlined),

              const SizedBox(height: 12),

              _buildStateDropdown(),

              const SizedBox(height: 14),

              _buildCityDropdown(),

              const SizedBox(height: 28),

              _buildSectionTitle('Marketplace Preferences', Icons.tune_rounded),

              const SizedBox(height: 12),

              _buildPreferredCategory(),

              const SizedBox(height: 14),

              _buildPrivacyOption(),

              const SizedBox(height: 28),

              _buildAccountInformation(),

              const SizedBox(height: 30),

              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION DROPDOWNS
  // ============================================================

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'State',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        DropdownSearch<StateModel>(
          selectedItem: _selectedState,
          enabled: !_isLoadingStates && _states.isNotEmpty,
          items: (filter, loadProps) => _states,
          itemAsString: (StateModel state) => state.stateName,
          compareFn: (StateModel a, StateModel b) => a.stateCode == b.stateCode,
          onSelected: (StateModel? value) {
            if (value == null) return;
            setState(() {
              _selectedState = value;
              _selectedCity = null;
              _initialCityName = null;
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
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: _isLoadingStates ? "Loading states..." : "Select state",
              prefixIcon: const Icon(
                Icons.map_outlined,
                color: AppColors.primary,
                size: 19,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              suffixIcon: _isLoadingStates
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.accent.withOpacity(0.45),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.accent.withOpacity(0.45),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.3,
                ),
              ),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'City',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        DropdownSearch<CityModel>(
          selectedItem: _selectedCity,
          enabled:
              _selectedState != null && !_isLoadingCities && _cities.isNotEmpty,
          items: (filter, loadProps) => _cities,
          itemAsString: (CityModel city) => city.cityName,
          compareFn: (CityModel a, CityModel b) => a.cityId == b.cityId,
          onSelected: (CityModel? value) {
            setState(() => _selectedCity = value);
          },
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: _selectedState == null
                  ? "Select state first"
                  : _isLoadingCities
                  ? "Loading cities..."
                  : _cities.isEmpty
                  ? "No cities available"
                  : "Select city",
              prefixIcon: const Icon(
                Icons.location_city_outlined,
                color: AppColors.primary,
                size: 19,
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              suffixIcon: _isLoadingCities
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.accent.withOpacity(0.45),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.accent.withOpacity(0.45),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.3,
                ),
              ),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE PHOTO
  // ============================================================

  Widget _buildProfilePhoto() {
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 3),
                ),
                child: const Center(
                  child: Text(
                    'D',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              Positioned(
                right: -2,
                bottom: 2,
                child: GestureDetector(
                  onTap: _changeProfilePhoto,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Profile Photo',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 3),

          Text('Tap the camera icon to change', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),

        const SizedBox(width: 9),

        Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
      ],
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          maxLength: maxLength,

          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.hint,

            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: maxLines > 1 ? 40 : 0),
              child: Icon(icon, color: AppColors.primary, size: 19),
            ),

            counterStyle: AppTextStyles.caption.copyWith(fontSize: 9),

            filled: true,
            fillColor: AppColors.surface,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.accent.withOpacity(0.45)),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.accent.withOpacity(0.45)),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.3,
              ),
            ),
          ),

          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PREFERRED CATEGORY
  // ============================================================

  Widget _buildPreferredCategory() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.category_outlined,
                size: 19,
                color: AppColors.primary,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferred Category',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Used to personalize marketplace suggestions.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _categories.map((category) {
              final selected = _selectedCategory == category;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.accent.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRIVACY OPTION
  // ============================================================

  Widget _buildPrivacyOption() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_outlined,
              color: AppColors.primary,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show phone number',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Allow buyers to see your phone number on listings.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          Switch.adaptive(
            value: _showPhoneNumber,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _showPhoneNumber = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCOUNT INFORMATION
  // ============================================================

  Widget _buildAccountInformation() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 19,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              'Your email and phone number are used for account communication and order updates. You can manage account security from Settings.',
              style: AppTextStyles.caption.copyWith(fontSize: 10, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 19),
                  SizedBox(width: 7),
                  Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }

  // CHANGE PHOTO

  void _changeProfilePhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Profile Photo', style: AppTextStyles.title),
                ),

                const SizedBox(height: 14),

                _photoOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon(
                      'Gallery selection will be connected later.',
                    );
                  },
                ),

                const SizedBox(height: 9),

                _photoOption(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take a Photo',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Camera will be connected later.');
                  },
                ),

                const SizedBox(height: 9),

                _photoOption(
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove Photo',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Photo removal will be connected later.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photoOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.error.withOpacity(0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: destructive
                ? AppColors.error.withOpacity(0.2)
                : AppColors.accent.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: destructive ? AppColors.error : AppColors.primary,
            ),

            const SizedBox(width: 10),

            Text(
              title,
              style: TextStyle(
                color: destructive ? AppColors.error : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: destructive ? AppColors.error : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // SAVE PROFILE

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    _clearMessage();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        title: 'Validation Error',
        message: 'Please enter your full name.',
        type: AppMessageType.warning,
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      _showMessage(
        title: 'Validation Error',
        message: 'Please enter a valid email address.',
        type: AppMessageType.warning,
      );
      return;
    }

    if (phone.isEmpty) {
      _showMessage(
        title: 'Validation Error',
        message: 'Please enter your phone number.',
        type: AppMessageType.warning,
      );
      return;
    }

    if (_selectedState == null) {
      _showMessage(
        title: 'Validation Error',
        message: 'Please select your state.',
        type: AppMessageType.warning,
      );
      return;
    }

    if (_selectedCity == null) {
      _showMessage(
        title: 'Validation Error',
        message: 'Please select your city.',
        type: AppMessageType.warning,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Perform save API call logic here as needed
      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(
        title: 'Save Failed',
        message: _getReadableError(e),
        type: AppMessageType.error,
      );
    }
  }

  void _showComingSoon(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
