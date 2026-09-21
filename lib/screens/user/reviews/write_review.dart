import 'package:flutter/material.dart';

import '../../../app_theme/app_colors.dart';
import '../../../app_theme/app_text_styles.dart';

/// UI-only Write Review page.
///
/// The page returns the entered review data to the previous screen when
/// submitted. Backend/API integration can be connected later.
class WriteReview extends StatefulWidget {
  final Map<String, dynamic> product;

  const WriteReview({super.key, required this.product});

  @override
  State<WriteReview> createState() => _WriteReviewState();
}

class _WriteReviewState extends State<WriteReview> {
  final TextEditingController _reviewController = TextEditingController();

  int _rating = 0;
  bool _wouldRecommend = true;
  bool _isSubmitting = false;

  String get _title =>
      widget.product['title']?.toString() ?? 'Wooden Study Table';

  String get _image {
    final images = widget.product['images'];

    if (images is List && images.isNotEmpty) {
      return images.first.toString();
    }

    final image = widget.product['image']?.toString();

    if (image != null && image.isNotEmpty) {
      return image;
    }

    return 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6b0?auto=format&fit=crop&w=700&q=80';
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Write Review',
          style: AppTextStyles.title.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductCard(),
              const SizedBox(height: 22),
              _buildRatingSection(),
              const SizedBox(height: 22),
              _buildReviewSection(),
              const SizedBox(height: 20),
              _buildRecommendationSection(),
              const SizedBox(height: 25),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _image,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 68,
                height: 68,
                color: AppColors.light,
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How was your experience?',
          style: AppTextStyles.title.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Tap a star to rate this product.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final value = index + 1;
              final selected = value <= _rating;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rating = value;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      selected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 43,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 9),
        Center(
          child: Text(
            _rating == 0 ? 'Select your rating' : _ratingLabel,
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Select your rating';
    }
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us more',
          style: AppTextStyles.title.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Your review can help another person make a better choice.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reviewController,
          maxLines: 6,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'What did you like? How was the condition?',
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            filled: true,
            fillColor: AppColors.surface,
            alignLabelWithHint: true,
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
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.accent.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.thumb_up_alt_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Would you recommend it?',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Help us understand your experience.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _wouldRecommend,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() {
                _wouldRecommend = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.surface,
                ),
              )
            : Text(
                'Submit Review',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      _showMessage('Please select a rating first.');
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      _showMessage('Please write a short review.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    final review = {
      'rating': _rating,
      'comment': _reviewController.text.trim(),
      'wouldRecommend': _wouldRecommend,
      'date': 'Just now',
    };

    Navigator.pop(context, review);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
