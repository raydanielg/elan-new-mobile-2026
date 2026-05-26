import 'package:flutter/material.dart';
import '../api/api_service.dart';

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searching = false;
  List<Map<String, dynamic>> _results = [];
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      // Perform AJAX search for sales, customers, products
      final results = <Map<String, dynamic>>[];
      
      // Search sales
      try {
        final salesRaw = await ApiService.instance.app.getData('sales');
        if (salesRaw is List) {
          final sales = salesRaw.whereType<Map>().where((item) {
            final name = (item['customer_name'] ?? item['customer'] ?? '').toString().toLowerCase();
            final phone = (item['customer_phone'] ?? item['phone'] ?? '').toString().toLowerCase();
            final id = (item['sale_id'] ?? item['id'] ?? '').toString().toLowerCase();
            final q = query.toLowerCase();
            return name.contains(q) || phone.contains(q) || id.contains(q);
          }).toList();
          
          for (var sale in sales) {
            results.add({
              'type': 'sale',
              'id': sale['sale_id']?.toString() ?? sale['id']?.toString() ?? '',
              'title': sale['customer_name']?.toString() ?? sale['customer']?.toString() ?? 'Customer',
              'subtitle': 'TSh ${sale['total_amount']?.toString() ?? '0'}',
              'icon': Icons.receipt_long,
              'color': const Color(0xFF00C853),
            });
          }
        }
      } catch (_) {}

      // Search customers
      try {
        final customersRaw = await ApiService.instance.app.getData('customers');
        if (customersRaw is List) {
          final customers = customersRaw.whereType<Map>().where((item) {
            final name = (item['customer_name'] ?? item['name'] ?? '').toString().toLowerCase();
            final phone = (item['customer_phone'] ?? item['phone'] ?? '').toString().toLowerCase();
            final q = query.toLowerCase();
            return name.contains(q) || phone.contains(q);
          }).toList();
          
          for (var customer in customers) {
            results.add({
              'type': 'customer',
              'id': customer['customer_id']?.toString() ?? customer['id']?.toString() ?? '',
              'title': customer['customer_name']?.toString() ?? customer['name']?.toString() ?? 'Customer',
              'subtitle': customer['customer_phone']?.toString() ?? customer['phone']?.toString() ?? '',
              'icon': Icons.person,
              'color': const Color(0xFF00B0FF),
            });
          }
        }
      } catch (_) {}

      // Search products
      try {
        final productsRaw = await ApiService.instance.app.getData('stock');
        if (productsRaw is List) {
          final products = productsRaw.whereType<Map>().where((item) {
            final name = (item['product_name'] ?? item['name'] ?? '').toString().toLowerCase();
            final code = (item['product_code'] ?? item['code'] ?? '').toString().toLowerCase();
            final q = query.toLowerCase();
            return name.contains(q) || code.contains(q);
          }).toList();
          
          for (var product in products) {
            results.add({
              'type': 'product',
              'id': product['product_id']?.toString() ?? product['id']?.toString() ?? '',
              'title': product['product_name']?.toString() ?? product['name']?.toString() ?? 'Product',
              'subtitle': product['product_code']?.toString() ?? product['code']?.toString() ?? '',
              'icon': Icons.inventory_2,
              'color': const Color(0xFF7C4DFF),
            });
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Search',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Search Field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search sales, customers, products...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _results = [];
                            });
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  // Debounce search
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _performSearch(value);
                    }
                  });
                },
                onSubmitted: _performSearch,
              ),
            ),
            
            // Results
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_searching) {
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
              Text(
                'Search failed',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Type to search',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = _results[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (result['color'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              result['icon'] as IconData,
              color: result['color'] as Color,
              size: 20,
            ),
          ),
          title: Text(
            result['title'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            result['subtitle'] as String,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
          onTap: () {
            Navigator.of(context).pop();
            // TODO: Navigate to appropriate page based on result type
          },
        );
      },
    );
  }
}
