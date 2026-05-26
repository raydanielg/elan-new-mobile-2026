import 'package:flutter/material.dart';
import '../widgets/app_header.dart';

import '../api/api_service.dart';

class StockPage extends StatefulWidget {
  const StockPage({
    super.key,
    this.userId,
    this.shopId,
  });

  final String? userId;
  final String? shopId;

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  bool _loading = false;
  String? _error;
  List<_StockItem> _items = const [];
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();
  
  // Tab states matching backend filters
  String _activeFilter = 'all';

  String? _userId;
  String? _shopId;

  List<_StockItem> get _filteredItems {
    var items = _items;
    
    // Apply type filter if not 'all'
    if (_activeFilter != 'all') {
      items = items.where((it) => it.type.toLowerCase() == _activeFilter).toList();
    }

    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((it) => 
      it.name.toLowerCase().contains(q) || 
      it.sku.toLowerCase().contains(q)
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _shopId = widget.shopId;
    if (_userId == null || _shopId == null) {
      _fetchContext();
    }
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      debugPrint('Stock GET user_id=$_userId shop_id=$_shopId');
      // Prefer stock; fallback to sellable_stock if stock fails
      dynamic raw;
      try {
        raw = await ApiService.instance.client.getRawJson(
          '/app/get/getdata/stock',
          queryParameters: qp.isEmpty ? null : qp,
        );
      } catch (_) {
        raw = await ApiService.instance.client.getRawJson(
          '/app/get/getdata/sellable_stock',
          queryParameters: qp.isEmpty ? null : qp,
        );
      }

      if (raw is List) {
        debugPrint('Stock raw: List(len=${raw.length})');
      } else if (raw is Map) {
        final keys = raw.keys.map((e) => e.toString()).toList();
        keys.sort();
        debugPrint('Stock raw: Map(keys=${keys.take(40).toList()}${keys.length > 40 ? "..." : ""})');
      }

      final items = _parse(raw);
      debugPrint('Stock parsed count: ${items.length}');

      if (!mounted) return;
      setState(() {
        _items = items;
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

  List<_StockItem> _parse(dynamic raw) {
    dynamic data = raw;
    if (raw is Map) {
      if (raw['data'] != null) {
        data = raw['data'];
      } else if (raw['result'] != null) {
        data = raw['result'];
      } else if (raw['stock'] != null) {
        data = raw['stock'];
      }
    }

    if (data is Map) {
      if (data['data'] != null) data = data['data'];
      if (data is Map && data['result'] != null) data = data['result'];
      if (data is Map && data['stock'] != null) data = data['stock'];
      if (data is Map && data['items'] != null) data = data['items'];
      if (data is Map && data['rows'] != null) data = data['rows'];
      if (data is Map && data['list'] != null) data = data['list'];
    }

    final out = <_StockItem>[];
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final name = item['product_name']?.toString() ?? item['name']?.toString() ?? '';
        final sku = item['sku']?.toString() ?? item['barcode']?.toString() ?? '';
        final qty = item['qty']?.toString() ?? item['quantity']?.toString() ?? item['stock']?.toString() ?? '';
        final type = item['type']?.toString() ?? 'product';
        
        if (name.trim().isEmpty && sku.trim().isEmpty) continue;
        out.add(_StockItem(
          name: name.trim(), 
          sku: sku.trim(), 
          qty: qty.trim(),
          type: type.trim(),
        ));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: _isSearching
          ? AppBar(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              leading: IconButton(
                onPressed: () => setState(() {
                  _isSearching = false;
                  _searchCtrl.clear();
                }),
                icon: const Icon(Icons.arrow_back),
              ),
              title: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search stock...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
              actions: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    onPressed: () => setState(() => _searchCtrl.clear()),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            )
          : AppHeader(
              title: 'Stock',
              backgroundColor: primary,
              foregroundColor: Colors.white,
              onMenuPressed: () => Navigator.of(context).maybePop(),
              showUserMenu: false,
              actions: [
                IconButton(
                  onPressed: () => setState(() => _isSearching = true),
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                ),
                IconButton(
                  onPressed: _fetch,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.inventory_2_outlined, color: primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Total Stock Items',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _loading ? '...' : _items.length.toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_loading && _filteredItems.length != _items.length)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Filtered: ${_filteredItems.length}',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Filter Bar (Tabs like)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterBarItem(
                              label: 'All Stock',
                              icon: Icons.all_inclusive,
                              isActive: _activeFilter == 'all',
                              onTap: () => setState(() => _activeFilter = 'all'),
                            ),
                            const SizedBox(width: 8),
                            _FilterBarItem(
                              label: 'Products',
                              icon: Icons.inventory_2_outlined,
                              isActive: _activeFilter == 'product',
                              onTap: () => setState(() => _activeFilter = 'product'),
                            ),
                            const SizedBox(width: 8),
                            _FilterBarItem(
                              label: 'Services',
                              icon: Icons.miscellaneous_services_outlined,
                              isActive: _activeFilter == 'service',
                              onTap: () => setState(() => _activeFilter = 'service'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_error != null)
                        _ErrorCard(message: _error!, onRetry: _fetch),
                      
                      // Loading Skeletons
                      if (_loading)
                        _buildSkeletonList()
                      else if (_filteredItems.isEmpty)
                        _buildEmptyState(),
                    ],
                  ),
                ),
              ),
              
              // Stock List
              if (!_loading && _filteredItems.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final it = _filteredItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StockCard(item: it),
                        );
                      },
                      childCount: _filteredItems.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty ? 'No matches found' : 'No stock items found',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pull down to refresh or try a different search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Column(
      children: List.generate(8, (index) => const _SkeletonStockCard()),
    );
  }
}

class _SkeletonStockCard extends StatefulWidget {
  const _SkeletonStockCard();

  @override
  State<_SkeletonStockCard> createState() => _SkeletonStockCardState();
}

class _SkeletonStockCardState extends State<_SkeletonStockCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 140, height: 16, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 12, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockItem {
  const _StockItem({
    required this.name, 
    required this.sku, 
    required this.qty,
    required this.type,
  });

  final String name;
  final String sku;
  final String qty;
  final String type;
}

class _FilterBarItem extends StatelessWidget {
  const _FilterBarItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? primary : const Color(0xFFE5E7EB),
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.item});

  final _StockItem item;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final initials = item.name.isEmpty ? 'P' : item.name.toUpperCase().substring(0, 1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.isEmpty ? 'Product' : item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.sku.isNotEmpty ? 'SKU: ${item.sku}   •   QTY: ${item.qty.isEmpty ? '-' : item.qty}' : 'QTY: ${item.qty.isEmpty ? '-' : item.qty}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
