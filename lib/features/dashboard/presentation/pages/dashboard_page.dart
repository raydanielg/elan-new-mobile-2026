import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/api/api_client.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: IndexedStack(
        index: _currentTab,
        children: [
          const _HomeContent(),
          _PlaceholderContent(icon: LucideIcons.barChart2, label: 'Analytics'),
          _PlaceholderContent(icon: LucideIcons.creditCard, label: 'Payments'),
          _PlaceholderContent(icon: LucideIcons.arrowUpRight, label: 'Payouts'),
          _PlaceholderContent(icon: LucideIcons.settings, label: 'Settings'),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
      ),
    );
  }
}

// ─── Bottom Navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _labels = ['Home', 'Analytics', 'Payments', 'Payouts', 'Settings'];
  static const _icons = [
    LucideIcons.layoutGrid,
    LucideIcons.barChart2,
    LucideIcons.creditCard,
    LucideIcons.arrowUpRight,
    LucideIcons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.cardBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_labels.length, (i) {
          final active = currentIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icons[i], size: 22, color: active ? c.accent : c.textSecondary),
                  const SizedBox(height: 5),
                  Text(
                    _labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      height: 1,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? c.accent : c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Placeholder tabs ──────────────────────────────────────────────────────────

class _PlaceholderContent extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PlaceholderContent({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: c.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: c.cardBorder, width: 1.5),
              ),
              child: Icon(icon, size: 34, color: c.textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
            ),
            const SizedBox(height: 8),
            Text('Coming soon', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ─── Home Content ──────────────────────────────────────────────────────────────

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  bool _showBalance = false;
  bool _isLoading = true;
  List<dynamic>? _dashboardSummary;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // Validate token
      try {
        await ApiService.instance.fetchData('session_shop');
      } catch (e) {
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          if (kDebugMode) print('Token invalid — redirecting to login');
          await ApiClient.instance.clearToken();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
          return;
        }
      }

      // Resolve shop context
      String? shopId;
      try {
        final sessionShop = await ApiService.instance.fetchData('session_shop');
        if (sessionShop is Map) {
          shopId = sessionShop['shop_id']?.toString() ?? sessionShop['id']?.toString();
        }
      } catch (_) {
        try {
          final myShops = await ApiService.instance.fetchData('my_shops');
          if (myShops is List && myShops.isNotEmpty) {
            final first = myShops.first;
            if (first is Map) shopId = first['shop_id']?.toString() ?? first['id']?.toString();
          }
        } catch (_) {}
      }

      if (shopId != null) {
        try {
          final res = await ApiService.instance.switchShop(shopId);
          final tok = res['token']?.toString();
          if (tok != null && tok.isNotEmpty) await ApiClient.instance.saveToken(tok);
        } catch (_) {}
      }

      try {
        await ApiService.instance.setDateFilter(filter: 'reset');
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 500));

      final response = await ApiService.instance.fetchDashboardSummary();
      if (mounted) {
        setState(() {
          _dashboardSummary = response['result'] ?? response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _dashboardSummary = [];
        });
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          await ApiClient.instance.clearToken();
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildHeader(context),
            const SizedBox(height: 28),
            _buildBalanceCard(context),
            const SizedBox(height: 32),
            _buildQuickActions(context),
            const SizedBox(height: 32),
            _buildPaymentsSection(context),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Elan Ledgers',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
        ),
        Row(
          children: [
            // Dark ↔ Light mode animated toggle
            const _ThemeToggle(),
            const SizedBox(width: 10),
            const _CircleIconButton(icon: LucideIcons.bell, badge: 3),
            const SizedBox(width: 10),
            // User avatar
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.accent, width: 2),
                ),
                child: ClipOval(
                  child: Container(
                    width: 40,
                    height: 40,
                    color: c.cardBg,
                    child: Icon(LucideIcons.user, color: c.textSecondary, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.accent.withOpacity(isDark ? 0.12 : 0.06),
            blurRadius: 40,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Balance label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: c.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.wallet, color: c.accent, size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                'Balance',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Balance amount + eye toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 40),
              Flexible(
                child: _showBalance
                    ? Text(
                        'TZS 45,820,000',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          11,
                          (_) => Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            decoration: BoxDecoration(
                              color: c.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _showBalance = !_showBalance),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.cardBorder.withOpacity(isDark ? 0.5 : 0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _showBalance ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: c.textSecondary,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BalanceActionButton(icon: LucideIcons.plus, label: 'Add Money'),
              const SizedBox(width: 20),
              _BalanceActionButton(icon: LucideIcons.creditCard, label: 'Send'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final c = AppColors.of(context);
    const actions = [
      _QuickAction(LucideIcons.store, 'Profiles'),
      _QuickAction(LucideIcons.fileText, 'Pages'),
      _QuickAction(LucideIcons.externalLink, 'Links'),
      _QuickAction(LucideIcons.shoppingBag, 'Products'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) {
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: c.cardBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.cardBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(child: Icon(a.icon, color: c.accent, size: 22)),
              ),
              const SizedBox(height: 10),
              Text(
                a.label,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentsSection(BuildContext context) {
    final c = AppColors.of(context);

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: c.accent, strokeWidth: 2)),
      );
    }

    final summary = _dashboardSummary ?? [];

    // Empty state — no data yet
    if (summary.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
            decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.cardBorder, width: 1.5),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/onboarding/easy.svg',
                  height: 140,
                  fit: BoxFit.contain,
                  placeholderBuilder: (_) => SizedBox(
                    height: 140,
                    child: Center(
                      child: CircularProgressIndicator(color: c.accent, strokeWidth: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No payments yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your recent transactions will appear here',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Summary grid from API
    const iconMap = {
      'purchase': LucideIcons.shoppingCart,
      'cash_sales': LucideIcons.dollarSign,
      'credit_sales': LucideIcons.creditCard,
      'total_sales': LucideIcons.trendingUp,
      'profit': LucideIcons.pieChart,
      'orders': LucideIcons.package,
      'expense': LucideIcons.minusCircle,
      'currency': LucideIcons.globe,
      'from': LucideIcons.calendar,
      'to': LucideIcons.calendar,
      'filter_duration': LucideIcons.clock,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Summary',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: summary.length,
          itemBuilder: (context, index) {
            final item = summary[index] as Map<String, dynamic>;
            final key = item['key'] as String?;
            final label = item['label'] as String? ?? 'N/A';
            final value = item['value']?.toString() ?? '0';
            final isMain = item['main'] == true;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMain ? c.accent.withOpacity(0.1) : c.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMain ? c.accent : c.cardBorder,
                  width: isMain ? 2 : 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.accent.withOpacity(isMain ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconMap[key] ?? LucideIcons.barChart2,
                      color: c.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isMain ? c.accent : c.textPrimary,
                      fontSize: 14,
                      fontWeight: isMain ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: isMain ? c.accent : c.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Animated Dark / Light Toggle ─────────────────────────────────────────────

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (_, mode, __) {
        final isDark = mode == ThemeMode.dark;
        return GestureDetector(
          onTap: () {
            appThemeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            width: 54,
            height: 30,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  left: isDark ? 4.0 : 28.0,
                  top: 4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDark ? NeoColors.accentGreen : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? NeoColors.accentGreen.withOpacity(0.45)
                              : Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          isDark ? LucideIcons.moon : LucideIcons.sun,
                          key: ValueKey(isDark),
                          size: 11,
                          color: isDark ? Colors.white : NeoColors.accentGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Reusable Widgets ──────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final int badge;

  const _CircleIconButton({required this.icon, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.cardBg,
            shape: BoxShape.circle,
            border: Border.all(color: c.cardBorder, width: 1.5),
          ),
          child: Center(child: Icon(icon, color: c.textPrimary, size: 18)),
        ),
        if (badge > 0)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: c.accent,
                shape: BoxShape.circle,
                border: Border.all(color: c.background, width: 2),
              ),
              child: Center(
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BalanceActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BalanceActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF1C1C1E), Color(0xFF141416)]
                  : const [Color(0xFFF0F0F2), Color(0xFFE8E8EA)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: c.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: c.accent.withOpacity(isDark ? 0.2 : 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: Icon(icon, color: c.accent, size: 20)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  const _QuickAction(this.icon, this.label);
}
