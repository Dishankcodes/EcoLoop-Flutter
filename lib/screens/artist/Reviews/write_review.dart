import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';

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
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ArtistColors.textPrimary,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
          ),
          tooltip: 'Back',
        ),
        title: Text(
          'Write Review',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductCard(),
              const SizedBox(height: 18),
              _buildRatingSection(),
              const SizedBox(height: 18),
              _buildReviewSection(),
              const SizedBox(height: 18),
              _buildRecommendationSection(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Product card.
  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
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
                color: ArtistColors.surfaceSoft,
                child: const Icon(
                  Icons.image_outlined,
                  color: ArtistColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              _title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ArtistTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Rating section.
  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How was your experience?',
          style: ArtistTextStyles.title.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a star to rate this product.',
          style: ArtistTextStyles.caption,
        ),
        const SizedBox(height: 14),
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
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedScale(
                    scale: selected ? 1.08 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      selected
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 42,
                      color: selected
                          ? ArtistColors.warning
                          : ArtistColors.textMuted,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 7),
        Center(
          child: Text(
            _rating == 0 ? 'Select your rating' : _ratingLabel,
            style: ArtistTextStyles.bodyMedium.copyWith(
              color: ArtistColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // Rating label.
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

  // Review section.
  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us more',
          style: ArtistTextStyles.title.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          'Your review can help another person make a better choice.',
          style: ArtistTextStyles.caption,
        ),
        const SizedBox(height: 11),
        TextField(
          controller: _reviewController,
          maxLines: 6,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          style: ArtistTextStyles.body.copyWith(
            color: ArtistColors.textPrimary,
          ),
          cursorColor: ArtistColors.primary,
          decoration: InputDecoration(
            hintText: 'What did you like? How was the condition?',
            hintStyle: ArtistTextStyles.hint.copyWith(
              color: ArtistColors.textMuted,
            ),
            filled: true,
            fillColor: ArtistColors.surface,
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.all(15),
            counterStyle: ArtistTextStyles.small,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: ArtistColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: ArtistColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: ArtistColors.primary,
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Recommendation section.
  Widget _buildRecommendationSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: ArtistColors.surfaceSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.thumb_up_alt_outlined,
              color: ArtistColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Would you recommend it?',
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Help us understand your experience.',
                  style: ArtistTextStyles.small,
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _wouldRecommend,
            activeColor: ArtistColors.primary,
            activeTrackColor: ArtistColors.primary.withValues(alpha: 0.35),
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

  // Submit button.
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: ArtistColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ArtistColors.primary.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text('Submit Review', style: ArtistTextStyles.button),
      ),
    );
  }

  // Submit review.
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

  // Show message.
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
