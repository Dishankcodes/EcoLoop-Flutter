import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';

class ReviewHistory extends StatefulWidget {
  const ReviewHistory({super.key});

  @override
  State<ReviewHistory> createState() => _ReviewHistoryState();
}

class _ReviewHistoryState extends State<ReviewHistory> {
  // ACTIVE TAB

  int selectedTab = 0;

  // DEMO PRODUCT REVIEWS

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

  // DEMO SELLER REVIEWS

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

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // APP BAR
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),

        title: Text(
          'My Reviews',
          style: AppTextStyles.title.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // BODY
      body: SafeArea(
        child: Column(
          children: [
            // TAB SWITCHER
            _buildTabSwitcher(),

            const SizedBox(height: 5),

            // CONTENT
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

  // TAB SWITCHER

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(14),
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

  // TAB

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
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),

            const SizedBox(width: 6),

            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // PRODUCT REVIEWS

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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        _buildSectionIntro(
          title: 'Your Product Reviews',
          subtitle: '${productReviews.length} reviews written',
        ),

        const SizedBox(height: 14),

        ...productReviews.map((review) {
          return _buildProductReviewCard(review);
        }),
      ],
    );
  }

  // SELLER REVIEWS

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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        _buildSectionIntro(
          title: 'Your Seller Reviews',
          subtitle: '${sellerReviews.length} reviews written',
        ),

        const SizedBox(height: 14),

        ...sellerReviews.map((review) {
          return _buildSellerReviewCard(review);
        }),
      ],
    );
  }

  // SECTION INTRO

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
                style: AppTextStyles.title.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            selectedTab == 0
                ? '${productReviews.length}'
                : '${sellerReviews.length}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // PRODUCT REVIEW CARD

  Widget _buildProductReviewCard(_ProductReviewHistory review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PRODUCT INFORMATION
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(review.image),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Seller: ${review.sellerName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        _buildStars(review.rating, size: 15),

                        const SizedBox(width: 6),

                        Text(
                          '${review.rating}.0',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
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

          const SizedBox(height: 14),

          // REVIEW TEXT
          Text(review.review, style: AppTextStyles.body.copyWith(height: 1.5)),

          const SizedBox(height: 13),

          // DATE + EDIT
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.textSecondary,
              ),

              const SizedBox(width: 5),

              Text(review.date, style: AppTextStyles.caption),

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

  // SELLER REVIEW CARD

  Widget _buildSellerReviewCard(_SellerReviewHistory review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SELLER INFORMATION
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.light,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),

              const SizedBox(width: 11),

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
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(width: 5),

                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        _buildStars(review.rating, size: 15),

                        const SizedBox(width: 6),

                        Text(
                          '${review.rating}.0',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textPrimary,
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

          const SizedBox(height: 14),

          // REVIEW TEXT
          Text(review.review, style: AppTextStyles.body.copyWith(height: 1.5)),

          const SizedBox(height: 13),

          // DATE + EDIT
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: AppColors.textSecondary,
              ),

              const SizedBox(width: 5),

              Text(review.date, style: AppTextStyles.caption),

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

  // PRODUCT IMAGE

  Widget _buildProductImage(String imageUrl) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.secondary,
          );
        },
      ),
    );
  }

  // MORE BUTTON

  Widget _buildMoreButton({required VoidCallback onTap}) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: const Icon(
        Icons.more_horiz_rounded,
        size: 21,
        color: AppColors.textSecondary,
      ),
    );
  }

  // SMALL ACTION BUTTON

  Widget _buildSmallActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withOpacity(0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),

            const SizedBox(width: 5),

            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // STARS

  Widget _buildStars(int rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final bool filled = index < rating;

        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? AppColors.primary : AppColors.textSecondary,
        );
      }),
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState({
    required Key key,
    required IconData icon,
    required String title,
    required String message,
  }) {
    return ListView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(30, 65, 30, 30),
      children: [
        Container(
          width: 75,
          height: 75,
          decoration: const BoxDecoration(
            color: AppColors.light,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 32),
        ),

        const SizedBox(height: 18),

        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
      ],
    );
  }

  // PRODUCT REVIEW OPTIONS

  void _showProductReviewOptions(_ProductReviewHistory review) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBottomOption(
                  icon: Icons.edit_outlined,
                  title: 'Edit Review',
                  onTap: () {
                    Navigator.pop(context);

                    _editProductReview(review);
                  },
                ),

                const SizedBox(height: 8),

                _buildBottomOption(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Review',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(context);

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

  // SELLER REVIEW OPTIONS

  void _showSellerReviewOptions(_SellerReviewHistory review) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBottomOption(
                  icon: Icons.edit_outlined,
                  title: 'Edit Review',
                  onTap: () {
                    Navigator.pop(context);

                    _editSellerReview(review);
                  },
                ),

                const SizedBox(height: 8),

                _buildBottomOption(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete Review',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(context);

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

  // BOTTOM OPTION

  Widget _buildBottomOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: destructive
              ? AppColors.error.withOpacity(0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: destructive
                ? AppColors.error.withOpacity(0.2)
                : AppColors.accent.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: destructive ? AppColors.error : AppColors.primary,
            ),

            const SizedBox(width: 10),

            Text(
              title,
              style: AppTextStyles.body.copyWith(
                color: destructive ? AppColors.error : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Spacer(),

            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: destructive ? AppColors.error : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // EDIT PRODUCT REVIEW

  void _editProductReview(_ProductReviewHistory review) {
    _showMessage('Product review editing will be connected next.');
  }

  // EDIT SELLER REVIEW

  void _editSellerReview(_SellerReviewHistory review) {
    _showMessage('Seller review editing will be connected next.');
  }

  // DELETE PRODUCT REVIEW

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

  // DELETE SELLER REVIEW

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

  // DELETE CONFIRMATION

  void _showDeleteConfirmation({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,

          title: Text(
            title,
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w600),
          ),

          content: Text(message, style: AppTextStyles.body),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // SNACKBAR

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

// PRODUCT REVIEW HISTORY MODEL

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

// SELLER REVIEW HISTORY MODEL

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
