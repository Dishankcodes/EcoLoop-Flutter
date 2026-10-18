import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';

class WriteReview extends StatefulWidget {
  final Map<String, dynamic> product;
  final String? orderId;

  const WriteReview({super.key, required this.product, this.orderId});

  @override
  State<WriteReview> createState() => _WriteReviewState();
}

class _WriteReviewState extends State<WriteReview> {
  final TextEditingController _comment = TextEditingController();

  int _rating = 0;
  bool _recommend = true;
  bool _saving = false;
  String? _error;

  String get _productId =>
      '${widget.product['productId'] ?? widget.product['id'] ?? ''}'.trim();

  String get _title =>
      '${widget.product['title'] ?? widget.product['productName'] ?? widget.product['productTitle'] ?? widget.product['name'] ?? 'Product'}';

  /// Returns the first usable image URL from the product/order data.
  ///
  /// Supports:
  /// - imageUrls and productImageUrls
  /// - images and productImages
  /// - Lists of image URLs
  /// - JSON-encoded lists stored as Strings
  /// - productImage, productImageUrl, imageUrl and thumbnail
  String get _image {
    final product = widget.product;

    final imageListKeys = <String>[
      'imageUrls',
      'productImageUrls',
      'images',
      'productImages',
    ];

    for (final key in imageListKeys) {
      final dynamic value = product[key];

      if (value is List) {
        for (final item in value) {
          final url = _validImageUrl(item);
          if (url.isNotEmpty) return url;
        }
      } else if (value is String && value.trim().isNotEmpty) {
        final raw = value.trim();

        // Some API responses store imageUrls as a JSON string.
        try {
          final decoded = jsonDecode(raw);

          if (decoded is List) {
            for (final item in decoded) {
              final url = _validImageUrl(item);
              if (url.isNotEmpty) return url;
            }
          } else if (decoded is String) {
            final url = _validImageUrl(decoded);
            if (url.isNotEmpty) return url;
          }
        } catch (_) {
          // The value may be a single image URL rather than JSON.
          final url = _validImageUrl(raw);
          if (url.isNotEmpty) return url;
        }
      }
    }

    // Check individual image fields used by order and product responses.
    final singleImageKeys = <String>[
      'productImage',
      'productImageUrl',
      'imageUrl',
      'image',
      'thumbnail',
      'productPhoto',
      'photoUrl',
    ];

    for (final key in singleImageKeys) {
      final url = _validImageUrl(product[key]);
      if (url.isNotEmpty) return url;
    }

    return '';
  }

  /// Accepts HTTP(S) image URLs only.
  String _validImageUrl(dynamic value) {
    if (value == null) return '';

    final url = value.toString().trim();
    if (url.isEmpty || url.toLowerCase() == 'null') return '';

    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return '';
    }

    return url;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final orderId =
        (widget.orderId ??
                widget.product['reviewOrderId'] ??
                widget.product['orderId'] ??
                '')
            .toString()
            .trim();

    if (_productId.isEmpty || orderId.isEmpty) {
      setState(() {
        _error =
            'Product and order information are required. Open this form from a delivered order.';
      });
      return;
    }

    if (_rating < 1) {
      setState(() => _error = 'Select a star rating.');
      return;
    }

    if (_comment.text.trim().length < 5) {
      setState(() => _error = 'Please write at least 5 characters.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await EcoLoopApi.instance.post('/reviews/product', {
        'productId': int.tryParse(_productId) ?? _productId,
        'orderId': int.tryParse(orderId) ?? orderId,
        'rating': _rating,
        'comment': _comment.text.trim(),
        'wouldRecommend': _recommend,
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _buildProductImage() {
    final imageUrl = _image;

    if (imageUrl.isEmpty) {
      return const ColoredBox(
        color: AppColors.light,
        child: Center(
          child: Icon(Icons.image_outlined, color: AppColors.primary, size: 28),
        ),
      );
    }

    return Image.network(
      imageUrl,
      width: 66,
      height: 66,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: AppColors.light,
        child: Center(
          child: Icon(Icons.image_outlined, color: AppColors.primary, size: 28),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return const ColoredBox(
          color: AppColors.light,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Write a review'),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 66,
                    height: 66,
                    child: _buildProductImage(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'How was your experience?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                        _rating = i + 1;
                        _error = null;
                      }),
                icon: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              _rating == 0
                  ? 'Select a rating'
                  : const [
                      '',
                      'Poor',
                      'Fair',
                      'Good',
                      'Very good',
                      'Excellent',
                    ][_rating],
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _comment,
            minLines: 4,
            maxLines: 7,
            maxLength: 500,
            enabled: !_saving,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Your review',
              hintText: 'Share an honest review of this product',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _recommend,
            onChanged: _saving ? null : (v) => setState(() => _recommend = v),
            title: const Text('Would you recommend this product?'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit review'),
            ),
          ),
        ],
      ),
    ),
  );
}
