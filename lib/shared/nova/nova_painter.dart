import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:snapfood/shared/nova/nova_state.dart';

// ---------------------------------------------------------------------------
// NovaPainter
// ---------------------------------------------------------------------------
// Faithfully ports the SVG mascot from Nova state machine.html.
// All coordinates are in the original 300×330 viewBox space;
// the Canvas is pre-scaled to fit [size].
//
// The painter is STATELESS — callers pass animation values so that
// NovaWidget controls the AnimationControllers and this class just draws.
//
// Animation values expected (all 0.0–1.0 unless noted):
//   breathe        — idle body scale pulse
//   blinkProgress  — 0=open, 1=closed (scaleY on eye)
//   lookX          — pupils X offset (−5..+5 px in viewBox)
//   popProgress    — squash-and-stretch on state change (0=rest,1=rest,peak=mid)
//   bodyOffsetY    — translateY in viewBox px (hop / jump / sway uses rotate)
//   bodySway       — rotate degrees (thinking sway)
//   bodyShakeX     — translateX px (error shake)
//   armLAngle      — left arm rotation degrees
//   armRAngle      — right arm rotation degrees
//   scanDash       — scan ring rotation (0–360 deg, thinking state)
//   leafAngle      — leaf rotation degrees
//   hatOffsetY     — hat translateY (celebrating)
//   confettiT      — 0..1 confetti fall progress (celebrating)
//   mouthScale     — celebrating mouth open/close
// ---------------------------------------------------------------------------

class NovaPainter extends CustomPainter {
  final NovaState state;

  // animation values
  final double breathe;
  final double blinkProgress; // 0=open eye, 1=closed (scaleY)
  final double lookX;
  final double popProgress;
  final double bodyOffsetY;
  final double bodySway; // degrees
  final double bodyShakeX;
  final double armLAngle; // degrees
  final double armRAngle; // degrees
  final double scanDash; // degrees
  final double leafAngle; // degrees
  final double hatOffsetY;
  final double confettiT;
  final double mouthScale;
  final double sparkleT; // 0..1 sparkle pulse (happy / celebrating)
  final double dotT; // 0..1 thinking dots fade

  const NovaPainter({
    required this.state,
    this.breathe = 0,
    this.blinkProgress = 0,
    this.lookX = 0,
    this.popProgress = 0,
    this.bodyOffsetY = 0,
    this.bodySway = 0,
    this.bodyShakeX = 0,
    this.armLAngle = 0,
    this.armRAngle = 0,
    this.scanDash = 0,
    this.leafAngle = 0,
    this.hatOffsetY = 0,
    this.confettiT = 0,
    this.mouthScale = 1,
    this.sparkleT = 0,
    this.dotT = 0,
  });

  // ── Nova body colors (fixed — do NOT change for dark mode) ──────────────
  static const _cream = Color(0xFFF6E7C1);
  static const _stroke = Color(0xFFB98A55);
  static const _yellow = Color(0xFFFFC93C);
  static const _cheek = Color(0xFFFF8E72);
  static const _green = Color(0xFF5E8F57);
  static const _darkGreen = Color(0xFF2F5D31);
  static const _brown = Color(0xFF4A2C1A);
  static const _hatCream = Color(0xFFFFF4D6);
  static const _mouthRed = Color(0xFFC9422A);
  static const _mouthPink = Color(0xFFFF8E8E);
  static const _camYellow = Color(0xFFE8B83A);
  static const _camYellowStroke = Color(0xFFB98A1E);
  static const _lensInner = Color(0xFF2A2A2E);
  static const _lensInner2 = Color(0xFF4A4A55);
  static const _sweatBlue = Color(0xFF7CC4F0);
  static const _sweatBlueStroke = Color(0xFF3D8FC4);

  // ── Confetti palette ─────────────────────────────────────────────────────
  static const _cfColors = [
    Color(0xFFFFC93C),
    Color(0xFFFF9F2E),
    Color(0xFF5E8F57),
    Color(0xFFF6E7C1),
    Color(0xFF4A2C1A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Scale from 300×330 viewBox to actual size
    final scaleX = size.width / 300;
    final scaleY = size.height / 330;
    final scale = math.min(scaleX, scaleY);
    final ox = (size.width - 300 * scale) / 2;
    final oy = (size.height - 330 * scale) / 2;

    canvas.save();
    canvas.translate(ox, oy);
    canvas.scale(scale, scale);

    // Shadow
    _drawShadow(canvas);

    // Pop squash-and-stretch on #sq (whole character)
    canvas.save();
    canvas.translate(150, 300); // transform-origin: 150 300
    final popScaleX = 1.0 + _popScaleXOffset(popProgress);
    final popScaleY = 1.0 + _popScaleYOffset(popProgress);
    canvas.scale(popScaleX, popScaleY);
    canvas.translate(-150, -300);

    // Breathe on #nova group (idle)
    canvas.save();
    canvas.translate(150, 300);
    final breatheScale = state == NovaState.idle
        ? 1.0 + breathe * 0.015
        : 1.0;
    canvas.scale(breatheScale, state == NovaState.idle ? 1.0 - breathe * 0.015 : 1.0);
    canvas.translate(-150, -300);

    // Body Y offset (hop / jump) + shake X + sway rotation
    canvas.save();
    canvas.translate(150, 300); // sway origin
    canvas.rotate(bodySway * math.pi / 180);
    canvas.translate(-150, -300);
    canvas.translate(bodyShakeX, bodyOffsetY);

    _drawBody(canvas);
    _drawFace(canvas);
    _drawCamera(canvas);
    _drawArms(canvas);
    _drawHat(canvas);
    _drawFx(canvas);

    canvas.restore(); // body transforms
    canvas.restore(); // breathe
    canvas.restore(); // pop

    canvas.restore(); // viewBox scale
  }

  // ── Shadow ────────────────────────────────────────────────────────────────
  void _drawShadow(Canvas canvas) {
    final p = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      const Rect.fromLTWH(78, 301, 144, 18),
      p,
    );
  }

  // ── Body (egg + feet + face circle + cheeks) ────────────────────────────
  void _drawBody(Canvas canvas) {
    final fill = Paint()
      ..color = _cream
      ..style = PaintingStyle.fill;
    final str = Paint()
      ..color = _stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Left foot
    canvas.drawOval(const Rect.fromLTWH(92, 282, 48, 24), fill);
    canvas.drawOval(const Rect.fromLTWH(92, 282, 48, 24), str);
    // Right foot
    canvas.drawOval(const Rect.fromLTWH(160, 282, 48, 24), fill);
    canvas.drawOval(const Rect.fromLTWH(160, 282, 48, 24), str);

    // Egg body
    final bodyPath = Path()
      ..moveTo(150, 104)
      ..cubicTo(215, 104, 246, 160, 244, 218)
      ..cubicTo(242, 268, 205, 296, 150, 296)
      ..cubicTo(95, 296, 58, 268, 56, 218)
      ..cubicTo(54, 160, 85, 104, 150, 104)
      ..close();
    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, str);

    // Camera strap lines
    final strapP = Paint()
      ..color = _green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final strapL = Path()
      ..moveTo(96, 160)
      ..quadraticBezierTo(84, 202, 108, 246);
    canvas.drawPath(strapL, strapP);
    final strapR = Path()
      ..moveTo(204, 160)
      ..quadraticBezierTo(216, 202, 192, 246);
    canvas.drawPath(strapR, strapP);

    // Yellow face circle
    canvas.drawCircle(
      const Offset(150, 192),
      60,
      Paint()..color = _yellow,
    );

    // Cheeks
    canvas.drawOval(
      const Rect.fromLTWH(94, 200, 24, 16),
      Paint()..color = _cheek.withValues(alpha: 0.75),
    );
    canvas.drawOval(
      const Rect.fromLTWH(182, 200, 24, 16),
      Paint()..color = _cheek.withValues(alpha: 0.75),
    );
  }

  // ── Face: eyes + mouth ────────────────────────────────────────────────────
  void _drawFace(Canvas canvas) {
    switch (state) {
      case NovaState.idle:
      case NovaState.thinking:
        _drawNormalEyes(canvas);
        break;
      case NovaState.happy:
        _drawHappyEyes(canvas);
        break;
      case NovaState.error:
        _drawErrorEyes(canvas);
        break;
      case NovaState.celebrating:
        _drawCelebratingEyes(canvas);
        break;
    }

    switch (state) {
      case NovaState.idle:
        _drawIdleMouth(canvas);
        break;
      case NovaState.thinking:
        _drawThinkingMouth(canvas);
        break;
      case NovaState.happy:
        _drawHappyMouth(canvas);
        break;
      case NovaState.error:
        _drawErrorMouth(canvas);
        break;
      case NovaState.celebrating:
        _drawCelebratingMouth(canvas);
        break;
    }
  }

  void _drawNormalEyes(Canvas canvas) {
    final pupilFill = Paint()..color = _brown;
    final glintFill = Paint()..color = Colors.white;

    // Pupils with lookX offset applied
    for (final cx in [124.0, 176.0]) {
      // Eye white / blink scaleY
      canvas.save();
      canvas.translate(cx, 188);
      canvas.scale(1, 1.0 - blinkProgress * 0.9); // scaleY for blink
      canvas.translate(-cx, -188);

      // Draw eye ellipse (9×12.5)
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + lookX, 188),
          width: 18,
          height: 25,
        ),
        pupilFill,
      );
      // Glint
      canvas.drawCircle(Offset(cx + lookX + 3, 183), 3.6, glintFill);
      canvas.restore();
    }
  }

  void _drawHappyEyes(Canvas canvas) {
    // Crescent arcs (U-shapes)
    final p = Paint()
      ..color = _brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    final left = Path()
      ..moveTo(112, 192)
      ..quadraticBezierTo(124, 176, 136, 192);
    final right = Path()
      ..moveTo(164, 192)
      ..quadraticBezierTo(176, 176, 188, 192);
    canvas.drawPath(left, p);
    canvas.drawPath(right, p);
  }

  void _drawErrorEyes(Canvas canvas) {
    // Arrow / zigzag eyes
    final p = Paint()
      ..color = _brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final left = Path()
      ..moveTo(114, 178)
      ..lineTo(134, 188)
      ..lineTo(114, 198);
    final right = Path()
      ..moveTo(186, 178)
      ..lineTo(166, 188)
      ..lineTo(186, 198);
    canvas.drawPath(left, p);
    canvas.drawPath(right, p);
  }

  void _drawCelebratingEyes(Canvas canvas) {
    // Star eyes — circle + 8-point star shape
    final pupilFill = Paint()..color = _brown;
    final starFill = Paint()..color = _yellow;

    for (final cx in [124.0, 176.0]) {
      canvas.drawCircle(Offset(cx, 188), 13, pupilFill);
      _drawStar8(canvas, Offset(cx, 188), 8, starFill);
    }
  }

  void _drawStar8(Canvas canvas, Offset center, double r, Paint paint) {
    // 8-pointed star using the SVG polygon definition scaled to r
    const pts = <double>[
      0, -1, 0.263, -0.350, 0.950, -0.313, 0.413, 0.138,
      0.588, 0.813, 0, 0.438, -0.588, 0.813, -0.413, 0.138,
      -0.950, -0.313, -0.263, -0.350,
    ];
    final path = Path();
    for (var i = 0; i < pts.length; i += 2) {
      final x = center.dx + pts[i] * r;
      final y = center.dy + pts[i + 1] * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawIdleMouth(Canvas canvas) {
    final p = Paint()
      ..color = _brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(137, 208)
      ..quadraticBezierTo(150, 222, 163, 208);
    canvas.drawPath(path, p);
  }

  void _drawThinkingMouth(Canvas canvas) {
    // Small tongue / confused — ellipse
    canvas.drawOval(
      const Rect.fromLTWH(153, 208.5, 10, 9),
      Paint()
        ..color = const Color(0xFFD9482B)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      const Rect.fromLTWH(153, 208.5, 10, 9),
      Paint()
        ..color = _brown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawHappyMouth(Canvas canvas) {
    // Open smile — filled triangle path
    final fill = Paint()
      ..color = _mouthRed
      ..style = PaintingStyle.fill;
    final str = Paint()
      ..color = _brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    final mouth = Path()
      ..moveTo(134, 204)
      ..quadraticBezierTo(150, 232, 166, 204)
      ..close();
    canvas.drawPath(mouth, fill);
    canvas.drawPath(mouth, str);
    // Inner tongue
    canvas.drawOval(
      const Rect.fromLTWH(142, 213, 16, 11),
      Paint()..color = _mouthPink,
    );
  }

  void _drawErrorMouth(Canvas canvas) {
    // Wobble frown — animated wob
    final p = Paint()
      ..color = _brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    // wob offset applied via bodyShakeX analog — we'll use a slight
    // horizontal offset on the bezier control point
    final dx = math.sin(bodyShakeX * 0.5) * 3;
    final path = Path()
      ..moveTo(135, 214)
      ..quadraticBezierTo(142 + dx, 205, 150, 214)
      ..quadraticBezierTo(158 + dx, 223, 165, 214);
    canvas.drawPath(path, p);
  }

  void _drawCelebratingMouth(Canvas canvas) {
    // Large open mouth, scale with mouthScale
    canvas.save();
    canvas.translate(150, 202); // top center as transform-origin
    canvas.scale(1.0, mouthScale);
    canvas.translate(-150, -202);

    final fill = Paint()
      ..color = _mouthRed
      ..style = PaintingStyle.fill;
    final str = Paint()
      ..color = _brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    final mouth = Path()
      ..moveTo(128, 202)
      ..quadraticBezierTo(150, 242, 172, 202)
      ..close();
    canvas.drawPath(mouth, fill);
    canvas.drawPath(mouth, str);
    canvas.drawOval(
      const Rect.fromLTWH(140, 211, 20, 12),
      Paint()..color = _mouthPink,
    );
    canvas.restore();
  }

  // ── Camera ────────────────────────────────────────────────────────────────
  void _drawCamera(Canvas canvas) {
    // Hot shoe / mount
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(124, 224, 26, 14),
        const Radius.circular(5),
      ),
      Paint()
        ..color = const Color(0xFF4F8A4A)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(124, 224, 26, 14),
        const Radius.circular(5),
      ),
      Paint()
        ..color = _darkGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Camera body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(104, 232, 92, 58),
        const Radius.circular(12),
      ),
      Paint()
        ..color = _green
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(104, 232, 92, 58),
        const Radius.circular(12),
      ),
      Paint()
        ..color = _darkGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Lens outer ring
    canvas.drawCircle(
      const Offset(150, 261),
      21,
      Paint()
        ..color = _camYellow
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      const Offset(150, 261),
      21,
      Paint()
        ..color = _camYellowStroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Lens dark inner
    canvas.drawCircle(
      const Offset(150, 261),
      15,
      Paint()..color = _lensInner,
    );
    canvas.drawCircle(
      const Offset(150, 261),
      6,
      Paint()..color = _lensInner2,
    );

    // Lens glint
    canvas.drawCircle(
      const Offset(144, 255),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    // Thinking: spinning scan ring
    if (state == NovaState.thinking) {
      canvas.save();
      canvas.translate(150, 261);
      canvas.rotate(scanDash * math.pi / 180);
      canvas.translate(-150, -261);
      final scanPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      // Dashed circle approximation: draw 4 arcs
      for (var i = 0; i < 4; i++) {
        canvas.drawArc(
          const Rect.fromLTWH(125, 236, 50, 50),
          i * math.pi / 2,
          0.35,
          false,
          scanPaint,
        );
      }
      canvas.restore();
    }

    // LED dot top right
    canvas.drawCircle(
      const Offset(184, 244),
      3.5,
      Paint()..color = _cream,
    );
  }

  // ── Arms ──────────────────────────────────────────────────────────────────
  void _drawArms(Canvas canvas) {
    _drawArm(canvas, left: true, angleDeg: armLAngle);
    _drawArm(canvas, left: false, angleDeg: armRAngle);
  }

  void _drawArm(Canvas canvas, {required bool left, required double angleDeg}) {
    // transform-origin: left arm 104,218 / right arm 196,218
    final ox = left ? 104.0 : 196.0;
    const oy = 218.0;

    canvas.save();
    canvas.translate(ox, oy);
    canvas.rotate(angleDeg * math.pi / 180);
    canvas.translate(-ox, -oy);

    final cx = left ? 100.0 : 200.0;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 240), width: 28, height: 44),
      Paint()
        ..color = _cream
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 240), width: 28, height: 44),
      Paint()
        ..color = _stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.restore();
  }

  // ── Hat ───────────────────────────────────────────────────────────────────
  void _drawHat(Canvas canvas) {
    // transform-origin: 150,110 — celebrating hat bounce
    canvas.save();
    canvas.translate(150, 110);
    canvas.translate(0, hatOffsetY);
    canvas.translate(-150, -110);

    _hatShape(canvas, Paint()
      ..color = _stroke
      ..style = PaintingStyle.fill);
    _hatShape(canvas, Paint()
      ..color = _hatCream
      ..style = PaintingStyle.fill);

    // Brim lines
    final linePaint = Paint()
      ..color = const Color(0xFFEBD49E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final x in [130.0, 150.0, 170.0]) {
      canvas.drawLine(Offset(x, 90), Offset(x, 112), linePaint);
    }

    _drawLeaf(canvas);
    canvas.restore();
  }

  void _hatShape(Canvas canvas, Paint paint) {
    // Two circles + one circle + rect brim — stroked first (offset), then filled
    canvas.drawCircle(const Offset(118, 78), 22, paint);
    canvas.drawCircle(const Offset(182, 78), 22, paint);
    canvas.drawCircle(const Offset(150, 64), 27, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(106, 86, 88, 28),
        const Radius.circular(12),
      ),
      paint,
    );
  }

  void _drawLeaf(Canvas canvas) {
    // transform-origin: 188,100
    canvas.save();
    canvas.translate(188, 100);
    canvas.rotate(leafAngle * math.pi / 180);
    canvas.translate(-188, -100);

    final leafFill = Paint()
      ..color = _green
      ..style = PaintingStyle.fill;
    final leafStr = Paint()
      ..color = _darkGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    final leafPath = Path()
      ..moveTo(188, 100)
      ..cubicTo(190, 78, 212, 66, 232, 70)
      ..cubicTo(232, 92, 214, 106, 188, 100)
      ..close();
    canvas.drawPath(leafPath, leafFill);
    canvas.drawPath(leafPath, leafStr);

    // Leaf vein
    final veinPath = Path()
      ..moveTo(192, 98)
      ..quadraticBezierTo(210, 86, 226, 74);
    canvas.drawPath(
      veinPath,
      Paint()
        ..color = _darkGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  // ── FX (sparkles, dots, sweat, confetti) ─────────────────────────────────
  void _drawFx(Canvas canvas) {
    switch (state) {
      case NovaState.happy:
        _drawSparkles(canvas);
        break;
      case NovaState.thinking:
        _drawThinkingFx(canvas);
        break;
      case NovaState.error:
        _drawErrorFx(canvas);
        break;
      case NovaState.celebrating:
        _drawCelebratingFx(canvas);
        break;
      case NovaState.idle:
        break;
    }
  }

  void _drawSparkles(Canvas canvas) {
    // Four sparkle stars at fixed positions (from HTML fx positions)
    final opacity = math.sin(sparkleT * math.pi).clamp(0.0, 1.0);
    if (opacity <= 0) return;
    final starPaint = Paint()
      ..color = _yellow.withValues(alpha: opacity);
    final orangePaint = Paint()
      ..color = const Color(0xFFFF9F2E).withValues(alpha: opacity);

    _drawSparkleAt(canvas, const Offset(66, 150), 1.7 * 8, starPaint);
    _drawSparkleAt(canvas, const Offset(236, 128), 1.4 * 8, starPaint);
    _drawSparkleAt(canvas, const Offset(58, 236), 1.1 * 8, orangePaint);
    // Heart-like shape at (244, 206)
    final heartPaint = Paint()
      ..color = const Color(0xFFFF9F2E).withValues(alpha: opacity);
    _drawHeart(canvas, const Offset(244, 206), 10, heartPaint);
  }

  void _drawSparkleAt(Canvas canvas, Offset center, double r, Paint paint) {
    _drawStar8(canvas, center, r, paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double r, Paint paint) {
    // Simplified heart — two bezier petals
    final path = Path()
      ..moveTo(center.dx, center.dy - r * 0.4)
      ..cubicTo(
        center.dx, center.dy - r,
        center.dx - r, center.dy - r,
        center.dx - r, center.dy - r * 0.4,
      )
      ..cubicTo(
        center.dx - r, center.dy + r * 0.3,
        center.dx, center.dy + r,
        center.dx, center.dy + r,
      )
      ..cubicTo(
        center.dx, center.dy + r,
        center.dx + r, center.dy + r * 0.3,
        center.dx + r, center.dy - r * 0.4,
      )
      ..cubicTo(
        center.dx + r, center.dy - r,
        center.dx, center.dy - r,
        center.dx, center.dy - r * 0.4,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawThinkingFx(Canvas canvas) {
    // Question mark
    const qStyle = TextStyle(
      fontSize: 46,
      fontWeight: FontWeight.w800,
      color: Color(0xFF2F5D31),
    );
    final qPainter = TextPainter(
      text: const TextSpan(text: '?', style: qStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    // Bob up/down using bodyOffsetY analog
    final qY = 54.0 + math.sin(dotT * math.pi * 2) * 8;
    qPainter.paint(canvas, Offset(218, qY));

    // Three rising dots
    for (var i = 0; i < 3; i++) {
      final phase = (dotT + i * 0.33) % 1.0;
      final dotOpacity = (math.sin(phase * math.pi)).clamp(0.2, 1.0);
      canvas.drawCircle(
        Offset(214 + i * 6.0, 146 - i * 14.0),
        3.0 + i * 1.0,
        Paint()..color = _green.withValues(alpha: dotOpacity),
      );
    }
  }

  void _drawErrorFx(Canvas canvas) {
    // Sweat drop — animated fall
    final dropT = (dotT * 1.4) % 1.0;
    final dropY = dropT * 22;
    final dropOpacity = dropT < 0.15 ? dropT / 0.15 : (1.0 - dropT).clamp(0.0, 1.0);
    if (dropOpacity > 0) {
      final dropPath = Path()
        ..moveTo(212, 150 - 12 + dropY)
        ..quadraticBezierTo(221, 152 + dropY, 212, 158 + dropY)
        ..quadraticBezierTo(203, 152 + dropY, 212, 150 - 12 + dropY)
        ..close();
      canvas.drawPath(
        dropPath,
        Paint()
          ..color = _sweatBlue.withValues(alpha: dropOpacity)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        dropPath,
        Paint()
          ..color = _sweatBlueStroke.withValues(alpha: dropOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Scribble (wobble) — frustration lines
    final wobX = math.sin(dotT * math.pi * 4) * 3;
    final scribPaint = Paint()
      ..color = _darkGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final scrib = Path()
      ..moveTo(74 + wobX, 130)
      ..cubicTo(62, 128, 62, 114, 74 + wobX, 114)
      ..cubicTo(86 + wobX, 114, 86, 134, 70, 134)
      ..cubicTo(52, 134, 54, 108, 76 + wobX, 106);
    canvas.drawPath(scrib, scribPaint);
  }

  void _drawCelebratingFx(Canvas canvas) {
    _drawSparkles(canvas); // reuse sparkles

    // Confetti — 18 pieces, positions match HTML
    final rng = math.Random(42); // stable seed for consistent layout
    for (var i = 0; i < 18; i++) {
      final color = _cfColors[i % _cfColors.length];
      final startX = 8.0 + i * 16;
      final dx = rng.nextDouble() * 40 - 20;
      final dr = rng.nextDouble() * 720 - 360;
      final dur = 1.6 + rng.nextDouble() * 1.2;
      final delay = rng.nextDouble() * 2.5;

      // Progress accounting for delay offset
      final t = ((confettiT * dur - delay / dur) % 1.0).clamp(0.0, 1.0);
      final y = -30 + t * 370;
      final x = startX + t * dx;
      final angle = t * dr * math.pi / 180;
      final opacity = (t < 0.05 ? t / 0.05 : (t > 0.9 ? (1.0 - t) / 0.1 : 1.0)).clamp(0.0, 1.0);

      if (opacity <= 0) continue;

      canvas.save();
      canvas.translate(x + 3, y + 5);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: 6 + rng.nextDouble() * 3,
            height: 10 + rng.nextDouble() * 4,
          ),
          const Radius.circular(1.5),
        ),
        Paint()..color = color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  // ── Pop keyframe helpers ──────────────────────────────────────────────────
  // CSS: 0%{scale(.9,1.1)} 50%{scale(1.08,.92)} 100%{scale(1)}
  double _popScaleXOffset(double t) {
    if (t < 0.5) return _lerp(-0.1, 0.08, t * 2);
    return _lerp(0.08, 0.0, (t - 0.5) * 2);
  }

  double _popScaleYOffset(double t) {
    if (t < 0.5) return _lerp(0.1, -0.08, t * 2);
    return _lerp(-0.08, 0.0, (t - 0.5) * 2);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(NovaPainter old) => true; // always repaint during animation
}
