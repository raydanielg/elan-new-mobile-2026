import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? borderColor;
  final bool showGlow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? NeoColors.cardBg,
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        border: Border.all(
          color: showGlow 
              ? NeoColors.accentGreen.withOpacity(0.3) 
              : (borderColor ?? NeoColors.cardBorder),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
