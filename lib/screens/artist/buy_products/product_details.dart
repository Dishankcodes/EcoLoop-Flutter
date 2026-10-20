import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../widgets/cart_popup_artist.dart';
import '../../artist/profile/artist_profile.dart';
import '../../artist/reviews/product_reviews.dart';
import '../../artist/reviews/write_review.dart';
import '../reviews/write_seller_review.dart';
import 'checkout.dart';
import 'seller_profile.dart';

/// Screen displaying full item details, image gallery, seller info, reviews, and purchasing options.
class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;

  /// When opened from checkout's Browse Marketplace flow, return the selected
  /// listing and quantity instead of opening a separate cart/checkout.
  final bool returnToCheckoutOnSelect;

  const ProductDetails({
    super.key,
    required this.product,
    this.returnToCheckoutOnSelect = false,
  });

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  late PageController _imageController;
  late Map<String, dynamic> _product;
  bool _detailsLoading = false;
  String? _detailsError;

  int _currentImage = 0;
  int _quantity = 1;
  bool _isWishlisted = false;
  bool _wishlistBusy = false;
  bool _reviewsLoading = false;
  bool _eligibilityLoading = false;
  bool _canReview = false;
  String? _eligibleOrderId;
  String? _eligibleSellerOrderId;
  bool _canReviewSeller = false;
  bool _sellerReviewSubmitted = false;
  List<Map<String, dynamic>> _liveReviews = [];
  List<Map<String, dynamic>> _relatedProducts = <Map<String, dynamic>>[];
  bool _relatedLoading = false;
  final EcoLoopApi _api = EcoLoopApi.instance;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
    _product = Map<String, dynamic>.from(widget.product);
    _isWishlisted =
        _product['isWishlisted'] == true || _product['wishlisted'] == true;
    _loadProductDetails();
    _syncWishlistState();
    _loadReviews();
    _checkReviewEligibility();
    _checkSellerReviewEligibility();
    _loadRelatedProducts();
  }

  /// Refreshes the selected listing from the backend so artist/user edits and
  /// availability changes are reflected in the details page.
  Future<void> _loadProductDetails() async {
    final id =
        (_product['productId'] ??
                _product['product_id'] ??
                _product['id'] ??
                '')
            .toString()
            .trim();
    if (id.isEmpty) return;
    if (mounted) {
      setState(() {
        _detailsLoading = true;
        _detailsError = null;
      });
    }
    try {
      final response = await _api.get('/products/$id');
      final root = _asMap(response);
      final nested = _asMap(root['data']);
      final fetched = nested.isNotEmpty ? nested : root;
      if (fetched.isNotEmpty && mounted) {
        setState(() {
          _product = <String, dynamic>{..._product, ...fetched};
          final rawImages = _product['imageUrls'] ?? _product['images'];
          if (rawImages is List && rawImages.isNotEmpty) {
            _product['images'] = rawImages
                .map((item) => item.toString())
                .where((item) => item.isNotEmpty)
                .toList();
            _product['image'] ??= _product['images'].first;
          }
        });
      }
    } catch (e) {
      // Keep the marketplace-provided product visible if refresh is unavailable.
      if (mounted) setState(() => _detailsError = e.toString());
    } finally {
      if (mounted) setState(() => _detailsLoading = false);
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  String get title => _product['title']?.toString() ?? 'Product';

  int get priceValue {
    final value = _product['price'];
    if (value is num) {
      return value.toInt();
    }
    return _extractNumericPrice(value?.toString() ?? '0');
  }

  String get price => '₹${_formatPrice(priceValue)}';

  String get condition =>
      (_product['condition'] ?? '').toString().trim().isEmpty
      ? 'Not specified'
      : _product['condition'].toString();

  String get category =>
      (_product['category'] ?? _product['categoryName'] ?? '')
          .toString()
          .trim()
          .isEmpty
      ? 'Uncategorized'
      : (_product['category'] ?? _product['categoryName']).toString();

  String get seller {
    final value = (_product['sellerName'] ?? _product['seller'] ?? '')
        .toString()
        .trim();
    return value.isEmpty ? 'Seller' : value;
  }

  double get sellerRating {
    final value = _product['sellerRating'] ?? _product['rating'];
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0.0;
  }

  int get sellerListings {
    final value = _product['sellerListings'] ?? _product['listings'];
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  String get _sellerLocation =>
      location.isEmpty ? 'Location not provided' : location;

  /// Builds a readable location from the real listing fields, including a
  /// structured address when the product payload contains one.
  String get location {
    dynamic addressValue =
        _product['address'] ??
        _product['sellerAddress'] ??
        _product['seller_address'] ??
        _product['location'];

    final address = _asMap(addressValue);
    final values = <dynamic>[
      if (address.isNotEmpty) ...[
        address['label'],
        address['addressLine1'],
        address['addressLine2'],
        address['street'],
        address['area'],
        address['city'],
        address['state'],
        address['pincode'] ?? address['postalCode'] ?? address['zipCode'],
      ] else if (addressValue is String && addressValue.trim().isNotEmpty)
        addressValue,
      _product['sellerCity'] ?? _product['city'],
      _product['sellerState'] ?? _product['state'],
      _product['pincode'] ?? _product['postalCode'] ?? _product['zipCode'],
    ];
    final seen = <String>{};
    return values
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString().trim())
        .where((value) => seen.add(value.toLowerCase()))
        .join(', ');
  }

  /// Seller account type used for profile navigation.
  ///
  /// Backend will provide this as `sellerType`:
  /// - `user`    -> SellerProfile
  /// - `artist`  -> ArtistProfile
  ///
  /// The legacy fallbacks are kept only so older/local product maps do not
  /// break while the backend integration is still being implemented.
  String get sellerType {
    final type =
        _product['sellerType'] ??
        _product['sellerRole'] ??
        _product['seller_role'] ??
        _product['role'] ??
        'user';

    return type.toString().trim().toLowerCase();
  }

  bool get isArtistSeller =>
      sellerType == 'artist' ||
      sellerType == 'remaker' ||
      sellerType == 're_maker' ||
      sellerType == 're-maker';

  String get description =>
      (_product['description'] ?? '').toString().trim().isEmpty
      ? 'No description provided by the seller.'
      : _product['description'].toString();

  int get availableQuantity {
    final value = _product['availableQuantity'];
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get rating {
    if (_liveReviews.isNotEmpty) {
      final values = _liveReviews
          .map((r) => _intValue(r['rating']))
          .where((v) => v >= 1 && v <= 5)
          .toList();
      if (values.isNotEmpty) {
        return values.reduce((a, b) => a + b) / values.length;
      }
    }
    final value = _product['rating'];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int get reviewCount {
    if (_liveReviews.isNotEmpty) return _liveReviews.length;
    final value = _product['reviewCount'] ?? _product['reviews'] ?? 0;
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  List<String> get images {
    final productImages = _product['images'] ?? _product['imageUrls'];
    if (productImages is List && productImages.isNotEmpty) {
      return productImages
          .map((image) => image.toString())
          .where((image) => image.isNotEmpty)
          .toList();
    }

    final singleImage = _product['image']?.toString();
    if (singleImage != null && singleImage.isNotEmpty) {
      return [singleImage];
    }

    return const <String>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 115),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_detailsLoading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: ArtistColors.primary,
                  ),
                if (_detailsError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Showing saved listing data because the latest refresh failed.',
                      style: ArtistTextStyles.caption.copyWith(
                        color: ArtistColors.textSecondary,
                      ),
                    ),
                  ),
                _buildImageGallery(),
                _buildProductHeader(),
                _buildSellerSection(),
                _buildLocationSection(),
                _buildDescriptionSection(),
                _buildItemInformation(),
                _buildReviewsSection(),
                _buildEcoLoopInfo(),
                _buildSimilarProducts(),
                _buildReportSection(),
                const SizedBox(height: 15),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// AppBar with product screen title, share action, and overflow options.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ArtistColors.surface,
      foregroundColor: ArtistColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text(
        'Product Details',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: ArtistColors.textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Share',
          onPressed: _shareProduct,
          icon: const Icon(Icons.share_outlined),
        ),
        IconButton(
          tooltip: 'More',
          onPressed: _showMoreOptions,
          icon: const Icon(Icons.more_vert_rounded),
        ),
      ],
    );
  }

  /// Interactive product image slider with pagination indicator and wishlist toggle.
  Widget _buildImageGallery() {
    return Container(
      color: ArtistColors.surface,
      child: Column(
        children: [
          SizedBox(
            height: 330,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _imageController,
                  itemCount: images.isEmpty ? 1 : images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    if (images.isEmpty) {
                      return Container(
                        color: ArtistColors.light,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 60,
                            color: ArtistColors.primary,
                          ),
                        ),
                      );
                    }
                    return Image.network(
                      images[index],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: ArtistColors.light,
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 60,
                              color: ArtistColors.primary,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: ArtistColors.light,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ArtistColors.primary,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    color: Colors.white.withOpacity(0.95),
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _toggleWishlist,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          _isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isWishlisted
                              ? ArtistColors.error
                              : ArtistColors.textPrimary,
                          size: 23,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      images.isEmpty
                          ? 'No image'
                          : '${_currentImage + 1}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (images.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final selected = index == _currentImage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: selected ? 20 : 6,
                    decoration: BoxDecoration(
                      color: selected
                          ? ArtistColors.primary
                          : ArtistColors.border,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  /// Top section containing title, price, tags, and stock banner.
  Widget _buildProductHeader() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTag(condition, Icons.verified_outlined),
              const SizedBox(width: 7),
              _buildTag(category, Icons.category_outlined),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ArtistColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: ArtistColors.primary,
                ),
              ),
              const SizedBox(width: 9),
              if (_product['negotiable'] == true)
                const Text(
                  'Negotiable',
                  style: TextStyle(
                    fontSize: 11,
                    color: ArtistColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 17,
                color: Color(0xFFFFB300),
              ),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text('($reviewCount reviews)', style: ArtistTextStyles.caption),
              const SizedBox(width: 16),
              const Icon(
                Icons.visibility_outlined,
                size: 16,
                color: ArtistColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${_product['views'] ?? 0} views',
                style: ArtistTextStyles.caption,
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.favorite_border_rounded,
                size: 16,
                color: ArtistColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${_product['wishlistCount'] ?? 0} saved',
                style: ArtistTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 13),
          _buildAvailabilityBanner(),
        ],
      ),
    );
  }

  /// Banner indicating remaining stock availability.
  Widget _buildAvailabilityBanner() {
    final available = availableQuantity;
    final Color color = available <= 2
        ? ArtistColors.error
        : ArtistColors.success;
    final String message = available <= 2
        ? 'Only $available left'
        : '$available items available';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(
            available <= 2
                ? Icons.warning_amber_rounded
                : Icons.inventory_2_outlined,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 7),
          Text(
            message,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Tag chip helper for rendering category and condition labels.
  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ArtistColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: ArtistColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Seller summary card with rating, listings count, and profile navigation link.
  Widget _buildSellerSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Seller',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openSellerProfile,
                style: TextButton.styleFrom(
                  foregroundColor: ArtistColors.primary,
                ),
                child: const Text(
                  'View Profile',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          InkWell(
            onTap: _openSellerProfile,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ArtistColors.background,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: ArtistColors.border.withOpacity(0.45),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: ArtistColors.light,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: ArtistColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                seller,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ArtistColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (sellerRating > 0) ...[
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFFFB300),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                sellerRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ArtistColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 7),
                            ],
                            Text(
                              '$sellerListings listings',
                              style: ArtistTextStyles.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isArtistSeller ? 'EcoLoop ReMaker' : 'EcoLoop seller',
                          style: ArtistTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: ArtistColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: ArtistColors.light.withOpacity(0.55),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: ArtistColors.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Keep conversations and payments inside EcoLoop for a safer transaction.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: ArtistColors.textSecondary,
                      height: 1.4,
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

  /// Item location detail row widget.
  Widget _buildLocationSection() {
    return _section(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _showLocationDetails,
        child: Row(
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: ArtistColors.light,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: ArtistColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item Location',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ArtistColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(location, style: ArtistTextStyles.caption),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: ArtistColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  /// Opens a compact location card with the available listing address fields.
  void _showLocationDetails() {
    final addressValue =
        _product['address'] ??
        _product['sellerAddress'] ??
        _product['seller_address'] ??
        _product['location'];
    final address = _asMap(addressValue);

    final details = <String, String>{};
    void addDetail(String label, dynamic value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        details[label] = text;
      }
    }

    if (address.isNotEmpty) {
      addDetail(
        'Address',
        address['label'] ?? address['addressLine1'] ?? address['street'],
      );
      addDetail('Area', address['addressLine2'] ?? address['area']);
      addDetail(
        'City',
        address['city'] ?? _product['sellerCity'] ?? _product['city'],
      );
      addDetail(
        'State',
        address['state'] ?? _product['sellerState'] ?? _product['state'],
      );
      addDetail(
        'PIN code',
        address['pincode'] ?? address['postalCode'] ?? address['zipCode'],
      );
    } else {
      addDetail('Address', addressValue is String ? addressValue : null);
      addDetail('City', _product['sellerCity'] ?? _product['city']);
      addDetail('State', _product['sellerState'] ?? _product['state']);
      addDetail(
        'PIN code',
        _product['pincode'] ?? _product['postalCode'] ?? _product['zipCode'],
      );
    }
    if (details.isEmpty && _sellerLocation != 'Location not provided') {
      details['Location'] = _sellerLocation;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ArtistColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ArtistColors.light,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: ArtistColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Item Location',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: details.isEmpty
            ? const Text(
                'Location details are not available for this listing.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: ArtistColors.textSecondary,
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 11,
                                color: ArtistColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ArtistColors.textPrimary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(
                color: ArtistColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full text description and sustainability impact card.
  Widget _buildDescriptionSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About this item',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ArtistColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: ArtistColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: ArtistColors.light.withOpacity(0.65),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              children: [
                Icon(Icons.eco_outlined, size: 18, color: ArtistColors.success),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Buying pre-owned helps extend the life of useful products.',
                    style: TextStyle(
                      fontSize: 11,
                      color: ArtistColors.success,
                      fontWeight: FontWeight.w500,
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

  /// Key specifications list including category, condition, and listing date.
  Widget _buildItemInformation() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ArtistColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.category_outlined, 'Category', category),
          _infoRow(Icons.check_circle_outline, 'Condition', condition),
          _infoRow(
            Icons.inventory_2_outlined,
            'Availability',
            '$availableQuantity item${availableQuantity == 1 ? '' : 's'} available',
          ),
          _infoRow(
            Icons.calendar_today_outlined,
            'Listed',
            _displayReviewDate(_product['createdAt']),
          ),
          _infoRow(
            Icons.local_shipping_outlined,
            'Delivery',
            'EcoLoop Delivery',
          ),
        ],
      ),
    );
  }

  /// One-column specification row: label first, value directly underneath.
  /// This prevents long values from being squeezed into the middle/right edge.
  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: ArtistColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: ArtistColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.trim().isEmpty ? 'Not provided' : value,
                  textAlign: TextAlign.left,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: ArtistColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reviews are loaded from the backend; no sample reviews are displayed.
  Widget _buildReviewsSection() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ArtistColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openAllReviews,
                style: TextButton.styleFrom(
                  foregroundColor: ArtistColors.primary,
                ),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRatingSummary(),
          const SizedBox(height: 12),
          if (_reviewsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ArtistColors.primary,
                ),
              ),
            )
          else if (_liveReviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'No reviews for this product yet.',
                  style: ArtistTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._liveReviews
                .take(3)
                .map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildReviewCard(
                      name:
                          (review['reviewerName'] ??
                                  review['name'] ??
                                  review['userName'] ??
                                  'EcoLoop buyer')
                              .toString(),
                      rating: _intValue(review['rating']).clamp(1, 5),
                      date: _displayReviewDate(
                        review['createdAt'] ?? review['date'],
                      ),
                      review:
                          (review['comment'] ??
                                  review['review'] ??
                                  review['text'] ??
                                  '')
                              .toString(),
                      imageCount: 0,
                    ),
                  ),
                ),
          const SizedBox(height: 8),
          if (_eligibilityLoading)
            const LinearProgressIndicator(minHeight: 2)
          else if (_canReview)
            SizedBox(
              width: double.infinity,
              height: 43,
              child: OutlinedButton.icon(
                onPressed: _writeReview,
                icon: const Icon(Icons.rate_review_outlined, size: 17),
                label: const Text(
                  'Write a Review',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            )
          else
            Text(
              'Only buyers whose order for this product is marked Delivered can review it.',
              style: ArtistTextStyles.caption.copyWith(
                color: ArtistColors.textSecondary,
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: OutlinedButton.icon(
              onPressed:
                  _eligibilityLoading ||
                      !_canReviewSeller ||
                      _eligibleSellerOrderId == null
                  ? null
                  : _writeSellerReview,
              icon: const Icon(Icons.storefront_outlined, size: 17),
              label: Text(
                _sellerReviewSubmitted
                    ? 'Seller/Artist Reviewed'
                    : 'Write Seller/Artist Review',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkSellerReviewEligibility() async {
    final sellerId = _intValue(_product['sellerId'] ?? _product['artistId']);
    if (sellerId <= 0) return;
    try {
      final response = await _api.get('/orders');
      final root = _asMap(response);
      final nested = _asMap(root['data']);
      final dynamic rows = response is List
          ? response
          : (root['orders'] ??
                root['items'] ??
                nested['orders'] ??
                nested['items'] ??
                const []);
      String? orderId;
      if (rows is List)
        for (final raw in rows) {
          if (raw is! Map) continue;
          final order = Map<String, dynamic>.from(raw);
          final sameSeller =
              _intValue(order['sellerId'] ?? order['artistId']) == sellerId;
          final status = (order['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase()
              .replaceAll('_', ' ');
          final payment = (order['paymentStatus'] ?? order['payment'] ?? '')
              .toString()
              .trim()
              .toLowerCase()
              .replaceAll('_', ' ');
          final paid = const [
            'paid',
            'completed',
            'success',
            'successful',
            'captured',
            'cod paid',
          ].contains(payment);
          if (sameSeller && status == 'delivered' && paid) {
            orderId = (order['orderId'] ?? order['id'] ?? '').toString();
            if (orderId.isNotEmpty) break;
          }
        }
      final existing = await _api.get('/my/reviews');
      dynamic reviewRows = existing;
      if (existing is Map)
        reviewRows =
            existing['reviews'] ??
            existing['data'] ??
            existing['items'] ??
            const [];
      var reviewed = false;
      if (reviewRows is List)
        for (final raw in reviewRows) {
          if (raw is! Map) continue;
          final r = Map<String, dynamic>.from(raw);
          final type = (r['reviewType'] ?? r['type'] ?? '')
              .toString()
              .toLowerCase();
          final reviewedSeller = _intValue(r['sellerId'] ?? r['artistId']);
          if (reviewedSeller == sellerId &&
              _intValue(r['productId']) == 0 &&
              (type == 'seller' || type == 'artist' || type.isEmpty))
            reviewed = true;
        }
      if (mounted)
        setState(() {
          _eligibleSellerOrderId = orderId;
          _canReviewSeller = orderId != null && orderId.isNotEmpty && !reviewed;
          _sellerReviewSubmitted = reviewed;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _canReviewSeller = false;
          _eligibleSellerOrderId = null;
        });
    }
  }

  Future<void> _writeSellerReview() async {
    final sellerId = (_product['sellerId'] ?? _product['artistId'] ?? '')
        .toString();
    if (!_canReviewSeller || _eligibleSellerOrderId == null || sellerId.isEmpty)
      return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteSellerReview(
          sellerName: seller,
          sellerImage:
              (_product['sellerProfilePhotoUrl'] ??
                      _product['sellerImage'] ??
                      _product['profilePhotoUrl'])
                  ?.toString(),
          sellerId: sellerId,
          sellerType: sellerType,
          orderId: _eligibleSellerOrderId!,
        ),
      ),
    );
    if (result != null && mounted) _checkSellerReviewEligibility();
  }

  Future<void> _loadReviews() async {
    final id = _currentProductId;
    if (id.isEmpty) return;
    if (mounted) setState(() => _reviewsLoading = true);
    try {
      final response = await _api.get('/products/$id/reviews');
      final root = _asMap(response);
      final nested = _asMap(root['data']);
      final dynamic rows = response is List
          ? response
          : (root['reviews'] ??
                root['items'] ??
                nested['reviews'] ??
                nested['items'] ??
                const []);
      final parsed = rows is List
          ? rows
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() => _liveReviews = parsed);
    } catch (_) {
      if (mounted) setState(() => _liveReviews = []);
    } finally {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _checkReviewEligibility() async {
    final productId = _currentProductId;
    if (productId.isEmpty) return;
    if (mounted) setState(() => _eligibilityLoading = true);
    try {
      final response = await _api.get(
        '/products/$productId/review-eligibility',
      );
      final root = _asMap(response);
      final data = _asMap(root['data']);
      final result = data.isNotEmpty ? data : root;
      final eligible =
          result['eligible'] == true ||
          result['canReview'] == true ||
          result['can_review'] == true;
      final orderId = (result['orderId'] ?? result['order_id'] ?? '')
          .toString()
          .trim();
      if (!mounted) return;
      setState(() {
        _canReview = eligible && orderId.isNotEmpty;
        _eligibleOrderId = orderId.isEmpty ? null : orderId;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          _canReview = false;
          _eligibleOrderId = null;
        });
    } finally {
      if (mounted) setState(() => _eligibilityLoading = false);
    }
  }

  int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _displayReviewDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty)
      return 'Date unavailable';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  /// Summary bar showing average score and distribution chart for star ratings.
  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArtistColors.border.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: ArtistColors.textPrimary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 15,
                    color: const Color(0xFFFFB300),
                  );
                }),
              ),
              const SizedBox(height: 3),
              Text('$reviewCount reviews', style: ArtistTextStyles.caption),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Ratings appear after verified reviews.',
                  style: TextStyle(
                    fontSize: 10,
                    color: ArtistColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Review item card showing reviewer details, score, text, and user media.
  Widget _buildReviewCard({
    required String name,
    required int rating,
    required String date,
    required String review,
    required int imageCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArtistColors.border.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: ArtistColors.light,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 19,
                  color: ArtistColors.primary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ArtistColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            index < rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 12,
                            color: const Color(0xFFFFB300),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(date, style: ArtistTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: ArtistColors.success,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            review,
            style: const TextStyle(
              fontSize: 11,
              height: 1.45,
              color: ArtistColors.textSecondary,
            ),
          ),
          if (imageCount > 0) ...[
            const SizedBox(height: 9),
            Row(
              children: List.generate(imageCount, (index) {
                return Container(
                  width: 55,
                  height: 55,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(
                    color: ArtistColors.light,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: ArtistColors.primary,
                    size: 21,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  /// Informational section highlighting platform advantages and guarantees.
  Widget _buildEcoLoopInfo() {
    return _section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Why buy through EcoLoop?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ArtistColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _benefitRow(
            Icons.verified_user_outlined,
            'Safer transactions',
            'Keep your purchase protected through EcoLoop.',
          ),
          _benefitRow(
            Icons.local_shipping_outlined,
            'Reliable delivery',
            'Delivery options are handled through EcoLoop.',
          ),
          _benefitRow(
            Icons.eco_outlined,
            'Give items another life',
            'Every reused item helps reduce unnecessary waste.',
          ),
          _benefitRow(
            Icons.support_agent_outlined,
            'EcoLoop support',
            'Get assistance if something goes wrong.',
          ),
        ],
      ),
    );
  }

  /// Benefit row item for platform highlights.
  Widget _benefitRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: ArtistColors.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ArtistColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: ArtistColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal scrolling carousel of related product recommendations.
  Widget _buildSimilarProducts() {
    // Similar items should be loaded from GET /products by the marketplace
    // screen. Do not display hard-coded sample listings here.
    final products = _similarProducts;
    if (products.isEmpty && !_relatedLoading) return const SizedBox.shrink();

    return Container(
      color: ArtistColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Similar Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ArtistColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadRelatedProducts,
                  style: TextButton.styleFrom(
                    foregroundColor: ArtistColors.primary,
                  ),
                  child: const Text(
                    'See All',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_relatedLoading)
            const Padding(
              padding: EdgeInsets.only(right: 20, bottom: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (products.isNotEmpty)
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(right: 20),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 11),
                itemBuilder: (context, index) {
                  return _buildSimilarProductCard(products[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Card item rendered inside the similar products carousel.
  Widget _buildSimilarProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
        );
      },
      child: SizedBox(
        width: 135,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: 135,
                    height: 125,
                    color: ArtistColors.light,
                    child: Image.network(
                      (product['image'] ??
                              product['imageUrl'] ??
                              product['imageURL'] ??
                              ((product['imageUrls'] is List &&
                                      (product['imageUrls'] as List).isNotEmpty)
                                  ? (product['imageUrls'] as List).first
                                  : ''))
                          .toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.image_outlined,
                          color: ArtistColors.primary,
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.94),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 16,
                      color: ArtistColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              (product['title'] ?? 'Product').toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ArtistColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '₹${_formatPrice(_extractNumericPrice((product['price'] ?? 0).toString()))}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: ArtistColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Similar products are fetched from GET /products; no demo products are injected.
  List<Map<String, dynamic>> get _similarProducts => _relatedProducts;

  Future<void> _loadRelatedProducts() async {
    final currentId = _currentProductId;
    if (currentId.isEmpty) return;
    if (mounted) setState(() => _relatedLoading = true);
    try {
      final categoryId =
          (_product['categoryId'] ?? _product['category_id'] ?? '')
              .toString()
              .trim();
      final response = await _api.get(
        '/products',
        query: <String, dynamic>{
          if (categoryId.isNotEmpty) 'categoryId': categoryId,
          'limit': 12,
        },
      );
      final root = _asMap(response);
      final nested = _asMap(root['data']);
      final dynamic rows = response is List
          ? response
          : (root['products'] ??
                root['items'] ??
                nested['products'] ??
                nested['items'] ??
                const []);
      final parsed = rows is List
          ? rows
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .where((row) {
                  final id =
                      (row['productId'] ?? row['product_id'] ?? row['id'] ?? '')
                          .toString();
                  final status = (row['status'] ?? 'published')
                      .toString()
                      .toLowerCase();
                  return id.isNotEmpty &&
                      id != currentId &&
                      status != 'archived' &&
                      status != 'deleted' &&
                      status != 'sold' &&
                      status != 'out_of_stock';
                })
                .take(8)
                .toList()
          : <Map<String, dynamic>>[];
      for (final item in parsed) {
        final rawImages = item['imageUrls'] ?? item['images'];
        if (rawImages is List && rawImages.isNotEmpty) {
          item['image'] ??= rawImages.first.toString();
        }
      }
      if (mounted) setState(() => _relatedProducts = parsed);
    } catch (_) {
      if (mounted) setState(() => _relatedProducts = <Map<String, dynamic>>[]);
    } finally {
      if (mounted) setState(() => _relatedLoading = false);
    }
  }

  /// Persistent bottom purchase bar for quantity selection, cart addition, and instant checkout.
  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 11, 15, 15),
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: ArtistColors.border.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _quantity > 1
                          ? () {
                              setState(() {
                                _quantity--;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.remove_rounded, size: 18),
                      color: ArtistColors.primary,
                    ),
                    SizedBox(
                      width: 20,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ArtistColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _increaseQuantity,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      color: ArtistColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _addToCart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ArtistColors.primary,
                      side: const BorderSide(color: ArtistColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _buyNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtistColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Buy Now',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '₹${_formatPrice(priceValue * _quantity)}',
                          style: const TextStyle(fontSize: 10, height: 1.1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Increments quantity selection up to maximum available stock.
  void _increaseQuantity() {
    if (_quantity < availableQuantity) {
      setState(() {
        _quantity++;
      });
    } else {
      _showMessage(
        'Only $availableQuantity item${availableQuantity == 1 ? '' : 's'} available.',
      );
    }
  }

  void _returnSelectedProductToCheckout() {
    final selected = Map<String, dynamic>.from(_product);
    selected['id'] =
        _product['productId'] ?? _product['product_id'] ?? _product['id'] ?? '';
    selected['productId'] =
        _product['productId'] ?? _product['product_id'] ?? _product['id'] ?? '';
    selected['title'] = title;
    selected['price'] = priceValue;
    selected['quantity'] = _quantity;
    selected['condition'] = condition;
    selected['category'] = category;
    selected['seller'] = seller;
    selected['sellerName'] = seller;
    selected['sellerCity'] = selected['sellerCity'] ?? selected['city'] ?? '';
    selected['availableQuantity'] = availableQuantity;
    selected['image'] =
        selected['image'] ?? (images.isNotEmpty ? images.first : '');
    selected['images'] = selected['images'] ?? images;
    Navigator.pop(context, <String, dynamic>{
      'product': selected,
      'quantity': _quantity,
    });
  }

  /// Formats product data and presents the cart popup drawer.
  void _addToCart() {
    if (widget.returnToCheckoutOnSelect) {
      if (availableQuantity <= 0) {
        _showMessage('This product is currently unavailable.');
        return;
      }
      _returnSelectedProductToCheckout();
      return;
    }
    if (_currentProductId.isEmpty) {
      _showMessage('This product has no valid ID and cannot be added to cart.');
      return;
    }
    if (availableQuantity <= 0) {
      _showMessage('This product is currently unavailable.');
      return;
    }

    final cartProduct = Map<String, dynamic>.from(_product);

    cartProduct['id'] =
        _product['productId'] ?? _product['product_id'] ?? _product['id'] ?? '';

    cartProduct['productId'] =
        _product['productId'] ?? _product['product_id'] ?? _product['id'] ?? '';

    cartProduct['title'] = title;
    cartProduct['price'] = priceValue;
    cartProduct['quantity'] = _quantity;
    cartProduct['condition'] = condition;
    cartProduct['category'] = category;
    cartProduct['seller'] = seller;
    cartProduct['location'] = location;
    cartProduct['availableQuantity'] = availableQuantity;

    if (!cartProduct.containsKey('image') && images.isNotEmpty) {
      cartProduct['image'] = images.first;
    }

    if (!cartProduct.containsKey('images')) {
      cartProduct['images'] = images;
    }
    CartPopup.addItem(context, item: cartProduct);
  }

  /// Directs user immediately to the checkout flow with selected quantity.
  void _buyNow() {
    if (availableQuantity <= 0) {
      _showMessage('This product is currently unavailable.');
      return;
    }
    if (widget.returnToCheckoutOnSelect) {
      _returnSelectedProductToCheckout();
      return;
    }
    if (_currentProductId.isEmpty) {
      _showMessage('This product has no valid ID and cannot be purchased.');
      return;
    }
    if (availableQuantity <= 0) {
      _showMessage('This product is currently unavailable.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Checkout(product: _product, quantity: _quantity),
      ),
    );
  }

  String get _currentProductId =>
      (_product['productId'] ?? _product['product_id'] ?? _product['id'] ?? '')
          .toString()
          .trim();

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  Future<void> _syncWishlistState() async {
    final id = _currentProductId;
    if (id.isEmpty) return;
    try {
      final response = await _api.get('/wishlist');
      final root = _asMap(response);
      final data = _asMap(root['data']);
      final rows = response is List
          ? response
          : (root['items'] ??
                root['products'] ??
                root['wishlist'] ??
                data['items'] ??
                data['products'] ??
                data['wishlist'] ??
                const []);
      if (rows is! List) return;
      final saved = rows.any((row) {
        final item = _asMap(row);
        final nested = _asMap(item['product']);
        final productId =
            (item['productId'] ??
                    item['product_id'] ??
                    item['id'] ??
                    nested['productId'] ??
                    nested['product_id'] ??
                    nested['id'] ??
                    '')
                .toString();
        return productId == id;
      });
      if (mounted) setState(() => _isWishlisted = saved);
    } catch (_) {
      // Keep the state passed from the marketplace if wishlist is temporarily unavailable.
    }
  }

  /// Saves/removes the product through the backend and rolls back on failure.
  Future<void> _toggleWishlist() async {
    final id = _currentProductId;
    if (id.isEmpty) {
      _showMessage('This item has no product ID and cannot be saved.');
      return;
    }
    if (_wishlistBusy) return;
    final wasSaved = _isWishlisted;
    setState(() {
      _wishlistBusy = true;
      _isWishlisted = !wasSaved;
    });
    try {
      if (wasSaved) {
        await _api.delete('/wishlist/$id');
      } else {
        await _api.post('/wishlist', <String, dynamic>{'productId': id});
      }
      if (mounted)
        _showMessage(
          wasSaved ? 'Removed from your wishlist.' : 'Added to your wishlist.',
        );
    } catch (e) {
      if (mounted) {
        setState(() => _isWishlisted = wasSaved);
        _showMessage('Wishlist update failed. Please sign in and try again.');
      }
    } finally {
      if (mounted) setState(() => _wishlistBusy = false);
    }
  }

  /// Opens full profile page for the seller.
  void _openSellerProfile() {
    if (isArtistSeller) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtistProfile(
            artist: {
              'artistId': _product['sellerId'] ?? _product['artistId'],
              'sellerType': 'artist',
              'profileImage':
                  _product['sellerImage'] ?? _product['artistImage'] ?? '',
              'name': seller,
              'location': location,
              'rating': _product['sellerRating'] ?? _product['rating'] ?? 0,
              'reviews':
                  _product['sellerReviewCount'] ?? _product['reviewCount'] ?? 0,
              'followers': _product['followerCount'] ?? 0,
              'products': _product['sellerProductCount'] ?? 0,
            },
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerProfile(
          seller: {
            'userId': _product['sellerId'] ?? _product['userId'],
            'sellerType': 'user',
            'profileImage': _product['sellerImage'] ?? '',
            'name': seller,
            'location': location,
            'rating': _product['sellerRating'] ?? _product['rating'] ?? 0,
            'reviews':
                _product['sellerReviewCount'] ?? _product['reviewCount'] ?? 0,
            'listings': _product['sellerProductCount'] ?? 0,
            'sold': _product['salesCount'] ?? 0,
            'positive': _product['positiveRating'] ?? 0,
          },
        ),
      ),
    );
  }

  /// Opens the complete list of reviews for this product.
  void _openAllReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductReviews(product: _product)),
    );
  }

  /// Opens form interface for submitting a new review.
  Future<void> _writeReview() async {
    if (!_canReview || _eligibleOrderId == null) {
      _showMessage('A delivered purchase is required before you can review.');
      return;
    }
    final productForReview = <String, dynamic>{
      ..._product,
      'reviewOrderId': _eligibleOrderId,
    };
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => WriteReview(product: productForReview)),
    );
    if (submitted == true && mounted) {
      await _loadReviews();
      await _checkReviewEligibility();
    }
  }

  /// Sharing is kept separate from backend mutations; this screen does not invent a public product URL.
  /// Shares the real product details and, when available, its first valid
  /// product image through the device's native share sheet.
  ///
  /// The app does not currently define a public deep link for product pages,
  /// so this deliberately shares product details and the product ID rather
  /// than inventing a URL.
  Future<void> _shareProduct() async {
    if (!mounted) return;

    final String productName = title;
    final String productPrice = price;
    final String productCondition = condition;
    final String productCategory = category;
    final String productDescription = description;
    final String productId = _currentProductId.trim();

    final String shareText =
        '''
♻️ Check out this product on EcoLoop!

$productName

💰 Price: $productPrice
📦 Condition: $productCondition
🏷️ Category: $productCategory

$productDescription

${productId.isNotEmpty ? 'Product ID: $productId' : ''}

Discover sustainable products with EcoLoop!
'''
            .trim();

    try {
      final String? imageUrl = images.cast<String?>().firstWhere((String? url) {
        if (url == null || url.trim().isEmpty) return false;
        final Uri? uri = Uri.tryParse(url.trim());
        return uri != null &&
            (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty;
      }, orElse: () => null);

      XFile? imageFile;
      if (imageUrl != null) {
        try {
          final http.Response response = await http
              .get(Uri.parse(imageUrl.trim()))
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            final Uri uri = Uri.parse(imageUrl.trim());
            final String path = uri.path.toLowerCase();
            final String extension = path.endsWith('.png')
                ? 'png'
                : path.endsWith('.webp')
                ? 'webp'
                : path.endsWith('.gif')
                ? 'gif'
                : 'jpg';
            final String mimeType = extension == 'png'
                ? 'image/png'
                : extension == 'webp'
                ? 'image/webp'
                : extension == 'gif'
                ? 'image/gif'
                : 'image/jpeg';

            imageFile = XFile.fromData(
              response.bodyBytes,
              mimeType: mimeType,
              name: 'ecoloop_product.$extension',
            );
          }
        } catch (_) {
          // Sharing the text still works if the image cannot be downloaded.
        }
      }

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Check out $productName on EcoLoop',
          title: 'Share EcoLoop Product',
          files: imageFile == null ? null : <XFile>[imageFile],
          fileNameOverrides: imageFile == null
              ? null
              : <String>['ecoloop_product.${_sharedImageExtension()}'],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to share this product. Please try again.');
    }
  }

  /// Chooses a safe filename extension for the shared product image.
  String _sharedImageExtension() {
    if (images.isEmpty) return 'jpg';

    final Uri? uri = Uri.tryParse(images.first);
    final String path = uri?.path.toLowerCase() ?? '';

    if (path.endsWith('.png')) return 'png';
    if (path.endsWith('.webp')) return 'webp';
    if (path.endsWith('.gif')) return 'gif';
    return 'jpg';
  }

  /// Displays bottom sheet with secondary actions.
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 25),
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
                const SizedBox(height: 15),
                ListTile(
                  leading: const Icon(
                    Icons.favorite_border_rounded,
                    color: ArtistColors.primary,
                  ),
                  title: const Text('Add to Wishlist'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (!_isWishlisted) {
                      _toggleWishlist();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.share_outlined,
                    color: ArtistColors.primary,
                  ),
                  title: const Text('Share Product'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _shareProduct();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.rate_review_outlined,
                    color: ArtistColors.primary,
                  ),
                  title: const Text('View Reviews'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openAllReviews();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.flag_outlined,
                    color: ArtistColors.error,
                  ),
                  title: const Text(
                    'Report Listing',
                    style: TextStyle(color: ArtistColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _reportProduct();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Footer trigger button for reporting an issue with the product listing.
  Widget _buildReportSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: InkWell(
        onTap: _reportProduct,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flag_outlined,
                size: 17,
                color: ArtistColors.textSecondary,
              ),
              SizedBox(width: 7),
              Text(
                'Report this listing',
                style: TextStyle(
                  fontSize: 12,
                  color: ArtistColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a report form and submits the report to the existing Apps Script API.
  /// Code.gs handles POST /reports/product and stores the report in the Reports sheet.
  void _reportProduct() {
    final productId = int.tryParse(_currentProductId.trim());
    if (productId == null || productId <= 0) {
      _showMessage(
        'This listing has an invalid product ID and cannot be reported.',
      );
      return;
    }

    const reasons = <Map<String, dynamic>>[
      {'label': 'Misleading information', 'icon': Icons.info_outline_rounded},
      {'label': 'Inappropriate content', 'icon': Icons.block_outlined},
      {
        'label': 'Suspicious or scam listing',
        'icon': Icons.warning_amber_outlined,
      },
      {
        'label': 'Counterfeit or prohibited item',
        'icon': Icons.gpp_bad_outlined,
      },
      {'label': 'Other', 'icon': Icons.more_horiz_rounded},
    ];

    final detailsController = TextEditingController();
    String selectedReason = reasons.first['label'] as String;
    bool submitting = false;
    String? formError;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submitReport() async {
              if (submitting) return;
              if (selectedReason == 'Other' &&
                  detailsController.text.trim().isEmpty) {
                setSheetState(() {
                  formError = 'Please describe the issue for an Other report.';
                });
                return;
              }

              setSheetState(() {
                submitting = true;
                formError = null;
              });

              try {
                final response = await _api
                    .post('/reports/product', <String, dynamic>{
                      'productId': productId,
                      'reason': selectedReason,
                      'details': detailsController.text.trim(),
                    });

                if (!mounted) return;
                Navigator.of(sheetContext).pop();
                final result = _asMap(response);
                final message = result['message']?.toString().trim();
                _showMessage(
                  message != null && message.isNotEmpty
                      ? message
                      : 'Report submitted for review.',
                );
              } catch (error) {
                setSheetState(() {
                  submitting = false;
                  formError = error.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  20 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 4,
                          width: 42,
                          decoration: BoxDecoration(
                            color: ArtistColors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Report Listing',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: ArtistColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tell us why this listing should be reviewed. Your report will be sent to EcoLoop for moderation.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: ArtistColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...reasons.map((reason) {
                        final label = reason['label'] as String;
                        final icon = reason['icon'] as IconData;
                        final selected = selectedReason == label;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: Icon(
                            icon,
                            color: selected
                                ? ArtistColors.primary
                                : ArtistColors.textSecondary,
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: ArtistColors.textPrimary,
                            ),
                          ),
                          trailing: Icon(
                            selected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected
                                ? ArtistColors.primary
                                : ArtistColors.textSecondary,
                          ),
                          onTap: submitting
                              ? null
                              : () {
                                  setSheetState(() {
                                    selectedReason = label;
                                    formError = null;
                                  });
                                },
                        );
                      }),
                      const SizedBox(height: 8),
                      TextField(
                        controller: detailsController,
                        enabled: !submitting,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: selectedReason == 'Other'
                              ? 'Describe the issue (required)'
                              : 'Additional details (optional)',
                          hintText:
                              'Add details to help us review this listing',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: ArtistColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: ArtistColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: ArtistColors.border),
                          ),
                        ),
                      ),
                      if (formError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          formError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: ArtistColors.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: submitting ? null : submitReport,
                          icon: submitting
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.flag_outlined, size: 18),
                          label: Text(
                            submitting
                                ? 'Submitting report...'
                                : 'Submit Report',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ArtistColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: ArtistColors.primary
                                .withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(detailsController.dispose);
  }

  /// Helper parsing formatted price strings into integer values.
  int _extractNumericPrice(String value) {
    final cleaned = value.replaceAll('₹', '').replaceAll(',', '').trim();
    return int.tryParse(cleaned) ?? 0;
  }

  /// Helper formatting price integers with comma separators.
  String _formatPrice(int value) {
    final valueString = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < valueString.length; i++) {
      final position = valueString.length - i;
      buffer.write(valueString[i]);
      if (position > 1 && position % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }

  /// Displays floating snackbar message feedback.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  /// Card container block wrapper for primary detail sections.
  Widget _section({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      color: ArtistColors.surface,
      child: child,
    );
  }
}
