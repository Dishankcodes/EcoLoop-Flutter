import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ProductDetails extends StatefulWidget {
  const ProductDetails({super.key, required this.product});

  final Map<String, dynamic> product;

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  int _selectedImage = 0;
  int _quantity = 1;

  bool _isSaved = false;

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final List<dynamic> imageUrls = product['imageUrls'] is List
        ? product['imageUrls']
        : [];

    final int availableQuantity =
        (product['availableQuantity'] as num?)?.toInt() ?? 1;

    final int price = (product['price'] as num?)?.toInt() ?? 0;

    final int totalPrice = price * _quantity;

    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
        ),

        title: Text(
          'Product Details',
          style: ArtistTextStyles.title.copyWith(fontSize: 18),
        ),

        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: () {
              setState(() {
                _isSaved = !_isSaved;
              });

              _showMessage(
                _isSaved ? 'Product saved' : 'Product removed from saved items',
              );
            },
            icon: Icon(
              _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: ArtistColors.primary,
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // PRODUCT IMAGE
              // ==================================================
              _buildMainImage(imageUrls),

              const SizedBox(height: 12),

              // ==================================================
              // IMAGE THUMBNAILS
              // ==================================================
              if (imageUrls.length > 1) _buildImageThumbnails(imageUrls),

              const SizedBox(height: 22),

              // ==================================================
              // CATEGORY + CONDITION
              // ==================================================
              Row(
                children: [
                  _buildTag(
                    product['category']?.toString() ?? 'Product',
                    Icons.category_outlined,
                  ),

                  const SizedBox(width: 8),

                  _buildTag(
                    product['condition']?.toString() ?? 'Used',
                    Icons.recycling_outlined,
                  ),

                  const Spacer(),

                  if (product['status'] != null)
                    _buildStatusTag(product['status'].toString()),
                ],
              ),

              const SizedBox(height: 14),

              // ==================================================
              // TITLE
              // ==================================================
              Text(
                product['title']?.toString() ?? 'Untitled Product',
                style: ArtistTextStyles.heading.copyWith(fontSize: 25),
              ),

              const SizedBox(height: 8),

              // ==================================================
              // PRICE
              // ==================================================
              Text(
                '₹${price.toStringAsFixed(0)}',
                style: ArtistTextStyles.title.copyWith(
                  fontSize: 24,
                  color: ArtistColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // SELLER CARD
              // ==================================================
              _buildSellerCard(product),

              const SizedBox(height: 22),

              // ==================================================
              // DESCRIPTION
              // ==================================================
              _buildSectionTitle('Description'),

              const SizedBox(height: 8),

              Text(
                product['description']?.toString() ??
                    'No description available.',
                style: ArtistTextStyles.body,
              ),

              const SizedBox(height: 24),

              // ==================================================
              // PRODUCT INFORMATION
              // ==================================================
              _buildSectionTitle('Product Information'),

              const SizedBox(height: 12),

              _buildInformationCard(product),

              const SizedBox(height: 24),

              // ==================================================
              // AVAILABILITY
              // ==================================================
              _buildSectionTitle('Availability'),

              const SizedBox(height: 10),

              _buildAvailabilityCard(availableQuantity),

              const SizedBox(height: 24),

              // ==================================================
              // QUANTITY
              // ==================================================
              _buildSectionTitle('Quantity'),

              const SizedBox(height: 10),

              _buildQuantitySelector(availableQuantity),

              const SizedBox(height: 24),

              // ==================================================
              // TOTAL
              // ==================================================
              _buildTotalCard(price, totalPrice),

              const SizedBox(height: 20),

              // ==================================================
              // ACTION
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: availableQuantity <= 0 ? null : _handleBuy,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                  label: Text('Buy Now', style: ArtistTextStyles.button),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // CONTACT / SECONDARY ACTION
              // ==================================================
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showMessage('Contact seller will be connected later.');
                  },
                  icon: const Icon(Icons.chat_outlined, size: 19),
                  label: Text(
                    'Contact Seller',
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      color: ArtistColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // ==================================================
              // PRODUCT STATS
              // ==================================================
              _buildProductStats(product),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // MAIN IMAGE
  // ==========================================================

  Widget _buildMainImage(List<dynamic> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: ArtistColors.surfaceSoft,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: ArtistColors.textMuted,
          ),
        ),
      );
    }

    final String image = imageUrls[_selectedImage].toString();

    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ArtistColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: ArtistColors.textMuted,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(
            child: CircularProgressIndicator(
              color: ArtistColors.primary,
              strokeWidth: 2,
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // IMAGE THUMBNAILS
  // ==========================================================

  Widget _buildImageThumbnails(List<dynamic> imageUrls) {
    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = _selectedImage == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedImage = index;
              });
            },
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? ArtistColors.primary : ArtistColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imageUrls[index].toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: ArtistColors.surfaceSoft,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: ArtistColors.textMuted,
                      size: 22,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // SELLER CARD
  // ==========================================================

  Widget _buildSellerCard(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: ArtistColors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: ArtistColors.primary,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seller', style: ArtistTextStyles.small),
                const SizedBox(height: 2),
                Text(
                  product['seller']?.toString() ?? 'Unknown Seller',
                  style: ArtistTextStyles.bodyMedium,
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: ArtistColors.light.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              product['sellerType']?.toString() ?? 'Artist',
              style: ArtistTextStyles.small.copyWith(
                color: ArtistColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFORMATION CARD
  // ==========================================================

  Widget _buildInformationCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          _informationRow(
            'Product ID',
            product['productId']?.toString() ?? '-',
            Icons.tag_outlined,
          ),

          _divider(),

          _informationRow(
            'Category ID',
            product['categoryId']?.toString() ?? '-',
            Icons.category_outlined,
          ),

          _divider(),

          _informationRow(
            'Listing Type',
            product['listingType']?.toString() ?? '-',
            Icons.sell_outlined,
          ),

          _divider(),

          _informationRow(
            'Condition',
            product['condition']?.toString() ?? '-',
            Icons.recycling_outlined,
          ),

          _divider(),

          _informationRow(
            'Quantity',
            product['quantity']?.toString() ?? '-',
            Icons.inventory_2_outlined,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFORMATION ROW
  // ==========================================================

  Widget _informationRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: ArtistColors.primary),
          ),

          const SizedBox(width: 11),

          Expanded(child: Text(title, style: ArtistTextStyles.body)),

          Text(
            value,
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // AVAILABILITY
  // ==========================================================

  Widget _buildAvailabilityCard(int availableQuantity) {
    final bool available = availableQuantity > 0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: available
            ? ArtistColors.success.withOpacity(0.08)
            : ArtistColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: available
              ? ArtistColors.success.withOpacity(0.25)
              : ArtistColors.error.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            available
                ? Icons.check_circle_outline_rounded
                : Icons.remove_circle_outline_rounded,
            color: available ? ArtistColors.success : ArtistColors.error,
            size: 21,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              available
                  ? '$availableQuantity item${availableQuantity == 1 ? '' : 's'} available'
                  : 'Currently unavailable',
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: available ? ArtistColors.success : ArtistColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // QUANTITY SELECTOR
  // ==========================================================

  Widget _buildQuantitySelector(int availableQuantity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          Text('Select quantity', style: ArtistTextStyles.body),

          const Spacer(),

          _quantityButton(
            icon: Icons.remove_rounded,
            onTap: _quantity > 1
                ? () {
                    setState(() {
                      _quantity--;
                    });
                  }
                : null,
          ),

          SizedBox(
            width: 45,
            child: Center(
              child: Text(
                '$_quantity',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          _quantityButton(
            icon: Icons.add_rounded,
            onTap: _quantity < availableQuantity
                ? () {
                    setState(() {
                      _quantity++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // QUANTITY BUTTON
  // ==========================================================

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap == null
              ? ArtistColors.surfaceSoft
              : ArtistColors.light.withOpacity(0.6),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? ArtistColors.textMuted : ArtistColors.primary,
        ),
      ),
    );
  }

  // ==========================================================
  // TOTAL CARD
  // ==========================================================

  Widget _buildTotalCard(int price, int totalPrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total', style: ArtistTextStyles.caption),
                const SizedBox(height: 3),
                Text(
                  '₹${totalPrice.toStringAsFixed(0)}',
                  style: ArtistTextStyles.title.copyWith(
                    color: ArtistColors.primary,
                    fontSize: 21,
                  ),
                ),
              ],
            ),
          ),

          Text('₹$price × $_quantity', style: ArtistTextStyles.caption),
        ],
      ),
    );
  }

  // ==========================================================
  // PRODUCT STATS
  // ==========================================================

  Widget _buildProductStats(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          _statItem(
            icon: Icons.visibility_outlined,
            value: product['views']?.toString() ?? '0',
            label: 'Views',
          ),

          _verticalDivider(),

          _statItem(
            icon: Icons.favorite_border_rounded,
            value: product['wishlistCount']?.toString() ?? '0',
            label: 'Wishlist',
          ),

          _verticalDivider(),

          _statItem(
            icon: Icons.shopping_bag_outlined,
            value: product['salesCount']?.toString() ?? '0',
            label: 'Sales',
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STAT ITEM
  // ==========================================================

  Widget _statItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 19, color: ArtistColors.primary),

          const SizedBox(height: 5),

          Text(
            value,
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          Text(label, style: ArtistTextStyles.small),
        ],
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: ArtistTextStyles.title.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ==========================================================
  // TAG
  // ==========================================================

  Widget _buildTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ArtistColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ArtistColors.primary),

          const SizedBox(width: 5),

          Text(
            text,
            style: ArtistTextStyles.small.copyWith(
              color: ArtistColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STATUS TAG
  // ==========================================================

  Widget _buildStatusTag(String status) {
    final bool published = status.toLowerCase() == 'published';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: published
            ? ArtistColors.success.withOpacity(0.1)
            : ArtistColors.surfaceSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        status,
        style: ArtistTextStyles.small.copyWith(
          color: published ? ArtistColors.success : ArtistColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================================
  // DIVIDER
  // ==========================================================

  Widget _divider() {
    return Divider(height: 1, color: ArtistColors.border);
  }

  // ==========================================================
  // VERTICAL DIVIDER
  // ==========================================================

  Widget _verticalDivider() {
    return Container(width: 1, height: 42, color: ArtistColors.border);
  }

  // ==========================================================
  // BUY ACTION
  // ==========================================================

  void _handleBuy() {
    _showMessage('Checkout will be connected in the next phase.');
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: ArtistTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: ArtistColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}
