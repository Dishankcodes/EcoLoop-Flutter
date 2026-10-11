import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../shared_preferences_util.dart';
import 'add_address.dart';

class AddressList extends StatefulWidget {
  const AddressList({super.key});

  @override
  State<AddressList> createState() => _AddressListState();
}

class _AddressListState extends State<AddressList> {
  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbzvHq06GwL_I8qH2IPyQP36dRlESN62PYF4Ak5WkRE2VjHL5a-tr0Yk_KEtSvU_ZL6IbQ/exec';

  List<AddressItem> _addresses = [];
  bool _isLoading = true;
  bool _isMutating = false;
  String? _error;

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
    _loadAddresses();
  }

  Dio _dio() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ));

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

  List<dynamic> _list(dynamic value) {
    if (value is List) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }

  Future<dynamic> _unwrapRedirect(Dio dio, Response<dynamic> response) async {
    final status = response.statusCode;
    if (status == 301 || status == 302 || status == 303 ||
        status == 307 || status == 308) {
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

  Future<void> _loadAddresses() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (_token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Please sign in to view your saved addresses.';
      });
      return;
    }

    final dio = _dio();
    try {
      final response = await dio.get<dynamic>(
        _uri('/addresses', {'token': _token}).toString(),
        options: Options(followRedirects: false, maxRedirects: 0),
      );
      final raw = await _unwrapRedirect(dio, response);
      final outer = _map(raw);

      if (outer['success'] == false) {
        throw Exception(
          outer['message'] ?? outer['error'] ?? 'Unable to load addresses.',
        );
      }

      dynamic data = outer.containsKey('data') ? outer['data'] : raw;
      if (data is Map) {
        data = data['addresses'] ?? data['items'] ?? data['results'] ?? [];
      }

      final parsed = <AddressItem>[];
      for (final item in _list(data)) {
        final map = _map(item);
        if (map.isNotEmpty) parsed.add(AddressItem.fromMap(map));
      }

      if (!mounted) return;
      setState(() {
        _addresses = parsed;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _errorMessage(error);
      });
    } finally {
      dio.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _sendMutation(
    String path, {
    required String method,
    Map<String, dynamic> body = const {},
  }) async {
    if (_token.isEmpty) throw Exception('Please sign in again.');

    final dio = _dio();
    try {
      final response = await dio.post<dynamic>(
        _uri(path).toString(),
        data: {
          ...body,
          'token': _token,
          '_method': method,
        },
        options: Options(followRedirects: false, maxRedirects: 0),
      );
      final raw = await _unwrapRedirect(dio, response);
      final result = _map(raw);
      if (result['success'] == false) {
        throw Exception(
          result['message'] ?? result['error'] ?? 'Request failed.',
        );
      }
      return result['data'] is Map
          ? Map<String, dynamic>.from(result['data'])
          : result;
    } finally {
      dio.close(force: true);
    }
  }

  Future<void> _openAddressForm({AddressItem? address}) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAddress(address: address?.toMap()),
      ),
    );
    if (!mounted || result == null) return;
    // The AddAddress page saves to the backend before returning.
    await _loadAddresses();
  }

  Future<void> _deleteAddress(AddressItem address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Address?',
          style: AppTextStyles.title.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this saved address?',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: AppTextStyles.body.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || _isMutating) return;

    setState(() => _isMutating = true);
    try {
      await _sendMutation('/addresses/${Uri.encodeComponent(address.id)}',
          method: 'DELETE');
      if (!mounted) return;
      _showMessage('Address deleted.');
      await _loadAddresses();
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _setDefaultAddress(AddressItem address) async {
    if (address.isDefault || _isMutating) return;
    setState(() => _isMutating = true);
    try {
      await _sendMutation(
        '/addresses/${Uri.encodeComponent(address.id)}/default',
        method: 'POST',
      );
      if (!mounted) return;
      _showMessage('Default address updated.');
      await _loadAddresses();
    } catch (error) {
      if (mounted) _showMessage(_errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.error : AppColors.success,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'My Addresses',
          style: AppTextStyles.title.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadAddresses,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.light)),
          ),
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isMutating ? null : () => _openAddressForm(),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: Text(
                'Add New Address',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null && _addresses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load addresses',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadAddresses,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_addresses.isEmpty) {
      return _EmptyAddressState(onAddAddress: () => _openAddressForm());
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAddresses,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Saved addresses',
            style: AppTextStyles.title.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Manage your delivery addresses for a faster checkout.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ..._addresses.map(
            (address) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AddressCard(
                address: address,
                onEdit: () => _openAddressForm(address: address),
                onDelete: () => _deleteAddress(address),
                onSetDefault: () => _setDefaultAddress(address),
                enabled: !_isMutating,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddressItem {
  final String id;
  final String name;
  final String phone;
  final String house;
  final String street;
  final String area;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final String type;
  final bool isDefault;

  const AddressItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.house,
    required this.street,
    required this.area,
    required this.landmark,
    required this.city,
    required this.state,
    required this.pincode,
    required this.type,
    required this.isDefault,
  });

  factory AddressItem.fromMap(Map<String, dynamic> map) {
    String read(String key) => map[key]?.toString() ?? '';
    final id = read('addressId').isNotEmpty ? read('addressId') : read('id');
    final defaultValue = map['isDefault'];
    return AddressItem(
      id: id,
      name: read('name'),
      phone: read('phone'),
      house: read('house'),
      street: read('street'),
      area: read('area'),
      landmark: read('landmark'),
      city: read('city'),
      state: read('state'),
      pincode: read('pincode'),
      type: read('type').isEmpty ? 'Home' : read('type'),
      isDefault: defaultValue == true ||
          defaultValue?.toString().toLowerCase() == 'true' ||
          defaultValue?.toString() == '1',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'addressId': id,
        'name': name,
        'phone': phone,
        'house': house,
        'street': street,
        'area': area,
        'landmark': landmark,
        'city': city,
        'state': state,
        'pincode': pincode,
        'type': type,
        'isDefault': isDefault,
      };
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    required this.enabled,
  });

  final AddressItem address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: address.isDefault ? AppColors.primary : AppColors.light,
          width: address.isDefault ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _addressIcon(address.type),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          address.name,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        _AddressTypeBadge(type: address.type),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.phone,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                enabled: enabled,
                color: AppColors.surface,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                  size: 21,
                ),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                  if (value == 'default') onSetDefault();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (!address.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(Icons.star_outline_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('Set as Default'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.light),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _fullAddress(),
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          if (address.isDefault) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  'Default address',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _fullAddress() {
    final parts = [
      address.house,
      address.street,
      address.area,
      if (address.landmark.trim().isNotEmpty) address.landmark,
      address.city,
      address.state,
      address.pincode,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  IconData _addressIcon(String type) {
    switch (type.toLowerCase()) {
      case 'work':
        return Icons.work_outline_rounded;
      case 'other':
        return Icons.location_on_outlined;
      default:
        return Icons.home_outlined;
    }
  }
}

class _AddressTypeBadge extends StatelessWidget {
  const _AddressTypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyAddressState extends StatelessWidget {
  const _EmptyAddressState({required this.onAddAddress});
  final VoidCallback onAddAddress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No saved addresses',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first delivery address to make checkout faster and easier.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddAddress,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Address'),
            ),
          ],
        ),
      ),
    );
  }
}
