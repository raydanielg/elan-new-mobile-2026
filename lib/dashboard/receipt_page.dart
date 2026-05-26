import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';
import '../services/permission_service.dart';

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({
    super.key,
    required this.saleId,
    required this.saleData,
  });

  final String saleId;
  final Map<String, dynamic> saleData;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  bool _isLoadingPreview = false;
  bool _isSendingEmail = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final perm = PermissionService();
    final sale = widget.saleData['sale'] ?? widget.saleData['header'] ?? widget.saleData['data']?['sale'] ?? widget.saleData;
    final items = _asList(sale['items'] ?? widget.saleData['items'] ?? widget.saleData['sold_items'] ?? []);

    // Extract data
    final dateStr = sale['date']?.toString() ?? sale['record_date']?.toString() ?? '';
    final total = double.tryParse(sale['total_amount']?.toString() ?? sale['total']?.toString() ?? '0') ?? 0.0;
    final paid = double.tryParse(sale['paid_amount']?.toString() ?? sale['paid']?.toString() ?? '0') ?? 0.0;
    final discount = double.tryParse(sale['discount']?.toString() ?? '0') ?? 0.0;
    final vat = double.tryParse(sale['vat']?.toString() ?? sale['tax']?.toString() ?? '0') ?? 0.0;
    final balance = total - paid;

    final type = sale['sale_type']?.toString() ?? sale['status']?.toString() ?? 'Sale';
    final status = sale['status']?.toString() ?? (balance <= 0 ? 'Closed' : 'Pending');
    final customer = sale['customer']?.toString() ?? sale['customer_name']?.toString() ?? 'Walk-in Customer';
    final customerPhone = sale['customer_phone']?.toString() ?? '';
    final customerTin = sale['customer_tin']?.toString() ?? '';
    final staff = sale['username']?.toString() ?? sale['served_by']?.toString() ?? 'System';
    final waiter = sale['waiter']?.toString() ?? '';
    final tableNo = sale['table_no']?.toString() ?? '';
    final paymentMode = sale['payment_mode']?.toString() ?? (balance <= 0 ? 'Cash' : 'Pending');

    // Get business info from API/session - use safe fallbacks
    final businessName = _getBusinessName();
    final businessAddress = 'Your Business Address';
    final businessPhone = '';
    final businessTin = '';

    // Determine prefix based on type
    String prefix = 'SAL#';
    String docType = 'CASH SALE';
    if (type.toLowerCase().contains('order')) {
      prefix = 'ORD#';
      docType = 'ORDER';
    } else if (type.toLowerCase().contains('invoice')) {
      prefix = 'INV#';
      docType = 'INVOICE';
    } else if (type.toLowerCase().contains('quot') || type.toLowerCase().contains('quote')) {
      prefix = 'QT#';
      docType = 'QUOTATION';
    }

    final invoiceNo = sale['sale_id']?.toString() ?? sale['id']?.toString() ?? widget.saleId;
    final displayId = '$prefix$invoiceNo';

    final currencyFormat = NumberFormat.currency(symbol: '', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final displayDate = dateStr.isNotEmpty ? dateStr : DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Preview - requires can_preview_receipt
          if (perm.canPreviewReceipt)
            IconButton(
              icon: _isLoadingPreview 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.open_in_browser_outlined),
              onPressed: _isLoadingPreview ? null : () => _previewReceipt(),
              tooltip: 'Preview Receipt',
            ),
          
          // Download - requires can_print_receipt (for PDF download)
          if (perm.canPrintReceipt)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed: _isLoadingPreview ? null : () => _downloadReceipt(),
              tooltip: 'Download Receipt',
            ),
          
          // Email - requires can_send_email
          if (perm.canSendEmail)
            IconButton(
              icon: _isSendingEmail
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.email_outlined),
              onPressed: _isSendingEmail ? null : () => _emailReceipt(),
              tooltip: 'Email Receipt',
            ),
          
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                // Receipt Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Receipt Content with padding
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Business Header
                            _buildBusinessHeader(
                              businessName: businessName,
                              businessAddress: businessAddress,
                              businessPhone: businessPhone,
                              businessTin: businessTin,
                            ),

                            const Divider(height: 24, thickness: 1),

                            // Document Type & Number
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    docType,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: colorScheme.primary,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    displayId,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Date and Status Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoColumn('DATE', displayDate),
                                _buildStatusBadge(status, balance),
                              ],
                            ),

                            const Divider(height: 24, thickness: 1),

                            // Customer Info
                            _buildSectionTitle('CUSTOMER'),
                            _buildInfoRow('Name', customer),
                            if (customerPhone.isNotEmpty)
                              _buildInfoRow('Phone', customerPhone),
                            if (customerTin.isNotEmpty)
                              _buildInfoRow('TIN', customerTin),

                            const Divider(height: 24, thickness: 1),

                            // Items Table Header
                            _buildSectionTitle('ITEMS'),
                            const SizedBox(height: 8),

                            // Items
                            ...items.map((item) => _buildItemRow(
                              name: item['product_name']?.toString() ?? 'Item',
                              qty: double.tryParse(item['quantity']?.toString() ?? '0') ?? 0,
                              price: double.tryParse(item['price_per_unit']?.toString() ?? '0') ?? 0,
                              total: double.tryParse(item['total_price']?.toString() ?? '0') ?? 0,
                            )),

                            const Divider(height: 24, thickness: 1),

                            // Summary
                            _buildSummaryRow('Subtotal', total + discount - vat),
                            if (discount > 0)
                              _buildSummaryRow('Discount', discount, isNegative: true),
                            if (vat > 0)
                              _buildSummaryRow('VAT (18%)', vat),
                            const Divider(height: 16),
                            _buildSummaryRow('TOTAL', total, isBold: true, isTotal: true),
                            _buildSummaryRow('PAID', paid, color: Colors.green),
                            _buildSummaryRow('BALANCE', balance, color: balance > 0 ? Colors.red : Colors.green, isBold: true),

                            const Divider(height: 24, thickness: 1),

                            // Payment Info
                            _buildInfoRow('Payment Mode', paymentMode),
                            if (waiter.isNotEmpty)
                              _buildInfoRow('Waiter', waiter),
                            if (tableNo.isNotEmpty)
                              _buildInfoRow('Table No', tableNo),
                            _buildInfoRow('Served By', staff),

                            const SizedBox(height: 24),

                            // Footer
                            _buildReceiptFooter(),
                          ],
                        ),
                      ),

                      // Zigzag bottom edge
                      CustomPaint(
                        size: const Size(double.infinity, 12),
                        painter: ZigzagPainter(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons - only show if user has permissions
                Row(
                  children: [
                    // Preview button - requires can_preview_receipt
                    if (PermissionService().canPreviewReceipt)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingPreview ? null : () => _previewReceipt(),
                          icon: _isLoadingPreview
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.open_in_browser_outlined),
                          label: Text(_isLoadingPreview ? 'Loading...' : 'Preview'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    
                    if (PermissionService().canPreviewReceipt && PermissionService().canPrintReceipt)
                      const SizedBox(width: 12),
                    
                    // Download button - requires can_print_receipt
                    if (PermissionService().canPrintReceipt)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoadingPreview ? null : () => _downloadReceipt(),
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Download PDF'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: colorScheme.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessHeader({
    required String businessName,
    required String businessAddress,
    required String businessPhone,
    required String businessTin,
  }) {
    return Column(
      children: [
        // Logo placeholder
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.receipt_long_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          businessName.toUpperCase(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          businessAddress,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
        if (businessPhone.isNotEmpty)
          Text(
            'Tel: $businessPhone',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        if (businessTin.isNotEmpty)
          Text(
            'TIN: $businessTin',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, double balance) {
    Color color;
    String text;
    if (balance <= 0) {
      color = Colors.green;
      text = 'PAID';
    } else if (balance > 0 && balance < (balance * 2)) {
      color = Colors.orange;
      text = 'PARTIAL';
    } else {
      color = Colors.red;
      text = 'UNPAID';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required String name,
    required double qty,
    required double price,
    required double total,
  }) {
    final fmt = NumberFormat('#,##0');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${qty.toStringAsFixed(0)}x',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${fmt.format(price)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${fmt.format(total)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isTotal = false,
    bool isNegative = false,
    Color? color,
  }) {
    final fmt = NumberFormat('#,##0');
    final displayAmount = isNegative ? '-${fmt.format(amount)}' : fmt.format(amount);
    final textColor = color ?? (isTotal ? const Color(0xFF1E293B) : const Color(0xFF64748B));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold || isTotal ? 13 : 12,
              fontWeight: isBold || isTotal ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          Text(
            'TSh $displayAmount',
            style: TextStyle(
              fontSize: isBold || isTotal ? 14 : 12,
              fontWeight: isBold || isTotal ? FontWeight.w900 : FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptFooter() {
    return Column(
      children: [
        const Divider(height: 16),
        const Text(
          'THANK YOU FOR YOUR BUSINESS!',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Receipt generated by ElanLedgers POS',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Powered by ELAN SOLUTIONS',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Future<void> _previewReceipt() async {
    setState(() => _isLoadingPreview = true);
    
    try {
      final url = ApiService.instance.app.getReceiptPreviewUrl(widget.saleId);
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch preview URL';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preview failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    }
  }

  Future<void> _downloadReceipt() async {
    setState(() => _isLoadingPreview = true);
    
    try {
      final url = ApiService.instance.app.getReceiptDownloadUrl(widget.saleId);
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening download...'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw 'Could not launch download URL';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingPreview = false);
      }
    }
  }

  Future<void> _emailReceipt() async {
    if (_isSendingEmail) return;
    
    final sale = widget.saleData['sale'] ?? widget.saleData['header'] ?? widget.saleData['data']?['sale'] ?? widget.saleData;
    final customerEmail = sale['customer_email']?.toString() ?? '';
    
    final emailController = TextEditingController(text: customerEmail);
    
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Email Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter recipient email address:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'email@example.com',
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
      setState(() => _isSendingEmail = true);
      
      try {
        final res = await ApiService.instance.app.emailReceipt(
          saleId: widget.saleId,
          to: email,
        );
        
        if (!mounted) return;
        
        if (res.status) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message ?? 'Receipt emailed successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          throw Exception(res.message ?? 'Failed to email receipt');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isSendingEmail = false);
        }
      }
    }
  }


  List<dynamic> _asList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return [];
  }

  String _getBusinessName() {
    // Try to get business name from various sources
    final sale = widget.saleData['sale'] ?? widget.saleData['header'] ?? widget.saleData['data']?['sale'] ?? widget.saleData;
    final shopName = sale['shop_name']?.toString() ??
        sale['business_name']?.toString() ??
        widget.saleData['shop_name']?.toString() ??
        widget.saleData['business_name']?.toString();
    return shopName ?? 'ELAN LEDGERS';
  }
}

// Zigzag pattern painter for receipt bottom edge
class ZigzagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);

    // Draw zigzag
    const zigzagWidth = 12.0;
    var x = size.width;
    var isUp = true;
    while (x > 0) {
      x -= zigzagWidth / 2;
      final y = isUp ? 0.0 : size.height;
      path.lineTo(x, y);
      isUp = !isUp;
    }

    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
