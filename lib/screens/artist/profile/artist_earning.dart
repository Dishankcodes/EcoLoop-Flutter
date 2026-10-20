import 'package:flutter/material.dart';

import '../../../app_theme/artist/artist_colors.dart';
import '../../../app_theme/artist/artist_text_styles.dart';
import '../../../services/ecoloop_api.dart';
import '../../../widgets/artist_more_menu.dart';

/// Live artist earnings from GET /artist/analytics/earnings.
/// This screen deliberately shows only backend-confirmed paid transactions;
/// it does not estimate pending payouts or invent demo earnings.
class ArtistEarnings extends StatefulWidget {
  const ArtistEarnings({super.key});

  @override
  State<ArtistEarnings> createState() => _ArtistEarningsState();
}

class _ArtistEarningsState extends State<ArtistEarnings> {
  final EcoLoopApi _api = EcoLoopApi.instance;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  double _total = 0;
  List<Map<String, dynamic>> _transactions = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    final map = _asMap(value);
    for (final key in const ['transactions', 'items', 'results', 'data']) {
      final nested = map[key];
      if (nested is List) return nested;
      if (nested is Map) {
        final found = _asList(nested);
        if (found.isNotEmpty) return found;
      }
    }
    return <dynamic>[];
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().replaceAll(',', '')) ?? 0;
  }

  String _text(dynamic value, {String fallback = ''}) {
    final result = (value ?? '').toString().trim();
    return result.isEmpty ? fallback : result;
  }

  DateTime? _date(dynamic value) {
    final raw = _text(value);
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  Future<void> _loadEarnings({bool refresh = false}) async {
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
      final response = _asMap(await _api.get('/artist/analytics/earnings'));
      final transactions = _asList(response['transactions'])
          .whereType<Map>()
          .map((row) => _asMap(row))
          .toList();
      transactions.sort((a, b) {
        final ad = _date(a['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = _date(b['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      if (!mounted) return;
      setState(() {
        _total = _number(response['totalEarnings']);
        _transactions = transactions;
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double get _thisMonthTotal {
    final now = DateTime.now();
    return _transactions.where((row) {
      final date = _date(row['verifiedAt'] ?? row['createdAt']);
      return date != null && date.year == now.year && date.month == now.month;
    }).fold<double>(0, (sum, row) => sum + _number(row['amount']));
  }

  List<Map<String, dynamic>> get _visibleTransactions {
    if (_filter == 'This month') {
      final now = DateTime.now();
      return _transactions.where((row) {
        final date = _date(row['verifiedAt'] ?? row['createdAt']);
        return date != null && date.year == now.year && date.month == now.month;
      }).toList();
    }
    return _transactions;
  }

  String _money(num amount) => '₹${amount.toStringAsFixed(2)}';

  String _formatDate(dynamic value) {
    final date = _date(value);
    if (date == null) return 'Date unavailable';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month - 1]} ${date.year} · $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArtistColors.background,
      appBar: AppBar(
        backgroundColor: ArtistColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Earnings', style: ArtistTextStyles.title),
        actions: const [ArtistMoreMenu(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: ArtistColors.primary))
            : RefreshIndicator(
          color: ArtistColors.primary,
          onRefresh: () => _loadEarnings(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              if (_error != null) ...[
                _ErrorCard(message: _error!, onRetry: () => _loadEarnings(refresh: true)),
                const SizedBox(height: 14),
              ],
              _buildHero(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _MetricCard(
                    icon: Icons.calendar_month_rounded,
                    label: 'This month',
                    value: _money(_thisMonthTotal),
                    caption: 'Paid transactions',
                  )),
                  const SizedBox(width: 11),
                  Expanded(child: _MetricCard(
                    icon: Icons.receipt_long_rounded,
                    label: 'Transactions',
                    value: _transactions.length.toString(),
                    caption: 'Confirmed payments',
                  )),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Text('Payment history', style: ArtistTextStyles.title.copyWith(fontSize: 18))),
                  if (_refreshing)
                    const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: ArtistColors.primary)),
                ],
              ),
              const SizedBox(height: 5),
              Text('Your recorded successful payments, newest first.', style: ArtistTextStyles.caption),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  _FilterChip(label: 'All', selected: _filter == 'All', onTap: () => setState(() => _filter = 'All')),
                  _FilterChip(label: 'This month', selected: _filter == 'This month', onTap: () => setState(() => _filter = 'This month')),
                ],
              ),
              const SizedBox(height: 12),
              if (_visibleTransactions.isEmpty)
                _buildEmptyState()
              else
                ..._visibleTransactions.map(_buildTransaction),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: ArtistColors.light.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: ArtistColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: ArtistColors.primary, size: 19),
                    const SizedBox(width: 9),
                    Expanded(child: Text(
                      'Amounts shown here come from payment records marked as paid. This screen does not represent a bank balance or a payout that has not been recorded by EcoLoop.',
                      style: ArtistTextStyles.caption.copyWith(height: 1.45, color: ArtistColors.textSecondary),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 21, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArtistColors.primary, ArtistColors.primary.withOpacity(0.88), const Color(0xFF315A4B)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: ArtistColors.primary.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 9))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 43, height: 43,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white.withOpacity(0.17))),
            child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total recorded earnings', style: ArtistTextStyles.bodyMedium.copyWith(color: Colors.white.withOpacity(0.83), fontSize: 13)),
            const SizedBox(height: 3),
            Text('From successful payments', style: ArtistTextStyles.small.copyWith(color: Colors.white.withOpacity(0.68))),
          ])),
          const Icon(Icons.trending_up_rounded, color: Color(0xFFC1C8C4), size: 24),
        ]),
        const SizedBox(height: 23),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(_money(_total), style: const TextStyle(color: Colors.white, fontSize: 35, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
        ),
        const SizedBox(height: 17),
        Container(height: 1, color: Colors.white.withOpacity(0.18)),
        const SizedBox(height: 13),
        Row(children: [
          const Icon(Icons.verified_rounded, color: Color(0xFFC1C8C4), size: 17),
          const SizedBox(width: 7),
          Expanded(child: Text('Live data from your artist account', style: ArtistTextStyles.small.copyWith(color: Colors.white.withOpacity(0.88)))),
          IconButton(
            onPressed: () => _loadEarnings(refresh: true),
            tooltip: 'Refresh earnings',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
          ),
        ]),
      ]),
    );
  }

  Widget _buildTransaction(Map<String, dynamic> row) {
    final amount = _number(row['amount']);
    final paymentId = _text(row['paymentId'], fallback: '—');
    final orderId = _text(row['orderId'], fallback: '—');
    final method = _text(row['method'], fallback: 'Payment');
    final gateway = _text(row['gateway']);
    final reference = gateway.isNotEmpty ? '$method · $gateway' : method;
    final dateValue = row['verifiedAt'] ?? row['createdAt'];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: ArtistColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: ArtistColors.border)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 43, height: 43,
          decoration: BoxDecoration(color: ArtistColors.light, borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.south_west_rounded, color: ArtistColors.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(reference, maxLines: 1, overflow: TextOverflow.ellipsis, style: ArtistTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: ArtistColors.textPrimary)),
          const SizedBox(height: 4),
          Text(_formatDate(dateValue), style: ArtistTextStyles.small.copyWith(color: ArtistColors.textSecondary)),
          const SizedBox(height: 7),
          Wrap(spacing: 6, runSpacing: 5, children: [
            _MetaPill(label: 'Order #$orderId'),
            _MetaPill(label: 'Payment #$paymentId'),
          ]),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('+${_money(amount)}', style: ArtistTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800, color: ArtistColors.primary, fontSize: 14)),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE6F2EA), borderRadius: BorderRadius.circular(20)),
            child: const Text('PAID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF276343), letterSpacing: 0.5)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      decoration: BoxDecoration(color: ArtistColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: ArtistColors.border)),
      child: Column(children: [
        Container(width: 62, height: 62, decoration: BoxDecoration(color: ArtistColors.light, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.receipt_long_outlined, color: ArtistColors.primary, size: 29)),
        const SizedBox(height: 14),
        Text(_filter == 'This month' ? 'No payments this month' : 'No earnings recorded yet', textAlign: TextAlign.center, style: ArtistTextStyles.title.copyWith(fontSize: 16)),
        const SizedBox(height: 6),
        Text(_filter == 'This month' ? 'Successful payments from this month will appear here.' : 'When a payment for one of your sales is marked as paid, its details will appear here.', textAlign: TextAlign.center, style: ArtistTextStyles.caption.copyWith(height: 1.45)),
        if (_filter == 'This month' && _transactions.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: () => setState(() => _filter = 'All'), child: const Text('View all payments')),
        ],
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value, required this.caption});
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 124),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: ArtistColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: ArtistColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 18, color: ArtistColors.primary), const SizedBox(width: 7), Expanded(child: Text(label, style: ArtistTextStyles.caption.copyWith(fontWeight: FontWeight.w600))) ]),
      const SizedBox(height: 12),
      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: ArtistTextStyles.title.copyWith(fontSize: 21, fontWeight: FontWeight.w800))),
      const SizedBox(height: 4),
      Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: ArtistTextStyles.small.copyWith(color: ArtistColors.textSecondary)),
    ]),
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? ArtistColors.primary : ArtistColors.surface,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: selected ? ArtistColors.primary : ArtistColors.border)),
        child: Text(label, style: ArtistTextStyles.caption.copyWith(color: selected ? Colors.white : ArtistColors.textSecondary, fontWeight: FontWeight.w700)),
      ),
    ),
  );
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(color: ArtistColors.background, borderRadius: BorderRadius.circular(7)),
    child: Text(label, style: ArtistTextStyles.small.copyWith(fontSize: 9, color: ArtistColors.textSecondary)),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(color: ArtistColors.error.withOpacity(0.07), borderRadius: BorderRadius.circular(13), border: Border.all(color: ArtistColors.error.withOpacity(0.25))),
    child: Row(children: [
      const Icon(Icons.cloud_off_outlined, color: ArtistColors.error),
      const SizedBox(width: 9),
      Expanded(child: Text(message, style: ArtistTextStyles.caption.copyWith(color: ArtistColors.textPrimary))),
      IconButton(onPressed: onRetry, tooltip: 'Retry', icon: const Icon(Icons.refresh_rounded, color: ArtistColors.primary)),
    ]),
  );
}
