import 'package:flutter/material.dart';

import 'felt_ui.dart';

const feltTextureAsset = 'assets/images/felt-pressed-neutral-v2.png';
const feltCardSurfaceAsset = 'assets/images/felt-card-surface-v1.png';
const materialLandscapeAsset = 'assets/images/material-story-landscape-v1.png';
const materialIvoryAsset = 'assets/images/material-ivory-botanical-v1.png';
const materialBlueAsset = 'assets/images/material-blue-botanical-v1.png';
const materialSageAsset = 'assets/images/material-sage-botanical-v1.png';
const materialClayAsset = 'assets/images/material-clay-botanical-v1.png';
const materialMustardAsset = 'assets/images/material-mustard-geometric-v1.png';
const materialForestAsset = 'assets/images/material-forest-botanical-v1.png';

class AssetMaterialBackdrop extends StatelessWidget {
  final Widget child;

  const AssetMaterialBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ColoredBox(color: feltCream),
      Opacity(
        opacity: .26,
        child: Image.asset(
          materialIvoryAsset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
      child,
    ],
  );
}

class AssetFeltSurface extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double depth;
  final double textureOpacity;
  final bool showHighlightBorder;
  final String? surfaceAsset;
  final BoxFit surfaceFit;
  final AlignmentGeometry surfaceAlignment;
  final VoidCallback? onTap;

  const AssetFeltSurface({
    super.key,
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.depth = 2.5,
    this.textureOpacity = .96,
    this.showHighlightBorder = true,
    this.surfaceAsset,
    this.surfaceFit = BoxFit.cover,
    this.surfaceAlignment = Alignment.center,
    this.onTap,
  });

  BoxDecoration surfaceDecoration(Color surfaceColor, {bool edge = false}) =>
      BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radius),
        border: edge || !showHighlightBorder
            ? null
            : Border.all(color: Colors.white.withValues(alpha: .62)),
        image: edge
            ? DecorationImage(
                image: const AssetImage(feltTextureAsset),
                fit: BoxFit.cover,
                opacity: .64,
                colorFilter: ColorFilter.mode(surfaceColor, BlendMode.modulate),
                filterQuality: FilterQuality.low,
              )
            : null,
        boxShadow: edge
            ? null
            : const [
                BoxShadow(
                  color: Color(0x283B312B),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0x50FFFFFF),
                  blurRadius: 2,
                  offset: Offset(0, -1),
                ),
              ],
      );

  @override
  Widget build(BuildContext context) {
    final edgeColor = Color.lerp(color, feltInk, .07)!;
    final card = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 1,
          right: 1,
          top: depth,
          bottom: -depth,
          child: DecoratedBox(
            decoration: surfaceDecoration(edgeColor, edge: true),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: surfaceDecoration(color),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: textureOpacity,
                    child: surfaceAsset == null
                        ? Transform.scale(
                            scale: 1.12,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                color,
                                BlendMode.modulate,
                              ),
                              child: Image.asset(
                                feltCardSurfaceAsset,
                                fit: BoxFit.cover,
                                alignment: const Alignment(0, .12),
                                filterQuality: FilterQuality.low,
                              ),
                            ),
                          )
                        : Image.asset(
                            surfaceAsset!,
                            fit: surfaceFit,
                            alignment: surfaceAlignment,
                            filterQuality: FilterQuality.medium,
                          ),
                  ),
                ),
                if (surfaceAsset == null)
                  Positioned.fill(
                    child: FeltTextureOverlay(
                      borderRadius: BorderRadius.circular(radius),
                      opacity: .30,
                    ),
                  ),
                Padding(padding: padding, child: child),
              ],
            ),
          ),
        ),
      ],
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

class AssetFeltIconTile extends StatelessWidget {
  final IconData icon;
  final Widget? glyph;
  final Color color;
  final double size;
  final bool selected;
  final String? surfaceAsset;
  final String? selectedSurfaceAsset;

  const AssetFeltIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.glyph,
    this.size = 48,
    this.selected = false,
    this.surfaceAsset,
    this.selectedSurfaceAsset,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = selected ? feltForest : color;
    final glyphColor = selected ? feltIvory : feltInk;
    final asset = selected
        ? selectedSurfaceAsset ?? surfaceAsset
        : surfaceAsset;
    final radius = size * .24;
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x30382F2A),
              blurRadius: 5,
              spreadRadius: -1,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: Color(0x66FFFFFF),
              blurRadius: 2,
              spreadRadius: -1,
              offset: Offset(-1, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: tileColor),
              if (asset != null)
                Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                ),
              CustomPaint(painter: _SquareBevelPainter(radius)),
              Center(
                child:
                    glyph ??
                    Icon(
                      icon,
                      size: size * .44,
                      color: glyphColor,
                      weight: 200,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareBevelPainter extends CustomPainter {
  final double radius;

  const _SquareBevelPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final borderRect = rect.deflate(.75);
    final rrect = RRect.fromRectAndRadius(
      borderRect,
      Radius.circular((radius - .75).clamp(0, radius)),
    );
    final bevel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xB3FFFFFF), Color(0x24FFFFFF), Color(0x520F1F1A)],
        stops: [0, .48, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, bevel);

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6
      ..color = const Color(0x38FFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(2),
        Radius.circular((radius - 2).clamp(0, radius)),
      ),
      inner,
    );
  }

  @override
  bool shouldRepaint(covariant _SquareBevelPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

class FlatSpeechGlyph extends StatelessWidget {
  final Color color;
  final double size;

  const FlatSpeechGlyph({super.key, this.color = feltInk, this.size = 21});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _FlatSpeechGlyphPainter(color),
  );
}

class FeltTextureOverlay extends StatelessWidget {
  final BorderRadius borderRadius;
  final double opacity;

  const FeltTextureOverlay({
    super.key,
    this.borderRadius = BorderRadius.zero,
    this.opacity = .55,
  });

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ClipRRect(
      borderRadius: borderRadius,
      child: Opacity(
        opacity: opacity,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            2.4,
            0,
            0,
            0,
            -329,
            0,
            2.4,
            0,
            0,
            -329,
            0,
            0,
            2.4,
            0,
            -329,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: Image.asset(
            feltTextureAsset,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
          ),
        ),
      ),
    ),
  );
}

class _FlatSpeechGlyphPainter extends CustomPainter {
  final Color color;
  const _FlatSpeechGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bubble = Path()
      ..moveTo(size.width * .23, size.height * .22)
      ..quadraticBezierTo(
        size.width * .12,
        size.height * .22,
        size.width * .12,
        size.height * .34,
      )
      ..lineTo(size.width * .12, size.height * .63)
      ..quadraticBezierTo(
        size.width * .12,
        size.height * .75,
        size.width * .25,
        size.height * .75,
      )
      ..lineTo(size.width * .34, size.height * .75)
      ..lineTo(size.width * .27, size.height * .89)
      ..lineTo(size.width * .46, size.height * .75)
      ..lineTo(size.width * .76, size.height * .75)
      ..quadraticBezierTo(
        size.width * .88,
        size.height * .75,
        size.width * .88,
        size.height * .63,
      )
      ..lineTo(size.width * .88, size.height * .34)
      ..quadraticBezierTo(
        size.width * .88,
        size.height * .22,
        size.width * .76,
        size.height * .22,
      )
      ..close();
    canvas.drawPath(bubble, stroke);
    final dots = Paint()..color = color;
    for (final x in const [.38, .50, .62]) {
      canvas.drawCircle(Offset(size.width * x, size.height * .49), 1.15, dots);
    }
  }

  @override
  bool shouldRepaint(covariant _FlatSpeechGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
