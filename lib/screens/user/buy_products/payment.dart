import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
import 'order_success.dart';

class Payment extends StatefulWidget {
  const Payment({
    super.key,
    required this.totalAmount,
    this.items,
    this.address,
    this.deliveryMethod = 'Standard Delivery',
    this.savings = 0,
  });

  final double totalAmount;
  final List<Map<String, dynamic>>? items;
  final Map<String, dynamic>? address;
  final String deliveryMethod;
  final double savings;

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  // ---------------------------------------------------------------------------
  // PAYMENT METHOD
  // ---------------------------------------------------------------------------

  String _selectedMethod = 'upi';

  String? _selectedUpiApp;

  String? _selectedBank;

  bool _isProcessing = false;

  // ---------------------------------------------------------------------------
  // CONTROLLERS
  // ---------------------------------------------------------------------------

  final TextEditingController _upiController = TextEditingController();

  final TextEditingController _cardNumberController = TextEditingController();

  final TextEditingController _cardNameController = TextEditingController();

  final TextEditingController _expiryController = TextEditingController();

  final TextEditingController _cvvController = TextEditingController();

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _upiController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _formatPrice(double value) {
    return '₹${value.round()}';
  }

  String _formatIndianPrice(double value) {
    final number = value.round().toString();

    if (number.length <= 3) {
      return '₹$number';
    }

    final lastThree = number.substring(number.length - 3);

    var remaining = number.substring(0, number.length - 3);

    final parts = <String>[];

    while (remaining.length > 2) {
      parts.insert(0, remaining.substring(remaining.length - 2));

      remaining = remaining.substring(0, remaining.length - 2);
    }

    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return '₹${parts.join(',')},$lastThree';
  }

  String _productImage(Map<String, dynamic> item) {
    final image = item['image'];

    if (image is String && image.trim().isNotEmpty) {
      return image;
    }

    final imageUrl = item['imageUrl'];

    if (imageUrl is String && imageUrl.trim().isNotEmpty) {
      return imageUrl;
    }

    final imageUrls = item['imageUrls'];

    if (imageUrls is List && imageUrls.isNotEmpty) {
      return imageUrls.first.toString();
    }

    final images = item['images'];

    if (images is List && images.isNotEmpty) {
      return images.first.toString();
    }

    return '';
  }

  String _productTitle(Map<String, dynamic> item) {
    return (item['title'] ?? item['name'] ?? 'EcoLoop Product').toString();
  }

  int _productQuantity(Map<String, dynamic> item) {
    final quantity = item['quantity'];

    if (quantity is int) {
      return quantity;
    }

    if (quantity is num) {
      return quantity.toInt();
    }

    return int.tryParse(quantity?.toString() ?? '') ?? 1;
  }

  // ---------------------------------------------------------------------------
  // PAYMENT METHOD SELECTION
  // ---------------------------------------------------------------------------

  void _selectMethod(String method) {
    setState(() {
      _selectedMethod = method;

      if (method != 'upi') {
        _selectedUpiApp = null;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // PAYMENT ACTION
  // ---------------------------------------------------------------------------

  Future<void> _payNow() async {
    if (_isProcessing) {
      return;
    }

    if (_selectedMethod == 'upi') {
      if (_selectedUpiApp == null && _upiController.text.trim().isEmpty) {
        _showMessage('Select a UPI app or enter your UPI ID.');
        return;
      }
    }

    if (_selectedMethod == 'card') {
      if (_cardNumberController.text.replaceAll(' ', '').length < 12) {
        _showMessage('Please enter a valid card number.');
        return;
      }

      if (_cardNameController.text.trim().isEmpty) {
        _showMessage('Please enter the name on your card.');
        return;
      }

      if (_expiryController.text.trim().isEmpty) {
        _showMessage('Please enter card expiry.');
        return;
      }

      if (_cvvController.text.trim().length < 3) {
        _showMessage('Please enter a valid CVV.');
        return;
      }
    }

    if (_selectedMethod == 'netbanking' && _selectedBank == null) {
      _showMessage('Please select your bank.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // -------------------------------------------------------------------------
    // UI-ONLY PAYMENT SIMULATION
    // -------------------------------------------------------------------------

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
    });

    _showPaymentSuccess();
  }

  // ---------------------------------------------------------------------------
  // PAYMENT SUCCESS
  // ---------------------------------------------------------------------------

  void _showPaymentSuccess() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 44,
                    color: AppColors.success,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Payment Successful',
                  style: AppTextStyles.title.copyWith(fontSize: 21),
                ),

                const SizedBox(height: 7),

                Text(
                  'Your payment of ${_formatIndianPrice(widget.totalAmount)} has been received.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),

                const SizedBox(height: 18),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.primary,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order payment',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'EcoLoop order • Payment completed',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderSuccess(
                            totalAmount: widget.totalAmount,
                            itemCount: widget.items?.length ?? 1,
                            paymentMethod: _selectedMethod == 'upi'
                                ? 'UPI'
                                : _selectedMethod == 'card'
                                ? 'Credit / Debit Card'
                                : _selectedMethod == 'netbanking'
                                ? 'Net Banking'
                                : _selectedMethod == 'wallet'
                                ? 'Wallet'
                                : 'Cash on Delivery',
                            address: widget.address,
                            deliveryMethod: widget.deliveryMethod,
                          ),
                        ),
                      );
                    },
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // MESSAGE
  // ---------------------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Payment', style: AppTextStyles.title),
        centerTitle: false,
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSecureBanner(),

                    const SizedBox(height: 18),

                    _buildOrderSummary(),

                    const SizedBox(height: 20),

                    Text(
                      'Choose payment method',
                      style: AppTextStyles.title.copyWith(fontSize: 17),
                    ),

                    const SizedBox(height: 10),

                    _buildPaymentMethods(),

                    const SizedBox(height: 20),

                    _buildPaymentDetails(),

                    const SizedBox(height: 20),

                    _buildSecurityCard(),
                  ],
                ),
              ),
            ),

            _buildBottomPaymentBar(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECURE BANNER
  // ---------------------------------------------------------------------------

  Widget _buildSecureBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.light, AppColors.surface]),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Secure payment',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your payment information is protected.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          const Icon(
            Icons.verified_rounded,
            color: AppColors.success,
            size: 21,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ORDER SUMMARY
  // ---------------------------------------------------------------------------

  Widget _buildOrderSummary() {
    final items = widget.items ?? [];

    if (items.isEmpty) {
      return _sectionCard(
        child: Row(
          children: [
            _sectionIcon(Icons.shopping_bag_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your EcoLoop order',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              _formatIndianPrice(widget.totalAmount),
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return _sectionCard(
      child: Column(
        children: [
          Row(
            children: [
              _sectionIcon(Icons.shopping_bag_outlined),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Order summary',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                '${items.length} item${items.length == 1 ? '' : 's'}',
                style: AppTextStyles.caption,
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...items.take(3).map((item) => _buildMiniProduct(item)),

          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '+ ${items.length - 3} more item${items.length - 3 == 1 ? '' : 's'}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          const Divider(height: 1),

          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                'Total payable',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                _formatIndianPrice(widget.totalAmount),
                style: AppTextStyles.title.copyWith(fontSize: 17),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProduct(Map<String, dynamic> item) {
    final image = _productImage(item);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(11),
            ),
            clipBehavior: Clip.antiAlias,
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.eco_outlined,
                        color: AppColors.primary,
                      );
                    },
                  )
                : const Icon(Icons.eco_outlined, color: AppColors.primary),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _productTitle(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Qty: ${_productQuantity(item)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          Text(
            _formatIndianPrice(
              _toDouble(item['price']) * _productQuantity(item),
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAYMENT METHODS
  // ---------------------------------------------------------------------------

  Widget _buildPaymentMethods() {
    return Column(
      children: [
        _paymentMethodTile(
          value: 'upi',
          icon: Icons.account_balance_wallet_outlined,
          title: 'UPI',
          subtitle: 'Google Pay, PhonePe, Paytm & more',
        ),

        const SizedBox(height: 9),

        _paymentMethodTile(
          value: 'card',
          icon: Icons.credit_card_outlined,
          title: 'Credit / Debit Card',
          subtitle: 'Visa, Mastercard, RuPay & more',
        ),

        const SizedBox(height: 9),

        _paymentMethodTile(
          value: 'netbanking',
          icon: Icons.account_balance_outlined,
          title: 'Net Banking',
          subtitle: 'Pay directly from your bank account',
        ),

        const SizedBox(height: 9),

        _paymentMethodTile(
          value: 'wallet',
          icon: Icons.account_balance_wallet_rounded,
          title: 'Wallets',
          subtitle: 'Use your preferred digital wallet',
        ),

        const SizedBox(height: 9),

        _paymentMethodTile(
          value: 'cod',
          icon: Icons.local_shipping_outlined,
          title: 'Cash on Delivery',
          subtitle: 'Pay when your order arrives',
        ),
      ],
    );
  }

  Widget _paymentMethodTile({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedMethod == value;

    return InkWell(
      onTap: () {
        _selectMethod(value);
      },
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(15),
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
              child: Icon(icon, color: AppColors.primary, size: 21),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),

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

  // ---------------------------------------------------------------------------
  // PAYMENT DETAILS
  // ---------------------------------------------------------------------------

  Widget _buildPaymentDetails() {
    switch (_selectedMethod) {
      case 'upi':
        return _buildUpiSection();

      case 'card':
        return _buildCardSection();

      case 'netbanking':
        return _buildNetBankingSection();

      case 'wallet':
        return _buildWalletSection();

      case 'cod':
        return _buildCodSection();

      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // UPI
  // ---------------------------------------------------------------------------

  Widget _buildUpiSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pay using UPI',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _upiApp(
                icon: Icons.g_mobiledata_rounded,
                title: 'Google Pay',
                value: 'gpay',
              ),
              const SizedBox(width: 10),
              _upiApp(
                icon: Icons.phone_android_rounded,
                title: 'PhonePe',
                value: 'phonepe',
              ),
              const SizedBox(width: 10),
              _upiApp(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Paytm',
                value: 'paytm',
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('OR', style: AppTextStyles.caption),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _upiController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'UPI ID',
              hintText: 'example@upi',
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              suffixIcon: const Icon(
                Icons.verified_outlined,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _upiApp({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final selected = _selectedUpiApp == value;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUpiApp = value;
            _upiController.clear();
          });
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.light : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(height: 5),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD
  // ---------------------------------------------------------------------------

  Widget _buildCardSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter card details',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 13),

          TextField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            maxLength: 19,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: Icon(Icons.credit_card_outlined),
              counterText: '',
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: _cardNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name on Card',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryController,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  decoration: const InputDecoration(
                    labelText: 'Expiry',
                    hintText: 'MM/YY',
                    counterText: '',
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: TextField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 3,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '•••',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                'Your card details are encrypted',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NET BANKING
  // ---------------------------------------------------------------------------

  Widget _buildNetBankingSection() {
    final banks = [
      'HDFC Bank',
      'State Bank of India',
      'ICICI Bank',
      'Axis Bank',
      'Kotak Mahindra Bank',
      'Other Bank',
    ];

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your bank',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: banks.map((bank) {
              final selected = _selectedBank == bank;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedBank = bank;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.light : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    bank,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WALLET
  // ---------------------------------------------------------------------------

  Widget _buildWalletSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose wallet',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          _walletOption('Paytm Wallet', Icons.account_balance_wallet_outlined),

          const SizedBox(height: 9),

          _walletOption('Amazon Pay', Icons.shopping_bag_outlined),

          const SizedBox(height: 9),

          _walletOption('Other Wallet', Icons.wallet_outlined),
        ],
      ),
    );
  }

  Widget _walletOption(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COD
  // ---------------------------------------------------------------------------

  Widget _buildCodSection() {
    return _sectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cash on Delivery',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Pay using cash when your EcoLoop order is delivered.',
                  style: AppTextStyles.caption.copyWith(height: 1.45),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Text(
                    'No online payment required',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECURITY CARD
  // ---------------------------------------------------------------------------

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Safe & secure checkout',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _securityPoint(
            Icons.lock_outline_rounded,
            'Secure payment processing',
          ),

          _securityPoint(
            Icons.privacy_tip_outlined,
            'Your payment details stay protected',
          ),

          _securityPoint(
            Icons.support_agent_outlined,
            'EcoLoop support available for orders',
          ),
        ],
      ),
    );
  }

  Widget _securityPoint(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.caption)),
        ],
      ),
    );
  }

  // BOTTOM PAYMENT BAR

  Widget _buildBottomPaymentBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _formatIndianPrice(widget.totalAmount),
                  style: AppTextStyles.title.copyWith(fontSize: 19),
                ),
              ],
            ),

            const SizedBox(width: 16),

            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _payNow,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedMethod == 'cod'
                                  ? 'Place Order'
                                  : 'Pay ${_formatPrice(widget.totalAmount)}',
                            ),
                            const SizedBox(width: 5),
                            const Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // COMMON SECTION CARD

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _sectionIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: AppColors.primary),
    );
  }

  // DOUBLE HELPER

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }

    return 0;
  }
}
