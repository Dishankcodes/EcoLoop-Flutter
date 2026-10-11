import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../../../api/api_manager.dart';
import '../../../models/location/city_model.dart';
import '../../../models/location/state_model.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
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

  String _addressType = 'Home';
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
    _addressType = _value(a, 'type').isEmpty ? 'Home' : _value(a, 'type');
    _isDefault =
        a?['isDefault'] == true ||
        a?['isDefault']?.toString().toLowerCase() == 'true';
  }

  Future<void> _loadLocationAndProfile() async {
    if (_token.isEmpty) return;
    if (!widget.isEditing) {
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
        if (mounted) {
          if (_phoneController.text.trim().isEmpty) {
            _phoneController.text = (data['phone'] ?? '').toString();
          }
          if ((data['state'] ?? '').toString().trim().isNotEmpty) {
            _initialStateName = data['state'].toString();
          }
          if ((data['city'] ?? '').toString().trim().isNotEmpty) {
            _initialCityName = data['city'].toString();
          }
        }
      } catch (_) {
        // Keep the form usable if account prefill fails.
      } finally {
        dio.close(force: true);
      }
    }
    await _loadStates();
  }

  Future<void> _loadStates() async {
    if (!mounted) return;
    setState(() => _isLoadingStates = true);
    try {
      final response = await ApiManager().client.getStates('/locations/states');
      if (!mounted) return;
      if (response.success != true || response.data == null) {
        throw Exception(response.error ?? 'Unable to load states.');
      }
      final states = response.data!;
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
      if (initial != null)
        await _loadCities(initial.stateCode, preserveInitial: true);
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStates = false);
        _showMessage(
          'Could not load states. Check your connection and try again.',
          error: true,
        );
      }
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
      final response = await ApiManager().client.getCities(
        '/locations/cities',
        stateCode,
      );
      if (!mounted) return;
      if (response.success != true || response.data == null) {
        throw Exception(response.error ?? 'Unable to load cities.');
      }
      final cities = response.data!;
      _citiesCache[stateCode] = cities;
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
        _selectedCity = preserveInitial
            ? _matchCity(cities, _initialCityName)
            : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _cities = [];
          _selectedCity = null;
          _isLoadingCities = false;
        });
        _showMessage('Could not load cities for this state.', error: true);
      }
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
      'city': _selectedCity?.cityName ?? '',
      'state': _selectedState?.stateName ?? '',
      'stateCode': _selectedState?.stateCode ?? '',
      'pincode': _pincodeController.text.trim(),
      'type': _addressType,
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
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? AppColors.error : AppColors.success,
        ),
      );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  Widget _buildStateDropdown() {
    return DropdownSearch<StateModel>(
      selectedItem: _selectedState,
      enabled: !_isLoadingStates && _states.isNotEmpty && !_isSaving,
      items: (filter, loadProps) => _states,
      itemAsString: (StateModel state) => state.stateName,
      compareFn: (StateModel a, StateModel b) => a.stateCode == b.stateCode,
      onSelected: (StateModel? value) {
        if (value == null) return;
        setState(() {
          _selectedState = value;
          _selectedCity = null;
          _initialCityName = null;
          _cities = _citiesCache[value.stateCode] ?? [];
          _isLoadingCities = !_citiesCache.containsKey(value.stateCode);
        });
        _loadCities(value.stateCode);
      },
      validator: (value) => value == null ? 'Please select your state' : null,
      decoratorProps: DropDownDecoratorProps(
        decoration:
            _decoration(
              label: 'State',
              hint: _isLoadingStates ? 'Loading states...' : 'Select state',
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
                  : null,
            ),
      ),
      popupProps: PopupProps.modalBottomSheet(
        showSearchBox: true,
        searchDelay: Duration.zero,
        title: const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Text(
            'Select State',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search state...',
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return DropdownSearch<CityModel>(
      selectedItem: _selectedCity,
      enabled:
          _selectedState != null &&
          !_isLoadingCities &&
          _cities.isNotEmpty &&
          !_isSaving,
      items: (filter, loadProps) => _cities,
      itemAsString: (CityModel city) => city.cityName,
      compareFn: (CityModel a, CityModel b) => a.cityId == b.cityId,
      onSelected: (CityModel? value) => setState(() => _selectedCity = value),
      validator: (value) => value == null ? 'Please select your city' : null,
      decoratorProps: DropDownDecoratorProps(
        decoration:
            _decoration(
              label: 'City',
              hint: _selectedState == null
                  ? 'Select state first'
                  : (_isLoadingCities ? 'Loading cities...' : 'Select city'),
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
                  : null,
            ),
      ),
      popupProps: PopupProps.modalBottomSheet(
        showSearchBox: true,
        searchDelay: Duration.zero,
        title: const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Text(
            'Select City',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search city...',
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
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
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: AppColors.surface,
    labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
    hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.light),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.light),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          widget.isEditing ? 'Edit Address' : 'Add Address',
          style: AppTextStyles.heading.copyWith(color: AppColors.textPrimary),
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
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Use accurate details for delivery and order updates.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
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
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _TypeOption(
                          label: 'Home',
                          icon: Icons.home_outlined,
                          selected: _addressType == 'Home',
                          onTap: () => setState(() => _addressType = 'Home'),
                        ),
                        const SizedBox(width: 10),
                        _TypeOption(
                          label: 'Work',
                          icon: Icons.work_outline_rounded,
                          selected: _addressType == 'Work',
                          onTap: () => setState(() => _addressType = 'Work'),
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
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.light),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isDefault,
                    activeColor: AppColors.primary,
                    onChanged: (value) => setState(() => _isDefault = value),
                    title: Text(
                      'Set as default address',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Use this address automatically for orders.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
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
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.light)),
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
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
                        color: AppColors.surface,
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
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.surface,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.light),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
            color: selected ? AppColors.light : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.light,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
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
