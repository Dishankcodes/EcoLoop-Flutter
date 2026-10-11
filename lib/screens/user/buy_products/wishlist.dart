import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../shared_preferences_util.dart';
import 'product_details.dart';

class Wishlist extends StatefulWidget {
  const Wishlist({super.key});

  @override
  State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
  final TextEditingController _searchController = TextEditingController();

  static const String _baseUrl =
      'https://script.google.com/macros/s/AKfycbzvHq06GwL_I8qH2IPyQP36dRlESN62PYF4Ak5WkRE2VjHL5a-tr0Yk_KEtSvU_ZL6IbQ/exec';

  List<Map<String, dynamic>> _wishlistItems = [];
  Map<int, String> _categoryNames = {};

  String _searchQuery = '';
  bool _loading = true;
  bool _refreshing = false;
  bool _removing = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // SESSION
  // ------------------------------------------------------------

  String get _token {
    final role = Prefs.getString('userRole').toLowerCase().trim();

    return (role == 'artist'
            ? Prefs.getString('artistToken')
            : Prefs.getString('authToken'))
        .trim();
  }

  // ------------------------------------------------------------
  // API HELPERS
  // ------------------------------------------------------------

  Dio _createDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        responseType: ResponseType.json,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
  }

  Uri _uri(String path, {Map<String, String>? parameters}) {
    return Uri.parse(
      _baseUrl,
    ).replace(queryParameters: {'path': path, ...?parameters});
  }

  bool _isRedirect(int? status) {
    return status == 301 ||
        status == 302 ||
        status == 303 ||
        status == 307 ||
        status == 308;
  }

  Future<dynamic> _followRedirect(Dio dio, Response<dynamic> response) async {
    if (!_isRedirect(response.statusCode)) {
      return response.data;
    }

    final location = response.headers.value('location');

    if (location == null || location.trim().isEmpty) {
      throw Exception('The server returned a redirect without a URL.');
    }

    final redirectedResponse = await dio.get<dynamic>(
      location,
      options: Options(
        followRedirects: false,
        maxRedirects: 0,
        responseType: ResponseType.json,
      ),
    );

    if (redirectedResponse.statusCode != 200) {
      throw Exception(
        'The backend returned HTTP ${redirectedResponse.statusCode}.',
      );
    }

    return redirectedResponse.data;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is String) {
      try {
        final decoded = jsonDecode(value);

        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Handled by the response validation below.
      }
    }

    return {};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;

    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded;
      } catch (_) {
        // Return an empty result for an invalid list payload.
      }
    }

    return [];
  }

  Map<String, dynamic> _unwrap(dynamic response) {
    final outer = _asMap(response);

    if (outer.isEmpty) {
      throw Exception('The backend returned an invalid response.');
    }

    if (outer['success'] == false) {
      throw Exception(_apiError(outer));
    }

    final data = outer['data'];

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return outer;
  }

  String _apiError(Map<String, dynamic> response) {
    final error = response['error'];

    if (error is Map) {
      final message = error['message']?.toString().trim();

      if (message != null && message.isNotEmpty) return message;
    }

    if (error != null && error.toString().trim().isNotEmpty) {
      return error.toString();
    }

    final message = response['message']?.toString().trim();

    if (message != null && message.isNotEmpty) return message;

    return 'Unable to process the request.';
  }

  String _readError(Object error) {
    if (error is DioException) {
      final response = _asMap(error.response?.data);

      if (response.isNotEmpty) return _apiError(response);

      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return 'Your session may have expired. Please sign in again.';
      }

      if (error.response?.statusCode == 404) {
        return 'The wishlist endpoint was not found. Check your Code.gs deployment.';
      }

      return error.message ?? 'Unable to connect to EcoLoop.';
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<dynamic> _get(
    Dio dio,
    String path, {
    Map<String, String>? parameters,
  }) async {
    final token = _token;

    if (token.isEmpty) {
      throw Exception('Please sign in to view your wishlist.');
    }

    final uri = _uri(path, parameters: {...?parameters, 'token': token});

    final response = await dio.get<dynamic>(
      uri.toString(),
      options: Options(followRedirects: false, maxRedirects: 0),
    );

    return _followRedirect(dio, response);
  }

  Future<dynamic> _post(
    Dio dio,
    String path, {
    required Map<String, dynamic> body,
    String method = 'POST',
  }) async {
    final token = _token;

    if (token.isEmpty) {
      throw Exception('Please sign in to modify your wishlist.');
    }

    final uri = _uri(path);

    // Apps Script web apps support doGet/doPost.
    // _method lets the existing Code.gs router process DELETE.
    final response = await dio.post<dynamic>(
      uri.toString(),
      data: {...body, 'token': token, if (method != 'POST') '_method': method},
      options: Options(followRedirects: false, maxRedirects: 0),
    );

    return _followRedirect(dio, response);
  }

  // ------------------------------------------------------------
  // LOAD REAL DATA
  // ------------------------------------------------------------

  Future<void> _loadWishlist({bool showLoader = true}) async {
    if (_loading && !showLoader && _wishlistItems.isNotEmpty) return;

    if (mounted) {
      setState(() {
        if (showLoader && _wishlistItems.isEmpty) {
          _loading = true;
        } else {
          _refreshing = true;
        }

        _errorMessage = null;
      });
    }

    final dio = _createDio();

    try {
      // These records come from the logged-in user's Wishlist sheet rows.
      final response = await _get(dio, '/wishlist');
      final outer = _asMap(response);

      if (outer['success'] == false) {
        throw Exception(_apiError(outer));
      }

      dynamic data = outer['data'];

      // Support APIs returning a direct list or a wrapped list.
      if (data == null && response is List) {
        data = response;
      }

      if (data is Map) {
        data = data['items'] ?? data['wishlist'] ?? data['products'];
      }

      final rows = _asList(data);

      // Category names are real records from the Categories sheet.
      // If categories fail to load, product data still remains usable.
      try {
        final categoryResponse = await _get(dio, '/categories');
        final categoryOuter = _asMap(categoryResponse);

        if (categoryOuter['success'] == false) {
          throw Exception(_apiError(categoryOuter));
        }

        dynamic categoryData = categoryOuter['data'];

        if (categoryData == null && categoryResponse is List) {
          categoryData = categoryResponse;
        }

        _categoryNames = {};

        for (final entry in _asList(categoryData)) {
          final category = _asMap(entry);
          final id = _toInt(category['categoryId'] ?? category['id']);
          final name = _string(category['name'] ?? category['categoryName']);

          if (id > 0 && name.isNotEmpty) {
            _categoryNames[id] = name;
          }
        }
      } catch (error) {
        debugPrint('Wishlist category lookup failed: $error');
      }

      final items = <Map<String, dynamic>>[];

      for (final entry in rows) {
        final row = _asMap(entry);

        if (row.isEmpty) continue;

        // Code.gs productPublic_ returns productId, title, price,
        // condition, categoryId, imageUrls and availableQuantity.
        final id = _toInt(row['productId'] ?? row['id']);

        if (id <= 0) continue;

        final imageUrls = _readImages(
          row['imageUrls'] ?? row['images'] ?? row['image'],
        );

        final categoryId = _toInt(row['categoryId']);

        final category =
            _categoryNames[categoryId] ??
            _string(row['categoryName'] ?? row['category']);

        // Keep the data fields expected by the existing ProductDetails page.
        // No fake seller names, prices, images, descriptions or locations.
        items.add({
          ...row,
          'id': id,
          'productId': id,
          'title': _string(row['title']),
          'description': _string(row['description']),
          'price': _toNumber(row['price']),
          'condition': _string(row['condition']),
          'categoryId': categoryId,
          'category': category,
          'imageUrls': imageUrls,
          'images': imageUrls,
          'image': imageUrls.isNotEmpty ? imageUrls.first : '',
          'availableQuantity': _toInt(row['availableQuantity']),
          'quantity': _toInt(row['quantity']),
          'views': _toInt(row['views']),
          'wishlistCount': _toInt(row['wishlistCount']),
          'salesCount': _toInt(row['salesCount']),
          'seller': _string(row['sellerName'] ?? row['seller']),
          'location': _formatLocation(row),
        });
      }

      if (!mounted) return;

      setState(() {
        _wishlistItems = items;
        _loading = false;
        _refreshing = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _refreshing = false;
        _errorMessage = _readError(error);
      });
    } finally {
      dio.close(force: true);
    }
  }

  String _string(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  num _toNumber(dynamic value) {
    if (value is num) return value;

    return num.tryParse(value?.toString().replaceAll(',', '').trim() ?? '') ??
        0;
  }

  List<String> _readImages(dynamic value) {
    dynamic decoded = value;

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty) return [];

      try {
        decoded = jsonDecode(text);
      } catch (_) {
        // A single URL can also be returned as a string.
        if (text.startsWith('https://') || text.startsWith('http://')) {
          return [text];
        }

        return [];
      }
    }

    if (decoded is List) {
      return decoded
          .map((item) => item?.toString().trim() ?? '')
          .where(
            (url) => url.startsWith('https://') || url.startsWith('http://'),
          )
          .toList();
    }

    return [];
  }

  String _formatLocation(Map<String, dynamic> product) {
    final directLocation = _string(product['location']);

    if (directLocation.isNotEmpty) return directLocation;

    final city = _string(product['city']);
    final state = _string(product['state']);

    if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
    if (city.isNotEmpty) return city;
    if (state.isNotEmpty) return state;

    return '';
  }

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  List<Map<String, dynamic>> get _filteredItems {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return _wishlistItems;

    return _wishlistItems.where((product) {
      final title = _string(product['title']).toLowerCase();
      final category = _string(product['category']).toLowerCase();
      final seller = _string(product['seller']).toLowerCase();

      return title.contains(query) ||
          category.contains(query) ||
          seller.contains(query);
    }).toList();
  }

  // ------------------------------------------------------------
  // REMOVE SAVED ITEM
  // ------------------------------------------------------------

  Future<void> _removeProduct(Map<String, dynamic> product) async {
    if (_removing) return;

    final productId = _toInt(product['productId'] ?? product['id']);

    if (productId <= 0) {
      _showMessage('This product has an invalid ID.', error: true);
      return;
    }

    setState(() => _removing = true);

    final dio = _createDio();

    try {
      // The Code.gs route expects the product ID, not the wishlist row ID.
      final response = await _post(
        dio,
        '/wishlist/$productId',
        body: const {},
        method: 'DELETE',
      );

      final result = _asMap(response);

      if (result.isNotEmpty && result['success'] == false) {
        throw Exception(_apiError(result));
      }

      if (!mounted) return;

      setState(() {
        _wishlistItems.removeWhere(
          (item) => _toInt(item['productId'] ?? item['id']) == productId,
        );
      });

      _showMessage('Product removed from your wishlist.');
    } catch (error) {
      _showMessage(
        'Could not remove product: ${_readError(error)}',
        error: true,
      );
    } finally {
      dio.close(force: true);

      if (mounted) setState(() => _removing = false);
    }
  }

  // ------------------------------------------------------------
  // CLEAR WISHLIST
  // ------------------------------------------------------------

  Future<void> _confirmClearWishlist() async {
    if (_wishlistItems.isEmpty || _removing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(
          Icons.delete_sweep_outlined,
          color: AppColors.error,
          size: 35,
        ),
        title: const Text('Clear Wishlist?'),
        content: const Text(
          'This removes each saved product from your account. '
          'The products themselves will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Each removal must be persisted to the backend.
    // Never clear the local list without confirming server success.
    final items = List<Map<String, dynamic>>.from(_wishlistItems);

    for (final item in items) {
      if (!mounted) return;
      await _removeProduct(item);
    }

    if (mounted && _wishlistItems.isEmpty) {
      _showMessage('Your wishlist is now empty.');
    }
  }

  // ------------------------------------------------------------
  // PRODUCT DETAILS
  // ------------------------------------------------------------

  Future<void> _openProductDetails(Map<String, dynamic> product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetails(product: product)),
    );

    if (mounted) {
      await _loadWishlist(showLoader: false);
    }
  }

  // ------------------------------------------------------------
  // MESSAGES
  // ------------------------------------------------------------

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Wishlist',
          style: AppTextStyles.title.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_wishlistItems.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'clear') _confirmClearWishlist();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: AppColors.error),
                      SizedBox(width: 12),
                      Text('Clear Wishlist'),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshing
                ? null
                : () => _loadWishlist(showLoader: false),
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null && _wishlistItems.isEmpty) {
      return _buildErrorState();
    }

    if (_wishlistItems.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildHeader(),
        _buildSearch(),
        _buildResultInfo(),
        Expanded(
          child: _filteredItems.isEmpty ? _buildNoSearchResult() : _buildGrid(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved for later',
                  style: AppTextStyles.title.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 3),
                Text(
                  'Your saved products from EcoLoop.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 22,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accent.withOpacity(0.55)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Search saved items...',
            hintStyle: AppTextStyles.hint,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(Icons.close_rounded, size: 19),
                  )
                : null,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildResultInfo() {
    final count = _filteredItems.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Text(
            '$count ${count == 1 ? 'saved item' : 'saved items'}',
            style: AppTextStyles.caption,
          ),
          const Spacer(),
          if (_searchQuery.isNotEmpty)
            Text(
              'Search results',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final items = _filteredItems;

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.64,
      ),
      itemBuilder: (context, index) {
        final product = items[index];

        return _WishlistProductCard(
          product: product,
          onTap: () => _openProductDetails(product),
          onRemove: () => _removeProduct(product),
          removing: _removing,
        );
      },
    );
  }

  Widget _buildNoSearchResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 60,
              color: AppColors.primary,
            ),
            const SizedBox(height: 18),
            Text('No saved items found', style: AppTextStyles.title),
            const SizedBox(height: 7),
            Text(
              'Try another product name, category or seller.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 23),
            Text(
              'Your wishlist is empty',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 9),
            Text(
              'Save products you like while exploring EcoLoop. '
              'They will appear here once added to your wishlist.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Explore Marketplace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 18),
            Text(
              'Could not load wishlist',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Please try again.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadWishlist(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// WISHLIST PRODUCT CARD
// ================================================================

class _WishlistProductCard extends StatelessWidget {
  const _WishlistProductCard({
    required this.product,
    required this.onTap,
    required this.onRemove,
    required this.removing,
  });

  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool removing;

  String _text(dynamic value) => value?.toString().trim() ?? '';

  num _price(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final title = _text(product['title']);
    final condition = _text(product['condition']);
    final category = _text(product['category']);
    final seller = _text(product['seller']);
    final location = _text(product['location']);
    final price = _price(product['price']);

    final rawImage = product['image'];
    final imageUrl = rawImage is String ? rawImage.trim() : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.accent.withOpacity(0.42)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 9,
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
                    child: imageUrl.isEmpty
                        ? _imagePlaceholder()
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;

                              return _imagePlaceholder(loading: true);
                            },
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          ),
                  ),

                  if (condition.isNotEmpty)
                    Positioned(
                      left: 9,
                      top: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          condition,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    right: 9,
                    top: 9,
                    child: Material(
                      color: Colors.white.withOpacity(0.94),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: removing ? null : onRemove,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 18,
                            color: removing
                                ? AppColors.textSecondary
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (category.isNotEmpty)
                    Positioned(
                      left: 9,
                      bottom: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
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
                    title.isEmpty ? 'Untitled product' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}',
                    style: AppTextStyles.title.copyWith(fontSize: 17),
                  ),

                  if (seller.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            seller,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 8.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'View Product',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _imagePlaceholder({bool loading = false}) {
    return Container(
      color: AppColors.light,
      child: Center(
        child: loading
            ? const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              )
            : const Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: AppColors.secondary,
              ),
      ),
    );
  }
}
