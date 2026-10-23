import 'package:ecoloop/services/ecoloop_api.dart';
import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../profile/add_address.dart';
import 'marketplace.dart';
import 'payment.dart';

/// User checkout. The layout follows the artist checkout design language,
/// while all addresses and suggested products are loaded from the EcoLoop API.
class Checkout extends StatefulWidget {
  final List<Map<String, dynamic>>? items;
  final Map<String, dynamic>? product;
  final int quantity;
  final String? initialCouponCode;
  final double initialCouponDiscount;
  final bool clearCartAfterOrder;

  const Checkout({
    super.key,
    this.items,
    this.product,
    this.quantity = 1,
    this.initialCouponCode,
    this.initialCouponDiscount = 0,
    this.clearCartAfterOrder = false,
    // Kept temporarily for compatibility with existing navigation call sites; Eco Points are not used in checkout.
    double initialEcoPointDiscount = 0,
  });

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _addresses = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _suggestedProducts = <Map<String, dynamic>>[];
  final Set<String> _ownProductIds = <String>{};
  String? _currentAccountId;
  String _currentAccountType = 'user';

  String? _selectedAddressId;
  String _selectedDelivery = 'standard';
  String? _couponCode;
  double _couponDiscount = 0;

  bool _loadingAddresses = true;
  bool _loadingProducts = false;
  bool _savingAddress = false;
  bool _proceeding = false;
  String? _addressError;
  String? _productsError;

  @override
  void initState() {
    super.initState();
    _couponCode = widget.initialCouponCode?.trim().toUpperCase();
    if (_couponCode != null &&
        !{'RECYCLE20', 'LOOP50', 'ECO100'}.contains(_couponCode)) {
      _couponCode = null;
    }
    _couponDiscount = 0;

    if (widget.items != null) {
      for (final item in widget.items!) {
        _items.add(_normalizeItem(item));
      }
    } else if (widget.product != null) {
      _items.add(
        _normalizeItem({...widget.product!, 'quantity': widget.quantity}),
      );
    }

    _loadAddresses();
    _loadCurrentAccountAndOwnProducts().then((_) {
      if (mounted) _loadSuggestedProducts();
    });
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractRows(
    dynamic response, {
    List<String> keys = const [
      'items',
      'products',
      'addresses',
      'data',
      'results',
    ],
  }) {
    if (response is List) {
      return response.whereType<Map>().map((row) => _asMap(row)).toList();
    }
    final root = _asMap(response);
    for (final key in keys) {
      final value = root[key];
      if (value is List) {
        return value.whereType<Map>().map((row) => _asMap(row)).toList();
      }
      if (value is Map) {
        for (final nestedKey in keys) {
          final nested = value[nestedKey];
          if (nested is List) {
            return nested.whereType<Map>().map((row) => _asMap(row)).toList();
          }
        }
      }
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _normalizeItem(Map<String, dynamic> source) {
    final item = Map<String, dynamic>.from(source);
    item['productId'] =
        item['productId'] ?? item['product_id'] ?? item['id'] ?? '';
    item['title'] = item['title'] ?? item['name'] ?? 'Product';
    item['price'] = _number(item['price'] ?? item['unitPrice']);
    item['quantity'] = _integer(item['quantity'], 1).clamp(1, 999);
    item['availableQuantity'] = _integer(
      item['availableQuantity'] ??
          item['available_quantity'] ??
          item['stock'] ??
          item['quantityAvailable'],
      0,
    ).clamp(0, 999999);
    item['image'] = _productImage(item);
    item['seller'] =
        item['seller'] ??
        item['sellerName'] ??
        item['artistName'] ??
        item['ownerName'] ??
        'EcoLoop Seller';
    item['sellerCity'] =
        item['sellerCity'] ??
        item['seller_city'] ??
        item['city'] ??
        item['location'] ??
        '';
    return item;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
          (value ?? '')
              .toString()
              .replaceAll(',', '')
              .replaceAll('₹', '')
              .trim(),
        ) ??
        0;
  }

  int _integer(dynamic value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  String _productImage(Map<String, dynamic> item) {
    for (final key in ['image', 'imageUrl', 'image_url', 'thumbnail']) {
      final value = item[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    for (final key in ['imageUrls', 'images', 'photos']) {
      final value = item[key];
      if (value is List && value.isNotEmpty) {
        final first = value.first;
        if (first is Map) {
          final map = _asMap(first);
          final url = map['url'] ?? map['imageUrl'] ?? map['image'];
          if (url != null && url.toString().trim().isNotEmpty)
            return url.toString().trim();
        } else if (first.toString().trim().isNotEmpty) {
          return first.toString().trim();
        }
      }
    }
    return '';
  }

  double get _subtotal => _items.fold<double>(
    0,
    (sum, item) => sum + _number(item['price']) * _integer(item['quantity'], 1),
  );

  // Keep in sync with the backend's per-order-line calculation: round 2% of
  // each product line subtotal, then round 18% GST on that rounded fee.
  // The backend independently recomputes pricing from current product records.
  double _platformFeeForLine(Map<String, dynamic> item) {
    final lineSubtotal = _number(item['price']) * _integer(item['quantity'], 1);
    return (lineSubtotal * 0.02).roundToDouble();
  }

  double get _platformFee =>
      _items.fold<double>(0, (sum, item) => sum + _platformFeeForLine(item));

  double get _taxes => _items.fold<double>(
    0,
    (sum, item) => sum + (_platformFeeForLine(item) * 0.18).roundToDouble(),
  );

  String _sellerKey(Map<String, dynamic> item) {
    final sellerId =
        item['sellerId'] ??
        item['seller_id'] ??
        item['ownerId'] ??
        item['owner_id'];
    final sellerType =
        (item['sellerType'] ??
                item['seller_type'] ??
                item['ownerType'] ??
                item['owner_type'] ??
                'user')
            .toString()
            .trim()
            .toLowerCase();
    if (sellerId != null && sellerId.toString().trim().isNotEmpty) {
      return '$sellerType:${sellerId.toString().trim()}';
    }
    final sellerName =
        (item['seller'] ?? item['sellerName'] ?? item['artistName'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    return sellerName.isEmpty
        ? 'product:${item['productId']}'
        : 'name:$sellerName';
  }

  bool _isFreeDeliveryProduct(Map<String, dynamic> item) {
    final method =
        (item['deliveryMethod'] ??
                item['delivery_method'] ??
                item['shippingMethod'] ??
                item['shipping_method'] ??
                '')
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll('_', ' ')
            .replaceAll('-', ' ');
    return method == 'free delivery' ||
        method == 'free' ||
        method == 'free shipping';
  }

  bool _sellerHasPaidDelivery(String sellerKey) {
    final sellerItems = _items.where((item) => _sellerKey(item) == sellerKey);
    return sellerItems.isNotEmpty &&
        sellerItems.any((item) => !_isFreeDeliveryProduct(item));
  }

  double _deliveryRateForSeller({
    required String buyerCity,
    required String sellerCity,
    required bool express,
  }) {
    final sameCity =
        buyerCity.isNotEmpty &&
        sellerCity.isNotEmpty &&
        buyerCity == sellerCity;
    if (express) return sameCity ? 69.0 : 99.0;
    return sameCity ? 40.0 : 59.0;
  }

  double _calculateDeliveryFee({required bool express}) {
    final buyerCity = (_selectedAddress?['city'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final chargedSellers = <String>{};
    var fee = 0.0;

    for (final item in _items) {
      final key = _sellerKey(item);
      if (!chargedSellers.add(key) || !_sellerHasPaidDelivery(key)) continue;

      final sellerCity =
          (item['sellerCity'] ??
                  item['seller_city'] ??
                  (item['seller'] is Map
                      ? (item['seller'] as Map)['city']
                      : null) ??
                  item['city'] ??
                  '')
              .toString()
              .trim()
              .toLowerCase();

      // Missing city data uses the out-of-city rate rather than silently
      // showing zero delivery charges.
      fee += _deliveryRateForSeller(
        buyerCity: buyerCity,
        sellerCity: sellerCity,
        express: express,
      );
    }
    return fee;
  }

  double get _standardDeliveryFee => _calculateDeliveryFee(express: false);

  double get _expressDeliveryFee => _calculateDeliveryFee(express: true);

  double get _deliveryFee => _selectedDelivery == 'express'
      ? _expressDeliveryFee
      : _standardDeliveryFee;

  int _couponMinimum(String code) {
    switch (code.toUpperCase()) {
      case 'RECYCLE20':
        return 499;
      case 'LOOP50':
        return 999;
      case 'ECO100':
        return 1599;
      default:
        return 0;
    }
  }

  double _couponAmount(String code) {
    switch (code.toUpperCase()) {
      case 'RECYCLE20':
        return 20;
      case 'LOOP50':
        return 50;
      case 'ECO100':
        return 100;
      default:
        return 0;
    }
  }

  double get _couponSavings {
    if (_couponCode == null) return 0;
    final code = _couponCode!.toUpperCase();
    if (_couponMinimum(code) == 0 || _subtotal < _couponMinimum(code)) return 0;
    return _couponAmount(code).clamp(0.0, _subtotal).toDouble();
  }

  double get _grandTotal {
    final value =
        _subtotal + _platformFee + _taxes + _deliveryFee - _couponSavings;
    return value < 0 ? 0 : value;
  }

  int get _totalQuantity =>
      _items.fold<int>(0, (sum, item) => sum + _integer(item['quantity'], 1));

  String _money(num value) => '₹${_indianNumber(value.round())}';

  String _indianNumber(int number) {
    final raw = number.toString();
    if (raw.length <= 3) return raw;
    final lastThree = raw.substring(raw.length - 3);
    var left = raw.substring(0, raw.length - 3);
    final groups = <String>[];
    while (left.length > 2) {
      groups.insert(0, left.substring(left.length - 2));
      left = left.substring(0, left.length - 2);
    }
    if (left.isNotEmpty) groups.insert(0, left);
    return '${groups.join(',')},$lastThree';
  }

  Future<void> _loadAddresses({
    bool showLoading = true,
    int attempts = 1,
  }) async {
    if (!mounted) return;
    if (showLoading) {
      setState(() {
        _loadingAddresses = _addresses.isEmpty;
        _addressError = null;
      });
    }

    Object? lastError;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final response = await _api.get('/addresses');
        final rows = _extractRows(
          response,
          keys: const ['addresses', 'items', 'data', 'results'],
        );

        final addresses = rows
            .map((raw) {
              final address = Map<String, dynamic>.from(raw);
              address['addressId'] =
                  address['addressId'] ??
                  address['address_id'] ??
                  address['id'] ??
                  address['ID'];
              address['label'] =
                  address['label'] ??
                  address['type'] ??
                  address['addressType'] ??
                  'Address';
              address['name'] =
                  address['name'] ??
                  address['recipientName'] ??
                  address['recipient_name'] ??
                  '';
              address['phone'] =
                  address['phone'] ??
                  address['phoneNumber'] ??
                  address['phone_number'] ??
                  '';
              address['addressLine'] =
                  address['addressLine'] ??
                  address['address_line'] ??
                  address['fullAddress'] ??
                  address['full_address'] ??
                  address['address'] ??
                  [address['house'], address['street']]
                      .where((v) => v != null && v.toString().trim().isNotEmpty)
                      .join(', ');
              address['area'] =
                  address['area'] ??
                  address['landmark'] ??
                  address['locality'] ??
                  '';
              address['city'] = address['city'] ?? address['town'] ?? '';
              address['state'] = address['state'] ?? address['region'] ?? '';
              address['pincode'] =
                  address['pincode'] ??
                  address['postalCode'] ??
                  address['postal_code'] ??
                  address['zipCode'] ??
                  address['zip_code'] ??
                  '';
              return address;
            })
            .where((a) {
              final id = a['addressId'];
              return id != null && id.toString().trim().isNotEmpty;
            })
            .toList();

        if (!mounted) return;
        Map<String, dynamic>? defaultAddress;
        for (final address in addresses) {
          if (_isTrue(address['isDefault'] ?? address['is_default'])) {
            defaultAddress = address;
            break;
          }
        }

        setState(() {
          _addresses = addresses;
          final currentExists = addresses.any(
            (a) => a['addressId'].toString() == _selectedAddressId,
          );
          if (!currentExists) {
            _selectedAddressId =
                (defaultAddress?['addressId'] ??
                        (addresses.isNotEmpty
                            ? addresses.first['addressId']
                            : null))
                    ?.toString();
          }
          _loadingAddresses = false;
          _addressError = null;
        });
        if (addresses.isNotEmpty || attempt == attempts - 1) return;
      } catch (error) {
        lastError = error;
        if (attempt == attempts - 1) break;
      }

      // Apps Script/Sheets may briefly take a moment to expose a just-saved row.
      if (attempt < attempts - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }

    if (!mounted) return;
    setState(() {
      _loadingAddresses = false;
      _addressError =
          lastError?.toString() ??
          'No saved addresses were returned. Please refresh and try again.';
    });
  }

  Future<void> _loadCurrentAccountAndOwnProducts() async {
    // These independent reads can run together. Both remain best-effort because
    // the final order endpoint validates ownership and stock authoritatively.
    final results = await Future.wait<dynamic>([
      _api
          .get('/auth/me')
          .then<dynamic>((value) => value)
          .catchError((_) => null),
      _api
          .get('/my/products')
          .then<dynamic>((value) => value)
          .catchError((_) => null),
    ]);

    final rawAccount = results[0];
    if (rawAccount != null) {
      final response = _asMap(rawAccount);
      final data = _asMap(response['data']);
      final account = _asMap(
        response['account'] ??
            response['user'] ??
            response['artist'] ??
            data['account'] ??
            data['user'] ??
            data['artist'] ??
            data,
      );
      final id =
          account['accountId'] ??
          account['userId'] ??
          account['artistId'] ??
          account['id'];
      final type =
          (account['accountType'] ??
                  account['ownerType'] ??
                  account['role'] ??
                  response['accountType'] ??
                  data['accountType'] ??
                  'user')
              .toString()
              .trim()
              .toLowerCase();
      if (id != null && id.toString().trim().isNotEmpty) {
        _currentAccountId = id.toString().trim();
        _currentAccountType =
            <String>{'artist', 'remaker', 're-maker', 're_maker'}.contains(type)
            ? 'artist'
            : 'user';
      }
    }

    final rawProducts = results[1];
    if (rawProducts != null) {
      final rows = _extractRows(
        rawProducts,
        keys: const ['products', 'items', 'data', 'results'],
      );
      _ownProductIds.addAll(
        rows
            .map(_asMap)
            .map(
              (row) =>
                  (row['productId'] ?? row['product_id'] ?? row['id'] ?? '')
                      .toString()
                      .trim(),
            )
            .where((id) => id.isNotEmpty),
      );
    }
  }

  bool _isOwnProduct(Map<String, dynamic> product) {
    final id =
        (product['productId'] ?? product['product_id'] ?? product['id'] ?? '')
            .toString()
            .trim();
    if (id.isNotEmpty && _ownProductIds.contains(id)) return true;
    final sellerId =
        (product['sellerId'] ??
                product['seller_id'] ??
                product['ownerId'] ??
                product['owner_id'] ??
                '')
            .toString()
            .trim();
    if (sellerId.isEmpty ||
        _currentAccountId == null ||
        sellerId != _currentAccountId) {
      return false;
    }
    final sellerType =
        (product['sellerType'] ??
                product['seller_type'] ??
                product['sellerRole'] ??
                product['seller_role'] ??
                product['ownerType'] ??
                'user')
            .toString()
            .trim()
            .toLowerCase();
    final isArtist = <String>{
      'artist',
      'remaker',
      're-maker',
      're_maker',
    }.contains(sellerType);
    return isArtist == (_currentAccountType == 'artist');
  }

  Future<void> _browseMarketplace() async {
    if (_proceeding) return;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const Marketplace(returnToCheckoutOnSelect: true),
      ),
    );
    if (!mounted || result == null) return;
    final product = _asMap(result['product']);
    final quantity = _integer(result['quantity'], 1).clamp(1, 999);
    if (product.isNotEmpty) _addProduct(product, quantity: quantity);
  }

  Future<void> _loadSuggestedProducts() async {
    if (!mounted || _loadingProducts) return;
    setState(() {
      _loadingProducts = true;
      _productsError = null;
    });
    try {
      final response = await _api.get('/products');
      final rows = _extractRows(response);
      final currentIds = _items.map((i) => i['productId'].toString()).toSet();
      final available = rows
          .map(_normalizeItem)
          .where((product) {
            final id = product['productId'].toString();
            final status = (product['status'] ?? 'published')
                .toString()
                .toLowerCase();
            final stock = _integer(product['availableQuantity'], 0);
            return id.isNotEmpty &&
                !currentIds.contains(id) &&
                !_isOwnProduct(product) &&
                status == 'published' &&
                stock > 0;
          })
          .take(12)
          .toList();
      if (!mounted) return;
      setState(() {
        _suggestedProducts = available;
        _loadingProducts = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingProducts = false;
        _productsError = error.toString();
      });
    }
  }

  bool _isTrue(dynamic value) =>
      value == true ||
      value.toString().toLowerCase() == 'true' ||
      value.toString() == '1';

  Map<String, dynamic>? get _selectedAddress {
    for (final address in _addresses) {
      final id = address['addressId'] ?? address['address_id'] ?? address['id'];
      if (id != null && id.toString() == _selectedAddressId) return address;
    }
    return null;
  }

  Future<void> _addAddress() async {
    if (_savingAddress) return;
    setState(() => _savingAddress = true);
    final previousAddressIds = _addresses
        .map(
          (address) =>
              (address['addressId'] ?? address['address_id'] ?? address['id'])
                  .toString(),
        )
        .toSet();
    try {
      // AddAddress returns `true` after a successful save, not an address map.
      // Accept dynamic here so the route result cannot fail a Map type cast.
      final dynamic result = await Navigator.push<dynamic>(
        context,
        MaterialPageRoute<dynamic>(builder: (_) => const AddAddress()),
      );
      if (!mounted) return;

      if (result == true) {
        // Refresh from the API after saving. Retry briefly until the newly
        // created row appears, rather than accepting an old/stale list.
        for (var attempt = 0; attempt < 4; attempt++) {
          await _loadAddresses(showLoading: true, attempts: 1);
          if (!mounted) return;
          final newlyAdded = _addresses.where((address) {
            final id =
                (address['addressId'] ?? address['address_id'] ?? address['id'])
                    .toString();
            return !previousAddressIds.contains(id);
          }).toList();
          if (newlyAdded.isNotEmpty) {
            setState(
              () =>
                  _selectedAddressId = newlyAdded.first['addressId'].toString(),
            );
            _message('Address saved and selected.');
            return;
          }
          if (attempt < 3) {
            await Future<void>.delayed(const Duration(milliseconds: 300));
          }
        }
        if (_addresses.isNotEmpty) {
          _message(
            'Address saved. Choose your address below or refresh the list.',
          );
        } else {
          _message(
            'Address saved, but the list has not refreshed yet. Tap refresh to reload addresses.',
          );
        }
        return;
      }

      // Also support older AddAddress pages that return the saved address map.
      if (result is Map) {
        final returned = _asMap(result);
        await _loadAddresses(showLoading: true, attempts: 3);
        if (!mounted) return;
        final returnedId =
            returned['addressId'] ?? returned['address_id'] ?? returned['id'];
        Map<String, dynamic>? match;
        if (returnedId != null) {
          for (final address in _addresses) {
            if (address['addressId'].toString() == returnedId.toString()) {
              match = address;
              break;
            }
          }
        }
        match ??= _addresses.cast<Map<String, dynamic>?>().firstWhere(
          (address) =>
              address != null &&
              (address['name'] ?? '').toString().trim() ==
                  (returned['name'] ?? returned['recipientName'] ?? '')
                      .toString()
                      .trim() &&
              (address['phone'] ?? '').toString().trim() ==
                  (returned['phone'] ?? returned['phoneNumber'] ?? '')
                      .toString()
                      .trim() &&
              (address['city'] ?? '').toString().trim().toLowerCase() ==
                  (returned['city'] ?? '').toString().trim().toLowerCase(),
          orElse: () => null,
        );
        if (match != null && mounted) {
          setState(() => _selectedAddressId = match!['addressId'].toString());
        }
      }
    } catch (error) {
      _message('Could not open Add Address: $error');
    } finally {
      if (mounted) setState(() => _savingAddress = false);
    }
  }

  void _addProduct(Map<String, dynamic> source, {int quantity = 1}) {
    final product = _normalizeItem(source);
    if (_isOwnProduct(product)) {
      _message('You cannot add your own listing to checkout.');
      return;
    }
    final id = product['productId'].toString();
    if (id.isEmpty) {
      _message('This listing has no product ID and cannot be added.');
      return;
    }
    final stock = _integer(product['availableQuantity'], 0);
    if (stock < 1) {
      _message('This product is currently out of stock.');
      return;
    }
    final index = _items.indexWhere(
      (item) => item['productId'].toString() == id,
    );
    if (index >= 0) {
      final current = _integer(_items[index]['quantity'], 1);
      final available = _integer(_items[index]['availableQuantity'], 0);
      if (current + quantity > available) {
        _message(
          'No more stock available. Maximum available quantity is $available.',
        );
        return;
      }
      setState(() {
        _items[index]['quantity'] = current + quantity;
        _recalculateCoupon();
      });
    } else {
      setState(() {
        if (quantity > stock) {
          _message(
            'No more stock available. Maximum available quantity is $stock.',
          );
          return;
        }
        _items.add({...product, 'quantity': quantity});
        _recalculateCoupon();
      });
    }
    _loadSuggestedProducts();
    _message('${product['title']} added to checkout.');
  }

  void _increase(int index) {
    if (index < 0 || index >= _items.length) return;
    final item = _items[index];
    final quantity = _integer(item['quantity'], 1);
    final available = _integer(item['availableQuantity'], 0);
    if (available <= 0 || quantity >= available) {
      _message(
        available == 0
            ? 'This product is out of stock.'
            : 'No more stock available. Maximum available quantity is $available.',
      );
      return;
    }
    setState(() {
      item['quantity'] = quantity + 1;
      _recalculateCoupon();
    });
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: AppTextStyles.title),
        content: Text(
          message,
          style: AppTextStyles.caption.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _decrease(int index) async {
    if (index < 0 || index >= _items.length) return;
    final quantity = _integer(_items[index]['quantity'], 1);
    if (quantity <= 1) {
      await _removeItem(
        index,
        message:
            'Quantity is 1. Removing this item will clear it from your checkout. Are you sure?',
        confirmLabel: 'Remove item',
      );
      return;
    }
    setState(() {
      _items[index]['quantity'] = quantity - 1;
      _recalculateCoupon();
    });
  }

  Future<void> _removeItem(
    int index, {
    String? message,
    String confirmLabel = 'Remove',
    bool confirm = true,
  }) async {
    if (index < 0 || index >= _items.length) return;
    final title = _items[index]['title'].toString();
    final confirmed =
        !confirm ||
        await _confirmAction(
          title: 'Remove item?',
          message:
              message ??
              'Are you sure you want to remove "$title" from your checkout?',
          confirmLabel: confirmLabel,
        );
    if (!confirmed || !mounted || index >= _items.length) return;
    setState(() {
      _items.removeAt(index);
      _recalculateCoupon();
    });
    _loadSuggestedProducts();
    _message(
      _items.isEmpty
          ? 'Your checkout is now empty.'
          : '$title removed from checkout.',
    );
  }

  void _recalculateCoupon() {
    final code = _couponCode;
    if (code == null) return;
    final minimum = _couponMinimum(code);
    if (minimum == 0 || _subtotal < minimum) {
      _couponCode = null;
      _couponDiscount = 0;
      return;
    }
    _couponDiscount = _couponAmount(code).clamp(0.0, _subtotal).toDouble();
  }

  Future<void> _openAddMoreProducts() async {
    if (_suggestedProducts.isEmpty && !_loadingProducts) {
      await _loadSuggestedProducts();
    }
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
              child: Column(
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Browse products',
                              style: AppTextStyles.title.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Live listings from the EcoLoop marketplace',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _loadingProducts
                        ? const Center(child: CircularProgressIndicator())
                        : _productsError != null
                        ? _emptyState(
                            'Could not load products.',
                            action: () async {
                              await _loadSuggestedProducts();
                              if (mounted) setSheetState(() {});
                            },
                          )
                        : _suggestedProducts.isEmpty
                        ? _emptyState(
                            'No additional live products are available right now.',
                          )
                        : ListView.separated(
                            itemCount: _suggestedProducts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, index) {
                              final product = _suggestedProducts[index];
                              final id = product['productId'].toString();
                              final already = _items.any(
                                (i) => i['productId'].toString() == id,
                              );
                              return _suggestedProductTile(
                                product,
                                already,
                                () {
                                  _addProduct(product);
                                  setSheetState(() {});
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _browseMarketplace();
                      },
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Browse full marketplace'),
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

  Widget _suggestedProductTile(
    Map<String, dynamic> product,
    bool already,
    VoidCallback onAdd,
  ) {
    final stock = _integer(product['availableQuantity'], 0);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _productImageWidget(_productImage(product), 70, 70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(_number(product['price'])),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product['category'] ?? 'Marketplace'} · $stock available',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: OutlinedButton(
              onPressed: already || stock < 1 ? null : onAdd,
              child: Text(already ? 'Added' : 'Add'),
            ),
          ),
        ],
      ),
    );
  }

  void _openCouponSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Apply Coupon',
                      style: AppTextStyles.title.copyWith(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _couponOptionTile(
                  sheetContext,
                  code: 'ECO100',
                  title: '₹100 OFF',
                  subtitle: 'On orders of ₹1,599 or more',
                  minimumOrder: 1599,
                  discount: 100,
                ),
                const SizedBox(height: 10),
                _couponOptionTile(
                  sheetContext,
                  code: 'LOOP50',
                  title: '₹50 OFF',
                  subtitle: 'On orders of ₹999 or more',
                  minimumOrder: 999,
                  discount: 50,
                ),
                const SizedBox(height: 10),
                _couponOptionTile(
                  sheetContext,
                  code: 'RECYCLE20',
                  title: '₹20 OFF',
                  subtitle: 'On orders of ₹499 or more',
                  minimumOrder: 499,
                  discount: 20,
                ),
                if (_couponCode != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _couponCode = null;
                          _couponDiscount = 0;
                        });
                        Navigator.pop(sheetContext);
                        _message('Coupon removed.');
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Remove applied coupon'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _couponOptionTile(
    BuildContext sheetContext, {
    required String code,
    required String title,
    required String subtitle,
    required double minimumOrder,
    required double discount,
  }) {
    final applied = _couponCode == code;
    final eligible = _subtotal >= minimumOrder;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: applied
            ? AppColors.light.withValues(alpha: 0.65)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: applied
              ? AppColors.primary
              : AppColors.accent.withValues(alpha: 0.5),
          width: applied ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.confirmation_num_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTextStyles.caption),
                const SizedBox(height: 3),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                if (!eligible)
                  Text(
                    'Add ${_money(minimumOrder - _subtotal)} more to use this coupon',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: applied
                  ? null
                  : () {
                      if (!eligible) {
                        _message(
                          '$code requires a product subtotal of at least ${_money(minimumOrder)}.',
                        );
                        return;
                      }
                      setState(() {
                        _couponCode = code;
                        _couponDiscount = discount
                            .clamp(0.0, _subtotal)
                            .toDouble();
                      });
                      Navigator.pop(sheetContext);
                      _message(
                        '$code applied. You save ${_money(_couponSavings)}.',
                      );
                    },
              child: Text(applied ? 'Applied' : 'Apply'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continueToPayment() async {
    if (_proceeding) return;
    if (_items.isEmpty) {
      _message('Add at least one product to continue.');
      return;
    }
    if (_selectedAddress == null) {
      _message('Please add and select a delivery address.');
      return;
    }

    final address = Map<String, dynamic>.from(_selectedAddress!);
    final addressId =
        address['addressId'] ??
        address['address_id'] ??
        address['id'] ??
        address['ID'];
    if (addressId == null || addressId.toString().trim().isEmpty) {
      _message('Please select a saved address again before continuing.');
      return;
    }
    address['addressId'] = addressId;

    setState(() => _proceeding = true);
    try {
      // Ensure account ownership data is available before allowing payment.
      await _loadCurrentAccountAndOwnProducts();
      // Re-read authoritative product data just before checkout. The server
      // still performs final stock validation atomically during batch ordering.
      final refreshed = <Map<String, dynamic>>[];
      for (final current in _items) {
        if (_isOwnProduct(current)) {
          throw Exception(
            'You cannot checkout your own listing: ${current['title'] ?? 'Product'}. Remove it from checkout.',
          );
        }
        final id =
            (current['productId'] ??
                    current['product_id'] ??
                    current['id'] ??
                    '')
                .toString();
        final quantity = _integer(current['quantity'], 0);
        final numericId = int.tryParse(id);
        if (numericId == null || numericId <= 0 || quantity < 1) {
          throw Exception('A cart item has an invalid product ID or quantity.');
        }
        final response = await _api.get('/products/$numericId/validate');
        final root = _asMap(response);
        final product = _asMap(root['data'] ?? root['product'] ?? response);
        if (product.isEmpty) {
          throw Exception(
            'Could not validate product #$numericId. Please try again.',
          );
        }
        final normalized = _normalizeItem({...current, ...product});
        if (_isOwnProduct(normalized)) {
          throw Exception(
            'You cannot checkout your own listing: ${normalized['title']}. Remove it from checkout.',
          );
        }
        final status = (normalized['status'] ?? 'published')
            .toString()
            .toLowerCase();
        final stock = _integer(normalized['availableQuantity'], 0);
        if (status != 'published' || stock < quantity) {
          throw Exception(
            '${normalized['title']} is no longer available in the requested quantity. Update your cart.',
          );
        }
        normalized['quantity'] = quantity;
        refreshed.add(normalized);
      }
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(refreshed);
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Payment(
            totalAmount: _grandTotal,
            items: refreshed
                .map((item) => Map<String, dynamic>.from(item))
                .toList(),
            address: address,
            deliveryMethod: _selectedDelivery == 'express'
                ? 'Express Delivery'
                : 'Standard Delivery',
            savings: _couponSavings,
            couponCode: _couponCode,
            clearCartAfterSuccess: widget.clearCartAfterOrder,
          ),
        ),
      );
    } catch (error) {
      _message(
        'Could not validate checkout: ${error.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _proceeding = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _addressText(Map<String, dynamic> address) {
    final parts = <String>[];
    void addIfMissing(dynamic value) {
      if (value == null) return;
      final part = value.toString().trim();
      if (part.isEmpty) return;
      final current = parts.join(', ').toLowerCase();
      if (!current.contains(part.toLowerCase())) parts.add(part);
    }

    addIfMissing(
      address['addressLine'] ??
          address['address_line'] ??
          address['house'] ??
          address['fullAddress'] ??
          address['full_address'] ??
          address['address'],
    );
    addIfMissing(address['area'] ?? address['landmark']);
    addIfMissing(address['city']);
    addIfMissing(address['state']);
    addIfMissing(
      address['pincode'] ?? address['postalCode'] ?? address['postal_code'],
    );
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh checkout',
            onPressed: () async {
              await Future.wait([_loadAddresses(), _loadSuggestedProducts()]);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _items.isEmpty
          ? _emptyCheckout()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                    children: [
                      _buildStepIndicator(),
                      const SizedBox(height: 18),
                      _buildAddressSection(),
                      const SizedBox(height: 14),
                      _buildProductsSection(),
                      const SizedBox(height: 14),
                      _buildDeliverySection(),
                      const SizedBox(height: 14),
                      _buildCouponSection(),
                      const SizedBox(height: 14),
                      _buildPriceDetails(),
                      const SizedBox(height: 14),
                      _buildTrustSection(),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _step(1, 'Address', true),
          _stepLine(),
          _step(2, 'Order summary', true),
          _stepLine(),
          _step(3, 'Payment', false),
        ],
      ),
    );
  }

  Widget _step(int number, String title, bool active) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.primary : AppColors.light,
            ),
            child: active
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
                : Text(
                    '$number',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepLine() => Expanded(
    child: Container(
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 18),
      color: AppColors.accent.withValues(alpha: 0.7),
    ),
  );

  Widget _buildAddressSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.location_on_outlined,
            'Delivery address',
            trailing: TextButton.icon(
              onPressed: _savingAddress ? null : _addAddress,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add new'),
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingAddresses)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_addressError != null)
            _emptyState(
              'Could not load saved addresses.',
              action: _loadAddresses,
            )
          else if (_addresses.isEmpty)
            _emptyState(
              'No saved address found. Add a delivery address to continue.',
              action: _addAddress,
            )
          else
            ..._addresses.map((address) {
              final selected =
                  address['addressId'].toString() == _selectedAddressId;
              final isDefault = _isTrue(
                address['isDefault'] ?? address['is_default'],
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: InkWell(
                  onTap: () => setState(
                    () => _selectedAddressId = address['addressId'].toString(),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.light.withValues(alpha: 0.55)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.accent.withValues(alpha: 0.55),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            (address['label'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains('work')
                                ? Icons.work_outline_rounded
                                : Icons.home_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 7,
                                children: [
                                  Text(
                                    (address['label'] ?? 'Address').toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isDefault) _smallTag('DEFAULT'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (address['name'] ?? '').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _addressText(address),
                                style: AppTextStyles.caption.copyWith(
                                  height: 1.4,
                                ),
                              ),
                              if ((address['phone'] ?? '')
                                  .toString()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  address['phone'].toString(),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.shopping_bag_outlined,
            'Order summary',
            trailing: Text(
              '${_totalQuantity} item${_totalQuantity == 1 ? '' : 's'}',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_items.length, (index) => _buildProductRow(index)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAddMoreProducts,
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              label: const Text('Browse products / Add another item'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(int index) {
    final item = _items[index];
    final quantity = _integer(item['quantity'], 1);
    final stock = _integer(item['availableQuantity'], 0);
    final lineTotal = _number(item['price']) * quantity;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _productImageWidget(_productImage(item), 78, 78),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(_number(item['price'])),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  (item['seller'] ?? 'EcoLoop Seller').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 9),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _quantityControl(
                      quantity: quantity,
                      onMinus: () => _decrease(index),
                      onPlus: () => _increase(index),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _money(lineTotal),
                            maxLines: 1,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Remove item',
            visualDensity: VisualDensity.compact,
            onPressed: () => _removeItem(index),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _openDeliveryOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Delivery Options', style: AppTextStyles.title),
                ),
                const SizedBox(height: 12),
                _deliveryOption(
                  sheetContext,
                  id: 'standard',
                  title: 'Standard Delivery',
                  subtitle: 'Same city ₹40 • Other city ₹59 per seller',
                  price: _standardDeliveryFee == 0
                      ? 'FREE'
                      : _money(_standardDeliveryFee),
                  icon: Icons.local_shipping_outlined,
                ),
                const SizedBox(height: 10),
                _deliveryOption(
                  sheetContext,
                  id: 'express',
                  title: 'Express Delivery',
                  subtitle: 'Same city ₹69 • Other city ₹99 per seller',
                  price: _expressDeliveryFee == 0
                      ? 'FREE'
                      : _money(_expressDeliveryFee),
                  icon: Icons.speed_outlined,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _deliveryOption(
    BuildContext sheetContext, {
    required String id,
    required String title,
    required String subtitle,
    required String price,
    required IconData icon,
  }) {
    final selected = _selectedDelivery == id;

    return InkWell(
      onTap: () {
        setState(() => _selectedDelivery = id);
        Navigator.pop(sheetContext);
      },
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.light : AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: price == 'FREE'
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    final isFree = _deliveryFee == 0;

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionIcon(Icons.local_shipping_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delivery',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
              ),
              TextButton(
                onPressed: _openDeliveryOptions,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Change',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    _selectedDelivery == 'express'
                        ? Icons.speed_outlined
                        : Icons.local_shipping_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDelivery == 'express'
                            ? 'Express Delivery'
                            : 'Standard Delivery',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _selectedDelivery == 'express'
                            ? '1–2 business days'
                            : '3–5 business days',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  isFree ? 'FREE' : _money(_deliveryFee),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isFree ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _items.isNotEmpty && _items.every(_isFreeDeliveryProduct)
                ? 'Free Delivery selected on all products in this order.'
                : 'Delivery is charged once per seller. Free Delivery listings add no delivery charge.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    final applied = _couponCode != null && _couponSavings > 0;
    return _sectionCard(
      child: Column(
        children: [
          Row(
            children: [
              _sectionIcon(Icons.local_offer_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      applied ? 'Coupon Applied' : 'Apply Coupon',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      applied
                          ? '$_couponCode • You saved ${_money(_couponSavings)}'
                          : 'Save more on your EcoLoop order',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _openCouponSheet,
                child: Text(
                  applied ? 'Change' : 'Apply',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!applied) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: _openCouponSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.confirmation_num_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'View all available coupons',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceDetails() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(Icons.receipt_long_outlined, 'Price details'),
          const SizedBox(height: 14),
          _priceRow('Items subtotal', _money(_subtotal)),
          const SizedBox(height: 10),
          _priceRow('Platform fee', _money(_platformFee)),
          const SizedBox(height: 10),
          _priceRow('GST on platform fee (18%)', _money(_taxes)),
          const SizedBox(height: 10),
          _priceRow(
            'Delivery charges',
            _deliveryFee == 0 ? 'FREE' : _money(_deliveryFee),
            valueColor: _deliveryFee == 0 ? AppColors.primary : null,
          ),
          if (_couponSavings > 0) ...[
            const SizedBox(height: 10),
            _priceRow(
              'Coupon savings',
              '−${_money(_couponSavings)}',
              valueColor: AppColors.primary,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1),
          ),
          _priceRow('Total payable', _money(_grandTotal), bold: true),
          const SizedBox(height: 8),
          Text(
            'Fees shown here are estimates. The backend must revalidate price, stock, discounts and payable total when an order is created.',
            style: AppTextStyles.caption.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustSection() {
    return _sectionCard(
      child: Column(
        children: [
          _trustRow(
            Icons.verified_user_outlined,
            'Secure checkout',
            'Your order is linked to your EcoLoop account.',
          ),
          const SizedBox(height: 12),
          _trustRow(
            Icons.recycling_outlined,
            'A second life for every item',
            'Buying reused items supports a circular economy.',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.accent.withValues(alpha: 0.35)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL PAYABLE',
                  style: AppTextStyles.caption.copyWith(letterSpacing: 0.7),
                ),
                const SizedBox(height: 3),
                Text(
                  _money(_grandTotal),
                  style: AppTextStyles.title.copyWith(
                    fontSize: 22,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _proceeding || _loadingAddresses || _items.isEmpty
                    ? null
                    : _continueToPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _proceeding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Continue to payment',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.button.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCheckout() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sectionIcon(Icons.shopping_bag_outlined),
            const SizedBox(height: 14),
            Text(
              'Your checkout is empty',
              style: AppTextStyles.title.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 7),
            Text(
              'Browse live EcoLoop listings and add an item to begin.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _browseMarketplace,
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Browse marketplace'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message, {Future<void> Function()? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
          if (action != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: action, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: _cardDecoration(),
    child: child,
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(19),
    border: Border.all(color: AppColors.accent.withValues(alpha: 0.38)),
  );

  Widget _sectionHeading(IconData icon, String title, {Widget? trailing}) {
    return Row(
      children: [
        _sectionIcon(icon),
        const SizedBox(width: 11),
        Expanded(
          child: Text(title, style: AppTextStyles.title.copyWith(fontSize: 17)),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _sectionIcon(IconData icon) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: AppColors.light,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: AppColors.primary, size: 21),
  );

  Widget _smallTag(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.light,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    ),
  );

  Widget _priceRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 18 : 13,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            color:
                valueColor ??
                (bold ? AppColors.primary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _trustRow(IconData icon, String title, String subtitle) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.primary, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(subtitle, style: AppTextStyles.caption.copyWith(height: 1.35)),
          ],
        ),
      ),
    ],
  );

  Widget _quantityControl({
    required int quantity,
    required VoidCallback onMinus,
    VoidCallback? onPlus,
  }) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(Icons.remove_rounded, onMinus),
          SizedBox(
            width: 30,
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          _quantityButton(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback? onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 30,
      height: 34,
      child: Icon(
        icon,
        size: 16,
        color: onTap == null
            ? AppColors.textSecondary.withValues(alpha: 0.5)
            : AppColors.primary,
      ),
    ),
  );

  Widget _productImageWidget(String image, double width, double height) {
    if (image.trim().isEmpty) return _imagePlaceholder(width, height);
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Image.network(
        image,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(width, height),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : _imagePlaceholder(width, height, loading: true),
      ),
    );
  }

  Widget _imagePlaceholder(
    double width,
    double height, {
    bool loading = false,
  }) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.light,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Center(
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : const Icon(
              Icons.image_outlined,
              size: 29,
              color: AppColors.primary,
            ),
    ),
  );

  Widget _sheetHandle() => Center(
    child: Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}
