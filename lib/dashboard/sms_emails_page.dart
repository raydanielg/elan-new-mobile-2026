import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class SmsEmailsPage extends StatefulWidget {
  const SmsEmailsPage({super.key});

  @override
  State<SmsEmailsPage> createState() => _SmsEmailsPageState();
}

class _SmsEmailsPageState extends State<SmsEmailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  String? _error;

  List<dynamic> _contacts = [];
  List<dynamic> _categories = [];
  List<dynamic> _messageHistory = [];

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

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
        ApiService.instance.app.getData('contacts'),
        ApiService.instance.app.getData('contact_category'),
        ApiService.instance.app.getData('customer/message-history'),
      ]);

      if (!mounted) return;

      setState(() {
        _contacts = _asList(results[0]);
        _categories = _asList(results[1]);
        _messageHistory = _asList(results[2]);
        _loading = false;
      });

      if (kDebugMode) {
        debugPrint('Contacts: ${_contacts.length}, Categories: ${_categories.length}');
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

  void _showSendMessageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SendMessageSheet(
        contacts: _contacts,
        categories: _categories,
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
        title: 'SMS & Emails',
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
                Tab(text: 'Contacts', icon: Icon(Icons.contacts)),
                Tab(text: 'Categories', icon: Icon(Icons.folder)),
                Tab(text: 'History', icon: Icon(Icons.history)),
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
                          _buildContactsTab(),
                          _buildCategoriesTab(),
                          _buildHistoryTab(),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendMessageSheet,
        icon: const Icon(Icons.send),
        label: const Text('Send Message'),
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

  Widget _buildContactsTab() {
    if (_contacts.isEmpty) {
      return const Center(
        child: Text(
          'No contacts found',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contacts.length,
      itemBuilder: (context, i) {
        final c = _contacts[i];
        final name = c['full_name']?.toString() ??
            c['name']?.toString() ??
            'Contact';
        final phone = c['phone']?.toString() ?? '';
        final email = c['email']?.toString() ?? '';
        final category = c['category_name']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(phone.isNotEmpty ? phone : email),
            trailing: category.isNotEmpty
                ? Chip(
                    label: Text(category),
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    if (_categories.isEmpty) {
      return const Center(
        child: Text(
          'No categories found',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        final c = _categories[i];
        final name = c['name']?.toString() ?? 'Category';
        final count = c['contact_count'] ?? c['count'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: const Icon(Icons.folder, color: Colors.orange),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_messageHistory.isEmpty) {
      return const Center(
        child: Text(
          'No message history',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messageHistory.length,
      itemBuilder: (context, i) {
        final h = _messageHistory[i];
        final message = h['message']?.toString() ?? '';
        final type = h['type']?.toString() ?? 'SMS';
        final date = h['sent_date']?.toString() ?? h['created_at']?.toString() ?? '';
        final status = h['status']?.toString() ?? 'sent';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: type == 'email'
                  ? Colors.purple.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              child: Icon(
                type == 'email' ? Icons.email : Icons.sms,
                color: type == 'email' ? Colors.purple : Colors.green,
              ),
            ),
            title: Text(
              message.length > 50 ? '${message.substring(0, 50)}...' : message,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(date),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'sent'
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: status == 'sent' ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SendMessageSheet extends StatefulWidget {
  final List<dynamic> contacts;
  final List<dynamic> categories;
  final VoidCallback onSubmitted;

  const _SendMessageSheet({
    required this.contacts,
    required this.categories,
    required this.onSubmitted,
  });

  @override
  State<_SendMessageSheet> createState() => _SendMessageSheetState();
}

class _SendMessageSheetState extends State<_SendMessageSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  String _type = 'SMS';
  List<String> _selectedContacts = [];
  bool _submitting = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      await ApiService.instance.app.postData(
        'customer/campaign/send',
        body: {
          'type': _type.toLowerCase(),
          'recipients': _selectedContacts,
          'subject': _type == 'Email' ? _subjectCtrl.text.trim() : null,
          'message': _messageCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully')),
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
                    'Send Campaign',
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
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'SMS', label: Text('SMS')),
                ButtonSegment(value: 'Email', label: Text('Email')),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
            const SizedBox(height: 16),
            if (_type == 'Email')
              TextFormField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
            if (_type == 'Email') const SizedBox(height: 12),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Recipients:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.contacts.map((c) {
                final name = c['full_name']?.toString() ??
                    c['name']?.toString() ??
                    'Contact';
                final id = c['id']?.toString() ?? c['contact_id']?.toString() ?? '';
                final isSelected = _selectedContacts.contains(id);

                return FilterChip(
                  label: Text(name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedContacts.add(id);
                      } else {
                        _selectedContacts.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
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
                  : Text('Send $_type'),
            ),
          ],
        ),
      ),
    );
  }
}
