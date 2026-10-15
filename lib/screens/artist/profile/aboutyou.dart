import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';

/// Shows the signed-in artist's real customer reviews and rating information.
/// No sample review names, comments, dates, or rating counts are generated here.
class AboutYou extends StatefulWidget {
  const AboutYou({super.key});

  @override
  State<AboutYou> createState() => _AboutYouState();
}

class _AboutYouState extends State<AboutYou> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _reviews = [];

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is List)
      return value.map(_map).where((e) => e.isNotEmpty).toList();
    final map = _map(value);
    for (final key in ['reviews', 'items', 'results', 'data']) {
      final nested = map[key];
      if (nested is List) {
        return nested.map(_map).where((e) => e.isNotEmpty).toList();
      }
    }
    return [];
  }

  String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? fallback : text;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _rating(Map<String, dynamic> review) =>
      _number(review['rating']).round().clamp(0, 5).toInt();

  DateTime? _date(Map<String, dynamic> review) {
    final raw = review['createdAt'] ?? review['date'] ?? review['updatedAt'];
    if (raw == null || raw.toString().trim().isEmpty) return null;
    return DateTime.tryParse(raw.toString());
  }

  String _formatDate(Map<String, dynamic> review) {
    final date = _date(review);
    if (date == null) return 'Date not provided';
    const months = [
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final profile = _map(await _api.get('/profile'));
      final artistId = _text(profile['artistId'] ?? profile['id']);
      if (artistId.isEmpty) {
        throw Exception(
          'The backend did not return an artist ID for this account.',
        );
      }

      final results = await Future.wait<dynamic>([
        _api.get('/artists/$artistId/reviews'),
        _api.get('/artist/analytics'),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _reviews = _list(results[0]);
        _analytics = _map(results[1]);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return _number(_analytics['averageRating']);
    final total = _reviews.fold<int>(0, (sum, review) => sum + _rating(review));
    return total / _reviews.length;
  }

  int _countForRating(int rating) =>
      _reviews.where((review) => _rating(review) == rating).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: ArtistColors.textPrimary,
            size: 23,
          ),
        ),
        title: Text(
          'About You',
          style: ArtistTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh reviews',
            onPressed: _loading ? null : _load,
            icon: const Icon(
              Icons.refresh_rounded,
              color: ArtistColors.textPrimary,
              size: 21,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildError()
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What People Say About You',
                        style: ArtistTextStyles.heading.copyWith(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Customer feedback from reviews stored in EcoLoop.',
                        style: ArtistTextStyles.body.copyWith(
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildArtistProfile(),
                      const SizedBox(height: 16),
                      _buildRatingSummary(),
                      const SizedBox(height: 20),
                      _buildReviewsHeader(),
                      const SizedBox(height: 12),
                      if (_reviews.isEmpty)
                        _buildEmptyReviews()
                      else
                        ..._reviews.map(_buildReviewCard),
                      const SizedBox(height: 2),
                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: ArtistColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: ArtistTextStyles.body.copyWith(height: 1.4),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtistColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistProfile() {
    final name = _text(_profile['userName'], 'Artist');
    final role = _text(_profile['role'], 'artist');
    final photo = _text(_profile['profilePhotoUrl']);
    final rating = _averageRating;
    final ratingCount = _reviews.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ArtistColors.light,
              border: Border.all(
                color: ArtistColors.primary.withOpacity(0.25),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: photo.isEmpty
                ? const Icon(
                    Icons.person_rounded,
                    color: ArtistColors.primary,
                    size: 34,
                  )
                : Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person_rounded,
                      color: ArtistColors.primary,
                      size: 34,
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ArtistTextStyles.title.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  role[0].toUpperCase() + role.substring(1),
                  style: ArtistTextStyles.caption,
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: ArtistColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: ArtistColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '$ratingCount ${ratingCount == 1 ? 'review' : 'reviews'}',
                        overflow: TextOverflow.ellipsis,
                        style: ArtistTextStyles.caption.copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    final rating = _averageRating;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Column(
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: ArtistTextStyles.heading.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: ArtistColors.primary,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Average rating',
                  textAlign: TextAlign.center,
                  style: ArtistTextStyles.caption.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final stars = 5 - index;
                return _ratingBar(stars, _countForRating(stars));
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(int rating, int count) {
    final progress = _reviews.isEmpty ? 0.0 : count / _reviews.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              '$rating',
              style: ArtistTextStyles.caption.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.star_rounded, color: ArtistColors.primary, size: 11),
          const SizedBox(width: 5),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: ArtistColors.surfaceSoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ArtistColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: ArtistTextStyles.caption.copyWith(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Customer Reviews',
            style: ArtistTextStyles.title.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: ArtistColors.light,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '${_reviews.length} ${_reviews.length == 1 ? 'Review' : 'Reviews'}',
            style: ArtistTextStyles.caption.copyWith(
              color: ArtistColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.rate_review_outlined,
            size: 34,
            color: ArtistColors.textMuted,
          ),
          const SizedBox(height: 9),
          Text(
            'No customer reviews yet',
            style: ArtistTextStyles.title.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            'Reviews will appear here after customers submit feedback for your artist profile.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = _rating(review);
    final name = _text(
      review['reviewerName'] ?? review['name'],
      'EcoLoop buyer',
    );
    final comment = _text(review['comment'] ?? review['review']);
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ArtistColors.light,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      color: ArtistColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ArtistTextStyles.bodyMedium.copyWith(
                        color: ArtistColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(review),
                      style: ArtistTextStyles.caption.copyWith(fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: ArtistColors.primary,
                      size: 13,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$rating.0',
                      style: ArtistTextStyles.caption.copyWith(
                        color: ArtistColors.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: ArtistColors.primary,
                size: 16,
              ),
            ),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              comment,
              style: ArtistTextStyles.body.copyWith(
                color: ArtistColors.textPrimary,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ArtistColors.light,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ArtistColors.border.withOpacity(0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: ArtistColors.primary,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'This page displays reviews returned by EcoLoop. If no reviews exist in the backend, the page stays empty instead of showing sample feedback.',
              style: ArtistTextStyles.body.copyWith(
                color: ArtistColors.textPrimary,
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
