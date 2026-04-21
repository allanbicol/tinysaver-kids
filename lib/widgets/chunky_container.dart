import 'package:flutter/material.dart';

/// Chunky 3D container — a solid card with a darker "shelf" underneath
/// instead of a shadow. Gives buttons and cards a stacked physical feel.
///
/// Use [ChunkyContainer] for static cards, [ChunkyButton] for interactive
/// elements with a press-down animation.
class ChunkyContainer extends StatelessWidget {
  /// Top face.
  final Widget child;

  /// The face color (solid) OR leave null and pass [gradient].
  final Color? color;
  final Gradient? gradient;

  /// Color of the shelf beneath the face. Defaults to a darkened [color].
  final Color? shelfColor;

  /// How tall the shelf appears in px.
  final double shelfHeight;

  /// Corner radius.
  final double radius;

  /// Padding applied inside the top face (around the child).
  final EdgeInsetsGeometry padding;

  /// Width/height constraints (optional).
  final double? width;
  final double? height;

  const ChunkyContainer({
    super.key,
    required this.child,
    this.color,
    this.gradient,
    this.shelfColor,
    this.shelfHeight = 6,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
    this.width,
    this.height,
  }) : assert(color != null || gradient != null,
          'Must provide either color or gradient');

  Color _resolveShelf() {
    if (shelfColor != null) return shelfColor!;
    if (color != null) return _darken(color!, 0.22);
    // Take last stop of gradient as base for shelf
    final g = gradient;
    if (g is LinearGradient) return _darken(g.colors.last, 0.22);
    return Colors.black;
  }

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    final dark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return dark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final shelf = _resolveShelf();

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: shelf,
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: EdgeInsets.only(bottom: shelfHeight),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            gradient: gradient,
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Pressable chunky button — animates down to meet the shelf on tap,
/// giving a tactile "click" feel.
class ChunkyButton extends StatefulWidget {
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final Color? shelfColor;
  final double shelfHeight;
  final double radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool disabled;

  const ChunkyButton({
    super.key,
    required this.child,
    this.color,
    this.gradient,
    this.shelfColor,
    this.shelfHeight = 6,
    this.radius = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.onTap,
    this.disabled = false,
  }) : assert(color != null || gradient != null,
          'Must provide either color or gradient');

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDown(_) {
    if (widget.disabled || widget.onTap == null) return;
    _ctrl.forward();
  }

  void _onUp(_) {
    if (widget.disabled || widget.onTap == null) return;
    _ctrl.reverse();
    widget.onTap?.call();
  }

  void _onCancel() {
    if (widget.disabled || widget.onTap == null) return;
    _ctrl.reverse();
  }

  Color _resolveShelf() {
    if (widget.shelfColor != null) return widget.shelfColor!;
    if (widget.color != null) return ChunkyContainer._darken(widget.color!, 0.22);
    final g = widget.gradient;
    if (g is LinearGradient) return ChunkyContainer._darken(g.colors.last, 0.22);
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final shelf = _resolveShelf();
    final opacity = widget.disabled ? 0.55 : 1.0;

    return GestureDetector(
      onTapDown: _onDown,
      onTapUp: _onUp,
      onTapCancel: _onCancel,
      child: Opacity(
        opacity: opacity,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            // During press: reduce bottom padding so the face slides down onto the shelf
            final pressedShelf = widget.shelfHeight * (1 - _ctrl.value);
            return Container(
              decoration: BoxDecoration(
                color: shelf,
                borderRadius: BorderRadius.circular(widget.radius),
              ),
              padding: EdgeInsets.only(bottom: pressedShelf),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.color,
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(widget.radius),
                ),
                padding: widget.padding,
                child: Center(
                  heightFactor: 1,
                  child: IgnorePointer(
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    // ignore: prefer_const_constructors
  }
}
