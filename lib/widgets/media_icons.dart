import 'package:flutter/material.dart';

class CustomShuffleIcon extends StatelessWidget {
  final Color color;
  final bool isOn;
  const CustomShuffleIcon({super.key, required this.color, required this.isOn});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _ShufflePainter(color: color, isOn: isOn),
    );
  }
}

class _ShufflePainter extends CustomPainter {
  final Color color;
  final bool isOn;
  _ShufflePainter({required this.color, required this.isOn});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Skala ukuran asli 24x24 ke ukuran widget
    canvas.scale(size.width / 24, size.height / 24);

    if (isOn) {
      final fillPaint = Paint()..color = color;
      final path = Path()
        ..moveTo(10.59, 9.17)
        ..lineTo(5.41, 4)
        ..lineTo(4, 5.41)
        ..lineTo(9.17, 10.58)
        ..close()
        ..moveTo(14.5, 4)
        ..lineTo(16.54, 6.04)
        ..lineTo(4, 18.59)
        ..lineTo(5.41, 20)
        ..lineTo(17.96, 7.46)
        ..lineTo(20, 9.5)
        ..lineTo(20, 4)
        ..close()
        ..moveTo(14.83, 13.41)
        ..lineTo(13.42, 14.82)
        ..lineTo(16.55, 17.95)
        ..lineTo(14.5, 20)
        ..lineTo(20, 20)
        ..lineTo(20, 14.5)
        ..lineTo(17.96, 16.54)
        ..close();
      canvas.drawPath(path, fillPaint);
    } else {
      // Garis lengkung
      final path1 = Path()
        ..moveTo(3, 7)
        ..lineTo(6.5, 7)
        ..cubicTo(8.5, 7, 9.7, 8, 10.8, 9.6)
        ..lineTo(13.2, 13.4)
        ..cubicTo(14.3, 15, 15.5, 16, 17.5, 16)
        ..lineTo(21, 16);
      canvas.drawPath(path1, paint);

      final path2 = Path()
        ..moveTo(3, 17)
        ..lineTo(6.5, 17)
        ..cubicTo(7.7, 17, 8.6, 16.6, 9.4, 15.9);
      canvas.drawPath(path2, paint);

      final path3 = Path()
        ..moveTo(14.6, 8.1)
        ..cubicTo(15.4, 7.4, 16.4, 7, 17.6, 7)
        ..lineTo(21, 7);
      canvas.drawPath(path3, paint);

      // Panah
      final arrow1 = Path()
        ..moveTo(18.5, 4.5)
        ..lineTo(21, 7)
        ..lineTo(18.5, 9.5);
      canvas.drawPath(arrow1, paint);

      final arrow2 = Path()
        ..moveTo(18.5, 14.5)
        ..lineTo(21, 17)
        ..lineTo(18.5, 19.5);
      canvas.drawPath(arrow2, paint);

      // Garis miring silang
      final cross = Path()
        ..moveTo(4.5, 4)
        ..lineTo(19.5, 20);
      canvas.drawPath(cross, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShufflePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isOn != isOn;
}

// ============================================================================

class CustomRepeatIcon extends StatelessWidget {
  final Color color;
  final bool isAll;
  final bool isOne;
  const CustomRepeatIcon({
    super.key,
    required this.color,
    required this.isAll,
    required this.isOne,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _RepeatPainter(color: color, isAll: isAll, isOne: isOne),
    );
  }
}

class _RepeatPainter extends CustomPainter {
  final Color color;
  final bool isAll;
  final bool isOne;
  _RepeatPainter({
    required this.color,
    required this.isAll,
    required this.isOne,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.scale(size.width / 24, size.height / 24);

    if (!isAll && !isOne) {
      // Mode Mati (Off)
      final numPaint = Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final p1 = Path()
        ..moveTo(7, 13)
        ..lineTo(9.5, 6.5)
        ..lineTo(12, 13);
      canvas.drawPath(p1, numPaint);

      final p2 = Path()
        ..moveTo(8, 11)
        ..lineTo(11, 11);
      canvas.drawPath(p2, numPaint);

      final p3 = Path()
        ..moveTo(5, 17)
        ..lineTo(19, 17);
      canvas.drawPath(p3, paint);

      final p4 = Path()
        ..moveTo(16, 14)
        ..lineTo(19, 17)
        ..lineTo(16, 20);
      canvas.drawPath(p4, paint);
    } else {
      // Mode Loop
      final loopPath = Path()
        ..moveTo(4, 11)
        ..lineTo(4, 9)
        ..cubicTo(4, 7.3, 5.3, 6, 7, 6)
        ..lineTo(19, 6)
        ..moveTo(16.5, 3.5)
        ..lineTo(19, 6)
        ..lineTo(16.5, 8.5)
        ..moveTo(20, 13)
        ..lineTo(20, 15)
        ..cubicTo(20, 16.7, 18.7, 18, 17, 18)
        ..lineTo(5, 18)
        ..moveTo(7.5, 15.5)
        ..lineTo(5, 18)
        ..lineTo(7.5, 20.5);
      canvas.drawPath(loopPath, paint);

      final innerPaint = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (isAll) {
        // Mode All ('A')
        final aPath = Path()
          ..moveTo(9.8, 15)
          ..lineTo(12, 9.5)
          ..lineTo(14.2, 15)
          ..moveTo(10.7, 13)
          ..lineTo(13.3, 13);
        canvas.drawPath(aPath, innerPaint);
      } else {
        // Mode One ('1')
        final onePath = Path()
          ..moveTo(11, 10.8)
          ..lineTo(12.6, 9.6)
          ..lineTo(12.6, 15);
        canvas.drawPath(onePath, innerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RepeatPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isAll != isAll ||
      oldDelegate.isOne != isOne;
}
