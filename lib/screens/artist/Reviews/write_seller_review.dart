import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';

class WriteSellerReview extends StatefulWidget {
  final String sellerName;
  final String? sellerImage;
  final String sellerId;
  final String sellerType;
  final String orderId;

  const WriteSellerReview({
    super.key,
    required this.sellerName,
    this.sellerImage,
    required this.sellerId,
    required this.sellerType,
    required this.orderId,
  });

  @override
  State<WriteSellerReview> createState() => _WriteSellerReviewState();
}

class _WriteSellerReviewState extends State<WriteSellerReview> {
  final _api = EcoLoopApi.instance;
  final _comment = TextEditingController();
  int _rating = 0;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final sellerId = int.tryParse(widget.sellerId);
    final orderId = int.tryParse(widget.orderId);
    if (_rating < 1 ||
        _comment.text.trim().length < 5 ||
        _comment.text.trim().length > 500 ||
        sellerId == null ||
        orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a rating and write at least 5 characters.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final sellerType = widget.sellerType.trim().toLowerCase().replaceAll(
        '-',
        '_',
      );
      final artist =
          sellerType == 'artist' ||
          sellerType == 'remaker' ||
          sellerType == 're_maker';
      final result = artist
          ? await _api.post('/reviews/artist', {
              'artistId': sellerId,
              'orderId': orderId,
              'rating': _rating,
              'comment': _comment.text.trim(),
            })
          : await _api.post('/reviews/seller', {
              'sellerId': sellerId,
              'sellerType': 'user',
              'orderId': orderId,
              'reviewType': 'seller',
              'rating': _rating,
              'comment': _comment.text.trim(),
            });
      // Return a bool because callers use the result to refresh review lists.
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ArtistColors.background,
    appBar: AppBar(
      backgroundColor: ArtistColors.background,
      foregroundColor: ArtistColors.textPrimary,
      elevation: 0,
      title: Text(
        'Write ${['artist', 'remaker', 're_maker'].contains(widget.sellerType.trim().toLowerCase().replaceAll('-', '_')) ? 'Artist' : 'Seller'} Review',
        style: ArtistTextStyles.title,
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ArtistColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ArtistColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: ArtistColors.light,
                backgroundImage:
                    (widget.sellerImage?.startsWith('http') ?? false)
                    ? NetworkImage(widget.sellerImage!)
                    : null,
                onBackgroundImageError:
                    (widget.sellerImage?.startsWith('http') ?? false)
                    ? (_, __) {}
                    : null,
                child: (widget.sellerImage?.startsWith('http') ?? false)
                    ? null
                    : const Icon(
                        Icons.person_outline,
                        color: ArtistColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.sellerName,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'How was your experience?',
          style: ArtistTextStyles.title.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => IconButton(
              onPressed: _saving ? null : () => setState(() => _rating = i + 1),
              iconSize: 38,
              icon: Icon(
                i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: ArtistColors.warning,
              ),
            ),
          ),
        ),
        TextField(
          controller: _comment,
          minLines: 4,
          maxLines: 7,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Share your experience with this seller/artist...',
            filled: true,
            fillColor: ArtistColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: ArtistColors.primary,
              foregroundColor: Colors.white,
            ),
            child: _saving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Review'),
          ),
        ),
      ],
    ),
  );
}
