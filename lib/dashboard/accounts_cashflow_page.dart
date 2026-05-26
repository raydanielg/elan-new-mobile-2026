import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class AccountsCashflowPage extends StatefulWidget {
  const AccountsCashflowPage({super.key});

  @override
  State<AccountsCashflowPage> createState() => _AccountsCashflowPageState();
}

class _AccountsCashflowPageState extends State<AccountsCashflowPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  String? _error;

  List<dynamic> _accounts = [];
  List<dynamic> _transactions = [];

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        ApiService.instance.app.getData('cashbookAccounts'),
        ApiService.instance.app.getData('cashbook'),
      ]);

      if (!mounted) return;

      setState(() {
        _accounts = _asList(results[0]);
        _transactions = _asList(results[1]);
        _loading = false;
      });

      if (kDebugMode) {
        debugPrint('Accounts: ${_accounts.length}, Transactions: ${_transactions.length}');
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

  String _fmt(dynamic v) {
    if (v == null) return '0.00';
    if (v is num) return v.toStringAsFixed(2);
    final n = double.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.]'), ''));
    return (n ?? 0).toStringAsFixed(2);
  }

  void _showTransferSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TransferSheet(
        accounts: _accounts,
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
        title: 'Accounts & Cashflow',
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
                Tab(text: 'Accounts', icon: Icon(Icons.account_balance)),
                Tab(text: 'Transactions', icon: Icon(Icons.receipt_long)),
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
                          _buildAccountsTab(),
                          _buildTransactionsTab(),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTransferSheet,
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Transfer'),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchAllData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsTab() {
    if (_accounts.isEmpty) {
      return const Center(
        child: Text(
          'No accounts found',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    double totalBalance = 0;
    for (final a in _accounts) {
      if (a is Map) {
        final bal = a['balance'] ?? a['amount'] ?? 0;
        totalBalance += bal is num ? bal : 0;
      }
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Tsh ${_fmt(totalBalance)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _accounts.length,
            itemBuilder: (context, i) {
              final a = _accounts[i];
              final name = a['account_name']?.toString() ??
                  a['name']?.toString() ??
                  'Account';
              final balance = a['balance'] ?? a['amount'] ?? 0;
              final type = a['account_type']?.toString() ??
                  a['type']?.toString() ??
                  'General';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.green),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(type),
                  trailing: Text(
                    'Tsh ${_fmt(balance)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Text(
          'No transactions found',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, i) {
        final t = _transactions[i];
        final desc = t['description']?.toString() ??
            t['narration']?.toString() ??
            'Transaction';
        final amount = t['amount'] ?? 0;
        final type = t['transaction_type']?.toString() ??
            t['type']?.toString() ??
            'debit';
        final date = t['transaction_date']?.toString() ??
            t['date']?.toString() ??
            '';
        final isCredit = type.toLowerCase() == 'credit' ||
            type.toLowerCase() == 'income' ||
            type.toLowerCase() == 'deposit';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCredit
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
            title: Text(desc, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(date),
            trailing: Text(
              '${isCredit ? '+' : '-'} Tsh ${_fmt(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isCredit ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TransferSheet extends StatefulWidget {
  final List<dynamic> accounts;
  final VoidCallback onSubmitted;

  const _TransferSheet({
    required this.accounts,
    required this.onSubmitted,
  });

  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _fromAccountId;
  String? _toAccountId;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromAccountId == null || _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both accounts')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await ApiService.instance.app.postData(
        'cashbook/transfer',
        body: {
          'from_account_id': _fromAccountId,
          'to_account_id': _toAccountId,
          'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
          'note': _noteCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer completed successfully')),
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
                    'Transfer Funds',
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
              value: _fromAccountId,
              decoration: const InputDecoration(
                labelText: 'From Account',
                border: OutlineInputBorder(),
              ),
              items: widget.accounts
                  .where((a) => a is Map)
                  .map((a) => DropdownMenuItem<String>(
                        value: a['id']?.toString() ?? a['account_id']?.toString(),
                        child: Text(a['account_name']?.toString() ??
                            a['name']?.toString() ??
                            'Account'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _fromAccountId = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _toAccountId,
              decoration: const InputDecoration(
                labelText: 'To Account',
                border: OutlineInputBorder(),
              ),
              items: widget.accounts
                  .where((a) => a is Map)
                  .map((a) => DropdownMenuItem<String>(
                        value: a['id']?.toString() ?? a['account_id']?.toString(),
                        child: Text(a['account_name']?.toString() ??
                            a['name']?.toString() ??
                            'Account'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _toAccountId = v),
              validator: (v) => v == null ? 'Required' : null,
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
            TextFormField(
              controller: _noteCtrl,
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
                  : const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }
}
