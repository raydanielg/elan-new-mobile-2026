import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class SettingsHubPage extends StatefulWidget {
  const SettingsHubPage({super.key});

  @override
  State<SettingsHubPage> createState() => _SettingsHubPageState();
}

class _SettingsHubPageState extends State<SettingsHubPage> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _shopSettings = {};
  Map<String, dynamic> _userProfile = {};

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.instance.app.getData('shop_settings'),
        ApiService.instance.app.getData('session_user'),
      ]);

      if (!mounted) return;

      setState(() {
        _shopSettings = _asMap(results[0]);
        _userProfile = _asMap(results[1]);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  final List<_SettingsSection> _settingsSections = [
    _SettingsSection(
      'Shop Settings',
      Icons.store,
      [
        _SettingsItem('Business Info', Icons.business, 'edit_business'),
        _SettingsItem('Shop Profile', Icons.storefront, 'shop_profile'),
        _SettingsItem('Tax Settings', Icons.account_balance, 'tax_settings'),
        _SettingsItem('Currency', Icons.attach_money, 'currency'),
        _SettingsItem('Receipt Template', Icons.receipt, 'receipt_template'),
      ],
    ),
    _SettingsSection(
      'User & Security',
      Icons.security,
      [
        _SettingsItem('Profile', Icons.person, 'profile'),
        _SettingsItem('Change Password', Icons.lock, 'password'),
        _SettingsItem('Notifications', Icons.notifications, 'notifications'),
        _SettingsItem('Biometric Login', Icons.fingerprint, 'biometric'),
      ],
    ),
    _SettingsSection(
      'System',
      Icons.settings_applications,
      [
        _SettingsItem('Language', Icons.language, 'language'),
        _SettingsItem('Theme', Icons.color_lens, 'theme'),
        _SettingsItem('Backup', Icons.backup, 'backup'),
        _SettingsItem('About', Icons.info, 'about'),
      ],
    ),
  ];

  void _handleSettingTap(String key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$key settings coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Settings',
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _settingsSections.length,
              itemBuilder: (context, i) => _buildSection(_settingsSections[i]),
            ),
    );
  }

  Widget _buildSection(_SettingsSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(section.icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  section.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
            itemBuilder: (context, i) {
              final item = section.items[i];
              return ListTile(
                leading: Icon(item.icon, color: const Color(0xFF6B7280)),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _handleSettingTap(item.key),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsSection {
  final String title;
  final IconData icon;
  final List<_SettingsItem> items;

  _SettingsSection(this.title, this.icon, this.items);
}

class _SettingsItem {
  final String title;
  final IconData icon;
  final String key;

  _SettingsItem(this.title, this.icon, this.key);
}
