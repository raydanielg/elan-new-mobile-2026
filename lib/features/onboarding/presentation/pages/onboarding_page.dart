import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/neo_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  int _currentIndex = 0;
  final int _totalCards = 8;
  late AnimationController _arrowAnimationController;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _arrowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _arrowAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _arrowAnimationController, curve: Curves.easeInOut),
    );
    _arrowAnimationController.repeat(reverse: true);
    _startAutoScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    _arrowAnimationController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_scrollController.hasClients) {
        _currentIndex = (_currentIndex + 1) % _totalCards;
        _scrollToIndex(_currentIndex);
      }
    });
  }

  void _scrollToIndex(int index) {
    final cardWidth = 160.0;
    final padding = 16.0;
    final scrollPosition = index * (cardWidth + padding);
    
    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToNext() {
    _currentIndex = (_currentIndex + 1) % _totalCards;
    _scrollToIndex(_currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/onboarding/blue-colorful-curvy-geometric-lines-wave-pattern-texture-colorful-background_571748-525.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                NeoColors.background.withOpacity(0.95),
                NeoColors.background.withOpacity(0.97),
                NeoColors.background.withOpacity(0.98),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // Top-left Logo
                  Row(
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Image.asset(
                          'assets/onboarding/elanbrandslogo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              LucideIcons.wallet,
                              color: NeoColors.accentGreen,
                              size: 32,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Title
                  Text(
                    'Revolutionizing Ledgers.\nEnabling Growth.',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: NeoColors.textPrimary,
                          height: 1.25,
                          letterSpacing: -1.0,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'The most advanced digital ledger system for Tanzanian businesses – providing real-time cash flow tracking, sales automation, and deep financial analytics.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NeoColors.textSecondary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                  ),
                  const Spacer(),

                  // Horizontal Scrollable Feature Cards
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        final features = [
                          {
                            'icon': LucideIcons.trendingUp,
                            'title': 'Ledger Monitoring',
                            'description': 'Track real-time sales and daily transactions.',
                          },
                          {
                            'icon': LucideIcons.receipt,
                            'title': 'Instant Invoicing',
                            'description': 'Create and issue secure digital invoices.',
                          },
                          {
                            'icon': LucideIcons.package,
                            'title': 'Stock Management',
                            'description': 'Manage inventory and product tracking.',
                          },
                          {
                            'icon': LucideIcons.users,
                            'title': 'Customer Management',
                            'description': 'Organize customers and suppliers.',
                          },
                          {
                            'icon': LucideIcons.dollarSign,
                            'title': 'Cashflow Tracking',
                            'description': 'Monitor income and expenses.',
                          },
                          {
                            'icon': LucideIcons.barChart3,
                            'title': 'Reports & Analytics',
                            'description': 'Deep financial insights and reports.',
                          },
                          {
                            'icon': LucideIcons.shieldCheck,
                            'title': 'Team Management',
                            'description': 'Manage staff and permissions.',
                          },
                          {
                            'icon': LucideIcons.shield,
                            'title': 'Secure Cloud',
                            'description': 'Enterprise-grade data protection.',
                          },
                        ];
                        final feature = features[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == 7 ? 0 : 16,
                          ),
                          child: _buildFeatureCard(
                            context,
                            icon: feature['icon'] as IconData,
                            title: feature['title'] as String,
                            description: feature['description'] as String,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Get Started CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: NeoColors.accentGreen.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NeoColors.accentGreen,
                          foregroundColor: NeoColors.background,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Get Started',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            AnimatedBuilder(
                              animation: _arrowAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_arrowAnimation.value, 0),
                                  child: Icon(
                                    LucideIcons.arrowRight,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeoColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NeoColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: NeoColors.accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: NeoColors.accentGreen,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: NeoColors.textSecondary,
                    height: 1.3,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
