import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Which drawing to use. Chosen from a menu entry's `visual.iconKey`.
enum IllustrationKind {
  /// A tray of 3 takoyaki.
  takoyaki,

  /// A fuller tray, for 2-flavour bundles.
  duo,

  /// A big box of takoyaki, for sharing bundles.
  box,

  /// A cup with straw, liquid tinted.
  drink,

  /// Takoyaki tray with a drink.
  combo;

  static IllustrationKind fromKey(String key) => switch (key) {
    'drink' => drink,
    'combo' => combo,
    'duo' => duo,
    'group' || 'box' => box,
    _ => takoyaki,
  };
}

/// Flat, friendly food drawings in one consistent style: orange takoyaki
/// and simple cups on a cream background. Only the [accent] changes per
/// flavour (topping flakes on takoyaki, liquid colour in cups).
class FoodIllustration extends StatelessWidget {
  const FoodIllustration({
    super.key,
    required this.kind,
    required this.accent,
    this.drinkColor,
  });

  final IllustrationKind kind;
  final Color accent;

  /// Liquid colour for drinks (defaults to [accent]).
  final Color? drinkColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.illustrationBg,
      child: CustomPaint(
        painter: _FoodPainter(kind, accent, drinkColor ?? accent),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _FoodPainter extends CustomPainter {
  _FoodPainter(this.kind, this.accent, this.drinkColor);

  final IllustrationKind kind;
  final Color accent;
  final Color drinkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    // Work in a centred square so wide tiles stay in proportion.
    final area = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: s,
      height: s,
    );
    _decorations(canvas, area);
    switch (kind) {
      case IllustrationKind.takoyaki:
        _tray(canvas, _sub(area, 0.06, 0.10, 0.94, 0.92), accent, rows: 1);
      case IllustrationKind.duo:
        _tray(
          canvas,
          _sub(area, 0.02, 0.12, 0.98, 0.92),
          accent,
          rows: 1,
          perRow: 4,
        );
      case IllustrationKind.box:
        _tray(canvas, _sub(area, 0.02, 0.08, 0.98, 0.94), accent, rows: 2);
      case IllustrationKind.drink:
        _cup(canvas, _sub(area, 0.18, 0.06, 0.82, 0.94), drinkColor);
      case IllustrationKind.combo:
        _tray(canvas, _sub(area, -0.02, 0.22, 0.70, 0.92), accent, rows: 1);
        _cup(canvas, _sub(area, 0.56, 0.12, 0.98, 0.90), drinkColor);
    }
  }

  /// A rect inside [r] given as fractions of its width/height.
  Rect _sub(Rect r, double l, double t, double rr, double b) => Rect.fromLTRB(
    r.left + r.width * l,
    r.top + r.height * t,
    r.left + r.width * rr,
    r.top + r.height * b,
  );

  /// Soft background dots so tiles don't look empty.
  void _decorations(Canvas canvas, Rect a) {
    final paint = Paint()..color = AppColors.primary.withValues(alpha: 0.10);
    canvas.drawCircle(
      a.topLeft + Offset(a.width * 0.14, a.height * 0.18),
      a.width * 0.05,
      paint,
    );
    canvas.drawCircle(
      a.topRight + Offset(-a.width * 0.12, a.height * 0.12),
      a.width * 0.03,
      paint,
    );
    canvas.drawCircle(
      a.bottomRight + Offset(-a.width * 0.10, -a.height * 0.16),
      a.width * 0.04,
      paint,
    );
  }

  void _tray(
    Canvas canvas,
    Rect r,
    Color topping, {
    required int rows,
    int perRow = 3,
  }) {
    final w = r.width;
    final h = r.height;

    // Ball size fits the row count.
    final radius = rows == 1 ? w / (perRow * 2 + 0.5) : w / (perRow * 2 + 1.2);
    final trayTop = r.top + h * (rows == 1 ? 0.56 : 0.60);
    final trayBottom = r.bottom - h * 0.08;

    // Kraft paper boat.
    final tray = Path()
      ..moveTo(r.left + w * 0.04, trayTop)
      ..lineTo(r.right - w * 0.04, trayTop)
      ..lineTo(r.right - w * 0.14, trayBottom)
      ..quadraticBezierTo(
        r.center.dx,
        trayBottom + h * 0.03,
        r.left + w * 0.14,
        trayBottom,
      )
      ..close();
    canvas.drawShadow(tray, Colors.black, 2, false);
    canvas.drawPath(tray, Paint()..color = const Color(0xFFE9D2B4));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          r.left + w * 0.02,
          trayTop - h * 0.025,
          r.right - w * 0.02,
          trayTop + h * 0.03,
        ),
        Radius.circular(h * 0.03),
      ),
      Paint()..color = const Color(0xFFD9BC97),
    );

    // Balls: back row first so the front row overlaps it.
    final centres = <Offset>[];
    final spacing = (w - radius * 2 * perRow) / (perRow + 1);
    double rowX(int i, int count, double inset) =>
        r.left + inset + spacing + radius + i * (radius * 2 + spacing);
    if (rows == 1) {
      for (var i = 0; i < perRow; i++) {
        final lift = (i.isOdd ? 0.10 : 0.0) * h;
        centres.add(Offset(rowX(i, perRow, 0), trayTop - radius * 0.35 - lift));
      }
      // Draw lifted (odd) balls first so lower ones overlap them.
      centres.sort((a, b) => a.dy.compareTo(b.dy));
    } else {
      for (var i = 0; i < perRow; i++) {
        centres.add(
          Offset(rowX(i, perRow, radius * 0.6), trayTop - radius * 1.25),
        );
      }
      for (var i = 0; i < perRow; i++) {
        centres.add(
          Offset(rowX(i, perRow, -radius * 0.2), trayTop - radius * 0.1),
        );
      }
    }
    for (final c in centres) {
      _ball(canvas, c, radius, topping);
    }
  }

  void _ball(Canvas canvas, Offset c, double r, Color topping) {
    final circle = Rect.fromCircle(center: c, radius: r);
    // Soft shadow under the ball.
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(0, r * 0.85),
        width: r * 1.7,
        height: r * 0.35,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );
    // Golden batter.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          radius: 1.0,
          colors: [Color(0xFFFFC487), AppColors.primary, Color(0xFFE5822A)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(circle),
    );
    // Sauce cap.
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    final sauce = Path()
      ..moveTo(c.dx - r * 1.1, c.dy - r * 0.05)
      ..cubicTo(
        c.dx - r * 0.6,
        c.dy + r * 0.25,
        c.dx - r * 0.2,
        c.dy - r * 0.15,
        c.dx + r * 0.1,
        c.dy + r * 0.12,
      )
      ..cubicTo(
        c.dx + r * 0.45,
        c.dy + r * 0.35,
        c.dx + r * 0.8,
        c.dy - r * 0.05,
        c.dx + r * 1.1,
        c.dy + r * 0.05,
      )
      ..lineTo(c.dx + r * 1.1, c.dy - r * 1.2)
      ..lineTo(c.dx - r * 1.1, c.dy - r * 1.2)
      ..close();
    canvas.drawPath(sauce, Paint()..color = const Color(0xFF7A4122));
    canvas.restore();

    // Mayo zigzag.
    final mayo = Path()..moveTo(c.dx - r * 0.65, c.dy - r * 0.45);
    for (var i = 1; i <= 4; i++) {
      mayo.lineTo(
        c.dx - r * 0.65 + i * r * 0.32,
        c.dy - r * (i.isOdd ? 0.72 : 0.42),
      );
    }
    canvas.drawPath(
      mayo,
      Paint()
        ..color = const Color(0xFFFFFBF2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Flavour accent: a few topping flakes.
    final flake = Paint()..color = topping;
    for (final (dx, dy, size) in const [
      (-0.35, -0.2, 0.13),
      (0.15, -0.6, 0.11),
      (0.42, -0.25, 0.12),
    ]) {
      canvas.save();
      canvas.translate(c.dx + r * dx, c.dy + r * dy);
      canvas.rotate(dx * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * size * 2.2,
            height: r * size * 1.3,
          ),
          Radius.circular(r * 0.05),
        ),
        flake,
      );
      canvas.restore();
    }

    // Highlight.
    canvas.drawCircle(
      c + Offset(-r * 0.45, r * 0.35),
      r * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  void _cup(Canvas canvas, Rect r, Color liquid) {
    final w = r.width;
    final h = r.height;
    final topY = r.top + h * 0.22;
    final bottomY = r.bottom - h * 0.04;
    final topHalf = w * 0.38;
    final bottomHalf = w * 0.28;
    final cx = r.center.dx;

    final cup = Path()
      ..moveTo(cx - topHalf, topY)
      ..lineTo(cx + topHalf, topY)
      ..lineTo(cx + bottomHalf, bottomY - h * 0.03)
      ..quadraticBezierTo(
        cx + bottomHalf - w * 0.01,
        bottomY,
        cx + bottomHalf - w * 0.06,
        bottomY,
      )
      ..lineTo(cx - bottomHalf + w * 0.06, bottomY)
      ..quadraticBezierTo(
        cx - bottomHalf + w * 0.01,
        bottomY,
        cx - bottomHalf,
        bottomY - h * 0.03,
      )
      ..close();

    // Straw behind the lid.
    final straw = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx + w * 0.04, topY + h * 0.05),
      Offset(cx + w * 0.18, r.top + h * 0.02),
      straw,
    );
    canvas.drawLine(
      Offset(cx + w * 0.18, r.top + h * 0.02),
      Offset(cx + w * 0.30, r.top + h * 0.02),
      straw,
    );

    canvas.drawShadow(cup, Colors.black, 2, false);
    canvas.drawPath(cup, Paint()..color = Colors.white);

    // Liquid fill with a lighter top.
    canvas.save();
    canvas.clipPath(cup);
    final liquidRect = Rect.fromLTRB(r.left, topY + h * 0.10, r.right, bottomY);
    canvas.drawRect(
      liquidRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(liquid, Colors.white, 0.25)!, liquid],
        ).createShader(liquidRect),
    );
    // Bubbles.
    final bubble = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (final (dx, dy, size) in const [
      (-0.12, 0.55, 0.035),
      (0.08, 0.70, 0.025),
      (-0.02, 0.42, 0.02),
      (0.14, 0.50, 0.03),
    ]) {
      canvas.drawCircle(Offset(cx + w * dx, r.top + h * dy), w * size, bubble);
    }
    // Shine.
    canvas.drawRect(
      Rect.fromLTWH(
        cx - topHalf + w * 0.08,
        topY + h * 0.14,
        w * 0.06,
        h * 0.5,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );
    canvas.restore();

    // Lid.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          cx - topHalf - w * 0.04,
          topY - h * 0.06,
          cx + topHalf + w * 0.04,
          topY + h * 0.02,
        ),
        Radius.circular(h * 0.03),
      ),
      Paint()..color = const Color(0xFFF4ECE3),
    );
    canvas.drawPath(
      cup,
      Paint()
        ..color = AppColors.borderStrong
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );
  }

  @override
  bool shouldRepaint(_FoodPainter old) =>
      old.kind != kind || old.accent != accent || old.drinkColor != drinkColor;
}
