import 'package:flutter/material.dart';
import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'rating_summary.dart';
import 'write_review.dart';

class ProductReviews extends StatefulWidget {
  final Map<String, dynamic> product;
  /// Required for submitting a review; must be the delivered order containing this product.
  final String? orderId;
  const ProductReviews({super.key, required this.product, this.orderId});
  @override
  State<ProductReviews> createState() => _ProductReviewsState();
}

class _ProductReviewsState extends State<ProductReviews> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reviews = [];
  String _filter = 'All';
  String _sort = 'Newest';

  int _int(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
  double _double(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  String get _id => '${widget.product['productId'] ?? widget.product['id'] ?? ''}';
  String get _title => '${widget.product['title'] ?? widget.product['name'] ?? 'Product'}';
  String get _image {
    final images = widget.product['imageUrls'] ?? widget.product['images'];
    if (images is List && images.isNotEmpty) return '${images.first}';
    return '${widget.product['imageUrl'] ?? widget.product['image'] ?? ''}';
  }
  double get _average => _reviews.isEmpty ? 0 : _reviews.fold<double>(0, (sum, r) => sum + _double(r['rating'])) / _reviews.length;
  Map<int, int> get _counts => {for (var n = 1; n <= 5; n++) n: _reviews.where((r) => _int(r['rating']) == n).length};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_id.isEmpty) throw Exception('This product has no valid product ID.');
      final data = await EcoLoopApi.instance.get('/products/$_id/reviews');
      final rows = data is List ? data : (data is Map && data['reviews'] is List ? data['reviews'] as List : <dynamic>[]);
      if (!mounted) return;
      setState(() { _reviews = rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(); _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _visible {
    var rows = List<Map<String, dynamic>>.from(_reviews);
    if (_filter != 'All') {
      if (_filter == 'With Photos') {
        rows = rows.where((r) => (r['photos'] is List && (r['photos'] as List).isNotEmpty)).toList();
      } else {
        final star = int.tryParse(_filter[0]) ?? 0;
        rows = rows.where((r) => _int(r['rating']) == star).toList();
      }
    }
    rows.sort((a,b) {
      final ad = DateTime.tryParse('${a['createdAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = DateTime.tryParse('${b['createdAt'] ?? ''}') ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (_sort == 'Highest Rating') return _int(b['rating']).compareTo(_int(a['rating']));
      if (_sort == 'Lowest Rating') return _int(a['rating']).compareTo(_int(b['rating']));
      return bd.compareTo(ad);
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Product Reviews'), backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary, elevation: 0),
    body: RefreshIndicator(onRefresh: _load, child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _productCard(),
        const SizedBox(height: 14),
        RatingSummary(rating: _average, totalReviews: _reviews.length, ratingCounts: _counts),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: widget.orderId == null || widget.orderId!.isEmpty ? null : () async {
            final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => WriteReview(product: widget.product, orderId: widget.orderId!)));
            if (result == true) _load();
          },
          icon: const Icon(Icons.rate_review_outlined), label: const Text('Write a review'),
        )),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: ['All','5 Star','4 Star','3 Star','2 Star','1 Star'].map((f) => ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f))).toList()),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _sort,
          decoration: const InputDecoration(labelText: 'Sort reviews', border: OutlineInputBorder()),
          items: const [DropdownMenuItem(value:'Newest',child:Text('Newest')),DropdownMenuItem(value:'Highest Rating',child:Text('Highest Rating')),DropdownMenuItem(value:'Lowest Rating',child:Text('Lowest Rating'))],
          onChanged: (v) { if (v != null) setState(() => _sort = v); },
        ),
        const SizedBox(height: 12),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()))
        else if (_error != null) _message(_error!, action: _load)
        else if (_visible.isEmpty) _message('No reviews have been submitted for this product yet.')
        else ..._visible.map(_reviewCard),
      ],
    )),
  );

  Widget _productCard() => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 68, height: 68, child: _image.isEmpty
        ? const ColoredBox(color: AppColors.light, child: Icon(Icons.image_outlined))
        : Image.network(_image, fit: BoxFit.cover, errorBuilder: (_,__,___) => const ColoredBox(color: AppColors.light, child: Icon(Icons.image_not_supported_outlined))))),
      const SizedBox(width: 12),
      Expanded(child: Text(_title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
    ]),
  );

  Widget _reviewCard(Map<String,dynamic> r) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(15)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('${r['reviewerName'] ?? r['name'] ?? 'EcoLoop user'}', style: const TextStyle(fontWeight: FontWeight.w700))), Text('${_int(r['rating'])} ★', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))]),
      const SizedBox(height: 5),
      Text('${r['createdAt'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 8),
      Text('${r['comment'] ?? ''}'),
    ]),
  );

  Widget _message(String text, {Future<void> Function()? action}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(children: [const Icon(Icons.rate_review_outlined, size: 34, color: AppColors.textSecondary), const SizedBox(height: 8), Text(text, textAlign: TextAlign.center), if (action != null) TextButton(onPressed: action, child: const Text('Try again'))]),
  );
}
