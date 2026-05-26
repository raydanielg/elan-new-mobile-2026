import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../services/permission_service.dart';
import '../widgets/permission_gate.dart';
import 'receipt_page.dart';

class SaleDetailsPage extends StatefulWidget {
  const SaleDetailsPage({
    super.key,
    required this.saleId,
    this.initialData,
    this.isModal = false,
  });

  final String saleId;
  final Map<String, dynamic>? initialData;
  final bool isModal;

  @override
  State<SaleDetailsPage> createState() => _SaleDetailsPageState();
}

class _SaleDetailsPageState extends State<SaleDetailsPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _data = widget.initialData;
      _loading = false;
    } else {
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.instance.app.getSaleRecord(widget.saleId);
      if (!mounted) return;

      setState(() {
        _data = res is Map<String, dynamic> ? res : null;
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

    if (widget.isModal) {
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _buildActionToolbar(),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : _data == null
                          ? const Center(child: Text('No details found'))
                          : _buildDetails(_data!),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Sale Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.email_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _data == null
                  ? const Center(child: Text('No details found'))
                  : _buildDetails(_data!),
      bottomNavigationBar: _data != null ? _buildBottomActions() : null,
    );
  }

  Widget _buildActionToolbar() {
    final perm = PermissionService();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Email - requires can_send_email permission
          if (perm.canSendEmail)
            _ActionButton(
              icon: Icons.email_outlined,
              label: 'Email',
              onTap: () => _handleEmailAction(),
            ),
          
          // Pay - requires can_make_sales permission
          if (perm.canMakeSales)
            _ActionButton(
              icon: Icons.payments_outlined,
              label: 'Pay',
              onTap: () => _handlePayAction(),
              color: Colors.green,
            ),
          
          // Edit - requires can_edit_entry permission
          if (perm.canEditEntry)
            _ActionButton(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: () => _handleEditAction(),
            ),
          
          // Receipt - requires can_preview_receipt or can_print_receipt
          if (perm.canPreviewReceipt || perm.canPrintReceipt)
            _ActionButton(
              icon: Icons.receipt_long_outlined,
              label: 'Receipt',
              onTap: () => _handleReceiptAction(),
              color: Theme.of(context).colorScheme.primary,
            ),
          
          // Delete - requires can_delete_entry permission
          if (perm.canDeleteEntry)
            _ActionButton(
              icon: Icons.delete_outline,
              label: 'Delete',
              onTap: () => _handleDeleteAction(),
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  void _handleReceiptAction() {
    if (_data == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptPage(
          saleId: widget.saleId,
          saleData: _data!,
        ),
      ),
    );
  }

  Future<void> _handleEmailAction() async {
    if (_data == null) return;
    final sale = _data!['sale'] ?? _data!['header'] ?? _data!['data']?['sale'] ?? _data!;
    // Use session user's email, fallback to customer email from sale data
    final currentEmail = ApiService.instance.tokenStore.userEmail ??
        sale['customer_email']?.toString() ??
        sale['email']?.toString() ??
        '';
    final saleId = widget.saleId;
    final saleType = sale['sale_type']?.toString() ?? 'sale';

    final emailController = TextEditingController(text: currentEmail);

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send via Email', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your email (session):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'your-email@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(context, emailController.text.trim()),
            child: const Text('SEND'),
          ),
        ],
      ),
    );

    if (email != null && email.isNotEmpty) {
      if (!mounted) return;
      
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending email...'), duration: Duration(seconds: 1)),
      );

      try {
        final res = await ApiService.instance.app.sendEmail(
          type: saleType,
          recordId: saleId,
          email: email,
        );

        if (!mounted) return;

        if (res.status) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message ?? 'Success'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          throw Exception(res.message);
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handlePayAction() async {
    if (_data == null) return;
    final sale = _data!['sale'] ?? _data!['header'] ?? _data!['data']?['sale'] ?? _data!;
    
    final total = double.tryParse(sale['total_amount']?.toString() ?? sale['total']?.toString() ?? '0') ?? 0.0;
    final paid = double.tryParse(sale['paid_amount']?.toString() ?? sale['paid']?.toString() ?? '0') ?? 0.0;
    final balance = total - paid;

    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This record is already fully paid'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Fetch accounts for payment
    List<dynamic> accounts = [];
    try {
      final res = await ApiService.instance.app.getData('cashbookAccounts');
      if (res is Map && res['data'] is List) {
        accounts = res['data'] as List;
      } else if (res is List) {
        accounts = res;
      }
    } catch (e) {
      // Continue with empty accounts - will show error in dialog if empty
    }

    if (!mounted) return;

    final amountController = TextEditingController(text: balance.toStringAsFixed(0));
    final dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    String? selectedAccountId = accounts.isNotEmpty ? accounts.first['id']?.toString() : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.payments_outlined, color: Colors.green),
                SizedBox(width: 8),
                Text('Add Payment', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Balance Due:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        Text(
                          NumberFormat.currency(symbol: 'TSh ', decimalDigits: 0).format(balance),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date picker
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Payment Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setDialogState(() {
                          dateController.text = DateFormat('yyyy-MM-dd').format(date);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Amount input
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Account selector
                  if (accounts.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      decoration: InputDecoration(
                        labelText: 'To Account',
                        prefixIcon: const Icon(Icons.account_balance),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: accounts.map((account) {
                        final id = account['id']?.toString() ?? '';
                        final name = account['account_name']?.toString() ?? account['name']?.toString() ?? 'Unknown';
                        return DropdownMenuItem(value: id, child: Text(name, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (value) => setDialogState(() => selectedAccountId = value),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(child: Text('No payment accounts available. Please set up accounts first.', style: TextStyle(fontSize: 12, color: Colors.orange))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: accounts.isEmpty || selectedAccountId == null
                    ? null
                    : () async {
                        final amount = double.tryParse(amountController.text.trim()) ?? 0;
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        if (amount > balance) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Overpayment Warning'),
                              content: Text('Amount (TSh ${NumberFormat('#,##0').format(amount)}) exceeds the balance (TSh ${NumberFormat('#,##0').format(balance)}). Continue?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NO')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('YES')),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                        }
                        Navigator.pop(context);
                        await _submitPayment(amount, dateController.text, selectedAccountId!);
                      },
                child: const Text('POST PAYMENT'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitPayment(double amount, String date, String accountId) async {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing payment...'), duration: Duration(seconds: 1)),
    );

    try {
      final res = await ApiService.instance.app.addPayment(
        saleId: widget.saleId,
        amount: amount,
        date: date,
        toAccount: accountId,
      );

      if (!mounted) return;

      if (res.status) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? 'Payment recorded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Refresh sale details to show updated payment status
        _fetchDetails();
      } else {
        throw Exception(res.message ?? 'Payment failed');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleEditAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon'), behavior: SnackBarBehavior.floating),
    );
  }

  void _handleReturnAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Return feature coming soon'), behavior: SnackBarBehavior.floating),
    );
  }

  void _handleDeleteAction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this record? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete feature coming soon'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final perm = PermissionService();
    
    // Only show payment button if user has can_make_sales permission
    if (!perm.canMakeSales) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handlePayAction,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('POST PAYMENT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(Map<String, dynamic> data) {
    final sale = data['sale'] ?? data['header'] ?? data['data']?['sale'] ?? data;
    final items = _asList(sale['items'] ?? data['items'] ?? data['sold_items'] ?? []);
    
    final colorScheme = Theme.of(context).colorScheme;

    final dateStr = sale['date']?.toString() ?? sale['record_date']?.toString() ?? '';
    final total = double.tryParse(sale['total_amount']?.toString() ?? sale['total']?.toString() ?? '0') ?? 0.0;
    final paid = double.tryParse(sale['paid_amount']?.toString() ?? sale['paid']?.toString() ?? '0') ?? 0.0;
    final discount = double.tryParse(sale['discount']?.toString() ?? '0') ?? 0.0;
    final balance = total - paid;
    
    final type = sale['sale_type']?.toString() ?? sale['status']?.toString() ?? 'Sale';
    final status = sale['status']?.toString() ?? (balance <= 0 ? 'Closed' : 'Pending');
    final customer = sale['customer']?.toString() ?? sale['customer_name']?.toString() ?? 'Guest';
    final staff = sale['username']?.toString() ?? '';
    
    // Determine prefix based on type
    String prefix = 'SAL#';
    if (type.toLowerCase().contains('order')) prefix = 'ORD#';
    else if (type.toLowerCase().contains('invoice')) prefix = 'INV#';
    
    final invoiceNo = sale['sale_id']?.toString() ?? sale['id']?.toString() ?? '---';
    final displayId = '$prefix$invoiceNo';

    final statusColor = _getStatusColor(status);
    final currencyFormat = NumberFormat.currency(symbol: 'TSh ', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(displayId, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('$customer • $staff', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildSummaryLine('Grand Total', total, primary: true),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(child: _buildMiniStat('Paid', paid, Colors.green)),
                    Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                    Expanded(child: _buildMiniStat('Balance', balance, balance > 0 ? Colors.red : Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('RECEIPT DETAILS'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: [
                _buildInfoRow('Served By', staff.isNotEmpty ? staff : 'System'),
                _buildInfoRow('Table No', sale['table_no']?.toString() ?? '-'),
                _buildInfoRow('Payment Mode', sale['payment_mode']?.toString() ?? 'Pending Payment'),
                _buildInfoRow('Document Date', dateStr),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('ITEMS'),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: items.map((item) {
                final name = item['product_name']?.toString() ?? 'Item';
                final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
                final price = double.tryParse(item['price_per_unit']?.toString() ?? '0') ?? 0.0;
                final itemTotal = double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  subtitle: Text('${qty.toStringAsFixed(0)} × ${currencyFormat.format(price)}', style: const TextStyle(fontSize: 12)),
                  trailing: Text(currencyFormat.format(itemTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('RECEIPT SUMMARY'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(
              children: [
                _buildSummaryDetail('Total', total),
                _buildSummaryDetail('Discount', discount),
                _buildSummaryDetail('Paid', paid),
                const Divider(),
                _buildSummaryDetail('Balance', balance, isBold: true, color: balance > 0 ? Colors.red : Colors.green),
              ],
            ),
          ),
          if (type.toLowerCase().contains('order'))
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
              child: Text(
                'This record is still an order. Balance remains due until payment is posted.',
                style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, double amount, {bool primary = false}) {
    final fmt = NumberFormat.currency(symbol: 'TSh ', decimalDigits: 0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: primary ? 14 : 13, fontWeight: primary ? FontWeight.w900 : FontWeight.w600, color: const Color(0xFF64748B))),
        Text(fmt.format(amount), style: TextStyle(fontSize: primary ? 20 : 16, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildSummaryDetail(String label, double amount, {bool isBold = false, Color? color}) {
    final fmt = NumberFormat.currency(symbol: 'TSh ', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: const Color(0xFF64748B))),
          Text(fmt.format(amount), style: TextStyle(fontWeight: isBold ? FontWeight.w900 : FontWeight.w800, color: color ?? const Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, Color color) {
    final fmt = NumberFormat.currency(symbol: 'TSh ', decimalDigits: 0);
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(fmt.format(amount), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchDetails, child: const Text('Retry')),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('paid') || s.contains('closed') || s.contains('complete')) return Colors.green;
    if (s.contains('partial')) return Colors.orange;
    if (s.contains('unpaid') || s.contains('due') || s.contains('pending')) return Colors.red;
    return Colors.blue;
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return [];
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? const Color(0xFF64748B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: themeColor, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
