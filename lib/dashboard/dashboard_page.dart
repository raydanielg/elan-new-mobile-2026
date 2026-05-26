import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api/api_service.dart';
import '../auth/login_page.dart';
import '../business/manage_business_page.dart';
import '../widgets/app_header.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/global_filter_widget.dart';
import '../widgets/search_dialog.dart';
import '../customers/customers_page.dart';
import '../members/members_page.dart';
import '../products/products_page.dart';
import '../shops/shops_page.dart';
import '../suppliers/suppliers_page.dart';
import '../settings/settings_page.dart';
import 'su_page.dart';
import 'revenue_expenses_profit_page.dart';
import 'accounts_cashflow_page.dart';
import 'file_cabinet_page.dart';
import 'sms_emails_page.dart';
import 'reports_hub_page.dart';
import 'subscription_page.dart';
import 'add_team_page.dart';
import 'settings_hub_page.dart';
import 'recycle_bin_page.dart';
import 'affiliate_program_page.dart';
import 'add_business_page.dart';
import '../sales/sales_page.dart';
import '../orders/orders_page.dart';
import '../purchases/purchases_page.dart';
import '../invoices/invoices_page.dart';
import '../expenses/expenses_page.dart';
import '../accounts/accounts_page.dart';
import '../widgets/coming_soon_page.dart';
import '../services/permission_service.dart';
import '../widgets/permission_gate.dart';
import 'sales_and_orders_page.dart';
import 'sales_revenue_page.dart';
import 'services_revenue_page.dart';
import 'stock_and_services_page.dart';
import 'stock_overview_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _QuickAction {
  const _QuickAction({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _TileItem {
  const _TileItem({required this.label, required this.icon, this.description, this.iconUrl});

  final String label;
  final IconData icon;
  final String? description;
  final String? iconUrl;
}

class _DashboardKpiItem {
  const _DashboardKpiItem({
    required this.key,
    required this.label,
    required this.value,
    required this.main,
  });

  final String key;
  final String label;
  final String value;
  final bool main;
}

class _DashboardMenuItem {
  const _DashboardMenuItem({required this.name, this.description, this.iconUrl});

  final String name;
  final String? description;
  final String? iconUrl;
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  late ScrollController _kpiScrollController;
  Timer? _kpiTimer;

  bool _shopsLoading = false;
  String? _shopsError;
  List<_Shop> _shops = const [];
  _Shop? _selectedShop;

  bool _menuLoading = false;
  String? _menuError;
  List<_DashboardMenuItem> _dashboardMenu = const [];

  bool _summaryLoading = false;
  String? _summaryError;
  Map<String, dynamic> _dashboardSummary = const {};
  List<_DashboardKpiItem> _dashboardKpis = const [];

  bool _sidebarLoading = false;
  String? _sidebarError;
  String? _userName;
  String? _userEmail;
  String? _userId;
  String? _avatarUrl;
  Map<String, int> _sidebarCounters = const {
    'shops': 0,
    'members': 0,
    'customers': 0,
    'suppliers': 0,
    'products': 0,
  };

  @override
  void initState() {
    super.initState();
    _kpiScrollController = ScrollController();
    _fetchMyShops();
    _startKpiAutoScroll();
  }

  @override
  void dispose() {
    _kpiTimer?.cancel();
    _kpiScrollController.dispose();
    super.dispose();
  }

  void _startKpiAutoScroll() {
    _kpiTimer?.cancel();
    _kpiTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_kpiScrollController.hasClients) {
        final maxScroll = _kpiScrollController.position.maxScrollExtent;
        final currentScroll = _kpiScrollController.offset;
        
        // Kama tumefika mwisho, rudi mwanzo bila kuonekana (jump)
        // Lakini kwa infinite, ListView.builder inafanya kazi vizuri zaidi
        if (currentScroll >= maxScroll - 1) {
          _kpiScrollController.jumpTo(0);
        } else {
          _kpiScrollController.animateTo(
            currentScroll + 1,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      }
    });
  }

  Future<void> _refreshAll() async {
    await _fetchMyShops();
    if (!mounted) return;
    if (_selectedShop != null) {
      await _fetchSidebarData();
      await _fetchDashboardSummary();
      await _fetchDashboardMenu();
    }
  }

  Future<void> _fetchMyShops() async {
    if (!mounted) return;
    setState(() {
      _shopsLoading = true;
      _shopsError = null;
    });

    dynamic raw;
    try {
      raw = await ApiService.instance.app.getData('my_shops');
    } catch (_) {
      try {
        raw = await ApiService.instance.app.getData('session_shop');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _shopsLoading = false;
          _shopsError = e.toString();
        });
        return;
      }
    }

    final out = <_Shop>[];
    final list = (raw is Map && raw['data'] is List)
        ? (raw['data'] as List)
        : (raw is List)
            ? raw
            : null;

    if (list != null) {
      for (final item in list) {
        if (item is Map) {
          final id = item['shop_id']?.toString() ?? item['id']?.toString() ?? '';
          final name = item['shop_name']?.toString() ?? item['name']?.toString() ?? '';
          if (id.isNotEmpty && name.isNotEmpty) {
            out.add(_Shop(id: id, name: name));
          }
        }
      }
    }

    if (!mounted) return;
    
    // Restore previous selection safely
    _Shop? nextSelected;
    final savedShopId = ApiService.instance.tokenStore.selectedShopId;
    
    if (savedShopId != null) {
      final found = out.where((s) => s.id == savedShopId);
      if (found.isNotEmpty) {
        nextSelected = found.first;
      }
    }
    
    nextSelected ??= (out.isEmpty ? null : out.first);

    setState(() {
      _shops = out;
      _selectedShop = nextSelected;
      _shopsLoading = false;
    });

    // Run secondary fetches in background without blocking main UI thread too much
    if (nextSelected != null) {
      _loadShopContext(nextSelected.id);
    }
  }

  Future<void> _loadShopContext(String shopId) async {
    try {
      // Switch shop and refresh token
      final res = await ApiService.instance.auth.switchShop(shopId: shopId);
      
      // Save new token if returned
      final newToken = res.raw['token']?.toString();
      if (newToken != null && newToken.isNotEmpty) {
        await ApiService.instance.tokenStore.setToken(newToken);
      }
      
      // Persist shop selection
      await ApiService.instance.tokenStore.setSelectedShopId(shopId);
      
      // Parallel fetch secondary data
      await Future.wait([
        _fetchSidebarData(),
        _fetchDashboardSummary(),
        _fetchDashboardMenu(),
      ]);
      
      // Show success message
      if (mounted) {
        final shopName = _shops.firstWhereOrNull((s) => s.id == shopId)?.name ?? shopId;
        final message = res.raw['message']?.toString() ?? 'Switched to $shopName';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error background loading shop context: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Failed to load shop: ${e.toString()}',
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
  }

  int _extractCount(dynamic raw) {
    if (raw == null) return 0;
    if (raw is List) return raw.length;
    if (raw is Map) {
      final data = raw['data'];
      if (data is List) return data.length;
      final list = raw['list'];
      if (list is List) return list.length;
      final rows = raw['rows'];
      if (rows is List) return rows.length;
      final result = raw['result'];
      if (result is List) return result.length;
      final count = raw['count'];
      final parsed = int.tryParse(count?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  Future<void> _fetchSidebarData() async {
    setState(() {
      _sidebarLoading = true;
      _sidebarError = null;
    });

    try {
      final sessionUserRaw = await ApiService.instance.app.getData('session_user');
      if (kDebugMode) {
        debugPrint('getdata/session_user response: $sessionUserRaw');
      }

      String? email;
      String? userId;
      String? name;
      String? avatar;
      if (sessionUserRaw is Map) {
        final m = sessionUserRaw;
        final data = (m['data'] is Map) ? (m['data'] as Map) : m;
        name = data['full_name']?.toString() ??
            data['name']?.toString() ??
            data['user_name']?.toString() ??
            data['username']?.toString();

        final avatarCandidate = data['avatar_url'] ??
            data['avatar'] ??
            data['photo'] ??
            data['profile_picture'] ??
            data['profile_pic'] ??
            data['image'] ??
            data['picture'] ??
            data['user_image'];

        if (avatarCandidate is String) {
          avatar = avatarCandidate.trim();
        } else if (avatarCandidate is Map) {
          final maybeUrl = avatarCandidate['url'] ?? avatarCandidate['path'];
          if (maybeUrl is String) avatar = maybeUrl.trim();
        }

        if (avatar != null && avatar!.isNotEmpty) {
          final isAbsolute = avatar!.startsWith('http://') || avatar!.startsWith('https://');
          if (!isAbsolute) {
            final base = ApiService.instance.client.config.baseUrl;
            avatar = Uri.parse(base).resolve(avatar!).toString();
          }
        } else {
          avatar = null;
        }
        email = data['email']?.toString() ??
            data['user_email']?.toString() ??
            data['username']?.toString();
        userId = data['user_id']?.toString() ?? data['id']?.toString();
      }

      final shopsRaw = await ApiService.instance.app.getData('my_shops');
      dynamic membersRaw;
      dynamic customersRaw;
      dynamic suppliersRaw;
      dynamic productsRaw;

      try {
        membersRaw = await ApiService.instance.app.getData('team');
      } catch (_) {
        membersRaw = null;
      }
      try {
        customersRaw = await ApiService.instance.app.getData('customers');
      } catch (_) {
        customersRaw = null;
      }
      try {
        suppliersRaw = await ApiService.instance.app.getData('suppliers');
      } catch (_) {
        suppliersRaw = null;
      }
      try {
        productsRaw = await ApiService.instance.app.getData('products');
      } catch (_) {
        productsRaw = null;
      }

      final nextCounters = <String, int>{
        'shops': _extractCount(shopsRaw),
        'members': _extractCount(membersRaw),
        'customers': _extractCount(customersRaw),
        'suppliers': _extractCount(suppliersRaw),
        'products': _extractCount(productsRaw),
      };

      if (!mounted) return;
      setState(() {
        _userName = name;
        _userEmail = email;
        _userId = userId;
        _avatarUrl = avatar;
        _sidebarCounters = nextCounters;
        _sidebarLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sidebarLoading = false;
        _sidebarError = e.toString();
      });
    }
  }

  Future<void> _fetchDashboardSummary() async {
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });

    try {
      // 1. Double check current shop to ensure backend context is correct
      final currentShopId = _selectedShop?.id ?? ApiService.instance.tokenStore.selectedShopId;
      if (currentShopId != null) {
        final res = await ApiService.instance.auth.switchShop(shopId: currentShopId);
        // Save new token with updated shop context
        final newToken = res.raw['token']?.toString();
        if (newToken != null && newToken.isNotEmpty) {
          await ApiService.instance.tokenStore.setToken(newToken);
        }
      }

      // 2. Reset filter to get correct range
      await ApiService.instance.app.postData('filter/set', body: {'filter': 'reset'});
      
      // 3. Wait for backend context stability
      await Future.delayed(const Duration(milliseconds: 500));

      final raw = await ApiService.instance.app.getData('dashboard_summary');
      if (kDebugMode) {
        debugPrint('getdata/dashboard_summary response: $raw');
      }

      Map<String, dynamic> out = const {};
      List<_DashboardKpiItem> kpis = const [];

      if (raw is List) {
        // Direct list response like in user's log
        kpis = _parseDashboardKpis(raw);
        out = {for (var k in kpis) k.key: k.value};
      } else if (raw is Map) {
        out = raw.map((k, v) => MapEntry(k.toString(), v));
        final kpiList = raw['kpis'] ?? raw['summary'] ?? raw['data'];
        if (kpiList is List) {
          kpis = _parseDashboardKpis(kpiList);
        } else {
          kpis = _generateKpisFromMap(out);
        }
      }

      if (!mounted) return;
      setState(() {
        _dashboardSummary = out;
        _dashboardKpis = kpis;
        _summaryLoading = false;
      });
      
      // Show success notification
      if (mounted && kpis.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dashboard updated: ${kpis.length} metrics loaded',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF3B82F6),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryLoading = false;
        _summaryError = e.toString();
        _dashboardSummary = const {};
        _dashboardKpis = const [];
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
                  'Failed to load dashboard: ${e.toString()}',
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

  List<_DashboardKpiItem> _generateKpisFromMap(Map<String, dynamic> map) {
    final out = <_DashboardKpiItem>[];
    
    // Map common keys to readable labels
    final keyLabels = {
      'total_sales': 'Total Sales',
      'today_sales': 'Today Sales',
      'total_profit': 'Total Profit',
      'today_profit': 'Today Profit',
      'total_expenses': 'Total Expenses',
      'total_credits': 'Credits',
      'monthly_sales': 'Monthly Sales',
    };

    map.forEach((key, value) {
      if (keyLabels.containsKey(key)) {
        out.add(_DashboardKpiItem(
          key: key,
          label: keyLabels[key]!,
          value: value?.toString() ?? '0',
          main: key.contains('total') || key.contains('sales'),
        ));
      }
    });

    return out;
  }

  List<_DashboardKpiItem> _parseDashboardKpis(dynamic raw) {
    if (raw is! List) return const [];

    final out = <_DashboardKpiItem>[];
    for (final item in raw) {
      if (item is Map) {
        final m = item.map((k, v) => MapEntry(k.toString(), v));
        final key = (m['key'] ?? '').toString().trim();
        if (key.isEmpty) continue;
        final label = (m['label'] ?? key).toString().trim();
        final value = (m['value'] ?? '').toString().trim();
        final main = (m['main'] == true) || (m['main']?.toString() == '1');
        out.add(
          _DashboardKpiItem(
            key: key,
            label: label.isEmpty ? key : label,
            value: value,
            main: main,
          ),
        );
      }
    }
    return out;
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '').trim()) ?? 0;
  }

  String _formatAmount(double v) => v.toStringAsFixed(2);

  double _pickDouble(List<dynamic> candidates) {
    for (final c in candidates) {
      final d = _asDouble(c);
      if (d != 0) return d;
    }
    return _asDouble(candidates.isEmpty ? null : candidates.first);
  }

  double get _totalSales {
    final m = _dashboardSummary;
    final candidates = <dynamic>[
      m['total_sales'],
      m['totalSale'],
      m['total_sales_amount'],
      m['sales_total'],
      m['total'],
      (m['summary'] is Map ? (m['summary'] as Map)['total_sales'] : null),
      (m['data'] is Map ? (m['data'] as Map)['total_sales'] : null),
    ];
    return _pickDouble(candidates);
  }

  double get _todaySales {
    final m = _dashboardSummary;
    return _pickDouble([
      m['today_sales'],
      m['todays_sales'],
      m['sales_today'],
      m['todaySale'],
      (m['summary'] is Map ? (m['summary'] as Map)['today_sales'] : null),
      (m['data'] is Map ? (m['data'] as Map)['today_sales'] : null),
    ]);
  }

  double get _todayCredit {
    final m = _dashboardSummary;
    return _pickDouble([
      m['today_credit'],
      m['todays_credit'],
      m['today_credits'],
      m['credit_today'],
      m['todayCredit'],
      (m['summary'] is Map ? (m['summary'] as Map)['today_credit'] : null),
      (m['data'] is Map ? (m['data'] as Map)['today_credit'] : null),
    ]);
  }

  double get _todayProfit {
    final m = _dashboardSummary;
    return _pickDouble([
      m['today_profit'],
      m['todays_profit'],
      m['profit_today'],
      (m['summary'] is Map ? (m['summary'] as Map)['today_profit'] : null),
      (m['data'] is Map ? (m['data'] as Map)['today_profit'] : null),
    ]);
  }

  double get _expensesToday {
    final m = _dashboardSummary;
    return _pickDouble([
      m['expenses_today'],
      m['expense_today'],
      m['today_expense'],
      m['today_expenses'],
      (m['summary'] is Map ? (m['summary'] as Map)['expenses_today'] : null),
      (m['data'] is Map ? (m['data'] as Map)['expenses_today'] : null),
    ]);
  }

  double get _todayStockValue {
    final m = _dashboardSummary;
    return _pickDouble([
      m['today_stock_value'],
      m['stock_value_today'],
      m['stock_today_value'],
      m['todayStockValue'],
      (m['summary'] is Map ? (m['summary'] as Map)['today_stock_value'] : null),
      (m['data'] is Map ? (m['data'] as Map)['today_stock_value'] : null),
    ]);
  }

  double get _monthSales {
    final m = _dashboardSummary;
    return _pickDouble([
      m['month_sales'],
      m['monthly_sales'],
      m['sales_month'],
      m['this_month_sales'],
      m['thismonth_sales'],
      (m['summary'] is Map ? (m['summary'] as Map)['month_sales'] : null),
      (m['data'] is Map ? (m['data'] as Map)['month_sales'] : null),
    ]);
  }

  double get _monthCredits {
    final m = _dashboardSummary;
    return _pickDouble([
      m['month_credits'],
      m['monthly_credits'],
      m['credits_month'],
      m['this_month_credits'],
      m['thismonth_credits'],
      (m['summary'] is Map ? (m['summary'] as Map)['thismonth_credits'] : null),
      (m['data'] is Map ? (m['data'] as Map)['thismonth_credits'] : null),
    ]);
  }

  double get _monthProfit {
    final m = _dashboardSummary;
    return _pickDouble([
      m['month_profit'],
      m['monthly_profit'],
      m['profit_month'],
      m['this_month_profit'],
      m['thismonth_profit'],
      (m['summary'] is Map ? (m['summary'] as Map)['thismonth_profit'] : null),
      (m['data'] is Map ? (m['data'] as Map)['thismonth_profit'] : null),
    ]);
  }

  double get _monthExpense {
    final m = _dashboardSummary;
    return _pickDouble([
      m['month_expense'],
      m['month_expenses'],
      m['monthly_expense'],
      m['expenses_month'],
      m['this_month_expense'],
      (m['summary'] is Map ? (m['summary'] as Map)['month_expense'] : null),
      (m['data'] is Map ? (m['data'] as Map)['month_expense'] : null),
    ]);
  }

  double get _servicesRevenue {
    final m = _dashboardSummary;
    return _pickDouble([
      m['services_revenue'],
      m['service_revenue'],
      m['total_service_revenue'],
      m['service_sales_total'],
      (m['summary'] is Map ? (m['summary'] as Map)['services_revenue'] : null),
      (m['data'] is Map ? (m['data'] as Map)['services_revenue'] : null),
    ]);
  }

  double get _servicesToday {
    final m = _dashboardSummary;
    return _pickDouble([
      m['today_services_revenue'],
      m['today_service_revenue'],
      m['services_revenue_today'],
      m['service_revenue_today'],
      (m['summary'] is Map ? (m['summary'] as Map)['today_services_revenue'] : null),
      (m['data'] is Map ? (m['data'] as Map)['today_services_revenue'] : null),
    ]);
  }

  Future<void> _fetchDashboardMenu() async {
    setState(() {
      _menuLoading = true;
      _menuError = null;
    });

    try {
      dynamic raw;
      try {
        final res = await ApiService.instance.auth.constants();
        final constants = res.raw['constants'];
        if (constants is Map) {
          raw = constants['dashboard_menu'] ?? constants['dashboardMenu'];
        }
      } catch (_) {
        raw = null;
      }

      raw ??= await ApiService.instance.app.getDashboardMenu();

      final out = <_DashboardMenuItem>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final name = item['name']?.toString() ?? '';
            final desc = item['description']?.toString() ??
                item['desc']?.toString() ??
                item['subtitle']?.toString() ??
                item['details']?.toString();
            final iconUrlRaw = item['icon']?.toString() ??
                item['icon_url']?.toString() ??
                item['image']?.toString() ??
                item['img']?.toString();

            final iconUrl = (iconUrlRaw ?? '').trim();
            final resolvedIconUrl = iconUrl.isEmpty
                ? null
                : (iconUrl.contains('<') || iconUrl.contains("bi ")
                    ? null
                    : iconUrl);

            if (name.isNotEmpty) {
              final d = (desc ?? '').trim();
              out.add(_DashboardMenuItem(
                name: name,
                description: d.isEmpty ? null : d,
                iconUrl: resolvedIconUrl,
              ));
            }
          } else if (item != null) {
            final name = item.toString();
            if (name.isNotEmpty) out.add(_DashboardMenuItem(name: name));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _dashboardMenu = out;
        _menuLoading = false;
        if (out.isEmpty) {
          _menuError = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _menuLoading = false;
        _menuError = e.toString();
      });
    }
  }

  IconData _iconForMenuName(String name) {
    final n = name.toLowerCase();
    if (n == 's-u' || n == 'su' || n.contains('super user') || n.contains('s-u')) {
      return Icons.admin_panel_settings_outlined;
    }
    if (n.contains('stock')) return Icons.inventory_2_outlined;
    if (n.contains('service')) return Icons.design_services_outlined;
    if (n.contains('sale')) return Icons.point_of_sale_outlined;
    if (n.contains('order')) return Icons.shopping_bag_outlined;
    if (n.contains('purchase')) return Icons.shopping_cart_outlined;
    if (n.contains('invoice')) return Icons.receipt_long_outlined;
    if (n.contains('profit')) return Icons.trending_up_rounded;
    if (n.contains('expense')) return Icons.payments_outlined;
    if (n.contains('customer')) return Icons.people_outline;
    if (n.contains('account') || n.contains('cashflow') || n.contains('cash flow')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (n.contains('report')) return Icons.bar_chart_rounded;
    if (n.contains('sms') || n.contains('email')) return Icons.mark_email_read_outlined;
    if (n.contains('file') || n.contains('cabinet') || n.contains('document')) {
      return Icons.folder_open_rounded;
    }
    if (n.contains('revenue')) return Icons.trending_up_rounded;
    return Icons.grid_view_rounded;
  }

  List<_TileItem> _buildTiles() {
    return _dashboardMenu
        .map(
          (m) => _TileItem(
            label: m.name,
            description: m.description,
            icon: _iconForMenuName(m.name),
            iconUrl: m.iconUrl,
          ),
        )
        .toList();
  }

  Future<void> _logout() async {
    try {
      await ApiService.instance.auth.signOut();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (_) => const SearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 980;

    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    // Check if all critical data failed to load
    final criticalError = _shopsError != null && _summaryError != null && _menuError != null;
    final allLoading = _shopsLoading && _summaryLoading && _menuLoading;
    
    if (criticalError && !allLoading) {
      // Show development error page when critical APIs fail
      return _DevelopmentErrorPage(
        onRetry: () async {
          await _fetchMyShops();
          await _fetchDashboardSummary();
          await _fetchDashboardMenu();
        },
        errorMessage: _shopsError ?? _summaryError ?? _menuError,
      );
    }

    final pageTitle = switch (_selectedIndex) {
      0 => '',
      1 => 'Shops',
      2 => 'Members',
      3 => 'Customers',
      4 => 'Suppliers',
      5 => 'Products',
      _ => 'Dashboard',
    };

    // Build quick actions based on user permissions
    final perm = PermissionService();
    final quickActions = <_QuickAction>[
      if (perm.canMakeSales) 
        const _QuickAction(label: 'Sale', icon: Icons.point_of_sale_outlined),
      if (perm.canManageOrders) 
        const _QuickAction(label: 'Order', icon: Icons.shopping_bag_outlined),
      if (perm.canAddProduct) 
        const _QuickAction(label: 'Product', icon: Icons.inventory_2_outlined),
      // Purchase - requires supplier view permission
      if (perm.canViewSuppliers) 
        const _QuickAction(label: 'Purchase', icon: Icons.shopping_cart_outlined),
      if (perm.canMakeInvoice) 
        const _QuickAction(label: 'Invoice', icon: Icons.receipt_long_outlined),
    ];

    final tiles = _buildTiles();

    final hasBusiness = _selectedShop != null;

    void onQuickActionTap(String label) {
      Widget page;
      final normalized = label.trim().toLowerCase();
      final isStockAndServices = normalized.contains('stock') && normalized.contains('service');
      final isSalesAndOrders = normalized.contains('sale') && normalized.contains('order');
      final isPurchasesAndSuppliers = normalized.contains('purchase') && normalized.contains('supplier');
      final isRevenueExpensesProfit =
          normalized.contains('revenue') || (normalized.contains('expense') && normalized.contains('profit'));
      final isAccountsAndCashflow = normalized.contains('account') && normalized.contains('cash');
      final isFileCabinet = normalized.contains('file') && (normalized.contains('cabin') || normalized.contains('cabinet'));
      final isSmsAndEmails = normalized.contains('sms') || normalized.contains('email');

      if (isStockAndServices) {
        page = const StockAndServicesPage();
      } else if (isSalesAndOrders) {
        page = SalesAndOrdersPage(shopId: _selectedShop?.id);
      } else if (isPurchasesAndSuppliers) {
        page = const PurchasesPage();
      } else if (isRevenueExpensesProfit) {
        page = const RevenueExpensesProfitPage();
      } else if (isAccountsAndCashflow) {
        page = const AccountsCashflowPage();
      } else if (isFileCabinet) {
        page = const FileCabinetPage();
      } else if (isSmsAndEmails) {
        page = const SmsEmailsPage();
      } else {
        switch (normalized) {
          case 'sale':
            page = const SalesPage();
            break;
          case 'order':
            page = const OrdersPage();
            break;
          case 'product':
            page = ProductsPage(userId: _userId, shopId: _selectedShop?.id);
            break;
          case 'purchase':
            page = const PurchasesPage();
            break;
          case 'invoice':
            page = const InvoicesPage();
            break;
          case 'expenses':
            page = const ExpensesPage();
            break;
          case 'accounts':
            page = const AccountsPage();
            break;
          case 'reports':
            page = const ReportsHubPage();
            break;
          case 'subscribe':
          case 'subscription':
            page = const SubscriptionPage();
            break;
          case 'add team':
          case 'team':
            page = const AddTeamPage();
            break;
          case 'settings':
            page = const SettingsHubPage();
            break;
          case 'recycle bin':
          case 'recycle':
            page = const RecycleBinPage();
            break;
          case 'affiliate program':
          case 'affiliate':
            page = const AffiliateProgramPage();
            break;
          case 's-u':
          case 'su':
          case 'super user':
            page = const SuPage();
            break;
          case 'add business':
          case 'add business':
            page = const AddBusinessPage();
            break;
          default:
            page = ComingSoonPage(title: label);
            break;
        }
      }
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    }

    final showMobileShortcuts = !isWide && hasBusiness;
    const mobileShortcutsHeight = 92.0;

    Widget dashboardContent() {
      if (_shopsLoading || _summaryLoading || _menuLoading) {
        return _DashboardSkeleton();
      }

      return RefreshIndicator(
        onRefresh: _refreshAll,
        color: Theme.of(context).colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            showMobileShortcuts ? 16 + mobileShortcutsHeight : 16,
          ),
          child: Column(
            children: [
              _BusinessSelector(
              loading: _shopsLoading,
              error: _shopsError,
              refreshing: _summaryLoading,
              shops: _shops,
              selected: _selectedShop,
              onRetry: _fetchMyShops,
              onSelect: (shop) async {
                setState(() => _selectedShop = shop);
                try {
                  // Switch shop and refresh token
                  final res = await ApiService.instance.auth.switchShop(shopId: shop.id);
                  
                  // Save new token if returned
                  final newToken = res.raw['token']?.toString();
                  if (newToken != null && newToken.isNotEmpty) {
                    await ApiService.instance.tokenStore.setToken(newToken);
                  }
                  
                  // Persist shop selection
                  await ApiService.instance.tokenStore.setSelectedShopId(shop.id);
                  
                  // Show success message from backend
                  if (mounted) {
                    final message = res.raw['message']?.toString() ?? 'Switched to ${shop.name}';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                message,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                } catch (e) {
                  // Show error if switch failed
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Failed to switch shop: ${e.toString()}',
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
                await _fetchSidebarData();
                await _fetchDashboardSummary();
                await _fetchDashboardMenu();
              },
              onAddBusiness: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const ManageBusinessPage()),
                );
                if (!mounted) return;
                if (created == true) {
                  await _fetchMyShops();
                }
              },
            ),
            if (!hasBusiness)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Business is required',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Please select or add a business to open the dashboard.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          final created = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const ManageBusinessPage(),
                            ),
                          );
                          if (!mounted) return;
                          if (created == true) {
                            await _fetchMyShops();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add business'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  const SizedBox(height: 10),
                  // Filter chip
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlobalFilterWidget(
                      onFilterChanged: () async {
                        await _fetchDashboardSummary();
                      },
                    ),
                  ),
                  if (_summaryError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InlineErrorCard(
                        message: _summaryError!,
                        onRetry: _fetchDashboardSummary,
                      ),
                    ),
                  if (_summaryLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final allowedKeys = <String>{
                          'sales',
                          'credits',
                          'profit',
                          'expense',
                          'expenses',
                          'purchase',
                          'purchases',
                          'orders',
                        };

                        final items = _dashboardKpis
                            .where((k) => allowedKeys.contains(k.key.toLowerCase()))
                            .map(
                              (k) => (
                                title: k.label,
                                value: k.value,
                                icon: _iconForMenuName(k.key),
                                color: switch (k.key.toLowerCase()) {
                                  'sales' => const Color(0xFF00C853),
                                  'profit' => const Color(0xFF7C4DFF),
                                  'credits' => const Color(0xFFFF6D00),
                                  'expense' || 'expenses' => const Color(0xFFD50000),
                                  'orders' => const Color(0xFF00B0FF),
                                  'purchase' || 'purchases' => const Color(0xFF00E676),
                                  _ => const Color(0xFF651FFF),
                                },
                              ),
                            )
                            .toList();

                        final screenWidth = MediaQuery.of(context).size.width;
                        final kpiWidth = screenWidth < 400 ? 170.0 : (screenWidth < 600 ? 190.0 : 220.0);
                        final kpiHeight = screenWidth < 400 ? 96.0 : 104.0;

                        return SizedBox(
                          height: kpiHeight,
                          child: GestureDetector(
                            onPanDown: (_) => _kpiTimer?.cancel(),
                            onPanEnd: (_) => _startKpiAutoScroll(),
                            onPanCancel: () => _startKpiAutoScroll(),
                            child: ListView.builder(
                              controller: _kpiScrollController,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemBuilder: (context, index) {
                                final i = index % items.length;
                                final keyLower = _dashboardKpis.isNotEmpty
                                    ? _dashboardKpis
                                        .where((k) => allowedKeys.contains(k.key.toLowerCase()))
                                        .map((k) => k.key)
                                        .toList()[i]
                                        .toLowerCase()
                                    : '';

                                String? destinationLabel;
                                switch (keyLower) {
                                  case 'sales':
                                    destinationLabel = 'Sale';
                                    break;
                                  case 'orders':
                                    destinationLabel = 'Order';
                                    break;
                                  case 'purchase' || 'purchases':
                                    destinationLabel = 'Purchase';
                                    break;
                                  case 'expense' || 'expenses':
                                    destinationLabel = 'Expenses';
                                    break;
                                  case 'credits':
                                    destinationLabel = 'Invoice';
                                    break;
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                    width: kpiWidth,
                                    child: _StatCard(
                                      title: items[i].title,
                                      value: items[i].value,
                                      icon: items[i].icon,
                                      color: items[i].color,
                                      onTap: destinationLabel == null
                                          ? null
                                          : () => onQuickActionTap(destinationLabel!),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  if (_menuError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _InlineErrorCard(
                        message: _menuError!,
                        onRetry: _fetchDashboardMenu,
                      ),
                    ),
                  if (_menuLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (tiles.isEmpty)
                    const _DashboardSkeleton()
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 1200 
                            ? 5 
                            : (constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 600 ? 3 : 2));
                        
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tiles.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: constraints.maxWidth < 400 ? 0.92 : 1.05,
                          ),
                          itemBuilder: (context, i) {
                            final t = tiles[i];
                            return _DashboardTile(
                              title: t.label,
                              subtitle: t.description,
                              icon: t.icon,
                              iconUrl: t.iconUrl,
                              onTap: () {
                                onQuickActionTap(t.label);
                              },
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
    }

    final content = switch (_selectedIndex) {
      0 => dashboardContent(),
      1 => ShopsPage(
          selectedShopId: _selectedShop?.id,
          onSelectShop: (s) async {
            setState(() {
              _selectedShop = _Shop(id: s.id, name: s.name);
              _selectedIndex = 0;
            });
            try {
              // Switch shop and refresh token
              final res = await ApiService.instance.auth.switchShop(shopId: s.id);
              
              // Save new token if returned
              final newToken = res.raw['token']?.toString();
              if (newToken != null && newToken.isNotEmpty) {
                await ApiService.instance.tokenStore.setToken(newToken);
              }
              
              // Show success message
              if (mounted) {
                final message = res.raw['message']?.toString() ?? 'Switched to ${s.name}';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Failed to switch shop: ${e.toString()}',
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
            await _fetchSidebarData();
            await _fetchDashboardSummary();
            await _fetchDashboardMenu();
          },
        ),
      2 => const MembersPage(),
      3 => const CustomersPage(embedded: true),
      4 => const SuppliersPage(embedded: true),
      5 => ProductsPage(
          userId: _userId,
          shopId: _selectedShop?.id,
          embedded: true,
        ),
      _ => dashboardContent(),
    };

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: pageTitle,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onMenuPressed: isWide
            ? null
            : () => _scaffoldKey.currentState?.openDrawer(),
        actions: [
          IconButton(
            onPressed: _refreshAll,
            tooltip: 'Refresh',
            icon: (_menuLoading || _shopsLoading)
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () {
              _showSearchDialog();
            },
            tooltip: 'Search',
            icon: const Icon(Icons.search),
          ),
        ],
        showUserMenu: false,
        userInitials: 'U',
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: AppSidebar(
                selectedIndex: _selectedIndex,
                onSelected: (i) {
                  setState(() => _selectedIndex = i);
                  Navigator.of(context).pop();
                },
                userName: _userName,
                userEmail: _userEmail,
                userId: _userId,
                avatarUrl: _avatarUrl,
                counters: _sidebarCounters,
                onShare: () {
                  final msg = _sidebarError == null
                      ? 'Share'
                      : 'Sidebar: $_sidebarError';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                },
                onSignOut: _logout,
              ),
            ),
      bottomSheet: showMobileShortcuts
          ? SafeArea(
              top: false,
              child: Container(
                color: const Color(0xFFF2F2F2),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: _QuickActionsRow(
                  actions: quickActions,
                  onTap: onQuickActionTap,
                ),
              ),
            )
          : null,
      body: Row(
        children: [
          if (isWide)
            AppSidebar(
              selectedIndex: _selectedIndex,
              onSelected: (i) => setState(() => _selectedIndex = i),
              userName: _userName,
              userEmail: _userEmail,
              userId: _userId,
              avatarUrl: _avatarUrl,
              counters: _sidebarCounters,
              onShare: () {
                final msg = _sidebarError == null ? 'Share' : 'Sidebar: $_sidebarError';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              },
              onSignOut: _logout,
            ),
          Expanded(
            child: content,
          ),
        ],
      ),
    );
  }

}

class _Shop {
  const _Shop({required this.id, required this.name});

  final String id;
  final String name;
}

class _BusinessSelector extends StatelessWidget {
  const _BusinessSelector({
    required this.loading,
    required this.error,
    required this.refreshing,
    required this.shops,
    required this.selected,
    required this.onRetry,
    required this.onSelect,
    required this.onAddBusiness,
  });

  final bool loading;
  final String? error;
  final bool refreshing;
  final List<_Shop> shops;
  final _Shop? selected;
  final VoidCallback onRetry;
  final ValueChanged<_Shop> onSelect;
  final VoidCallback onAddBusiness;

  static const _addBusinessValue = '__add_business__';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final valueText = selected?.name ?? 'Select business';

    final selector = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.storefront_outlined,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valueText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      error!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (loading || refreshing)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          else
            PopupMenuButton<String>(
              tooltip: 'Switch business',
              onSelected: (v) {
                if (v == _addBusinessValue) {
                  onAddBusiness();
                  return;
                }
                final shop = shops.firstWhereOrNull((s) => s.id == v);
                if (shop != null) onSelect(shop);
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];

                if (shops.isEmpty) {
                  items.add(
                    PopupMenuItem<String>(
                      enabled: false,
                      value: '__empty__',
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('No businesses found')),
                        ],
                      ),
                    ),
                  );
                } else {
                  for (final s in shops) {
                    final isSelected = s.id == selected?.id;
                    items.add(
                      PopupMenuItem<String>(
                        value: s.id,
                        child: Row(
                          children: [
                            Expanded(child: Text(s.name)),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                }

                items.add(const PopupMenuDivider());
                items.add(
                  const PopupMenuItem<String>(
                    value: _addBusinessValue,
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 18),
                        SizedBox(width: 10),
                        Text('Add business'),
                      ],
                    ),
                  ),
                );

                return items;
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: selector,
      ),
    );
  }
}

extension on Iterable<_Shop> {
  _Shop? get firstOrNull {
    for (final s in this) {
      return s;
    }
    return null;
  }

  _Shop? firstWhereOrNull(bool Function(_Shop) test) {
    for (final s in this) {
      if (test(s)) return s;
    }
    return null;
  }
}


class _TotalSalesCard extends StatelessWidget {
  const _TotalSalesCard({
    required this.color,
    required this.value,
    required this.error,
    required this.onRetry,
  });

  final Color color;
  final double? value;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final shown = value ?? 0;
    final shownText = shown.toStringAsFixed(2);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Total Sales',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            shownText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      error!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.actions,
    required this.onTap,
  });

  final List<_QuickAction> actions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions.map((a) {
          return _QuickActionButton(
            label: a.label,
            icon: a.icon,
            onTap: () => onTap(a.label),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconUrl,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    // Process icon URL if it exists
    Widget iconWidget;
    if (iconUrl != null && iconUrl!.isNotEmpty) {
      String fullUrl = iconUrl!;
      if (!fullUrl.startsWith('http')) {
        final baseUrl = ApiService.instance.client.config.baseUrl;
        fullUrl = Uri.parse(baseUrl).resolve(fullUrl).toString();
      }

      final lower = fullUrl.toLowerCase();
      final isSvg = lower.endsWith('.svg') || lower.contains('svg');
      if (isSvg) {
        iconWidget = SvgPicture.network(
          fullUrl,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(primary, BlendMode.srcIn),
          placeholderBuilder: (_) => Icon(icon, color: primary, size: 24),
        );
      } else {
        iconWidget = Image.network(
          fullUrl,
          width: 24,
          height: 24,
          color: primary,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Icon(icon, color: primary, size: 24),
        );
      }
    } else {
      iconWidget = Icon(icon, color: primary, size: 24);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              flex: 3,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: iconWidget,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 3,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (hasSubtitle) ...[
              const SizedBox(height: 2),
              Flexible(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 3,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            // Business Selector Skeleton
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 20),
            // KPI Stats Skeleton
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 190,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Menu Tiles Skeleton
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (_, __) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF6B7280)),
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

class _DevelopmentErrorPage extends StatelessWidget {
  const _DevelopmentErrorPage({
    required this.onRetry,
    this.errorMessage,
  });

  final VoidCallback onRetry;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF800000),
                        Color(0xFFA52A2A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF800000).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Under Development',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'We\'re currently working on this feature.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stay tuned for updates!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFB91C1C),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: $errorMessage',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
