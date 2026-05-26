import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class RecycleBinPage extends StatefulWidget {
  const RecycleBinPage({super.key});

  @override
  State<RecycleBinPage> createState() => _RecycleBinPageState();
}

class _RecycleBinPageState extends State<RecycleBinPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  String? _error;

  List<dynamic> _deletedItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.instance.app.getData('recycle_bin');

      if (!mounted) return;

      setState(() {
        _deletedItems = _asList(data);
        _loading = false;
      });

      if (kDebugMode) {
        debugPrint('Recycle Bin: ${_deletedItems.length} items');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return [];
  }

  Future<void> _restoreItem(dynamic item) async {
    try {
      final id = item['id']?.toString() ?? '';
      final type = item['type']?.toString() ?? 'item';

      await ApiService.instance.app.postData(
        'recycle_bin/restore',
        body: {'id': id, 'type': type},
      );

      if (!mounted) return;
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item restored successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deletePermanently(dynamic item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final id = item['id']?.toString() ?? '';

      await ApiService.instance.app.postData(
        'recycle_bin/delete',
        body: {'id': id, 'permanent': true},
      );

      if (!mounted) return;
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted permanently')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  List<dynamic> _getItemsByType(String type) {
    return _deletedItems.where((item) {
      final itemType = item['type']?.toString()?.toLowerCase() ?? '';
      return itemType == type || (type == 'other' && !['product', 'customer', 'sale'].contains(itemType));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Recycle Bin',
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: colorScheme.primary,
              isScrollable: true,
              tabs: const [
                Tab(text: 'All', icon: Icon(Icons.delete)),
                Tab(text: 'Products', icon: Icon(Icons.inventory)),
                Tab(text: 'Customers', icon: Icon(Icons.people)),
                Tab(text: 'Sales', icon: Icon(Icons.receipt)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildItemsList(_deletedItems),
                      _buildItemsList(_getItemsByType('product')),
                      _buildItemsList(_getItemsByType('customer')),
                      _buildItemsList(_getItemsByType('sale')),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<dynamic> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'No deleted items',
              style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final name = item['name']?.toString() ??
            item['title']?.toString() ??
            'Deleted Item';
        final type = item['type']?.toString() ?? 'Item';
        final date = item['deleted_at']?.toString() ??
            item['date']?.toString() ??
            'Unknown date';

        IconData icon;
        Color color;
        switch (type.toLowerCase()) {
          case 'product':
            icon = Icons.inventory;
            color = Colors.blue;
            break;
          case 'customer':
            icon = Icons.person;
            color = Colors.green;
            break;
          case 'sale':
            icon = Icons.receipt;
            color = Colors.purple;
            break;
          default:
            icon = Icons.folder;
            color = Colors.grey;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('$type • Deleted: $date'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green),
                  onPressed: () => _restoreItem(item),
                  tooltip: 'Restore',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () => _deletePermanently(item),
                  tooltip: 'Delete Forever',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
