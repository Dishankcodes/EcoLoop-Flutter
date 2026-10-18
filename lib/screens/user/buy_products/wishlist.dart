import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'product_details.dart';

class Wishlist extends StatefulWidget {
const Wishlist({super.key});

@override
State<Wishlist> createState() => _WishlistState();
}

class _WishlistState extends State<Wishlist> {
final EcoLoopApi _api = EcoLoopApi.instance;
final TextEditingController _searchController = TextEditingController();

bool _loading = true;
bool _refreshing = false;
String? _error;

final Set<String> _removingIds = <String>{};

String _sortBy = 'Recently saved';

List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];

// -------------------- FILTER AND SORT --------------------

List<Map<String, dynamic>> get _visibleItems {
final query = _searchController.text.trim().toLowerCase();

final result = _items.where((item) {
if (query.isEmpty) return true;

final title = _text(
item,
['title', 'name', 'productName', 'product_name'],
).toLowerCase();

final category = _text(
item,
['category', 'categoryName', 'category_name'],
).toLowerCase();

final seller = _text(
item,
['sellerName', 'seller_name', 'seller', 'artistName', 'userName'],
).toLowerCase();

return title.contains(query) ||
category.contains(query) ||
seller.contains(query);
}).toList();

if (_sortBy == 'Price: low to high') {
result.sort(
(a, b) => (_price(a) ?? double.infinity).compareTo(
_price(b) ?? double.infinity,
),
);
} else if (_sortBy == 'Price: high to low') {
result.sort(
(a, b) => (_price(b) ?? -1).compareTo(_price(a) ?? -1),
);
} else if (_sortBy == 'Name: A–Z') {
result.sort(
(a, b) => _text(a, ['title', 'name'])
    .toLowerCase()
    .compareTo(_text(b, ['title', 'name']).toLowerCase()),
);
}

return result;
}

// -------------------- DATA HELPERS --------------------

Map<String, dynamic> _map(dynamic value) {
if (value is Map<String, dynamic>) return value;

if (value is Map) {
return value.map(
(key, value) => MapEntry(key.toString(), value),
);
}

return <String, dynamic>{};
}

List<Map<String, dynamic>> _rows(dynamic response) {
if (response is List) {
return response
    .map(_map)
    .where((row) => row.isNotEmpty)
    .toList();
}

final root = _map(response);
final data = _map(root['data']);

for (final key in <String>[
'items',
'products',
'wishlist',
'results',
]) {
final value = root[key] ?? data[key];

if (value is List) {
return value
    .map(_map)
    .where((row) => row.isNotEmpty)
    .toList();
}
}

return <Map<String, dynamic>>[];
}

String _productId(Map<String, dynamic> product) {
final nested = _map(product['product']);

final value = product['productId'] ??
product['product_id'] ??
product['id'] ??
nested['productId'] ??
nested['product_id'] ??
nested['id'];

return value?.toString().trim() ?? '';
}

String _text(
Map<String, dynamic> product,
List<String> keys, {
String fallback = '',
}) {
for (final key in keys) {
final value = product[key];

if (value != null &&
value.toString().trim().isNotEmpty &&
value.toString().toLowerCase() != 'null') {
return value.toString().trim();
}
}

return fallback;
}

double? _price(Map<String, dynamic> product) {
final raw = product['price'] ??
product['sellingPrice'] ??
product['selling_price'];

if (raw is num) return raw.toDouble();

final cleaned = (raw ?? '')
    .toString()
    .replaceAll(RegExp(r'[^0-9.]'), '');

return double.tryParse(cleaned);
}

String _formatPrice(double? value) {
if (value == null) return 'Price unavailable';

final whole = value == value.roundToDouble();

return '₹${whole ? value.toStringAsFixed(0) : value.toStringAsFixed(2)}';
}

List<String> _images(Map<String, dynamic> product) {
final raw = product['imageUrls'] ??
product['images'] ??
product['imageUrl'] ??
product['image_url'] ??
product['image'];

if (raw is List) {
return raw
    .map((entry) => entry.toString().trim())
    .where(_isHttpUrl)
    .toList();
}

if (raw is String && raw.trim().isNotEmpty) {
final normalized = raw
    .replaceAll('[', '')
    .replaceAll(']', '')
    .replaceAll('"', '')
    .replaceAll("'", '');

return normalized
    .split(RegExp(r'[,;\n]'))
    .map((entry) => entry.trim())
    .where(_isHttpUrl)
    .toSet()
    .toList();
}

return <String>[];
}

bool _isHttpUrl(String value) =>
value.startsWith('https://') || value.startsWith('http://');

String _sellerType(Map<String, dynamic> product) {
final value = _text(
product,
[
'sellerType',
'seller_type',
'sellerRole',
'seller_role',
'role',
],
fallback: 'user',
).toLowerCase();

return <String>{
'artist',
'remaker',
're-maker',
're_maker',
}.contains(value)
? 'ReMaker'
    : 'User seller';
}

String _sellerName(Map<String, dynamic> product) {
return _text(
product,
['sellerName', 'seller_name', 'seller', 'artistName', 'userName'],
fallback: _sellerType(product) == 'ReMaker'
? 'ReMaker'
    : 'EcoLoop seller',
);
}

// -------------------- LOAD WISHLIST --------------------

Future<void> _load({bool refresh = false}) async {
if (!mounted) return;

setState(() {
if (refresh) {
_refreshing = true;
} else {
_loading = true;
}

_error = null;
});

try {
final rows = _rows(await _api.get('/wishlist'));

final cleaned = <Map<String, dynamic>>[];
final seen = <String>{};

for (final row in rows) {
final nested = _map(row['product']);

final item = nested.isNotEmpty
? <String, dynamic>{...row, ...nested}
    : <String, dynamic>{...row};

final id = _productId(item).isNotEmpty
? _productId(item)
    : _productId(row);

if (id.isEmpty || !seen.add(id)) continue;

item['productId'] = id;

final title = _text(
item,
['title', 'name', 'productName', 'product_name'],
);

if (title.isEmpty) continue;

item['title'] = title;
cleaned.add(item);
}

if (!mounted) return;

setState(() {
_items = cleaned;
_loading = false;
_refreshing = false;
});
} catch (error) {
if (!mounted) return;

setState(() {
_error = error.toString().replaceFirst('Exception: ', '');
_loading = false;
_refreshing = false;
});
}
}

// -------------------- REMOVE ITEM --------------------

Future<void> _remove(Map<String, dynamic> product) async {
final id = _productId(product);

if (id.isEmpty || _removingIds.contains(id)) return;

final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) {
return Dialog(
backgroundColor: Colors.white,
surfaceTintColor: Colors.transparent,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(25),
),
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 68,
height: 68,
decoration: BoxDecoration(
color: const Color(0xFFFFF0F1),
borderRadius: BorderRadius.circular(22),
),
child: const Icon(
Icons.favorite_border_rounded,
color: Colors.redAccent,
size: 31,
),
),
const SizedBox(height: 18),
const Text(
'Remove from wishlist?',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.w800,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 9),
Text(
'Remove "${_text(product, ['title', 'name'], fallback: 'this item')}" from your saved items?',
textAlign: TextAlign.center,
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 13,
height: 1.55,
),
),
const SizedBox(height: 23),
Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: () =>
Navigator.pop(dialogContext, false),
style: OutlinedButton.styleFrom(
minimumSize: const Size(0, 47),
foregroundColor: AppColors.primary,
side: BorderSide(
color: AppColors.primary.withOpacity(0.25),
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
child: const Text('Keep item'),
),
),
const SizedBox(width: 11),
Expanded(
child: FilledButton(
onPressed: () =>
Navigator.pop(dialogContext, true),
style: FilledButton.styleFrom(
minimumSize: const Size(0, 47),
backgroundColor: Colors.redAccent,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
child: const Text('Remove'),
),
),
],
),
],
),
),
);
},
);

if (confirmed != true || !mounted) return;

final previous = List<Map<String, dynamic>>.from(_items);

setState(() {
_removingIds.add(id);
_items.removeWhere((item) => _productId(item) == id);
});

try {
await _api.delete('/wishlist/$id');

if (!mounted) return;

ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: const Text('Removed from your wishlist'),
behavior: SnackBarBehavior.floating,
backgroundColor: AppColors.primary,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(13),
),
),
);
} catch (error) {
if (!mounted) return;

setState(() => _items = previous);

ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(
'Could not remove item: ${error.toString().replaceFirst('Exception: ', '')}',
),
behavior: SnackBarBehavior.floating,
backgroundColor: AppColors.error,
),
);
} finally {
if (mounted) {
setState(() => _removingIds.remove(id));
}
}
}

// -------------------- PRODUCT DETAILS --------------------

Future<void> _openProduct(Map<String, dynamic> product) async {
await Navigator.of(context).push(
MaterialPageRoute<void>(
builder: (_) => ProductDetails(
product: Map<String, dynamic>.from(product),
),
),
);

if (mounted) {
_load(refresh: true);
}
}

@override
void initState() {
super.initState();
_load();
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

// -------------------- MAIN SCREEN --------------------

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.background,
appBar: AppBar(
backgroundColor: AppColors.background,
foregroundColor: AppColors.primary,
elevation: 0,
scrolledUnderElevation: 0,
titleSpacing: 18,
title: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'My Wishlist',
style: TextStyle(
fontSize: 21,
fontWeight: FontWeight.w800,
color: AppColors.textPrimary,
),
),
Text(
'${_items.length} saved ${_items.length == 1 ? 'item' : 'items'}',
style: TextStyle(
color: AppColors.textSecondary.withOpacity(0.9),
fontSize: 11,
fontWeight: FontWeight.w500,
),
),
],
),
actions: [
IconButton(
tooltip: 'Refresh wishlist',
onPressed: _refreshing ? null : () => _load(refresh: true),
icon: _refreshing
? const SizedBox(
width: 19,
height: 19,
child: CircularProgressIndicator(strokeWidth: 2),
)
    : const Icon(Icons.refresh_rounded),
),
const SizedBox(width: 7),
],
),
body: _buildBody(),
);
}

// -------------------- SINGLE SCROLL VIEW --------------------

Widget _buildBody() {
final visible = _visibleItems;

return RefreshIndicator(
onRefresh: () => _load(refresh: true),
color: AppColors.primary,
backgroundColor: Colors.white,
child: CustomScrollView(
physics: const AlwaysScrollableScrollPhysics(
parent: BouncingScrollPhysics(),
),
slivers: [
SliverToBoxAdapter(
child: _wishlistHero(),
),

SliverToBoxAdapter(
child: _buildSearchBar(),
),

SliverToBoxAdapter(
child: _buildSectionHeader(visible.length),
),

if (_loading && _items.isEmpty)
const SliverFillRemaining(
hasScrollBody: false,
child: Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
SizedBox(
width: 34,
height: 34,
child: CircularProgressIndicator(
color: AppColors.primary,
strokeWidth: 3,
),
),
SizedBox(height: 15),
Text(
'Loading your wishlist...',
style: TextStyle(
color: AppColors.textSecondary,
fontSize: 13,
),
),
],
),
),
)
else if (_error != null && _items.isEmpty)
SliverFillRemaining(
hasScrollBody: false,
child: _stateMessage(
icon: Icons.cloud_off_rounded,
title: 'Could not load your wishlist',
message: _error!,
actionLabel: 'Try again',
onAction: () => _load(),
),
)
else if (_items.isEmpty)
SliverFillRemaining(
hasScrollBody: false,
child: _stateMessage(
icon: Icons.favorite_border_rounded,
title: 'Your wishlist is waiting',
message:
'Save items you love from the marketplace. '
'They will be kept here for you.',
actionLabel: 'Refresh',
onAction: () => _load(refresh: true),
),
)
else if (visible.isEmpty)
SliverFillRemaining(
hasScrollBody: false,
child: _stateMessage(
icon: Icons.search_off_rounded,
title: 'No matching items',
message: 'Try a different product, category or seller name.',
actionLabel: 'Clear search',
onAction: () {
_searchController.clear();
setState(() {});
},
),
)
else
SliverPadding(
padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
sliver: SliverLayoutBuilder(
builder: (context, constraints) {
final width = constraints.crossAxisExtent;
final columns = width >= 850
? 4
    : width >= 560
? 3
    : 2;

return SliverGrid(
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: columns,
crossAxisSpacing: 13,
mainAxisSpacing: 15,
childAspectRatio: columns >= 3 ? 0.72 : 0.59,
),
delegate: SliverChildBuilderDelegate(
(context, index) => _wishlistCard(visible[index]),
childCount: visible.length,
),
);
},
),
),

if (!_loading && _items.isNotEmpty && visible.isNotEmpty)
SliverToBoxAdapter(
child: _ecoTip(),
),

const SliverToBoxAdapter(
child: SizedBox(height: 25),
),
],
),
);
}

// -------------------- HERO BANNER --------------------

Widget _wishlistHero() {
return Container(
margin: const EdgeInsets.fromLTRB(16, 7, 16, 19),
padding: const EdgeInsets.fromLTRB(19, 21, 15, 19),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(25),
gradient: const LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
Color(0xFF174D1C),
Color(0xFF23732B),
Color(0xFF32863A),
],
),
boxShadow: [
BoxShadow(
color: AppColors.primary.withOpacity(0.19),
blurRadius: 20,
offset: const Offset(0, 8),
),
],
),
child: Stack(
children: [
Positioned(
right: -18,
top: -23,
child: Icon(
Icons.eco_rounded,
size: 130,
color: Colors.white.withOpacity(0.06),
),
),
Row(
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.13),
borderRadius: BorderRadius.circular(30),
border: Border.all(
color: Colors.white.withOpacity(0.14),
),
),
child: const Text(
'YOUR PERSONAL COLLECTION',
style: TextStyle(
color: Colors.white,
fontSize: 9,
letterSpacing: 1,
fontWeight: FontWeight.w800,
),
),
),
const SizedBox(height: 14),
const Text(
'Loved it?\nSave it here.',
style: TextStyle(
color: Colors.white,
fontSize: 27,
height: 1.12,
fontWeight: FontWeight.w900,
letterSpacing: -0.6,
),
),
const SizedBox(height: 9),
Text(
'Your favourites, all in one place.',
style: TextStyle(
color: Colors.white.withOpacity(0.82),
fontSize: 11.5,
),
),
const SizedBox(height: 16),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 8,
),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.13),
borderRadius: BorderRadius.circular(12),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.favorite_rounded,
color: Color(0xFFFFD4D8),
size: 15,
),
const SizedBox(width: 7),
Text(
'${_items.length} saved ${_items.length == 1 ? 'item' : 'items'}',
style: const TextStyle(
color: Colors.white,
fontSize: 11,
fontWeight: FontWeight.w800,
),
),
],
),
),
],
),
),
const SizedBox(width: 8),
Container(
width: 74,
height: 74,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.12),
shape: BoxShape.circle,
border: Border.all(
color: Colors.white.withOpacity(0.22),
),
),
child: const Icon(
Icons.favorite_rounded,
size: 37,
color: Color(0xFFFFD4D8),
),
),
],
),
],
),
);
}

// -------------------- SEARCH --------------------

Widget _buildSearchBar() {
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 16),
child: Container(
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(17),
border: Border.all(
color: AppColors.primary.withOpacity(0.12),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.025),
blurRadius: 13,
offset: const Offset(0, 4),
),
],
),
child: TextField(
controller: _searchController,
onChanged: (_) => setState(() {}),
textInputAction: TextInputAction.search,
decoration: InputDecoration(
hintText: 'Search products, categories or sellers...',
hintStyle: const TextStyle(
fontSize: 12,
color: AppColors.textSecondary,
),
prefixIcon: const Icon(
Icons.search_rounded,
color: AppColors.primary,
size: 23,
),
suffixIcon: _searchController.text.isEmpty
? null
    : IconButton(
tooltip: 'Clear search',
onPressed: () {
_searchController.clear();
setState(() {});
},
icon: const Icon(
Icons.close_rounded,
color: AppColors.textSecondary,
),
),
filled: true,
fillColor: Colors.transparent,
contentPadding: const EdgeInsets.symmetric(vertical: 16),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(17),
borderSide: BorderSide.none,
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(17),
borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(17),
borderSide: const BorderSide(
color: AppColors.primary,
width: 1.2,
),
),
),
),
),
);
}

// -------------------- SECTION HEADING / SORT --------------------

Widget _buildSectionHeader(int count) {
return Padding(
padding: const EdgeInsets.fromLTRB(19, 24, 16, 15),
child: Row(
children: [
Container(
width: 5,
height: 37,
decoration: BoxDecoration(
color: AppColors.primary,
borderRadius: BorderRadius.circular(8),
),
),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Your saved finds',
style: TextStyle(
color: AppColors.textPrimary,
fontSize: 17,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 4),
Text(
'$count ${count == 1 ? 'item' : 'items'}'
'${_searchController.text.trim().isNotEmpty ? ' found' : ' saved for later'}',
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 11,
),
),
],
),
),
PopupMenuButton<String>(
tooltip: 'Sort wishlist',
initialValue: _sortBy,
onSelected: (value) => setState(() => _sortBy = value),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
),
itemBuilder: (_) => const [
PopupMenuItem(
value: 'Recently saved',
child: Text('Recently saved'),
),
PopupMenuItem(
value: 'Price: low to high',
child: Text('Price: low to high'),
),
PopupMenuItem(
value: 'Price: high to low',
child: Text('Price: high to low'),
),
PopupMenuItem(
value: 'Name: A–Z',
child: Text('Name: A–Z'),
),
],
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 11,
vertical: 10,
),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(13),
border: Border.all(
color: AppColors.primary.withOpacity(0.13),
),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.tune_rounded,
size: 17,
color: AppColors.primary,
),
const SizedBox(width: 5),
Text(
_sortBy == 'Recently saved' ? 'Sort' : 'Sorted',
style: const TextStyle(
color: AppColors.primary,
fontSize: 11,
fontWeight: FontWeight.w800,
),
),
const SizedBox(width: 2),
const Icon(
Icons.keyboard_arrow_down_rounded,
size: 17,
color: AppColors.primary,
),
],
),
),
),
],
),
);
}

// -------------------- PRODUCT CARD --------------------

Widget _wishlistCard(Map<String, dynamic> product) {
final images = _images(product);
final id = _productId(product);
final title = _text(
product,
['title', 'name'],
fallback: 'Product',
);
final seller = _sellerName(product);
final category = _text(
product,
['category', 'categoryName', 'category_name'],
);
final removing = _removingIds.contains(id);
final price = _formatPrice(_price(product));

return Material(
color: AppColors.surface,
borderRadius: BorderRadius.circular(21),
clipBehavior: Clip.antiAlias,
child: InkWell(
onTap: () => _openProduct(product),
borderRadius: BorderRadius.circular(21),
child: Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(21),
border: Border.all(
color: AppColors.primary.withOpacity(0.12),
),
boxShadow: [
BoxShadow(
color: AppColors.primary.withOpacity(0.055),
blurRadius: 15,
offset: const Offset(0, 5),
),
],
),
clipBehavior: Clip.antiAlias,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// Product image
Expanded(
flex: 11,
child: Stack(
fit: StackFit.expand,
children: [
images.isEmpty
? _imageFallback()
    : Image.network(
images.first,
fit: BoxFit.cover,
width: double.infinity,
loadingBuilder: (context, child, progress) {
if (progress == null) return child;

return Stack(
fit: StackFit.expand,
children: [
_imageFallback(),
Center(
child: SizedBox(
width: 24,
height: 24,
child: CircularProgressIndicator(
strokeWidth: 2,
color: AppColors.primary,
value: progress.expectedTotalBytes ==
null
? null
    : progress.cumulativeBytesLoaded /
progress.expectedTotalBytes!,
),
),
),
],
);
},
errorBuilder: (_, __, ___) => _imageFallback(),
),

// Subtle image overlay
Positioned(
left: 0,
right: 0,
bottom: 0,
height: 60,
child: IgnorePointer(
child: DecoratedBox(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
Colors.transparent,
Colors.black.withOpacity(0.22),
],
),
),
),
),
),

// Remove button
Positioned(
top: 9,
right: 9,
child: Material(
color: Colors.white.withOpacity(0.96),
shape: const CircleBorder(),
elevation: 2,
child: InkWell(
customBorder: const CircleBorder(),
onTap: removing ? null : () => _remove(product),
child: SizedBox(
width: 36,
height: 36,
child: Center(
child: removing
? const SizedBox(
width: 17,
height: 17,
child: CircularProgressIndicator(
strokeWidth: 2,
color: AppColors.primary,
),
)
    : const Icon(
Icons.favorite_rounded,
color: Colors.redAccent,
size: 20,
),
),
),
),
),
),

if (category.isNotEmpty)
Positioned(
left: 9,
bottom: 9,
right: 9,
child: Align(
alignment: Alignment.bottomLeft,
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 5,
),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.95),
borderRadius: BorderRadius.circular(20),
),
child: Text(
category,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: AppColors.primary,
fontSize: 9,
fontWeight: FontWeight.w800,
),
),
),
),
),

if (images.length > 1)
Positioned(
top: 53,
right: 9,
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 7,
vertical: 4,
),
decoration: BoxDecoration(
color: Colors.black.withOpacity(0.58),
borderRadius: BorderRadius.circular(10),
),
child: Text(
'${images.length} photos',
style: const TextStyle(
color: Colors.white,
fontSize: 9,
fontWeight: FontWeight.w700,
),
),
),
),
],
),
),

// Product information
Expanded(
flex: 10,
child: Padding(
padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: AppColors.textPrimary,
fontSize: 12.5,
height: 1.25,
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 6),

Row(
children: [
Icon(
_sellerType(product) == 'ReMaker'
? Icons.brush_outlined
    : Icons.storefront_outlined,
size: 13,
color: AppColors.textSecondary,
),
const SizedBox(width: 4),
Expanded(
child: Text(
seller,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 10,
),
),
),
],
),

const Spacer(),

Container(
height: 1,
color: AppColors.primary.withOpacity(0.09),
),

const SizedBox(height: 8),

Row(
children: [
Expanded(
child: Text(
price,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: AppColors.primary,
fontSize: 14,
fontWeight: FontWeight.w900,
),
),
),
Container(
width: 28,
height: 28,
decoration: BoxDecoration(
color: AppColors.light,
borderRadius: BorderRadius.circular(9),
),
child: const Icon(
Icons.arrow_forward_rounded,
color: AppColors.primary,
size: 16,
),
),
],
),
],
),
),
),
],
),
),
),
);
}

// -------------------- IMAGE FALLBACK --------------------

Widget _imageFallback() {
return Container(
color: AppColors.light,
child: Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.image_not_supported_outlined,
size: 35,
color: AppColors.primary.withOpacity(0.55),
),
const SizedBox(height: 6),
const Text(
'No image',
style: TextStyle(
color: AppColors.textSecondary,
fontSize: 10,
),
),
],
),
),
);
}

// -------------------- ECO TIP --------------------

Widget _ecoTip() {
return Container(
margin: const EdgeInsets.fromLTRB(16, 5, 16, 12),
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
color: AppColors.light,
borderRadius: BorderRadius.circular(17),
border: Border.all(
color: AppColors.accent.withOpacity(0.6),
),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.8),
borderRadius: BorderRadius.circular(13),
),
child: const Icon(
Icons.eco_rounded,
color: AppColors.primary,
size: 23,
),
),
const SizedBox(width: 12),
const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Choose a more sustainable find',
style: TextStyle(
color: AppColors.primary,
fontSize: 12,
fontWeight: FontWeight.w800,
),
),
SizedBox(height: 5),
Text(
'Good finds deserve a second life. Keep your favourites close until you are ready.',
style: TextStyle(
color: AppColors.textSecondary,
fontSize: 11,
height: 1.5,
),
),
],
),
),
],
),
);
}

// -------------------- EMPTY / ERROR STATES --------------------

Widget _stateMessage({
required IconData icon,
required String title,
required String message,
required String actionLabel,
required VoidCallback onAction,
}) {
return Center(
child: Padding(
padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 92,
height: 92,
decoration: BoxDecoration(
color: AppColors.light,
shape: BoxShape.circle,
border: Border.all(
color: AppColors.accent.withOpacity(0.55),
),
),
child: Icon(
icon,
size: 42,
color: AppColors.primary,
),
),
const SizedBox(height: 20),
Text(
title,
textAlign: TextAlign.center,
style: const TextStyle(
color: AppColors.textPrimary,
fontSize: 19,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 9),
Text(
message,
textAlign: TextAlign.center,
style: const TextStyle(
color: AppColors.textSecondary,
fontSize: 13,
height: 1.55,
),
),
const SizedBox(height: 21),
FilledButton.icon(
onPressed: onAction,
icon: Icon(
actionLabel == 'Clear search'
? Icons.close_rounded
    : Icons.refresh_rounded,
size: 18,
),
label: Text(actionLabel),
style: FilledButton.styleFrom(
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(
horizontal: 21,
vertical: 13,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
textStyle: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w800,
),
),
),
],
),
),
);
}
}
