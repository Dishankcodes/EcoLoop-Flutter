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

  const Checkout({super.key, this.items, this.product, this.quantity = 1,
    this.initialCouponCode, this.initialCouponDiscount = 0, this.initialEcoPointDiscount = 0});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _addresses = [];
  String? _selectedAddressId;
  bool _loadingAddresses = true;
  bool _savingAddress = false;
  bool _proceeding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.items != null) {
      for (final item in widget.items!) { _items.add(_normalizeItem(item)); }
    } else if (widget.product != null) {
      final item = Map<String, dynamic>.from(widget.product!)..['quantity'] = widget.quantity;
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
    copy['availableQuantity'] = _integer(copy['availableQuantity'] ?? copy['stock'], 1);
    return copy;
  }
  double _number(dynamic v) => v is num ? v.toDouble() : double.tryParse((v ?? '').toString().replaceAll(',', '')) ?? 0;
  int _integer(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : int.tryParse((v ?? '').toString()) ?? fallback;
  double get _subtotal => _items.fold(0, (sum, item) => sum + _number(item['price']) * _integer(item['quantity'], 1));
  String _money(num value) => '₹${value.round()}';

  Future<void> _loadAddresses() async {
    setState(() { _loadingAddresses = true; _error = null; });
    try {
      final data = await EcoLoopApi.instance.get('/addresses');
      final list = data is List ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _addresses = list;
        Map<String, dynamic>? defaultAddress;
        for (final address in list) {
          if (address['isDefault'] == true) { defaultAddress = address; break; }
        }
        _selectedAddressId = list.any((a) => a['addressId'].toString() == _selectedAddressId)
          ? _selectedAddressId : (defaultAddress?['addressId'] ?? (list.isNotEmpty ? list.first['addressId'] : null))?.toString();
        _loadingAddresses = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingAddresses = false; _error = e.toString(); });
    }
  }

  Map<String, dynamic>? get _selectedAddress {
    for (final address in _addresses) {
      if (address['addressId'].toString() == _selectedAddressId) return address;
    }
    return null;
  }

  Future<void> _addAddress() async {
    final formKey = GlobalKey<FormState>();
    final controllers = <String, TextEditingController>{
      'label': TextEditingController(text: 'Home'), 'name': TextEditingController(),
      'phone': TextEditingController(), 'addressLine': TextEditingController(),
      'area': TextEditingController(), 'city': TextEditingController(),
      'state': TextEditingController(), 'pincode': TextEditingController(),
    };
    bool makeDefault = _addresses.isEmpty;
    final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
      backgroundColor: AppColors.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) => SafeArea(
        child: Padding(padding: EdgeInsets.fromLTRB(20, 22, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Form(key: formKey, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Add delivery address', style: AppTextStyles.title.copyWith(fontSize: 20)), const SizedBox(height: 16),
            for (final field in const [
              ('label','Label (Home / Work)',false),('name','Recipient name',false),('phone','Phone number',false),
              ('addressLine','House / street address',false),('area','Area / landmark',true),('city','City',false),('state','State',false),('pincode','PIN code',false)])
              Padding(padding: const EdgeInsets.only(bottom: 10), child: TextFormField(controller: controllers[field.$1], decoration: InputDecoration(labelText: field.$2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: field.$1 == 'phone' || field.$1 == 'pincode' ? TextInputType.phone : TextInputType.text,
                validator: field.$3 ? null : (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
            CheckboxListTile(contentPadding: EdgeInsets.zero, value: makeDefault, onChanged: (v) => setSheetState(() => makeDefault = v ?? false), title: const Text('Set as default address')),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(sheetContext, true);
            }, child: const Text('Save address'))),
           ])))))),
       );
    if (saved == true) {
      setState(() => _savingAddress = true);
      try {
        final payload = <String, dynamic>{for (final entry in controllers.entries) entry.key: entry.value.text.trim(), 'isDefault': makeDefault};
        final response = await EcoLoopApi.instance.post('/addresses', payload);
        if (!mounted) return;
        await _loadAddresses();
        if (response is Map && response['addressId'] != null) setState(() => _selectedAddressId = response['addressId'].toString());
      } catch (e) { if (mounted) _message('Could not save address: $e'); }
      finally { for (final c in controllers.values) { c.dispose(); } if (mounted) setState(() => _savingAddress = false); }
    } else { for (final c in controllers.values) { c.dispose(); } }
  }

  void _continue() {
    if (_items.isEmpty) { _message('Your cart is empty.'); return; }
    if (_selectedAddress == null) { _message('Please add and select a delivery address.'); return; }
    Navigator.push(context, MaterialPageRoute(builder: (_) => Payment(totalAmount: _subtotal,
      items: List<Map<String, dynamic>>.from(_items), address: _selectedAddress,
      deliveryMethod: 'Standard Delivery')));
  }
  void _message(String value) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value), behavior: SnackBarBehavior.floating)); }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.background,
    appBar: AppBar(backgroundColor: AppColors.background, foregroundColor: AppColors.textPrimary, elevation: 0, title: const Text('Checkout')),
    body: _items.isEmpty ? const Center(child: Text('No items to checkout.')) : ListView(padding: const EdgeInsets.all(18), children: [
      _heading('Delivery address'), const SizedBox(height: 10),
      if (_loadingAddresses) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
      else if (_addresses.isEmpty) _emptyAddresses()
      else ..._addresses.map((a) => _addressCard(a)),
      const SizedBox(height: 8), OutlinedButton.icon(onPressed: _savingAddress ? null : _addAddress, icon: const Icon(Icons.add), label: Text(_savingAddress ? 'Saving…' : 'Add new address')),
      if (_error != null) TextButton.icon(onPressed: _loadAddresses, icon: const Icon(Icons.refresh), label: const Text('Retry loading addresses')),
      const SizedBox(height: 24), _heading('Order summary'), const SizedBox(height: 10),
      ..._items.map((item) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(13), decoration: _cardDecoration(), child: Row(children: [
        _productThumb(item), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['title'].toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text('Qty ${item['quantity']}', style: AppTextStyles.caption)])), Text(_money(_number(item['price']) * _integer(item['quantity'], 1)), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))]))),
      const SizedBox(height: 10), Container(padding: const EdgeInsets.all(16), decoration: _cardDecoration(), child: Column(children: [
        _summaryRow('Items subtotal', _money(_subtotal)), const Divider(height: 22), _summaryRow('Total payable', _money(_subtotal), bold: true),
        const SizedBox(height: 8), Text('Shipping and discounts are not added unless calculated by the backend. Payment is collected on delivery.', style: AppTextStyles.caption),
      ])), const SizedBox(height: 20),
      SizedBox(height: 52, child: FilledButton(onPressed: _proceeding || _loadingAddresses ? null : _continue, child: Text(_proceeding ? 'Please wait…' : 'Continue to payment · ${_money(_subtotal)}'))),
    ]));

  Widget _emptyAddresses() => Container(padding: const EdgeInsets.all(18), decoration: _cardDecoration(), child: const Column(children: [Icon(Icons.location_off_outlined, size: 30, color: AppColors.primary), SizedBox(height: 8), Text('No saved addresses yet'), Text('Add a real delivery address to continue.') ]));
  Widget _addressCard(Map<String, dynamic> a) { final selected = a['addressId'].toString() == _selectedAddressId; final text = [a['addressLine'], a['area'], a['city'], a['state'], a['pincode']].where((x) => x != null && x.toString().trim().isNotEmpty).join(', '); return InkWell(onTap: () => setState(() => _selectedAddressId = a['addressId'].toString()), borderRadius: BorderRadius.circular(16), child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? AppColors.primary : AppColors.accent.withValues(alpha: .45), width: selected ? 1.5 : 1)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.primary), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text((a['label'] ?? 'Address').toString(), style: const TextStyle(fontWeight: FontWeight.w700)), if (a['isDefault'] == true) const Padding(padding: EdgeInsets.only(left: 8), child: Chip(label: Text('Default'), visualDensity: VisualDensity.compact))]), Text((a['name'] ?? '').toString()), Text((a['phone'] ?? '').toString()), Text(text),]))]))); }
  Widget _productThumb(Map<String, dynamic> item) { final raw = item['image'] ?? item['imageUrl'] ?? ((item['imageUrls'] is List && (item['imageUrls'] as List).isNotEmpty) ? item['imageUrls'][0] : ''); final url = raw.toString(); return ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 56, height: 56, child: url.startsWith('http') ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _thumbFallback()) : _thumbFallback())); }
  Widget _thumbFallback() => Container(color: AppColors.light, child: const Icon(Icons.recycling, color: AppColors.primary));
  Widget _heading(String value) => Text(value, style: AppTextStyles.title.copyWith(fontSize: 18));
  BoxDecoration _cardDecoration() => BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accent.withValues(alpha: .4)));
  Widget _summaryRow(String label, String value, {bool bold = false}) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400)), Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? AppColors.primary : AppColors.textPrimary))]);
}
