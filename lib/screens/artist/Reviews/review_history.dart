import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

class ReviewHistory extends StatefulWidget {
  const ReviewHistory({super.key});

  @override
  State<ReviewHistory> createState() => _ReviewHistoryState();
}

class _ReviewHistoryState extends State<ReviewHistory> {
  int selectedTab = 0;

  final List<_ProductReviewHistory> productReviews = [
    _ProductReviewHistory(
      productName: 'Wooden Study Table',
      sellerName: 'Rahul',
      rating: 5,
      date: '12 Sep 2026',
      review:
          'Really good quality product. The table was exactly as described and the condition was excellent.',
      image:
          'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc'
          '?auto=format&fit=crop&w=800&q=85',
    ),
    _ProductReviewHistory(
      productName: 'Vintage Storage Cabinet',
      sellerName: 'Meera Crafts',
      rating: 4,
      date: '08 Sep 2026',
      review:
          'Good product overall. The finish was nice and the seller packed everything carefully.',
      image:
          'https://images.unsplash.com/photo-1558997519-83ea9252edf8'
          '?auto=format&fit=crop&w=800&q=85',
    ),
    _ProductReviewHistory(
      productName: 'Reclaimed Wood Pieces',
      sellerName: 'GreenCraft',
      rating: 5,
      date: '28 Aug 2026',
      review:
          'Perfect for my DIY project. The pieces were useful and exactly what I needed.',
      image:
          'https://images.unsplash.com/photo-1519710164239-da123dc03ef4'
          '?auto=format&fit=crop&w=800&q=85',
    ),
  ];

  final List<_SellerReviewHistory> sellerReviews = [
    _SellerReviewHistory(
      sellerName: 'Rahul',
      rating: 5,
      date: '12 Sep 2026',
      review:
          'Very helpful seller and communication was excellent throughout the purchase.',
    ),
    _SellerReviewHistory(
      sellerName: 'Meera Crafts',
      rating: 4,
      date: '08 Sep 2026',
      review:
          'Good seller. The product was packed properly and delivered safely.',
    ),
    _SellerReviewHistory(
      sellerName: 'GreenCraft',
      rating: 5,
      date: '28 Aug 2026',
      review:
          'Very professional ReMaker. Would definitely buy from them again.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
          tooltip: 'Back',
        ),
        title: Text(
          'My Reviews',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTabSwitcher(),
            const SizedBox(height: 3),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: selectedTab == 0
                    ? _buildProductReviews()
                    : _buildSellerReviews(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: ArtistColors.surfaceSoft,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTab(
                label: 'Product Reviews',
                icon: Icons.inventory_2_outlined,
                index: 0,
              ),
            ),
            Expanded(
              child: _buildTab(
                label: 'Seller Reviews',
                icon: Icons.person_outline_rounded,
                index: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required int index,
  }) {
    final bool selected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? ArtistColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: ArtistColors.textPrimary.withValues(alpha: 0.04),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? ArtistColors.primary
                  : ArtistColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArtistTextStyles.small.copyWith(
                  color: selected
                      ? ArtistColors.primary
                      : ArtistColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductReviews() {
    if (productReviews.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('product-empty'),
        icon: Icons.rate_review_outlined,
        title: 'No product reviews yet',
        message: 'Reviews you write for products will appear here.',
      );
    }

    return ListView(
      key: const ValueKey('product-reviews'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 24),
      children: [
        _buildSectionIntro(
          title: 'Your Product Reviews',
          subtitle: '${productReviews.length} reviews written',
        ),
        const SizedBox(height: 12),
        ...productReviews.map((review) => _buildProductReviewCard(review)),
      ],
    );
  }

  Widget _buildSellerReviews() {
    if (sellerReviews.isEmpty) {
      return _buildEmptyState(
        key: const ValueKey('seller-empty'),
        icon: Icons.person_outline_rounded,
        title: 'No seller reviews yet',
        message: 'Reviews you write for sellers and ReMakers will appear here.',
      );
    }

    return ListView(
      key: const ValueKey('seller-reviews'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 24),
      children: [
        _buildSectionIntro(
          title: 'Your Seller Reviews',
          subtitle: '${sellerReviews.length} reviews written',
        ),
        const SizedBox(height: 12),
        ...sellerReviews.map((review) => _buildSellerReviewCard(review)),
      ],
    );
  }

  Widget _buildSectionIntro({required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ArtistTextStyles.title.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: ArtistTextStyles.small),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: ArtistColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            selectedTab == 0
                ? '${productReviews.length}'
                : '${sellerReviews.length}',
            style: ArtistTextStyles.small.copyWith(
              color: ArtistColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductReviewCard(_ProductReviewHistory review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(review.image),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Seller: ${review.sellerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.small,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _buildStars(review.rating, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          '${review.rating}.0',
                          style: ArtistTextStyles.small.copyWith(
                            color: ArtistColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildMoreButton(
                onTap: () {
                  _showProductReviewOptions(review);
                },
              ),
            ],
          ),
          const SizedBox(height: 11),

          Text(
            review.review,
            style: ArtistTextStyles.body.copyWith(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 11),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: ArtistColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(review.date, style: ArtistTextStyles.small),
              const Spacer(),
              _buildSmallActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () {
                  _editProductReview(review);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSellerReviewCard(_SellerReviewHistory review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: const BoxDecoration(
                  color: ArtistColors.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: ArtistColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.sellerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ArtistTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: ArtistColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStars(review.rating, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          '${review.rating}.0',
                          style: ArtistTextStyles.small.copyWith(
                            color: ArtistColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildMoreButton(
                onTap: () {
                  _showSellerReviewOptions(review);
                },
              ),
            ],
          ),
          const SizedBox(height: 11),

          Text(
            review.review,
            style: ArtistTextStyles.body.copyWith(fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 11),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: ArtistColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(review.date, style: ArtistTextStyles.small),
              const Spacer(),
              _buildSmallActionButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () {
                  _editSellerReview(review);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: ArtistColors.surfaceSoft,
        borderRadius: BorderRadius.circular(11),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported_outlined,
            color: ArtistColors.secondary,
          );
        },
      ),
    );
  }

  Widget _buildMoreButton({required VoidCallback onTap}) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: const Icon(
        Icons.more_horiz_rounded,
        size: 21,
        color: ArtistColors.textSecondary,
      ),
    );
  }

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ArtistColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ArtistColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: ArtistColors.primary),
            const SizedBox(width: 5),
            Text(
              label,
              style: ArtistTextStyles.small.copyWith(
                color: ArtistColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(int rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final bool filled = index < rating;

        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? ArtistColors.warning : ArtistColors.textMuted,
        );
      }),
    );
  }

  Widget _buildEmptyState({
    required Key key,
    required IconData icon,
    required String title,
    required String message,
  }) {
    return ListView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(30, 55, 30, 30),
      children: [
        Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: ArtistColors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ArtistColors.primary, size: 30),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: ArtistTextStyles.body.copyWith(fontSize: 13),
        ),
      ],
    );
  }

  void _showProductReviewOptions(_ProductReviewHistory review) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBottomOption(
                  icon: Icons.edit_outlined,
                  title: 'Edit Review',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _editProductReview(review);
                  },
                ),
                const SizedBox(height: 7),
                _buildBottomOption(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Review',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeleteProductReview(review);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSellerReviewOptions(_SellerReviewHistory review) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBottomOption(
                  icon: Icons.edit_outlined,
                  title: 'Edit Review',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _editSellerReview(review);
                  },
                ),
                const SizedBox(height: 7),
                _buildBottomOption(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Review',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeleteSellerReview(review);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final Color iconColor = destructive
        ? ArtistColors.error
        : ArtistColors.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: destructive
              ? ArtistColors.error.withValues(alpha: 0.05)
              : ArtistColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: destructive
                ? ArtistColors.error.withValues(alpha: 0.18)
                : ArtistColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Text(
              title,
              style: ArtistTextStyles.bodyMedium.copyWith(
                color: destructive
                    ? ArtistColors.error
                    : ArtistColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: destructive
                  ? ArtistColors.error
                  : ArtistColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _editProductReview(_ProductReviewHistory review) {
    _showMessage('Product review editing will be connected next.');
  }

  void _editSellerReview(_SellerReviewHistory review) {
    _showMessage('Seller review editing will be connected next.');
  }

  void _confirmDeleteProductReview(_ProductReviewHistory review) {
    _showDeleteConfirmation(
      title: 'Delete product review?',
      message: 'This review will be removed from your review history.',
      onConfirm: () {
        setState(() {
          productReviews.remove(review);
        });

        _showMessage('Product review deleted.');
      },
    );
  }

  void _confirmDeleteSellerReview(_SellerReviewHistory review) {
    _showDeleteConfirmation(
      title: 'Delete seller review?',
      message: 'This review will be removed from your review history.',
      onConfirm: () {
        setState(() {
          sellerReviews.remove(review);
        });

        _showMessage('Seller review deleted.');
      },
    );
  }

  void _showDeleteConfirmation({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: ArtistColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(message, style: ArtistTextStyles.body),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: Text(
                'Delete',
                style: ArtistTextStyles.button.copyWith(fontSize: 13),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: ArtistTextStyles.body.copyWith(
              color: Colors.white,
              fontSize: 12.5,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ArtistColors.accent,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      );
  }
}

class _ProductReviewHistory {
  final String productName;
  final String sellerName;
  final int rating;
  final String date;
  final String review;
  final String image;

  _ProductReviewHistory({
    required this.productName,
    required this.sellerName,
    required this.rating,
    required this.date,
    required this.review,
    required this.image,
  });
}

class _SellerReviewHistory {
  final String sellerName;
  final int rating;
  final String date;
  final String review;

  _SellerReviewHistory({
    required this.sellerName,
    required this.rating,
    required this.date,
    required this.review,
  });
}
