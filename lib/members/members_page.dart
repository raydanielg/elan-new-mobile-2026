import 'package:flutter/material.dart';
import '../widgets/app_header.dart';

import '../api/api_service.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  bool _loading = false;
  String? _error;

  _Member? _me;
  List<_Member> _members = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.instance.app.getData('session_user'),
        ApiService.instance.app.getData('team'),
      ]);

      final sessionUserRaw = results[0];
      final teamRaw = results[1];

      final me = _parseMe(sessionUserRaw);
      final team = _parseTeam(teamRaw);

      if (!mounted) return;
      setState(() {
        _me = me;
        _members = team;
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

  _Member? _parseMe(dynamic raw) {
    if (raw is! Map) return null;
    final data = (raw['data'] is Map) ? (raw['data'] as Map) : raw;

    final id = data['user_id']?.toString() ?? data['id']?.toString();
    final name = data['full_name']?.toString() ??
        data['name']?.toString() ??
        data['user_name']?.toString() ??
        data['username']?.toString();
    final email = data['email']?.toString() ??
        data['user_email']?.toString() ??
        data['username']?.toString();
    final role = data['role']?.toString() ?? data['user_role']?.toString() ?? 'Owner';

    final resolvedId = (id ?? '').trim();
    final resolvedName = (name ?? '').trim();
    final resolvedEmail = (email ?? '').trim();

    if (resolvedId.isEmpty && resolvedName.isEmpty && resolvedEmail.isEmpty) return null;
    return _Member(
      id: resolvedId,
      name: resolvedName,
      email: resolvedEmail,
      role: role.trim().isEmpty ? 'Owner' : role.trim(),
      isMe: true,
    );
  }

  List<_Member> _parseTeam(dynamic raw) {
    dynamic data = raw;
    if (raw is Map && raw['data'] != null) {
      data = raw['data'];
    }

    final out = <_Member>[];
    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final id = item['user_id']?.toString() ?? item['id']?.toString() ?? '';
        final name = item['full_name']?.toString() ??
            item['name']?.toString() ??
            item['user_name']?.toString() ??
            item['username']?.toString() ??
            '';
        final email = item['email']?.toString() ?? item['user_email']?.toString() ?? '';
        final role = item['role']?.toString() ??
            item['user_role']?.toString() ??
            item['position']?.toString() ??
            'Member';
        if (id.trim().isEmpty && name.trim().isEmpty && email.trim().isEmpty) continue;
        out.add(
          _Member(
            id: id.trim(),
            name: name.trim(),
            email: email.trim(),
            role: role.trim().isEmpty ? 'Member' : role.trim(),
            isMe: false,
          ),
        );
      }
    }

    return out;
  }

  void _openAddMember() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add member',
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
              child: _AddMemberPanel(
                onCreated: () async {
                  await _refresh();
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

    final all = <_Member>[
      if (_me != null) _me!,
      ..._members.where((m) => _me == null || m.id != _me!.id),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Members',
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
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
                            child: Icon(Icons.group_outlined, color: primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Members',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _loading ? '...' : all.length.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 74,
                    child: ElevatedButton.icon(
                      onPressed: _openAddMember,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text(
                        'Add',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_error != null)
                _ErrorCard(
                  message: _error!,
                  onRetry: _refresh,
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (all.isEmpty)
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
                          'No members found. Pull down to refresh.',
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
                    for (final m in all) ...[
                      _MemberCard(member: m),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Member {
  const _Member({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isMe,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool isMe;
}

enum _MemberType {
  waiter,
  staff,
  nonstaff,
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final _Member member;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final name = member.name.trim().isEmpty
        ? (member.email.trim().isEmpty ? 'Member' : member.email.trim())
        : member.name.trim();
    final initials = name.isEmpty ? 'M' : name.toUpperCase().substring(0, 1);

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.isMe ? '$name (You)' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        member.role,
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  member.email.isEmpty ? 'User ID: ${member.id}' : member.email,
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

class _AddMemberPanel extends StatefulWidget {
  const _AddMemberPanel({required this.onCreated});

  final Future<void> Function() onCreated;

  @override
  State<_AddMemberPanel> createState() => _AddMemberPanelState();
}

class _AddMemberPanelState extends State<_AddMemberPanel> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _role = 'Member';
  _MemberType _type = _MemberType.staff;
  bool _submitting = false;

  bool _permissionsLoading = false;
  String? _permissionsError;
  List<_PermissionItem> _permissions = const [];
  final Map<String, bool> _permissionValues = {};
  bool _isManager = false;

  List<String> _roles = const [];

  @override
  void initState() {
    super.initState();
    _fetchPermissions();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPermissions() async {
    setState(() {
      _permissionsLoading = true;
      _permissionsError = null;
    });

    try {
      final raw = await ApiService.instance.app.getData('permissions');
      final parsed = _parsePermissions(raw);
      final roles = _parseRoles(raw);

      if (!mounted) return;
      setState(() {
        _permissions = parsed;
        _roles = roles;
        for (final p in parsed) {
          _permissionValues.putIfAbsent(p.key, () => false);
        }
        _permissionsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _permissionsLoading = false;
        _permissionsError = e.toString();
      });
    }
  }

  List<_PermissionItem> _parsePermissions(dynamic raw) {
    dynamic data = raw;
    if (raw is Map && raw['data'] != null) {
      data = raw['data'];
    }

    final out = <_PermissionItem>[];

    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final key = item['col']?.toString() ??
            item['key']?.toString() ??
            item['permission']?.toString() ??
            '';
        final label = item['name']?.toString() ??
            item['label']?.toString() ??
            item['title']?.toString() ??
            key;
        final group = item['group']?.toString() ??
            item['category']?.toString() ??
            item['section']?.toString() ??
            'Other';
        if (key.trim().isEmpty) continue;
        out.add(_PermissionItem(key: key.trim(), label: label.trim(), group: group.trim()));
      }
    } else if (data is Map) {
      // If permissions are returned as a map like {"Sales": [{...}], "Stock": [{...}]}
      for (final entry in data.entries) {
        final group = entry.key.toString();
        final v = entry.value;
        if (v is List) {
          for (final item in v) {
            if (item is! Map) continue;
            final key = item['col']?.toString() ??
                item['key']?.toString() ??
                item['permission']?.toString() ??
                '';
            final label = item['name']?.toString() ??
                item['label']?.toString() ??
                item['title']?.toString() ??
                key;
            if (key.trim().isEmpty) continue;
            out.add(
              _PermissionItem(key: key.trim(), label: label.trim(), group: group.trim()),
            );
          }
        }
      }
    }

    out.sort((a, b) {
      final g = a.group.compareTo(b.group);
      if (g != 0) return g;
      return a.label.compareTo(b.label);
    });

    return out;
  }

  List<String> _parseRoles(dynamic raw) {
    if (raw is! Map) return const [];
    final data = (raw['data'] is Map) ? (raw['data'] as Map) : raw;

    dynamic rolesRaw = raw['roles'] ?? data['roles'] ?? data['role'] ?? data['role_list'];

    final out = <String>[];
    if (rolesRaw is List) {
      for (final r in rolesRaw) {
        if (r is Map) {
          final name = r['name']?.toString() ??
              r['role_name']?.toString() ??
              r['title']?.toString();
          final v = (name ?? '').trim();
          if (v.isNotEmpty) out.add(v);
        } else if (r != null) {
          final v = r.toString().trim();
          if (v.isNotEmpty) out.add(v);
        }
      }
    }

    if (out.isEmpty) {
      return const ['Admin', 'Member', 'Cashier', 'Owner', 'Waiter'];
    }

    if (!out.any((e) => e.toLowerCase() == 'waiter')) out.add('Waiter');
    return out.toSet().toList();
  }

  void _toggleManager(bool v) {
    setState(() {
      _isManager = v;
      for (final k in _permissionValues.keys) {
        _permissionValues[k] = v;
      }
    });
  }

  void _togglePermission(String key, bool v) {
    setState(() {
      _permissionValues[key] = v;
      if (!v) {
        _isManager = false;
      } else {
        final allOn = _permissionValues.values.every((x) => x == true);
        if (allOn) _isManager = true;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      final endpoint = switch (_type) {
        _MemberType.waiter => 'team/waiter/create',
        _MemberType.staff => 'team/staff/add',
        _MemberType.nonstaff => 'team/nonstaff/add',
      };

      final effectiveRole = _type == _MemberType.waiter ? 'Waiter' : _role;
      final payload = <String, dynamic>{
        'full_name': _nameCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'role': effectiveRole,
      };

      // Prefer JSON, fallback to form.
      Map<String, dynamic>? createdRaw;
      try {
        final created = await ApiService.instance.client.postJson(
          '/app/post/postdata/$endpoint',
          body: payload,
        );
        createdRaw = created.raw;
      } catch (_) {
        final created = await ApiService.instance.client.postForm(
          '/app/post/postdata/$endpoint',
          body: payload,
        );
        createdRaw = created.raw;
      }

      final roleId = _extractRoleId(createdRaw);

      if (roleId != null && _permissionValues.isNotEmpty) {
        for (final e in _permissionValues.entries) {
          final status = e.value ? 1 : 0;
          try {
            await ApiService.instance.client.postJson(
              '/app/post/postdata/team/permission/update',
              body: {
                'role_id': roleId,
                'col': e.key,
                'status': status,
              },
            );
          } catch (_) {
            await ApiService.instance.client.postForm(
              '/app/post/postdata/team/permission/update',
              body: {
                'role_id': roleId,
                'col': e.key,
                'status': status,
              },
            );
          }
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onCreated();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            roleId == null
                ? 'Member added. Permissions pending (role_id missing).'
                : 'Member added successfully',
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

  String? _extractRoleId(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    dynamic data = raw;
    if (raw['data'] is Map) data = raw['data'];
    if (data is Map) {
      final candidates = <dynamic>[
        data['role_id'],
        data['roleId'],
        data['role'],
        data['user_role_id'],
        raw['role_id'],
        raw['roleId'],
      ];
      for (final c in candidates) {
        final v = c?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
    }
    return null;
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
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add member',
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
                      Row(
                        children: [
                          Expanded(
                            child: _TypeChip(
                              label: 'Waiter',
                              selected: _type == _MemberType.waiter,
                              onTap: () => setState(() => _type = _MemberType.waiter),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TypeChip(
                              label: 'Staff',
                              selected: _type == _MemberType.staff,
                              onTap: () => setState(() => _type = _MemberType.staff),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TypeChip(
                              label: 'Non-staff',
                              selected: _type == _MemberType.nonstaff,
                              onTap: () => setState(() => _type = _MemberType.nonstaff),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Full name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Email is required';
                          if (!s.contains('@')) return 'Enter a valid email';
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
                      DropdownButtonFormField<String>(
                        value: _type == _MemberType.waiter ? 'Waiter' : _role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: (_roles.isEmpty
                                ? const ['Admin', 'Member', 'Cashier', 'Owner', 'Waiter']
                                : _roles)
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                        onChanged: _type == _MemberType.waiter
                            ? null
                            : (v) => setState(() => _role = v ?? 'Member'),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Set permissions',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                if (_permissionsLoading)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                if (!_permissionsLoading)
                                  IconButton(
                                    onPressed: _fetchPermissions,
                                    icon: const Icon(Icons.refresh),
                                    tooltip: 'Refresh permissions',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              value: _isManager,
                              onChanged: _toggleManager,
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Make This User Manager',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              subtitle: const Text(
                                'If enabled, all features will be enabled',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_permissionsError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _permissionsError!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            if (!_permissionsLoading && _permissions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'No permissions returned from API.',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (_permissions.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              for (final g in _groupedPermissions(_permissions).entries)
                                _PermissionGroup(
                                  title: g.key,
                                  items: g.value,
                                  values: _permissionValues,
                                  onChanged: _togglePermission,
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: primary),
                        onPressed: _submitting ? null : _submit,
                        child: Text(
                          _submitting ? 'Adding…' : 'Add member',
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

Map<String, List<_PermissionItem>> _groupedPermissions(List<_PermissionItem> items) {
  final m = <String, List<_PermissionItem>>{};
  for (final p in items) {
    m.putIfAbsent(p.group, () => []).add(p);
  }
  return m;
}

class _PermissionItem {
  const _PermissionItem({required this.key, required this.label, required this.group});

  final String key;
  final String label;
  final String group;
}

class _PermissionGroup extends StatelessWidget {
  const _PermissionGroup({
    required this.title,
    required this.items,
    required this.values,
    required this.onChanged,
  });

  final String title;
  final List<_PermissionItem> items;
  final Map<String, bool> values;
  final void Function(String key, bool v) onChanged;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
            fontSize: 13,
          ),
        ),
        children: [
          for (final p in items)
            SwitchListTile(
              value: values[p.key] ?? false,
              onChanged: (v) => onChanged(p.key, v),
              contentPadding: EdgeInsets.zero,
              title: Text(
                p.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = selected ? primary.withValues(alpha: 0.12) : const Color(0xFFF3F4F6);
    final border = selected ? primary.withValues(alpha: 0.35) : const Color(0xFFE5E7EB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? primary : const Color(0xFF111827),
            fontWeight: FontWeight.w900,
          ),
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
