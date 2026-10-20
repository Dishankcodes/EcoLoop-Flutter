import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../buy_products/seller_profile.dart';
import '../profile/artist_profile.dart';

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
  final EcoLoopApi _api = EcoLoopApi.instance;
  final TextEditingController _comment = TextEditingController();
  int _rating = 0;
  bool _saving = false;

  String get _normalisedSellerType => widget.sellerType
      .trim()
      .toLowerCase()
      .replaceAll('-', '_')
      .replaceAll(' ', '_');

  bool get _isArtist =>
      _normalisedSellerType == 'artist' ||
      _normalisedSellerType == 'remaker' ||
      _normalisedSellerType == 're_maker';

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  /// Opens the correct profile page based on the order's seller type.
  void _openSellerProfile() {
    final sellerId = widget.sellerId.trim();
    if (sellerId.isEmpty ||
        sellerId == '0' ||
        sellerId.toLowerCase() == 'null') {
      _showMessage(
        'Seller profile is unavailable because the seller ID is missing.',
      );
      return;
    }

    final image = (widget.sellerImage ?? '').trim();
    final profile = <String, dynamic>{
      'id': sellerId,
      'userId': sellerId,
      'sellerId': sellerId,
      'artistId': sellerId,
      'sellerType': _isArtist ? 'artist' : 'user',
      'role': _isArtist ? 'artist' : 'user',
      'name': widget.sellerName,
      'userName': widget.sellerName,
      'sellerName': widget.sellerName,
      'firstName': widget.sellerName,
      'profilePhotoUrl': image,
      'profileImage': image,
      'image': image,
    };

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _isArtist
            ? ArtistProfile(artist: profile)
            : SellerProfile(seller: profile),
      ),
    );
  }

  Future<void> _submit() async {
    final sellerId = int.tryParse(widget.sellerId.trim());
    final orderId = int.tryParse(widget.orderId.trim());
    final comment = _comment.text.trim();

    if (_rating < 1 ||
        comment.length < 5 ||
        comment.length > 500 ||
        sellerId == null ||
        orderId == null) {
      _showMessage('Choose a rating and write between 5 and 500 characters.');
      return;
    }

    setState(() => _saving = true);
    try {
      final result = _isArtist
          ? await _api.post('/reviews/artist', {
              'artistId': sellerId,
              'orderId': orderId,
              'rating': _rating,
              'comment': comment,
            })
          : await _api.post('/reviews/seller', {
              'sellerId': sellerId,
              'sellerType': 'user',
              'orderId': orderId,
              'reviewType': 'seller',
              'rating': _rating,
              'comment': comment,
            });

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
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
        'Write ${_isArtist ? 'Artist' : 'Seller'} Review',
        style: ArtistTextStyles.title,
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Tapping this card opens the seller or artist profile.
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _openSellerProfile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
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
                    backgroundImage: _validNetworkImage(widget.sellerImage)
                        ? NetworkImage(widget.sellerImage!.trim())
                        : null,
                    onBackgroundImageError:
                        _validNetworkImage(widget.sellerImage)
                        ? (_, __) {}
                        : null,
                    child: _validNetworkImage(widget.sellerImage)
                        ? null
                        : const Icon(
                            Icons.person_outline,
                            color: ArtistColors.primary,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ArtistTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'View ${_isArtist ? 'artist' : 'seller'} profile',
                          style: ArtistTextStyles.small.copyWith(
                            color: ArtistColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: ArtistColors.textSecondary,
                  ),
                ],
              ),
            ),
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
            (index) => IconButton(
              onPressed: _saving
                  ? null
                  : () => setState(() => _rating = index + 1),
              iconSize: 38,
              icon: Icon(
                index < _rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: ArtistColors.warning,
              ),
            ),
          ),
        ),
        Center(
          child: Text(
            _rating == 0 ? 'Select your rating' : '$_rating out of 5 stars',
            style: ArtistTextStyles.bodyMedium.copyWith(
              color: ArtistColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _comment,
          minLines: 4,
          maxLines: 7,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Submit Review'),
          ),
        ),
      ],
    ),
  );

  bool _validNetworkImage(String? value) {
    final raw = (value ?? '').trim();
    final uri = Uri.tryParse(raw);
    return uri != null &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
