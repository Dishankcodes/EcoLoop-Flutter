
import 'package:flutter/material.dart';

import '../../../app_theme/user/app_colors.dart';
import '../../../services/ecoloop_api.dart';

class DonationDetails extends StatefulWidget {
final Map<String, dynamic> donation;

const DonationDetails({
super.key,
required this.donation,
});

@override
State<DonationDetails> createState() => _DonationDetailsState();
}

class _DonationDetailsState extends State<DonationDetails> {
late Map<String, dynamic> _donation;

bool _loading = false;
bool _requestingPickup = false;
String? _error;

Map<String, String> _categoryNames = {};

@override
void initState() {
super.initState();
_donation = _normalize(widget.donation);
_loadCategories();
_refreshDetails();
}

// --------------------------------------------------
// NORMALIZE DONATION DATA
// --------------------------------------------------

Map<String, dynamic> _normalize(
Map<String, dynamic> raw,
) {
final dynamic images = raw['imageUrls'];

String image = raw['image']?.toString() ?? '';

if (images is List && images.isNotEmpty) {
image = images.first.toString();
}

final rawStatus =
(raw['status'] ?? 'pending').toString();

final categoryId = raw['categoryId']?.toString();

final category = raw['category']?.toString() ??
raw['categoryName']?.toString() ??
(categoryId != null
? _categoryNames[categoryId]
    : null) ??
(categoryId == null
? 'Category unavailable'
    : 'Category $categoryId');

final createdAt = raw['createdAt']?.toString() ??
raw['date']?.toString() ??
'';

return {
...raw,
'id': raw['donationId']?.toString() ??
raw['id']?.toString() ??
'',
'item': raw['title']?.toString() ??
raw['item']?.toString() ??
'Donated Item',
'category': category,
'condition': _pretty(
raw['condition']?.toString() ?? 'used',
),
'status': _prettyStatus(rawStatus),
'rawStatus': rawStatus.toLowerCase(),
'image': image,
'date': _displayDate(createdAt),
'city': raw['city']?.toString() ?? '',
'state': raw['state']?.toString() ?? '',
'location': [
raw['city']?.toString(),
raw['state']?.toString(),
].where(
(part) => part != null && part.trim().isNotEmpty,
).join(', '),
'address': raw['address']?.toString() ?? '',
'description': raw['description']?.toString() ?? '',
'pickupDate': raw['pickupDate']?.toString() ?? '',
'rewardStatus': raw['rewardStatus']?.toString() ??
'Pending acceptance',
'rewardPoints': raw['rewardPoints'] ?? 0,
'rewardCredited': raw['rewardCredited'] == true ||
'${raw['rewardCredited']}'.toLowerCase() == 'true',
};
}

String _pretty(String value) {
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
return 'Pickup Requested';
case 'pickup scheduled':
case 'pickup_scheduled':
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
return _pretty(value);
}
}

String _displayDate(String raw) {
if (raw.trim().isEmpty) return 'Recently';

final parsed = DateTime.tryParse(raw.trim());

if (parsed == null) return raw;

const months = [
'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

// --------------------------------------------------
// LOAD CATEGORY NAMES
// --------------------------------------------------

Future<void> _loadCategories() async {
try {
final response =
await EcoLoopApi.instance.get('/categories');

final rows = response is List
? response
    : response is Map && response['categories'] is List
? response['categories'] as List
    : <dynamic>[];

final names = <String, String>{};

for (final row in rows.whereType<Map>()) {
final id = row['categoryId'] ?? row['id'];
final name = row['name'];

if (id != null && name != null) {
names[id.toString()] = name.toString();
}
}

if (!mounted) return;

setState(() {
_categoryNames = names;
_donation = _normalize(_donation);
});
} catch (_) {
// Keep the already-loaded donation visible.
}
}

// --------------------------------------------------
// REFRESH DETAILS
// --------------------------------------------------

Future<void> _refreshDetails() async {
final id = (_donation['id'] ?? '').toString();

if (id.isEmpty || int.tryParse(id) == null) {
if (mounted) {
setState(() => _loading = false);
}
return;
}

if (mounted) {
setState(() {
_loading = true;
_error = null;
});
}

try {
final response =
await EcoLoopApi.instance.get('/donations/$id');

Map<String, dynamic>? raw;

if (response is Map) {
if (response['donation'] is Map) {
raw = Map<String, dynamic>.from(
response['donation'] as Map,
);
} else if (response['data'] is Map) {
raw = Map<String, dynamic>.from(
response['data'] as Map,
);
} else {
raw = Map<String, dynamic>.from(response);
}
}

if (raw != null && mounted) {
setState(() {
_donation = _normalize(raw!);
_error = null;
});
}
} catch (e) {
if (mounted) {
setState(() {
_error = e.toString().replaceFirst(
'Exception: ',
'',
);
});
}
} finally {
if (mounted) {
setState(() => _loading = false);
}
}
}

// --------------------------------------------------
// REQUEST PICKUP
// --------------------------------------------------

bool get _pickupCanBeRequested {
final status =
(_donation['rawStatus'] ?? '').toString().toLowerCase();

return status == 'pending' || status == 'submitted';
}

Future<void> _requestPickup() async {
final id = (_donation['id'] ?? '').toString();

if (id.isEmpty || int.tryParse(id) == null) {
_showMessage('This donation has no valid ID.');
return;
}

if (_requestingPickup) return;

setState(() => _requestingPickup = true);

try {
await EcoLoopApi.instance.post(
'/donations/$id/pickup-request',
{},
);

if (!mounted) return;

_showMessage('Pickup request submitted successfully.');

await _refreshDetails();
} catch (e) {
if (mounted) {
_showMessage(
e.toString().replaceFirst('Exception: ', ''),
);
}
} finally {
if (mounted) {
setState(() => _requestingPickup = false);
}
}
}

void _showMessage(String message) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
behavior: SnackBarBehavior.floating,
backgroundColor: AppColors.primary,
),
);
}

// --------------------------------------------------
// MAIN UI
// --------------------------------------------------

@override
Widget build(BuildContext context) {
final status =
(_donation['status'] ?? 'Pending').toString();

return Scaffold(
backgroundColor: AppColors.background,
appBar: AppBar(
backgroundColor: AppColors.surface,
foregroundColor: AppColors.textPrimary,
elevation: 0,
scrolledUnderElevation: 0,
centerTitle: true,
title: const Text(
'Donation Details',
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w800,
),
),
actions: [
IconButton(
tooltip: 'Refresh details',
onPressed: _loading ? null : _refreshDetails,
icon: _loading
? const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(
strokeWidth: 2,
),
)
    : const Icon(Icons.refresh_rounded),
),
const SizedBox(width: 4),
],
),
body: RefreshIndicator(
color: AppColors.primary,
backgroundColor: AppColors.surface,
onRefresh: _refreshDetails,
child: ListView(
physics: const AlwaysScrollableScrollPhysics(
parent: BouncingScrollPhysics(),
),
padding: const EdgeInsets.only(bottom: 24),
children: [
_buildHero(status),

if (_error != null)
_buildRefreshWarning(),

_buildStatusSection(status),

_buildPickupSection(),

_buildDonationInformation(),

_buildRewardSection(),

if (_pickupCanBeRequested)
_buildPickupButton(),

_buildEcoLoopMessage(),
],
),
),
);
}

// --------------------------------------------------
// HERO / ITEM HEADER
// --------------------------------------------------

Widget _buildHero(String status) {
final image = (_donation['image'] ?? '').toString();

return Container(
margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(24),
border: Border.all(
color: AppColors.accent.withOpacity(0.4),
),
boxShadow: [
BoxShadow(
color: AppColors.primary.withOpacity(0.06),
blurRadius: 16,
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
SizedBox(
width: double.infinity,
height: 205,
child: image.startsWith('http')
? Image.network(
image,
fit: BoxFit.cover,
loadingBuilder: (context, child, progress) {
if (progress == null) return child;

return _imagePlaceholder(
height: 205,
loading: true,
);
},
errorBuilder: (_, __, ___) =>
_imagePlaceholder(height: 205),
)
    : _imagePlaceholder(height: 205),
),
Positioned(
top: 14,
left: 14,
child: Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 8,
),
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.94),
borderRadius: BorderRadius.circular(30),
),
child: const Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.eco_rounded,
color: AppColors.primary,
size: 15,
),
SizedBox(width: 5),
Text(
'ECOLOOP DONATION',
style: TextStyle(
fontSize: 9,
letterSpacing: 0.7,
fontWeight: FontWeight.w800,
color: AppColors.primary,
),
),
],
),
),
),
Positioned(
right: 14,
bottom: 14,
child: _statusBadge(status),
),
],
),
Padding(
padding: const EdgeInsets.fromLTRB(17, 17, 17, 19),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
(_donation['item'] ?? 'Donated Item').toString(),
style: const TextStyle(
fontSize: 22,
height: 1.2,
fontWeight: FontWeight.w800,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 10),
Wrap(
spacing: 7,
runSpacing: 7,
children: [
_smallTag(
Icons.category_outlined,
(_donation['category'] ?? 'Other').toString(),
),
_smallTag(
Icons.checkroom_outlined,
(_donation['condition'] ?? 'Used').toString(),
),
],
),
const SizedBox(height: 16),
Divider(
height: 1,
color: AppColors.accent.withOpacity(0.4),
),
const SizedBox(height: 13),
Row(
children: [
const Icon(
Icons.confirmation_number_outlined,
color: AppColors.primary,
size: 17,
),
const SizedBox(width: 8),
const Text(
'Donation ID',
style: TextStyle(
fontSize: 11,
color: AppColors.textSecondary,
),
),
const Spacer(),
Flexible(
child: Text(
(_donation['id'] ?? '—').toString(),
textAlign: TextAlign.right,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w800,
color: AppColors.textPrimary,
),
),
),
],
),
const SizedBox(height: 11),
Row(
children: [
const Icon(
Icons.calendar_month_outlined,
color: AppColors.primary,
size: 17,
),
const SizedBox(width: 8),
const Text(
'Date submitted',
style: TextStyle(
fontSize: 11,
color: AppColors.textSecondary,
),
),
const Spacer(),
Flexible(
child: Text(
(_donation['date'] ?? 'Recently').toString(),
textAlign: TextAlign.right,
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.w700,
color: AppColors.textPrimary,
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
);
}

Widget _smallTag(IconData icon, String label) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 7,
),
decoration: BoxDecoration(
color: AppColors.light,
borderRadius: BorderRadius.circular(10),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, size: 14, color: AppColors.primary),
const SizedBox(width: 5),
Text(
label,
style: const TextStyle(
fontSize: 10,
fontWeight: FontWeight.w700,
color: AppColors.primary,
),
),
],
),
);
}

Widget _imagePlaceholder({
double height = 105,
bool loading = false,
}) {
return Container(
height: height,
width: double.infinity,
color: AppColors.light,
alignment: Alignment.center,
child: loading
? const CircularProgressIndicator(
strokeWidth: 2,
color: AppColors.primary,
)
    : const Icon(
Icons.volunteer_activism_outlined,
size: 49,
color: AppColors.primary,
),
);
}

// --------------------------------------------------
// STATUS BADGE
// --------------------------------------------------

Widget _statusBadge(String status) {
final lower = status.toLowerCase();

final pending = [
'pending',
'pickup requested',
'pickup scheduled',
].contains(lower);

final failed = [
'rejected',
'cancelled',
].contains(lower);

final color = pending
? const Color(0xFF9A6900)
    : failed
? AppColors.error
    : AppColors.success;

final background = pending
? const Color(0xFFFFF3D3)
    : failed
? const Color(0xFFFFE7E7)
    : const Color(0xFFE8F5E9);

return Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 8,
),
decoration: BoxDecoration(
color: background,
borderRadius: BorderRadius.circular(30),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
pending
? Icons.schedule_rounded
    : failed
? Icons.cancel_outlined
    : Icons.check_circle_rounded,
color: color,
size: 14,
),
const SizedBox(width: 6),
Text(
status,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.w800,
color: color,
),
),
],
),
);
}

// --------------------------------------------------
// REFRESH WARNING
// --------------------------------------------------

Widget _buildRefreshWarning() {
return Container(
margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: const Color(0xFFFFF4D9),
borderRadius: BorderRadius.circular(13),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Icon(
Icons.info_outline_rounded,
size: 19,
color: Color(0xFF946200),
),
const SizedBox(width: 9),
Expanded(
child: Text(
'Showing saved details. Latest update could not be loaded.',
style: const TextStyle(
fontSize: 11,
height: 1.4,
color: Color(0xFF805800),
),
),
),
TextButton(
onPressed: _refreshDetails,
child: const Text('Retry'),
),
],
),
);
}

// --------------------------------------------------
// DONATION STATUS TIMELINE
// --------------------------------------------------

Widget _buildStatusSection(String status) {
final lower =
(_donation['rawStatus'] ?? status).toString().toLowerCase();

final rejected = lower == 'rejected';
final cancelled = lower == 'cancelled';

final pickupRequested = [
'pickup_requested',
'requested',
'pickup scheduled',
'pickup_scheduled',
'picked_up',
'collected',
'completed',
'accepted',
'approved',
].contains(lower);

final collected = [
'picked_up',
'collected',
'completed',
].contains(lower);

return _section(
title: 'Donation Progress',
subtitle: 'Follow the journey of your donated item.',
icon: Icons.timeline_rounded,
child: Column(
children: [
_timelineStep(
icon: Icons.volunteer_activism_rounded,
title: 'Donation submitted',
subtitle: 'Your donation has been recorded.',
completed: true,
active: false,
last: false,
),
_timelineStep(
icon: Icons.fact_check_outlined,
title: 'Review and pickup',
subtitle: rejected
? 'This donation was rejected.'
    : cancelled
? 'This donation was cancelled.'
    : collected
? 'Your item has been collected.'
    : pickupRequested
? status
    : 'Waiting for pickup request or review.',
completed: collected || pickupRequested,
active: !rejected &&
!cancelled &&
!collected &&
pickupRequested,
last: false,
failed: rejected || cancelled,
),
_timelineStep(
icon: Icons.check_circle_outline_rounded,
title: 'Donation completed',
subtitle: collected
? 'Your item has been collected successfully.'
    : 'This step is complete after collection.',
completed: collected,
active: false,
last: true,
),
],
),
);
}

Widget _timelineStep({
required IconData icon,
required String title,
required String subtitle,
required bool completed,
required bool active,
required bool last,
bool failed = false,
}) {
final color = failed
? AppColors.error
    : completed || active
? AppColors.primary
    : AppColors.textSecondary;

return IntrinsicHeight(
child: Row(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
SizedBox(
width: 42,
child: Column(
children: [
Container(
height: 38,
width: 38,
decoration: BoxDecoration(
color: failed
? const Color(0xFFFFE7E7)
    : completed || active
? AppColors.light
    : AppColors.background,
shape: BoxShape.circle,
),
child: Icon(icon, color: color, size: 19),
),
if (!last)
Expanded(
child: Container(
width: 2,
margin: const EdgeInsets.symmetric(vertical: 3),
color: completed
? AppColors.accent
    : AppColors.background,
),
),
],
),
),
const SizedBox(width: 10),
Expanded(
child: Padding(
padding: EdgeInsets.only(
top: 3,
bottom: last ? 0 : 22,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: TextStyle(
fontSize: 13,
fontWeight: completed || active
? FontWeight.w800
    : FontWeight.w600,
color: failed
? AppColors.error
    : AppColors.textPrimary,
),
),
const SizedBox(height: 5),
Text(
subtitle,
style: const TextStyle(
fontSize: 11,
height: 1.45,
color: AppColors.textSecondary,
),
),
],
),
),
),
],
),
);
}

// --------------------------------------------------
// PICKUP INFORMATION
// --------------------------------------------------

Widget _buildPickupSection() {
final addressParts = [
_donation['address']?.toString(),
_donation['city']?.toString(),
_donation['state']?.toString(),
].where(
(part) => part != null && part.trim().isNotEmpty,
).toList();

final location = addressParts.join(', ');

final rawPickupDate =
(_donation['pickupDate'] ?? '').toString();

final pickupDate = rawPickupDate.isEmpty
? 'Not scheduled'
    : _displayDate(rawPickupDate);

return _section(
title: 'Pickup Information',
subtitle: 'Collection details for your donation.',
icon: Icons.local_shipping_outlined,
child: Column(
children: [
_infoRow(
Icons.calendar_month_outlined,
'Pickup date',
pickupDate,
),
_infoRow(
Icons.location_on_outlined,
'Pickup address',
location.isEmpty ? 'Address not available' : location,
),
_infoRow(
Icons.local_shipping_outlined,
'Collection',
'Free EcoLoop pickup',
),
const SizedBox(height: 5),
Container(
width: double.infinity,
padding: const EdgeInsets.all(13),
decoration: BoxDecoration(
color: AppColors.light,
borderRadius: BorderRadius.circular(14),
),
child: const Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
Icons.tips_and_updates_outlined,
color: AppColors.primary,
size: 19,
),
SizedBox(width: 9),
Expanded(
child: Text(
'Pickup timing is confirmed by the EcoLoop team. '
'Keep your item ready once your pickup is confirmed.',
style: TextStyle(
fontSize: 11,
height: 1.5,
color: AppColors.textSecondary,
),
),
),
],
),
),
],
),
);
}

// --------------------------------------------------
// DONATION INFORMATION
// --------------------------------------------------

Widget _buildDonationInformation() {
final description =
(_donation['description'] ?? '').toString();

return _section(
title: 'Item Information',
subtitle: 'Details provided with your donation.',
icon: Icons.inventory_2_outlined,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_infoRow(
Icons.category_outlined,
'Category',
(_donation['category'] ?? 'Other').toString(),
),
_infoRow(
Icons.check_circle_outline_rounded,
'Condition',
(_donation['condition'] ?? 'Used').toString(),
),
_infoRow(
Icons.calendar_today_outlined,
'Submitted',
(_donation['date'] ?? 'Recently').toString(),
),
_infoRow(
Icons.tag_rounded,
'Donation ID',
(_donation['id'] ?? '—').toString(),
),
if (description.trim().isNotEmpty) ...[
const SizedBox(height: 5),
const Text(
'Description',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w800,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 8),
Container(
width: double.infinity,
padding: const EdgeInsets.all(13),
decoration: BoxDecoration(
color: AppColors.background,
borderRadius: BorderRadius.circular(13),
),
child: Text(
description,
style: const TextStyle(
fontSize: 12,
height: 1.6,
color: AppColors.textSecondary,
),
),
),
],
],
),
);
}

// --------------------------------------------------
// REWARD INFORMATION
// --------------------------------------------------

Widget _buildRewardSection() {
final status =
(_donation['rawStatus'] ?? '').toString().toLowerCase();

final accepted = [
'accepted',
'approved',
'completed',
'collected',
'picked_up',
].contains(status);

final rejected = status == 'rejected';

final credited = _donation['rewardCredited'] == true;

final points =
int.tryParse('${_donation['rewardPoints'] ?? 0}') ?? 0;

final title = rejected
? 'Donation not eligible'
    : credited
? 'Rewards credited'
    : accepted
? 'Donation accepted'
    : 'Rewards pending';

final message = rejected
? 'This donation was rejected and is not eligible for rewards.'
    : credited
? '$points Eco Points have been credited for this donation.'
    : accepted
? 'Your donation has been accepted. Check your Rewards page for the latest points balance.'
    : 'Your donation is awaiting review. Rewards are subject to donation approval.';

final color = rejected
? AppColors.error
    : credited
? AppColors.success
    : AppColors.primary;

return _section(
title: 'EcoLoop Rewards',
subtitle: 'Your contribution to a greener community.',
icon: Icons.card_giftcard_rounded,
child: Container(
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
color: AppColors.light,
borderRadius: BorderRadius.circular(17),
border: Border.all(
color: AppColors.accent.withOpacity(0.45),
),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
height: 48,
width: 48,
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(15),
),
child: Icon(
Icons.stars_rounded,
color: color,
size: 26,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w800,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 6),
Text(
message,
style: const TextStyle(
fontSize: 11,
height: 1.5,
color: AppColors.textSecondary,
),
),
if (points > 0) ...[
const SizedBox(height: 11),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 11,
vertical: 7,
),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(30),
),
child: Row(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.stars_rounded,
size: 16,
color: Color(0xFFB77900),
),
const SizedBox(width: 6),
Text(
'$points Eco Points',
style: const TextStyle(
fontSize: 11,
fontWeight: FontWeight.w800,
color: AppColors.primary,
),
),
],
),
),
],
],
),
),
],
),
),
);
}

// --------------------------------------------------
// PICKUP BUTTON
// --------------------------------------------------

Widget _buildPickupButton() {
return Padding(
padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
SizedBox(
height: 54,
child: ElevatedButton.icon(
onPressed:
_requestingPickup ? null : _requestPickup,
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.primary,
foregroundColor: Colors.white,
disabledBackgroundColor:
AppColors.primary.withOpacity(0.55),
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(17),
),
),
icon: _requestingPickup
? const SizedBox(
height: 19,
width: 19,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Icon(
Icons.local_shipping_outlined,
size: 21,
),
label: Text(
_requestingPickup
? 'Requesting pickup...'
    : 'Request Free Pickup',
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.w800,
),
),
),
),
const SizedBox(height: 10),
const Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.verified_user_outlined,
size: 14,
color: AppColors.textSecondary,
),
SizedBox(width: 6),
Flexible(
child: Text(
'Pickup is free and subject to confirmation.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 10,
color: AppColors.textSecondary,
),
),
),
],
),
],
),
);
}

// --------------------------------------------------
// FOOTER MESSAGE
// --------------------------------------------------

Widget _buildEcoLoopMessage() {
return Padding(
padding: const EdgeInsets.fromLTRB(22, 7, 22, 16),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Icon(
Icons.eco_rounded,
size: 21,
color: AppColors.success,
),
const SizedBox(width: 9),
Expanded(
child: Text(
'Thank you for giving your item another life. '
'Every donation helps reduce waste and supports '
'a more circular community.',
style: TextStyle(
fontSize: 11,
height: 1.55,
color: AppColors.textSecondary,
),
),
),
],
),
);
}

// --------------------------------------------------
// REUSABLE SECTION CARD
// --------------------------------------------------

Widget _section({
required String title,
required String subtitle,
required IconData icon,
required Widget child,
}) {
return Container(
width: double.infinity,
margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
padding: const EdgeInsets.all(17),
decoration: BoxDecoration(
color: AppColors.surface,
borderRadius: BorderRadius.circular(21),
border: Border.all(
color: AppColors.accent.withOpacity(0.32),
),
boxShadow: [
BoxShadow(
color: AppColors.primary.withOpacity(0.035),
blurRadius: 12,
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
height: 39,
width: 39,
decoration: BoxDecoration(
color: AppColors.light,
borderRadius: BorderRadius.circular(12),
),
child: Icon(
icon,
size: 20,
color: AppColors.primary,
),
),
const SizedBox(width: 11),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w800,
color: AppColors.textPrimary,
),
),
const SizedBox(height: 4),
Text(
subtitle,
style: const TextStyle(
fontSize: 10.5,
height: 1.4,
color: AppColors.textSecondary,
),
),
],
),
),
],
),
const SizedBox(height: 19),
child,
],
),
);
}

// --------------------------------------------------
// INFORMATION ROW
// --------------------------------------------------

Widget _infoRow(
IconData icon,
String title,
String value,
) {
return Padding(
padding: const EdgeInsets.only(bottom: 15),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(
icon,
size: 18,
color: AppColors.primary,
),
const SizedBox(width: 10),
SizedBox(
width: 95,
child: Text(
title,
style: const TextStyle(
fontSize: 11,
height: 1.5,
color: AppColors.textSecondary,
),
),
),
const SizedBox(width: 8),
Expanded(
child: Text(
value,
textAlign: TextAlign.right,
style: const TextStyle(
fontSize: 11,
height: 1.5,
fontWeight: FontWeight.w700,
color: AppColors.textPrimary,
),
),
),
],
),
);
}
}