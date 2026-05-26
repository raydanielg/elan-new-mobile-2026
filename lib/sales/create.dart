import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/api_service.dart';
import '../widgets/app_header.dart';

class CreateSalePage extends StatefulWidget {
  const CreateSalePage({super.key});

  @override
  State<CreateSalePage> createState() => _CreateSalePageState();
}

class _CreateSalePageState extends State<CreateSalePage> {
  final _formKey = GlobalKey<FormState>();

  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _productSearchController = TextEditingController();

  DateTime _recordDate = DateTime.now();
  bool _wholeSale = false;

  bool _loadingLookups = false;
  String? _lookupError;

  List<_Customer> _customers = const [];
  _Customer? _selectedCustomer;

  List<_PaymentMode> _paymentModes = const [];
  _PaymentMode? _selectedPaymentMode;

  List<_SellableProduct> _products = const [];
  final List<_SaleLine> _lines = <_SaleLine>[];

  bool _saving = false;

  @override
  void dispose() {
    _paidAmountController.dispose();
    _notesController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }

  double? _parseAmount(String raw) {
    final normalized = raw.replaceAll(',', '').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  @override
  void initState() {
    super.initState();
    _loadLookups();
    _productSearchController.addListener(() => setState(() {}));
  }

  Future<void> _loadLookups() async {
    setState(() {
      _loadingLookups = true;
      _lookupError = null;
    });

    try {
      final customersRaw = await ApiService.instance.app.getData('customers');
      final paymentRaw = await ApiService.instance.app.getData('payment_mode');

      dynamic productsRaw;
      try {
        productsRaw = await ApiService.instance.app.getData('sellable_stock');
      } catch (_) {
        productsRaw = await ApiService.instance.app.getData('products');
      }

      final customers = _parseCustomers(customersRaw);
      final modes = _parsePaymentModes(paymentRaw);
      final products = _parseSellableProducts(productsRaw);

      if (!mounted) return;
      setState(() {
        _customers = customers;
        _paymentModes = modes;
        _products = products;
        _selectedCustomer ??= customers.isEmpty ? null : customers.first;
        _selectedPaymentMode ??= modes.isEmpty ? null : modes.first;
        _loadingLookups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLookups = false;
        _lookupError = e.toString();
      });
    }
  }

  List<_Customer> _parseCustomers(dynamic raw) {
    dynamic data = raw;
    if (raw is Map && raw['data'] != null) data = raw['data'];
    if (data is Map && data['rows'] != null) data = data['rows'];
    if (data is Map && data['list'] != null) data = data['list'];

    final out = <_Customer>[];
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final id = item['customer_id']?.toString() ?? item['id']?.toString() ?? '';
        final name = item['customer_name']?.toString() ??
            item['name']?.toString() ??
            item['full_name']?.toString() ??
            '';
        if (id.trim().isEmpty && name.trim().isEmpty) continue;
        out.add(_Customer(id: id.trim(), name: name.trim().isEmpty ? id.trim() : name.trim()));
      }
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  List<_PaymentMode> _parsePaymentModes(dynamic raw) {
    dynamic data = raw;
    if (raw is Map && raw['data'] != null) data = raw['data'];
    if (data is Map && data['rows'] != null) data = data['rows'];
    if (data is Map && data['list'] != null) data = data['list'];

    final out = <_PaymentMode>[];
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final id = item['account_id']?.toString() ??
            item['payment_mode_id']?.toString() ??
            item['id']?.toString() ??
            '';
        final name = item['name']?.toString() ??
            item['account_name']?.toString() ??
            item['payment_mode_name']?.toString() ??
            '';
        if (id.trim().isEmpty && name.trim().isEmpty) continue;
        out.add(_PaymentMode(id: id.trim(), name: name.trim().isEmpty ? id.trim() : name.trim()));
      }
    }
    out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  List<_SellableProduct> _parseSellableProducts(dynamic raw) {
    dynamic data = raw;
    if (raw is Map && raw['data'] != null) data = raw['data'];
    if (raw is Map && raw['result'] != null) data = raw['result'];
    if (data is Map && data['rows'] != null) data = data['rows'];
    if (data is Map && data['list'] != null) data = data['list'];

    final out = <_SellableProduct>[];
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final id = item['product_id']?.toString() ?? item['id']?.toString() ?? '';
        final stockId = item['stock_id']?.toString() ?? item['stockId']?.toString() ?? '';
        final name = item['product_name']?.toString() ?? item['name']?.toString() ?? '';
        final sku = item['sku']?.toString() ?? item['barcode']?.toString() ?? '';
        final price = _parseAmount(item['sp']?.toString() ?? '') ??
            _parseAmount(item['selling_price']?.toString() ?? item['price']?.toString() ?? '') ??
            _parseAmount(item['sale_price']?.toString() ?? '') ??
            0;
        final wholePrice = _parseAmount(item['wp']?.toString() ?? '') ??
            _parseAmount(item['wholesale_price']?.toString() ?? item['whole_sale_price']?.toString() ?? '') ??
            _parseAmount(item['bulk_price']?.toString() ?? '') ??
            price;
        final balance = _parseAmount(item['available']?.toString() ?? '') ??
            _parseAmount(item['available_stock']?.toString() ?? '') ??
            _parseAmount(item['balance']?.toString() ?? item['qty']?.toString() ?? item['quantity']?.toString() ?? '') ??
            0;
        final type = item['type']?.toString().trim().toLowerCase() ?? 'product';
        if (id.trim().isEmpty && name.trim().isEmpty && sku.trim().isEmpty) continue;
        out.add(
          _SellableProduct(
            id: id.trim(),
            stockId: stockId.trim(),
            name: name.trim().isEmpty ? (sku.trim().isEmpty ? id.trim() : sku.trim()) : name.trim(),
            sku: sku.trim(),
            price: price,
            wholesalePrice: wholePrice,
            balance: balance,
            isService: type == 'service',
          ),
        );
      }
    }
    return out;
  }

  List<_SellableProduct> get _filteredProducts {
    final q = _productSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products
        .where(
          (p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q) || p.id.toLowerCase().contains(q),
        )
        .toList();
  }

  void _addProduct(_SellableProduct p) {
    if (!p.isService && p.balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${p.name} is out of stock')),
      );
      return;
    }

    final existingIndex = _lines.indexWhere((l) => l.product.id == p.id && p.id.isNotEmpty);
    if (existingIndex >= 0) {
      setState(() {
        _lines[existingIndex] = _lines[existingIndex].copyWith(qty: _lines[existingIndex].qty + 1);
      });
      return;
    }

    final unitPrice = _wholeSale ? p.wholesalePrice : p.price;
    setState(() {
      _lines.insert(
        0,
        _SaleLine(
          product: p,
          qty: 1,
          unitPrice: unitPrice,
          discount: 0,
        ),
      );
    });
  }

  void _toggleWholeSale(bool v) {
    setState(() {
      _wholeSale = v;
      for (var i = 0; i < _lines.length; i++) {
        final p = _lines[i].product;
        _lines[i] = _lines[i].copyWith(unitPrice: v ? p.wholesalePrice : p.price);
      }
    });
  }

  double get _subTotal => _lines.fold<double>(0, (s, l) => s + (l.qty * l.unitPrice));
  double get _discountTotal => _lines.fold<double>(0, (s, l) => s + l.discount);
  double get _total => (_subTotal - _discountTotal).clamp(0, double.infinity);

  Future<void> _save() async {
    if (_saving) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select customer')),
      );
      return;
    }
    if (_selectedPaymentMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select payment mode')),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one product')),
      );
      return;
    }

    final paidAmount = _parseAmount(_paidAmountController.text) ?? _total;
    final notes = _notesController.text.trim();

    setState(() => _saving = true);

    try {
      final recordDate = '${_recordDate.year.toString().padLeft(4, '0')}-${_recordDate.month.toString().padLeft(2, '0')}-${_recordDate.day.toString().padLeft(2, '0')}';

      final itemStrings = _lines
          .map((l) {
            final subtotal = l.qty * l.unitPrice;
            final total = (subtotal - l.discount).clamp(0, double.infinity);
            return [
              l.product.id,
              l.product.stockId,
              l.qty,
              l.unitPrice,
              l.discount,
              subtotal,
              0,
              total,
            ].join('|');
          })
          .toList();

      await ApiService.instance.app.postData(
        'sales/add',
        body: {
          'date': recordDate,
          'due_date': recordDate,
          'status': 'closed',
          'sale_type': 'cashsale',
          'original_sale_type': 'cashsale',

          'customer_id': _selectedCustomer!.id,

          'payment_mode': _selectedPaymentMode!.id,

          'paid_amount': paidAmount,

          'subtotal': _subTotal,
          'discount': _discountTotal,
          'vat': 0,
          'total_amount': _total,
          'notes': notes,
          'items': itemStrings,
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = (e is ApiException) ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Create cashsale',
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FieldCard(
                        title: 'Record Date',
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _recordDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked == null) return;
                            setState(() => _recordDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_recordDate.month.toString().padLeft(2, '0')}/${_recordDate.day.toString().padLeft(2, '0')}/${_recordDate.year}',
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                const Icon(Icons.calendar_month_outlined, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FieldCard(
                        title: 'Paid Amount',
                        child: TextFormField(
                          controller: _paidAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (v) {
                            final x = _parseAmount(v ?? '') ?? 0;
                            if (x < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Whole Sale', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 10),
                      Switch(
                        value: _wholeSale,
                        onChanged: _toggleWholeSale,
                        activeColor: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sale details',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_loadingLookups)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_lookupError != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _lookupError!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: _loadLookups,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reload'),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              DropdownButtonFormField<_Customer>(
                                value: _selectedCustomer,
                                items: _customers
                                    .map(
                                      (c) => DropdownMenuItem<_Customer>(
                                        value: c,
                                        child: Text(c.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedCustomer = v),
                                decoration: const InputDecoration(
                                  labelText: 'Select customer',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
                                validator: (_) => _selectedCustomer == null ? 'Customer is required' : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<_PaymentMode>(
                                value: _selectedPaymentMode,
                                items: _paymentModes
                                    .map(
                                      (m) => DropdownMenuItem<_PaymentMode>(
                                        value: m,
                                        child: Text(m.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _selectedPaymentMode = v),
                                decoration: const InputDecoration(
                                  labelText: 'Payment mode',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
                                validator: (_) => _selectedPaymentMode == null ? 'Payment mode is required' : null,
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            hintText: 'Add a note…',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                                  const Text('Discount', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Text('TSh ${_discountTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Subtotal', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Text('TSh ${_subTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Amount', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Text('TSh ${_total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _productSearchController,
                          decoration: const InputDecoration(
                            hintText: 'Search product name…',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_products.isEmpty)
                          const Text(
                            'No products loaded',
                            style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                          )
                        else
                          SizedBox(
                            height: 180,
                            child: ListView.separated(
                              itemCount: _filteredProducts.take(20).length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final p = _filteredProducts[index];
                                final price = _wholeSale ? p.wholesalePrice : p.price;
                                return ListTile(
                                  dense: true,
                                  onTap: () => _addProduct(p),
                                  title: Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  subtitle: Text(
                                    '${p.sku.isEmpty ? '' : 'SKU: ${p.sku}   •   '}Bal: ${p.balance.toStringAsFixed(0)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    'TSh ${price.toStringAsFixed(0)}',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 14),
                        const Text('Selected Products', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827))),
                        const SizedBox(height: 8),
                        if (_lines.isEmpty)
                          const Text(
                            'No items selected',
                            style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _lines.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final l = _lines[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            l.product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => setState(() => _lines.removeAt(index)),
                                          icon: const Icon(Icons.close, size: 18),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _QtyStepper(
                                          qty: l.qty,
                                          onMinus: () => setState(() {
                                            final next = (l.qty - 1);
                                            if (next <= 0) {
                                              _lines.removeAt(index);
                                            } else {
                                              _lines[index] = l.copyWith(qty: next);
                                            }
                                          }),
                                          onPlus: () => setState(() => _lines[index] = l.copyWith(qty: l.qty + 1)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: l.unitPrice.toStringAsFixed(0),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(
                                              labelText: 'S.P @',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                              ),
                                              isDense: true,
                                            ),
                                            onChanged: (v) {
                                              final parsed = _parseAmount(v);
                                              if (parsed == null) return;
                                              setState(() => _lines[index] = l.copyWith(unitPrice: parsed));
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: l.discount.toStringAsFixed(0),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(
                                              labelText: 'Discount',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                              ),
                                              isDense: true,
                                            ),
                                            onChanged: (v) {
                                              final parsed = _parseAmount(v) ?? 0;
                                              setState(() => _lines[index] = l.copyWith(discount: parsed.clamp(0, double.infinity)));
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'TSh ${(((l.qty * l.unitPrice) - l.discount).clamp(0, double.infinity)).toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Saving…' : 'Save Record'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Customer {
  const _Customer({required this.id, required this.name});

  final String id;
  final String name;
}

class _PaymentMode {
  const _PaymentMode({required this.id, required this.name});

  final String id;
  final String name;
}

class _SellableProduct {
  const _SellableProduct({
    required this.id,
    required this.stockId,
    required this.name,
    required this.sku,
    required this.price,
    required this.wholesalePrice,
    required this.balance,
    required this.isService,
  });

  final String id;
  final String stockId;
  final String name;
  final String sku;
  final double price;
  final double wholesalePrice;
  final double balance;
  final bool isService;
}

class _SaleLine {
  const _SaleLine({
    required this.product,
    required this.qty,
    required this.unitPrice,
    required this.discount,
  });

  final _SellableProduct product;
  final int qty;
  final double unitPrice;
  final double discount;

  _SaleLine copyWith({
    _SellableProduct? product,
    int? qty,
    double? unitPrice,
    double? discount,
  }) {
    return _SaleLine(
      product: product ?? this.product,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove, size: 18),
            color: primary,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
          ),
          SizedBox(
            width: 42,
            child: Text(
              qty.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add, size: 18),
            color: primary,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
