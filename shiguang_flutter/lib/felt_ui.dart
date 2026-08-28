import 'dart:math' as math;

import 'package:flutter/material.dart';

const feltInk = Color(0xFF273733);
const feltForest = Color(0xFF285B44);
const feltCream = Color(0xFFFAF6EE);
const feltIvory = Color(0xFFFFFCF7);
const feltSage = Color(0xFFB8BE9E);
const feltBlue = Color(0xFFC4DDE1);
const feltClay = Color(0xFFE5A083);
const feltMustard = Color(0xFFE6B548);
const feltLine = Color(0xFFE2DCD1);
const feltMuted = Color(0xFF6F746E);

class FeltBackdrop extends StatelessWidget {
  final Widget child;
  const FeltBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ColoredBox(color: feltCream),
      const IgnorePointer(child: CustomPaint(painter: _FiberPainter(.045))),
      child,
    ],
  );
}

class FeltCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  const FeltCard({
    super.key,
    required this.child,
    this.color = feltIvory,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: .76)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F342C27),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color(0x12FFFFFF),
            blurRadius: 1,
            offset: Offset(0, -1),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _FiberPainter(.075)),
            ),
          ),
          child,
        ],
      ),
    );
    if (onTap == null) return card;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

class FeltIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  final double size;
  const FeltIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.selected = false,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _PebblePainter(color: selected ? feltForest : color),
      child: Center(
        child: Icon(
          icon,
          size: size * .46,
          weight: 200,
          color: selected ? feltIvory : feltInk,
        ),
      ),
    ),
  );
}

class FeltLandscape extends StatelessWidget {
  final double height;
  final bool sun;
  final double sunY;
  final double verticalBias;
  const FeltLandscape({
    super.key,
    this.height = 170,
    this.sun = true,
    this.sunY = .19,
    this.verticalBias = 0,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(
      painter: _LandscapePainter(
        sun: sun,
        sunY: sunY,
        verticalBias: verticalBias,
      ),
    ),
  );
}

class FeltInitial extends StatelessWidget {
  final String text;
  final double size;
  const FeltInitial({super.key, required this.text, this.size = 72});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: feltSage,
      border: Border.all(color: Colors.white.withValues(alpha: .7)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x30342C27),
          blurRadius: 7,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: ClipOval(
            child: CustomPaint(painter: const _FiberPainter(.09)),
          ),
        ),
        Center(
          child: Text(
            text,
            style: TextStyle(
              color: feltIvory,
              fontFamily: 'NotoSerifSC',
              fontSize: size * .43,
            ),
          ),
        ),
      ],
    ),
  );
}

class FeltSkill extends StatelessWidget {
  final String label;
  final String? caption;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double width;
  const FeltSkill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.caption,
    this.onTap,
    this.width = 104,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: SizedBox(
      width: width,
      child: Column(
        children: [
          FeltIconTile(icon: icon, color: color, size: 70),
          const SizedBox(height: 9),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          if (caption != null)
            Text(
              caption!,
              style: const TextStyle(fontSize: 11, color: feltMuted),
            ),
        ],
      ),
    ),
  );
}

class _FiberPainter extends CustomPainter {
  final double opacity;
  const _FiberPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()
      ..color = feltInk.withValues(alpha: opacity)
      ..strokeWidth = .42
      ..strokeCap = StrokeCap.round;
    final light = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 1.4)
      ..strokeWidth = .55
      ..strokeCap = StrokeCap.round;
    const spacing = 7.0;
    for (double y = 3; y < size.height; y += spacing) {
      for (double x = 3; x < size.width; x += spacing) {
        final seed = math.sin(x * 12.9898 + y * 78.233) * 43758.5453;
        final unit = seed - seed.floorToDouble();
        final angle = unit * math.pi * 1.7;
        final length = 1.5 + unit * 2.6;
        final origin = Offset(
          x + math.sin(seed) * 2.4,
          y + math.cos(seed * .71) * 2.4,
        );
        final end = origin + Offset(math.cos(angle), math.sin(angle)) * length;
        canvas.drawLine(origin, end, unit > .48 ? dark : light);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FiberPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

class _PebblePainter extends CustomPainter {
  final Color color;
  const _PebblePainter({required this.color});

  Path _path(Size size) => Path()
    ..moveTo(size.width * .18, size.height * .07)
    ..cubicTo(
      size.width * .43,
      size.height * -.01,
      size.width * .82,
      size.height * .03,
      size.width * .93,
      size.height * .26,
    )
    ..cubicTo(
      size.width * 1.02,
      size.height * .52,
      size.width * .94,
      size.height * .86,
      size.width * .71,
      size.height * .96,
    )
    ..cubicTo(
      size.width * .43,
      size.height * 1.04,
      size.width * .10,
      size.height * .94,
      size.width * .04,
      size.height * .68,
    )
    ..cubicTo(
      size.width * -.02,
      size.height * .43,
      size.width * .01,
      size.height * .19,
      size.width * .18,
      size.height * .07,
    )
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    canvas.drawShadow(path, const Color(0x4A342C27), 4, false);
    canvas.drawPath(path, Paint()..color = color);
    canvas.save();
    canvas.clipPath(path);
    const _FiberPainter(.09).paint(canvas, size);
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = Colors.white.withValues(alpha: .62),
    );
  }

  @override
  bool shouldRepaint(covariant _PebblePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LandscapePainter extends CustomPainter {
  final bool sun;
  final double sunY;
  final double verticalBias;
  const _LandscapePainter({
    required this.sun,
    required this.sunY,
    required this.verticalBias,
  });

  Path _hill(Size size, double startY, List<Offset> points) {
    final path = Path()..moveTo(0, size.height * (startY + verticalBias));
    for (var i = 0; i < points.length; i += 3) {
      path.cubicTo(
        size.width * points[i].dx,
        size.height * (points[i].dy + verticalBias),
        size.width * points[i + 1].dx,
        size.height * (points[i + 1].dy + verticalBias),
        size.width * points[i + 2].dx,
        size.height * (points[i + 2].dy + verticalBias),
      );
    }
    return path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  void _plant(Canvas canvas, Size size, Offset base, double scale) {
    final stem = Paint()
      ..color = const Color(0xFF7E8766)
      ..strokeWidth = 1.4 * scale
      ..strokeCap = StrokeCap.round;
    final start = Offset(size.width * base.dx, size.height * base.dy);
    final top = start.translate(-7 * scale, -48 * scale);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        start.dx - 2 * scale,
        start.dy - 24 * scale,
        top.dx,
        top.dy,
      );
    canvas.drawPath(path, stem);
    for (var i = 0; i < 4; i++) {
      final t = .22 + i * .18;
      final center = Offset.lerp(start, top, t)!;
      final direction = i.isEven ? 1.0 : -1.0;
      final leaf = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
          center.dx + 9 * scale * direction,
          center.dy - 8 * scale,
          center.dx + 13 * scale * direction,
          center.dy - 2 * scale,
        )
        ..quadraticBezierTo(
          center.dx + 7 * scale * direction,
          center.dy + 4 * scale,
          center.dx,
          center.dy,
        )
        ..close();
      canvas.drawPath(leaf, Paint()..color = const Color(0xFF9DA582));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (sun) {
      canvas.drawCircle(
        Offset(size.width * .80, size.height * sunY),
        size.height * .10,
        Paint()..color = feltMustard,
      );
    }
    final layers = <(Color, Path)>[
      (
        feltClay,
        _hill(size, .57, const [
          Offset(.19, .34),
          Offset(.37, .48),
          Offset(.52, .56),
          Offset(.69, .66),
          Offset(.82, .35),
          Offset(1, .48),
        ]),
      ),
      (
        feltSage,
        _hill(size, .48, const [
          Offset(.17, .24),
          Offset(.33, .36),
          Offset(.49, .54),
          Offset(.67, .73),
          Offset(.78, .46),
          Offset(1, .58),
        ]),
      ),
      (
        feltBlue,
        _hill(size, .73, const [
          Offset(.18, .57),
          Offset(.36, .69),
          Offset(.54, .81),
          Offset(.72, .92),
          Offset(.88, .68),
          Offset(1, .72),
        ]),
      ),
      (
        feltMustard,
        _hill(size, .91, const [
          Offset(.18, .88),
          Offset(.35, .73),
          Offset(.54, .76),
          Offset(.72, .78),
          Offset(.88, .58),
          Offset(1, .66),
        ]),
      ),
    ];
    for (final layer in layers) {
      canvas.drawShadow(layer.$2, const Color(0x24342C27), 3, false);
      canvas.drawPath(layer.$2, Paint()..color = layer.$1);
      canvas.save();
      canvas.clipPath(layer.$2);
      const _FiberPainter(.07).paint(canvas, size);
      canvas.restore();
    }
    _plant(canvas, size, const Offset(.78, .67), size.height / 190);
    _plant(canvas, size, const Offset(.91, .63), size.height / 230);
  }

  @override
  bool shouldRepaint(covariant _LandscapePainter oldDelegate) =>
      oldDelegate.sun != sun ||
      oldDelegate.sunY != sunY ||
      oldDelegate.verticalBias != verticalBias;
}
