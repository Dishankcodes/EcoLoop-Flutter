import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../widgets/cart_popup_user.dart';
import '../reviews/product_reviews.dart';
import '../reviews/write_review.dart';
import 'artist_profile.dart';
import 'checkout.dart';
import 'seller_profile.dart';

/// Screen displaying full item details, image gallery, seller info, reviews, and purchasing options.
class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetails({super.key, required this.product});

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
  bool _cartAdding = false;
  bool _reviewsLoading = false;
  bool _eligibilityLoading = false;
  bool _canReview = false;
  String? _eligibleOrderId;
  List<Map<String, dynamic>> _liveReviews = [];
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

  String get condition => _product['condition']?.toString() ?? 'Good';

  String get category => _product['category']?.toString() ?? 'Furniture';

  String get seller =>
      _product['sellerName']?.toString() ??
      _product['seller']?.toString() ??
      'EcoLoop Member';

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

  String get location => [
    _product['sellerCity'],
    _product['sellerState'],
  ].where((v) => v != null && v.toString().trim().isNotEmpty).join(', ');

  String get description =>
      _product['description']?.toString() ??
      'No description provided by the seller.';

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
      backgroundColor: AppColors.background,
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
                    color: AppColors.primary,
                  ),
                if (_detailsError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Showing saved listing data because the latest refresh failed.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
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
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: const Text(
        'Product Details',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
      color: AppColors.surface,
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
                        color: AppColors.light,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 60,
                            color: AppColors.primary,
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
                          color: AppColors.light,
                          child: const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 60,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppColors.light,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
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
                              ? AppColors.error
                              : AppColors.textPrimary,
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
                      color: selected ? AppColors.primary : AppColors.accent,
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
              color: AppColors.textPrimary,
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
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Negotiable',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text('($reviewCount reviews)', style: AppTextStyles.caption),
              const SizedBox(width: 16),
              const Icon(
                Icons.visibility_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${_product['views'] ?? 0} views',
                style: AppTextStyles.caption,
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.favorite_border_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${_product['wishlistCount'] ?? 0} saved',
                style: AppTextStyles.caption,
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
    final Color color = available <= 2 ? AppColors.error : AppColors.success;
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
        color: AppColors.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
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
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openSellerProfile,
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
                color: AppColors.background,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.accent.withOpacity(0.45)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: AppColors.light,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
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
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFFFB300),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              '4.8',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text('127 listings', style: AppTextStyles.caption),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text('EcoLoop member', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.light.withOpacity(0.55),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Keep conversations and payments inside EcoLoop for a safer transaction.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
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
        onTap: () {
          _showMessage('Location details will be connected later.');
        },
        child: Row(
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(location, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ],
        ),
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
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.light.withOpacity(0.65),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Row(
              children: [
                Icon(Icons.eco_outlined, size: 18, color: AppColors.success),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Buying pre-owned helps extend the life of useful products.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
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
              color: AppColors.textPrimary,
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
            _formatFriendlyDate(_product['createdAt']),
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

  /// Helper row widget for individual item specification items.
  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
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
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openAllReviews,
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
                  color: AppColors.primary,
                ),
              ),
            )
          else if (_liveReviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'No reviews for this product yet.',
                  style: AppTextStyles.caption,
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
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
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
      String? eligibleOrder;
      if (rows is List) {
        for (final raw in rows) {
          if (raw is! Map) continue;
          final order = Map<String, dynamic>.from(raw);
          final orderedProductId =
              (order['productId'] ?? order['product_id'] ?? '').toString();
          final status = (order['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase()
              .replaceAll('_', ' ');
          if (orderedProductId == productId && status == 'delivered') {
            eligibleOrder = (order['orderId'] ?? order['order_id'] ?? '')
                .toString();
            if (eligibleOrder.isNotEmpty) break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _eligibleOrderId = eligibleOrder;
        _canReview =
            eligibleOrder != null &&
            eligibleOrder.isNotEmpty &&
            !_liveReviews.any(
              (r) =>
                  (r['userId'] ?? r['buyerId'] ?? '').toString().isNotEmpty &&
                  (r['productId'] ?? '').toString() == productId,
            );
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

  /// Converts backend ISO timestamps into short, readable dates without
  /// changing the timestamp stored in Google Sheets.
  ///
  /// Examples: Today, Yesterday, 10 Oct, 8 Oct 2025.
  /// ISO timestamps containing Z/UTC offsets are converted to device-local time
  /// before comparing calendar dates. Date-only/local timestamps remain valid.
  String _formatFriendlyDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Date unavailable';
    }

    final raw = value.toString().trim();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final date = parsed.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final listedDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(listedDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dayMonth = '${date.day} ${months[date.month - 1]}';
    return date.year == now.year ? dayMonth : '$dayMonth ${date.year}';
  }

  String _displayReviewDate(dynamic value) => _formatFriendlyDate(value);

  /// Summary bar showing average score and distribution chart for star ratings.
  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
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
                  color: AppColors.textPrimary,
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
              Text('$reviewCount reviews', style: AppTextStyles.caption),
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
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper bar widget rendering percentage distribution for individual star ratings.
  Widget _ratingBar(int number, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 15,
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFB300)),
          const SizedBox(width: 5),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: percentage,
                backgroundColor: AppColors.accent.withOpacity(0.3),
                color: AppColors.primary,
              ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.35)),
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
                  color: AppColors.light,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 19,
                  color: AppColors.primary,
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
                        color: AppColors.textPrimary,
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
                        Text(date, style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            review,
            style: const TextStyle(
              fontSize: 11,
              height: 1.45,
              color: AppColors.textSecondary,
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
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.primary,
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
              color: AppColors.textPrimary,
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
              color: AppColors.light,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: AppColors.textSecondary,
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
    if (products.isEmpty) return const SizedBox.shrink();

    return Container(
      color: AppColors.surface,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showMessage('More products will open later.');
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
                    color: AppColors.light,
                    child: Image.network(
                      product['image'].toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.image_outlined,
                          color: AppColors.primary,
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              product['title'].toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '₹${_formatPrice(_extractNumericPrice(product['price'].toString()))}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mock dataset for similar products recommendations.
  List<Map<String, dynamic>> get _similarProducts =>
      const <Map<String, dynamic>>[];

  /// Persistent bottom purchase bar for quantity selection, cart addition, and instant checkout.
  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 11, 15, 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
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
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
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
                      color: AppColors.primary,
                    ),
                    SizedBox(
                      width: 20,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _increaseQuantity,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      color: AppColors.primary,
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
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
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
                      backgroundColor: AppColors.primary,
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

  /// Formats product data and presents the cart popup drawer.
  Future<void> _addToCart() async {
    if (_cartAdding) return;
    if (availableQuantity <= 0) {
      _showMessage('This product is currently unavailable.');
      return;
    }
    final productId = int.tryParse(_currentProductId);
    if (productId == null || productId <= 0) {
      _showMessage(
        'This product has an invalid ID and cannot be added to cart.',
      );
      return;
    }

    final cartProduct = Map<String, dynamic>.from(_product);
    cartProduct['id'] = productId;
    cartProduct['productId'] = productId;
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

    setState(() => _cartAdding = true);
    try {
      await _api.post('/cart', {'productId': productId, 'quantity': _quantity});
      if (!mounted) return;
      CartPopup.addItem(context, item: cartProduct);
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Could not add item to cart: ${error.toString().replaceFirst('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _cartAdding = false);
    }
  }

  /// Directs user immediately to the checkout flow with selected quantity.
  void _buyNow() {
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
          .toString();

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
              'rating': _product['rating'] ?? 0,
              'reviews': _product['reviewCount'] ?? 0,
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
            'rating': _product['rating'] ?? 0,
            'reviews': _product['reviewCount'] ?? 0,
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

  /// Triggers product sharing option placeholder.

  /// Shares the current EcoLoop product through the device's native share sheet.
  /// Includes the real product details and attaches the first product image
  /// when that image can be downloaded successfully.
  Future<void> _shareProduct() async {
    if (!mounted) return;

    final productName = title;
    final productPrice = price;
    final productCondition = condition;
    final productCategory = category;
    final productDescription = description;
    final productId = _currentProductId.trim();

    // Do not invent a URL: the current app does not yet define a public
    // product-details URL that recipients can open.
    final shareText =
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
      // Use the first available image from the real product data.
      final imageUrl = images.cast<String?>().firstWhere((url) {
        if (url == null || url.trim().isEmpty) return false;

        final uri = Uri.tryParse(url.trim());
        return uri != null &&
            (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty;
      }, orElse: () => null);

      XFile? imageFile;

      if (imageUrl != null) {
        try {
          final response = await http
              .get(Uri.parse(imageUrl.trim()))
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            final uri = Uri.parse(imageUrl.trim());
            final path = uri.path.toLowerCase();

            final extension = path.endsWith('.png')
                ? 'png'
                : path.endsWith('.webp')
                ? 'webp'
                : path.endsWith('.gif')
                ? 'gif'
                : 'jpg';

            final mimeType = extension == 'png'
                ? 'image/png'
                : extension == 'webp'
                ? 'image/webp'
                : extension == 'gif'
                ? 'image/gif'
                : 'image/jpeg';

            imageFile = XFile.fromData(response.bodyBytes, mimeType: mimeType);
          }
        } catch (_) {
          // If the image cannot be downloaded, share the product details
          // as text instead of failing the entire share action.
        }
      }

      final shareParams = ShareParams(
        text: shareText,
        subject: 'Check out $productName on EcoLoop',
        title: 'Share EcoLoop Product',
        files: imageFile == null ? null : [imageFile],
        fileNameOverrides: imageFile == null
            ? null
            : ['ecoloop_product.${_sharedImageExtension()}'],
      );

      await SharePlus.instance.share(shareParams);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to share this product. Please try again.');
    }
  }

  /// Returns a safe filename extension for the downloaded image.
  /// This helper is only for the shared file's filename.
  String _sharedImageExtension() {
    if (images.isEmpty) return 'jpg';

    final uri = Uri.tryParse(images.first);
    final path = uri?.path.toLowerCase() ?? '';

    if (path.endsWith('.png')) return 'png';
    if (path.endsWith('.webp')) return 'webp';
    if (path.endsWith('.gif')) return 'gif';

    return 'jpg';
  }

  /// Displays bottom sheet with secondary actions.
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                ListTile(
                  leading: const Icon(
                    Icons.favorite_border_rounded,
                    color: AppColors.primary,
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
                    color: AppColors.primary,
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
                    color: AppColors.primary,
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
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Report Listing',
                    style: TextStyle(color: AppColors.error),
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
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 7),
              Text(
                'Report this listing',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
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
      backgroundColor: AppColors.surface,
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
                            color: AppColors.accent,
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tell us why this listing should be reviewed. Your report will be sent to EcoLoop for moderation.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: AppColors.textSecondary,
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
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          trailing: Icon(
                            selected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
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
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.accent),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.accent),
                          ),
                        ),
                      ),
                      if (formError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          formError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
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
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary
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
      color: AppColors.surface,
      child: child,
    );
  }
}
