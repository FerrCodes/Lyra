import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show TickerCanceled;

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const MarqueeText({super.key, required this.text, this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  static const double _gap = 40.0;
  static const double _pixelsPerSecond = 35.0;
  static const Duration _startPause = Duration(milliseconds: 1300);

  late final AnimationController _animationController;

  bool _shouldAnimate = false;
  bool _syncScheduled = false;
  bool _pendingShouldAnimate = false;
  bool _forceRestart = false;
  double _travelDistance = 0;
  double _pendingTravelDistance = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      // Batalkan loop lama agar perubahan lagu tidak menjalankan dua animasi.
      _generation++;
      _animationController.stop();
      _forceRestart = true;
    }
  }

  void _scheduleAnimationSync({
    required bool shouldAnimate,
    required double travelDistance,
  }) {
    _pendingShouldAnimate = shouldAnimate;
    _pendingTravelDistance = travelDistance;

    if (_syncScheduled) return;
    _syncScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;

      final nextShouldAnimate = _pendingShouldAnimate;
      final nextTravelDistance = _pendingTravelDistance;
      final distanceChanged =
          (nextTravelDistance - _travelDistance).abs() > 0.5;
      final needsRestart =
          _forceRestart ||
          nextShouldAnimate != _shouldAnimate ||
          (nextShouldAnimate && distanceChanged);

      _forceRestart = false;
      _shouldAnimate = nextShouldAnimate;
      _travelDistance = nextTravelDistance;

      if (!needsRestart) return;

      final generation = ++_generation;
      _animationController.stop();
      _animationController.value = 0;

      if (_shouldAnimate) {
        _runMarqueeLoop(generation);
      }
    });
  }

  Future<void> _runMarqueeLoop(int generation) async {
    while (mounted && generation == _generation && _shouldAnimate) {
      await Future.delayed(_startPause);

      if (!mounted || generation != _generation || !_shouldAnimate) return;

      final distance = _travelDistance;
      if (distance <= 0) return;

      final durationMs = (distance / _pixelsPerSecond * 1000)
          .round()
          .clamp(1, 60000)
          .toInt();
      _animationController.duration = Duration(milliseconds: durationMs);

      try {
        await _animationController.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }

      if (!mounted || generation != _generation || !_shouldAnimate) return;

      // Salinan kedua berada tepat di posisi salinan pertama pada titik ini,
      // jadi reset ke nol tidak terlihat sebagai lompatan.
      _animationController.value = 0;
    }
  }

  @override
  void dispose() {
    _generation++;
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final defaultStyle = DefaultTextStyle.of(context).style;
        final effectiveStyle = widget.style == null
            ? defaultStyle
            : widget.style!.inherit
            ? defaultStyle.merge(widget.style)
            : widget.style!;
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
        )..layout();

        final hasBoundedWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite;
        final shouldAnimate =
            hasBoundedWidth && textPainter.width > constraints.maxWidth;
        final travelDistance = textPainter.width + _gap;

        _scheduleAnimationSync(
          shouldAnimate: shouldAnimate,
          travelDistance: travelDistance,
        );

        if (!shouldAnimate) {
          return Text(
            widget.text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }

        final repeatedText = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              style: widget.style,
            ),
            const SizedBox(width: _gap),
            Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              style: widget.style,
            ),
          ],
        );

        return SizedBox(
          width: constraints.maxWidth,
          height: textPainter.height,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _animationController,
              child: repeatedText,
              builder: (context, child) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(
                      -(_animationController.value * travelDistance),
                      0,
                    ),
                    // Row harus diukur selebar konten aslinya, bukan dibatasi
                    // selebar viewport. ClipRect di luar akan memotong bagian
                    // yang berada di luar area tampilan.
                    child: OverflowBox(
                      alignment: Alignment.centerLeft,
                      minWidth: 0,
                      maxWidth: double.infinity,
                      child: child,
                    ),
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
