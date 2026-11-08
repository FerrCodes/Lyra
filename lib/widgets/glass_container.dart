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

  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 30,
    this.width,
    this.height,
    this.padding,
    this.blurSigma = 24,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colors.glassShadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.glassTintTop, colors.glassTintBottom],
              ),
            ),
            child: CustomPaint(
              painter: _GradientBorderPainter(
                radius: radius,
                topColor: colors.glassBorderTop,
                bottomColor: colors.glassBorderBottom,
              ),
              child: child,
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

  _GradientBorderPainter({
    required this.radius,
    required this.topColor,
    required this.bottomColor,
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
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter old) =>
      old.radius != radius ||
      old.topColor != topColor ||
      old.bottomColor != bottomColor;
}
