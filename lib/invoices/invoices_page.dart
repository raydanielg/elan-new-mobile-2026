import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../widgets/app_header.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _LocalInvoice {
  final String customer;
  final double amount;
  final String? status;
  final String? invoiceNumber;
  final DateTime createdAt;

  const _LocalInvoice({
    required this.customer,
    required this.amount,
    required this.createdAt,
    this.status,
    this.invoiceNumber,
  });
}

class _InvoicesPageState extends State<InvoicesPage> {
  bool _loading = false;
  String? _error;
  List<_LocalInvoice> _invoices = <_LocalInvoice>[];

  String? _userId;
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
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

  List<_LocalInvoice> _parseInvoices(dynamic raw) {
    dynamic data = raw;
    if (raw is Map && raw['data'] != null) data = raw['data'];

    final list = (data is List)
        ? data
        : (data is Map && data['rows'] is List)
            ? data['rows']
            : (data is Map && data['list'] is List)
                ? data['list']
                : null;

    final out = <_LocalInvoice>[];
    if (list is List) {
      for (final item in list) {
        if (item is! Map) continue;
        final customer = item['customer_name']?.toString() ??
            item['customer']?.toString() ??
            item['name']?.toString() ??
            'Customer';

        final amount = _parseAmount(
          item['amount'] ??
              item['total_amount'] ??
              item['grand_total'] ??
              item['total'] ??
              item['invoice_amount'],
        );

        final status = item['status']?.toString() ?? item['invoice_status']?.toString();
        final invoiceNumber = item['invoice_number']?.toString() ??
            item['invoice_no']?.toString() ??
            item['number']?.toString();
        final createdAt = _parseDate(
          item['created_at'] ?? item['date'] ?? item['invoice_date'] ?? item['createdAt'],
        );

        out.add(
          _LocalInvoice(
            customer: customer.trim().isEmpty ? 'Customer' : customer.trim(),
            amount: amount,
            status: (status != null && status.trim().isNotEmpty) ? status.trim() : null,
            invoiceNumber: (invoiceNumber != null && invoiceNumber.trim().isNotEmpty)
                ? invoiceNumber.trim()
                : null,
            createdAt: createdAt,
          ),
        );
      }
    }
    return out;
  }

  Future<void> _fetchInvoices() async {
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
        '/app/get/getdata/invoices',
        queryParameters: qp.isEmpty ? null : qp,
      );
      final invoices = _parseInvoices(raw);
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
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

  Future<void> _openCreateInvoice() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Invoice - Coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final total = _invoices.fold<double>(0, (sum, i) => sum + i.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Invoices',
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateInvoice,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Invoice'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchInvoices,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
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
                          color: colorScheme.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Invoices',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_invoices.length} invoices',
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
                            'Total',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${total.toStringAsFixed(2)} TZS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
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
                          onPressed: _fetchInvoices,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_invoices.isEmpty)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No invoices found',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ..._invoices.map((invoice) {
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        invoice.customer,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatDate(invoice.createdAt)),
                          if (invoice.invoiceNumber != null)
                            Text(
                              'INV: ${invoice.invoiceNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (invoice.status != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                invoice.status!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        '${invoice.amount.toStringAsFixed(2)} TZS',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
