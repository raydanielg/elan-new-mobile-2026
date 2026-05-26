import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class AddTeamPage extends StatefulWidget {
  const AddTeamPage({super.key});

  @override
  State<AddTeamPage> createState() => _AddTeamPageState();
}

class _AddTeamPageState extends State<AddTeamPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  String? _error;

  List<dynamic> _teamMembers = [];
  List<dynamic> _waiters = [];
  List<dynamic> _roles = [];

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
        ApiService.instance.app.getData('team'),
        ApiService.instance.app.getData('waiters'),
        ApiService.instance.app.getData('permissions'),
      ]);

      if (!mounted) return;

      setState(() {
        _teamMembers = _asList(results[0]);
        _waiters = _asList(results[1]);
        _roles = _extractRoles(results[2]);
        _loading = false;
      });

      if (kDebugMode) {
        debugPrint('Team: ${_teamMembers.length}, Waiters: ${_waiters.length}');
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
    if (raw is Map && raw['team'] is List) return raw['team'] as List;
    return [];
  }

  List<dynamic> _extractRoles(dynamic raw) {
    if (raw is! Map) return ['Admin', 'Manager', 'Staff', 'Cashier'];
    final data = raw['data'] ?? raw;
    if (data is Map && data['roles'] is List) return data['roles'] as List;
    return ['Admin', 'Manager', 'Staff', 'Cashier'];
  }

  void _showAddMemberSheet(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMemberSheet(
        type: type,
        roles: _roles,
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
        title: 'Add Team',
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
                Tab(text: 'Staff', icon: Icon(Icons.people)),
                Tab(text: 'Waiters', icon: Icon(Icons.room_service)),
                Tab(text: 'Roles', icon: Icon(Icons.badge)),
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
                          _buildStaffTab(),
                          _buildWaitersTab(),
                          _buildRolesTab(),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final index = _tabController.index;
          final type = index == 0 ? 'staff' : index == 1 ? 'waiter' : 'role';
          _showAddMemberSheet(type);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
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

  Widget _buildStaffTab() {
    if (_teamMembers.isEmpty) {
      return const Center(
        child: Text(
          'No staff members found',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teamMembers.length,
      itemBuilder: (context, i) {
        final m = _teamMembers[i];
        final name = m['full_name']?.toString() ??
            m['name']?.toString() ??
            'Team Member';
        final role = m['role']?.toString() ?? m['role_name']?.toString() ?? 'Staff';
        final phone = m['phone']?.toString() ?? '';
        final email = m['email']?.toString() ?? '';
        final isActive = m['status']?.toString() == 'active' ||
            m['is_active'] == true ||
            m['active'] == 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('$role${phone.isNotEmpty ? ' • $phone' : ''}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaitersTab() {
    if (_waiters.isEmpty) {
      return const Center(
        child: Text(
          'No waiters found',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _waiters.length,
      itemBuilder: (context, i) {
        final w = _waiters[i];
        final name = w['full_name']?.toString() ??
            w['name']?.toString() ??
            'Waiter';
        final code = w['code']?.toString() ?? w['waiter_code']?.toString() ?? '';
        final table = w['assigned_table']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: const Icon(Icons.room_service, color: Colors.orange),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('Code: $code${table.isNotEmpty ? ' • Table: $table' : ''}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }

  Widget _buildRolesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _roles.length,
      itemBuilder: (context, i) {
        final r = _roles[i];
        final name = r is String ? r : (r['name']?.toString() ?? 'Role');
        final desc = r is Map ? (r['description']?.toString() ?? '') : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withValues(alpha: 0.1),
              child: const Icon(Icons.badge, color: Colors.purple),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: desc.isNotEmpty ? Text(desc) : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  final String type;
  final List<dynamic> roles;
  final VoidCallback onSubmitted;

  const _AddMemberSheet({
    required this.type,
    required this.roles,
    required this.onSubmitted,
  });

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String? _selectedRole;
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

    setState(() => _submitting = true);

    try {
      final endpoint = widget.type == 'waiter'
          ? 'team/waiter/create'
          : 'team/staff/add';

      await ApiService.instance.app.postData(
        endpoint,
        body: {
          'full_name': _nameCtrl.text.trim(),
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'role': _selectedRole ?? 'Staff',
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.type} added successfully')),
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
                Expanded(
                  child: Text(
                    'Add ${widget.type.capitalize()}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
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
            ),
            if (widget.type != 'waiter') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: widget.roles
                    .map((r) {
                      final name = r is String ? r : r['name']?.toString() ?? '';
                      return DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      );
                    })
                    .where((i) => i.value != null && i.value!.isNotEmpty)
                    .toList(),
                onChanged: (v) => setState(() => _selectedRole = v),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
