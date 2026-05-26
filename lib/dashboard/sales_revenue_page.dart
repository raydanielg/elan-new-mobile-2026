import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../sales/create.dart';
import '../sales/sales_page.dart';
import '../widgets/app_header.dart';

class SalesRevenuePage extends StatefulWidget {
  const SalesRevenuePage({
    super.key,
    this.userId,
    this.shopId,
  });

  final String? userId;
  final String? shopId;

  @override
  State<SalesRevenuePage> createState() => _SalesRevenuePageState();
}

class _SalesRevenuePageState extends State<SalesRevenuePage> {
  bool _loading = false;
  String? _error;
  List<_SaleRecord> _sales = const [];
  Map<String, dynamic> _summary = const {};
  String? _userId;
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _shopId = widget.shopId;
    _fetch();
  }

  Future<void> _fetchContext() async {
    try {
      final sessionUserRaw = await ApiService.instance.app.getData('session_user');
      final sessionShopRaw = await ApiService.instance.app.getData('session_shop');
      if (!mounted) return;

      String? userId;
      String? shopId;

      if (sessionUserRaw is Map) {
        final data =
            (sessionUserRaw['data'] is Map) ? sessionUserRaw['data'] as Map : sessionUserRaw;
        userId = data['user_id']?.toString() ?? data['id']?.toString();
      }

      if (sessionShopRaw is Map) {
        final data =
            (sessionShopRaw['data'] is Map) ? sessionShopRaw['data'] as Map : sessionShopRaw;
        shopId = data['shop_id']?.toString() ??
            data['id']?.toString() ??
            data['session_shop_id']?.toString();
      }

      setState(() {
        _userId ??= userId?.trim().isEmpty == true ? null : userId?.trim();
        _shopId ??= shopId?.trim().isEmpty == true ? null : shopId?.trim();
      });
    } catch (_) {}
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_userId == null || _shopId == null) {
        await _fetchContext();
      }

      final qp = <String, dynamic>{
        if (_userId != null) 'user_id': _userId,
        if (_shopId != null) 'shop_id': _shopId,
      };

      final salesRaw = await ApiService.instance.client.getRawJson(
        '/app/get/getdata/sales',
        queryParameters: qp.isEmpty ? null : qp,
      );

      dynamic summaryRaw;
      try {
        summaryRaw = await ApiService.instance.client.getRawJson(
          '/app/get/getdata/sales_summary',
          queryParameters: qp.isEmpty ? null : qp,
        );
      } catch (_) {
        summaryRaw = const {};
      }

      if (!mounted) return;
      setState(() {
        _sales = _parseSales(salesRaw);
        _summary = _normalizeMap(summaryRaw);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Map<String, dynamic> _normalizeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  List<_SaleRecord> _parseSales(dynamic raw) {
    dynamic data = raw;
    if (raw is Map) {
      data = raw['data'] ?? raw['rows'] ?? raw['list'] ?? raw['result'] ?? raw;
    }
    if (data is Map) {
      data = data['data'] ?? data['rows'] ?? data['list'] ?? data['result'] ?? data;
    }

    final out = <_SaleRecord>[];
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final customer = item['customer_name']?.toString() ??
            item['customer']?.toString() ??
            item['name']?.toString() ??
            'Customer';
        final amount = _asDouble(
          item['amount'] ??
              item['total_amount'] ??
              item['grand_total'] ??
              item['total'] ??
              item['sale_amount'],
        );
        final rawDate =
            item['created_at'] ?? item['date'] ?? item['sale_date'] ?? item['createdAt'];
        out.add(
          _SaleRecord(
            customer: customer.trim().isEmpty ? 'Customer' : customer.trim(),
            amount: amount,
            dateLabel: rawDate?.toString() ?? '',
          ),
        );
      }
    }
    return out;
  }

  double _asDouble(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().replaceAll(',', '').trim()) ?? 0;
  }

  double _pick(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final value = _asDouble(candidate);
      if (value != 0) return value;
    }
    return candidates.isEmpty ? 0 : _asDouble(candidates.first);
  }

  String _money(num value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final totalRevenue = _pick([
      _summary['total_sales'],
      _summary['sales_total'],
      _summary['total_amount'],
      _summary['grand_total'],
      _sales.fold<double>(0, (sum, sale) => sum + sale.amount),
    ]);
    final todayRevenue = _pick([
      _summary['today_sales'],
      _summary['todays_sales'],
      _summary['today_total'],
    ]);
    final averageSale = _sales.isEmpty ? 0 : totalRevenue / _sales.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Sales Revenue',
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateSalePage()),
          );
          if (!mounted || created != true) return;
          await _fetch();
        },
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New sale'),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _RevenueMetricCard(
                      title: 'Total Revenue',
                      value: _loading ? '...' : _money(totalRevenue),
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RevenueMetricCard(
                      title: 'Today',
                      value: _loading ? '...' : _money(todayRevenue),
                      icon: Icons.today_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RevenueMetricCard(
                      title: 'Transactions',
                      value: _loading ? '...' : _sales.length.toString(),
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RevenueMetricCard(
                      title: 'Average Sale',
                      value: _loading ? '...' : _money(averageSale),
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _RevenueSectionCard(
                title: 'Recent sales',
                subtitle: 'Using `/app/get/getdata/sales` and `/app/get/getdata/sales_summary`.',
                trailing: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SalesPage()),
                    );
                  },
                  child: const Text('Open sales'),
                ),
                child: _error != null
                    ? _RevenueError(message: _error!, onRetry: _fetch)
                    : _loading
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _sales.isEmpty
                            ? const _RevenueEmpty(
                                title: 'No sales yet',
                                message: 'Sales revenue will appear here after records are added.',
                              )
                            : Column(
                                children: _sales.take(8).map((sale) {
                                  return _RevenueListRow(
                                    title: sale.customer,
                                    subtitle: sale.dateLabel.isEmpty ? 'Sale record' : sale.dateLabel,
                                    trailing: _money(sale.amount),
                                  );
                                }).toList(),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaleRecord {
  const _SaleRecord({
    required this.customer,
    required this.amount,
    required this.dateLabel,
  });

  final String customer;
  final double amount;
  final String dateLabel;
}

class _RevenueMetricCard extends StatelessWidget {
  const _RevenueMetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueSectionCard extends StatelessWidget {
  const _RevenueSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RevenueListRow extends StatelessWidget {
  const _RevenueListRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            trailing,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueError extends StatelessWidget {
  const _RevenueError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, style: const TextStyle(color: Color(0xFFB91C1C))),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class _RevenueEmpty extends StatelessWidget {
  const _RevenueEmpty({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.bar_chart_rounded, size: 32, color: Color(0xFF94A3B8)),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}
