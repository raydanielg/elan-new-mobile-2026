import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class SuPage extends StatefulWidget {
  const SuPage({super.key});

  @override
  State<SuPage> createState() => _SuPageState();
}

class _SuPageState extends State<SuPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  String? _error;

  List<dynamic> _shops = [];
  List<dynamic> _admins = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final results = await Future.wait([
        ApiService.instance.app.getData('suShops'),
        ApiService.instance.app.getData('reseller_admin_list'),
      ]);

      if (!mounted) return;

      setState(() {
        _shops = _asList(results[0]);
        _admins = _asList(results[1]);
        _loading = false;
      });

      if (kDebugMode) {
        debugPrint('SU: shops=${_shops.length} admins=${_admins.length}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppHeader(
        title: 'S-U',
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
              tabs: const [
                Tab(text: 'Shops', icon: Icon(Icons.storefront)),
                Tab(text: 'Admins', icon: Icon(Icons.admin_panel_settings)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildShopsTab(),
                          _buildAdminsTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopsTab() {
    if (_shops.isEmpty) {
      return const Center(
        child: Text(
          'No shops found',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _shops.length,
      itemBuilder: (context, i) {
        final s = _shops[i];
        final name = s['shop_name']?.toString() ?? s['name']?.toString() ?? 'Shop';
        final owner = s['owner_name']?.toString() ?? s['owner']?.toString() ?? '';
        final status = s['status']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.storefront, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(owner.isNotEmpty ? 'Owner: $owner' : ''),
            trailing: status.isEmpty
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildAdminsTab() {
    if (_admins.isEmpty) {
      return const Center(
        child: Text(
          'No admins found',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _admins.length,
      itemBuilder: (context, i) {
        final a = _admins[i];
        final name = a['full_name']?.toString() ?? a['name']?.toString() ?? 'Admin';
        final phone = a['phone']?.toString() ?? '';
        final email = a['email']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: const Icon(Icons.admin_panel_settings, color: Colors.blue),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(phone.isNotEmpty ? phone : email),
          ),
        );
      },
    );
  }
}
