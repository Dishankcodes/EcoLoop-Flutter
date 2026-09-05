import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';
import '../../../widgets/cart_popup.dart';
import 'checkout.dart';
import 'seller_profile.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetails({super.key, required this.product});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  late PageController _imageController;

  int _currentImage = 0;
  int _quantity = 1;
  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();

    _isWishlisted =
        widget.product['isWishlisted'] == true ||
        widget.product['wishlisted'] == true;
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  // ============================================================
  // PRODUCT DATA
  // ============================================================

  String get title =>
      widget.product['title']?.toString() ?? 'Wooden Study Table';

  int get priceValue {
    final value = widget.product['price'];

    if (value is num) {
      return value.toInt();
    }

    return _extractNumericPrice(value?.toString() ?? '2500');
  }

  String get price => '₹${_formatPrice(priceValue)}';

  String get condition => widget.product['condition']?.toString() ?? 'Good';

  String get category => widget.product['category']?.toString() ?? 'Furniture';

  String get seller => widget.product['seller']?.toString() ?? 'Rahul Mehta';

  String get location =>
      widget.product['location']?.toString() ?? 'Ahmedabad, Gujarat';

  String get description =>
      widget.product['description']?.toString() ??
      'A well-maintained pre-owned wooden study table. '
          'Perfect for students, home offices and creative workspaces. '
          'The table is sturdy, spacious and suitable for students, '
          'home offices and creative workspaces.';

  int get availableQuantity {
    final value = widget.product['availableQuantity'];

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 5;
  }

  double get rating {
    final value = widget.product['rating'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 4.7;
  }

  int get reviewCount {
    final value =
        widget.product['reviewCount'] ?? widget.product['reviews'] ?? 42;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 42;
  }

  List<String> get images {
    final productImages = widget.product['images'];

    if (productImages is List && productImages.isNotEmpty) {
      return productImages
          .map((image) => image.toString())
          .where((image) => image.isNotEmpty)
          .toList();
    }

    final singleImage = widget.product['image']?.toString();

    if (singleImage != null && singleImage.isNotEmpty) {
      return [singleImage];
    }

    return [
      'https://images.unsplash.com/photo-1518455027359-f3f8164ba6b0?auto=format&fit=crop&w=1200&q=85',
      'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=85',
      'https://images.unsplash.com/photo-1541558869434-2840d308329a?auto=format&fit=crop&w=1200&q=85',
      'https://images.unsplash.com/photo-1593642532400-2682810df593?auto=format&fit=crop&w=1200&q=85',
    ];
  }

  // ============================================================
  // BUILD
  // ============================================================

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

  // ============================================================
  // APP BAR
  // ============================================================

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

  // ============================================================
  // IMAGE GALLERY
  // ============================================================

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
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImage = index;
                    });
                  },
                  itemBuilder: (context, index) {
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
                        if (progress == null) {
                          return child;
                        }

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

                // Wishlist
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

                // Image counter
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
                      '${_currentImage + 1}/${images.length}',
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

  // ============================================================
  // PRODUCT HEADER
  // ============================================================

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
                '${widget.product['views'] ?? 12} views',
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
                '${widget.product['wishlistCount'] ?? 4} saved',
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

  // ============================================================
  // SELLER
  // ============================================================

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

  // ============================================================
  // LOCATION
  // ============================================================

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

  // ============================================================
  // DESCRIPTION
  // ============================================================

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

  // ============================================================
  // ITEM INFORMATION
  // ============================================================

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
            widget.product['date']?.toString() ?? '28 Aug 2026',
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

  // ============================================================
  // REVIEWS
  // ============================================================

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
                child: const Text(
                  'See all',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _buildRatingSummary(),

          const SizedBox(height: 16),

          _buildReviewCard(
            name: 'Priya S.',
            rating: 5,
            date: '2 weeks ago',
            review:
                'Great quality! Exactly as shown. Very sturdy and easy to assemble.',
            imageCount: 2,
          ),

          const SizedBox(height: 10),

          _buildReviewCard(
            name: 'Amit K.',
            rating: 4,
            date: '1 month ago',
            review:
                'Good product for the price. Minor scratches but overall great.',
            imageCount: 1,
          ),

          const SizedBox(height: 12),

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
          ),
        ],
      ),
    );
  }

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
                _ratingBar(5, 0.82),
                _ratingBar(4, 0.12),
                _ratingBar(3, 0.04),
                _ratingBar(2, 0.01),
                _ratingBar(1, 0.01),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  // ============================================================
  // ECOLOOP INFORMATION
  // ============================================================

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

  // ============================================================
  // SIMILAR PRODUCTS
  // ============================================================

  Widget _buildSimilarProducts() {
    final products = _similarProducts;

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

  // ============================================================
  // DUMMY RELATED PRODUCTS
  // ============================================================

  List<Map<String, dynamic>> get _similarProducts {
    return [
      {
        'id': 'similar_1',
        'title': 'Laptop Table',
        'price': 1800,
        'condition': 'Good',
        'category': category,
        'seller': 'Amit K.',
        'location': 'Ahmedabad, Gujarat',
        'availableQuantity': 3,
        'image':
            'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=600&q=80',
      },
      {
        'id': 'similar_2',
        'title': 'Bookshelf',
        'price': 2200,
        'condition': 'Used',
        'category': category,
        'seller': 'Neha P.',
        'location': 'Ahmedabad, Gujarat',
        'availableQuantity': 2,
        'image':
            'https://images.unsplash.com/photo-1594620302200-9a762244a156?auto=format&fit=crop&w=600&q=80',
      },
      {
        'id': 'similar_3',
        'title': 'Office Chair',
        'price': 3500,
        'condition': 'Good',
        'category': category,
        'seller': 'Vivek R.',
        'location': 'Gandhinagar, Gujarat',
        'availableQuantity': 4,
        'image':
            'https://images.unsplash.com/photo-1580480055273-228ff5388ef8?auto=format&fit=crop&w=600&q=80',
      },
      {
        'id': 'similar_4',
        'title': 'Computer Desk',
        'price': 2900,
        'condition': 'Good',
        'category': category,
        'seller': 'Rahul M.',
        'location': 'Ahmedabad, Gujarat',
        'availableQuantity': 2,
        'image':
            'https://images.unsplash.com/photo-1518455027359-f3f8164ba6b0?auto=format&fit=crop&w=600&q=80',
      },
    ];
  }

  // ============================================================
  // BOTTOM PURCHASE BAR
  // ============================================================

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
              // Quantity
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

              // Add to cart
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

              // Buy Now
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

  // ============================================================
  // QUANTITY
  // ============================================================

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

  // ============================================================
  // ADD TO CART
  // ============================================================

  void _addToCart() {
    if (availableQuantity <= 0) {
      _showMessage('This product is currently unavailable.');
      return;
    }

    final cartProduct = Map<String, dynamic>.from(widget.product);

    cartProduct['id'] =
        widget.product['productId'] ??
        widget.product['id'] ??
        'product_${title.hashCode}';

    cartProduct['productId'] =
        widget.product['productId'] ??
        widget.product['id'] ??
        'product_${title.hashCode}';

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

    // UI-only cart popup.
    //
    // The popup will use the same cart data once
    // CartManager is connected in the next step.
    CartPopup.show(context, items: [cartProduct]);
  }

  // ============================================================
  // BUY NOW
  // ============================================================

  void _buyNow() {
    if (availableQuantity <= 0) {
      _showMessage('This product is currently unavailable.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Checkout(product: widget.product, quantity: _quantity),
      ),
    );
  }

  // ============================================================
  // WISHLIST
  // ============================================================

  void _toggleWishlist() {
    setState(() {
      _isWishlisted = !_isWishlisted;
    });

    _showMessage(
      _isWishlisted ? 'Added to your wishlist.' : 'Removed from your wishlist.',
    );
  }

  // ============================================================
  // SELLER PROFILE
  // ============================================================

  void _openSellerProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerProfile(
          seller: {
            'name': seller,
            'location': location,
            'rating': '4.8',
            'reviews': '42',
            'listings': '127',
            'sold': '42',
            'positive': '98%',
          },
        ),
      ),
    );
  }

  // ============================================================
  // REVIEWS ACTIONS
  // ============================================================

  void _openAllReviews() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            child: Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 10, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Reviews',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                    children: [
                      _buildRatingSummary(),

                      const SizedBox(height: 18),

                      _buildReviewCard(
                        name: 'Priya S.',
                        rating: 5,
                        date: '2 weeks ago',
                        review:
                            'Great quality! Exactly as shown. Very sturdy and easy to assemble.',
                        imageCount: 2,
                      ),

                      const SizedBox(height: 10),

                      _buildReviewCard(
                        name: 'Amit K.',
                        rating: 4,
                        date: '1 month ago',
                        review:
                            'Good product for the price. Minor scratches but overall great.',
                        imageCount: 1,
                      ),

                      const SizedBox(height: 10),

                      _buildReviewCard(
                        name: 'Neha P.',
                        rating: 5,
                        date: '2 months ago',
                        review:
                            'Seller was helpful and the item was packed properly.',
                        imageCount: 0,
                      ),

                      const SizedBox(height: 10),

                      _buildReviewCard(
                        name: 'Vivek R.',
                        rating: 4,
                        date: '3 months ago',
                        review:
                            'Nice pre-owned item. Description was accurate.',
                        imageCount: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _writeReview() {
    _showMessage('You can review this product after your order is delivered.');
  }

  // ============================================================
  // SHARE
  // ============================================================

  void _shareProduct() {
    _showMessage('Product sharing will be connected later.');
  }

  // ============================================================
  // MORE OPTIONS
  // ============================================================

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

  // ============================================================
  // REPORT
  // ============================================================

  Widget _buildReportSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: InkWell(
        onTap: _reportProduct,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
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

  void _reportProduct() {
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
                  'Why are you reporting this listing?',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 15),

                _reportOption(
                  'Misleading information',
                  Icons.info_outline,
                  sheetContext,
                ),

                _reportOption(
                  'Inappropriate content',
                  Icons.block_outlined,
                  sheetContext,
                ),

                _reportOption(
                  'Suspicious or scam listing',
                  Icons.warning_amber_outlined,
                  sheetContext,
                ),

                _reportOption('Other', Icons.more_horiz_rounded, sheetContext),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reportOption(String title, IconData icon, BuildContext sheetContext) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.textSecondary,
      ),
      onTap: () {
        Navigator.pop(sheetContext);

        _showMessage('Report submitted for review.');
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _extractNumericPrice(String value) {
    final cleaned = value.replaceAll('₹', '').replaceAll(',', '').trim();

    return int.tryParse(cleaned) ?? 0;
  }

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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

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
