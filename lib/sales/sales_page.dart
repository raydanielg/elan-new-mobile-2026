import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../widgets/app_header.dart';
import 'create.dart';
import 'sales_details_page.dart';
import 'sales_analytics_page.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _LocalSale {
  final String id;
  final String customer;
  final double amount;
  final double paidAmount;
  final double balance;
  final String? notes;
  final DateTime createdAt;
  final String status;
  final String saleType;
  final String? customerPhone;
  final int itemsCount;

  const _LocalSale({
    required this.id,
    required this.customer,
    required this.amount,
    required this.paidAmount,
    required this.balance,
    required this.createdAt,
    required this.status,
    required this.saleType,
    this.notes,
    this.customerPhone,
    this.itemsCount = 0,
  });

  bool get isPaid => balance <= 0;
  bool get isInvoice => saleType.toLowerCase() == 'invoice';
  bool get isOrder => saleType.toLowerCase() == 'order' || saleType.toLowerCase() == 'orders';
}

class _SalesPageState extends State<SalesPage> {
  bool _loading = false;
  String? _error;
  List<_LocalSale> _sales = <_LocalSale>[];
  List<_LocalSale> _filteredSales = <_LocalSale>[];

  String? _userId;
  String? _shopId;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, paid, unpaid, order, invoice

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredSales = _sales.where((sale) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery;
        final matchesCustomer = sale.customer.toLowerCase().contains(query);
        final matchesPhone = sale.customerPhone?.toLowerCase().contains(query) ?? false;
        final matchesId = sale.id.toLowerCase().contains(query);
        if (!matchesCustomer && !matchesPhone && !matchesId) return false;
      }
      
      // Status filter
      switch (_statusFilter) {
        case 'paid':
          return sale.isPaid;
        case 'unpaid':
          return !sale.isPaid;
        case 'order':
          return sale.isOrder;
        case 'invoice':
          return sale.isInvoice;
        default:
          return true;
      }
    }).toList();
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

  List<_LocalSale> _parseSales(dynamic raw) {
    dynamic data = raw;
    if (raw is Map && raw['data'] != null) data = raw['data'];

    final list = (data is List)
        ? data
        : (data is Map && data['rows'] is List)
            ? data['rows']
            : (data is Map && data['list'] is List)
                ? data['list']
                : null;

    final out = <_LocalSale>[];
    if (list is List) {
      for (final item in list) {
        if (item is! Map) continue;
        final id = item['sale_id']?.toString() ?? item['id']?.toString() ?? '';
        final customer = item['customer_name']?.toString() ??
            item['customer']?.toString() ??
            item['name']?.toString() ??
            'Customer';

        final amount = _parseAmount(
          item['total_amount'] ??
              item['amount'] ??
              item['grand_total'] ??
              item['total'] ??
              item['sale_amount'],
        );
        
        final paidAmount = _parseAmount(
          item['paid_amount'] ??
              item['paid'] ??
              item['amount_paid'] ??
              0,
        );
        
        final balance = _parseAmount(
          item['balance_amount'] ??
              item['balance'] ??
              (amount - paidAmount),
        );

        final notes = item['notes']?.toString() ?? item['remark']?.toString();
        final createdAt = _parseDate(
          item['created_at'] ?? item['date'] ?? item['sale_date'] ?? item['createdAt'],
        );
        
        final status = item['status']?.toString() ?? 'active';
        final saleType = item['sale_type']?.toString() ?? 'cashsale';
        final customerPhone = item['customer_phone']?.toString() ?? item['phone']?.toString();
        final itemsCount = int.tryParse(item['items_count']?.toString() ?? '0') ?? 0;

        out.add(
          _LocalSale(
            id: id,
            customer: customer.trim().isEmpty ? 'Customer' : customer.trim(),
            amount: amount,
            paidAmount: paidAmount,
            balance: balance,
            notes: (notes != null && notes.trim().isNotEmpty) ? notes.trim() : null,
            createdAt: createdAt,
            status: status,
            saleType: saleType,
            customerPhone: customerPhone,
            itemsCount: itemsCount,
          ),
        );
      }
    }
    return out;
  }

  Future<void> _fetchSales() async {
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

      final raw = await ApiService.instance.app.getSalesOrders();
      final sales = _parseSales(raw);
      if (!mounted) return;
      setState(() {
        _sales = sales;
        _filteredSales = sales;
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

  Future<void> _openCreateSale() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateSalePage()),
    );

    if (!mounted || created != true) return;
    await _fetchSales();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = _sales.fold<double>(0, (sum, s) => sum + s.amount);
    final totalPaid = _sales.fold<double>(0, (sum, s) => sum + s.paidAmount);
    final totalBalance = _sales.fold<double>(0, (sum, s) => sum + s.balance);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Sales',
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SalesAnalyticsPage()),
              );
            },
            tooltip: 'Analytics',
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(
            onPressed: _fetchSales,
            tooltip: 'Refresh',
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSale,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Total Sales',
                      'TSh ${total.toStringAsFixed(0)}',
                      Icons.trending_up,
                      const Color(0xFF00C853),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Paid',
                      'TSh ${totalPaid.toStringAsFixed(0)}',
                      Icons.check_circle,
                      const Color(0xFF00B0FF),
                    ),
                  ),
                ],
              ),
            ),
            if (totalBalance > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSummaryCard(
                  context,
                  'Pending Balance',
                  'TSh ${totalBalance.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  const Color(0xFFFF6D00),
                ),
              ),
            const SizedBox(height: 12),
            
            // Search and Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search sales...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Paid', 'paid'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Unpaid', 'unpaid'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Orders', 'order'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Invoices', 'invoice'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Sales List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchSales,
                child: _buildSalesList(colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    final colorScheme = Theme.of(context).colorScheme;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = selected ? value : 'all';
          _applyFilters();
        });
      },
      selectedColor: colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? colorScheme.primary : Colors.grey.shade700,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? colorScheme.primary : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildSalesList(ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Failed to load sales',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetchSales,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_filteredSales.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No sales found',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty || _statusFilter != 'all'
                    ? 'Try adjusting your search or filters'
                    : 'Create your first sale to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              if (_searchQuery.isEmpty && _statusFilter == 'all') ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openCreateSale,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Sale'),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: _filteredSales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sale = _filteredSales[index];
        return _buildSaleCard(sale, colorScheme);
      },
    );
  }

  Widget _buildSaleCard(_LocalSale sale, ColorScheme colorScheme) {
    final statusColor = sale.isPaid
        ? const Color(0xFF00C853)
        : (sale.isOrder ? const Color(0xFF00B0FF) : const Color(0xFFFF6D00));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SalesDetailsPage(saleId: sale.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          sale.customer,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (sale.customerPhone != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sale.customerPhone!,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sale.isPaid
                              ? Icons.check_circle
                              : (sale.isOrder ? Icons.shopping_bag : Icons.pending),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sale.isPaid
                              ? 'Paid'
                              : (sale.isOrder ? 'Order' : 'Unpaid'),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TSh ${sale.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: statusColor,
                          ),
                        ),
                        if (!sale.isPaid) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Balance: TSh ${sale.balance.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(sale.createdAt),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (sale.itemsCount > 0)
                        Text(
                          '${sale.itemsCount} item${sale.itemsCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (sale.notes != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sale.notes!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
