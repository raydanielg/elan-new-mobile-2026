import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';
import 'add_new_product.dart';
import 'stock.dart';
import 'update_product_page.dart';

enum _ViewMode { grid, list }

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    this.userId,
    this.shopId,
    this.embedded = false,
  });

  final String? userId;
  final String? shopId;
  final bool embedded;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _loading = false;
  String? _error;
  bool _isSearching = false;

  List<_ProductItem> _products = const [];
  List<String> _categories = const [];
  int _lowStockCount = 0;

  final _searchCtrl = TextEditingController();
  _ViewMode _viewMode = _ViewMode.list;
  String? _selectedCategoryFilter;

  String? _userId;
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _shopId = widget.shopId;
    _fetchProducts();
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
    } catch (_) {}
  }

  Future<void> _fetchProducts() async {
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

      dynamic productsRaw;
      try {
        productsRaw = await ApiService.instance.client.getRawJson(
          '/app/get/getdata/products',
          queryParameters: qp.isEmpty ? null : qp,
        );
      } catch (_) {
        productsRaw = await ApiService.instance.client.getRawJson(
          '/app/get/getdata/sellable_stock',
          queryParameters: qp.isEmpty ? null : qp,
        );
      }

      dynamic categoriesRaw;
      try {
        categoriesRaw = await ApiService.instance.client.getRawJson(
          '/app/get/getdata/stock_category',
          queryParameters: qp.isEmpty ? null : qp,
        );
      } catch (_) {
        categoriesRaw = await ApiService.instance.client.getRawJson(
          '/app/get/getdata/stock/lob-categories',
          queryParameters: qp.isEmpty ? null : qp,
        );
      }

      dynamic lowStockRaw;
      try {
        lowStockRaw = await ApiService.instance.client.getRawJson(
          '/app/get/getreport/lowStock',
          queryParameters: qp.isEmpty ? null : qp,
        );
      } catch (_) {
        lowStockRaw = null;
      }

      final products = _parseProducts(productsRaw);
      final categories = _parseCategories(categoriesRaw);
      final lowStock = _parseProducts(lowStockRaw);

      if (!mounted) return;
      setState(() {
        _products = products;
        _categories = categories;
        _lowStockCount = lowStock.length;
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

  List<_ProductItem> _parseProducts(dynamic raw) {
    dynamic data = raw;
    if (raw is Map) {
      data = raw['data'] ?? raw['result'] ?? raw['products'] ?? raw['items'] ?? raw['rows'] ?? raw['list'] ?? raw;
    }

    if (data is Map) {
      data = data['data'] ?? data['result'] ?? data['products'] ?? data['items'] ?? data['rows'] ?? data['list'] ?? data;
    }

    final out = <_ProductItem>[];
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;

        final id = item['product_id']?.toString() ??
            item['id']?.toString() ??
            item['stock_id']?.toString() ??
            '';
        final name = item['product_name']?.toString() ??
            item['name']?.toString() ??
            item['service_name']?.toString() ??
            '';
        final sku = item['sku']?.toString() ??
            item['barcode']?.toString() ??
            item['product_code']?.toString() ??
            '';
        final price = item['selling_price']?.toString() ??
            item['price']?.toString() ??
            item['sale_price']?.toString() ??
            item['selling']?.toString() ??
            '';
        final wholesalePrice = item['wholesale_price']?.toString() ??
            item['whole_price']?.toString() ??
            item['ws_price']?.toString() ??
            '';
        final quantity = item['qty']?.toString() ??
            item['quantity']?.toString() ??
            item['stock']?.toString() ??
            item['balance']?.toString() ??
            '';
        final category = item['category_name']?.toString() ??
            item['category']?.toString() ??
            item['stock_category']?.toString() ??
            item['subcategory_name']?.toString() ??
            '';
        final type = item['type']?.toString() ??
            item['product_type']?.toString() ??
            item['item_type']?.toString() ??
            '';

        if (id.trim().isEmpty && name.trim().isEmpty && sku.trim().isEmpty) continue;

        out.add(
          _ProductItem(
            id: id.trim(),
            name: name.trim(),
            sku: sku.trim(),
            price: price.trim(),
            wholesalePrice: wholesalePrice.trim(),
            quantity: quantity.trim(),
            category: category.trim(),
            type: type.trim(),
          ),
        );
      }
    }
    return out;
  }

  List<String> _parseCategories(dynamic raw) {
    dynamic data = raw;
    if (raw is Map) {
      data = raw['data'] ?? raw['result'] ?? raw['rows'] ?? raw['list'] ?? raw;
    }
    if (data is Map) {
      data = data['data'] ?? data['result'] ?? data['rows'] ?? data['list'] ?? data;
    }

    final out = <String>{};
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final category = item['category_name']?.toString() ??
            item['name']?.toString() ??
            item['category']?.toString() ??
            item['subcategory_name']?.toString() ??
            '';
        final cleaned = category.trim();
        if (cleaned.isNotEmpty) out.add(cleaned);
      }
    }
    return out.toList()..sort();
  }

  List<_ProductItem> get _filtered {
    var items = _products;
    
    // Category filter
    if (_selectedCategoryFilter != null && _selectedCategoryFilter!.isNotEmpty) {
      items = items.where((p) => p.category == _selectedCategoryFilter).toList();
    }
    
    // Search filter
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();
  }

  double _asDouble(String raw) {
    return double.tryParse(raw.replaceAll(',', '').trim()) ?? 0;
  }

  String _money(String raw) {
    final value = _asDouble(raw);
    if (value == 0 && raw.trim().isEmpty) return '-';
    return value.toStringAsFixed(2);
  }

  Future<void> _openAddProduct() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddNewProductPage(
          userId: _userId,
          shopId: _shopId,
        ),
      ),
    );
    if (!mounted) return;
    if (created == true) {
      await _fetchProducts();
    }
  }

  Future<void> _openStock() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => StockPage(
          userId: _userId,
          shopId: _shopId,
        ),
      ),
    );
  }

  Future<void> _openUpdateProduct(_ProductItem product) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UpdateProductPage(
          product: {
            'product_id': product.id,
            'product_name': product.name,
            'name': product.name,
            'sku': product.sku,
            'barcode': product.sku,
            'selling_price': product.price,
            'price': product.price,
            'wholesale_price': product.wholesalePrice,
            'wp': product.wholesalePrice,
            'qty': product.quantity,
            'quantity': product.quantity,
            'category': product.category,
            'type': product.type,
          },
          userId: _userId,
          shopId: _shopId,
        ),
      ),
    );
    if (!mounted) return;
    if (updated == true) {
      await _fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final items = _filtered;
    final totalSellPrice = _products.fold<double>(
      0,
      (sum, product) => sum + _asDouble(product.price),
    );

    final pageBody = SafeArea(
      top: !widget.embedded,
      child: RefreshIndicator(
        onRefresh: _fetchProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Skeleton Loading or Metric Cards
                    _loading 
                      ? _buildMetricSkeleton()
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _MetricCard(
                              title: 'Products',
                              value: _products.length.toString(),
                              icon: Icons.inventory_2_outlined,
                              color: primary,
                            ),
                            _MetricCard(
                              title: 'Categories',
                              value: _categories.length.toString(),
                              icon: Icons.category_outlined,
                              color: Colors.blue,
                            ),
                            _MetricCard(
                              title: 'Low Stock',
                              value: _lowStockCount.toString(),
                              icon: Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
                            _MetricCard(
                              title: 'Stock Value',
                              value: 'TZS ${totalSellPrice.toStringAsFixed(0)}',
                              icon: Icons.payments_outlined,
                              color: Colors.green,
                            ),
                          ],
                        ),
                    const SizedBox(height: 16),
                    
                    // Filter & View Toggle Row
                    Row(
                      children: [
                        // Category Filter
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedCategoryFilter,
                                hint: const Text('All Categories'),
                                isExpanded: true,
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All Categories'),
                                  ),
                                  ..._categories.map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  )),
                                ],
                                onChanged: (v) => setState(() => _selectedCategoryFilter = v),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // View Mode Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              _ViewModeButton(
                                icon: Icons.view_list,
                                isSelected: _viewMode == _ViewMode.list,
                                onTap: () => setState(() => _viewMode = _ViewMode.list),
                              ),
                              _ViewModeButton(
                                icon: Icons.grid_view,
                                isSelected: _viewMode == _ViewMode.grid,
                                onTap: () => setState(() => _viewMode = _ViewMode.grid),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Results Count
                    if (!_loading && items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Showing ${items.length} of ${_products.length} products',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    
                    // Error Card
                    if (_error != null)
                      _ErrorCard(message: _error!, onRetry: _fetchProducts),
                    
                    // Loading Skeleton for List
                    if (_loading)
                      _buildListSkeleton()
                    else if (items.isEmpty)
                      const _EmptyCard(
                        title: 'No products found',
                        message: 'Pull down to refresh or add a new product.',
                      ),
                  ],
                ),
              ),
            ),
            
            // Products List/Grid
            if (!_loading && items.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                sliver: _viewMode == _ViewMode.list
                    ? SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final p = items[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                onTap: () => _openUpdateProduct(p),
                                child: _ProductCard(
                                  product: p,
                                  formattedPrice: _money(p.price),
                                  formattedWholesalePrice: _money(p.wholesalePrice),
                                ),
                              ),
                            );
                          },
                          childCount: items.length,
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final p = items[index];
                            return GestureDetector(
                              onTap: () => _openUpdateProduct(p),
                              child: _ProductGridCard(
                                product: p,
                                formattedPrice: _money(p.price),
                                formattedWholesalePrice: _money(p.wholesalePrice),
                              ),
                            );
                          },
                          childCount: items.length,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          pageBody,
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _openAddProduct,
              backgroundColor: primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: _isSearching 
        ? AppBar(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _isSearching = false;
                _searchCtrl.clear();
              }),
            ),
            title: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
            actions: [
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchCtrl.clear()),
                ),
            ],
          )
        : AppHeader(
            title: 'Products',
            backgroundColor: primary,
            foregroundColor: Colors.white,
            onMenuPressed: () => Navigator.of(context).maybePop(),
            showUserMenu: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _isSearching = true),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: pageBody,
    );
  }
  Widget _buildMetricSkeleton() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(4, (index) => _SkeletonBox(
        width: (MediaQuery.of(context).size.width - 42) / 2,
        height: 65,
        borderRadius: 14,
      )),
    );
  }

  Widget _buildListSkeleton() {
    return Column(
      children: List.generate(5, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _SkeletonBox(
          width: double.infinity,
          height: 100,
          borderRadius: 18,
        ),
      )),
    );
  }
}

class _ProductItem {
  const _ProductItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.wholesalePrice,
    required this.quantity,
    required this.category,
    required this.type,
  });

  final String id;
  final String name;
  final String sku;
  final String price;
  final String wholesalePrice;
  final String quantity;
  final String category;
  final String type;
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? primary : Colors.grey.shade500,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;
    // Calculate flex width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 42) / 2; // 2 cards per row with spacing
    
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cardColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.formattedPrice,
    required this.formattedWholesalePrice,
  });

  final _ProductItem product;
  final String formattedPrice;
  final String formattedWholesalePrice;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final name = product.name.trim().isEmpty
        ? (product.sku.trim().isEmpty ? 'Product' : product.sku.trim())
        : product.name.trim();
    final initials = name.isEmpty ? 'P' : name.toUpperCase().substring(0, 1);
    final subtitle = product.sku.isNotEmpty
        ? 'SKU: ${product.sku}'
        : (product.id.isNotEmpty ? 'ID: ${product.id}' : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
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
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (product.price.isNotEmpty)
                    Text(
                      'TZS $formattedPrice',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: primary,
                      ),
                    ),
                  if (product.quantity.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Qty: ${product.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (product.category.isNotEmpty) _TagChip(label: product.category),
              if (product.type.isNotEmpty) _TagChip(label: product.type),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({
    required this.product,
    required this.formattedPrice,
    required this.formattedWholesalePrice,
  });

  final _ProductItem product;
  final String formattedPrice;
  final String formattedWholesalePrice;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final name = product.name.trim().isEmpty
        ? (product.sku.trim().isEmpty ? 'Product' : product.sku.trim())
        : product.name.trim();
    final initials = name.isEmpty ? 'P' : name.toUpperCase().substring(0, 1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          if (product.sku.isNotEmpty)
            Text(
              product.sku,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          const Spacer(),
          if (product.price.isNotEmpty)
            Text(
              'TZS $formattedPrice',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: primary,
              ),
            ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              if (product.quantity.isNotEmpty)
                _SmallTagChip(label: 'Qty: ${product.quantity}'),
              if (product.category.isNotEmpty)
                _SmallTagChip(label: product.category),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SmallTagChip extends StatelessWidget {
  const _SmallTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 32, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

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
              maxLines: 3,
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
