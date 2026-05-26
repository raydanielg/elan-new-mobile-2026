import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_service.dart';
import '../widgets/app_header.dart';

class AffiliateProgramPage extends StatefulWidget {
  const AffiliateProgramPage({super.key});

  @override
  State<AffiliateProgramPage> createState() => _AffiliateProgramPageState();
}

class _AffiliateProgramPageState extends State<AffiliateProgramPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;

  Map<String, dynamic> _summary = {};
  List<dynamic> _invitedShops = [];

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        ApiService.instance.app.getData('reseller_summary'),
        ApiService.instance.app.getData('reseller_invited_shops'),
      ]);

      if (!mounted) return;

      setState(() {
        _summary = _asMap(results[0]);
        _invitedShops = _asList(results[1]);
        _loading = false;
      });

      if (kDebugMode) {
        debugPrint('Affiliate: ${_invitedShops.length} invited shops');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
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
    if (v == null) return '0';
    if (v is num) return v.toStringAsFixed(0);
    return v.toString();
  }

  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final referralCode = _summary['referral_code']?.toString() ?? 'ELAN123';
    final totalEarnings = _summary['total_earnings'] ?? 0;
    final totalInvited = _summary['total_invited'] ?? _invitedShops.length;
    final pendingPayout = _summary['pending_payout'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: 'Affiliate Program',
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Hero Card with Stats
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
                        'Your Referral Code',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _copyReferralCode(referralCode),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                referralCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.copy, color: Colors.white70, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('Total Invited', _fmt(totalInvited)),
                          _buildDivider(),
                          _buildStat('Total Earnings', 'Tsh ${_fmt(totalEarnings)}'),
                          _buildDivider(),
                          _buildStat('Pending', 'Tsh ${_fmt(pendingPayout)}'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Tabs
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    indicatorColor: colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Invited Shops', icon: Icon(Icons.store)),
                      Tab(text: 'How It Works', icon: Icon(Icons.help_outline)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildInvitedShopsTab(),
                      _buildHowItWorksTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white24,
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInvitedShopsTab() {
    if (_invitedShops.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'No invited shops yet',
              style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Share your referral code to start earning',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _invitedShops.length,
      itemBuilder: (context, i) {
        final shop = _invitedShops[i];
        final name = shop['shop_name']?.toString() ??
            shop['name']?.toString() ??
            'Shop';
        final owner = shop['owner_name']?.toString() ?? '';
        final date = shop['joined_date']?.toString() ??
            shop['created_at']?.toString() ??
            '';
        final status = shop['status']?.toString() ?? 'active';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              child: const Icon(Icons.store, color: Colors.orange),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(owner.isNotEmpty ? 'Owner: $owner' : date),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'active'
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: status == 'active' ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHowItWorksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStepCard(
          '1',
          'Share Your Code',
          'Share your unique referral code with friends and business owners.',
          Icons.share,
        ),
        const SizedBox(height: 12),
        _buildStepCard(
          '2',
          'They Subscribe',
          'When someone signs up using your code and subscribes, you earn commission.',
          Icons.card_membership,
        ),
        const SizedBox(height: 12),
        _buildStepCard(
          '3',
          'You Earn',
          'Earn 10% commission on every subscription payment they make.',
          Icons.payments,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Pro Tip',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'The more shops you refer, the more you earn! There\'s no limit to how much you can make.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(String number, String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: const Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}
