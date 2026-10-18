import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../app_theme/user/app_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../buy_products/artist_profile.dart';

class FollowingList extends StatefulWidget {
const FollowingList({super.key});

@override
State<FollowingList> createState() => _FollowingListState();
}

class _FollowingListState extends State<FollowingList> {
final EcoLoopApi _api = EcoLoopApi.instance;
final TextEditingController _searchController = TextEditingController();

List<Map<String, dynamic>> _following = [];
bool _loading = true;
String? _error;
final Set<String> _unfollowingIds = {};

@override
void initState() {
super.initState();
_loadFollowing();
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

// ---------------- DATA HELPERS ----------------

List<Map<String, dynamic>> _rowsFrom(dynamic response) {
dynamic rows = response;

if (rows is Map) {
rows = rows['following'] ??
rows['artists'] ??
rows['results'] ??
rows['data'] ??
rows['items'];

if (rows is Map) {
rows = rows['following'] ??
rows['artists'] ??
rows['results'] ??
rows['items'] ??
rows['data'];
}
}

if (rows is! List) return [];

return rows
    .whereType<Map>()
    .map((row) => Map<String, dynamic>.from(row))
    .where((row) => _artistId(row).isNotEmpty)
    .toList();
}

String _firstValue(
Map<String, dynamic> data,
List<String> keys,
) {
for (final key in keys) {
final value = data[key];

if (value == null) continue;

if (value is List) {
final result = value
    .map((item) => item.toString())
    .where((item) => item.trim().isNotEmpty)
    .join(', ');

if (result.isNotEmpty) return result;
} else {
final result = value.toString().trim();
if (result.isNotEmpty && result != 'null') return result;
}
}

return '';
}

String _artistId(Map<String, dynamic> artist) {
return _firstValue(artist, ['artistId', 'artist_id', 'id']);
}

String _artistName(Map<String, dynamic> artist) {
return _firstValue(
artist,
['name', 'userName', 'username', 'artistName', 'fullName'],
).ifEmpty('ReMaker');
}

String _avatar(Map<String, dynamic> artist) {
return _firstValue(
artist,
[
'profilePhotoUrl',
'image',
'profileImageUrl',
'avatarUrl',
'profile_image',
],
);
}

String _location(Map<String, dynamic> artist) {
final location = _firstValue(artist, ['location', 'address']);
if (location.isNotEmpty) return location;

final city = _firstValue(artist, ['city']);
final state = _firstValue(artist, ['state']);

if (city.isNotEmpty && state.isNotEmpty) {
return '$city, $state';
}

return city.isNotEmpty ? city : state;
}

String _skills(Map<String, dynamic> artist) {
return _firstValue(
artist,
['skills', 'category', 'specialization', 'craft'],
);
}

String _followerCount(Map<String, dynamic> artist) {
return _firstValue(artist, ['followerCount', 'followers'])
    .ifEmpty('0');
}

String _normaliseImageUrl(String raw) {
final url = raw.trim();
if (url.isEmpty) return '';

final match = RegExp(
r'(?:drive\.google\.com|docs\.google\.com)/(?:file/d/|open\?id=|uc\?[^#]*?id=)([A-Za-z0-9_-]+)',
caseSensitive: false,
).firstMatch(url);

if (match != null &&
(url.contains('drive.google.com') ||
url.contains('docs.google.com'))) {
return 'https://drive.google.com/uc?export=view&id=${match.group(1)}';
}

return url;
}

// ---------------- FETCH FOLLOWING ----------------

Future<void> _loadFollowing({bool showLoader = true}) async {
if (showLoader && mounted) {
setState(() {
_loading = true;
_error = null;
});
}

try {
final response = await _api.get('/my/following');
final rows = _rowsFrom(response);

if (!mounted) return;

setState(() {
_following = rows;
_loading = false;
_error = null;
});
} catch (error) {
if (!mounted) return;

setState(() {
_loading = false;
_error = error.toString();
});
}
}

// ---------------- SEARCH ----------------

List<Map<String, dynamic>> get _filteredFollowing {
final query = _searchController.text.trim().toLowerCase();

if (query.isEmpty) return _following;

return _following.where((artist) {
final searchable = [
_artistName(artist),
_location(artist),
_skills(artist),
_firstValue(artist, ['username', 'userName']),
_firstValue(artist, ['bio', 'description']),
].join(' ').toLowerCase();

return searchable.contains(query);
}).toList();
}

void _clearSearch() {
_searchController.clear();
setState(() {});
}

// ---------------- UNFOLLOW ----------------

Future<void> _unfollow(Map<String, dynamic> artist) async {
final id = _artistId(artist);

if (id.isEmpty || _unfollowingIds.contains(id)) return;

final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) {
return Dialog(
backgroundColor: AppColors.surface,
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
width: 70,
height: 70,
decoration: BoxDecoration(
color: AppColors.light,
borderRadius: BorderRadius.circular(22),
),
child: const Icon(
Icons.person_remove_alt_1_rounded,
color: AppColors.primary,
size: 32,
),
),
const SizedBox(height: 18),
Text(
'Unfollow ${_artistName(artist)}?',
textAlign: TextAlign.center,
style: AppTextStyles.title.copyWith(
fontSize: 19,
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 10),
Text(
'This creator will be removed from your following list. '
'You can follow them again anytime.',
textAlign: TextAlign.center,
style: AppTextStyles.body.copyWith(
fontSize: 13,
height: 1.6,
),
),
const SizedBox(height: 24),
Row(
children: [
Expanded(
child: OutlinedButton(
onPressed: () =>
Navigator.pop(dialogContext, false),
style: OutlinedButton.styleFrom(
foregroundColor: AppColors.primary,
minimumSize: const Size(0, 47),
side: BorderSide(
color: AppColors.accent.withOpacity(0.8),
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
child: const Text('Cancel'),
),
),
const SizedBox(width: 12),
Expanded(
child: FilledButton(
onPressed: () =>
Navigator.pop(dialogContext, true),
style: FilledButton.styleFrom(
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
minimumSize: const Size(0, 47),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
child: const Text('Unfollow'),
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

setState(() => _unfollowingIds.add(id));

try {
await _api.delete('/artists/$id/follow');

if (!mounted) return;

setState(() {
_following.removeWhere((item) => _artistId(item) == id);
_unfollowingIds.remove(id);
});

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('${_artistName(artist)} unfollowed successfully'),
behavior: SnackBarBehavior.floating,
backgroundColor: AppColors.primary,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
);
} catch (error) {
if (!mounted) return;

setState(() => _unfollowingIds.remove(id));

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Could not unfollow this artist: $error'),
behavior: SnackBarBehavior.floating,
backgroundColor: AppColors.error,
),
);
}
}

void _openArtist(Map<String, dynamic> artist) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ArtistProfile(artist: artist),
),
);
}

// ---------------- SCREEN ----------------

@override
Widget build(BuildContext context) {
final visible = _filteredFollowing;

return Scaffold(
backgroundColor: AppColors.background,
appBar: AppBar(
backgroundColor: AppColors.background,
surfaceTintColor: Colors.transparent,
elevation: 0,
scrolledUnderElevation: 0,
leading: IconButton(
onPressed: () => Navigator.maybePop(context),
icon: const Icon(
Icons.arrow_back_ios_new_rounded,
size: 19,
color: AppColors.textPrimary,
),
),
title: Text(
'My Following',
style: AppTextStyles.title.copyWith(
fontSize: 21,
fontWeight: FontWeight.w700,
),
),
actions: [
IconButton(
tooltip: 'Refresh',
onPressed: () => _loadFollowing(),
icon: const Icon(
Icons.refresh_rounded,
color: AppColors.primary,
),
),
const SizedBox(width: 5),
],
),

// One scroll view for the ENTIRE page.
body: SafeArea(
top: false,
child: RefreshIndicator(
onRefresh: () => _loadFollowing(showLoader: false),
color: AppColors.primary,
backgroundColor: Colors.white,
child: CustomScrollView(
physics: const AlwaysScrollableScrollPhysics(
parent: BouncingScrollPhysics(),
),
slivers: [
// Header scrolls with the page.
SliverToBoxAdapter(
child: _buildHeroHeader(),
),

SliverToBoxAdapter(
child: _buildSearchBar(),
),

SliverToBoxAdapter(
child: _buildSectionHeading(visible.length),
),

if (_loading)
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
strokeWidth: 3,
color: AppColors.primary,
),
),
SizedBox(height: 15),
Text(
'Loading your community...',
style: TextStyle(
color: AppColors.textSecondary,
fontSize: 13,
),
),
],
),
),
)
else if (_error != null && _following.isEmpty)
SliverFillRemaining(
hasScrollBody: false,
child: _buildState(
icon: Icons.cloud_off_rounded,
title: 'Couldn’t load your list',
message:
'Please check your connection and try again.',
buttonText: 'Try again',
onPressed: () => _loadFollowing(),
),
)
else if (_following.isEmpty)
SliverFillRemaining(
hasScrollBody: false,
child: _buildState(
icon: Icons.people_alt_outlined,
title: 'Your community starts here',
message:
'You are not following any creators yet. '
'Explore the marketplace to discover amazing ReMakers.',
buttonText: 'Explore marketplace',
onPressed: () => Navigator.maybePop(context),
),
)
else if (visible.isEmpty)
SliverFillRemaining(
hasScrollBody: false,
child: _buildState(
icon: Icons.search_off_rounded,
title: 'No creators found',
message:
'Try another name, skill or location.',
buttonText: 'Clear search',
onPressed: _clearSearch,
),
)
else
SliverPadding(
padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
sliver: SliverList(
delegate: SliverChildBuilderDelegate(
(context, index) {
final artist = visible[index];

return Padding(
padding: const EdgeInsets.only(bottom: 15),
child: _buildArtistCard(artist),
);
},
childCount: visible.length,
),
),
),
],
),
),
),
);
}

// ---------------- PREMIUM HEADER ----------------

Widget _buildHeroHeader() {
return Container(
margin: const EdgeInsets.fromLTRB(18, 8, 18, 20),
padding: const EdgeInsets.fromLTRB(21, 22, 21, 20),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [
Color(0xFF154D1B),
Color(0xFF23752D),
Color(0xFF43A047),
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
borderRadius: BorderRadius.circular(27),
boxShadow: [
BoxShadow(
color: AppColors.primary.withOpacity(0.20),
blurRadius: 22,
offset: const Offset(0, 9),
),
],
),
child: Stack(
children: [
Positioned(
right: -10,
top: -18,
child: Icon(
Icons.eco_rounded,
size: 130,
color: Colors.white.withOpacity(0.07),
),
),
Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 55,
height: 55,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.15),
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: Colors.white.withOpacity(0.2),
),
),
child: const Icon(
Icons.diversity_3_rounded,
color: Colors.white,
size: 29,
),
),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Your Creative Community',
style: TextStyle(
color: Colors.white,
fontSize: 17,
fontWeight: FontWeight.w800,
letterSpacing: -0.3,
),
),
const SizedBox(height: 6),
Text(
'Connect with creators who inspire you.',
style: TextStyle(
color: Colors.white.withOpacity(0.82),
fontSize: 11.5,
height: 1.5,
),
),
],
),
),
],
),
const SizedBox(height: 22),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 11,
),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.13),
borderRadius: BorderRadius.circular(15),
border: Border.all(
color: Colors.white.withOpacity(0.13),
),
),
child: Row(
children: [
const Icon(
Icons.people_alt_rounded,
color: Colors.white,
size: 20,
),
const SizedBox(width: 10),
Expanded(
child: Text(
'${_following.length} ${_following.length == 1 ? 'creator' : 'creators'} in your community',
style: const TextStyle(
color: Colors.white,
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
),
const Icon(
Icons.arrow_forward_rounded,
color: Colors.white70,
size: 18,
),
],
),
),
],
),
],
),
);
}

// ---------------- SEARCH BAR ----------------

Widget _buildSearchBar() {
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 18),
child: Container(
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: AppColors.accent.withOpacity(0.65),
),
boxShadow: [
BoxShadow(
color: AppColors.primary.withOpacity(0.035),
blurRadius: 15,
offset: const Offset(0, 5),
),
],
),
child: TextField(
controller: _searchController,
onChanged: (_) => setState(() {}),
textInputAction: TextInputAction.search,
decoration: InputDecoration(
hintText: 'Search creators, skills or locations...',
hintStyle: AppTextStyles.hint.copyWith(fontSize: 12),
prefixIcon: const Icon(
Icons.search_rounded,
color: AppColors.primary,
size: 23,
),
suffixIcon: _searchController.text.isEmpty
? null
    : IconButton(
tooltip: 'Clear search',
onPressed: _clearSearch,
icon: const Icon(
Icons.close_rounded,
color: AppColors.textSecondary,
),
),
border: InputBorder.none,
contentPadding: const EdgeInsets.symmetric(vertical: 17),
),
),
),
);
}

// ---------------- SECTION HEADING ----------------

Widget _buildSectionHeading(int visibleCount) {
return Padding(
padding: const EdgeInsets.fromLTRB(21, 24, 21, 16),
child: Row(
children: [
Container(
width: 5,
height: 35,
decoration: BoxDecoration(
color: AppColors.primary,
borderRadius: BorderRadius.circular(8),
),
),
const SizedBox(width: 11),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Artists & ReMakers',
style: AppTextStyles.title.copyWith(
fontSize: 16,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 3),
Text(
_searchController.text.trim().isEmpty
? 'People you are following'
    : '$visibleCount matching creator(s)',
style: AppTextStyles.caption.copyWith(fontSize: 11),
),
],
),
),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 8,
),
decoration: BoxDecoration(
color: AppColors.light,
borderRadius: BorderRadius.circular(12),
),
child: Text(
'$visibleCount',
style: const TextStyle(
color: AppColors.primary,
fontSize: 13,
fontWeight: FontWeight.w800,
),
),
),
],
),
);
}

// ---------------- ARTIST CARD ----------------

Widget _buildArtistCard(Map<String, dynamic> artist) {
final id = _artistId(artist);
final name = _artistName(artist);
final imageUrl = _normaliseImageUrl(_avatar(artist));
final location = _location(artist);
final skills = _skills(artist);
final followers = _followerCount(artist);
final busy = _unfollowingIds.contains(id);

return Material(
color: AppColors.surface,
borderRadius: BorderRadius.circular(23),
clipBehavior: Clip.antiAlias,
child: InkWell(
onTap: () => _openArtist(artist),
child: Container(
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(23),
border: Border.all(
color: AppColors.accent.withOpacity(0.55),
),
boxShadow: [
BoxShadow(
color: AppColors.primary.withOpacity(0.045),
blurRadius: 15,
offset: const Offset(0, 5),
),
],
),
child: Column(
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_buildAvatar(imageUrl),
const SizedBox(width: 14),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Expanded(
child: Text(
name,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: AppTextStyles.title.copyWith(
fontSize: 15,
fontWeight: FontWeight.w800,
),
),
),
const SizedBox(width: 5),
Container(
width: 24,
height: 24,
decoration: BoxDecoration(
color: AppColors.light,
borderRadius: BorderRadius.circular(8),
),
child: const Icon(
Icons.verified_rounded,
size: 16,
color: AppColors.primary,
),
),
],
),
const SizedBox(height: 8),
if (location.isNotEmpty)
_detailRow(
Icons.location_on_outlined,
location,
),
if (skills.isNotEmpty) ...[
const SizedBox(height: 7),
_detailRow(
Icons.auto_awesome_outlined,
skills,
),
],
const SizedBox(height: 9),
Row(
children: [
const Icon(
Icons.people_alt_outlined,
color: AppColors.primary,
size: 15,
),
const SizedBox(width: 5),
Text(
'$followers followers',
style: AppTextStyles.caption.copyWith(
fontSize: 11,
fontWeight: FontWeight.w600,
),
),
],
),
],
),
),
],
),
const SizedBox(height: 16),
Container(
height: 1,
color: AppColors.accent.withOpacity(0.4),
),
const SizedBox(height: 13),
Row(
children: [
Expanded(
child: OutlinedButton.icon(
onPressed: busy ? null : () => _unfollow(artist),
icon: busy
? const SizedBox(
width: 15,
height: 15,
child: CircularProgressIndicator(
strokeWidth: 2,
color: AppColors.primary,
),
)
    : const Icon(
Icons.person_remove_alt_1_rounded,
size: 17,
),
label: Text(busy ? 'Please wait' : 'Unfollow'),
style: OutlinedButton.styleFrom(
foregroundColor: AppColors.primary,
disabledForegroundColor:
AppColors.textSecondary,
minimumSize: const Size(0, 44),
padding: const EdgeInsets.symmetric(horizontal: 8),
side: BorderSide(
color: AppColors.primary.withOpacity(0.45),
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(13),
),
textStyle: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
),
),
const SizedBox(width: 10),
Expanded(
child: FilledButton.icon(
onPressed: () => _openArtist(artist),
icon: const Icon(
Icons.person_outline_rounded,
size: 17,
),
label: const Text('View Profile'),
style: FilledButton.styleFrom(
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
minimumSize: const Size(0, 44),
padding: const EdgeInsets.symmetric(horizontal: 8),
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(13),
),
textStyle: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
),
),
),
),
],
),
],
),
),
),
);
}

Widget _buildAvatar(String imageUrl) {
return Container(
width: 78,
height: 78,
padding: const EdgeInsets.all(3),
decoration: BoxDecoration(
shape: BoxShape.circle,
gradient: const LinearGradient(
colors: [
AppColors.secondary,
AppColors.accent,
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
boxShadow: [
BoxShadow(
color: AppColors.primary.withOpacity(0.10),
blurRadius: 9,
offset: const Offset(0, 3),
),
],
),
child: ClipOval(
child: Container(
color: AppColors.light,
child: imageUrl.isEmpty
? const Icon(
Icons.person_rounded,
size: 39,
color: AppColors.primary,
)
    : Image.network(
imageUrl,
key: ValueKey(imageUrl),
fit: BoxFit.cover,
errorBuilder: (_, __, ___) {
return const Icon(
Icons.person_rounded,
size: 39,
color: AppColors.primary,
);
},
loadingBuilder: (context, child, progress) {
if (progress == null) return child;

return const Center(
child: SizedBox(
width: 21,
height: 21,
child: CircularProgressIndicator(
strokeWidth: 2,
color: AppColors.primary,
),
),
);
},
),
),
),
);
}

Widget _detailRow(IconData icon, String value) {
return Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
icon,
size: 15,
color: AppColors.textSecondary,
),
const SizedBox(width: 6),
Expanded(
child: Text(
value,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: AppTextStyles.caption.copyWith(
fontSize: 11,
height: 1.45,
),
),
),
],
);
}

// ---------------- EMPTY / ERROR STATE ----------------

Widget _buildState({
required IconData icon,
required String title,
required String message,
required String buttonText,
required VoidCallback onPressed,
}) {
return Center(
child: Padding(
padding: const EdgeInsets.fromLTRB(30, 20, 30, 35),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 102,
height: 102,
decoration: BoxDecoration(
color: AppColors.light,
shape: BoxShape.circle,
border: Border.all(
color: AppColors.accent.withOpacity(0.7),
width: 1.5,
),
),
child: Icon(
icon,
size: 44,
color: AppColors.primary,
),
),
const SizedBox(height: 23),
Text(
title,
textAlign: TextAlign.center,
style: AppTextStyles.title.copyWith(
fontSize: 19,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 10),
Text(
message,
textAlign: TextAlign.center,
style: AppTextStyles.body.copyWith(
fontSize: 13,
height: 1.65,
),
),
const SizedBox(height: 23),
FilledButton.icon(
onPressed: onPressed,
icon: Icon(
buttonText == 'Try again'
? Icons.refresh_rounded
    : buttonText == 'Clear search'
? Icons.close_rounded
    : Icons.explore_outlined,
size: 18,
),
label: Text(buttonText),
style: FilledButton.styleFrom(
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(
horizontal: 22,
vertical: 14,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
textStyle: const TextStyle(
fontWeight: FontWeight.w700,
),
),
),
],
),
),
);
}
}

extension _StringFallback on String {
String ifEmpty(String fallback) =>
trim().isEmpty ? fallback : this;
}