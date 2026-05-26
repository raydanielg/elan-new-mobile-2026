import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class ServicesRevenuePage extends StatefulWidget {
  const ServicesRevenuePage({
    super.key,
    this.userId,
    this.shopId,
  });

  final String? userId;
  final String? shopId;

  @override
  State<ServicesRevenuePage> createState() => _ServicesRevenuePageState();
}

class _ServicesRevenuePageState extends State<ServicesRevenuePage> {
  bool _loading = false;
  String? _error;
  List<_ServiceRevenueItem> _services = const [];
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

      dynamic raw;
      try {
        raw = await ApiService.instance.client.getRawJson(
          '/app/get/getreport/serviceSales',
          queryParameters: qp.isEmpty ? null : qp,
        );
      } catch (_) {
        raw = await ApiService.instance.client.getRawJson(
          '/app/get/getreport/topServices',
          queryParameters: qp.isEmpty ? null : qp,
        );
      }

      if (!mounted) return;
      setState(() {
        _services = _parseServices(raw);
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

  List<_ServiceRevenueItem> _parseServices(dynamic raw) {
    dynamic data = raw;
    if (raw is Map) {
      data = raw['data'] ?? raw['rows'] ?? raw['result'] ?? raw['list'] ?? raw;
    }
    if (data is Map) {
      data = data['data'] ?? data['rows'] ?? data['result'] ?? data['list'] ?? data;
    }

    final out = <_ServiceRevenueItem>[];
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final name = item['service_name']?.toString() ??
            item['name']?.toString() ??
            item['product_name']?.toString() ??
            'Service';
        final count = _asDouble(
          item['count'] ?? item['qty'] ?? item['quantity'] ?? item['total_orders'],
        );
        final revenue = _asDouble(
          item['amount'] ??
              item['total'] ??
              item['revenue'] ??
              item['total_amount'] ??
              item['grand_total'],
        );
        out.add(
          _ServiceRevenueItem(
            name: name.trim().isEmpty ? 'Service' : name.trim(),
            count: count,
            revenue: revenue,
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

  String _money(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final totalRevenue =
        _services.fold<double>(0, (sum, service) => sum + service.revenue);
    final totalCount = _services.fold<double>(0, (sum, service) => sum + service.count);
    final topService = _services.isEmpty
        ? null
        : (_services.toList()..sort((a, b) => b.revenue.compareTo(a.revenue))).first;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Services Revenue',
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ServiceMetricCard(
                      title: 'Total Revenue',
                      value: _loading ? '...' : _money(totalRevenue),
                      icon: Icons.design_services_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceMetricCard(
                      title: 'Services',
                      value: _loading ? '...' : _services.length.toString(),
                      icon: Icons.widgets_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ServiceMetricCard(
                      title: 'Orders',
                      value: _loading ? '...' : totalCount.toStringAsFixed(0),
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceMetricCard(
                      title: 'Top Service',
                      value: _loading ? '...' : (topService?.name ?? 'None'),
                      icon: Icons.star_outline_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ServiceSectionCard(
                title: 'Service performance',
                subtitle:
                    'Powered by `/app/get/getreport/serviceSales` from the API documentation.',
                child: _error != null
                    ? _ServiceError(message: _error!, onRetry: _fetch)
                    : _loading
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _services.isEmpty
                            ? const _ServiceEmpty(
                                title: 'No service revenue data',
                                message: 'Service sales will show here after service records are available.',
                              )
                            : Column(
                                children: _services.take(8).map((service) {
                                  return _ServiceListRow(
                                    title: service.name,
                                    subtitle: 'Orders ${service.count.toStringAsFixed(0)}',
                                    trailing: _money(service.revenue),
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

class _ServiceRevenueItem {
  const _ServiceRevenueItem({
    required this.name,
    required this.count,
    required this.revenue,
  });

  final String name;
  final double count;
  final double revenue;
}

class _ServiceMetricCard extends StatelessWidget {
  const _ServiceMetricCard({
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

class _ServiceSectionCard extends StatelessWidget {
  const _ServiceSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ServiceListRow extends StatelessWidget {
  const _ServiceListRow({
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

class _ServiceError extends StatelessWidget {
  const _ServiceError({
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

class _ServiceEmpty extends StatelessWidget {
  const _ServiceEmpty({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.design_services_outlined, size: 32, color: Color(0xFF94A3B8)),
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
