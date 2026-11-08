import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

class WavySeekBar extends StatefulWidget {
  final double progress;
  final ValueChanged<double> onSeek;
  final bool isPlaying;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final Color thumbInnerColor;

  const WavySeekBar({
    super.key,
    required this.progress,
    required this.onSeek,
    required this.isPlaying,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.thumbInnerColor,
  });

  @override
  State<WavySeekBar> createState() => _WavySeekBarState();
}

class _WavySeekBarState extends State<WavySeekBar>
    with TickerProviderStateMixin {
  late AnimationController _phaseController;
  late AnimationController _dragController;
  double? _dragProgress;

  @override
  void initState() {
    super.initState();
    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _updatePlayState();
  }

  @override
  void didUpdateWidget(covariant WavySeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      _updatePlayState();
    }
  }

  void _updatePlayState() {
    if (widget.isPlaying) {
      _phaseController.repeat();
    } else {
      _phaseController.stop();
    }
  }

  @override
  void dispose() {
    _phaseController.dispose();
    _dragController.dispose();
    super.dispose();
  }

  void _startDrag(double dx, double width) {
    setState(() {
      _dragProgress = (dx / width).clamp(0.0, 1.0);
    });
    _dragController.forward();
  }

  void _updateDrag(double dx, double width) {
    setState(() {
      _dragProgress = (dx / width).clamp(0.0, 1.0);
    });
  }

  void _endDrag() {
    widget.onSeek(_dragProgress ?? widget.progress);
    setState(() {
      _dragProgress = null;
    });
    _dragController.reverse();
  }

  void _cancelDrag() {
    setState(() {
      _dragProgress = null;
    });
    _dragController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentProgress = _dragProgress ?? widget.progress;

        return GestureDetector(
          onHorizontalDragStart: (d) =>
              _startDrag(d.localPosition.dx, constraints.maxWidth),
          onHorizontalDragUpdate: (d) =>
              _updateDrag(d.localPosition.dx, constraints.maxWidth),
          onHorizontalDragEnd: (_) => _endDrag(),
          onHorizontalDragCancel: _cancelDrag,
          onTapDown: (d) =>
              _startDrag(d.localPosition.dx, constraints.maxWidth),
          onTapUp: (_) => _endDrag(),
          onTapCancel: _cancelDrag,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_phaseController, _dragController]),
              builder: (context, child) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, 40),
                  painter: _WavyPainter(
                    progress: currentProgress,
                    phase: _phaseController.value,
                    dragAnimValue: _dragController.value,
                    activeColor: widget.activeColor,
                    inactiveColor: widget.inactiveColor,
                    thumbColor: widget.thumbColor,
                    thumbInnerColor: widget.thumbInnerColor,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _WavyPainter extends CustomPainter {
  final double progress;
  final double phase;
  final double dragAnimValue;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final Color thumbInnerColor;

  _WavyPainter({
    required this.progress,
    required this.phase,
    required this.dragAnimValue,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.thumbInnerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Animasi amplitudo (6 -> 2) dan radius (7 -> 9)
    final waveHeight = lerpDouble(6.0, 2.0, dragAnimValue)!;
    final thumbRadius = lerpDouble(7.0, 9.0, dragAnimValue)!;

    final paintInactive = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintActive = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final pathInactive = Path();
    final pathActive = Path();

    final waveLength = 20.0;
    final centerY = size.height / 2;

    double thumbX = size.width * progress;
    double thumbY = centerY;

    for (double x = 0; x <= size.width; x++) {
      double y =
          centerY +
          math.sin((x / waveLength) * 2 * math.pi + phase * 2 * math.pi) *
              waveHeight;

      if (x == 0) {
        pathInactive.moveTo(x, y);
        pathActive.moveTo(x, y);
      } else {
        pathInactive.lineTo(x, y);
        if (x <= thumbX) {
          pathActive.lineTo(x, y);
          thumbY = y;
        }
      }
    }

    canvas.drawPath(pathInactive, paintInactive);
    canvas.drawPath(pathActive, paintActive);

    final paintThumb = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(thumbX, thumbY), thumbRadius, paintThumb);

    final paintThumbInner = Paint()
      ..color = thumbInnerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(thumbX, thumbY), 2.5, paintThumbInner);
  }

  @override
  bool shouldRepaint(covariant _WavyPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.dragAnimValue != dragAnimValue ||
        oldDelegate.activeColor != activeColor;
  }
}
