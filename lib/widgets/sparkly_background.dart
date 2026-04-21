import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Radial gold-glow background with scattered sparkles.
/// Used by splash and auth screens.
class SparklyBackground extends StatelessWidget {
  final Widget child;

  const SparklyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            Color(0xFFFFF4C2),          // warm gold glow center
            AppColors.surfaceContainerLow,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Sparkles (same positions as splash so it feels continuous)
          const _Sparkle(top: 80,  left: 40,  size: 22),
          const _Sparkle(top: 120, right: 60, size: 16),
          const _Sparkle(top: 260, right: 30, size: 20),
          const _Sparkle(bottom: 220, left: 30, size: 18),
          const _Sparkle(bottom: 180, right: 80, size: 14),
          const _Sparkle(bottom: 120, left: 80, size: 20),
          child,
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double? top, bottom, left, right;
  final double size;
  const _Sparkle({this.top, this.bottom, this.left, this.right, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Icon(Icons.auto_awesome_rounded,
        color: AppColors.primary.withValues(alpha: 0.45 * 255), size: size),
    );
  }
}
