import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../services/image_picker_service.dart';
import '../../../shared_preferences_util.dart';

/// Edits the authenticated artist row in Google Sheets via PUT /profile.
/// State and city options are loaded from the States and Cities sheets.
/// Email is displayed from the backend and remains read-only.
class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _loadError;

  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _cities = [];
  String? _selectedStateCode;
  String? _selectedStateName;
  String? _selectedCityName;
  String _profilePhotoUrl = '';
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List)
      return value.map(_asMap).where((e) => e.isNotEmpty).toList();
    final map = _asMap(value);
    for (final key in ['states', 'cities', 'items', 'results', 'data']) {
      final nested = map[key];
      if (nested is List) {
        return nested.map(_asMap).where((e) => e.isNotEmpty).toList();
      }
    }
    return [];
  }

  String _text(dynamic value) => (value ?? '').toString().trim();

  String _stateCode(Map<String, dynamic> state) =>
      _text(state['stateCode'] ?? state['state_code']).toUpperCase();

  String _stateName(Map<String, dynamic> state) =>
      _text(state['stateName'] ?? state['state_name'] ?? state['name']);

  String _cityName(Map<String, dynamic> city) =>
      _text(city['cityName'] ?? city['city_name'] ?? city['name']);

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final values = await Future.wait<dynamic>([
        _api.get('/profile'),
        _api.get('/locations/states'),
      ]);
      final profile = _asMap(values[0]);
      final states = _asList(values[1]);

      if (profile.isEmpty) {
        throw const EcoLoopApiException(
          'Your artist profile was not returned by the backend.',
        );
      }

      _profile = profile;
      _nameController.text = _text(profile['userName']);
      _emailController.text = _text(profile['email']);
      _phoneController.text = _text(profile['phone']);
      _bioController.text = _text(profile['bio']);
      _skillsController.text = _text(profile['skills']);
      _experienceController.text = _text(profile['experience']);
      _profilePhotoUrl = _text(profile['profilePhotoUrl']);

      _states = states;
      final currentStateCode = _text(profile['stateCode']).toUpperCase();
      final currentStateName = _text(profile['state']);
      Map<String, dynamic>? matchedState;

      for (final state in _states) {
        if ((_stateCode(state).isNotEmpty &&
                _stateCode(state) == currentStateCode) ||
            (_stateName(state).isNotEmpty &&
                _stateName(state).toLowerCase() ==
                    currentStateName.toLowerCase())) {
          matchedState = state;
          break;
        }
      }

      if (matchedState != null) {
        _selectedStateCode = _stateCode(matchedState);
        _selectedStateName = _stateName(matchedState);
        await _loadCities(
          _selectedStateCode!,
          selectCityName: _text(profile['city']),
        );
      } else {
        // The saved text still came from the profile sheet, but it is not a
        // valid dropdown selection until it matches an active location row.
        _selectedStateCode = null;
        _selectedStateName = null;
        _selectedCityName = null;
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadCities(String stateCode, {String? selectCityName}) async {
    try {
      final result = await _api.get(
        '/locations/cities',
        query: {'stateCode': stateCode},
      );
      final cities = _asList(result);
      if (!mounted) return;
      setState(() {
        _cities = cities;
        final requestedCity = _text(selectCityName).toLowerCase();
        final match = _cities.where(
          (city) => _cityName(city).toLowerCase() == requestedCity,
        );
        if (requestedCity.isNotEmpty && match.isNotEmpty) {
          _selectedCityName = _cityName(match.first);
        } else if (selectCityName == null) {
          _selectedCityName = null;
        } else {
          // Only allow cities currently returned by the Cities sheet.
          _selectedCityName = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cities = []);
      _showMessage(
        'Unable to load cities. Please check the connection and try again.',
        isError: true,
      );
    }
  }

  Future<void> _selectState(String? stateCode) async {
    if (stateCode == null || stateCode.isEmpty) return;
    final matches = _states.where((state) => _stateCode(state) == stateCode);
    if (matches.isEmpty) return;
    final state = matches.first;
    setState(() {
      _selectedStateCode = stateCode;
      _selectedStateName = _stateName(state);
      _selectedCityName = null;
      _cities = [];
    });
    await _loadCities(stateCode);
  }

  Future<void> _changeProfilePhoto() async {
    if (_uploadingPhoto) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Update profile photo',
                  style: ArtistTextStyles.title,
                ),
              ),
              const SizedBox(height: 12),
              _PhotoOption(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              const SizedBox(height: 9),
              _PhotoOption(
                icon: Icons.camera_alt_outlined,
                label: 'Take a Photo',
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final result = await ImagePickerService.instance
          .pickAndUploadProfilePhoto(source: source);
      if (!mounted) return;
      if (result == null) {
        setState(() => _uploadingPhoto = false);
        return;
      }

      await Prefs.setString('profilePhotoUrl', result.profilePhotoUrl);
      setState(() {
        _photoBytes = result.bytes;
        _profilePhotoUrl = result.profilePhotoUrl;
        _uploadingPhoto = false;
      });
      _showMessage('Profile photo uploaded successfully.');
    } on ImagePickerServiceException catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      _showMessage(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      _showMessage(
        'Could not upload profile photo. ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStateCode == null ||
        _selectedStateName == null ||
        _selectedStateName!.isEmpty) {
      _showMessage('Please select a state.', isError: true);
      return;
    }
    if (_selectedCityName == null || _selectedCityName!.trim().isEmpty) {
      _showMessage('Please select a city.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final response = await _api.put('/profile', {
        'userName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _selectedCityName!.trim(),
        'state': _selectedStateName!.trim(),
        'stateCode': _selectedStateCode!.trim().toUpperCase(),
        'bio': _bioController.text.trim(),
        'skills': _skillsController.text.trim(),
        'experience': _experienceController.text.trim(),
      });

      final updated = _asMap(response);
      if (updated.isNotEmpty) {
        _profile = updated;
      }

      await Prefs.setString('userName', _nameController.text.trim());
      await Prefs.setString('userEmail', _emailController.text.trim());
      if (_profilePhotoUrl.isNotEmpty) {
        await Prefs.setString('profilePhotoUrl', _profilePhotoUrl);
      }

      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Artist profile updated successfully.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        'Could not save profile. ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? ArtistColors.error : ArtistColors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _saveProfile,
            child: Text(
              'Save',
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: _saving || _loading
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
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: ArtistColors.primary),
              )
            : _loadError != null
            ? _LoadError(message: _loadError!, onRetry: _loadInitialData)
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfilePhoto(),
                      const SizedBox(height: 30),
                      _sectionTitle(
                        'Personal Information',
                        Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _nameController,
                        label: 'Artist / Studio Name',
                        hint: 'Enter your artist name',
                        icon: Icons.person_outline_rounded,
                        capitalization: TextCapitalization.words,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Please enter your artist name.'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      _emailField(),
                      const SizedBox(height: 15),
                      _textField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          final phone = (value ?? '').trim();
                          if (phone.isEmpty)
                            return 'Please enter your phone number.';
                          if (phone.length < 8)
                            return 'Please enter a valid phone number.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      _sectionTitle(
                        'Artist Information',
                        Icons.palette_outlined,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: _bioController,
                        label: 'Bio',
                        hint: 'Tell people about yourself and your work',
                        icon: Icons.edit_note_rounded,
                        maxLines: 4,
                        maxLength: 300,
                        capitalization: TextCapitalization.sentences,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Please enter a short bio.'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      _textField(
                        controller: _skillsController,
                        label: 'Skills',
                        hint: 'e.g. Painting, Upcycling, Woodwork',
                        icon: Icons.auto_awesome_outlined,
                        maxLines: 2,
                        capitalization: TextCapitalization.words,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Please add at least one skill.'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      _textField(
                        controller: _experienceController,
                        label: 'Experience',
                        hint: 'e.g. 3 years',
                        icon: Icons.workspace_premium_outlined,
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Please add your experience.'
                            : null,
                      ),
                      const SizedBox(height: 30),
                      _sectionTitle('Location', Icons.location_on_outlined),
                      const SizedBox(height: 8),
                      Text(
                        'Choose a state and city from the location data maintained in Google Sheets.',
                        style: ArtistTextStyles.caption,
                      ),
                      const SizedBox(height: 14),
                      _stateDropdown(),
                      const SizedBox(height: 14),
                      _cityDropdown(),
                      const SizedBox(height: 24),
                      _informationCard(),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ArtistColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: ArtistColors.primary
                                .withOpacity(0.55),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _saving
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
                                    Text(
                                      'Save Changes',
                                      style: ArtistTextStyles.button,
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

  Widget _buildProfilePhoto() {
    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  shape: BoxShape.circle,
                  border: Border.all(color: ArtistColors.accent, width: 3),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photoBytes != null
                    ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                    : _profilePhotoUrl.isNotEmpty
                    ? Image.network(
                        _profilePhotoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_rounded,
                          color: ArtistColors.primary,
                          size: 48,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        color: ArtistColors.primary,
                        size: 48,
                      ),
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: GestureDetector(
                  onTap: _uploadingPhoto ? null : _changeProfilePhoto,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: ArtistColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: ArtistColors.surface, width: 3),
                    ),
                    child: _uploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
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
            _uploadingPhoto
                ? 'Uploading to your EcoLoop profile...'
                : 'Tap the camera icon to choose a photo',
            style: ArtistTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ArtistTextStyles.label.copyWith(fontSize: 12)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          style: ArtistTextStyles.bodyMedium.copyWith(
            color: ArtistColors.textPrimary,
          ),
          decoration: _decoration(hint, icon: icon, multiline: maxLines > 1),
        ),
      ],
    );
  }

  Widget _emailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: ArtistTextStyles.label.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: _emailController,
          readOnly: true,
          keyboardType: TextInputType.emailAddress,
          style: ArtistTextStyles.bodyMedium.copyWith(
            color: ArtistColors.textSecondary,
          ),
          decoration:
              _decoration(
                'Email address',
                icon: Icons.email_outlined,
                readOnly: true,
              ).copyWith(
                suffixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: ArtistColors.textMuted,
                  size: 17,
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
              'Email is loaded from your account and cannot be edited here.',
              style: ArtistTextStyles.small,
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _decoration(
    String hint, {
    required IconData icon,
    bool multiline = false,
    bool readOnly = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: ArtistTextStyles.hint,
      prefixIcon: Padding(
        padding: EdgeInsets.only(bottom: multiline ? 35 : 0),
        child: Icon(
          icon,
          color: readOnly ? ArtistColors.textSecondary : ArtistColors.primary,
          size: 19,
        ),
      ),
      counterStyle: ArtistTextStyles.small.copyWith(fontSize: 9),
      filled: true,
      fillColor: readOnly ? ArtistColors.surfaceSoft : ArtistColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: ArtistColors.primary, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ArtistColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ArtistColors.error, width: 1.3),
      ),
    );
  }

  Widget _stateDropdown() {
    final selectedCode =
        _states.any((state) => _stateCode(state) == _selectedStateCode)
        ? _selectedStateCode
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('State', style: ArtistTextStyles.label.copyWith(fontSize: 12)),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: selectedCode,
          isExpanded: true,
          decoration: _decoration('Select state', icon: Icons.map_outlined),
          items: _states
              .where((state) => _stateCode(state).isNotEmpty)
              .map(
                (state) => DropdownMenuItem<String>(
                  value: _stateCode(state),
                  child: Text(
                    _stateName(state),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: _saving ? null : _selectState,
          validator: (_) =>
              _selectedStateCode == null ? 'Please select a state.' : null,
        ),
      ],
    );
  }

  Widget _cityDropdown() {
    final selectedCity =
        _cities.any((city) => _cityName(city) == _selectedCityName)
        ? _selectedCityName
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('City', style: ArtistTextStyles.label.copyWith(fontSize: 12)),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          value: selectedCity,
          isExpanded: true,
          decoration: _decoration(
            'Select city',
            icon: Icons.location_city_outlined,
          ),
          items: _cities
              .map(
                (city) => DropdownMenuItem<String>(
                  value: _cityName(city),
                  child: Text(_cityName(city), overflow: TextOverflow.ellipsis),
                ),
              )
              .where((item) => item.value != null && item.value!.isNotEmpty)
              .toList(),
          onChanged: _saving || _selectedStateCode == null
              ? null
              : (value) => setState(() => _selectedCityName = value),
          validator: (_) =>
              _selectedCityName == null ? 'Please select a city.' : null,
        ),
      ],
    );
  }

  Widget _informationCard() {
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
              'Your details are saved to your artist record in Google Sheets. Your profile photo is uploaded to EcoLoop Drive and its URL is saved to the same record. Email is read-only.',
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
}

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: ArtistColors.background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: ArtistColors.border.withOpacity(0.7)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: ArtistColors.primary),
            const SizedBox(width: 10),
            Text(
              label,
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: ArtistColors.textPrimary,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: ArtistColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: ArtistColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
