import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../widgets/back_button.dart';

class Portfolio extends StatefulWidget {
  const Portfolio({super.key});

  @override
  State<Portfolio> createState() => _PortfolioState();
}

class _PortfolioState extends State<Portfolio> {
  // DEMO PORTFOLIO DATA

  //
  // These objects are intentionally kept in one place so that
  // later they can be replaced directly with API data.
  //
  // Expected backend structure can eventually be:
  //
  // {
  //   id,
  //   title,
  //   description,
  //   category,
  //   image,
  //   images,
  //   featured,
  //   createdAt
  // }

  final List<Map<String, dynamic>> _portfolioItems = [
    {
      'id': 1,
      'title': 'Reclaimed Wood Coffee Table',
      'description':
          'A handcrafted coffee table created from reclaimed wood, '
          'designed to give discarded material a new purpose.',
      'category': 'Furniture',
      'image':
          'https://images.unsplash.com/photo-1533090481720-856c6e3c1fdc'
          '?auto=format&fit=crop&w=1200&q=85',
      'featured': true,
      'likes': 84,
      'views': 312,
    },
    {
      'id': 2,
      'title': 'Upcycled Wall Decor',
      'description':
          'A decorative wall piece made using reclaimed materials '
          'and hand-finished detailing.',
      'category': 'Home Decor',
      'image':
          'https://images.unsplash.com/photo-1549490349-8643362247b5'
          '?auto=format&fit=crop&w=1200&q=85',
      'featured': true,
      'likes': 61,
      'views': 248,
    },
    {
      'id': 3,
      'title': 'Recycled Wooden Organizer',
      'description':
          'Functional desk storage made from leftover wood pieces '
          'collected from previous projects.',
      'category': 'Utility',
      'image':
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7'
          '?auto=format&fit=crop&w=1200&q=85',
      'featured': false,
      'likes': 42,
      'views': 176,
    },
    {
      'id': 4,
      'title': 'Handmade Decorative Shelf',
      'description':
          'A minimalist shelf crafted from reclaimed timber with '
          'a natural finish.',
      'category': 'Furniture',
      'image':
          'https://images.unsplash.com/photo-1594620302200-9a762244a156'
          '?auto=format&fit=crop&w=1200&q=85',
      'featured': false,
      'likes': 37,
      'views': 151,
    },
    {
      'id': 5,
      'title': 'Bottle Upcycling Project',
      'description':
          'Discarded glass bottles transformed into decorative '
          'home accessories.',
      'category': 'Upcycling',
      'image':
          'https://images.unsplash.com/photo-1603006905003-be475563bc59'
          '?auto=format&fit=crop&w=1200&q=85',
      'featured': false,
      'likes': 29,
      'views': 128,
    },
    {
      'id': 6,
      'title': 'Reclaimed Material Art',
      'description':
          'An experimental artwork created using a combination '
          'of discarded and reclaimed materials.',
      'category': 'Art',
      'image':
          'https://images.unsplash.com/photo-1547891654-e66ed7ebb968'
          '?auto=format&fit=crop&w=1200&q=85',
      'featured': false,
      'likes': 51,
      'views': 205,
    },
  ];

  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Furniture',
    'Home Decor',
    'Utility',
    'Upcycling',
    'Art',
  ];

  // BUILD

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedCategory == 'All'
        ? _portfolioItems
        : _portfolioItems
              .where((item) => item['category'].toString() == _selectedCategory)
              .toList();

    final featuredItems = filteredItems
        .where((item) => item['featured'] == true)
        .toList();

    final regularItems = filteredItems
        .where((item) => item['featured'] != true)
        .toList();

    return Scaffold(
      backgroundColor: ArtistColors.background,

      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const AppBackButton(),
        title: Text('Portfolio', style: ArtistTextStyles.title),
        actions: [
          IconButton(
            tooltip: 'More',
            onPressed: _showPortfolioOptions,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: ArtistColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: ArtistColors.primary,
          onRefresh: _refreshPortfolio,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPortfolioHeader(),

                const SizedBox(height: 18),

                _buildPortfolioStats(),

                const SizedBox(height: 24),

                _buildCategorySelector(),

                const SizedBox(height: 24),

                if (featuredItems.isNotEmpty) ...[
                  _buildSectionTitle(
                    title: 'Featured Work',
                    subtitle: 'Your best work at a glance',
                  ),

                  const SizedBox(height: 12),

                  _buildFeaturedSection(featuredItems),

                  const SizedBox(height: 26),
                ],

                _buildSectionTitle(
                  title: 'My Work',
                  subtitle:
                      '${filteredItems.length} portfolio ${filteredItems.length == 1 ? 'item' : 'items'}',
                ),

                const SizedBox(height: 12),

                if (filteredItems.isEmpty)
                  _buildEmptyState()
                else
                  _buildPortfolioGrid(
                    regularItems.isEmpty ? filteredItems : regularItems,
                  ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPortfolioItem,
        backgroundColor: ArtistColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Work'),
      ),
    );
  }

  // HEADER

  Widget _buildPortfolioHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ArtistColors.border),
        boxShadow: [
          BoxShadow(
            color: ArtistColors.primary.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: ArtistColors.light,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.collections_bookmark_outlined,
                  color: ArtistColors.primary,
                  size: 29,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creative Portfolio',
                      style: ArtistTextStyles.title.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Showcase your creativity and give your work a story.',
                      style: ArtistTextStyles.caption.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ArtistColors.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 19,
                  color: ArtistColors.primary,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Add your best projects, creations and upcycling work. '
                    'This portfolio will later be visible to buyers and '
                    'other EcoLoop users.',
                    style: ArtistTextStyles.caption.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STATS

  Widget _buildPortfolioStats() {
    final totalViews = _portfolioItems.fold<int>(
      0,
      (sum, item) => sum + ((item['views'] ?? 0) as int),
    );

    final totalLikes = _portfolioItems.fold<int>(
      0,
      (sum, item) => sum + ((item['likes'] ?? 0) as int),
    );

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.collections_outlined,
            value: '${_portfolioItems.length}',
            label: 'Projects',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _StatCard(
            icon: Icons.visibility_outlined,
            value: _formatCount(totalViews),
            label: 'Views',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _StatCard(
            icon: Icons.favorite_border_rounded,
            value: _formatCount(totalLikes),
            label: 'Likes',
          ),
        ),
      ],
    );
  }

  // CATEGORY SELECTOR

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? ArtistColors.primary : ArtistColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? ArtistColors.primary : ArtistColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: ArtistTextStyles.caption.copyWith(
                  color: selected ? Colors.white : ArtistColors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // SECTION TITLE

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ArtistTextStyles.title.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(subtitle, style: ArtistTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }

  // FEATURED

  Widget _buildFeaturedSection(List<Map<String, dynamic>> items) {
    return SizedBox(
      height: 265,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildFeaturedCard(items[index]);
        },
      ),
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _openPortfolioDetails(item),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ArtistColors.border),
          boxShadow: [
            BoxShadow(
              color: ArtistColors.primary.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildNetworkImage(
                  item['image'].toString(),
                  height: 155,
                  width: double.infinity,
                ),

                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ArtistColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    item['category'].toString(),
                    style: ArtistTextStyles.caption.copyWith(
                      color: ArtistColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // GRID

  Widget _buildPortfolioGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        return _buildPortfolioCard(items[index]);
      },
    );
  }

  Widget _buildPortfolioCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _openPortfolioDetails(item),
      child: Container(
        decoration: BoxDecoration(
          color: ArtistColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: ArtistColors.border),
          boxShadow: [
            BoxShadow(
              color: ArtistColors.primary.withOpacity(0.035),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _buildNetworkImage(item['image'].toString()),
                  ),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _showItemOptions(item),
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    item['category'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ArtistTextStyles.caption.copyWith(
                      color: ArtistColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_border_rounded,
                        size: 14,
                        color: ArtistColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Text(
                        '${item['likes']}',
                        style: ArtistTextStyles.caption.copyWith(fontSize: 10),
                      ),

                      const SizedBox(width: 10),

                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: ArtistColors.textSecondary,
                      ),

                      const SizedBox(width: 3),

                      Text(
                        '${item['views']}',
                        style: ArtistTextStyles.caption.copyWith(fontSize: 10),
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
  }

  // EMPTY STATE

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 45),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: ArtistColors.light,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.collections_outlined,
              size: 31,
              color: ArtistColors.primary,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            'No work in this category',
            style: ArtistTextStyles.title.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Try another category or add a new project to your portfolio.',
            textAlign: TextAlign.center,
            style: ArtistTextStyles.caption.copyWith(height: 1.45),
          ),

          const SizedBox(height: 18),

          OutlinedButton.icon(
            onPressed: _addPortfolioItem,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Work'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ArtistColors.primary,
              side: const BorderSide(color: ArtistColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NETWORK IMAGE

  Widget _buildNetworkImage(String url, {double? width, double? height}) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: ArtistColors.light,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ArtistColors.primary,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: ArtistColors.light,
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: ArtistColors.primary,
              size: 32,
            ),
          ),
        );
      },
    );
  }

  // PORTFOLIO DETAILS

  void _openPortfolioDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _PortfolioDetailsSheet(
          item: item,
          onEdit: () {
            Navigator.pop(context);
            _editPortfolioItem(item);
          },
          onDelete: () {
            Navigator.pop(context);
            _deletePortfolioItem(item);
          },
        );
      },
    );
  }

  // ADD

  void _addPortfolioItem() {
    _showComingSoon(
      'Add Portfolio Work',
      'The portfolio editor UI will be connected to the backend next.',
    );
  }

  // EDIT

  void _editPortfolioItem(Map<String, dynamic> item) {
    _showComingSoon(
      'Edit Portfolio Work',
      'Editing will be connected to the portfolio API next.',
    );
  }

  // DELETE

  void _deletePortfolioItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: ArtistColors.surface,
          title: Text(
            'Delete Work?',
            style: ArtistTextStyles.title.copyWith(fontSize: 18),
          ),
          content: Text(
            'Are you sure you want to remove '
            '"${item['title']}" from your portfolio?',
            style: ArtistTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  _portfolioItems.removeWhere(
                    (element) => element['id'] == item['id'],
                  );
                });

                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(content: Text('Portfolio work removed.')),
                  );
              },
              child: Text(
                'Delete',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ITEM OPTIONS

  void _showItemOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ArtistColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: ArtistColors.primary,
                  ),
                  title: const Text('Edit Work'),
                  onTap: () {
                    Navigator.pop(context);
                    _editPortfolioItem(item);
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.star_outline_rounded,
                    color: ArtistColors.primary,
                  ),
                  title: Text(
                    item['featured'] == true
                        ? 'Remove from Featured'
                        : 'Mark as Featured',
                  ),
                  onTap: () {
                    Navigator.pop(context);

                    setState(() {
                      item['featured'] = !(item['featured'] == true);
                    });
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: ArtistColors.error,
                  ),
                  title: Text(
                    'Delete Work',
                    style: ArtistTextStyles.bodyMedium.copyWith(
                      color: ArtistColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deletePortfolioItem(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // MORE OPTIONS

  void _showPortfolioOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ArtistColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                ListTile(
                  leading: const Icon(
                    Icons.add_rounded,
                    color: ArtistColors.primary,
                  ),
                  title: const Text('Add New Work'),
                  onTap: () {
                    Navigator.pop(context);
                    _addPortfolioItem();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: ArtistColors.primary,
                  ),
                  title: const Text('About Portfolio'),
                  onTap: () {
                    Navigator.pop(context);
                    _showPortfolioInfo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // PORTFOLIO INFO

  void _showPortfolioInfo() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: ArtistColors.surface,
          title: Text(
            'Your Portfolio',
            style: ArtistTextStyles.title.copyWith(fontSize: 19),
          ),
          content: Text(
            'Your portfolio is your creative identity on EcoLoop. '
            'Use it to showcase your best work, explain your '
            'creative process and help buyers discover what you make.',
            style: ArtistTextStyles.body.copyWith(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Got it',
                style: ArtistTextStyles.bodyMedium.copyWith(
                  color: ArtistColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // REFRESH

  Future<void> _refreshPortfolio() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Portfolio refreshed.')));
  }

  // COMING SOON

  void _showComingSoon(String title, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ArtistColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ArtistColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 22),

                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: ArtistColors.light,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: ArtistColors.primary,
                    size: 28,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  title,
                  style: ArtistTextStyles.title.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: ArtistTextStyles.caption.copyWith(height: 1.45),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtistColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Okay'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // FORMAT COUNT

  String _formatCount(int value) {
    if (value >= 1000) {
      final formatted = (value / 1000).toStringAsFixed(1);

      return '${formatted.endsWith('.0') ? formatted.substring(0, formatted.length - 2) : formatted}K';
    }

    return value.toString();
  }
}

// STAT CARD

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
      decoration: BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ArtistColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: ArtistColors.primary),

          const SizedBox(height: 7),

          Text(
            value,
            style: ArtistTextStyles.title.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 2),

          Text(label, style: ArtistTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

// PORTFOLIO DETAILS SHEET

class _PortfolioDetailsSheet extends StatelessWidget {
  const _PortfolioDetailsSheet({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 650),
      decoration: const BoxDecoration(
        color: ArtistColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                  child: Image.network(
                    item['image'].toString(),
                    width: double.infinity,
                    height: 235,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 235,
                        color: ArtistColors.light,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 42,
                            color: ArtistColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title'].toString(),
                          style: ArtistTextStyles.title.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      if (item['featured'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: ArtistColors.light,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: ArtistColors.primary,
                            size: 17,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Text(
                    item['category'].toString(),
                    style: ArtistTextStyles.caption.copyWith(
                      color: ArtistColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    item['description'].toString(),
                    style: ArtistTextStyles.body.copyWith(height: 1.55),
                  ),

                  const SizedBox(height: 17),

                  Row(
                    children: [
                      _DetailStat(
                        icon: Icons.favorite_border_rounded,
                        value: '${item['likes']}',
                        label: 'Likes',
                      ),

                      const SizedBox(width: 18),

                      _DetailStat(
                        icon: Icons.visibility_outlined,
                        value: '${item['views']}',
                        label: 'Views',
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ArtistColors.primary,
                            side: const BorderSide(color: ArtistColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ArtistColors.error,
                            side: BorderSide(
                              color: ArtistColors.error.withOpacity(0.45),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
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
  }
}

// DETAIL STAT

class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: ArtistColors.textSecondary),

        const SizedBox(width: 5),

        Text(
          value,
          style: ArtistTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(width: 3),

        Text(label, style: ArtistTextStyles.caption),
      ],
    );
  }
}
