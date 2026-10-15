import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';

class ReviewHistory extends StatefulWidget {
  const ReviewHistory({super.key});

  @override
  State<ReviewHistory> createState() => _ReviewHistoryState();
}

class _ReviewHistoryState extends State<ReviewHistory> {
  final EcoLoopApi _api = EcoLoopApi.instance;

  int _tab = 0;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reviews = <Map<String, dynamic>>[];
  final Set<String> _deletingIds = <String>{};

  int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  String _string(dynamic value) => (value ?? '').toString().trim();

  String _reviewId(Map<String, dynamic> review) =>
      _string(review['reviewId'] ?? review['review_id'] ?? review['id']);

  bool _isSellerReview(Map<String, dynamic> review) {
    final type = _string(
      review['reviewType'] ?? review['review_type'],
    ).toLowerCase();
    if (type == 'seller' || type == 'artist') return true;
    final sellerId = _string(review['sellerId'] ?? review['seller_id']);
    final artistId = _string(review['artistId'] ?? review['artist_id']);
    final productId = _string(review['productId'] ?? review['product_id']);
    return (sellerId.isNotEmpty || artistId.isNotEmpty) && productId.isEmpty;
  }

  List<Map<String, dynamic>> get _visibleReviews {
    final result = _reviews
        .where(
          (review) =>
              _tab == 0 ? !_isSellerReview(review) : _isSellerReview(review),
        )
        .toList();
    result.sort((a, b) {
      final dateA = DateTime.tryParse(
        _string(a['createdAt'] ?? a['created_at']),
      );
      final dateB = DateTime.tryParse(
        _string(b['createdAt'] ?? b['created_at']),
      );
      return (dateB ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        dateA ?? DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
    return result;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final dynamic data = await _api.get('/my/reviews');
      final dynamic rows = data is List
          ? data
          : data is Map
          ? (data['reviews'] ??
                data['items'] ??
                data['data'] ??
                const <dynamic>[])
          : const <dynamic>[];
      if (!mounted) return;
      setState(() {
        _reviews = rows is List
            ? rows
                  .whereType<Map>()
                  .map((row) => Map<String, dynamic>.from(row))
                  .toList()
            : <Map<String, dynamic>>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> review) async {
    final id = _reviewId(review);
    if (id.isEmpty || _deletingIds.contains(id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete review?'),
        content: const Text(
          'This review will be removed from your review history and no longer appear publicly. This action cannot be undone from the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete review'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _deletingIds.add(id));
    try {
      await _api.delete('/reviews/$id');
      if (!mounted) return;
      setState(() {
        _reviews.removeWhere((item) => _reviewId(item) == id);
        _deletingIds.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review deleted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _deletingIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _dateLabel(dynamic value) {
    final parsed = DateTime.tryParse(_string(value));
    if (parsed == null) return 'Date unavailable';
    final local = parsed.toLocal();
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _visibleReviews;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Reviews'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 16),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 1.2),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  _tabButton(label: 'Products', index: 0),
                  _tabButton(label: 'Sellers', index: 1),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _loading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 140),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _error != null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                      children: [
                        const Icon(
                          Icons.rate_review_outlined,
                          size: 42,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _load,
                            child: const Text('Try again'),
                          ),
                        ),
                      ],
                    )
                  : reviews.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                      children: [
                        const Icon(
                          Icons.rate_review_outlined,
                          size: 44,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _tab == 0
                              ? 'You haven’t written any product reviews yet.'
                              : 'You haven’t written any seller reviews yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Reviews you submit will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _reviewCard(reviews[index]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({required String label, required int index}) {
    final selected = _tab == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 18, color: Colors.white),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> review) {
    final sellerReview = _isSellerReview(review);
    final title = sellerReview
        ? (_string(review['sellerName']).isNotEmpty
              ? _string(review['sellerName'])
              : 'Seller')
        : (_string(review['productTitle']).isNotEmpty
              ? _string(review['productTitle'])
              : 'Product');
    final comment = _string(review['comment']);
    final id = _reviewId(review);
    final deleting = _deletingIds.contains(id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  sellerReview
                      ? Icons.storefront_outlined
                      : Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${sellerReview ? 'Seller review' : 'Product review'} • ${_dateLabel(review['createdAt'] ?? review['created_at'])}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D8),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _int(review['rating']).toString(),
                      style: const TextStyle(
                        color: Color(0xFF855B00),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF4B400),
                      size: 17,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              comment,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE7EAE5)),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: deleting ? null : () => _confirmDelete(review),
              icon: deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(deleting ? 'Deleting…' : 'Delete review'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
