
import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';
import 'donation_details.dart';

class DonationHistory extends StatefulWidget {
const DonationHistory({super.key});

@override
State<DonationHistory> createState() => _DonationHistoryState();
}

class _DonationHistoryState extends State<DonationHistory> {
String _selectedFilter = 'All';
bool _loading = true;
String? _error;

List<Map<String, dynamic>> _donations = [];
Map<String, String> _categoryNames = {};

static const List<String> _filters = [
'All',
'Active',
'Completed',
];

@override
void initState() {
super.initState();
_loadDonations();
}

// --------------------------------------------------
// LOAD DONATIONS
// --------------------------------------------------

Future<void> _loadDonations() async {
if (mounted) {
setState(() {
_loading = true;
_error = null;
});
}

try {
final results = await Future.wait<dynamic>([
EcoLoopApi.instance.get('/donations'),
EcoLoopApi.instance.get('/categories'),
]);

final response = results[0];
final categoryResponse = results[1];

final List<dynamic> categoryRows =
categoryResponse is List
? categoryResponse
    : categoryResponse is Map &&
categoryResponse['categories'] is List
? categoryResponse['categories'] as List
    : <dynamic>[];

final categoryNames = <String, String>{};

for (final row in categoryRows.whereType<Map>()) {
final id = row['categoryId'] ?? row['id'];
final name = row['name'];

if (id != null && name != null) {
categoryNames[id.toString()] = name.toString();
}
}

final List<dynamic> rows;

if (response is List) {
rows = response;
} else if (response is Map &&
response['donations'] is List) {
rows = response['donations'] as List;
} else if (response is Map &&
response['data'] is List) {
rows = response['data'] as List;
} else {
throw Exception(
'The server returned an unexpected donations response.',
);
}

final parsed = rows
    .whereType<Map>()
    .map(
(row) => _normalizeDonation(
Map<String, dynamic>.from(row),
categoryNames,
),
)
    .toList();

if (!mounted) return;

setState(() {
_donations = parsed;
_categoryNames = categoryNames;
_loading = false;
_error = null;
});
} catch (e) {
if (!mounted) return;

setState(() {
_error = e.toString().replaceFirst('Exception: ', '');
_loading = false;
});
}
}

// --------------------------------------------------
// NORMALIZE API DATA
// --------------------------------------------------

Map<String, dynamic> _normalizeDonation(
Map<String, dynamic> raw, [
Map<String, String> categoryNames = const {},
]) {
final images = raw['imageUrls'];

String image = '';

if (images is List && images.isNotEmpty) {
image = images.first.toString();
} else if (raw['image'] != null) {
image = raw['image'].toString();
}

final rawStatus = raw['status']?.toString() ?? 'pending';
final createdAt = raw['createdAt']?.toString() ?? '';

return {
...raw,
'id': raw['donationId']?.toString() ??
raw['id']?.toString() ??
'',
'item': raw['title']?.toString() ??
raw['item']?.toString() ??
'Donated Item',
'category': raw['category']?.toString() ??
raw['categoryName']?.toString() ??
categoryNames[raw['categoryId']?.toString()] ??
(raw['categoryId'] == null
? 'Category unavailable'
    : 'Category ${raw['categoryId']}'),
'condition': _prettyCondition(
raw['condition']?.toString() ?? 'used',
),
'date': _displayDate(
createdAt.isNotEmpty
? createdAt
    : raw['date']?.toString(),
),
'status': _prettyStatus(rawStatus),
'rawStatus': rawStatus.toLowerCase(),
'pickupDate': raw['pickupDate']?.toString() ?? '',
'location': [
raw['city']?.toString(),
raw['state']?.toString(),
].where(
(part) => part != null && part.trim().isNotEmpty,
).join(', '),
'address': raw['address']?.toString() ?? '',
'image': image,
'rewardStatus': raw['rewardStatus']?.toString() ??
_rewardStatusFor(rawStatus),
'rewardPoints': raw['rewardPoints'] ?? 0,
'rewardCredited': raw['rewardCredited'] == true ||
'${raw['rewardCredited']}'.toLowerCase() == 'true',
};
}

String _rewardStatusFor(String status) {
switch (status.toLowerCase()) {
case 'accepted':
case 'approved':
case 'completed':
return 'Accepted — check Rewards for credited points';
case 'rejected':
return 'Not eligible';
default:
return 'Pending acceptance';
}
}

String _prettyCondition(String value) {
return value
    .replaceAll('_', ' ')
    .split(' ')
    .where((part) => part.isNotEmpty)
    .map(
(part) =>
'${part[0].toUpperCase()}${part.substring(1)}',
)
    .join(' ');
}

String _prettyStatus(String value) {
switch (value.toLowerCase()) {
case 'pending':
case 'submitted':
return 'Pending';
case 'pickup_requested':
case 'requested':
case 'pickup scheduled':
return 'Pickup Scheduled';
case 'picked_up':
case 'collected':
return 'Collected';
case 'accepted':
case 'approved':
return 'Accepted';
case 'rejected':
return 'Rejected';
case 'completed':
return 'Completed';
case 'cancelled':
return 'Cancelled';
default:
return _prettyCondition(value);
}
}

String _displayDate(String? raw) {
if (raw == null || raw.trim().isEmpty) {
return 'Date unavailable';
}

final parsed = DateTime.tryParse(raw.trim());

if (parsed == null) return raw;

const months = [
'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

// --------------------------------------------------
// FILTERS AND COUNTS
// --------------------------------------------------

bool _isCompleted(Map<String, dynamic> donation) {
final status =
(donation['rawStatus'] ?? donation['status'])
    .toString()
    .toLowerCase();

return [
'completed',
'collected',
'picked_up',
'accepted',
'approved',
].contains(status);
}

bool _isActive(Map<String, dynamic> donation) {
final status =
(donation['rawStatus'] ?? donation['status'])
    .toString()
    .toLowerCase();

return [
'pending',
'submitted',
'requested',
'pickup_requested',
'pickup scheduled',
'accepted',
'approved',
].contains(status);
}

List<Map<String, dynamic>> get _filteredDonations {
switch (_selectedFilter) {
case 'Active':
return _donations.where(_isActive).toList();
case 'Completed':
return _donations.where(_isCompleted).toList();
default:
return _donations;
}
}

int get _completedCount =>
_donations.where(_isCompleted).length;

int get _activeCount =>
_donations.where(_isActive).length;

int get _totalPoints {
return _donations.fold<int>(0, (total, donation) {
final points =
int.tryParse('${donation['rewardPoints'] ?? 0}') ?? 0;
return total + points;
});
}

// --------------------------------------------------
// MAIN SCREEN
// --------------------------------------------------

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.background,
appBar: AppBar(
backgroundColor: AppColors.surface,
foregroundColor: AppColors.textPrimary,
elevation: 0,
scrolledUnderElevation: 0,
leading: IconButton(
tooltip: 'Go back',
onPressed: () => Navigator.pop(context),
icon: const Icon(Icons.arrow_back_rounded),
),
title: const Text(
'Donation History',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w800,
),
),
centerTitle: true,
actions: [
IconButton(
tooltip: 'Refresh donations',
onPressed: _loading ? null : _loadDonations,
icon: const Icon(Icons.refresh_rounded),
),
const SizedBox(width: 4),
],
),
body: RefreshIndicator(
color: AppColors.primary,
backgroundColor: AppColors.surface,
onRefresh: _loadDonations,
child: CustomScrollView(
physics: const AlwaysScrollableScrollPhysics(
parent: BouncingScrollPhysics(),
),
slivers: [
// Summary scrolls with the rest of the screen.
SliverToBoxAdapter(
child: _buildHeaderSummary(),
),

SliverToBoxAdapter(
child: _buildIntroText(),
),

SliverToBoxAdapter(
child: _buildFilterSection(),
),

if (_loading)
const SliverFillRemaining(
hasScrollBody: false,
child: Center(
child: CircularProgressIndicator(),
),
)
else if (_error != null)
SliverFillRemaining(
hasScrollBody: false,
child: _buildErrorState(),
)
else if (_filteredDonations.isEmpty)
SliverFillRemaining(
hasScrollBody: false,
child: _buildEmptyState(),
)
else ...[
SliverPadding(
padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
sliver: SliverToBoxAdapter(
child: Row(
children: [
const Expanded(
child: Text(
'Your donations',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w800,
color: AppColors.textPrimary,
),
),
),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 11,
vertical: 6,
),
decoration: BoxDecoration(
color: AppColors.light,
borderRadius: BorderRadius.circular(30),
),
child: Text(
'${_filteredDonations.length} items',
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.w700,
color: AppColors.primary,
),
),
),
],
),
),
),

SliverPadding(
padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
sliver: SliverList(
delegate: SliverChildBuilderDelegate(
(context, index) {
return _buildDonationCard(
_filteredDonations[index],
);
},
childCount: _filteredDonations.length,
),
),
),
],
],
),
),
);
}

// --------------------------------------------------
// HEADER SUMMARY
// --------------------------------------------------

Widget _buildHeaderSummary() {
return Container(
width: double.infinity,
margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 20,
),
decoration: BoxDecoration(
gradient: const LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
AppColors.primary,
Color(0xFF2E7D32),
Color(0xFF438B4A),
],
),
borderRadius: BorderRadius.circular(24),
boxShadow: [
BoxShadow(
color: AppColors.primary.withOpacity(0.17),
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
height: 43,
width: 43,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.15),
borderRadius: BorderRadius.circular(14),
),
child: const Icon(
Icons.volunteer_activism_rounded,
color: Colors.white,
size: 23,
),
),
const SizedBox(width: 12),
const Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Your giving journey',
style: TextStyle(
color: Colors.white,
fontSize: 17,
fontWeight: FontWeight.w800,
),
),
SizedBox(height: 3),
Text(
'Small acts. Greener impact.',
style: TextStyle(
color: Colors.white70,
fontSize: 11,
),
),
],
),
),
const Icon(
Icons.eco_rounded,
color: Colors.white70,
size: 27,
),
],
),
const SizedBox(height: 23),
Row(
children: [
Expanded(
child: _summaryItem(
Icons.inventory_2_outlined,
'Donated',
'${_donations.length}',
),
),
_summaryDivider(),
Expanded(
child: _summaryItem(
Icons.pending_actions_rounded,
'Active',
'$_activeCount',
),
),
_summaryDivider(),
Expanded(
child: _summaryItem(
Icons.check_circle_outline_rounded,
'Completed',
'$_completedCount',
),
),
],
),
const SizedBox(height: 17),
Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(
horizontal: 13,
vertical: 11,
),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.13),
borderRadius: BorderRadius.circular(14),
border: Border.all(
color: Colors.white.withOpacity(0.15),
),
),
child: Row(
children: [
const Icon(
Icons.stars_rounded,
color: Color(0xFFFFE082),
size: 23,
),
const SizedBox(width: 10),
const Expanded(
child: Text(
'Total donation reward points',
style: TextStyle(
color: Colors.white,
fontSize: 11,
fontWeight: FontWeight.w500,
),
),
),
Text(
'$_totalPoints',
style: const TextStyle(
color: Colors.white,
fontSize: 18,
fontWeight: FontWeight.w800,
),
),
],
),
),
],
),
);
}

Widget _summaryDivider() {
return Container(
height: 42,
width: 1,
margin: const EdgeInsets.symmetric(horizontal: 4),
color: Colors.white.withOpacity(0.25),
);
}

Widget _summaryItem(
IconData icon,
String title,
String value,
) {
return Column(
children: [
Icon(icon, color: Colors.white, size: 21),
const SizedBox(height: 7),
Text(
value,
style: const TextStyle(
color: Colors.white,
fontSize: 19,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 3),
Text(
title,
textAlign: TextAlign.center,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: Colors.white70,
fontSize: 10,
fontWeight: FontWeight.w500,
),
),
],
);
}

Widget _buildIntroText() {
return Padding(
padding: const EdgeInsets.fromLTRB(20, 3, 20, 17),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Icon(
Icons.favorite_rounded,
size: 18,
color: AppColors.primary,
),
const SizedBox(width: 9),
Expanded(
child: Text(
'Every item you donate gets a second chance. '
'Track your pickups, status and rewards here.',
style: TextStyle(
fontSize: 12,
height: 1.5,
color: AppColors.textSecondary,
),
),
),
],
),
);
}

// --------------------------------------------------
// FILTER CHIPS
// --------------------------------------------------

Widget _buildFilterSection() {
return Padding(
padding: const EdgeInsets.only(bottom: 17),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Padding(
padding: EdgeInsets.fromLTRB(20, 0, 20, 11),
child: Text(
'Filter donations',
style: TextStyle(
color: AppColors.textPrimary,
fontSize: 15,
fontWeight: FontWeight.w800,
),
),
),
SizedBox(
height: 43,
child: ListView.separated(
padding: const EdgeInsets.symmetric(horizontal: 16),
scrollDirection: Axis.horizontal,
physics: const BouncingScrollPhysics(),
itemCount: _filters.length,
separatorBuilder: (_, __) =>
const SizedBox(width: 9),
itemBuilder: (context, index) {
final filter = _filters[index];
final selected = _selectedFilter == filter;

final count = filter == 'All'
? _donations.length
    : filter == 'Active'
? _activeCount
    : _completedCount;

return ChoiceChip(
showCheckmark: false,
selected: selected,
onSelected: (_) {
setState(() {
_selectedFilter = filter;
});
},
backgroundColor: AppColors.surface,
selectedColor: AppColors.primary,
side: BorderSide(
color: selected
? AppColors.primary
    : AppColors.accent.withOpacity(0.55),
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(30),
),
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 5,
),
label: Row(
mainAxisSize: MainAxisSize.min,
children: [
Text(
filter,
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w700,
color: selected
? Colors.white
    : AppColors.textSecondary,
),
),
const SizedBox(width: 7),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 6,
vertical: 3,
),
decoration: BoxDecoration(
color: selected
? Colors.white.withOpacity(0.18)
    : AppColors.light,
borderRadius: BorderRadius.circular(20),
),
child: Text(
'$count',
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w800,
color: selected
? Colors.white
    : AppColors.primary,
),
),
),
],
),
);
},
),
),
],
),
);
}

// --------------------------------------------------
// DONATION CARD
// --------------------------------------------------

Widget _buildDonationCard(
Map<String, dynamic> donation,
) {
final status = donation['status'].toString();
final image = donation['image'].toString();
final rewardPoints =
int.tryParse('${donation['rewardPoints'] ?? 0}') ?? 0;

return Container(
margin: const EdgeInsets.only(bottom: 14),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(21),
border: Border.all(
color: AppColors.accent.withOpacity(0.35),
),
boxShadow: [
BoxShadow(
color: AppColors.primary.withOpacity(0.045),
blurRadius: 14,
offset: const Offset(0, 5),
),
],
),
child: Material(
color: Colors.transparent,
borderRadius: BorderRadius.circular(21),
clipBehavior: Clip.antiAlias,
child: InkWell(
onTap: () async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => DonationDetails(
donation: donation,
),
),
);

if (mounted) {
_loadDonations();
}
},
child: Padding(
padding: const EdgeInsets.all(12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_buildDonationImage(image),
const SizedBox(width: 12),
Expanded(
child: _buildDonationInfo(
donation,
status,
),
),
],
),
const SizedBox(height: 13),
Divider(
height: 1,
thickness: 1,
color: AppColors.accent.withOpacity(0.25),
),
const SizedBox(height: 11),
Row(
children: [
const Icon(
Icons.calendar_month_outlined,
color: AppColors.textSecondary,
size: 15,
),
const SizedBox(width: 6),
Expanded(
child: Text(
donation['date'].toString(),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 10.5,
color: AppColors.textSecondary,
fontWeight: FontWeight.w500,
),
),
),
if (rewardPoints > 0)
Container(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 6,
),
decoration: BoxDecoration(
color: const Color(0xFFFFF5D8),
borderRadius: BorderRadius.circular(30),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.stars_rounded,
size: 14,
color: Color(0xFFB77900),
),
const SizedBox(width: 4),
Text(
'$rewardPoints points',
style: const TextStyle(
color: Color(0xFF946200),
fontSize: 10,
fontWeight: FontWeight.w800,
),
),
],
),
),
const SizedBox(width: 5),
const Icon(
Icons.arrow_forward_ios_rounded,
size: 12,
color: AppColors.textSecondary,
),
],
),
],
),
),
),
),
);
}

Widget _buildDonationImage(String image) {
return ClipRRect(
borderRadius: BorderRadius.circular(15),
child: SizedBox(
width: 88,
height: 100,
child: image.startsWith('http')
? Image.network(
image,
fit: BoxFit.cover,
loadingBuilder: (context, child, progress) {
if (progress == null) return child;

return _imagePlaceholder(
loading: true,
);
},
errorBuilder: (_, __, ___) =>
_imagePlaceholder(),
)
    : _imagePlaceholder(),
),
);
}

Widget _imagePlaceholder({bool loading = false}) {
return Container(
color: AppColors.light,
alignment: Alignment.center,
child: loading
? const SizedBox(
height: 22,
width: 22,
child: CircularProgressIndicator(
strokeWidth: 2,
color: AppColors.primary,
),
)
    : const Icon(
Icons.volunteer_activism_outlined,
color: AppColors.primary,
size: 31,
),
);
}

Widget _buildDonationInfo(
Map<String, dynamic> donation,
String status,
) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
donation['item'].toString(),
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 14,
height: 1.3,
fontWeight: FontWeight.w800,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 6),
Text(
donation['category'].toString(),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 11,
color: AppColors.textSecondary,
),
),
const SizedBox(height: 4),
Row(
children: [
const Icon(
Icons.recycling_rounded,
size: 13,
color: AppColors.primary,
),
const SizedBox(width: 4),
Expanded(
child: Text(
donation['condition'].toString(),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 10.5,
color: AppColors.textSecondary,
),
),
),
],
),
const SizedBox(height: 9),
_buildStatusBadge(status),
const SizedBox(height: 7),
Text(
'ID: ${donation['id']}',
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 9.5,
color: AppColors.textSecondary.withOpacity(0.9),
),
),
],
);
}

// --------------------------------------------------
// STATUS BADGE
// --------------------------------------------------

Widget _buildStatusBadge(String status) {
final normalized = status.toLowerCase();

final bool pending = [
'pending',
'pickup scheduled',
].contains(normalized);

final bool rejected = normalized == 'rejected';
final bool cancelled = normalized == 'cancelled';

final Color badgeColor = pending
? const Color(0xFFB77900)
    : rejected || cancelled
? AppColors.error
    : AppColors.success;

final Color badgeBackground = pending
? const Color(0xFFFFF4D6)
    : rejected || cancelled
? const Color(0xFFFFE9E9)
    : AppColors.light;

final IconData badgeIcon = pending
? Icons.schedule_rounded
    : rejected || cancelled
? Icons.cancel_outlined
    : Icons.check_circle_outline_rounded;

return Container(
padding: const EdgeInsets.symmetric(
horizontal: 9,
vertical: 5,
),
decoration: BoxDecoration(
color: badgeBackground,
borderRadius: BorderRadius.circular(30),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
badgeIcon,
size: 12,
color: badgeColor,
),
const SizedBox(width: 5),
Flexible(
child: Text(
status,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 9.5,
fontWeight: FontWeight.w800,
color: badgeColor,
),
),
),
],
),
);
}

// --------------------------------------------------
// ERROR STATE
// --------------------------------------------------

Widget _buildErrorState() {
return Center(
child: Padding(
padding: const EdgeInsets.all(28),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
width: 82,
height: 82,
decoration: BoxDecoration(
color: AppColors.light,
borderRadius: BorderRadius.circular(26),
),
child: const Icon(
Icons.cloud_off_rounded,
size: 39,
color: AppColors.primary,
),
),
const SizedBox(height: 19),
const Text(
'Could not load donations',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w800,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 9),
Text(
_error ?? 'Something went wrong. Please try again.',
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 12,
height: 1.5,
color: AppColors.textSecondary,
),
),
const SizedBox(height: 20),
ElevatedButton.icon(
onPressed: _loadDonations,
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
elevation: 0,
padding: const EdgeInsets.symmetric(
horizontal: 21,
vertical: 13,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
icon: const Icon(Icons.refresh_rounded, size: 18),
label: const Text('Try again'),
),
],
),
),
);
}

// --------------------------------------------------
// EMPTY STATE
// --------------------------------------------------

Widget _buildEmptyState() {
final bool filtered = _selectedFilter != 'All';

return Center(
child: Padding(
padding: const EdgeInsets.fromLTRB(32, 25, 32, 40),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
width: 105,
height: 105,
decoration: BoxDecoration(
color: AppColors.light,
shape: BoxShape.circle,
border: Border.all(
color: AppColors.accent.withOpacity(0.45),
width: 1.5,
),
),
child: const Icon(
Icons.volunteer_activism_rounded,
size: 46,
color: AppColors.primary,
),
),
const SizedBox(height: 22),
Text(
filtered
? 'No $_selectedFilter donations'
    : 'Your giving journey starts here',
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 19,
fontWeight: FontWeight.w800,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 10),
Text(
filtered
? 'There are no donations in this category yet. '
'Try another filter to see your donations.'
    : 'Your donated items and pickup updates will '
'appear here. Give useful things a new life '
'and make a difference.',
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 12,
height: 1.6,
color: AppColors.textSecondary,
),
),
if (filtered) ...[
const SizedBox(height: 19),
OutlinedButton(
onPressed: () {
setState(() {
_selectedFilter = 'All';
});
},
style: OutlinedButton.styleFrom(
foregroundColor: AppColors.primary,
side: const BorderSide(
color: AppColors.primary,
),
padding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 12,
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),
child: const Text(
'View all donations',
style: TextStyle(
fontWeight: FontWeight.w700,
),
),
),
],
],
),
),
);
}
}
