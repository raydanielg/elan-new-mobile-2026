import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../widgets/app_header.dart';
import '../widgets/global_filter_widget.dart';

class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _AnalyticsData {
  final double totalSales;
  final double todaySales;
  final double monthSales;
  final double totalProfit;
  final double todayProfit;
  final double monthProfit;
  final double totalExpenses;
  final double todayExpenses;
  final double monthExpenses;
  final double totalCredits;
  final double monthCredits;

  const _AnalyticsData({
    required this.totalSales,
    required this.todaySales,
    required this.monthSales,
    required this.totalProfit,
    required this.todayProfit,
    required this.monthProfit,
    required this.totalExpenses,
    required this.todayExpenses,
    required this.monthExpenses,
    required this.totalCredits,
    required this.monthCredits,
  });
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> {
  bool _loading = true;
  String? _error;
  _AnalyticsData? _data;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  double _parseAmount(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    final s = raw.toString().replaceAll(',', '').trim();
    return double.tryParse(s) ?? 0;
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.instance.app.getData('dashboard_summary');

      if (raw is Map) {
        _data = _AnalyticsData(
          totalSales: _parseAmount(raw['total_sales'] ?? raw['totalSale']),
          todaySales: _parseAmount(raw['today_sales'] ?? raw['todays_sales']),
          monthSales: _parseAmount(raw['month_sales'] ?? raw['monthly_sales']),
          totalProfit: _parseAmount(raw['total_profit']),
          todayProfit: _parseAmount(raw['today_profit']),
          monthProfit: _parseAmount(raw['month_profit']),
          totalExpenses: _parseAmount(raw['total_expenses'] ?? raw['expenses_today']),
          todayExpenses: _parseAmount(raw['expenses_today']),
          monthExpenses: _parseAmount(raw['month_expense']),
          totalCredits: _parseAmount(raw['total_credits']),
          monthCredits: _parseAmount(raw['month_credits']),
        );
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
        title: 'Sales Analytics',
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
        actions: [
          IconButton(
            onPressed: _fetchAnalytics,
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
        ],
      ),
      body: Column(
        children: [
          // Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: GlobalFilterWidget(
              onFilterChanged: () async {
                await _fetchAnalytics();
              },
            ),
          ),
          // Content
          Expanded(
            child: _buildBody(colorScheme),
          ),
        ],
      ),
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
                'Failed to load analytics',
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
                onPressed: _fetchAnalytics,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_data == null) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sales Overview
            _buildSectionTitle('Sales Overview', Icons.trending_up),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Today',
                    'TSh ${_data!.todaySales.toStringAsFixed(0)}',
                    const Color(0xFF00C853),
                    Icons.today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'This Month',
                    'TSh ${_data!.monthSales.toStringAsFixed(0)}',
                    const Color(0xFF00B0FF),
                    Icons.calendar_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              'Total Sales',
              'TSh ${_data!.totalSales.toStringAsFixed(0)}',
              const Color(0xFF7C4DFF),
              Icons.account_balance_wallet,
              isFullWidth: true,
            ),
            const SizedBox(height: 24),

            // Profit Overview
            _buildSectionTitle('Profit Overview', Icons.show_chart),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Today',
                    'TSh ${_data!.todayProfit.toStringAsFixed(0)}',
                    const Color(0xFF10B981),
                    Icons.today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'This Month',
                    'TSh ${_data!.monthProfit.toStringAsFixed(0)}',
                    const Color(0xFF00C853),
                    Icons.calendar_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              'Total Profit',
              'TSh ${_data!.totalProfit.toStringAsFixed(0)}',
              const Color(0xFF8B5CF6),
              Icons.account_balance_wallet,
              isFullWidth: true,
            ),
            const SizedBox(height: 24),

            // Expenses Overview
            _buildSectionTitle('Expenses Overview', Icons.money_off),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Today',
                    'TSh ${_data!.todayExpenses.toStringAsFixed(0)}',
                    const Color(0xFFEF4444),
                    Icons.today,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'This Month',
                    'TSh ${_data!.monthExpenses.toStringAsFixed(0)}',
                    const Color(0xFFF97316),
                    Icons.calendar_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              'Total Expenses',
              'TSh ${_data!.totalExpenses.toStringAsFixed(0)}',
              const Color(0xFFDC2626),
              Icons.account_balance_wallet,
              isFullWidth: true,
            ),
            const SizedBox(height: 24),

            // Credits Overview
            _buildSectionTitle('Credits Overview', Icons.receipt_long),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'This Month',
                    'TSh ${_data!.monthCredits.toStringAsFixed(0)}',
                    const Color(0xFFF59E0B),
                    Icons.calendar_month,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Total Credits',
                    'TSh ${_data!.totalCredits.toStringAsFixed(0)}',
                    const Color(0xFFD97706),
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isFullWidth ? 22 : 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
