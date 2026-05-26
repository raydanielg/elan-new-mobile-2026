import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _AddCustomerPanel extends StatefulWidget {
  const _AddCustomerPanel({required this.onCreated});

  final Future<void> Function() onCreated;

  @override
  State<_AddCustomerPanel> createState() => _AddCustomerPanelState();
}

class _AddCustomerPanelState extends State<_AddCustomerPanel> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final endpoints = <String>[
        '/app/post/postdata/customer/create',
        '/app/post/postdata/${Uri.encodeComponent('customer/create')}',
        '/app/post/postdata/customer_create',
        '/app/post/postdata/customer-create',
        '/app/post/postdata/customer',
      ];
      final payload = <String, dynamic>{
        'customer_name': _nameCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'endpoint': 'customer/create',
        'action': 'create',
      };

      payload.removeWhere((k, v) => v == null || v.toString().trim().isEmpty);

      Map<String, dynamic>? respRaw;
      Object? lastErr;

      for (final endpoint in endpoints) {
        try {
          final resp = await ApiService.instance.client.postJson(
            endpoint,
            body: payload,
          );
          respRaw = resp.raw;
          lastErr = null;
          break;
        } catch (e) {
          lastErr = e;
          try {
            final resp = await ApiService.instance.client.postForm(
              endpoint,
              body: payload,
            );
            respRaw = resp.raw;
            lastErr = null;
            break;
          } catch (e2) {
            lastErr = e2;
          }
        }
      }

      if (respRaw == null) {
        throw lastErr ?? Exception('Unable to add customer');
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onCreated();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            respRaw['message']?.toString() ?? 'Customer added successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      left: false,
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 8, 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add customer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111827),
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Customer name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Customer name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (optional)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return null;
                          if (!s.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: primary),
                        onPressed: _submitting ? null : _submit,
                        child: Text(
                          _submitting ? 'Adding...' : 'Add customer',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomersPageState extends State<CustomersPage> {
  bool _loading = false;
  String? _error;
  List<_CustomerItem> _customers = const [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.instance.app.getData('customers');
      final customers = _parseCustomers(raw);
      if (!mounted) return;
      setState(() {
        _customers = customers;
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

  List<_CustomerItem> _parseCustomers(dynamic raw) {
    dynamic data = raw;
    if (raw is Map && raw['data'] != null) data = raw['data'];

    final out = <_CustomerItem>[];

    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final id = item['customer_id']?.toString() ?? item['id']?.toString() ?? '';
        final name = item['customer_name']?.toString() ??
            item['name']?.toString() ??
            item['full_name']?.toString() ??
            '';
        final phone = item['phone']?.toString() ?? item['mobile']?.toString() ?? '';
        final email = item['email']?.toString() ?? '';

        if (id.trim().isEmpty && name.trim().isEmpty && phone.trim().isEmpty) continue;
        out.add(
          _CustomerItem(
            id: id.trim(),
            name: name.trim(),
            phone: phone.trim(),
            email: email.trim(),
          ),
        );
      }
    }

    return out;
  }

  void _openAddCustomer() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add customer',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) {
        final width = MediaQuery.of(context).size.width;
        final panelWidth = width < 420 ? width : 420.0;

        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: panelWidth,
              height: double.infinity,
              child: _AddCustomerPanel(
                onCreated: () async {
                  await _fetchCustomers();
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final pageBody = SafeArea(
      top: !widget.embedded,
      child: RefreshIndicator(
        onRefresh: _fetchCustomers,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.people_outline, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total Customers',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _loading ? '...' : _customers.length.toString(),
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openAddCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text(
                      'Add',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              _ErrorCard(
                message: _error!,
                onRetry: _fetchCustomers,
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_customers.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'No customers found. Pull down to refresh.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  for (final c in _customers) ...[
                    _CustomerCard(customer: c),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return pageBody;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Customers',
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: pageBody,
    );
  }
}

class _CustomerItem {
  const _CustomerItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});

  final _CustomerItem customer;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final name = customer.name.trim().isEmpty
        ? (customer.phone.trim().isEmpty ? 'Customer' : customer.phone.trim())
        : customer.name.trim();
    final initials = name.isEmpty ? 'C' : name.toUpperCase().substring(0, 1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
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
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.phone.isNotEmpty
                      ? customer.phone
                      : (customer.email.isNotEmpty ? customer.email : 'ID: ${customer.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    fontSize: 12,
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

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
              maxLines: 2,
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
