import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../models/location/city_model.dart';
import '../../../models/location/state_model.dart';
import '../../../services/ecoloop_api.dart';
import '../../../services/image_picker_service.dart';
import '../../../services/location_data_cache.dart';
import '../../../shared_preferences_util.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  List<StateModel> _states = [];
  List<CityModel> _cities = [];

  StateModel? _selectedState;
  CityModel? _selectedCity;

  String _savedState = '';
  String _savedCity = '';
  String _photoUrl = '';

  Uint8List? _photoBytes;

  bool _loadingProfile = false;
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  int _cityRequest = 0;

  @override
  void initState() {
    super.initState();

    // Show previously cached account details without waiting.
    _name.text = Prefs.getString('userName');
    _email.text = Prefs.getString('userEmail');
    _phone.text = Prefs.getString('userPhone');
    _savedState = Prefs.getString('userState');
    _savedCity = Prefs.getString('userCity');
    _photoUrl = Prefs.getString('profilePhotoUrl');

    _loadProfile();
    _loadStates();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _str(dynamic value) => value?.toString().trim() ?? '';

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  Map<String, dynamic> _unwrap(dynamic value) {
    final outer = _asMap(value);
    final data = _asMap(outer['data']);
    if (data.isNotEmpty) {
      final nested = _asMap(data['user']);
      return nested.isNotEmpty ? nested : data;
    }
    final user = _asMap(outer['user']);
    return user.isNotEmpty ? user : outer;
  }

  void _notice(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _errorText(Object error) {
    if (error is DioException) {
      final data = _asMap(error.response?.data);
      final nested = _asMap(data['error']);
      return _str(nested['message']).isNotEmpty
          ? _str(nested['message'])
          : _str(data['message']).isNotEmpty
          ? _str(data['message'])
          : 'Unable to connect to the backend.';
    }
    if (error is ImagePickerServiceException) {
      return error.message;
    }
    return error.toString();
  }

  Future<void> _loadProfile() async {
    if (_loadingProfile) return;
    setState(() => _loadingProfile = true);

    try {
      final response = await EcoLoopApi.instance.get('/auth/me');
      final data = _unwrap(response);

      if (data.isEmpty) {
        throw Exception('Profile data was not returned by the server.');
      }

      final firstName = _str(data['firstName']);
      final lastName = _str(data['lastName']);
      final fullName = _str(data['fullName']).isNotEmpty
          ? _str(data['fullName'])
          : _str(data['userName']).isNotEmpty
          ? _str(data['userName'])
          : '$firstName $lastName'.trim();

      if (!mounted) return;

      setState(() {
        _name.text = fullName;
        _email.text = _str(data['email']);
        _phone.text = _str(data['phone']).isNotEmpty
            ? _str(data['phone'])
            : _str(data['mobile']);

        _savedState = _str(data['state']);
        _savedCity = _str(data['city']);
        _photoUrl = _str(data['profilePhotoUrl']);

        _matchState();
      });

      await Future.wait([
        Prefs.setString('userName', fullName),
        Prefs.setString('userEmail', _email.text),
        Prefs.setString('userPhone', _phone.text),
        Prefs.setString('userState', _savedState),
        Prefs.setString('userCity', _savedCity),
        Prefs.setString('profilePhotoUrl', _photoUrl),
      ]);
    } catch (error) {
      _notice('Could not refresh profile: ${_errorText(error)}', error: true);
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadStates() async {
    if (!mounted) return;
    setState(() => _loadingStates = true);

    try {
      final states = await LocationDataCache.instance.getStates();

      if (!mounted) return;

      setState(() {
        _states = states;
        _matchState();
      });
    } catch (error) {
      if (mounted) {
        _notice('Unable to load states: ${_errorText(error)}', error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingStates = false);
      }
    }
  }

  void _matchState() {
    if (_savedState.isEmpty || _states.isEmpty) return;

    StateModel? match;
    for (final state in _states) {
      if (state.stateName.toLowerCase() == _savedState.toLowerCase() ||
          state.stateCode.toLowerCase() == _savedState.toLowerCase()) {
        match = state;
        break;
      }
    }

    if (match == null) return;

    final changed = _selectedState?.stateCode != match.stateCode;
    _selectedState = match;

    if (changed || _cities.isEmpty) {
      _loadCities(match.stateCode, preserveSavedCity: true);
    }
  }

  Future<void> _loadCities(
    String stateCode, {
    bool preserveSavedCity = false,
  }) async {
    final requestId = ++_cityRequest;

    if (!mounted) return;

    setState(() {
      _loadingCities = true;
      _cities = [];
      _selectedCity = null;
    });

    try {
      final cities = await LocationDataCache.instance.getCities(stateCode);

      if (!mounted || requestId != _cityRequest) return;

      CityModel? selected;

      if (preserveSavedCity) {
        for (final city in cities) {
          if (city.cityName.toLowerCase() == _savedCity.toLowerCase()) {
            selected = city;
            break;
          }
        }
      }

      setState(() {
        _cities = cities;
        _selectedCity = selected;
      });
    } catch (error) {
      if (mounted && requestId == _cityRequest) {
        _notice('Unable to load cities: ${_errorText(error)}', error: true);
      }
    } finally {
      if (mounted && requestId == _cityRequest) {
        setState(() => _loadingCities = false);
      }
    }
  }

  Future<void> _changePhoto(ImageSource source) async {
    if (_uploadingPhoto) return;

    setState(() => _uploadingPhoto = true);

    try {
      final result = await ImagePickerService.instance
          .pickAndUploadProfilePhoto(source: source);

      if (!mounted || result == null) return;

      await Prefs.setString('profilePhotoUrl', result.profilePhotoUrl);

      setState(() {
        _photoUrl = result.profilePhotoUrl;
        _photoBytes = result.bytes;
      });

      _notice('Profile picture updated successfully.');
    } catch (error) {
      _notice('Photo upload failed: ${_errorText(error)}', error: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 15),
            Text('Change Profile Photo', style: AppTextStyles.title),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _changePhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _changePhoto(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_saving || _uploadingPhoto) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final name = _name.text.trim();
    final parts = name.split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    // Preserve the sheet's existing location when no change was made.
    final state = _selectedState?.stateName ?? _savedState;
    final city = _selectedCity?.cityName ?? _savedCity;
    final stateCode = _selectedState?.stateCode ?? '';

    if (state.isEmpty || city.isEmpty) {
      _notice('Please select your state and city.', error: true);
      return;
    }

    setState(() => _saving = true);

    try {
      // Do not send email or mobile as editable fields.
      await ImagePickerService.instance.updateProfile(
        firstName: firstName,
        lastName: lastName,
        city: city,
        state: state,
        stateCode: stateCode,
        // The existing service requires phone; pass its unchanged value.
        phone: _phone.text.trim(),
      );

      await Future.wait([
        Prefs.setString('userName', name),
        Prefs.setString('userState', state),
        Prefs.setString('userCity', city),
      ]);

      if (!mounted) return;

      _notice('Profile saved successfully.');
      Navigator.pop(context, true);
    } catch (error) {
      _notice('Unable to save profile: ${_errorText(error)}', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.hint,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 19),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.accent.withOpacity(0.45)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: _decoration(label, icon).copyWith(
              suffixIcon: readOnly
                  ? const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 17,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 9),
          Text(title, style: AppTextStyles.title.copyWith(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _photo() {
    Widget image;

    if (_photoBytes != null) {
      image = Image.memory(
        _photoBytes!,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
      );
    } else if (_photoUrl.isNotEmpty) {
      image = Image.network(
        _photoUrl,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person_rounded,
          size: 46,
          color: AppColors.primary,
        ),
      );
    } else {
      image = const Icon(
        Icons.person_rounded,
        size: 46,
        color: AppColors.primary,
      );
    }

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 3),
                ),
                child: image,
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: GestureDetector(
                  onTap: _uploadingPhoto ? null : _showPhotoOptions,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.primary,
                    child: _uploadingPhoto
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            size: 17,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _uploadingPhoto ? 'Uploading photo...' : 'Profile Photo',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text('Tap the camera icon to change', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _stateDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownSearch<StateModel>(
        selectedItem: _selectedState,
        enabled: !_loadingStates && _states.isNotEmpty && !_saving,
        items: (filter, props) => _states,
        itemAsString: (item) => item.stateName,
        compareFn: (a, b) => a.stateCode == b.stateCode,
        onSelected: (value) {
          if (value == null) return;
          setState(() {
            _selectedState = value;
            _selectedCity = null;
            _savedState = value.stateName;
            _savedCity = '';
          });
          _loadCities(value.stateCode);
        },
        decoratorProps: DropDownDecoratorProps(
          decoration: _decoration(
            _loadingStates
                ? 'Loading states...'
                : _selectedState == null && _savedState.isNotEmpty
                ? _savedState
                : 'Select State',
            Icons.map_outlined,
          ),
        ),
        popupProps: PopupProps.modalBottomSheet(
          showSearchBox: true,
          searchDelay: Duration.zero,
        ),
      ),
    );
  }

  Widget _cityDropdown() {
    return DropdownSearch<CityModel>(
      selectedItem: _selectedCity,
      enabled:
          _selectedState != null &&
          !_loadingCities &&
          _cities.isNotEmpty &&
          !_saving,
      items: (filter, props) => _cities,
      itemAsString: (item) => item.cityName,
      compareFn: (a, b) => a.cityId == b.cityId,
      onSelected: (value) {
        setState(() {
          _selectedCity = value;
          _savedCity = value?.cityName ?? '';
        });
      },
      decoratorProps: DropDownDecoratorProps(
        decoration: _decoration(
          _loadingCities
              ? 'Loading cities...'
              : _selectedCity == null && _savedCity.isNotEmpty
              ? _savedCity
              : 'Select City',
          Icons.location_city_outlined,
        ),
      ),
      popupProps: PopupProps.modalBottomSheet(
        showSearchBox: true,
        searchDelay: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Edit Profile',
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                color: _saving ? AppColors.textSecondary : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_loadingProfile)
                  const LinearProgressIndicator(color: AppColors.primary),

                const SizedBox(height: 12),
                _photo(),
                const SizedBox(height: 30),

                _section('Personal Information', Icons.person_outline_rounded),

                _field(
                  'Full Name',
                  _name,
                  Icons.person_outline_rounded,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your full name'
                      : null,
                ),

                _field(
                  'Email Address',
                  _email,
                  Icons.email_outlined,
                  readOnly: true,
                ),

                _field(
                  'Mobile Number',
                  _phone,
                  Icons.phone_outlined,
                  readOnly: true,
                ),

                const SizedBox(height: 15),
                _section('Location', Icons.location_on_outlined),

                const Text(
                  'State',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _stateDropdown(),

                const Text(
                  'City',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                _cityDropdown(),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Email and mobile number cannot be edited here. '
                          'Your other profile details can be updated.',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
}
