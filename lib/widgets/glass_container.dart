import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/lyra_colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final double? tintOpacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 30,
    this.width,
    this.height,
    this.padding,
    this.blurSigma = 24,
    this.tintOpacity,
  });

  Widget _maybeBlur(Widget child) {
    if (blurSigma <= 0) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;

    return RepaintBoundary(
      child: CustomPaint(
        painter: _OuterShadowPainter(radius: radius, color: colors.glassShadow),
        child: SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: ClipRect(
              child: _maybeBlur(
                Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        tintOpacity != null
                            ? colors.glassTintTop.withValues(
                                alpha: tintOpacity!,
                              )
                            : colors.glassTintTop,
                        tintOpacity != null
                            ? colors.glassTintBottom.withValues(
                                alpha: tintOpacity!,
                              )
                            : colors.glassTintBottom,
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    painter: _GradientBorderPainter(
                      radius: radius,
                      topColor: colors.glassBorderTop,
                      bottomColor: colors.glassBorderBottom,
                      highlightColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double radius;
  final Color topColor;
  final Color bottomColor;
  final Color highlightColor;
  _GradientBorderPainter({
    required this.radius,
    required this.topColor,
    required this.bottomColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius - 0.5)),
      paint,
    );

    // Kilau tipis di dalam tepi atas (efek specular)
    /*
    final inner = rect.deflate(1.0);
    final highlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [highlightColor, highlightColor.withValues(alpha: 0)],
        stops: const [0.0, 0.5],
      ).createShader(inner)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, Radius.circular(radius - 1.5)),
      highlight,
    );
    */
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter old) =>
      old.radius != radius ||
      old.topColor != topColor ||
      old.bottomColor != bottomColor ||
      old.highlightColor != highlightColor;
}

// Bayangan hanya di luar bentuk kaca, supaya tidak tembus ke isi kaca.
class _OuterShadowPainter extends CustomPainter {
  final double radius;
  final Color color;

  _OuterShadowPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTRB(-300, -300, size.width + 300, size.height + 300))
      ..addRRect(rrect);

    canvas.save();
    canvas.clipPath(outside);
    canvas.drawRRect(
      rrect.shift(const Offset(0, 8)),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.4),
    );
    canvas.drawRRect(
      rrect.shift(const Offset(0, 1)),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OuterShadowPainter old) =>
      old.radius != radius || old.color != color;
}
