import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../buy_products/artist_profile.dart';
import '../buy_products/seller_profile.dart';

class WriteSellerReview extends StatefulWidget {
  final String sellerName;
  final String? sellerImage;
  final String sellerId;
  final String sellerType;
  final String? orderId;

  const WriteSellerReview({
    super.key,
    required this.sellerName,
    this.sellerImage,
    this.sellerId = '',
    this.sellerType = 'user',
    this.orderId,
  });

  @override
  State<WriteSellerReview> createState() => _WriteSellerReviewState();
}

class _WriteSellerReviewState extends State<WriteSellerReview> {
  final TextEditingController _reviewController = TextEditingController();

  int selectedRating = 0;
  bool _submitting = false;
  final EcoLoopApi _api = EcoLoopApi.instance;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  bool get canSubmit {
    return !_submitting &&
        selectedRating > 0 &&
        _reviewController.text.trim().length >= 5 &&
        _reviewController.text.trim().length <= 500 &&
        widget.sellerId.trim().isNotEmpty &&
        (widget.orderId?.trim().isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          'Write a Review',
          style: AppTextStyles.title.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSellerCard(),
              const SizedBox(height: 28),
              Text(
                'How was your experience?',
                style: AppTextStyles.title.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rate your experience with this seller.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 18),
              _buildRatingSelector(),
              const SizedBox(height: 30),
              Text(
                'Share your experience',
                style: AppTextStyles.title.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _buildReviewField(),
              const SizedBox(height: 26),
              _buildGuidelines(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  Widget _buildSellerCard() {
    final hasImage =
        widget.sellerImage != null && widget.sellerImage!.trim().isNotEmpty;

    return InkWell(
      onTap: _openSellerProfile,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
                image: hasImage
                    ? DecorationImage(
                        image: NetworkImage(widget.sellerImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasImage
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 30,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Seller',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSellerProfile() {
    final sellerId = widget.sellerId.trim();
    if (sellerId.isEmpty) {
      _showMessage(
        'Seller profile is unavailable because the seller ID is missing.',
      );
      return;
    }

    final type = widget.sellerType.trim().toLowerCase();
    final isArtist =
        type == 'artist' ||
        type == 'remaker' ||
        type == 're_maker' ||
        type == 're-maker';
    final profile = <String, dynamic>{
      'id': sellerId,
      'userId': sellerId,
      'sellerId': sellerId,
      'artistId': sellerId,
      'sellerType': isArtist ? 'artist' : 'user',
      'role': isArtist ? 'artist' : 'user',
      'name': widget.sellerName,
      'userName': widget.sellerName,
      'sellerName': widget.sellerName,
      'firstName': widget.sellerName,
      'profilePhotoUrl': widget.sellerImage ?? '',
      'profileImage': widget.sellerImage ?? '',
      'image': widget.sellerImage ?? '',
    };

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => isArtist
            ? ArtistProfile(artist: profile)
            : SellerProfile(seller: profile),
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = selectedRating >= value;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRating = value;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: AnimatedScale(
                    scale: selected ? 1.05 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      selected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 42,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            _ratingLabel,
            style: AppTextStyles.body.copyWith(
              color: selectedRating == 0
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String get _ratingLabel {
    switch (selectedRating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Needs improvement';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
    }
  }

  Widget _buildReviewField() {
    return TextField(
      controller: _reviewController,
      minLines: 6,
      maxLines: 9,
      maxLength: 500,
      onChanged: (_) {
        setState(() {});
      },
      textInputAction: TextInputAction.newline,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Tell others about your experience with this seller...',
        hintStyle: AppTextStyles.hint,
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.6),
            width: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelines() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Keep your review honest, respectful, and focused on your experience with the seller.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: AppColors.accent.withOpacity(0.4)),
          ),
        ),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canSubmit ? _submitReview : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.accent.withOpacity(0.45),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Submit Review', style: AppTextStyles.button),
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (!canSubmit) {
      _showMessage(
        'Choose a rating, write at least 5 characters, and open this form from an eligible order.',
      );
      return;
    }

    final reviewText = _reviewController.text.trim();
    final sellerId = int.tryParse(widget.sellerId.trim());
    final orderId = int.tryParse((widget.orderId ?? '').trim());
    if (sellerId == null || sellerId <= 0 || orderId == null || orderId <= 0) {
      _showMessage(
        'Seller or order information is missing. Open the review form from your order.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final type = widget.sellerType.trim().toLowerCase();
      final isArtist = type == 'artist' || type == 'remaker';
      final dynamic response;
      if (isArtist) {
        response = await _api.post('/reviews/artist', <String, dynamic>{
          'artistId': sellerId,
          'orderId': orderId,
          'rating': selectedRating,
          'comment': reviewText,
        });
      } else {
        response = await _api.post('/reviews/seller', <String, dynamic>{
          'sellerId': sellerId,
          'sellerType': 'user',
          'orderId': orderId,
          'reviewType': 'seller',
          'rating': selectedRating,
          'comment': reviewText,
        });
      }

      if (!mounted) return;
      final Map<String, dynamic> saved = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      final dynamic nested =
          saved['review'] ?? saved['data'] ?? saved['result'];
      final Map<String, dynamic> reviewData = nested is Map
          ? Map<String, dynamic>.from(nested)
          : saved;
      Navigator.pop(
        context,
        SellerReviewResult(
          reviewerName: 'You',
          initials: 'YO',
          rating: selectedRating,
          review: reviewText,
          reviewId: (reviewData['reviewId'] ?? reviewData['id'] ?? '')
              .toString(),
          orderId: orderId.toString(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(_friendlyError(error));
    }
  }

  String _friendlyError(Object error) {
    var message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty)
      message = 'Could not submit your review. Please try again.';
    return message;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class SellerReviewResult {
  final String reviewerName;
  final String initials;
  final int rating;
  final String review;
  final String reviewId;
  final String orderId;

  const SellerReviewResult({
    required this.reviewerName,
    required this.initials,
    required this.rating,
    required this.review,
    this.reviewId = '',
    this.orderId = '',
  });
}
