import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  bool _loading = false;
  String? _error;
  List<_SupplierItem> _suppliers = const [];

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.instance.app.getData('suppliers');
      final suppliers = _parseSuppliers(raw);
      if (!mounted) return;
      setState(() {
        _suppliers = suppliers;
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

  List<_SupplierItem> _parseSuppliers(dynamic raw) {
    dynamic data = raw;
    if (raw is Map && raw['data'] != null) data = raw['data'];

    final out = <_SupplierItem>[];
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final id = item['supplier_id']?.toString() ?? item['id']?.toString() ?? '';
        final name = item['supplier_name']?.toString() ?? item['name']?.toString() ?? '';
        final phone = item['phone']?.toString() ?? item['mobile']?.toString() ?? '';
        final email = item['email']?.toString() ?? '';
        if (id.trim().isEmpty && name.trim().isEmpty && phone.trim().isEmpty) continue;
        out.add(
          _SupplierItem(
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

  void _openAddSupplier() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add supplier',
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
              child: _AddSupplierPanel(
                onCreated: () async {
                  await _fetchSuppliers();
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

  void _onSupplierAction(_SupplierItem s, _SupplierAction action) {
    switch (action) {
      case _SupplierAction.edit:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit supplier: Coming soon')),
        );
        break;
      case _SupplierAction.delete:
        _confirmDelete(s);
        break;
    }
  }

  Future<void> _confirmDelete(_SupplierItem s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete supplier'),
          content: Text('Delete ${s.name.isEmpty ? 'this supplier' : s.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete supplier: API endpoint not configured yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final pageBody = SafeArea(
      top: !widget.embedded,
      child: RefreshIndicator(
        onRefresh: _fetchSuppliers,
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
                    child: Icon(Icons.local_shipping_outlined, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total Suppliers',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _loading ? '...' : _suppliers.length.toString(),
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
                    onPressed: _openAddSupplier,
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
                onRetry: _fetchSuppliers,
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_suppliers.isEmpty)
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
                        'No suppliers found. Pull down to refresh.',
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
                  for (final s in _suppliers) ...[
                    _SupplierCard(
                      supplier: s,
                      onAction: (a) => _onSupplierAction(s, a),
                    ),
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
        title: 'Suppliers',
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: pageBody,
    );
  }
}

class _SupplierItem {
  const _SupplierItem({
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

enum _SupplierAction { edit, delete }

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.supplier, required this.onAction});

  final _SupplierItem supplier;
  final ValueChanged<_SupplierAction> onAction;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final name = supplier.name.trim().isEmpty
        ? (supplier.phone.trim().isEmpty ? 'Supplier' : supplier.phone.trim())
        : supplier.name.trim();
    final initials = name.isEmpty ? 'S' : name.toUpperCase().substring(0, 1);

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
                  supplier.phone.isNotEmpty
                      ? supplier.phone
                      : (supplier.email.isNotEmpty ? supplier.email : 'ID: ${supplier.id}'),
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
          PopupMenuButton<_SupplierAction>(
            onSelected: onAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _SupplierAction.edit,
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: _SupplierAction.delete,
                child: Text('Delete'),
              ),
            ],
            child: Icon(Icons.more_vert, color: primary.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _AddSupplierPanel extends StatefulWidget {
  const _AddSupplierPanel({required this.onCreated});

  final Future<void> Function() onCreated;

  @override
  State<_AddSupplierPanel> createState() => _AddSupplierPanelState();
}

class _AddSupplierPanelState extends State<_AddSupplierPanel> {
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
      final endpoint = '/app/post/postdata/supplier/add';
      final payload = <String, dynamic>{
        'supplier_name': _nameCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      };

      payload.removeWhere((k, v) => v == null || v.toString().trim().isEmpty);

      Map<String, dynamic>? respRaw;
      try {
        final resp = await ApiService.instance.client.postJson(endpoint, body: payload);
        respRaw = resp.raw;
      } catch (_) {
        final resp = await ApiService.instance.client.postForm(endpoint, body: payload);
        respRaw = resp.raw;
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onCreated();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            respRaw?['message']?.toString() ?? 'Supplier added successfully',
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
                      'Add supplier',
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
                          labelText: 'Supplier name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Supplier name is required';
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
                          _submitting ? 'Adding...' : 'Add supplier',
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
