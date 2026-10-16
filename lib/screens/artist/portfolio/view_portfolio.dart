import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../widgets/back_button.dart';

/// Public portfolio grid. Use artistId on artist profiles or productId on product details.
class PublicArtistPortfolioPage extends StatefulWidget {
  const PublicArtistPortfolioPage({super.key, this.artistId, this.productId})
    : assert(artistId != null || productId != null);

  final int? artistId;
  final int? productId;

  @override
  State<PublicArtistPortfolioPage> createState() =>
      _PublicArtistPortfolioPageState();
}

class _PublicArtistPortfolioPageState extends State<PublicArtistPortfolioPage> {
  final _api = EcoLoopApi.instance;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final path = widget.productId != null
          ? '/products/${widget.productId}/portfolio'
          : '/artists/${widget.artistId}/portfolio';
      final result = await _api.get(path);
      final list = result is List
          ? result
          : (result is Map ? (result['items'] ?? []) : []);
      if (!mounted) return;
      setState(() {
        _items = list is List
            ? list
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
            : [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ArtistColors.background,
    appBar: AppBar(
      backgroundColor: ArtistColors.background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: const AppBackButton(),
      title: Text(
        widget.productId != null ? 'Product Story' : 'Artist Portfolio',
        style: ArtistTextStyles.title,
      ),
    ),
    body: RefreshIndicator(
      color: ArtistColors.primary,
      onRefresh: _load,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: ArtistColors.primary),
            )
          : _error != null
          ? ListView(
              children: [
                const SizedBox(height: 100),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: ArtistColors.error,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: ArtistTextStyles.body,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                const Icon(
                  Icons.collections_outlined,
                  size: 44,
                  color: ArtistColors.primary,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'No portfolio stories yet',
                    style: ArtistTextStyles.title,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'The artist has not published a story for this view.',
                    style: ArtistTextStyles.caption,
                  ),
                ),
              ],
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
                childAspectRatio: .68,
              ),
              itemBuilder: (context, index) {
                final item = _items[index];
                final image =
                    '${item['afterImageUrl'] ?? item['imageUrl'] ?? ''}';
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicPortfolioDetailPage(
                        portfolioId:
                            int.tryParse('${item['portfolioId']}') ?? 0,
                      ),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ArtistColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ArtistColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: image.isEmpty
                              ? Container(
                                  color: ArtistColors.light,
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: ArtistColors.primary,
                                    ),
                                  ),
                                )
                              : Image.network(
                                  image,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: ArtistColors.light,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: ArtistColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['title'] ?? 'Portfolio work'}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: ArtistTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item['category'] ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ArtistTextStyles.caption.copyWith(
                                  color: ArtistColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.compare_arrows_rounded,
                                    size: 15,
                                    color: ArtistColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Before & after',
                                    style: ArtistTextStyles.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    ),
  );
}

class PublicPortfolioDetailPage extends StatefulWidget {
  const PublicPortfolioDetailPage({super.key, required this.portfolioId});

  final int portfolioId;

  @override
  State<PublicPortfolioDetailPage> createState() =>
      _PublicPortfolioDetailPageState();
}

class _PublicPortfolioDetailPageState extends State<PublicPortfolioDetailPage> {
  final _api = EcoLoopApi.instance;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await _api.get('/portfolio/${widget.portfolioId}');
      if (!mounted) return;
      setState(() {
        _item = value is Map ? Map<String, dynamic>.from(value) : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Widget _image(String title, String url) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ArtistTextStyles.caption.copyWith(
            color: ArtistColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: .82,
            child: url.isEmpty
                ? Container(
                    color: ArtistColors.light,
                    child: const Icon(
                      Icons.image_outlined,
                      color: ArtistColors.primary,
                    ),
                  )
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: ArtistColors.light,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: ArtistColors.primary,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _story(String title, String value, IconData icon) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ArtistColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ArtistTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: ArtistTextStyles.body.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _item ?? {};
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const AppBackButton(),
        title: Text('Project Story', style: ArtistTextStyles.title),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: ArtistColors.primary),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: ArtistTextStyles.body,
                ),
              ),
            )
          : item.isEmpty
          ? Center(
              child: Text(
                'Portfolio work not found',
                style: ArtistTextStyles.body,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
              children: [
                Text(
                  '${item['title'] ?? ''}',
                  style: ArtistTextStyles.title.copyWith(fontSize: 24),
                ),
                if ('${item['caption'] ?? ''}'.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    '${item['caption']}',
                    style: ArtistTextStyles.body.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _image('BEFORE', '${item['beforeImageUrl'] ?? ''}'),
                    const SizedBox(width: 12),
                    _image(
                      'AFTER',
                      '${item['afterImageUrl'] ?? item['imageUrl'] ?? ''}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if ('${item['category'] ?? ''}'.isNotEmpty)
                  Text(
                    '${item['category']}',
                    style: ArtistTextStyles.caption.copyWith(
                      color: ArtistColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${item['description'] ?? ''}',
                  style: ArtistTextStyles.body.copyWith(height: 1.55),
                ),
                _story(
                  'Materials reused',
                  '${item['materialsUsed'] ?? ''}',
                  Icons.recycling_outlined,
                ),
                _story(
                  'Transformation process',
                  '${item['processDescription'] ?? ''}',
                  Icons.handyman_outlined,
                ),
                _story(
                  'Environmental impact',
                  '${item['environmentalImpact'] ?? ''}',
                  Icons.eco_outlined,
                ),
                if (item['artist'] is Map) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Created by',
                    style: ArtistTextStyles.title.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item['artist']['userName'] ?? 'EcoLoop Artist'}',
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ('${item['artist']['bio'] ?? ''}'.isNotEmpty)
                    Text(
                      '${item['artist']['bio']}',
                      style: ArtistTextStyles.body,
                    ),
                ],
              ],
            ),
    );
  }
}
