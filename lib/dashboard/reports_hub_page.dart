import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class ReportsHubPage extends StatefulWidget {
  const ReportsHubPage({super.key});

  @override
  State<ReportsHubPage> createState() => _ReportsHubPageState();
}

class _ReportsHubPageState extends State<ReportsHubPage> {
  bool _loading = true;
  String? _error;

  // Report categories matching web
  final Map<String, List<_ReportItem>> _reportGroups = {
    'Stock & Services': [
      _ReportItem('totalStock', 'Current Stock Summary', 'stock_id'),
      _ReportItem('stockByCategory', 'Stock by Category', 'category'),
      _ReportItem('countingSheet', 'Stock Counting Sheet', 'product_name'),
      _ReportItem('priceList', 'Price List', 'product_name'),
      _ReportItem('barcodeReport', 'Barcode List', 'barcode'),
      _ReportItem('lowStock', 'Low Stock Items', 'stock_id'),
      _ReportItem('badStock', 'Damaged Stock', 'stock_id'),
      _ReportItem('lostStock', 'Lost Stock Items', 'stock_id'),
      _ReportItem('soldStock', 'Sold Stock', 'stock_id'),
      _ReportItem('expiringStock', 'Expiring Stock', 'stock_id'),
      _ReportItem('expiredStock', 'Expired Stock Items', 'stock_id'),
      _ReportItem('outOfStock', 'Out of Stock Items', 'stock_id'),
      _ReportItem('stockMovements', 'Stock Movement History', 'movement_id'),
      _ReportItem('serviceSales', 'Service Sales Summary', 'service_name'),
      _ReportItem('serviceSalesByStaff', 'Service Sales by Staff', 'staff_name'),
      _ReportItem('topServices', 'Top Services', 'service_name'),
    ],
    'Sales': [
      _ReportItem('totalSales', 'Sales Summary', 'sale_id'),
      _ReportItem('allOrders', 'Sales Orders', 'sale_id'),
      _ReportItem('cashSales', 'Cash Sales Report', 'sale_id'),
      _ReportItem('creditSales', 'Credit Sales Report', 'sale_id'),
      _ReportItem('salesByCustomer', 'Sales by Customer', 'customer_id'),
      _ReportItem('salesByProduct', 'Sales by Product', 'product_name'),
      _ReportItem('salesByStaff', 'Sales by Staff', 'username'),
      _ReportItem('salesReturns', 'Sales Returns', 'sale_id'),
      _ReportItem('voidedSales', 'Voided Sales', 'sale_id'),
      _ReportItem('salesByPayment', 'Sales by Payment Mode', 'payment_mode'),
      _ReportItem('topSellingProducts', 'Top Selling Products', 'product_name'),
      _ReportItem('salesByDate', 'Sales by Date', 'sale_date'),
    ],
    'Purchase & Suppliers': [
      _ReportItem('purchaseHistory', 'Purchase History Report', 'id'),
      _ReportItem('purchaseReturns', 'Purchase Returns Report', 'product_name'),
      _ReportItem('purchasesBySupplier', 'Purchases by Supplier', 'supplier_id'),
      _ReportItem('purchasesByProduct', 'Purchases by Product', 'product_name'),
      _ReportItem('purchasesByStaff', 'Purchases by Staff', 'username'),
      _ReportItem('allSuppliers', 'Suppliers List', 'supplier_id'),
      _ReportItem('creditSuppliers', 'Suppliers with Credit', 'supplier_id'),
      _ReportItem('supplierBalances', 'Supplier Balances', 'supplier_id'),
      _ReportItem('topSuppliers', 'Top Suppliers', 'supplier_id'),
    ],
    'Customers': [
      _ReportItem('allCustomers', 'Customers List', 'customer_id'),
      _ReportItem('topCustomers', 'Top Customers', 'customer_id'),
      _ReportItem('customerBalances', 'Customer Balances', 'customer_id'),
      _ReportItem('creditCustomers', 'Customers with Credit', 'customer_id'),
    ],
    'Financial': [
      _ReportItem('profitSummary', 'Profit Summary', 'date'),
      _ReportItem('expenseSummary', 'Expense Summary', 'expense_id'),
      _ReportItem('cashflowReport', 'Cashflow Report', 'transaction_id'),
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = false;
      _error = null;
    });

    // Reports are hardcoded locally matching web structure
    // Could fetch from API if dynamic list available

    if (kDebugMode) {
      debugPrint('Reports loaded: ${_reportGroups.length} categories');
    }
  }

  Future<void> _runReport(String reportId, String reportName) async {
    setState(() => _loading = true);

    try {
      // Set filter first (required by API)
      await ApiService.instance.app.postData(
        'report/filter/set',
        body: {'report': reportId, 'filter': 'today'},
      );

      // Fetch report data
      final data = await ApiService.instance.app.get('getreport/$reportId');

      if (!mounted) return;
      setState(() => _loading = false);

      // Show report results
      _showReportResults(reportName, data.raw);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading report: $e')),
      );
    }
  }

  void _showReportResults(String title, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Report Result',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Data
              Expanded(
                child: _buildReportData(data, scrollCtrl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportData(Map<String, dynamic> data, ScrollController scrollCtrl) {
    // Extract list data from various possible response formats
    List<dynamic> rows = [];
    if (data['data'] is List) {
      rows = data['data'] as List;
    } else if (data['rows'] is List) {
      rows = data['rows'] as List;
    } else if (data['records'] is List) {
      rows = data['records'] as List;
    }

    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    // Get column headers from first row keys
    final firstRow = rows.firstWhere((r) => r is Map, orElse: () => {});
    final columns = firstRow is Map ? firstRow.keys.toList() : ['Value'];

    return SingleChildScrollView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: rows.map((row) {
          if (row is! Map) return const SizedBox.shrink();
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: columns.map((col) {
                  final val = row[col]?.toString() ?? '-';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$col: ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            val,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Reports',
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reportGroups.length,
                  itemBuilder: (context, index) {
                    final category = _reportGroups.keys.elementAt(index);
                    final reports = _reportGroups[category]!;
                    return _buildCategoryCard(category, reports, colorScheme);
                  },
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadReports,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category, List<_ReportItem> reports, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Group',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${reports.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Reports list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
            itemBuilder: (context, i) {
              final r = reports[i];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  r.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  r.function,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _runReport(r.function, r.name),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportItem {
  final String function;
  final String name;
  final String keyField;

  _ReportItem(this.function, this.name, this.keyField);
}
