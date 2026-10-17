import 'package:flutter/material.dart';
import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';

class WriteReview extends StatefulWidget {
  final Map<String, dynamic> product;
  final int? orderId;
  final int? existingReviewId;
  final int? initialRating;
  final String? initialComment;

  const WriteReview({
    super.key,
    required this.product,
    this.orderId,
    this.existingReviewId,
    this.initialRating,
    this.initialComment,
  });

  @override
  State<WriteReview> createState() => _WriteReviewState();
}

class _WriteReviewState extends State<WriteReview> {
  final _api = EcoLoopApi.instance;
  late final TextEditingController _comment;
  int _rating = 0;
  int? _orderId;
  bool _loadingEligibility = false;
  bool _submitting = false;
  String? _error;

  int get _productId =>
      _int(widget.product['productId'] ?? widget.product['id']);
  String get _title => _str(
    widget.product['title'] ?? widget.product['name'],
    fallback: 'Product',
  );
  String get _image {
    final images = widget.product['images'] ?? widget.product['imageUrls'];
    if (images is List && images.isNotEmpty) return images.first.toString();
    return _str(
      widget.product['image'] ??
          widget.product['imageUrl'] ??
          widget.product['productImage'],
    );
  }

  @override
  void initState() {
    super.initState();
    _comment = TextEditingController(text: widget.initialComment ?? '');
    _rating = widget.initialRating ?? 0;
    _orderId = widget.orderId;
    if (widget.existingReviewId == null && _orderId == null) _loadEligibility();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _loadEligibility() async {
    if (_productId <= 0) {
      setState(() => _error = 'This product has no valid ID.');
      return;
    }
    setState(() {
      _loadingEligibility = true;
      _error = null;
    });
    try {
      final raw = await _api.get('/products/$_productId/review-eligibility');
      final data = _map(raw);
      if (data['eligible'] == true ||
          data['eligible'].toString().toLowerCase() == 'true') {
        _orderId = _int(data['orderId']);
      } else {
        _error = _str(
          data['reason'],
          fallback:
              'A delivered and paid order is required to review this product.',
        );
      }
    } catch (e) {
      _error = _cleanError(e);
    }
    if (mounted) setState(() => _loadingEligibility = false);
  }

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5) {
      _message('Please select a rating.');
      return;
    }
    final comment = _comment.text.trim();
    if (comment.length < 5 || comment.length > 500) {
      _message('Write between 5 and 500 characters.');
      return;
    }
    if (widget.existingReviewId == null &&
        (_orderId == null || _orderId! <= 0)) {
      _message('A qualifying delivered order was not found.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final payload = <String, dynamic>{'rating': _rating, 'comment': comment};
      dynamic saved;
      if (widget.existingReviewId != null) {
        saved = await _api.put('/reviews/${widget.existingReviewId}', payload);
      } else {
        payload.addAll({'productId': _productId, 'orderId': _orderId});
        saved = await _api.post('/reviews/product', payload);
      }
      if (!mounted) return;
      Navigator.pop(context, _map(saved));
    } catch (e) {
      if (mounted) _message(_cleanError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) {
    final editing = widget.existingReviewId != null;
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ArtistColors.textPrimary,
        title: Text(
          editing ? 'Edit Review' : 'Write Review',
          style: ArtistTextStyles.title,
        ),
      ),
      body: SafeArea(
        child: _loadingEligibility
            ? const Center(
                child: CircularProgressIndicator(color: ArtistColors.primary),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _productCard(),
                  const SizedBox(height: 22),
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
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _rating = i + 1),
                        iconSize: 38,
                        icon: Icon(
                          i < _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: i < _rating
                              ? ArtistColors.warning
                              : ArtistColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      _rating == 0
                          ? 'Select your rating'
                          : '$_rating out of 5 stars',
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: ArtistColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your review',
                    style: ArtistTextStyles.title.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _comment,
                    maxLines: 6,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Share an honest review of this product',
                      filled: true,
                      fillColor: ArtistColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: ArtistColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: ArtistColors.border),
                      ),
                    ),
                  ),
                  if (_error != null && !editing) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ArtistColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ArtistColors.border),
                      ),
                      child: Text(
                        _error!,
                        style: ArtistTextStyles.body.copyWith(
                          color: ArtistColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting || (_error != null && !editing)
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArtistColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              editing ? 'Save Changes' : 'Submit Review',
                              style: ArtistTextStyles.button,
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _productCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ArtistColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ArtistColors.border),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 68,
            height: 68,
            child: _image.isEmpty
                ? const Icon(Icons.image_outlined, color: ArtistColors.primary)
                : Image.network(
                    _image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_outlined,
                      color: ArtistColors.primary,
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
            style: ArtistTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

Map<String, dynamic> _map(dynamic v) => v is Map<String, dynamic>
    ? v
    : v is Map
    ? v.map((k, value) => MapEntry(k.toString(), value))
    : <String, dynamic>{};
int _int(dynamic v) =>
    v is num ? v.toInt() : int.tryParse((v ?? '').toString()) ?? 0;
String _str(dynamic v, {String fallback = ''}) {
  final s = (v ?? '').toString().trim();
  return s.isEmpty ? fallback : s;
}

String _cleanError(Object e) => e.toString().replaceFirst('Exception: ', '');
