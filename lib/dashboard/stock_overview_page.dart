import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../products/stock.dart';
import '../widgets/app_header.dart';

class StockOverviewPage extends StatefulWidget {
  const StockOverviewPage({
    super.key,
    this.userId,
    this.shopId,
  });

  final String? userId;
  final String? shopId;

  @override
  State<StockOverviewPage> createState() => _StockOverviewPageState();
}

class _StockOverviewPageState extends State<StockOverviewPage> {
  bool _loading = false;
  String? _error;
  List<_StockRecord> _items = const [];
  List<_StockRecord> _lowStock = const [];

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

      dynamic stockRaw;
      try {
        stockRaw = await ApiService.instance.client.getRawJson(
          '/app/get/getdata/stock',
          queryParameters: qp.isEmpty ? null : qp,
        );
      } catch (_) {
        stockRaw = await ApiService.instance.client.getRawJson(
          '/app/get/getdata/sellable_stock',
          queryParameters: qp.isEmpty ? null : qp,
        );
      }

      dynamic lowStockRaw;
      try {
        lowStockRaw = await ApiService.instance.client.getRawJson(
          '/app/get/getreport/lowStock',
          queryParameters: qp.isEmpty ? null : qp,
        );
      } catch (_) {
        lowStockRaw = null;
      }

      if (!mounted) return;
      setState(() {
        _items = _parseStock(stockRaw);
        _lowStock = _parseStock(lowStockRaw);
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

  List<_StockRecord> _parseStock(dynamic raw) {
    dynamic data = raw;
    if (raw is Map) {
      data = raw['data'] ?? raw['result'] ?? raw['stock'] ?? raw['items'] ?? raw['rows'] ?? raw;
    }
    if (data is Map) {
      data = data['data'] ?? data['result'] ?? data['stock'] ?? data['items'] ?? data['rows'] ?? data['list'] ?? data;
    }

    final out = <_StockRecord>[];
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final name = item['product_name']?.toString() ??
            item['name']?.toString() ??
            item['service_name']?.toString() ??
            'Item';
        final category = item['category_name']?.toString() ??
            item['category']?.toString() ??
            item['stock_category']?.toString();
        final qtyText = item['qty']?.toString() ??
            item['quantity']?.toString() ??
            item['stock']?.toString() ??
            item['balance']?.toString() ??
            '0';
        final value = _asDouble(
          item['total_value'] ??
              item['stock_value'] ??
              item['selling_total'] ??
              item['subtotal'],
        );
        out.add(
          _StockRecord(
            name: name.trim().isEmpty ? 'Item' : name.trim(),
            category: category?.trim(),
            quantity: _asDouble(qtyText),
            value: value,
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
    final totalQty = _items.fold<double>(0, (sum, item) => sum + item.quantity);
    final totalValue = _items.fold<double>(0, (sum, item) => sum + item.value);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Stocks',
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
                    child: _OverviewMetricCard(
                      title: 'Items',
                      value: _loading ? '...' : _items.length.toString(),
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OverviewMetricCard(
                      title: 'Qty',
                      value: _loading ? '...' : totalQty.toStringAsFixed(0),
                      icon: Icons.stacked_bar_chart_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _OverviewMetricCard(
                      title: 'Stock Value',
                      value: _loading ? '...' : _money(totalValue),
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OverviewMetricCard(
                      title: 'Low Stock',
                      value: _loading ? '...' : _lowStock.length.toString(),
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Stock overview',
                subtitle: 'Current stock list from `/app/get/getdata/stock`.',
                trailing: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StockPage(userId: _userId, shopId: _shopId),
                      ),
                    );
                  },
                  child: const Text('Open full stock'),
                ),
                child: _error != null
                    ? _ErrorState(message: _error!, onRetry: _fetch)
                    : _loading
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _items.isEmpty
                            ? const _EmptyState(
                                title: 'No stock data',
                                message: 'No stock records were returned for this business yet.',
                              )
                            : Column(
                                children: _items.take(8).map((item) {
                                  return _ListRow(
                                    title: item.name,
                                    subtitle: item.category ?? 'Stock item',
                                    trailing: 'Qty ${item.quantity.toStringAsFixed(0)}',
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

class _StockRecord {
  const _StockRecord({
    required this.name,
    required this.quantity,
    required this.value,
    this.category,
  });

  final String name;
  final String? category;
  final double quantity;
  final double value;
}

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
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

class _ListRow extends StatelessWidget {
  const _ListRow({
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          style: const TextStyle(color: Color(0xFFB91C1C)),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.inbox_outlined, size: 32, color: Color(0xFF94A3B8)),
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
