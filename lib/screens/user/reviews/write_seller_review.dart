import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
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
  final _comment = TextEditingController();
  int _rating = 0;
  bool _saving = false;
  String? _error;

  bool get _canSubmit =>
      _rating > 0 && _comment.text.trim().length >= 5 && !_saving;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.sellerId.trim().isEmpty || widget.orderId.trim().isEmpty) {
      setState(
        () => _error =
            'Seller and delivered-order details are required. Open this form from an eligible order.',
      );
      return;
    }
    if (!_canSubmit) {
      setState(
        () => _error = 'Choose a rating and write at least 5 characters.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await EcoLoopApi.instance.post('/reviews/seller', {
        'sellerId': int.tryParse(widget.sellerId) ?? widget.sellerId,
        'sellerType': widget.sellerType.toLowerCase(),
        'orderId': int.tryParse(widget.orderId) ?? widget.orderId,
        'rating': _rating,
        'comment': _comment.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(() {
          _saving = false;
          _error = e.toString();
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('Review seller'),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.light,
                backgroundImage:
                    (widget.sellerImage?.trim().isNotEmpty ?? false)
                    ? NetworkImage(widget.sellerImage!)
                    : null,
                child: (widget.sellerImage?.trim().isNotEmpty ?? false)
                    ? null
                    : const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.sellerName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Rate your experience with this seller',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => IconButton(
              onPressed: () => setState(() => _rating = i + 1),
              icon: Icon(
                i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
          ),
        ),
        TextField(
          controller: _comment,
          minLines: 5,
          maxLines: 8,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Your experience',
            hintText: 'Write an honest seller review',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _canSubmit ? _submit : null,
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
  );
}
