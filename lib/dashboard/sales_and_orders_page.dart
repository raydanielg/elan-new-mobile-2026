import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../services/permission_service.dart';
import '../widgets/global_filter_widget.dart';
import '../repositories/filter_repository.dart';
import '../repositories/sales_repository.dart';
import 'sale_details_page.dart';
import 'sales_pos_page.dart';

class SalesAndOrdersPage extends StatefulWidget {
  const SalesAndOrdersPage({
    super.key,
    this.shopId,
  });

  final String? shopId;

  @override
  State<SalesAndOrdersPage> createState() => _SalesAndOrdersPageState();
}

class _SalesAndOrdersPageState extends State<SalesAndOrdersPage> {
  DateTimeRange? _customRange;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  int _currentTabIndex = 0;
  late final PageController _pageController;

  bool _loading = false;
  String? _error;

  Map<String, dynamic> _filterRange = const {};

  List<dynamic> _incomeRows = const [];
  List<dynamic> _customerRows = const [];
  List<dynamic> _staffRows = const [];
  bool _isHotel = false;
  String? _currentShopId;
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentTabIndex);
    _currentShopId = widget.shopId ?? ApiService.instance.tokenStore.selectedShopId;
    _initFiltersAndFetch();
  }

  @override
  void didUpdateWidget(covariant SalesAndOrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newShopId = widget.shopId ?? ApiService.instance.tokenStore.selectedShopId;
    if (newShopId != _currentShopId) {
      _currentShopId = newShopId;
      _initFiltersAndFetch();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newShopId = widget.shopId ?? ApiService.instance.tokenStore.selectedShopId;
    if (newShopId != _currentShopId) {
      _currentShopId = newShopId;
      _initFiltersAndFetch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initFiltersAndFetch() async {
    setState(() => _loading = true);
    try {
      await FilterRepository.instance.applyGlobalFilter(shopId: _currentShopId);
      await _refreshAll();
    } catch (e) {
      debugPrint('Error setting initial filter: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Error: $e', style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      _refreshAll();
    }
  }

  String _fmtDate(DateTime d) {
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<DateTimeRange?> _pickRange() {
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _customRange ?? DateTimeRange(start: now, end: now),
    );
  }

  Future<void> _applyFilter(String filter, {DateTime? from, DateTime? to}) async {
    final body = <String, String>{'filter': filter};
    if (from != null) body['from'] = _fmtDate(from);
    if (to != null) body['to'] = _fmtDate(to);

    try {
      await ApiService.instance.app.postData('filter/set', body: body);
      await Future.delayed(const Duration(milliseconds: 300));
      await _refreshAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final frRes = await FilterRepository.instance.applyGlobalFilter(shopId: _currentShopId);
      final salesRes = await SalesRepository.instance.getSalesOrders(shopId: _currentShopId);

      final results = await Future.wait([
        ApiService.instance.app.getCustomersInSales(),
        ApiService.instance.app.getStaffInSales(),
        ApiService.instance.app.getData('session_user'),
        ApiService.instance.app.getWaitersInSales(),
      ]);

      if (!mounted) return;

      final role = (results[2] is Map) ? results[2] as Map : {};
      final isHotel = role['is_hotel'] == '1' || 
                      role['business_type'] == 'hotel' || 
                      role['session_shop_type'] == 'hotel';

      setState(() {
        _isHotel = isHotel;
        _incomeRows = salesRes.data ?? const [];
        _customerRows = isHotel ? _asList(results[3]) : _asList(results[0]);
        _staffRows = _asList(results[1]);
        _filterRange = frRes.data ?? const {};
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

  List<dynamic> _asList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is Map) {
      final data = raw['data'] ?? raw['result'] ?? raw['rows'] ?? raw['list'];
      if (data is List) return data;
    }
    return const [];
  }

  Future<void> _openFilterSheet() {
    final primary = Theme.of(context).colorScheme.primary;
    Widget filterButton(String label, String filterKey, {String? subtitle}) {
      return SizedBox(
        height: 60,
        child: OutlinedButton(
          onPressed: () async {
            if (filterKey == 'custom') {
              final picked = await _pickRange();
              if (picked == null) return;
              setState(() { _customRange = picked; _loading = true; });
              await _applyFilter('custom', from: _customRange!.start, to: _customRange!.end);
              if (mounted) Navigator.pop(context);
              return;
            }
            setState(() => _loading = true);
            await _applyFilter(filterKey);
            if (mounted) Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primary, width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
              if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      pageBuilder: (ctx, a1, a2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.9,
              height: MediaQuery.of(ctx).size.height * 0.7,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(child: Text('Filters', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.5,
                      children: [
                        filterButton('Reset', 'reset'),
                        filterButton('Today', 'today'),
                        filterButton('Yesterday', 'yesterday'),
                        filterButton('This Week', 'thisweek'),
                        filterButton('Last Week', 'last_week'),
                        filterButton('This Month', 'thismonth'),
                        filterButton('Last Month', 'last_month'),
                        filterButton('Custom', 'custom'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final filterTitle = ApiService.instance.tokenStore.globalFilterTitle;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Search...', border: InputBorder.none),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Sales & Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() { _isSearching = !_isSearching; if (!_isSearching) _searchController.clear(); }),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll),
          // Global Filter
          GlobalFilterWidget(
            onFilterChanged: () {
              if (mounted) _refreshAll();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        selectedItemColor: primary,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Income'),
          BottomNavigationBarItem(icon: Icon(_isHotel ? Icons.restaurant_outlined : Icons.people_outline), label: _isHotel ? 'Waiters' : 'Customers'),
          const BottomNavigationBarItem(icon: Icon(Icons.badge_outlined), label: 'Staff'),
        ],
      ),
      floatingActionButton: _buildFAB(primary),
      body: Column(
        children: [
          Container(
            height: 54,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _TypeChip(label: 'All', value: 'all', selected: _selectedType == 'all', onSelect: (v) => setState(() => _selectedType = v)),
                _TypeChip(label: 'Sales', value: 'sales', selected: _selectedType == 'sales', onSelect: (v) => setState(() => _selectedType = v)),
                _TypeChip(label: 'Orders', value: 'orders', selected: _selectedType == 'orders', onSelect: (v) => setState(() => _selectedType = v)),
                _TypeChip(label: 'Invoices', value: 'invoices', selected: _selectedType == 'invoices', onSelect: (v) => setState(() => _selectedType = v)),
                _TypeChip(label: 'Quotes', value: 'quotations', selected: _selectedType == 'quotations', onSelect: (v) => setState(() => _selectedType = v)),
              ],
            ),
          ),
          const Divider(height: 1),
          // Global Filter Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: ApiService.instance.tokenStore.hasActiveFilter 
                ? primary.withOpacity(0.1) 
                : Colors.grey.shade50,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today, 
                  size: 14, 
                  color: ApiService.instance.tokenStore.hasActiveFilter ? primary : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  filterTitle, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 12, 
                    color: ApiService.instance.tokenStore.hasActiveFilter ? primary : Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                if (ApiService.instance.tokenStore.hasActiveFilter)
                  GestureDetector(
                    onTap: () async {
                      await resetGlobalFilter();
                      if (mounted) _refreshAll();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentTabIndex = index);
              },
              children: [
                _buildTabList(_incomeRows, primary),
                _buildTabList(_customerRows, primary),
                _buildTabList(_staffRows, primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabList(List<dynamic> rows, Color primary) {
    final query = _searchController.text.trim().toLowerCase();
    final typeFiltered = rows.where((r) {
      if (_selectedType == 'all') return true;
      if (r is! Map) return false;
      final rowType = (r['sale_type'] ?? r['document_type'] ?? '').toString().toLowerCase();
      if (_selectedType == 'sales') return rowType == 'cashsale' || rowType == 'sale';
      if (_selectedType == 'orders') return rowType == 'order';
      if (_selectedType == 'invoices') return rowType == 'invoice';
      if (_selectedType == 'quotations') return rowType == 'quotation';
      return true;
    }).toList();

    final filtered = query.isEmpty ? typeFiltered : typeFiltered.where((r) => r.toString().toLowerCase().contains(query)).toList();

    if (_loading) return _buildSkeletonList();
    if (_error != null) return _InlineError(message: _error!, onRetry: _refreshAll);
    if (filtered.isEmpty) return const Center(child: Text('No records found', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: filtered.length,
      itemBuilder: (context, i) => _SalesRowCard(primary: primary, row: filtered[i]),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, i) => const _SkeletonRowCard(),
    );
  }

  Widget? _buildFAB(Color primary) {
    final perm = PermissionService();
    
    // Check if user has any permission to create transactions
    final canCreateAny = perm.canMakeSales || 
                         perm.canManageOrders || 
                         perm.canMakeInvoice;
    
    if (!canCreateAny) {
      return null; // Hide FAB if no permissions
    }
    
    return FloatingActionButton(
      heroTag: 'add_fab',
      onPressed: _showSaleTypeSelector,
      backgroundColor: primary,
      child: const Icon(Icons.add, size: 28, color: Colors.white),
    );
  }

  void _showSaleTypeSelector() {
    final perm = PermissionService();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text('New Transaction', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                // Sale - requires can_make_sales
                if (perm.canMakeSales)
                  _CircularActionBtn(
                    icon: Icons.point_of_sale_outlined, 
                    label: 'Sale', 
                    color: Colors.green, 
                    onTap: () { 
                      Navigator.pop(context); 
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SalesPosPage(saleType: 'cashsale', shopId: _currentShopId))); 
                    }
                  ),
                // Order - requires can_manage_orders
                if (perm.canManageOrders)
                  _CircularActionBtn(
                    icon: Icons.shopping_bag_outlined, 
                    label: 'Order', 
                    color: Colors.blue, 
                    onTap: () { 
                      Navigator.pop(context); 
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SalesPosPage(saleType: 'order', shopId: _currentShopId))); 
                    }
                  ),
                // Invoice - requires can_make_invoice
                if (perm.canMakeInvoice)
                  _CircularActionBtn(
                    icon: Icons.receipt_long_outlined, 
                    label: 'Invoice', 
                    color: Colors.orange, 
                    onTap: () { 
                      Navigator.pop(context); 
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SalesPosPage(saleType: 'invoice', shopId: _currentShopId))); 
                    }
                  ),
                // Quote - requires can_make_invoice (same as invoice)
                if (perm.canMakeInvoice)
                  _CircularActionBtn(
                    icon: Icons.description_outlined, 
                    label: 'Quote', 
                    color: Colors.purple, 
                    onTap: () { 
                      Navigator.pop(context); 
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SalesPosPage(saleType: 'quotation', shopId: _currentShopId))); 
                    }
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesRowCard extends StatelessWidget {
  const _SalesRowCard({required this.primary, required this.row});
  final Color primary;
  final dynamic row;
  @override
  Widget build(BuildContext context) {
    if (row is! Map) return const SizedBox.shrink();
    
    // Extract data based on the API response structure seen in logs
    final date = row['date']?.toString() ?? row['record_date']?.toString() ?? '';
    final total = (row['total_amount'] ?? row['total'] ?? 0).toString();
    final paid = (row['paid_amount'] ?? row['paid'] ?? 0).toString();
    final type = (row['sale_type'] ?? row['document_type'] ?? '').toString().toLowerCase();
    final rawInvoiceNo = row['invoice_no']?.toString() ?? row['sale_id']?.toString() ?? '---';
    
    // Determine prefix based on type
    String prefix = '#';
    if (type.contains('order')) prefix = 'ORD-';
    else if (type.contains('invoice')) prefix = 'INV-';
    else if (type.contains('quotation') || type.contains('quote')) prefix = 'QT-';
    else if (type.contains('cash') || type.contains('sale')) prefix = 'SAL-';

    final invoiceNo = rawInvoiceNo.startsWith(prefix) || rawInvoiceNo.startsWith('#') 
        ? rawInvoiceNo 
        : '$prefix$rawInvoiceNo';
    final customer = row['customer']?.toString() ?? row['customer_name']?.toString() ?? '';
    final staff = row['username']?.toString() ?? row['staff_name']?.toString() ?? '';
    final waiter = row['waiter']?.toString() ?? '';
    final mode = row['payment_mode']?.toString() ?? row['mode']?.toString() ?? '';
    
    final totalVal = double.tryParse(total) ?? 0;
    final paidVal = double.tryParse(paid) ?? 0;
    final isPaid = paidVal >= totalVal && totalVal != 0;
    final isPartial = paidVal > 0 && paidVal < totalVal;
    
    final statusColor = isPaid ? Colors.green : (isPartial ? Colors.orange : Colors.red);

    return GestureDetector(
      onTap: () {
        final id = row['sale_id']?.toString() ?? row['id']?.toString();
        if (id != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) => SaleDetailsPage(saleId: id, initialData: row is Map<String, dynamic> ? row : null, isModal: true),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoiceNo.startsWith('#') ? invoiceNo : '#$invoiceNo',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (type.isNotEmpty) 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(8),
                    ), 
                    child: Text(
                      type.toUpperCase(), 
                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              customer.isNotEmpty ? customer : 'Guest Customer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            waiter.isNotEmpty ? Icons.restaurant_menu : Icons.badge_outlined,
                            size: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            waiter.isNotEmpty ? waiter : (staff.isNotEmpty ? staff : 'System'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TSh $total',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPaid ? 'PAID' : (isPartial ? 'PARTIAL' : 'UNPAID'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.value, required this.selected, required this.onSelect});
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black87)),
        selected: selected,
        onSelected: (_) => onSelect(value),
        selectedColor: primary,
        backgroundColor: Colors.grey[100],
      ),
    );
  }
}

class _CircularActionBtn extends StatelessWidget {
  const _CircularActionBtn({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SkeletonRowCard extends StatelessWidget {
  const _SkeletonRowCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(message), ElevatedButton(onPressed: onRetry, child: const Text('Retry'))]));
  }
}
