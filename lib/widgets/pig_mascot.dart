import 'dart:math';
import 'package:flutter/material.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../models/accessory.dart';

/// Fully programmatic pig mascot drawn with CustomPainter.
/// No external assets required.
class PigMascot extends StatefulWidget {
  final PigState pigState;
  final PigLevel level;
  final String? accessoryId;    // optional shop accessory worn on top of level
  final MascotKind kind;        // pig, bunny, or bear
  final double size;

  const PigMascot({
    super.key,
    required this.pigState,
    this.level = PigLevel.happy,
    this.accessoryId,
    this.kind = MascotKind.pig,
    this.size = 200,
  });

  @override
  State<PigMascot> createState() => _PigMascotState();
}

class _PigMascotState extends State<PigMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -18.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -18.0, end: 4.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotateAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(PigMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pigState != widget.pigState) {
      _playAnimation();
    }
  }

  void _playAnimation() {
    if (widget.pigState == PigState.happy ||
        widget.pigState == PigState.excited) {
      _controller.reset();
      if (widget.pigState == PigState.excited) {
        _controller.repeat(count: 3);
      } else {
        _controller.forward();
      }
    } else {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnim.value),
          child: Transform.rotate(
            angle: _rotateAnim.value,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _PigPainter(
                state: widget.pigState,
                level: widget.level,
                accessory: accessoryById(widget.accessoryId),
                kind: widget.kind,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PigPainter extends CustomPainter {
  final PigState state;
  final PigLevel level;
  final Accessory? accessory;
  final MascotKind kind;
  _PigPainter({
    required this.state,
    required this.level,
    this.accessory,
    this.kind = MascotKind.pig,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.42;

    // ── Shadow ──────────────────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = Colors.black12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.85), width: r * 1.6, height: r * 0.4),
      shadowPaint,
    );

    // ── Body ─────────────────────────────────────────────────────────────────
    final bodyColor = _bodyColor();
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawCircle(Offset(cx, cy), r, bodyPaint);

    // Body highlight
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.7,
        colors: [Colors.white54, Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, highlightPaint);

    // ── Ears (shape differs by mascot) ────────────────────────────────────────
    _drawEars(canvas, cx, cy, r, bodyColor);

    // ── Snout / muzzle (pig has oval; bear has round muzzle; bunny has small) ─
    final snoutColor = Color.lerp(bodyColor, Colors.white, 0.25)!;
    final snoutPaint = Paint()..color = snoutColor;
    final double snoutRx, snoutRy;
    switch (kind) {
      case MascotKind.pig:
        snoutRx = r * 0.42; snoutRy = r * 0.28;
      case MascotKind.bear:
      case MascotKind.panda:
        snoutRx = r * 0.45; snoutRy = r * 0.32;
      case MascotKind.bunny:
        snoutRx = r * 0.32; snoutRy = r * 0.22;
      case MascotKind.cat:
        snoutRx = r * 0.30; snoutRy = r * 0.18;
      case MascotKind.fox:
        snoutRx = r * 0.38; snoutRy = r * 0.24;
      case MascotKind.unicorn:
        snoutRx = r * 0.34; snoutRy = r * 0.22;
      case MascotKind.robot:
        snoutRx = 0; snoutRy = 0;   // no snout — draw a grille instead below
      case MascotKind.plant:
        snoutRx = r * 0.28; snoutRy = r * 0.18;
      case MascotKind.birdie:
        snoutRx = 0; snoutRy = 0;   // beak only, no round muzzle
    }
    final snoutY = cy + r * 0.25;
    if (snoutRx > 0 && snoutRy > 0) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, snoutY), width: snoutRx * 2, height: snoutRy * 2),
        snoutPaint,
      );
    }

    // Nose/nostrils differ by kind
    if (kind == MascotKind.pig) {
      final nostrilPaint = Paint()..color = _nostrilColor();
      canvas.drawCircle(Offset(cx - snoutRx * 0.38, snoutY), r * 0.065, nostrilPaint);
      canvas.drawCircle(Offset(cx + snoutRx * 0.38, snoutY), r * 0.065, nostrilPaint);
    } else if (kind == MascotKind.robot) {
      // Robot "speaker grille" — 3 small dark ovals
      final grille = Paint()..color = const Color(0xFF3D4C5C);
      for (int i = -1; i <= 1; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx + i * r * 0.15, snoutY),
            width: r * 0.1, height: r * 0.04),
          grille,
        );
      }
    } else if (kind == MascotKind.birdie) {
      // Orange triangle beak pointing down
      final beakPaint = Paint()..color = const Color(0xFFFF9A3C);
      final beakPath = Path()
        ..moveTo(cx - r * 0.14, snoutY - r * 0.1)
        ..lineTo(cx + r * 0.14, snoutY - r * 0.1)
        ..lineTo(cx, snoutY + r * 0.18)
        ..close();
      canvas.drawPath(beakPath, beakPaint);
      // Inner darker triangle for 3D look
      canvas.drawLine(
        Offset(cx, snoutY - r * 0.08),
        Offset(cx, snoutY + r * 0.15),
        Paint()
          ..color = const Color(0xFFC4761E)
          ..strokeWidth = r * 0.015,
      );
    } else {
      // Small triangle nose (bunny/bear/cat/fox/unicorn/plant)
      final nosePaint = Paint()..color = kind == MascotKind.bunny
          ? const Color(0xFFFF85A1)
          : const Color(0xFF3D2817);
      final noseY = snoutY - r * 0.08;
      final path = Path()
        ..moveTo(cx - r * 0.08, noseY)
        ..lineTo(cx + r * 0.08, noseY)
        ..lineTo(cx, noseY + r * 0.08)
        ..close();
      canvas.drawPath(path, nosePaint);
      // Whiskers for bunny, cat and fox
      if (kind == MascotKind.bunny ||
          kind == MascotKind.cat ||
          kind == MascotKind.fox) {
        final whiskerPaint = Paint()
          ..color = const Color(0xFF888888)
          ..strokeWidth = r * 0.012;
        for (int i = -1; i <= 1; i += 2) {
          for (int j = -1; j <= 1; j++) {
            canvas.drawLine(
              Offset(cx + i * r * 0.12, snoutY + j * r * 0.04),
              Offset(cx + i * r * 0.42, snoutY + j * r * 0.08),
              whiskerPaint,
            );
          }
        }
      }
    }

    // ── Panda eye patches (before eyes so eyes sit on top) ────────────────────
    if (kind == MascotKind.panda) {
      final patchPaint = Paint()..color = const Color(0xFF2D2D2D);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx - r * 0.3, cy - r * 0.08),
          width: r * 0.38, height: r * 0.4),
        patchPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + r * 0.3, cy - r * 0.08),
          width: r * 0.38, height: r * 0.4),
        patchPaint,
      );
    }

    // ── Unicorn horn ──────────────────────────────────────────────────────────
    if (kind == MascotKind.unicorn) {
      final hornPaint = Paint()..color = AppColors.primary;
      final hornDark = Paint()..color = AppColors.primaryDark;
      final hornPath = Path()
        ..moveTo(cx - r * 0.12, cy - r * 0.7)
        ..lineTo(cx + r * 0.12, cy - r * 0.7)
        ..lineTo(cx, cy - r * 1.25)
        ..close();
      canvas.drawPath(hornPath, hornPaint);
      // Spiral accent lines
      final linePaint = Paint()
        ..color = hornDark.color.withValues(alpha: 0.7 * 255)
        ..strokeWidth = r * 0.018
        ..style = PaintingStyle.stroke;
      for (int i = 0; i < 3; i++) {
        final y = cy - r * 0.78 - i * r * 0.13;
        final w = r * 0.1 - i * r * 0.03;
        canvas.drawLine(
          Offset(cx - w, y),
          Offset(cx + w, y + r * 0.04),
          linePaint,
        );
      }
    }

    // ── Eyes ──────────────────────────────────────────────────────────────────
    _drawEye(canvas, Offset(cx - r * 0.3, cy - r * 0.08), r, state);
    _drawEye(canvas, Offset(cx + r * 0.3, cy - r * 0.08), r, state);

    // ── Mouth ─────────────────────────────────────────────────────────────────
    _drawMouth(canvas, Offset(cx, snoutY - r * 0.04), r, state);

    // ── Cheeks (blush) ────────────────────────────────────────────────────────
    if (state == PigState.happy || state == PigState.excited) {
      final blushPaint = Paint()..color = AppColors.pigBlush.withValues(alpha: 0.28 * 255);
      canvas.drawCircle(Offset(cx - r * 0.62, cy + r * 0.08), r * 0.22, blushPaint);
      canvas.drawCircle(Offset(cx + r * 0.62, cy + r * 0.08), r * 0.22, blushPaint);
    }

    // ── Stars / sparkles for excited ──────────────────────────────────────────
    if (state == PigState.excited) {
      _drawSparkle(canvas, Offset(cx - r * 0.85, cy - r * 0.55), r * 0.12, AppColors.primary);
      _drawSparkle(canvas, Offset(cx + r * 0.9, cy - r * 0.6), r * 0.1, AppColors.secondary);
      _drawSparkle(canvas, Offset(cx, cy - r * 1.05), r * 0.09, AppColors.pigBlush);
    }

    // ── Tear drop for sad ─────────────────────────────────────────────────────
    if (state == PigState.sad) {
      final tearPaint = Paint()..color = AppColors.secondaryDark.withValues(alpha: 0.7 * 255);
      canvas.drawCircle(Offset(cx - r * 0.22, cy + r * 0.28), r * 0.065, tearPaint);
      canvas.drawCircle(Offset(cx + r * 0.22, cy + r * 0.28), r * 0.065, tearPaint);
    }

    // ── Level-based accessories ───────────────────────────────────────────────
    switch (level) {
      case PigLevel.baby:
        _drawBabyAccessories(canvas, cx, cy, r);
      case PigLevel.happy:
        _drawHappyAccessories(canvas, cx, cy, r);
      case PigLevel.rich:
        _drawRichAccessories(canvas, cx, cy, r);
    }

    // ── Shop accessory (on top of everything) ───────────────────────────────
    if (accessory != null) {
      _drawShopAccessory(canvas, cx, cy, r, accessory!);
    }
  }

  // ── Shop accessory drawing ────────────────────────────────────────────────
  void _drawShopAccessory(Canvas canvas, double cx, double cy, double r, Accessory a) {
    switch (a.kind) {
      case AccessoryKind.partyHat:
        _drawPartyHat(canvas, cx, cy, r, a.primaryColor);
      case AccessoryKind.wizardHat:
        _drawWizardHat(canvas, cx, cy, r, a.primaryColor);
      case AccessoryKind.sunglasses:
        _drawSunglasses(canvas, cx, cy, r, a.primaryColor);
      case AccessoryKind.bowTie:
        _drawShopBowTie(canvas, cx, cy, r, a.primaryColor);
      case AccessoryKind.headband:
        _drawHeadband(canvas, cx, cy, r, a.primaryColor);
    }
  }

  void _drawPartyHat(Canvas canvas, double cx, double cy, double r, Color color) {
    final tipY = cy - r * 1.55;
    final baseL = Offset(cx - r * 0.32, cy - r * 0.7);
    final baseR = Offset(cx + r * 0.32, cy - r * 0.7);
    final path = Path()
      ..moveTo(cx, tipY)
      ..lineTo(baseR.dx, baseR.dy)
      ..lineTo(baseL.dx, baseL.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    // Zigzag stripe
    final stripePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = r * 0.04
      ..style = PaintingStyle.stroke;
    final stripe = Path()
      ..moveTo(cx - r * 0.2, cy - r * 0.95)
      ..lineTo(cx - r * 0.1, cy - r * 1.05)
      ..lineTo(cx, cy - r * 0.95)
      ..lineTo(cx + r * 0.1, cy - r * 1.05)
      ..lineTo(cx + r * 0.2, cy - r * 0.95);
    canvas.drawPath(stripe, stripePaint);
    // Pom-pom on top
    canvas.drawCircle(Offset(cx, tipY - r * 0.06), r * 0.11,
      Paint()..color = Colors.white);
  }

  void _drawWizardHat(Canvas canvas, double cx, double cy, double r, Color color) {
    // Wide brim
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy - r * 0.65), width: r * 2.1, height: r * 0.3),
      Paint()..color = color,
    );
    // Cone (tilted)
    final path = Path()
      ..moveTo(cx + r * 0.4, cy - r * 1.7)    // tip tilted right
      ..lineTo(cx - r * 0.45, cy - r * 0.68)
      ..lineTo(cx + r * 0.45, cy - r * 0.68)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    // Gold star
    _drawStar(canvas, Offset(cx, cy - r * 1.1), r * 0.1, AppColors.primary);
  }

  void _drawSunglasses(Canvas canvas, double cx, double cy, double r, Color color) {
    final paint = Paint()..color = color;
    final y = cy - r * 0.08;
    final lens = r * 0.2;
    final roundL = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - r * 0.3, y), width: lens * 2, height: lens * 1.7),
      Radius.circular(r * 0.08));
    final roundR = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + r * 0.3, y), width: lens * 2, height: lens * 1.7),
      Radius.circular(r * 0.08));
    canvas.drawRRect(roundL, paint);
    canvas.drawRRect(roundR, paint);
    // Bridge
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, y), width: r * 0.2, height: r * 0.04),
      paint,
    );
    // Glare
    canvas.drawCircle(Offset(cx - r * 0.38, y - r * 0.05), r * 0.04,
      Paint()..color = Colors.white.withValues(alpha: 0.7 * 255));
    canvas.drawCircle(Offset(cx + r * 0.22, y - r * 0.05), r * 0.04,
      Paint()..color = Colors.white.withValues(alpha: 0.7 * 255));
  }

  void _drawShopBowTie(Canvas canvas, double cx, double cy, double r, Color color) {
    final y = cy + r * 0.95;
    final paint = Paint()..color = color;
    final leftBow = Path()
      ..moveTo(cx, y)
      ..lineTo(cx - r * 0.32, y - r * 0.18)
      ..lineTo(cx - r * 0.32, y + r * 0.18)
      ..close();
    final rightBow = Path()
      ..moveTo(cx, y)
      ..lineTo(cx + r * 0.32, y - r * 0.18)
      ..lineTo(cx + r * 0.32, y + r * 0.18)
      ..close();
    canvas.drawPath(leftBow, paint);
    canvas.drawPath(rightBow, paint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, y), width: r * 0.14, height: r * 0.22),
      paint,
    );
    // White dot polka
    canvas.drawCircle(Offset(cx - r * 0.2, y), r * 0.03,
      Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + r * 0.2, y), r * 0.03,
      Paint()..color = Colors.white);
  }

  void _drawHeadband(Canvas canvas, double cx, double cy, double r, Color color) {
    // Band across forehead
    final band = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - r * 0.55),
        width: r * 1.8, height: r * 0.22),
      Radius.circular(r * 0.12),
    );
    canvas.drawRRect(band, Paint()..color = color);
    // Stripe detail
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy - r * 0.55),
        width: r * 1.8, height: r * 0.06),
      Paint()..color = Colors.white,
    );
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 4 * pi / 5) - pi / 2;
      final x = center.dx + radius * cos(outerAngle);
      final y = center.dy + radius * sin(outerAngle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  // ── Baby: pacifier + bonnet/cap ─────────────────────────────────────────────
  void _drawBabyAccessories(Canvas canvas, double cx, double cy, double r) {
    // Soft blue bonnet on top of head
    final bonnetColor = AppColors.secondary;
    final bonnetPaint = Paint()..color = bonnetColor;
    final bonnetPath = Path()
      ..moveTo(cx - r * 0.95, cy - r * 0.55)
      ..quadraticBezierTo(cx, cy - r * 1.55, cx + r * 0.95, cy - r * 0.55)
      ..lineTo(cx + r * 0.8, cy - r * 0.5)
      ..quadraticBezierTo(cx, cy - r * 1.3, cx - r * 0.8, cy - r * 0.5)
      ..close();
    canvas.drawPath(bonnetPath, bonnetPaint);

    // Pom-pom on top of bonnet
    canvas.drawCircle(
      Offset(cx, cy - r * 1.18),
      r * 0.14,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx, cy - r * 1.18),
      r * 0.08,
      Paint()..color = AppColors.secondaryContainer,
    );

    // Small pacifier below mouth (only on normal / happy)
    if (state == PigState.normal || state == PigState.happy) {
      final paciCenter = Offset(cx, cy + r * 0.63);
      canvas.drawCircle(paciCenter, r * 0.09,
        Paint()..color = AppColors.tertiaryContainer);
      canvas.drawCircle(paciCenter, r * 0.05,
        Paint()..color = AppColors.tertiaryDark);
    }
  }

  // ── Happy: confident bowtie ────────────────────────────────────────────────
  void _drawHappyAccessories(Canvas canvas, double cx, double cy, double r) {
    // Yellow flower on ear
    final flowerCenter = Offset(cx - r * 0.8, cy - r * 0.9);
    final petalPaint = Paint()..color = AppColors.primary;
    for (int i = 0; i < 5; i++) {
      final angle = (i / 5) * 2 * pi;
      canvas.drawCircle(
        Offset(flowerCenter.dx + cos(angle) * r * 0.08,
               flowerCenter.dy + sin(angle) * r * 0.08),
        r * 0.08,
        petalPaint,
      );
    }
    canvas.drawCircle(flowerCenter, r * 0.06,
      Paint()..color = AppColors.primaryDark);
  }

  // ── Rich: crown + bowtie + monocle ──────────────────────────────────────────
  void _drawRichAccessories(Canvas canvas, double cx, double cy, double r) {
    // Crown on top of head
    final crownGold = AppColors.primary;
    final crownDark = AppColors.primaryDark;
    final crownBase = cy - r * 0.95;
    final crownHeight = r * 0.38;
    final crownWidth = r * 1.2;

    final crownPath = Path()
      ..moveTo(cx - crownWidth / 2, crownBase)
      ..lineTo(cx - crownWidth / 2, crownBase - crownHeight * 0.3)
      // 3 triangular peaks
      ..lineTo(cx - crownWidth * 0.32, crownBase - crownHeight)
      ..lineTo(cx - crownWidth * 0.18, crownBase - crownHeight * 0.45)
      ..lineTo(cx, crownBase - crownHeight * 1.1)
      ..lineTo(cx + crownWidth * 0.18, crownBase - crownHeight * 0.45)
      ..lineTo(cx + crownWidth * 0.32, crownBase - crownHeight)
      ..lineTo(cx + crownWidth / 2, crownBase - crownHeight * 0.3)
      ..lineTo(cx + crownWidth / 2, crownBase)
      ..close();

    // Crown body with gradient-like fill
    canvas.drawPath(crownPath,
      Paint()..color = crownGold);
    // Crown outline
    canvas.drawPath(crownPath,
      Paint()
        ..color = crownDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.03);

    // Jewels on the crown (3 red/pink dots)
    canvas.drawCircle(Offset(cx, crownBase - crownHeight * 0.25),
      r * 0.07, Paint()..color = AppColors.tertiaryDark);
    canvas.drawCircle(Offset(cx - crownWidth * 0.28, crownBase - crownHeight * 0.15),
      r * 0.05, Paint()..color = AppColors.secondaryDark);
    canvas.drawCircle(Offset(cx + crownWidth * 0.28, crownBase - crownHeight * 0.15),
      r * 0.05, Paint()..color = AppColors.secondaryDark);

    // Crown highlight/shine dot
    canvas.drawCircle(Offset(cx - crownWidth * 0.1, crownBase - crownHeight * 0.5),
      r * 0.04, Paint()..color = Colors.white.withValues(alpha: 0.7 * 255));

    // ── Bowtie below chin ─────────────────────────────────────────────────────
    final bowY = cy + r * 0.95;
    final bowColor = AppColors.tertiaryDark;
    final bowPaint = Paint()..color = bowColor;

    // Left triangle
    final leftBow = Path()
      ..moveTo(cx, bowY)
      ..lineTo(cx - r * 0.28, bowY - r * 0.16)
      ..lineTo(cx - r * 0.28, bowY + r * 0.16)
      ..close();
    // Right triangle
    final rightBow = Path()
      ..moveTo(cx, bowY)
      ..lineTo(cx + r * 0.28, bowY - r * 0.16)
      ..lineTo(cx + r * 0.28, bowY + r * 0.16)
      ..close();
    canvas.drawPath(leftBow, bowPaint);
    canvas.drawPath(rightBow, bowPaint);
    // Center knot
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bowY), width: r * 0.12, height: r * 0.2),
      bowPaint,
    );

    // ── Monocle on right eye (if not sad) ────────────────────────────────────
    if (state != PigState.sad && state != PigState.excited) {
      final monocleCenter = Offset(cx + r * 0.3, cy - r * 0.08);
      canvas.drawCircle(monocleCenter, r * 0.19,
        Paint()
          ..color = crownDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.025);
      // Chain dangling down
      final chainPaint = Paint()
        ..color = crownDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.015;
      final chainPath = Path()
        ..moveTo(monocleCenter.dx + r * 0.18, monocleCenter.dy + r * 0.05)
        ..quadraticBezierTo(
          monocleCenter.dx + r * 0.3, monocleCenter.dy + r * 0.3,
          monocleCenter.dx + r * 0.15, monocleCenter.dy + r * 0.5);
      canvas.drawPath(chainPath, chainPaint);
    }
  }

  Color _bodyColor() {
    // Base color per mascot
    final base = switch (kind) {
      MascotKind.pig     => const Color(0xFFFFB6C1),  // classic pig pink
      MascotKind.bunny   => const Color(0xFFFFFFFF),  // white bunny
      MascotKind.bear    => const Color(0xFFC08457),  // warm brown
      MascotKind.cat     => const Color(0xFFF9A866),  // orange tabby
      MascotKind.fox     => const Color(0xFFE86B2A),  // fox orange
      MascotKind.panda   => const Color(0xFFFAFAFA),  // panda white
      MascotKind.unicorn => const Color(0xFFE6D0FF),  // lavender
      MascotKind.robot   => const Color(0xFFB0C4D6),  // metallic blue-gray
      MascotKind.plant   => const Color(0xFF8BD47A),  // fresh green sprout
      MascotKind.birdie  => const Color(0xFFFFE066),  // sunny yellow
    };
    // State modulates lightness/saturation
    switch (state) {
      case PigState.happy:
        return Color.lerp(base, const Color(0xFFFFFFFF), 0.1)!;
      case PigState.excited:
        return Color.lerp(base, const Color(0xFFFF85A1), 0.15)!;
      case PigState.sad:
        return Color.lerp(base, const Color(0xFF808080), 0.25)!;
      case PigState.normal:
        return base;
    }
  }

  Color _nostrilColor() {
    switch (state) {
      case PigState.sad:
        return const Color(0xFF9E7A8A);
      default:
        return const Color(0xFFD47FA6);
    }
  }

  void _drawEar(Canvas canvas, Offset center, double radius, Color bodyColor) {
    final outerPaint = Paint()..color = bodyColor;
    canvas.drawCircle(center, radius, outerPaint);
    final innerPaint = Paint()..color = AppColors.pigBlush.withValues(alpha: 0.45 * 255);
    canvas.drawCircle(center, radius * 0.58, innerPaint);
  }

  /// Dispatches ear drawing to kind-specific shape.
  void _drawEars(Canvas canvas, double cx, double cy, double r, Color bodyColor) {
    switch (kind) {
      case MascotKind.pig:
        _drawEar(canvas, Offset(cx - r * 0.68, cy - r * 0.72), r * 0.32, bodyColor);
        _drawEar(canvas, Offset(cx + r * 0.68, cy - r * 0.72), r * 0.32, bodyColor);
      case MascotKind.bunny:
        _drawBunnyEar(canvas, cx - r * 0.32, cy - r * 1.2, r, bodyColor);
        _drawBunnyEar(canvas, cx + r * 0.32, cy - r * 1.2, r, bodyColor);
      case MascotKind.bear:
        _drawBearEar(canvas, Offset(cx - r * 0.78, cy - r * 0.85), r * 0.28, bodyColor);
        _drawBearEar(canvas, Offset(cx + r * 0.78, cy - r * 0.85), r * 0.28, bodyColor);
      case MascotKind.cat:
        _drawTriangleEar(canvas, cx - r * 0.55, cy - r * 0.78, r, bodyColor, 0.5);
        _drawTriangleEar(canvas, cx + r * 0.55, cy - r * 0.78, r, bodyColor, 0.5);
      case MascotKind.fox:
        _drawTriangleEar(canvas, cx - r * 0.55, cy - r * 0.82, r, bodyColor, 0.55);
        _drawTriangleEar(canvas, cx + r * 0.55, cy - r * 0.82, r, bodyColor, 0.55);
      case MascotKind.panda:
        _drawBearEar(canvas, Offset(cx - r * 0.72, cy - r * 0.82),
            r * 0.26, const Color(0xFF2D2D2D));
        _drawBearEar(canvas, Offset(cx + r * 0.72, cy - r * 0.82),
            r * 0.26, const Color(0xFF2D2D2D));
      case MascotKind.unicorn:
        _drawTriangleEar(canvas, cx - r * 0.5, cy - r * 0.82, r, bodyColor, 0.45);
        _drawTriangleEar(canvas, cx + r * 0.5, cy - r * 0.82, r, bodyColor, 0.45);
      case MascotKind.robot:
        _drawRobotAntenna(canvas, cx - r * 0.28, cy - r * 1.05, r);
        _drawRobotAntenna(canvas, cx + r * 0.28, cy - r * 1.05, r);
        _drawRobotSidePlate(canvas, Offset(cx - r * 0.95, cy), r);
        _drawRobotSidePlate(canvas, Offset(cx + r * 0.95, cy), r);
      case MascotKind.plant:
        _drawLeaf(canvas, cx - r * 0.22, cy - r * 0.95, r, flip: false);
        _drawLeaf(canvas, cx + r * 0.22, cy - r * 0.95, r, flip: true);
      case MascotKind.birdie:
        // Head tuft — 3 little feathers on top
        _drawTriangleEar(canvas, cx - r * 0.2, cy - r * 0.85, r, bodyColor, 0.3);
        _drawTriangleEar(canvas, cx, cy - r * 0.95, r, bodyColor, 0.32);
        _drawTriangleEar(canvas, cx + r * 0.2, cy - r * 0.85, r, bodyColor, 0.3);
    }
  }

  void _drawRobotAntenna(Canvas canvas, double cx, double yTip, double r) {
    final stick = Paint()
      ..color = const Color(0xFF6A7A8A)
      ..strokeWidth = r * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, yTip + r * 0.22),
      Offset(cx, yTip),
      stick,
    );
    // Antenna ball (blinking red/green LED)
    canvas.drawCircle(Offset(cx, yTip), r * 0.08,
      Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(Offset(cx - r * 0.02, yTip - r * 0.02), r * 0.03,
      Paint()..color = Colors.white.withValues(alpha: 0.7 * 255));
  }

  void _drawRobotSidePlate(Canvas canvas, Offset center, double r) {
    final plate = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: r * 0.22, height: r * 0.4),
      Radius.circular(r * 0.08),
    );
    canvas.drawRRect(plate, Paint()..color = const Color(0xFF6A7A8A));
    // Screw-head detail
    canvas.drawCircle(center, r * 0.04,
      Paint()..color = const Color(0xFF3D4C5C));
  }

  void _drawLeaf(Canvas canvas, double cx, double cy, double r,
      {required bool flip}) {
    final path = Path();
    final dir = flip ? -1.0 : 1.0;
    // Leaf body — curved teardrop
    path.moveTo(cx, cy + r * 0.15);
    path.quadraticBezierTo(
      cx + dir * r * 0.4, cy - r * 0.1,
      cx + dir * r * 0.32, cy - r * 0.55,
    );
    path.quadraticBezierTo(
      cx + dir * r * 0.05, cy - r * 0.2,
      cx, cy + r * 0.15,
    );
    canvas.drawPath(path, Paint()..color = const Color(0xFF5FA764));
    // Highlight stripe down the middle
    final veinPaint = Paint()
      ..color = const Color(0xFF3D7A46)
      ..strokeWidth = r * 0.015
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx + dir * r * 0.04, cy + r * 0.1),
      Offset(cx + dir * r * 0.28, cy - r * 0.48),
      veinPaint,
    );
  }

  void _drawTriangleEar(Canvas canvas, double cx, double cy, double r,
      Color bodyColor, double heightFactor) {
    final outerPaint = Paint()..color = bodyColor;
    final path = Path()
      ..moveTo(cx - r * 0.22, cy + r * 0.05)
      ..lineTo(cx + r * 0.22, cy + r * 0.05)
      ..lineTo(cx, cy - r * heightFactor)
      ..close();
    canvas.drawPath(path, outerPaint);
    // Inner triangle
    final innerColor = kind == MascotKind.fox
        ? const Color(0xFF2D2D2D)
        : (kind == MascotKind.cat
            ? const Color(0xFFFFC0B0)
            : const Color(0xFFFFD0D9));
    final innerPaint = Paint()..color = innerColor;
    final innerPath = Path()
      ..moveTo(cx - r * 0.13, cy)
      ..lineTo(cx + r * 0.13, cy)
      ..lineTo(cx, cy - r * heightFactor * 0.7)
      ..close();
    canvas.drawPath(innerPath, innerPaint);
  }

  void _drawBunnyEar(Canvas canvas, double cx, double cy, double r, Color bodyColor) {
    // Long oval ear pointing up
    final outerPaint = Paint()..color = bodyColor;
    final innerPaint = Paint()..color = const Color(0xFFFFD0D9);
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: r * 0.32, height: r * 0.75);
    canvas.drawOval(rect, outerPaint);
    final innerRect = Rect.fromCenter(center: Offset(cx, cy + r * 0.05),
      width: r * 0.18, height: r * 0.55);
    canvas.drawOval(innerRect, innerPaint);
  }

  void _drawBearEar(Canvas canvas, Offset center, double radius, Color bodyColor) {
    final outerPaint = Paint()..color = bodyColor;
    canvas.drawCircle(center, radius, outerPaint);
    final innerPaint = Paint()
      ..color = Color.lerp(bodyColor, Colors.white, 0.35)!;
    canvas.drawCircle(center, radius * 0.55, innerPaint);
  }

  void _drawEye(Canvas canvas, Offset center, double r, PigState state) {
    if (state == PigState.sad) {
      // Droopy half-closed eye
      final eyePaint = Paint()
        ..color = const Color(0xFF2D2D2D)
        ..strokeWidth = r * 0.055
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(center.dx - r * 0.1, center.dy)
        ..quadraticBezierTo(center.dx, center.dy - r * 0.1, center.dx + r * 0.1, center.dy);
      canvas.drawPath(path, eyePaint);
      return;
    }

    if (state == PigState.excited) {
      // Star-shaped eyes
      _drawStarEye(canvas, center, r * 0.1);
      return;
    }

    // Normal / happy eyes — white + pupil
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, r * 0.13, whitePaint);

    final pupilPaint = Paint()..color = const Color(0xFF2D2D2D);
    final pupilOffset = state == PigState.happy
        ? Offset(center.dx + r * 0.02, center.dy - r * 0.015)
        : center;
    canvas.drawCircle(pupilOffset, r * 0.075, pupilPaint);

    // Shine
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(pupilOffset.dx - r * 0.03, pupilOffset.dy - r * 0.03), r * 0.025, shinePaint);

    // Happy = U-shaped squint above eye
    if (state == PigState.happy) {
      final squintPaint = Paint()
        ..color = const Color(0xFFD47FA6)
        ..strokeWidth = r * 0.04
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(center.dx - r * 0.12, center.dy - r * 0.1)
        ..quadraticBezierTo(center.dx, center.dy - r * 0.02, center.dx + r * 0.12, center.dy - r * 0.1);
      canvas.drawPath(path, squintPaint);
    }
  }

  void _drawStarEye(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..color = AppColors.primary;
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawMouth(Canvas canvas, Offset center, double r, PigState state) {
    final mouthPaint = Paint()
      ..color = const Color(0xFFB05070)
      ..strokeWidth = r * 0.05
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    switch (state) {
      case PigState.normal:
        // Small smile
        path.moveTo(center.dx - r * 0.15, center.dy + r * 0.04);
        path.quadraticBezierTo(center.dx, center.dy + r * 0.14, center.dx + r * 0.15, center.dy + r * 0.04);
      case PigState.happy:
        // Big open smile
        path.moveTo(center.dx - r * 0.22, center.dy);
        path.quadraticBezierTo(center.dx, center.dy + r * 0.22, center.dx + r * 0.22, center.dy);
        // Teeth hint
        mouthPaint
          ..style = PaintingStyle.fill
          ..color = Colors.white;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(center.dx, center.dy + r * 0.06), width: r * 0.3, height: r * 0.1),
            const Radius.circular(4),
          ),
          mouthPaint,
        );
        mouthPaint
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFB05070);
        path.moveTo(center.dx - r * 0.22, center.dy);
        path.quadraticBezierTo(center.dx, center.dy + r * 0.22, center.dx + r * 0.22, center.dy);
      case PigState.excited:
        // Wide O mouth
        mouthPaint
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFB05070);
        canvas.drawCircle(Offset(center.dx, center.dy + r * 0.08), r * 0.12, mouthPaint);
        return;
      case PigState.sad:
        // Frown
        path.moveTo(center.dx - r * 0.18, center.dy + r * 0.12);
        path.quadraticBezierTo(center.dx, center.dy + r * 0.02, center.dx + r * 0.18, center.dy + r * 0.12);
    }
    canvas.drawPath(path, mouthPaint);
  }

  void _drawSparkle(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = r * 0.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        Offset(center.dx + cos(angle) * r * 0.3, center.dy + sin(angle) * r * 0.3),
        Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r),
        paint,
      );
    }

    canvas.drawCircle(center, r * 0.25, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PigPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.level != level ||
      oldDelegate.accessory?.id != accessory?.id ||
      oldDelegate.kind != kind;
}
