import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../widgets/app_header.dart';
import 'payment_collection_dialog.dart';
import 'order_status_dialog.dart';

class SalesDetailsPage extends StatefulWidget {
  final String saleId;

  const SalesDetailsPage({
    super.key,
    required this.saleId,
  });

  @override
  State<SalesDetailsPage> createState() => _SalesDetailsPageState();
}

class _SaleItem {
  final String productName;
  final double quantity;
  final double price;
  final double discount;
  final double total;

  const _SaleItem({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.discount,
    required this.total,
  });
}

class _SaleDetails {
  final String id;
  final String customerName;
  final String? customerPhone;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String status;
  final String saleType;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? notes;
  final String? tableNo;
  final String? paymentType;
  final double vat;
  final double discount;

  const _SaleDetails({
    required this.id,
    required this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.status,
    required this.saleType,
    required this.createdAt,
    this.dueDate,
    this.notes,
    this.tableNo,
    this.paymentType,
    required this.vat,
    required this.discount,
  });

  bool get isPaid => balanceAmount <= 0;
  bool get isInvoice => saleType.toLowerCase() == 'invoice';
  bool get isOrder => saleType.toLowerCase() == 'order' || saleType.toLowerCase() == 'orders';
}

class _SalesDetailsPageState extends State<SalesDetailsPage> {
  bool _loading = true;
  String? _error;
  _SaleDetails? _saleDetails;
  List<_SaleItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchSaleDetails();
  }

  double _parseAmount(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    final s = raw.toString().replaceAll(',', '').trim();
    return double.tryParse(s) ?? 0;
  }

  DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    final s = raw.toString().trim();
    final dt = DateTime.tryParse(s);
    return dt ?? DateTime.now();
  }

  Future<void> _fetchSaleDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.instance.app.getSaleRecord(widget.saleId);

      if (raw is Map) {
        final saleData = raw['sale'];
        final itemsData = raw['items'];

        if (saleData is Map) {
          _saleDetails = _SaleDetails(
            id: saleData['sale_id']?.toString() ?? saleData['id']?.toString() ?? '',
            customerName: saleData['customer_name']?.toString() ??
                saleData['customer']?.toString() ??
                'Customer',
            customerPhone: saleData['customer_phone']?.toString() ??
                saleData['phone']?.toString(),
            totalAmount: _parseAmount(
              saleData['total_amount'] ?? saleData['amount'] ?? saleData['grand_total'],
            ),
            paidAmount: _parseAmount(
              saleData['paid_amount'] ?? saleData['paid'] ?? saleData['amount_paid'] ?? 0,
            ),
            balanceAmount: _parseAmount(
              saleData['balance_amount'] ?? saleData['balance'] ?? 0,
            ),
            status: saleData['status']?.toString() ?? 'active',
            saleType: saleData['sale_type']?.toString() ?? 'cashsale',
            createdAt: _parseDate(
              saleData['created_at'] ?? saleData['date'] ?? saleData['sale_date'],
            ),
            dueDate: saleData['due_date'] != null
                ? _parseDate(saleData['due_date'])
                : null,
            notes: saleData['notes']?.toString() ?? saleData['remark']?.toString(),
            tableNo: saleData['table_no']?.toString(),
            paymentType: saleData['payment_type']?.toString(),
            vat: _parseAmount(saleData['vat'] ?? 0),
            discount: _parseAmount(saleData['discount'] ?? 0),
          );
        }

        if (itemsData is List) {
          _items = itemsData.map((item) {
            if (item is! Map) return null;
            return _SaleItem(
              productName: item['product_name']?.toString() ??
                  item['name']?.toString() ??
                  'Product',
              quantity: _parseAmount(item['quantity'] ?? item['qty'] ?? 0),
              price: _parseAmount(item['price'] ?? item['price_per_unit'] ?? 0),
              discount: _parseAmount(item['discount'] ?? 0),
              total: _parseAmount(item['total'] ?? item['total_price'] ?? 0),
            );
          }).whereType<_SaleItem>().toList();
        }
      }

      if (!mounted) return;
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Sale Details',
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
        actions: [
          IconButton(
            onPressed: _fetchSaleDetails,
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
          IconButton(
            onPressed: () {
              // TODO: Print receipt
            },
            tooltip: 'Print',
            icon: const Icon(Icons.print),
          ),
          IconButton(
            onPressed: () {
              // TODO: Share
            },
            tooltip: 'Share',
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
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
                'Failed to load sale details',
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
                onPressed: _fetchSaleDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_saleDetails == null) {
      return const Center(
        child: Text(
          'Sale not found',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSaleDetails,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSaleHeader(colorScheme),
            const SizedBox(height: 16),
            _buildCustomerInfo(colorScheme),
            const SizedBox(height: 16),
            _buildItemsList(colorScheme),
            const SizedBox(height: 16),
            _buildSummary(colorScheme),
            const SizedBox(height: 16),
            if (_saleDetails!.notes != null) _buildNotes(colorScheme),
            const SizedBox(height: 16),
            _buildActions(colorScheme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleHeader(ColorScheme colorScheme) {
    final sale = _saleDetails!;
    final statusColor = sale.isPaid
        ? const Color(0xFF00C853)
        : (sale.isOrder ? const Color(0xFF00B0FF) : const Color(0xFFFF6D00));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                      'Sale #${sale.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TSh ${sale.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
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
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sale.isPaid
                          ? 'PAID'
                          : (sale.isOrder ? 'ORDER' : 'UNPAID'),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: statusColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                DateFormat('dd MMM yyyy, HH:mm').format(sale.createdAt),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.receipt_long, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                sale.saleType.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(ColorScheme colorScheme) {
    final sale = _saleDetails!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Customer',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sale.customerName,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF111827),
            ),
          ),
          if (sale.customerPhone != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  sale.customerPhone!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
          if (sale.tableNo != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.table_restaurant, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Table ${sale.tableNo}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Items (${_items.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No items found',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.quantity.toStringAsFixed(2)} x TSh ${item.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'TSh ${item.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(ColorScheme colorScheme) {
    final sale = _saleDetails!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Summary',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', sale.totalAmount - sale.vat - sale.discount),
          if (sale.discount > 0) _buildSummaryRow('Discount', -sale.discount, isNegative: true),
          if (sale.vat > 0) _buildSummaryRow('VAT', sale.vat),
          const Divider(height: 24),
          _buildSummaryRow('Total', sale.totalAmount, isTotal: true),
          const SizedBox(height: 8),
          _buildSummaryRow('Paid', sale.paidAmount, color: const Color(0xFF00C853)),
          if (sale.balanceAmount > 0)
            _buildSummaryRow('Balance', sale.balanceAmount, color: const Color(0xFFFF6D00)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false, bool isNegative = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
              fontSize: isTotal ? 16 : 13,
              color: isTotal ? const Color(0xFF111827) : Colors.grey.shade700,
            ),
          ),
          Text(
            'TSh ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              fontSize: isTotal ? 18 : 14,
              color: color ?? (isTotal ? const Color(0xFF111827) : Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(ColorScheme colorScheme) {
    final sale = _saleDetails!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: const Color(0xFF9A3412), size: 18),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: const Color(0xFF9A3412),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sale.notes!,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF9A3412),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(ColorScheme colorScheme) {
    final sale = _saleDetails!;

    return Column(
      children: [
        if (!sale.isPaid)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => PaymentCollectionDialog(
                    saleId: sale.id,
                    customerName: sale.customerName,
                    balanceAmount: sale.balanceAmount,
                    onSuccess: () {
                      _fetchSaleDetails();
                    },
                  ),
                );
              },
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Record Payment'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        if (sale.isOrder)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => OrderStatusDialog(
                      saleId: sale.id,
                      currentStatus: sale.status,
                      onSuccess: () {
                        _fetchSaleDetails();
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.assignment),
                label: const Text('Update Status'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Edit sale
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Sale'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
