import 'package:flutter/material.dart';
import 'package:ecoloop/services/ecoloop_api.dart';
import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import 'payment.dart';

class Checkout extends StatefulWidget {
  final List<Map<String, dynamic>>? items;
  final Map<String, dynamic>? product;
  final int quantity;
  final String? initialCouponCode;
  final double initialCouponDiscount;
  final double initialEcoPointDiscount;

  const Checkout({super.key, this.items, this.product, this.quantity = 1, this.initialCouponCode, this.initialCouponDiscount = 0, this.initialEcoPointDiscount = 0});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;
  bool _loadingAddresses = true;
  bool _savingAddress = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.items != null) {
      for (final item in widget.items!) { _items.add(_normalizeItem(item)); }
    } else if (widget.product != null) {
      final item = Map<String, dynamic>.from(widget.product!);
      item['quantity'] = widget.quantity;
      _items.add(_normalizeItem(item));
    }
    _loadAddresses();
  }

  Map<String, dynamic> _normalizeItem(Map<String, dynamic> item) {
    final copy = Map<String, dynamic>.from(item);
    copy['productId'] = copy['productId'] ?? copy['id'];
    copy['title'] = copy['title'] ?? copy['name'] ?? 'Product';
    copy['price'] = _number(copy['price']);
    copy['quantity'] = _integer(copy['quantity'], 1);
    return copy;
  }

  double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse((value ?? '').toString().replaceAll(',', '')) ?? 0;
  int _integer(dynamic value, [int fallback = 0]) => value is num ? value.toInt() : int.tryParse((value ?? '').toString()) ?? fallback;
  double get _subtotal => _items.fold<double>(0, (sum, item) => sum + _number(item['price']) * _integer(item['quantity'], 1));
  String _money(num value) => '₹${value.round()}';

  Future<void> _loadAddresses() async {
    if (mounted) setState(() { _loadingAddresses = true; _error = null; });
    try {
      final data = await EcoLoopApi.instance.get('/addresses');
      final rows = data is List ? data.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList() : <Map<String, dynamic>>[];
      if (!mounted) return;
      Map<String, dynamic>? defaultAddress;
      for (final row in rows) {
        if (row['isDefault'] == true) { defaultAddress = row; break; }
      }
      setState(() {
        _addresses = rows;
        final exists = rows.any((row) => (row['addressId'] ?? row['id']).toString() == _selectedAddressId);
        _selectedAddressId = exists ? _selectedAddressId : (defaultAddress?['addressId'] ?? defaultAddress?['id'] ?? (rows.isNotEmpty ? rows.first['addressId'] ?? rows.first['id'] : null))?.toString();
        _loadingAddresses = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _loadingAddresses = false; _error = error.toString(); });
    }
  }

  Map<String, dynamic>? get _selectedAddress {
    for (final address in _addresses) {
      if ((address['addressId'] ?? address['id']).toString() == _selectedAddressId) return address;
    }
    return null;
  }

  Future<void> _addAddress() async {
    final formKey = GlobalKey<FormState>();
    final fields = <String, TextEditingController>{
      'label': TextEditingController(text: 'Home'),
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'addressLine': TextEditingController(),
      'area': TextEditingController(),
      'city': TextEditingController(),
      'state': TextEditingController(),
      'pincode': TextEditingController(),
    };
    bool isDefault = _addresses.isEmpty;
    final shouldSave = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      title: const Text('Add delivery address'),
      content: SizedBox(width: 480, child: Form(key: formKey, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final entry in fields.entries)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: TextFormField(
            controller: entry.value,
            keyboardType: entry.key == 'phone' || entry.key == 'pincode' ? TextInputType.phone : TextInputType.text,
            decoration: InputDecoration(labelText: _fieldLabel(entry.key), border: const OutlineInputBorder()),
            validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
          )),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: isDefault, onChanged: (value) => setDialogState(() => isDefault = value ?? false), title: const Text('Set as default address')),
      ])))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('Save address')),
      ],
    )));

    if (shouldSave == true) {
      setState(() => _savingAddress = true);
      try {
        final payload = <String, dynamic>{for (final entry in fields.entries) entry.key: entry.value.text.trim(), 'isDefault': isDefault};
        final result = await EcoLoopApi.instance.post('/addresses', payload);
        await _loadAddresses();
        if (mounted && result is Map) {
          final id = result['addressId'] ?? result['id'];
          if (id != null) setState(() => _selectedAddressId = id.toString());
        }
      } catch (error) {
        if (mounted) _message('Could not save address: $error');
      } finally {
        if (mounted) setState(() => _savingAddress = false);
      }
    }
    for (final controller in fields.values) { controller.dispose(); }
  }

  String _fieldLabel(String key) {
    const labels = {'label': 'Address label', 'name': 'Recipient name', 'phone': 'Phone number', 'addressLine': 'House / street address', 'area': 'Area / landmark', 'city': 'City', 'state': 'State', 'pincode': 'PIN code'};
    return labels[key] ?? key;
  }

  void _continue() {
    if (_items.isEmpty) { _message('Your cart is empty.'); return; }
    final address = _selectedAddress;
    if (address == null) { _message('Please add and select a delivery address.'); return; }
    Navigator.push(context, MaterialPageRoute(builder: (_) => Payment(totalAmount: _subtotal, items: List<Map<String, dynamic>>.from(_items), address: address, deliveryMethod: 'Standard Delivery')));
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(backgroundColor: AppColors.background, foregroundColor: AppColors.textPrimary, elevation: 0, title: const Text('Checkout')),
    body: _items.isEmpty ? const Center(child: Text('No items to checkout.')) : ListView(padding: const EdgeInsets.all(18), children: [
      Text('Delivery address', style: AppTextStyles.title.copyWith(fontSize: 18)),
      const SizedBox(height: 10),
      if (_loadingAddresses) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
      else if (_addresses.isEmpty) _emptyAddresses()
      else ..._addresses.map(_addressCard),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: _savingAddress ? null : _addAddress, icon: const Icon(Icons.add), label: Text(_savingAddress ? 'Saving…' : 'Add new address')),
      if (_error != null) TextButton.icon(onPressed: _loadAddresses, icon: const Icon(Icons.refresh), label: const Text('Retry loading addresses')),
      const SizedBox(height: 24),
      Text('Order summary', style: AppTextStyles.title.copyWith(fontSize: 18)),
      const SizedBox(height: 10),
      ..._items.map((item) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(13), decoration: _cardDecoration(), child: Row(children: [
        _productThumb(item), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['title'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text('Qty ${item['quantity']}', style: AppTextStyles.caption)])),
        Text(_money(_number(item['price']) * _integer(item['quantity'], 1)), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
      ]))),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(16), decoration: _cardDecoration(), child: Column(children: [
        _summaryRow('Items subtotal', _money(_subtotal)),
        const Divider(height: 22),
        _summaryRow('Total payable', _money(_subtotal), bold: true),
        const SizedBox(height: 8),
        Text('Delivery fees and discounts are not included unless returned by the backend.', style: AppTextStyles.caption),
      ])),
      const SizedBox(height: 20),
      SizedBox(height: 52, child: FilledButton(onPressed: _loadingAddresses ? null : _continue, child: Text('Continue to payment · ${_money(_subtotal)}'))),
    ]),
  );

  Widget _emptyAddresses() => Container(padding: const EdgeInsets.all(18), decoration: _cardDecoration(), child: const Column(children: [Icon(Icons.location_off_outlined, size: 30, color: AppColors.primary), SizedBox(height: 8), Text('No saved addresses yet'), Text('Add a real delivery address to continue.')]));

  Widget _addressCard(Map<String, dynamic> address) {
    final id = (address['addressId'] ?? address['id']).toString();
    final selected = id == _selectedAddressId;
    final addressText = [address['addressLine'] ?? address['address'], address['area'], address['city'], address['state'], address['pincode']].where((value) => value != null && value.toString().trim().isNotEmpty).join(', ');
    return InkWell(
      onTap: () => setState(() => _selectedAddressId = id),
      borderRadius: BorderRadius.circular(16),
      child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? AppColors.primary : AppColors.accent.withValues(alpha: .45), width: selected ? 1.5 : 1)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text((address['label'] ?? 'Address').toString(), style: const TextStyle(fontWeight: FontWeight.w700)), if (address['isDefault'] == true) const Padding(padding: EdgeInsets.only(left: 8), child: Chip(label: Text('Default'), visualDensity: VisualDensity.compact))]),
          Text((address['name'] ?? '').toString()),
          Text((address['phone'] ?? '').toString()),
          Text(addressText),
        ])),
      ])),
    );
  }

  Widget _productThumb(Map<String, dynamic> item) {
    final raw = item['image'] ?? item['imageUrl'] ?? ((item['imageUrls'] is List && (item['imageUrls'] as List).isNotEmpty) ? item['imageUrls'][0] : '');
    final url = raw.toString();
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 56, height: 56, child: url.startsWith('http') ? Image.network(url, fit: BoxFit.cover, errorBuilder: (context, error, stack) => _thumbFallback()) : _thumbFallback()));
  }
  Widget _thumbFallback() => Container(color: AppColors.light, child: const Icon(Icons.recycling, color: AppColors.primary));
  BoxDecoration _cardDecoration() => BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accent.withValues(alpha: .4)));
  Widget _summaryRow(String label, String value, {bool bold = false}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400)), Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? AppColors.primary : AppColors.textPrimary))]);
}
