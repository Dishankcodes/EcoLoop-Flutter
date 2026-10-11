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
  final _comment = TextEditingController();
  int _rating = 0;
  bool _recommend = true;
  bool _saving = false;
  String? _error;
  String get _productId => '${widget.product['productId'] ?? widget.product['id'] ?? ''}';
  String get _title => '${widget.product['title'] ?? widget.product['name'] ?? 'Product'}';
  String get _image {
    final images = widget.product['imageUrls'] ?? widget.product['images'];
    if (images is List && images.isNotEmpty) return '${images.first}';
    return '${widget.product['imageUrl'] ?? widget.product['image'] ?? ''}';
  }
  @override
  void dispose() { _comment.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_productId.isEmpty || (widget.orderId ?? '').trim().isEmpty) { setState(() => _error = 'Product and order information are required. Open this form from a delivered order.'); return; }
    if (_rating < 1) { setState(() => _error = 'Select a star rating.'); return; }
    if (_comment.text.trim().length < 5) { setState(() => _error = 'Please write at least 5 characters.'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      await EcoLoopApi.instance.post('/reviews/product', {
        'productId': int.tryParse(_productId) ?? _productId,
        'orderId': int.tryParse(widget.orderId ?? '') ?? widget.orderId,
        'rating': _rating,
        'comment': _comment.text.trim(),
        'wouldRecommend': _recommend,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Write a review'), backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary, elevation: 0),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)), child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 66, height: 66, child: _image.isEmpty ? const ColoredBox(color: AppColors.light, child: Icon(Icons.image_outlined)) : Image.network(_image, fit: BoxFit.cover, errorBuilder: (_,__,___) => const ColoredBox(color: AppColors.light, child: Icon(Icons.image_outlined))))),
        const SizedBox(width: 12), Expanded(child: Text(_title, style: const TextStyle(fontWeight: FontWeight.w700))),
      ])),
      const SizedBox(height: 24),
      const Text('How was your experience?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
        onPressed: _saving ? null : () => setState(() => _rating = i + 1),
        icon: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 38, color: AppColors.primary),
      ))),
      Center(child: Text(_rating == 0 ? 'Select a rating' : ['', 'Poor', 'Fair', 'Good', 'Very good', 'Excellent'][_rating], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
      const SizedBox(height: 20),
      TextField(controller: _comment, minLines: 4, maxLines: 7, maxLength: 500, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Your review', hintText: 'Share an honest review of this product', border: OutlineInputBorder(), alignLabelWithHint: true)),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: _recommend, onChanged: (v) => setState(() => _recommend = v), title: const Text('Would you recommend this product?')),
      if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
      SizedBox(height: 52, child: ElevatedButton(onPressed: _saving ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit review'))),
    ]),
  );
}
