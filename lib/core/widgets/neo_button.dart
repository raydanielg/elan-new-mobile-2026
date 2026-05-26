import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeoButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSecondary;
  final IconData? icon;
  final double? width;
  final double height;
  final bool showGlow;

  const NeoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSecondary = false,
    this.icon,
    this.width,
    this.height = 56,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (showGlow && !isSecondary)
            BoxShadow(
              color: NeoColors.accentGreen.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.transparent : NeoColors.accentGreen,
          foregroundColor: isSecondary ? NeoColors.textPrimary : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSecondary 
                ? const BorderSide(color: NeoColors.cardBorder, width: 1.5)
                : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: isSecondary ? NeoColors.textPrimary : Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSecondary ? NeoColors.textPrimary : Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
