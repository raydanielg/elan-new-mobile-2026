import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class RevenueExpensesProfitPage extends StatefulWidget {
  const RevenueExpensesProfitPage({super.key});

  @override
  State<RevenueExpensesProfitPage> createState() => _RevenueExpensesProfitPageState();
}

class _RevenueExpensesProfitPageState extends State<RevenueExpensesProfitPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = false;
  String? _error;

  Map<String, dynamic> _profitSummary = {};
  Map<String, dynamic> _expenseSummary = {};
  List<dynamic> _expenseList = [];
  List<dynamic> _expenseAccounts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.instance.app.getData('profit_summary'),
        ApiService.instance.app.getData('expense_summary'),
        ApiService.instance.app.getData('expenses'),
        ApiService.instance.app.getData('expense_accounts'),
      ]);

      if (!mounted) return;

      setState(() {
        _profitSummary = _asMap(results[0]);
        _expenseSummary = _asMap(results[1]);
        _expenseList = _asList(results[2]);
        _expenseAccounts = _asList(results[3]);
        _loading = false;
      });

      if (kDebugMode) {
        debugPrint('profit_summary: $_profitSummary');
        debugPrint('expense_summary: $_expenseSummary');
        debugPrint('expenses count: ${_expenseList.length}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return [];
  }

  String _fmt(dynamic v) {
    if (v == null) return '0.00';
    if (v is num) return v.toStringAsFixed(2);
    final n = double.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
    return (n ?? 0).toStringAsFixed(2);
  }

  void _showAddExpenseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddExpenseSheet(
        accounts: _expenseAccounts,
        onSubmitted: _fetchAllData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Revenue, Expenses & Profit',
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
                Tab(text: 'Profit', icon: Icon(Icons.trending_up)),
                Tab(text: 'Expenses', icon: Icon(Icons.wallet)),
                Tab(text: 'List', icon: Icon(Icons.list)),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError(_error!)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildProfitTab(),
                          _buildExpensesTab(),
                          _buildExpenseListTab(),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchAllData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitTab() {
    final revenue = _profitSummary['total_revenue'] ?? _profitSummary['revenue'] ?? 0;
    final cost = _profitSummary['total_cost'] ?? _profitSummary['cost'] ?? 0;
    final profit = _profitSummary['total_profit'] ?? _profitSummary['profit'] ?? 0;
    final margin = profit is num && revenue is num && revenue != 0
        ? '${((profit / revenue) * 100).toStringAsFixed(1)}%'
        : '0.0%';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildKpiCard('Total Revenue', 'Tsh ${_fmt(revenue)}', Icons.attach_money, Colors.green),
          const SizedBox(height: 12),
          _buildKpiCard('Total Cost', 'Tsh ${_fmt(cost)}', Icons.money_off, Colors.orange),
          const SizedBox(height: 12),
          _buildKpiCard('Net Profit', 'Tsh ${_fmt(profit)}', Icons.trending_up, Colors.purple),
          const SizedBox(height: 12),
          _buildKpiCard('Profit Margin', margin, Icons.percent, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildExpensesTab() {
    final total = _expenseSummary['total_expenses'] ?? _expenseSummary['total'] ?? 0;
    final count = _expenseSummary['expense_count'] ?? _expenseList.length;
    final avg = count > 0 && total is num
        ? (total / count)
        : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildKpiCard('Total Expenses', 'Tsh ${_fmt(total)}', Icons.wallet, Colors.red),
          const SizedBox(height: 12),
          _buildKpiCard('Expense Count', count.toString(), Icons.format_list_numbered, Colors.blue),
          const SizedBox(height: 12),
          _buildKpiCard('Average Expense', 'Tsh ${_fmt(avg)}', Icons.calculate, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildExpenseListTab() {
    if (_expenseList.isEmpty) {
      return const Center(
        child: Text(
          'No expenses found',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expenseList.length,
      itemBuilder: (context, i) {
        final e = _expenseList[i];
        final title = e['title']?.toString() ?? 'Expense';
        final amount = e['amount'] ?? e['total'] ?? 0;
        final date = e['record_date']?.toString() ?? e['date']?.toString() ?? '';
        final category = e['category_name']?.toString() ?? e['category']?.toString() ?? 'General';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              child: const Icon(Icons.wallet, color: Colors.red),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('$category • $date'),
            trailing: Text(
              'Tsh ${_fmt(amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    fontSize: 18,
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

class _AddExpenseSheet extends StatefulWidget {
  final List<dynamic> accounts;
  final VoidCallback onSubmitted;

  const _AddExpenseSheet({required this.accounts, required this.onSubmitted});

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await ApiService.instance.app.postData(
        'expense/create',
        body: {
          'title': _titleCtrl.text.trim(),
          'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
          'category_id': _selectedCategoryId,
          'record_date': _selectedDate.toIso8601String().split('T').first,
          'note': _noteCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Create Expense',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: widget.accounts
                  .where((a) => a is Map)
                  .map((a) => DropdownMenuItem<String>(
                        value: a['id']?.toString() ?? a['account_id']?.toString(),
                        child: Text(a['name']?.toString() ?? a['title']?.toString() ?? 'Category'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                hintText: 'e.g., Office Supplies',
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: 'Tsh ',
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDate.toIso8601String().split('T').first,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
