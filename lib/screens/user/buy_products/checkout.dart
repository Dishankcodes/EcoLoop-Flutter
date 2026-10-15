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

  const Checkout({
    super.key,
    this.items,
    this.product,
    this.quantity = 1,
    this.initialCouponCode,
    this.initialCouponDiscount = 0,
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

  String? _selectedAddressId;
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
    _couponCode = widget.initialCouponCode;
    _couponDiscount = widget.initialCouponDiscount;

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
    _loadSuggestedProducts();
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
      1,
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

  double get _platformFee => _items.fold<double>(0, (sum, item) {
    final line = _number(item['price']) * _integer(item['quantity'], 1);
    return sum + (line * 0.02).roundToDouble();
  });

  double get _taxes => _items.fold<double>(0, (sum, item) {
    final line = _number(item['price']) * _integer(item['quantity'], 1);
    final fee = (line * 0.02).roundToDouble();
    return sum + (fee * 0.18).roundToDouble();
  });

  double get _deliveryCharges {
    final buyerCity = (_selectedAddress?['city'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (buyerCity.isEmpty) return 0;
    return _items.fold<double>(0, (sum, item) {
      final sellerCity = (item['sellerCity'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      return sum + (sellerCity.isNotEmpty && sellerCity != buyerCity ? 40 : 0);
    });
  }

  double get _couponSavings => _couponDiscount.clamp(0.0, _subtotal).toDouble();

  double get _grandTotal {
    final value =
        _subtotal + _platformFee + _taxes + _deliveryCharges - _couponSavings;
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

  Future<void> _loadAddresses() async {
    if (!mounted) return;
    setState(() {
      _loadingAddresses = true;
      _addressError = null;
    });
    try {
      final response = await _api.get('/addresses');
      final rows = _extractRows(response);
      final addresses = rows
          .map((raw) {
            final address = Map<String, dynamic>.from(raw);
            address['addressId'] =
                address['addressId'] ?? address['address_id'] ?? address['id'];
            address['label'] = address['label'] ?? address['type'] ?? 'Address';
            address['addressLine'] =
                address['addressLine'] ??
                address['address_line'] ??
                [address['house'], address['street']]
                    .where((v) => v != null && v.toString().trim().isNotEmpty)
                    .join(', ');
            address['area'] = address['area'] ?? address['landmark'] ?? '';
            return address;
          })
          .where((a) => (a['addressId'] ?? '').toString().isNotEmpty)
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
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingAddresses = false;
        _addressError = error.toString();
      });
    }
  }

  Future<void> _loadSuggestedProducts() async {
    if (!mounted) return;
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
      if (address['addressId'].toString() == _selectedAddressId) return address;
    }
    return null;
  }

  Future<void> _addAddress() async {
    if (_savingAddress) return;
    setState(() => _savingAddress = true);
    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (_) => const AddAddress()),
      );
      await _loadAddresses();
      if (!mounted) return;
      if (result != null) {
        final resultId =
            result['addressId'] ?? result['address_id'] ?? result['id'];
        if (resultId != null &&
            _addresses.any(
              (a) => a['addressId'].toString() == resultId.toString(),
            )) {
          setState(() => _selectedAddressId = resultId.toString());
        } else if (_addresses.isNotEmpty) {
          final match = _addresses.where(
            (a) =>
                (a['name'] ?? '').toString().trim() ==
                    (result['name'] ?? '').toString().trim() &&
                (a['phone'] ?? '').toString().trim() ==
                    (result['phone'] ?? '').toString().trim() &&
                (a['city'] ?? '').toString().trim() ==
                    (result['city'] ?? '').toString().trim(),
          );
          if (match.isNotEmpty)
            setState(
              () => _selectedAddressId = match.last['addressId'].toString(),
            );
        }
      }
    } catch (error) {
      _message('Could not open Add Address: $error');
    } finally {
      if (mounted) setState(() => _savingAddress = false);
    }
  }

  void _addProduct(Map<String, dynamic> source) {
    final product = _normalizeItem(source);
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
      if (current >= available) {
        _message('Maximum available quantity already added.');
        return;
      }
      setState(() => _items[index]['quantity'] = current + 1);
    } else {
      setState(() => _items.add({...product, 'quantity': 1}));
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
            : 'Only $available available.',
      );
      return;
    }
    setState(() => item['quantity'] = quantity + 1);
  }

  void _decrease(int index) {
    if (index < 0 || index >= _items.length) return;
    final quantity = _integer(_items[index]['quantity'], 1);
    if (quantity <= 1) {
      _removeItem(index);
    } else {
      setState(() => _items[index]['quantity'] = quantity - 1);
    }
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    final title = _items[index]['title'].toString();
    setState(() => _items.removeAt(index));
    _loadSuggestedProducts();
    _message('$title removed from checkout.');
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Marketplace(),
                          ),
                        );
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
    final controller = TextEditingController(text: _couponCode ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 18),
              Text(
                'Apply coupon',
                style: AppTextStyles.title.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a coupon code issued by EcoLoop. Discount is not applied until the backend confirms its validity.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Coupon code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final code = controller.text.trim().toUpperCase();
                    if (code.isEmpty) {
                      _message('Enter a coupon code.');
                      return;
                    }
                    // Do not fabricate a discount: coupon validation must be implemented server-side.
                    _message(
                      'Coupon validation is not enabled in this API yet. No discount was applied.',
                    );
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Validate coupon'),
                ),
              ),
              if (_couponCode != null && _couponCode!.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _couponCode = null;
                      _couponDiscount = 0;
                    });
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Remove existing coupon'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _continueToPayment() {
    if (_proceeding) return;
    if (_items.isEmpty) {
      _message('Add at least one product to continue.');
      return;
    }
    for (final item in _items) {
      final id = item['productId'].toString();
      final quantity = _integer(item['quantity'], 0);
      final stock = _integer(item['availableQuantity'], 0);
      if (id.isEmpty || quantity < 1 || quantity > stock) {
        _message('Please check product IDs and quantities before continuing.');
        return;
      }
    }
    if (_selectedAddress == null) {
      _message('Please add and select a delivery address.');
      return;
    }

    final address = Map<String, dynamic>.from(_selectedAddress!);
    address['addressId'] = address['addressId'] ?? address['id'];
    final savings = _couponSavings;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Payment(
          totalAmount: _grandTotal,
          items: _items.map((item) => Map<String, dynamic>.from(item)).toList(),
          address: address,
          deliveryMethod: 'Standard Delivery',
          savings: savings,
        ),
      ),
    );
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _addressText(Map<String, dynamic> address) {
    final parts =
        [
              address['addressLine'] ??
                  address['address_line'] ??
                  address['house'] ??
                  address['address'],
              address['area'] ?? address['landmark'],
              address['city'],
              address['state'],
              address['pincode'] ??
                  address['postalCode'] ??
                  address['postal_code'],
            ]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .map((value) => value.toString().trim())
            .toList();
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
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _quantityControl(
                      quantity: quantity,
                      onMinus: () => _decrease(index),
                      onPlus: stock > quantity ? () => _increase(index) : null,
                    ),
                    const Spacer(),
                    Text(
                      _money(lineTotal),
                      style: const TextStyle(fontWeight: FontWeight.w800),
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

  Widget _buildDeliverySection() {
    final city = (_selectedAddress?['city'] ?? '').toString();
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(Icons.local_shipping_outlined, 'Delivery details'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.light.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Standard delivery',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Delivery fee is calculated using the saved address and seller city.',
                        style: AppTextStyles.caption.copyWith(height: 1.35),
                      ),
                    ],
                  ),
                ),
                Text(
                  _deliveryCharges == 0 ? 'FREE' : _money(_deliveryCharges),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _deliveryCharges == 0
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            city.isEmpty
                ? 'Select a delivery address to calculate delivery charges.'
                : '₹40 per item applies when the buyer and seller are in different cities.',
            style: AppTextStyles.caption.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return _sectionCard(
      child: Row(
        children: [
          _sectionIcon(Icons.local_offer_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coupons & offers',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  _couponCode == null
                      ? 'Use an eligible EcoLoop coupon'
                      : 'Coupon: $_couponCode',
                  style: AppTextStyles.caption,
                ),
                if (_couponSavings > 0)
                  Text(
                    'Savings: ${_money(_couponSavings)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openCouponSheet,
            child: Text(_couponCode == null ? 'Apply' : 'Change'),
          ),
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
          _priceRow('Platform fee (2%)', _money(_platformFee)),
          const SizedBox(height: 10),
          _priceRow('GST on platform fee (18%)', _money(_taxes)),
          const SizedBox(height: 10),
          _priceRow(
            'Delivery charges',
            _deliveryCharges == 0 ? 'FREE' : _money(_deliveryCharges),
            valueColor: _deliveryCharges == 0 ? AppColors.primary : null,
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Marketplace()),
              ),
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
