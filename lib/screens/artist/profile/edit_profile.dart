import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../models/location/city_model.dart';
import '../../../models/location/state_model.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  // Input controllers with initial default values
  final TextEditingController _nameController = TextEditingController(
    text: 'Creative Studio',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'artist@ecoloop.com',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '+91 98765 43210',
  );
  final TextEditingController _bioController = TextEditingController(
    text: 'Turning reusable materials into beautiful, meaningful creations.',
  );
  final TextEditingController _skillsController = TextEditingController(
    text: 'Upcycling, Woodwork, Home Decor',
  );
  final TextEditingController _experienceController = TextEditingController(
    text: '3 years',
  );

  // Initial location fallback names and model references
  String? _initialStateName = 'Gujarat';
  String? _initialCityName = 'Ahmedabad';
  StateModel? _selectedState;
  CityModel? _selectedCity;

  // Active state/city lists and loading flags
  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  bool _isSaving = false;

  // In-memory cache and request deduplication map for location API responses
  final Map<String, List<CityModel>> _citiesCache = {};
  final Map<String, Future<List<CityModel>>> _cityLoadingFutures = {};

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  @override
  void dispose() {
    // Clean up input controllers when widget is unmounted
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // Parses API and connection errors into user-friendly error messages
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

  // Fetches available states from the API and auto-selects initial state
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

          if (_initialStateName != null && _states.isNotEmpty) {
            try {
              _selectedState = _states.firstWhere(
                (state) =>
                    state.stateName.toLowerCase() ==
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
        setState(() {
          _isLoadingStates = false;
        });

        _showErrorMessage(
          'Unable to load states',
          response.error ?? 'Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingStates = false;
      });

      _showErrorMessage('Unable to load states', _getReadableError(e));
    }
  }

  // Returns cached cities or initiates a new network fetch if uncached
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

  // Executes the API call to retrieve cities for a given state code
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

  // Prefetches city lists in parallel background batches for quick switching
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

  // Loads city options for a target state and resolves initial selection
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
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingCities = false;
      });
    }
  }

  // Matches initial city name string against loaded city models
  void _matchAndSetInitialCity() {
    if (_initialCityName != null && _cities.isNotEmpty) {
      try {
        _selectedCity = _cities.firstWhere(
          (city) =>
              city.cityName.toLowerCase() == _initialCityName!.toLowerCase(),
        );
      } catch (_) {
        _selectedCity = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
        ),
        title: Text(
          'Edit Profile',
          style: ArtistTextStyles.title.copyWith(fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              'Save',
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: _isSaving
                    ? ArtistColors.textMuted
                    : ArtistColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfilePhoto(),
              const SizedBox(height: 30),
              _buildSectionTitle(
                'Personal Information',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _nameController,
                label: 'Artist Name',
                hint: 'Enter your artist name',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 15),
              _buildEmailField(),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                hint: 'Tell people about yourself and your work',
                icon: Icons.edit_note_rounded,
                maxLines: 5,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('Artist Information', Icons.palette_outlined),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _skillsController,
                label: 'Skills',
                hint: 'e.g. Painting, Upcycling, Woodwork',
                icon: Icons.auto_awesome_outlined,
                maxLines: 3,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _experienceController,
                label: 'Experience',
                hint: 'e.g. 3 years',
                icon: Icons.workspace_premium_outlined,
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('Location', Icons.location_on_outlined),
              const SizedBox(height: 8),
              Text(
                'Update the state and city associated with your artist profile.',
                style: ArtistTextStyles.caption,
              ),
              const SizedBox(height: 14),
              _buildStateDropdown(),
              const SizedBox(height: 14),
              _buildCityDropdown(),
              const SizedBox(height: 30),
              _buildInformationCard(),
              const SizedBox(height: 30),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Renders profile photo avatar along with edit camera badge
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
                  color: ArtistColors.light,
                  shape: BoxShape.circle,
                  border: Border.all(color: ArtistColors.accent, width: 3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: ArtistColors.primary,
                    size: 44,
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
                      color: ArtistColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: ArtistColors.surface, width: 3),
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
            style: ArtistTextStyles.bodyMedium.copyWith(
              color: ArtistColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Tap the camera icon to change',
            style: ArtistTextStyles.caption,
          ),
        ],
      ),
    );
  }

  // Form section header icon and label builder
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: ArtistColors.light,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: ArtistColors.primary),
        ),
        const SizedBox(width: 9),
        Text(title, style: ArtistTextStyles.title.copyWith(fontSize: 16)),
      ],
    );
  }

  // Custom formatted text input field builder
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
        Text(label, style: ArtistTextStyles.label.copyWith(fontSize: 12)),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          maxLength: maxLength,
          style: ArtistTextStyles.bodyMedium.copyWith(
            color: ArtistColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ArtistTextStyles.hint,
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: maxLines > 1 ? 45 : 0),
              child: Icon(icon, color: ArtistColors.primary, size: 19),
            ),
            counterStyle: ArtistTextStyles.small.copyWith(fontSize: 9),
            filled: true,
            fillColor: ArtistColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: ArtistColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: ArtistColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: ArtistColors.primary,
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Read-only user email field with lock badge indicator
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: ArtistTextStyles.label.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _emailController,
          readOnly: true,
          keyboardType: TextInputType.emailAddress,
          style: ArtistTextStyles.bodyMedium.copyWith(
            color: ArtistColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: 'Email address',
            hintStyle: ArtistTextStyles.hint,
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: ArtistColors.textSecondary,
              size: 19,
            ),
            suffixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: ArtistColors.textMuted,
              size: 17,
            ),
            filled: true,
            fillColor: ArtistColors.surfaceSoft,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: ArtistColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: ArtistColors.border),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 13,
              color: ArtistColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              'Email address cannot be changed here.',
              style: ArtistTextStyles.small,
            ),
          ],
        ),
      ],
    );
  }

  // Searchable state selection dropdown sheet widget
  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('State', style: ArtistTextStyles.label.copyWith(fontSize: 12)),
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
              hintText: _isLoadingStates ? 'Loading states...' : 'Select state',
              prefixIcon: const Icon(
                Icons.map_outlined,
                color: ArtistColors.primary,
                size: 19,
              ),
              filled: true,
              fillColor: ArtistColors.surface,
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ArtistColors.primary,
                        ),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: ArtistColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: ArtistColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: ArtistColors.primary,
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
                'Select State',
                style: ArtistTextStyles.body.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.textPrimary,
                ),
              ),
            ),
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search state...',
                hintStyle: ArtistTextStyles.hint,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: ArtistColors.primary,
                ),
                filled: true,
                fillColor: ArtistColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ArtistColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ArtistColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ArtistColors.primary),
                ),
              ),
            ),
            itemBuilder: (context, state, isDisabled, isSelected) {
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
      ],
    );
  }

  // Searchable city selection dropdown sheet widget based on active state
  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('City', style: ArtistTextStyles.label.copyWith(fontSize: 12)),
        const SizedBox(height: 7),
        DropdownSearch<CityModel>(
          selectedItem: _selectedCity,
          enabled:
              _selectedState != null && !_isLoadingCities && _cities.isNotEmpty,
          items: (filter, loadProps) => _cities,
          itemAsString: (CityModel city) => city.cityName,
          compareFn: (CityModel a, CityModel b) => a.cityId == b.cityId,
          onSelected: (CityModel? value) {
            setState(() {
              _selectedCity = value;
            });
          },
          decoratorProps: DropDownDecoratorProps(
            decoration: InputDecoration(
              hintText: _selectedState == null
                  ? 'Select state first'
                  : _isLoadingCities
                  ? 'Loading cities...'
                  : _cities.isEmpty
                  ? 'No cities available'
                  : 'Select city',
              prefixIcon: const Icon(
                Icons.location_city_outlined,
                color: ArtistColors.primary,
                size: 19,
              ),
              filled: true,
              fillColor: ArtistColors.surface,
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ArtistColors.primary,
                        ),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: ArtistColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: ArtistColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: ArtistColors.primary,
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
                    ? 'Select City'
                    : 'Select City in ${_selectedState!.stateName}',
                style: ArtistTextStyles.body.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.textPrimary,
                ),
              ),
            ),
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search city...',
                hintStyle: ArtistTextStyles.hint,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: ArtistColors.primary,
                ),
                filled: true,
                fillColor: ArtistColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ArtistColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ArtistColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ArtistColors.primary),
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
      ],
    );
  }

  // Information banner component highlighting profile visibility
  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ArtistColors.light.withOpacity(0.30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.secondary.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: ArtistColors.primary,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Your profile information helps customers understand your work and discover your ReMaker profile.',
              style: ArtistTextStyles.small.copyWith(
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Primary profile save button with integrated loading state
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: ArtistColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ArtistColors.primary.withOpacity(0.55),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 19),
                  const SizedBox(width: 7),
                  Text('Save Changes', style: ArtistTextStyles.button),
                ],
              ),
      ),
    );
  }

  // Bottom modal sheet trigger for profile image choices
  void _changeProfilePhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
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
                    color: ArtistColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Profile Photo', style: ArtistTextStyles.title),
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

  // Reusable action row item builder for photo bottom sheet options
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
              ? ArtistColors.error.withOpacity(0.05)
              : ArtistColors.background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: destructive
                ? ArtistColors.error.withOpacity(0.2)
                : ArtistColors.border.withOpacity(0.7),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: destructive ? ArtistColors.error : ArtistColors.primary,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: destructive
                    ? ArtistColors.error
                    : ArtistColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: destructive
                  ? ArtistColors.error
                  : ArtistColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // Form field validation and save handler
  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final bio = _bioController.text.trim();
    final skills = _skillsController.text.trim();
    final experience = _experienceController.text.trim();

    if (name.isEmpty) {
      _showValidationMessage('Please enter your artist name.');
      return;
    }
    if (phone.isEmpty) {
      _showValidationMessage('Please enter your phone number.');
      return;
    }
    if (bio.isEmpty) {
      _showValidationMessage('Please enter your bio.');
      return;
    }
    if (skills.isEmpty) {
      _showValidationMessage('Please enter your skills.');
      return;
    }
    if (experience.isEmpty) {
      _showValidationMessage('Please enter your experience.');
      return;
    }
    if (_selectedState == null) {
      _showValidationMessage('Please select your state.');
      return;
    }
    if (_selectedCity == null) {
      _showValidationMessage('Please select your city.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context);
  }

  // Displays floating warning notifications for input validation
  void _showValidationMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ArtistColors.warning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Displays API error message dialog/snackbar
  void _showErrorMessage(String title, String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: ArtistColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Displays placeholder notification for upcoming feature connections
  void _showComingSoon(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
