import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../repositories/shop_context.dart';
import '../products/add_new_product.dart';
import 'barcode_scanner_page.dart';

class SalesPosPage extends StatefulWidget {
  const SalesPosPage({
    super.key,
    required this.saleType,
    this.shopId,
  });

  final String saleType;
  final String? shopId;

  @override
  State<SalesPosPage> createState() => _SalesPosPageState();
}

class _SalesPosPageState extends State<SalesPosPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _productSearchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _products = const [];
  List<Map<String, dynamic>> _customers = const [];
  List<Map<String, dynamic>> _paymentModes = const [];

  String? _selectedCategoryId;
  String? _selectedCustomerId;
  String? _selectedPaymentModeId;

  final List<_CartLine> _cart = [];

  String? _currentShopId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentShopId = widget.shopId ?? ApiService.instance.tokenStore.selectedShopId;
    _loadPosData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh if shop changed while page was open
    final newShopId = widget.shopId ?? ApiService.instance.tokenStore.selectedShopId;
    if (newShopId != _currentShopId) {
      _currentShopId = newShopId;
      _loadPosData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPosData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ShopContext.instance.ensureShop(widget.shopId ?? _currentShopId);

      // Fetch POS data
      final results = await Future.wait([
        _getProducts(),
        _getCustomers(),
        _getPaymentModes(),
      ]);

      if (!mounted) return;

      setState(() {
        _products = results[0];
        _customers = results[1];
        _paymentModes = results[2];
        _selectedPaymentModeId = _paymentModes.isNotEmpty
            ? (_paymentModes.first['account_id']?.toString() ??
                _paymentModes.first['id']?.toString())
            : null;
        _loading = false;
      });

      if (kDebugMode) {
        debugPrint(
          'POS loaded saleType=${widget.saleType} products=${_products.length} customers=${_customers.length} modes=${_paymentModes.length}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      
      // Show error notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Error loading POS: ${e.toString()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getProducts() async {
    final endpoints = <String>[
      'sellable_stock',
      'stock',
      'products',
    ];

    dynamic raw;
    for (final ep in endpoints) {
      try {
        raw = await ApiService.instance.app.getData(ep);
        final list = _asList(raw);
        if (list.isNotEmpty) {
          return list
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
        }
      } catch (_) {
        continue;
      }
    }

    return const [];
  }

  Future<List<Map<String, dynamic>>> _getCustomers() async {
    try {
      final raw = await ApiService.instance.app.getData('customers');
      final list = _asList(raw);
      return list
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _getPaymentModes() async {
    try {
      final raw = await ApiService.instance.app.getData('payment_mode');
      final list = _asList(raw);
      return list
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    if (raw is Map && raw['data'] is Map && raw['data']['rows'] is List) {
      return raw['data']['rows'] as List;
    }
    if (raw is Map && raw['rows'] is List) return raw['rows'] as List;
    if (raw is Map && raw['list'] is List) return raw['list'] as List;
    return const [];
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '');
    return double.tryParse(s) ?? 0;
  }

  String _productTitle(Map<String, dynamic> p) {
    return p['product_name']?.toString() ??
        p['name']?.toString() ??
        p['title']?.toString() ??
        'Product';
  }

  String _productSku(Map<String, dynamic> p) {
    return p['barcode']?.toString() ??
        p['sku']?.toString() ??
        p['code']?.toString() ??
        '';
  }

  double _productPrice(Map<String, dynamic> p) {
    final candidates = [
      p['sp'],
      p['selling_price'],
      p['sell_price'],
      p['price'],
      p['unit_price'],
      p['rate'],
    ];
    for (final c in candidates) {
      final d = _asDouble(c);
      if (d > 0) return d;
    }
    return 0;
  }

  String? _productId(Map<String, dynamic> p) {
    final id = p['product_id']?.toString() ?? p['id']?.toString();
    return id == null || id.trim().isEmpty ? null : id.trim();
  }

  String? _stockId(Map<String, dynamic> p) {
    final id = p['stock_id']?.toString() ?? p['stockId']?.toString();
    return id == null || id.trim().isEmpty ? '' : id.trim();
  }

  bool _isOutOfStock(Map<String, dynamic> p) {
    final type = (p['type']?.toString() ?? 'product').toLowerCase();
    if (type == 'service') return false;
    final available = _asDouble(
      p['available'] ?? p['available_stock'] ?? p['balance'] ?? p['qty'],
    );
    return available <= 0;
  }

  void _addToCart(Map<String, dynamic> product) {
    final pid = _productId(product);
    final sid = _stockId(product);
    if (pid == null && sid == null) return;

    final existingIndex = _cart.indexWhere((l) => l.productId == pid && l.stockId == sid);
    if (existingIndex >= 0) {
      setState(() {
        _cart[existingIndex] = _cart[existingIndex].copyWith(qty: _cart[existingIndex].qty + 1);
      });
      return;
    }

    setState(() {
      _cart.add(
        _CartLine(
          productId: pid,
          stockId: sid,
          name: _productTitle(product),
          unitPrice: _productPrice(product),
          qty: 1,
        ),
      );
    });
  }

  void _setQty(_CartLine line, int qty) {
    if (qty <= 0) {
      setState(() {
        _cart.remove(line);
      });
      return;
    }

    final idx = _cart.indexOf(line);
    if (idx < 0) return;
    setState(() {
      _cart[idx] = line.copyWith(qty: qty);
    });
  }

  double get _subTotal {
    return _cart.fold(0, (sum, l) => sum + l.unitPrice * l.qty);
  }

  double get _discountTotal {
    return _cart.fold(0, (sum, l) => sum + l.discount);
  }

  double get _vatTotal {
    return _cart.fold(0, (sum, l) => sum + l.vat);
  }

  double get _grandTotal {
    final total = _subTotal - _discountTotal + _vatTotal;
    return total < 0 ? 0 : total;
  }

  Future<void> _submit() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final items = _cart.map((l) => l.toApiItemString()).toList();
      final today = DateTime.now();
      final date = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final paidAmount = widget.saleType == 'cashsale' ? _grandTotal : 0;
      final body = <String, dynamic>{
        'sale_type': widget.saleType,
        'original_sale_type': widget.saleType,
        'customer_id': _selectedCustomerId,
        'items': items,
        'total_amount': _grandTotal,
        'paid_amount': paidAmount,
        'payment_mode': _selectedPaymentModeId,
        'vat': _vatTotal,
        'discount': _discountTotal,
        'subtotal': _subTotal,
        'date': date,
        'due_date': date,
        'status': widget.saleType == 'order' ? 'active' : 'closed',
      };

      body.removeWhere((k, v) => v == null);

      final res = await ApiService.instance.app.postData('sales/add', body: body);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _cart.clear();
      });

      final saleId = res.raw['record_id']?.toString() ??
          res.raw['sale_id']?.toString() ??
          res.raw['data']?['sale_id']?.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved successfully${saleId != null ? ' (#$saleId)' : ''}')),
      );

      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _openScanner() async {
    final String? code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (code != null && code.isNotEmpty) {
      final sanitizedCode = code.trim();
      setState(() {
        _productSearchCtrl.text = sanitizedCode;
        _tabController.index = 0; // Switch to products tab
      });

      // Find product by exact barcode match (case-insensitive and trimmed)
      final match = _products.firstWhere(
        (p) {
          final sku = _productSku(p).trim();
          return sku.toLowerCase() == sanitizedCode.toLowerCase();
        },
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        _addToCart(match);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${_productTitle(match)} via scan')),
        );
      } else {
        // Product not found - ask to register
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Product Not Found'),
            content: Text('Barcode "$sanitizedCode" is not registered. Do you want to add this product now?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final added = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => AddNewProductPage(initialSku: sanitizedCode),
                    ),
                  );
                  if (added == true) {
                    _loadPosData(); // Refresh products list
                  }
                },
                child: const Text('Register Product'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final showSearch = _tabController.index == 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(64 + (showSearch ? 56 : 0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              title: Text(
                widget.saleType == 'cashsale'
                    ? 'Make Sale'
                    : widget.saleType == 'order'
                        ? 'Create Order'
                        : widget.saleType == 'invoice'
                            ? 'Create Invoice'
                            : widget.saleType == 'quotation'
                                ? 'Create Quotation'
                                : 'Sales',
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Text(
                        'Cart: ${_cart.length}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (showSearch)
              Container(
                color: primary,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _productSearchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search product or barcode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _openScanner,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.65)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _PosError(message: _error!, onRetry: _loadPosData)
              : Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: primary,
                        unselectedLabelColor: const Color(0xFF6B7280),
                        indicatorColor: primary,
                        tabs: const [
                          Tab(text: 'Products'),
                          Tab(text: 'Cart'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildProductsTab(),
                          _buildCartTab(),
                        ],
                      ),
                    ),
                    _buildBottomBar(),
                  ],
                ),
    );
  }

  Widget _buildProductsTab() {
    final primary = Theme.of(context).colorScheme.primary;

    // Extract categories
    final categories = _products
        .map((p) => p['category_name']?.toString() ?? p['category']?.toString() ?? 'General')
        .toSet()
        .toList();
    categories.sort();

    final query = _productSearchCtrl.text.trim().toLowerCase();
    final filtered = _products.where((p) {
      final title = _productTitle(p).toLowerCase();
      final sku = _productSku(p).toLowerCase();
      final cat = (p['category_name']?.toString() ?? p['category']?.toString() ?? 'General');
      
      final matchesSearch = query.isEmpty || title.contains(query) || sku.contains(query);
      final matchesCategory = _selectedCategoryId == null || cat == _selectedCategoryId;
      
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        if (categories.isNotEmpty)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length + 1,
              itemBuilder: (context, i) {
                final isAll = i == 0;
                final cat = isAll ? null : categories[i - 1];
                final isSelected = _selectedCategoryId == cat;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(isAll ? 'All' : cat!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = selected ? cat : null;
                      });
                    },
                    selectedColor: primary.withValues(alpha: 0.2),
                    checkmarkColor: primary,
                    labelStyle: TextStyle(
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected ? primary : const Color(0xFF475569),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No products found',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                        final p = filtered[i];
                        final name = _productTitle(p);
                        final sku = _productSku(p);
                        final price = _productPrice(p);
                        final outOfStock = _isOutOfStock(p);

                        return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: sku.isEmpty
                            ? null
                            : Text(
                                sku,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              price <= 0 ? '—' : 'Tsh ${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: outOfStock
                                  ? null
                                  : () {
                                _addToCart(p);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Added $name')),
                                );
                              },
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (outOfStock ? Colors.grey : primary).withValues(alpha: 0.12),
                                ),
                                child: Icon(
                                  outOfStock ? Icons.block : Icons.add,
                                  color: outOfStock ? Colors.grey : primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCartTab() {
    if (_cart.isEmpty) {
      return const Center(
        child: Text(
          'Cart is empty',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: _cart.length,
      itemBuilder: (context, i) {
        final line = _cart[i];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            title: Text(
              line.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              'Unit: Tsh ${line.unitPrice.toStringAsFixed(0)}  •  Total: Tsh ${line.lineTotal.toStringAsFixed(0)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => _setQty(line, line.qty - 1),
                        icon: const Icon(Icons.remove, size: 18),
                      ),
                      Text(
                        '${line.qty}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: () => _setQty(line, line.qty + 1),
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => setState(() => _cart.remove(line)),
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 420;

                final customerField = DropdownButtonFormField<String>(
                  value: _selectedCustomerId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Customer (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _customers
                      .map((c) {
                        final id = c['customer_id']?.toString() ?? c['id']?.toString();
                        final name = c['name']?.toString() ?? c['full_name']?.toString() ?? 'Customer';
                        if (id == null || id.isEmpty) return null;
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1),
                        );
                      })
                      .whereType<DropdownMenuItem<String>>()
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCustomerId = v),
                );

                final paymentField = DropdownButtonFormField<String>(
                  value: _selectedPaymentModeId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Payment',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _paymentModes
                      .map((m) {
                        final id = m['account_id']?.toString() ?? m['id']?.toString();
                        final name = m['name']?.toString() ??
                            m['account_name']?.toString() ??
                            m['title']?.toString() ??
                            'Mode';
                        if (id == null || id.isEmpty) return null;
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(name, overflow: TextOverflow.ellipsis, maxLines: 1),
                        );
                      })
                      .whereType<DropdownMenuItem<String>>()
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPaymentModeId = v),
                );

                if (narrow) {
                  return Column(
                    children: [
                      customerField,
                      const SizedBox(height: 10),
                      paymentField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: customerField),
                    const SizedBox(width: 10),
                    SizedBox(width: 200, child: paymentField),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TotalChip(label: 'Subtotal', value: _subTotal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TotalChip(label: 'Discount', value: _discountTotal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TotalChip(label: 'VAT', value: _vatTotal),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Grand Total',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: primary,
                    ),
                  ),
                ),
                Text(
                  'Tsh ${_grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(widget.saleType == 'cashsale'
                    ? 'Complete Sale'
                    : widget.saleType == 'order'
                        ? 'Save Order'
                        : widget.saleType == 'invoice'
                            ? 'Save Invoice'
                            : widget.saleType == 'quotation'
                                ? 'Save Quotation'
                                : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tsh ${value.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosError extends StatelessWidget {
  const _PosError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _CartLine {
  const _CartLine({
    required this.productId,
    required this.stockId,
    required this.name,
    required this.unitPrice,
    required this.qty,
    this.discount = 0,
    this.vat = 0,
  });

  final String? productId;
  final String? stockId;
  final String name;
  final double unitPrice;
  final int qty;
  final double discount;
  final double vat;

  double get subtotal => unitPrice * qty;
  double get lineTotal => subtotal - discount + vat;

  _CartLine copyWith({
    String? productId,
    String? stockId,
    String? name,
    double? unitPrice,
    int? qty,
    double? discount,
    double? vat,
  }) {
    return _CartLine(
      productId: productId ?? this.productId,
      stockId: stockId ?? this.stockId,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      qty: qty ?? this.qty,
      discount: discount ?? this.discount,
      vat: vat ?? this.vat,
    );
  }

  String toApiItemString() {
    final pid = (productId ?? '').trim();
    final sid = (stockId ?? '').trim();
    final sub = subtotal;
    final total = lineTotal;

    return '$pid|$sid|$qty|$unitPrice|$discount|$sub|$vat|$total';
  }
}
