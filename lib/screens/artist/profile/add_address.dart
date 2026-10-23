import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../models/location/city_model.dart';
import '../../../models/location/state_model.dart';
import '../../../services/location_data_cache.dart';
import '../../../shared_preferences_util.dart';

class AddAddress extends StatefulWidget {
  final Map<String, dynamic>? address;

  const AddAddress({super.key, this.address});

  bool get isEditing => address != null;

  @override
  State<AddAddress> createState() => _AddAddressState();
}

class _AddAddressState extends State<AddAddress> {
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbzvHq06GwL_I8qH2IPyQP36dRlESN62PYF4Ak5WkRE2VjHL5a-tr0Yk_KEtSvU_ZL6IbQ/exec';

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _houseController;
  late final TextEditingController _streetController;
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _pincodeController;

  List<StateModel> _states = [];
  List<CityModel> _cities = [];
  final Map<String, List<CityModel>> _citiesCache = {};
  StateModel? _selectedState;
  CityModel? _selectedCity;
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  String? _initialStateName;
  String? _initialCityName;

  String _addressType = 'Studio';
  bool _isDefault = false;
  bool _isSaving = false;

  String get _token {
    final role = Prefs.getString('userRole').toLowerCase().trim();
    return (role == 'artist'
            ? Prefs.getString('artistToken')
            : Prefs.getString('authToken'))
        .trim();
  }

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _nameController = TextEditingController(text: _value(a, 'name'));
    _phoneController = TextEditingController(text: _value(a, 'phone'));
    _houseController = TextEditingController(text: _value(a, 'house'));
    _streetController = TextEditingController(text: _value(a, 'street'));
    _areaController = TextEditingController(text: _value(a, 'area'));
    _landmarkController = TextEditingController(text: _value(a, 'landmark'));
    _initialStateName = _value(a, 'state').isNotEmpty
        ? _value(a, 'state')
        : null;
    _initialCityName = _value(a, 'city').isNotEmpty ? _value(a, 'city') : null;
    _loadLocationAndProfile();
    _pincodeController = TextEditingController(text: _value(a, 'pincode'));
    _addressType = _value(a, 'type').isEmpty ? 'Studio' : _value(a, 'type');
    _isDefault =
        a?['isDefault'] == true ||
        a?['isDefault']?.toString().toLowerCase() == 'true';
  }

  String _firstNonEmpty(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  Future<void> _loadLocationAndProfile() async {
    // Start the cached location lookup immediately; profile networking must
    // never block the state dropdown from becoming usable.
    _loadStates();

    // Fill from locally saved session/profile values first so the name appears
    // immediately, then refresh it from the server in the background.
    if (!widget.isEditing) {
      final savedName = _firstNonEmpty([
        Prefs.getString('fullName'),
        Prefs.getString('userName'),
        Prefs.getString('name'),
        Prefs.getString('artistName'),
        Prefs.getString('displayName'),
      ]);
      final savedPhone = _firstNonEmpty([
        Prefs.getString('phone'),
        Prefs.getString('mobile'),
        Prefs.getString('phoneNumber'),
      ]);
      if (_nameController.text.trim().isEmpty && savedName.isNotEmpty) {
        _nameController.text = savedName;
      }
      if (_phoneController.text.trim().isEmpty && savedPhone.isNotEmpty) {
        _phoneController.text = savedPhone;
      }
    }

    if (_token.isEmpty || widget.isEditing) return;

    final dio = _dio();
    try {
      final response = await dio.get<dynamic>(
        _uri('/profile', {'token': _token}).toString(),
        options: Options(followRedirects: false, maxRedirects: 0),
      );
      final raw = await _unwrapRedirect(dio, response);
      final outer = _map(raw);
      final data = outer['data'] is Map
          ? Map<String, dynamic>.from(outer['data'])
          : outer;
      final user = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'])
          : (data['profile'] is Map
                ? Map<String, dynamic>.from(data['profile'])
                : (data['artist'] is Map
                      ? Map<String, dynamic>.from(data['artist'])
                      : data));

      if (!mounted) return;
      final profileName = _firstNonEmpty([
        user['name'],
        user['fullName'],
        user['full_name'],
        user['displayName'],
        user['display_name'],
        user['userName'],
        user['username'],
        user['artistName'],
        user['artist_name'],
        data['name'],
        data['fullName'],
        outer['name'],
      ]);
      final profilePhone = _firstNonEmpty([
        user['phone'],
        user['mobile'],
        user['phoneNumber'],
        user['phone_number'],
        data['phone'],
        outer['phone'],
      ]);

      if (_nameController.text.trim().isEmpty && profileName.isNotEmpty) {
        _nameController.text = profileName;
      }
      if (_phoneController.text.trim().isEmpty && profilePhone.isNotEmpty) {
        _phoneController.text = profilePhone;
      }

      final state = _firstNonEmpty([
        user['state'],
        user['stateName'],
        data['state'],
      ]);
      final city = _firstNonEmpty([
        user['city'],
        user['cityName'],
        data['city'],
      ]);
      if (state.isNotEmpty) _initialStateName = state;
      if (city.isNotEmpty) _initialCityName = city;
    } catch (_) {
      // Profile prefill is best-effort; address entry remains available.
    } finally {
      dio.close(force: true);
    }
  }

  Future<void> _loadStates() async {
    if (!mounted) return;

    setState(() => _isLoadingStates = true);

    try {
      final states = await LocationDataCache.instance.getStates();

      if (!mounted) return;

      StateModel? initial;
      final wanted = (_initialStateName ?? '').trim().toLowerCase();

      for (final item in states) {
        if (wanted.isNotEmpty &&
            (item.stateName.trim().toLowerCase() == wanted ||
                item.stateCode.trim().toLowerCase() == wanted)) {
          initial = item;
          break;
        }
      }

      setState(() {
        _states = states;
        _selectedState = initial;
        _isLoadingStates = false;
      });

      if (initial != null) {
        await _loadCities(initial.stateCode, preserveInitial: true);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoadingStates = false);

      _showMessage(
        'Could not load states. Check your connection and try again.',
        error: true,
      );
    }
  }

  Future<void> _loadCities(
    String stateCode, {
    bool preserveInitial = false,
  }) async {
    if (!mounted) return;

    final cached = _citiesCache[stateCode];

    if (cached != null) {
      setState(() {
        _cities = cached;
        _isLoadingCities = false;
        _selectedCity = preserveInitial
            ? _matchCity(cached, _initialCityName)
            : null;
      });
      return;
    }

    setState(() {
      _cities = [];
      _selectedCity = null;
      _isLoadingCities = true;
    });

    try {
      final cities = await LocationDataCache.instance.getCities(stateCode);

      if (!mounted) return;

      _citiesCache[stateCode] = cities;

      setState(() {
        _cities = cities;
        _isLoadingCities = false;
        _selectedCity = preserveInitial
            ? _matchCity(cities, _initialCityName)
            : null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cities = [];
        _selectedCity = null;
        _isLoadingCities = false;
      });

      _showMessage('Could not load cities for this state.', error: true);
    }
  }

  CityModel? _matchCity(List<CityModel> cities, String? name) {
    if (name == null || name.trim().isEmpty) return null;
    for (final city in cities) {
      if (city.cityName.trim().toLowerCase() == name.trim().toLowerCase())
        return city;
    }
    return null;
  }

  String _value(Map<String, dynamic>? map, String key) =>
      map?[key]?.toString() ?? '';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Dio _dio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) =>
          status != null && status >= 200 && status < 400,
    ),
  );

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse(_baseUrl).replace(queryParameters: {'path': path, ...?query});

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  Future<dynamic> _unwrapRedirect(Dio dio, Response<dynamic> response) async {
    final status = response.statusCode;
    if (status == 301 ||
        status == 302 ||
        status == 303 ||
        status == 307 ||
        status == 308) {
      final location = response.headers.value('location');
      if (location == null || location.isEmpty) {
        throw Exception('The API redirected without a response URL.');
      }
      final redirected = await dio.get<dynamic>(
        location,
        options: Options(followRedirects: false, maxRedirects: 0),
      );
      if (redirected.statusCode != 200) {
        throw Exception('Server returned HTTP ${redirected.statusCode}.');
      }
      return redirected.data;
    }
    return response.data;
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final body = _map(error.response?.data);
      if (body.isNotEmpty) {
        final message = body['message'] ?? body['error'];
        if (message != null && message.toString().isNotEmpty) {
          return message.toString();
        }
      }
      if (error.response?.statusCode == 404) {
        return 'Address API is not deployed yet. Add the /addresses routes in Code.gs.';
      }
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return 'Your session has expired. Please sign in again.';
      }
      return error.message ?? 'Unable to connect to the server.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _saveAddress() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    if (_selectedState == null) {
      _showMessage('Please select your state.', error: true);
      return;
    }
    if (_selectedCity == null) {
      _showMessage('Please select your city.', error: true);
      return;
    }
    FocusScope.of(context).unfocus();

    if (_token.isEmpty) {
      _showMessage('Please sign in before saving an address.', error: true);
      return;
    }

    setState(() => _isSaving = true);
    final dio = _dio();

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'house': _houseController.text.trim(),
      'street': _streetController.text.trim(),
      'area': _areaController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      // The deployed Code.gs address endpoint requires addressLine.
      'addressLine': [
        _houseController.text.trim(),
        _streetController.text.trim(),
        _areaController.text.trim(),
        if (_landmarkController.text.trim().isNotEmpty)
          'Landmark: ${_landmarkController.text.trim()}',
      ].where((part) => part.trim().isNotEmpty).join(', '),
      'city': _selectedCity?.cityName ?? '',
      'state': _selectedState?.stateName ?? '',
      'stateCode': _selectedState?.stateCode ?? '',
      'pincode': _pincodeController.text.trim(),
      'type': _addressType,
      'label': _addressType,
      'isDefault': _isDefault,
    };

    try {
      final id = widget.address?['addressId'] ?? widget.address?['id'];
      final path = widget.isEditing && id != null
          ? '/addresses/$id'
          : '/addresses';
      final method = widget.isEditing ? 'PUT' : 'POST';

      // Apps Script receives the request through doPost; _method is read
      // by processRequest_ in Code.gs.
      final response = await dio.post<dynamic>(
        _uri(path).toString(),
        data: {
          ...payload,
          'token': _token,
          if (method != 'POST') '_method': method,
        },
        options: Options(followRedirects: false, maxRedirects: 0),
      );
      final raw = await _unwrapRedirect(dio, response);
      final result = _map(raw);
      if (result['success'] == false) {
        throw Exception(
          result['message'] ?? result['error'] ?? 'Address could not be saved.',
        );
      }

      final data = result['data'] is Map
          ? Map<String, dynamic>.from(result['data'])
          : result;

      if (!mounted) return;
      _showMessage(widget.isEditing ? 'Address updated.' : 'Address saved.');
      Navigator.pop(context, {
        ...payload,
        ...data,
        'id': data['addressId'] ?? data['id'] ?? id,
        'addressId': data['addressId'] ?? data['id'] ?? id,
      });
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error), error: true);
    } finally {
      dio.close(force: true);
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null || !messenger.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: error ? ArtistColors.error : ArtistColors.success,
          ),
        );
    });
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  Widget _buildStateDropdown() {
    return TextFormField(
      key: ValueKey(_selectedState?.stateCode ?? 'state-empty'),
      readOnly: true,
      initialValue: _selectedState?.stateName ?? '',
      onTap: (_isLoadingStates || _isSaving) ? null : _selectState,
      validator: (_) =>
          _selectedState == null ? 'Please select your state' : null,
      decoration:
          _decoration(
            label: 'State',
            hint: _isLoadingStates
                ? 'Loading states...'
                : (_states.isEmpty
                      ? 'States unavailable — tap to retry'
                      : 'Select state'),
            icon: Icons.map_outlined,
          ).copyWith(
            suffixIcon: _isLoadingStates
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.keyboard_arrow_down_rounded),
          ),
    );
  }

  Future<void> _selectState() async {
    if (_states.isEmpty) {
      await _loadStates();
      if (!mounted || _states.isEmpty) return;
    }
    final selected = await _showSearchPicker<StateModel>(
      title: 'Select State',
      searchHint: 'Search state...',
      items: _states,
      itemLabel: (state) => state.stateName,
      selectedItem: _selectedState,
    );
    if (!mounted || selected == null) return;
    if (_selectedState?.stateCode == selected.stateCode) return;
    setState(() {
      _selectedState = selected;
      _selectedCity = null;
      _initialCityName = null;
      _cities = _citiesCache[selected.stateCode] ?? [];
      _isLoadingCities = !_citiesCache.containsKey(selected.stateCode);
    });
    await _loadCities(selected.stateCode);
  }

  Widget _buildCityDropdown() {
    return TextFormField(
      key: ValueKey(
        '${_selectedState?.stateCode ?? 'no-state'}-${_selectedCity?.cityId ?? 'city-empty'}',
      ),
      readOnly: true,
      initialValue: _selectedCity?.cityName ?? '',
      onTap: (_selectedState == null || _isLoadingCities || _isSaving)
          ? null
          : _selectCity,
      validator: (_) =>
          _selectedCity == null ? 'Please select your city' : null,
      decoration:
          _decoration(
            label: 'City',
            hint: _selectedState == null
                ? 'Select state first'
                : (_isLoadingCities
                      ? 'Loading cities...'
                      : (_cities.isEmpty
                            ? 'Cities unavailable — tap to retry'
                            : 'Select city')),
            icon: Icons.location_city_outlined,
          ).copyWith(
            suffixIcon: _isLoadingCities
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.keyboard_arrow_down_rounded),
          ),
    );
  }

  Future<void> _selectCity() async {
    final state = _selectedState;
    if (state == null) return;
    if (_cities.isEmpty && !_isLoadingCities) {
      await _loadCities(state.stateCode);
      if (!mounted || _cities.isEmpty) return;
    }
    if (_isLoadingCities) return;
    final selected = await _showSearchPicker<CityModel>(
      title: 'Select City',
      searchHint: 'Search city...',
      items: _cities,
      itemLabel: (city) => city.cityName,
      selectedItem: _selectedCity,
    );
    if (!mounted || selected == null) return;
    setState(() => _selectedCity = selected);
  }

  Future<T?> _showSearchPicker<T>({
    required String title,
    required String searchHint,
    required List<T> items,
    required String Function(T) itemLabel,
    required T? selectedItem,
  }) async {
    if (!mounted) return null;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => _SearchPickerSheet<T>(
        title: title,
        searchHint: searchHint,
        items: items,
        itemLabel: itemLabel,
        selectedItem: selectedItem,
      ),
    );
  }

  String? _phoneValidator(String? value) {
    if (value == null || !RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _pincodeValidator(String? value) {
    if (value == null || !RegExp(r'^[0-9]{6}$').hasMatch(value.trim())) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: ArtistColors.primary),
    filled: true,
    fillColor: ArtistColors.surface,
    labelStyle: ArtistTextStyles.caption.copyWith(
      color: ArtistColors.textSecondary,
    ),
    hintStyle: ArtistTextStyles.body.copyWith(
      color: ArtistColors.textSecondary,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ArtistColors.light),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ArtistColors.light),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ArtistColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ArtistColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: ArtistColors.error, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        foregroundColor: ArtistColors.textPrimary,
        toolbarHeight: 56,
        titleSpacing: 4,
        title: Text(
          widget.isEditing ? 'Edit Address' : 'Add Address',
          style: ArtistTextStyles.title.copyWith(
            color: ArtistColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing
                      ? 'Update your address'
                      : 'Add a new address',
                  style: ArtistTextStyles.title.copyWith(
                    color: ArtistColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use accurate details for delivery and order updates.',
                  style: ArtistTextStyles.body.copyWith(
                    color: ArtistColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                _SectionCard(
                  title: 'Contact Information',
                  icon: Icons.person_outline_rounded,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      validator: _required,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      validator: _phoneValidator,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: _decoration(
                        label: 'Phone Number',
                        hint: '10-digit phone number',
                        icon: Icons.phone_outlined,
                      ).copyWith(counterText: ''),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Address Details',
                  icon: Icons.location_on_outlined,
                  children: [
                    TextFormField(
                      controller: _houseController,
                      validator: _required,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration(
                        label: 'House / Flat / Building',
                        hint: 'Enter building or flat details',
                        icon: Icons.home_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _streetController,
                      validator: _required,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration(
                        label: 'Street / Society',
                        hint: 'Enter street or society',
                        icon: Icons.signpost_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _areaController,
                      validator: _required,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration(
                        label: 'Area',
                        hint: 'Enter area or locality',
                        icon: Icons.location_city_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _landmarkController,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration(
                        label: 'Landmark (optional)',
                        hint: 'Nearby landmark',
                        icon: Icons.flag_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildStateDropdown(),
                    const SizedBox(height: 14),
                    _buildCityDropdown(),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _pincodeController,
                      validator: _pincodeValidator,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: _decoration(
                        label: 'Pincode',
                        hint: '6-digit pincode',
                        icon: Icons.pin_drop_outlined,
                      ).copyWith(counterText: ''),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Address Type',
                  icon: Icons.label_outline_rounded,
                  children: [
                    Text(
                      'Choose a label for this address',
                      style: ArtistTextStyles.body.copyWith(
                        color: ArtistColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _TypeOption(
                          label: 'Studio',
                          icon: Icons.home_outlined,
                          selected: _addressType == 'Studio',
                          onTap: () => setState(() => _addressType = 'Studio'),
                        ),
                        const SizedBox(width: 10),
                        _TypeOption(
                          label: 'Workshop',
                          icon: Icons.work_outline_rounded,
                          selected: _addressType == 'Workshop',
                          onTap: () =>
                              setState(() => _addressType = 'Workshop'),
                        ),
                        const SizedBox(width: 10),
                        _TypeOption(
                          label: 'Other',
                          icon: Icons.place_outlined,
                          selected: _addressType == 'Other',
                          onTap: () => setState(() => _addressType = 'Other'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: ArtistColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ArtistColors.light),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isDefault,
                    activeColor: ArtistColors.primary,
                    onChanged: (value) => setState(() => _isDefault = value),
                    title: Text(
                      'Set as default address',
                      style: ArtistTextStyles.body.copyWith(
                        color: ArtistColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Use this address automatically for orders.',
                      style: ArtistTextStyles.caption.copyWith(
                        color: ArtistColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: ArtistColors.background,
            border: Border(top: BorderSide(color: ArtistColors.light)),
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: ArtistColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: ArtistColors.surface,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isEditing
                              ? Icons.check_rounded
                              : Icons.save_outlined,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isEditing ? 'Update Address' : 'Save Address',
                          style: ArtistTextStyles.body.copyWith(
                            color: ArtistColors.surface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchPickerSheet<T> extends StatefulWidget {
  const _SearchPickerSheet({
    required this.title,
    required this.searchHint,
    required this.items,
    required this.itemLabel,
    required this.selectedItem,
  });

  final String title;
  final String searchHint;
  final List<T> items;
  final String Function(T) itemLabel;
  final T? selectedItem;

  @override
  State<_SearchPickerSheet<T>> createState() => _SearchPickerSheetState<T>();
}

class _SearchPickerSheetState<T> extends State<_SearchPickerSheet<T>> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.items
        .where((item) => widget.itemLabel(item).toLowerCase().contains(query))
        .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: ArtistColors.surface,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: ArtistTextStyles.title.copyWith(
                            color: ArtistColors.textPrimary,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: ArtistColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No matching results',
                            style: ArtistTextStyles.body.copyWith(
                              color: ArtistColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isSelected =
                                widget.selectedItem != null &&
                                item == widget.selectedItem;
                            return Material(
                              color: isSelected
                                  ? ArtistColors.light
                                  : ArtistColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: Text(widget.itemLabel(item)),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: ArtistColors.primary,
                                      )
                                    : null,
                                onTap: () => Navigator.of(context).pop(item),
                              ),
                            );
                          },
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.light),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ArtistColors.primary, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: ArtistTextStyles.title.copyWith(
                    color: ArtistColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? ArtistColors.light : ArtistColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ArtistColors.primary : ArtistColors.light,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? ArtistColors.primary
                    : ArtistColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: ArtistTextStyles.caption.copyWith(
                  color: selected
                      ? ArtistColors.primary
                      : ArtistColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
