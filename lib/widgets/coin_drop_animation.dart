import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated coin that drops from top of the screen and lands on a target
/// point (typically the mascot center). Pass [targetKey] to align with a
/// specific widget; falls back to 38% of screen height if unavailable.
class CoinDropOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final GlobalKey? targetKey;

  const CoinDropOverlay({super.key, required this.onComplete, this.targetKey});

  @override
  State<CoinDropOverlay> createState() => _CoinDropOverlayState();
}

class _CoinDropOverlayState extends State<CoinDropOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  Offset? _target;

  static const double _coinSize = 60;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Resolve the target once the first frame lands.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = widget.targetKey;
      if (key?.currentContext != null) {
        final box = key!.currentContext!.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final topLeft = box.localToGlobal(Offset.zero);
          setState(() {
            _target = Offset(
              topLeft.dx + box.size.width / 2,
              topLeft.dy + box.size.height / 2,
            );
          });
        }
      }
      if (mounted) _ctrl.forward().then((_) => widget.onComplete());
    });

    _progress = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 70),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 30,
      ),
    ]).animate(_ctrl);

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_ctrl);

    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 60),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Fallback target if no key or RO lookup failed: 38% down center.
    final target = _target ?? Offset(size.width / 2, size.height * 0.38);
    // Start 60px above the status-bar area.
    final startY = -_coinSize.toDouble();
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _progress.value;
        final x = target.dx - _coinSize / 2;
        final y = startY + (target.dy - _coinSize / 2 - startY) * t;
        return Positioned(
          top: y,
          left: x,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: const _CoinWidget(size: _coinSize),
            ),
          ),
        );
      },
    );
  }
}

class _CoinWidget extends StatelessWidget {
  final double size;
  const _CoinWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [Color(0xFFFFF176), AppColors.coinGold, AppColors.coinDark],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.coinDark.withValues(alpha: 0.5 * 255),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '🪙',
          style: TextStyle(fontSize: size * 0.55),
        ),
      ),
    );
  }
}

/// Floating +N coins text that rises and fades.
class FloatingCoinText extends StatefulWidget {
  final int amount;
  final Offset startPosition;
  final VoidCallback onComplete;

  const FloatingCoinText({
    super.key,
    required this.amount,
    required this.startPosition,
    required this.onComplete,
  });

  @override
  State<FloatingCoinText> createState() => _FloatingCoinTextState();
}

class _FloatingCoinTextState extends State<FloatingCoinText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _posY;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _posY = Tween(begin: 0.0, end: -80.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Positioned(
          left: widget.startPosition.dx - 30,
          top: widget.startPosition.dy + _posY.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Text(
              '+${widget.amount} 🪙',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF7A5C00),
                shadows: [
                  Shadow(color: Colors.white, blurRadius: 8),
                  Shadow(color: AppColors.coinGold, blurRadius: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Multi-coin burst when milestone hit.
class CoinBurst extends StatefulWidget {
  final Offset center;
  final VoidCallback onComplete;

  const CoinBurst({super.key, required this.center, required this.onComplete});

  @override
  State<CoinBurst> createState() => _CoinBurstState();
}

class _CoinBurstState extends State<CoinBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: List.generate(10, (i) {
            final angle = (i / 10) * 2 * pi + _rng.nextDouble() * 0.5;
            final distance = 60 + _rng.nextDouble() * 80;
            final progress = Curves.easeOut.transform(_ctrl.value);
            final x = widget.center.dx + cos(angle) * distance * progress;
            final y = widget.center.dy + sin(angle) * distance * progress
                + 40 * progress * progress; // gravity
            final opacity = (1 - _ctrl.value).clamp(0.0, 1.0);
            return Positioned(
              left: x - 16,
              top: y - 16,
              child: Opacity(
                opacity: opacity,
                child: const Text('🪙', style: TextStyle(fontSize: 22)),
              ),
            );
          }),
        );
      },
    );
  }
}
