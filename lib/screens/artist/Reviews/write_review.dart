import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: ArtistWriteReviewPage(),
));

class ArtistWriteReviewPage extends StatefulWidget {
  const ArtistWriteReviewPage({super.key});

  @override
  State<ArtistWriteReviewPage> createState() => _ArtistWriteReviewPageState();
}

class _ArtistWriteReviewPageState extends State<ArtistWriteReviewPage> {
  // Artist theme
  static const Color primary = Color(0xFFA6533C);
  static const Color primaryDark = Color(0xFF7D3F2F);
  static const Color background = Color(0xFFF9F5F2);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF2D2522);
  static const Color secondaryText = Color(0xFF8A7D77);
  static const Color borderColor = Color(0xFFE8DDD8);

  int selectedRating = 0;

  final TextEditingController reviewController = TextEditingController();

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  void submitReview() {
    if (selectedRating == 0) {
      showMessage('Please select a rating');
      return;
    }

    if (reviewController.text.trim().isEmpty) {
      showMessage('Please write your review');
      return;
    }

    showMessage('Review submitted successfully!');

    reviewController.clear();

    setState(() {
      selectedRating = 0;
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textColor,
          ),
          onPressed: () => showMessage('Back clicked'),
        ),
        title: const Text(
          'Write a Review',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),

      // ---------------- BODY ----------------
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Product section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=300&q=80',
                        width: 78,
                        height: 78,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Wooden Coffee Table',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            '₹2,499',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Purchased product',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Rating title
              const Text(
                'How was your experience?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'Your review helps other users discover quality products and artists.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: secondaryText,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- STAR RATING ----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 22,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Rate this product',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: secondaryText,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                            (index) {
                          final starNumber = index + 1;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedRating = starNumber;
                              });
                            },
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 5),
                              child: Icon(
                                starNumber <= selectedRating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 42,
                                color: primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      selectedRating == 0
                          ? 'Tap a star to rate'
                          : ratingText(selectedRating),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ---------------- REVIEW ----------------
              const Text(
                'Write your review',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                  ),
                ),
                child: TextField(
                  controller: reviewController,
                  maxLines: 6,
                  maxLength: 500,
                  style: const TextStyle(
                    fontSize: 13,
                    color: textColor,
                  ),
                  decoration: const InputDecoration(
                    hintText:
                    'Share your experience with this product...',
                    hintStyle: TextStyle(
                      color: Color(0xFFAAA09B),
                      fontSize: 13,
                    ),
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: secondaryText,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Keep your review honest, respectful and helpful.',
                      style: TextStyle(
                        fontSize: 11,
                        color: secondaryText,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ---------------- SUBMIT BUTTON ----------------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Submit Review',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Cancel
              Center(
                child: TextButton(
                  onPressed: () => showMessage('Review cancelled'),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

  String ratingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Needs Improvement';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}