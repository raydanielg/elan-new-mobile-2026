import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'onboarding_page_data.dart';

const Color _kMaroonPrimary = Color(0xFF800000);
const Color _kMaroonSecondary = Color(0xFFA52A2A);
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<OnboardingPageData> _pages = const [
    OnboardingPageData(
      assetPath: 'assets/onboarding/19197238.jpg',
      title: 'Simamia biashara kwa urahisi',
      description:
          'Mauzo, bidhaa na matumizi yako yawe sehemu moja ili kila siku ya kazi iwe nyepesi na yenye mpangilio.',
    ),
    OnboardingPageData(
      assetPath: 'assets/onboarding/2334.jpg',
      title: 'Taarifa zako ziko salama',
      description:
          'Fuatilia hesabu zako kwa utulivu ukijua taarifa muhimu zinalindwa na zinapatikana pale unapozihitaji.',
    ),
    OnboardingPageData(
      assetPath: 'assets/onboarding/Sandy_Ppl-02_Single-08.jpg',
      title: 'Anza haraka bila usumbufu',
      description:
          'Muonekano safi, hatua chache na matumizi mepesi vinakusaidia kuanza kazi mara moja.',
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_isLast) {
      widget.onFinished();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _finish() {
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/onboarding/elanbrandlogo.png',
                      height: 54,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Elan Ledgers',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _kMaroonPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) {
                    setState(() {
                      _index = i;
                    });
                  },
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _CenteredArtwork(assetPath: page.assetPath),
                          ),
                          const SizedBox(height: 28),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.08, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              key: ValueKey<int>(i),
                              children: [
                                Text(
                                  page.title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 320),
                                  child: Text(
                                    page.description,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: Colors.black54,
                                      height: 1.55,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Dots(
                        count: _pages.length,
                        index: _index,
                        selectedColor: _kMaroonPrimary,
                        unselectedColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  _NextButton(
                    isLast: _isLast,
                    onTap: _goNext,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredArtwork extends StatelessWidget {
  const _CenteredArtwork({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (assetPath.toLowerCase().endsWith('.svg')) {
      image = SvgPicture.asset(
        assetPath,
        fit: BoxFit.contain,
      );
    } else {
      image = Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 360,
          maxHeight: 320,
        ),
        child: image,
      ),
    );
  }
}

class _NextButton extends StatefulWidget {
  const _NextButton({
    required this.isLast,
    required this.onTap,
  });

  final bool isLast;
  final VoidCallback onTap;

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kMaroonPrimary, _kMaroonSecondary],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kMaroonPrimary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.isLast ? 'Start' : 'Next',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final dx = 4 * _controller.value;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.index,
    this.selectedColor,
    this.unselectedColor,
  });

  final int count;
  final int index;
  final Color? selectedColor;
  final Color? unselectedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = selectedColor ?? theme.colorScheme.primary;
    final unselected =
        unselectedColor ?? theme.colorScheme.primary.withValues(alpha: 0.25);

    return Row(
      children: List.generate(count, (i) {
        final isSelected = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 8),
          height: 8,
          width: isSelected ? 24 : 8,
          decoration: BoxDecoration(
            color: isSelected ? selected : unselected,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
