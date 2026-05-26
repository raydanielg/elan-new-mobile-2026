import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../widgets/app_header.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _settings;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await ApiService.instance.app.getData('shop_settings');
      
      if (raw is Map) {
        _settings = Map<String, dynamic>.from(raw);
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
        title: 'Settings',
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
        actions: [
          IconButton(
            onPressed: _fetchSettings,
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
      body: _buildBody(colorScheme),
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
                'Failed to load settings',
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
                onPressed: _fetchSettings,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSettings,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Shop Settings', Icons.store),
            const SizedBox(height: 12),
            _buildSettingsCard(colorScheme),
            const SizedBox(height: 24),
            _buildSectionTitle('Account Settings', Icons.person),
            const SizedBox(height: 12),
            _buildAccountCard(colorScheme),
            const SizedBox(height: 24),
            _buildSectionTitle('App Settings', Icons.phone_android),
            const SizedBox(height: 12),
            _buildAppCard(colorScheme),
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

  Widget _buildSettingsCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.store,
            label: 'Shop Name',
            value: _settings?['shop_name']?.toString() ?? 'N/A',
          ),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.phone,
            label: 'Phone',
            value: _settings?['shop_phone']?.toString() ?? 'N/A',
          ),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.email,
            label: 'Email',
            value: _settings?['shop_email']?.toString() ?? 'N/A',
          ),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.location_on,
            label: 'Address',
            value: _settings?['shop_address']?.toString() ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.person,
            label: 'Username',
            value: _settings?['username']?.toString() ?? 'N/A',
          ),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.badge,
            label: 'Role',
            value: _settings?['role']?.toString() ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.attach_money,
            label: 'Currency',
            value: _settings?['currency']?.toString() ?? 'TSh',
          ),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.language,
            label: 'Language',
            value: _settings?['language']?.toString() ?? 'English',
          ),
          const Divider(height: 24),
          _buildSettingItem(
            icon: Icons.date_range,
            label: 'Date Format',
            value: _settings?['date_format']?.toString() ?? 'DD-MM-YYYY',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
