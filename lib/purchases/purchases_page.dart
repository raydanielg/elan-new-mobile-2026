import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../widgets/app_header.dart';

class PurchasesPage extends StatefulWidget {
  const PurchasesPage({super.key});

  @override
  State<PurchasesPage> createState() => _PurchasesPageState();
}

class _LocalPurchase {
  final String id;
  final String supplier;
  final double amount;
  final String? status;
  final DateTime createdAt;
  final String? createdBy;

  const _LocalPurchase({
    required this.id,
    required this.supplier,
    required this.amount,
    required this.createdAt,
    this.status,
    this.createdBy,
  });
}

class _PurchasesPageState extends State<PurchasesPage> {
  int _selectedTabIndex = 1;
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  String? _error;
  List<_LocalPurchase> _purchases = <_LocalPurchase>[];
  List<_LocalPurchase> _filteredPurchases = <_LocalPurchase>[];

  String? _userId;
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPurchases = _purchases.where((p) {
        return p.supplier.toLowerCase().contains(query) ||
            p.id.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchContext() async {
    try {
      final sessionUserRaw = await ApiService.instance.app.getData('session_user');
      final sessionShopRaw = await ApiService.instance.app.getData('session_shop');
      if (!mounted) return;

      String? userId;
      String? shopId;

      if (sessionUserRaw is Map) {
        final data = (sessionUserRaw['data'] is Map)
            ? (sessionUserRaw['data'] as Map)
            : sessionUserRaw;
        userId = data['user_id']?.toString() ?? data['id']?.toString();
        userId = userId?.trim();
        if (userId != null && userId.isEmpty) userId = null;
      }

      if (sessionShopRaw is Map) {
        final data = (sessionShopRaw['data'] is Map)
            ? (sessionShopRaw['data'] as Map)
            : sessionShopRaw;
        shopId = data['shop_id']?.toString() ??
            data['id']?.toString() ??
            data['session_shop_id']?.toString();
        shopId = shopId?.trim();
        if (shopId != null && shopId.isEmpty) shopId = null;
      }

      setState(() {
        _userId ??= userId;
        _shopId ??= shopId;
      });
    } catch (_) {
      // ignore
    }
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    final s = raw.toString().trim();
    final dt = DateTime.tryParse(s);
    return dt ?? DateTime.now();
  }

  double _parseAmount(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    final s = raw.toString().replaceAll(',', '').trim();
    return double.tryParse(s) ?? 0;
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<_LocalPurchase> _parsePurchases(dynamic raw) {
    dynamic data = raw;
    if (raw is Map && raw['data'] != null) data = raw['data'];

    final list = (data is List)
        ? data
        : (data is Map && data['rows'] is List)
            ? data['rows']
            : (data is Map && data['list'] is List)
                ? data['list']
                : null;

    final out = <_LocalPurchase>[];
    if (list is List) {
      for (final item in list) {
        if (item is! Map) continue;
        final id = item['purchase_id']?.toString() ??
            item['id']?.toString() ??
            '';
        final supplier = item['supplier_name']?.toString() ??
            item['supplier']?.toString() ??
            item['name']?.toString() ??
            'Supplier';

        final amount = _parseAmount(
          item['amount'] ??
              item['total_amount'] ??
              item['grand_total'] ??
              item['total'] ??
              item['purchase_amount'],
        );

        final status = item['status']?.toString() ?? item['purchase_status']?.toString();
        final createdBy = item['created_by']?.toString() ?? item['user_name']?.toString();
        final createdAt = _parseDate(
          item['created_at'] ?? item['date'] ?? item['purchase_date'] ?? item['createdAt'],
        );

        out.add(
          _LocalPurchase(
            id: id.trim().isEmpty ? '0' : id.trim(),
            supplier: supplier.trim().isEmpty ? 'Supplier' : supplier.trim(),
            amount: amount,
            status: (status != null && status.trim().isNotEmpty) ? status.trim() : null,
            createdBy: (createdBy != null && createdBy.trim().isNotEmpty) ? createdBy.trim() : null,
            createdAt: createdAt,
          ),
        );
      }
    }
    return out;
  }

  Future<void> _fetchPurchases() async {
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

      final raw = await ApiService.instance.client.getRawJson(
        '/app/get/getdata/purchase_history',
        queryParameters: qp.isEmpty ? null : qp,
      );
      final purchases = _parsePurchases(raw);
      if (!mounted) return;
      setState(() {
        _purchases = purchases;
        _filteredPurchases = purchases;
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

  Future<void> _openNewPurchase() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create New Purchase - Coming soon')),
    );
  }

  Future<void> _openFilter() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter - Coming soon')),
    );
  }

  Widget _topTab({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary, width: 2),
                color: selected ? primary : Colors.white,
              ),
              child: Icon(icon, size: 18, color: selected ? Colors.white : primary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? primary : const Color(0xFF111827),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: 50,
              decoration: BoxDecoration(
                color: selected ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _purchaseCard(_LocalPurchase purchase) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.shopping_cart_outlined, color: primary),
        ),
        title: Text(
          purchase.supplier,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(purchase.createdAt)),
            if (purchase.createdBy != null)
              Text(
                'By: ${purchase.createdBy}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            if (purchase.status != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  purchase.status!,
                  style: TextStyle(
                    fontSize: 12,
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        trailing: Text(
          '${purchase.amount.toStringAsFixed(2)} TZS',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final grandTotal = _filteredPurchases.fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Purchases',
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchPurchases,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            children: [
              // Summary Card
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.shopping_cart_outlined, color: primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Purchases',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_filteredPurchases.length} purchases',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Grand Total',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${grandTotal.toStringAsFixed(2)} TZS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Top Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    _topTab(
                      icon: Icons.arrow_back,
                      label: 'Back',
                      selected: false,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    _topTab(
                      icon: Icons.inventory_2_outlined,
                      label: 'Purchase\nHistory',
                      selected: _selectedTabIndex == 1,
                      onTap: () => setState(() => _selectedTabIndex = 1),
                    ),
                    _topTab(
                      icon: Icons.shopping_basket_outlined,
                      label: 'New\nPurchase',
                      selected: _selectedTabIndex == 2,
                      onTap: () => setState(() => _selectedTabIndex = 2),
                    ),
                    _topTab(
                      icon: Icons.filter_list,
                      label: 'Filter',
                      selected: _selectedTabIndex == 3,
                      onTap: _openFilter,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Quick Action
              Center(
                child: InkWell(
                  onTap: _openNewPurchase,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF800000),
                              Color(0xFFA52A2A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF800000).withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'New Purchase',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search supplier...',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Purchase List
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _fetchPurchases,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredPurchases.isEmpty)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No purchases found',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ..._filteredPurchases.map(_purchaseCard),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
