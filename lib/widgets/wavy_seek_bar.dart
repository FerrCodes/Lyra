import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WavySeekBar extends StatefulWidget {
  final double progress;
  final Duration duration; // <-- TAMBAHAN
  final ValueChanged<double> onSeek;
  final bool isPlaying;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final Color thumbInnerColor;

  const WavySeekBar({
    super.key,
    required this.progress,
    required this.duration, // <-- TAMBAHAN
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
  late AnimationController _interactionController;
  double? _dragProgress;

  @override
  void initState() {
    super.initState();
    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _interactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
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
    _interactionController.dispose();
    super.dispose();
  }

  void _startDrag(double dx, double width) {
    HapticFeedback.selectionClick(); // Getar halus
    setState(() {
      _dragProgress = (dx / width).clamp(0.0, 1.0);
    });
    _interactionController.forward();
  }

  void _updateDrag(double dx, double width) {
    setState(() {
      _dragProgress = (dx / width).clamp(0.0, 1.0);
    });
  }

  void _endDrag() {
    final targetProgress = _dragProgress ?? widget.progress;
    widget.onSeek(targetProgress);

    _interactionController.reverse();

    // Optimistic Progress: Tahan jarum selama 500ms agar audio sempat menyusul
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _dragProgress = null;
        });
      }
    });
  }

  void _cancelDrag() {
    setState(() {
      _dragProgress = null;
    });
    _interactionController.reverse();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentProgress = _dragProgress ?? widget.progress;
        final width = constraints.maxWidth;

        final thumbX = width * currentProgress;
        final previewTime = widget.duration * currentProgress;

        return GestureDetector(
          onHorizontalDragStart: (d) => _startDrag(d.localPosition.dx, width),
          onHorizontalDragUpdate: (d) => _updateDrag(d.localPosition.dx, width),
          onHorizontalDragEnd: (_) => _endDrag(),
          onHorizontalDragCancel: _cancelDrag,
          onTapDown: (d) => _startDrag(d.localPosition.dx, width),
          onTapUp: (_) => _endDrag(),
          onTapCancel: _cancelDrag,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // GELOMBANG ASLI (Tidak diubah sama sekali)
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _phaseController,
                    _interactionController,
                  ]),
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(width, 40),
                      painter: _WavyPainter(
                        progress: currentProgress,
                        phase: _phaseController.value,
                        interactionValue: _interactionController.value,
                        activeColor: widget.activeColor,
                        inactiveColor: widget.inactiveColor,
                        thumbColor: widget.thumbColor,
                        thumbInnerColor: widget.thumbInnerColor,
                      ),
                    );
                  },
                ),
              ),

              // TIME PREVIEW MELAYANG
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: (thumbX - 30).clamp(0.0, width - 60),
                top: _dragProgress != null ? -30 : -20,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _dragProgress != null ? 1.0 : 0.0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      scale: _dragProgress != null ? 1.0 : 0.5,
                      child: Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.activeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDuration(previewTime),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WavyPainter extends CustomPainter {
  final double progress;
  final double phase;
  final double interactionValue;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final Color thumbInnerColor;

  _WavyPainter({
    required this.progress,
    required this.phase,
    required this.interactionValue,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.thumbInnerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final trackHeight = 3.0;

    // Konfigurasi Gelombang ASLI
    final maxAmplitude = 2.5;
    final waveLength = 48.0;
    final taperDistance = 64.0;

    // Hanya mendatar jika sedang ditarik (interactionValue == 1)
    final currentAmplitude = maxAmplitude * (1.0 - interactionValue);

    // Animasi Thumb ASLI
    final baseThumbSize = 14.0;
    final thumbCurrentWidth = lerpDouble(
      baseThumbSize,
      trackHeight * 1.2,
      interactionValue,
    )!;
    final thumbCurrentHeight = lerpDouble(
      baseThumbSize,
      20.0,
      interactionValue,
    )!;

    double thumbX = size.width * progress;
    double thumbY = centerY;

    // 1. Garis Inactive
    if (thumbX < size.width) {
      final paintInactive = Paint()
        ..color = inactiveColor
        ..strokeWidth = trackHeight
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(thumbX, centerY),
        Offset(size.width, centerY),
        paintInactive,
      );
    }

    // 2. Gelombang Active
    if (thumbX > 0) {
      final paintActive = Paint()
        ..shader = LinearGradient(
          colors: [activeColor.withValues(alpha: 0.35), activeColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(0, 0, thumbX, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackHeight
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final pathActive = Path();
      final samplesPerCycle = 20.0;
      final periodPx = waveLength;
      final waveStep = (periodPx / samplesPerCycle).clamp(1.2, trackHeight);

      double yAt(double x) {
        final s = math.sin(
          (x / waveLength) * 2 * math.pi + phase * 2 * math.pi,
        );
        final taper = (x / taperDistance).clamp(0.0, 1.0);
        final finalAmp = currentAmplitude * taper;
        return centerY + finalAmp * s;
      }

      double prevX = 0;
      double prevY = yAt(prevX);
      pathActive.moveTo(prevX, prevY);

      double x = prevX + waveStep;
      while (x < thumbX) {
        final y = yAt(x);
        final mX = (prevX + x) * 0.5;
        final mY = (prevY + y) * 0.5;
        pathActive.quadraticBezierTo(prevX, prevY, mX, mY);
        prevX = x;
        prevY = y;
        x += waveStep;
      }

      final endY = yAt(thumbX);
      pathActive.quadraticBezierTo(prevX, prevY, thumbX, endY);
      thumbY = endY;

      canvas.drawPath(pathActive, paintActive);
    }

    // 3. Thumb Utama (Kapsul)
    final paintThumb = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;
    final rRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(thumbX, thumbY),
        width: thumbCurrentWidth,
        height: thumbCurrentHeight,
      ),
      Radius.circular(thumbCurrentWidth / 2),
    );
    canvas.drawRRect(rRect, paintThumb);

    // 4. Inner Highlight (Saran GPT: Titik tengah yang kontras)
    final paintInner = Paint()
      ..color = thumbInnerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(thumbX, thumbY), 3.0, paintInner);
  }

  @override
  bool shouldRepaint(covariant _WavyPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.interactionValue != interactionValue ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.thumbColor != thumbColor ||
        oldDelegate.thumbInnerColor != thumbInnerColor;
  }
}
