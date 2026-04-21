import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Speech bubble that types out text character-by-character, stays for a
/// moment, then fades away. Designed to sit above the mascot's head.
///
/// Give each unique greeting a distinct [key] (e.g. `ValueKey(message)`) so
/// the widget re-animates when the message changes.
class SpeechBubble extends StatefulWidget {
  final String message;
  final VoidCallback? onDone;
  final Duration lifetime;

  const SpeechBubble({
    super.key,
    required this.message,
    this.onDone,
    this.lifetime = const Duration(milliseconds: 3800),
  });

  @override
  State<SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<SpeechBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<int> _chars;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.lifetime);

    // Entry: scale up with a little bounce (0.0 → 0.20 of timeline).
    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 18,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 7),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 15),
    ]).animate(_ctrl);

    // Fade: in fast, out slower.
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
    ]).animate(_ctrl);

    // Typewriter: reveal characters over first ~35% of lifetime.
    _chars = StepTween(begin: 0, end: widget.message.length).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.05, 0.40, curve: Curves.linear),
      ),
    );

    _ctrl.forward().whenComplete(() {
      if (mounted) widget.onDone?.call();
    });
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
        final shown = widget.message.substring(
          0, _chars.value.clamp(0, widget.message.length));
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            alignment: Alignment.bottomCenter,
            scale: _scale.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.10 * 255),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    shown,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                // Little tail pointing down to mascot.
                CustomPaint(
                  size: const Size(18, 10),
                  painter: _BubbleTailPainter(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) => false;
}
