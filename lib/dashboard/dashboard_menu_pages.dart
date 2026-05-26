import 'package:flutter/material.dart';

import '../widgets/app_header.dart';
import '../business/manage_business_page.dart';

class DashboardMenuSimplePage extends StatelessWidget {
  const DashboardMenuSimplePage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppHeader(
        title: title,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        onMenuPressed: () => Navigator.of(context).maybePop(),
        showUserMenu: false,
        actions: actions,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
                      color: colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      size: 44,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Under Development',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This feature is being prepared for this app version.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RevenueExpensesProfitPage extends StatelessWidget {
  const RevenueExpensesProfitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardMenuSimplePage(
      title: 'Revenue, Expenses & Profit',
      subtitle: 'View P&L trends',
      icon: Icons.trending_up_rounded,
    );
  }
}

class AccountsCashflowPage extends StatelessWidget {
  const AccountsCashflowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardMenuSimplePage(
      title: 'Accounts & Cashflow',
      subtitle: 'Manage cash & accounts',
      icon: Icons.account_balance_wallet_outlined,
    );
  }
}

class FileCabinetPage extends StatelessWidget {
  const FileCabinetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardMenuSimplePage(
      title: 'File Cabinet',
      subtitle: 'Upload and manage files',
      icon: Icons.folder_open_rounded,
    );
  }
}

class SmsEmailsPage extends StatelessWidget {
  const SmsEmailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardMenuSimplePage(
      title: 'SMS & Emails',
      subtitle: 'Send SMS & Emails',
      icon: Icons.mark_email_read_outlined,
    );
  }
}

class ReportsHubPage extends StatelessWidget {
  const ReportsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardMenuSimplePage(
      title: 'Reports',
      subtitle: 'Custom analytics',
      icon: Icons.bar_chart_rounded,
    );
  }
}

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardMenuSimplePage(
      title: 'Subscribe',
      subtitle: 'Manage your subscription',
      icon: Icons.autorenew_rounded,
    );
  }
}

class AddTeamPage extends StatelessWidget {
  const AddTeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardMenuSimplePage(
      title: 'Add Team',
      subtitle: 'Hire, assign and manage',
      icon: Icons.people_outline,
    );
  }
}

class SettingsHubPage extends StatelessWidget {
  const SettingsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardMenuSimplePage(
      title: 'Settings',
      subtitle: 'Account settings & preferences',
      icon: Icons.settings,
    );
  }
}

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardMenuSimplePage(
      title: 'Recycle Bin',
      subtitle: 'Restore archived records',
      icon: Icons.delete_outline,
    );
  }
}

class AffiliateProgramPage extends StatelessWidget {
  const AffiliateProgramPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardMenuSimplePage(
      title: 'Affiliate Program',
      subtitle: 'Join reseller program',
      icon: Icons.group_work_outlined,
    );
  }
}

class AddBusinessPage extends StatelessWidget {
  const AddBusinessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardMenuSimplePage(
      title: 'Add Business',
      subtitle: 'Expand locations',
      icon: Icons.storefront_outlined,
      actions: [
        IconButton(
          tooltip: 'Add business',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageBusinessPage()),
            );
          },
          icon: const Icon(Icons.add_business_rounded),
        ),
      ],
    );
  }
}
