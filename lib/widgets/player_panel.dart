import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../ui/player_page.dart';

// Mengatur posisi panel player penuh (0 = tersembunyi, 1 = terbuka penuh).
class PlayerPanelController {
  PlayerPanelController(TickerProvider vsync)
    : _controller = AnimationController(
        vsync: vsync,
        lowerBound: 0.0,
        upperBound: 1.0,
        value: 0.0,
      ) {
    _controller.addListener(_syncVisibility);
  }

  final AnimationController _controller;

  // true selama panel terlihat sedikit pun (dipakai untuk Offstage dan tombol back).
  final ValueNotifier<bool> isVisible = ValueNotifier<bool>(false);

  Animation<double> get animation => _controller;
  double get value => _controller.value;

  static final SpringDescription _spring = SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 400.0,
    ratio: 1.0,
  );

  void _syncVisibility() {
    final visible = _controller.value > 0.002;
    if (visible != isVisible.value) isVisible.value = visible;
  }

  void open() => _springTo(1.0, 0.0);
  void close() => _springTo(0.0, 0.0);

  // Panel mengikuti jari. fraction positif = membuka.
  void dragBy(double fraction) {
    _controller.stop();
    _controller.value = (_controller.value + fraction)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  // Dipanggil saat jari dilepas. velocityY dalam px/detik, negatif = ke atas.
  // opening = true  -> gesture berasal dari mini player
  // opening = false -> gesture berasal dari panel player
  void settle(
    double velocityY, {
    required bool opening,
    required double screenHeight,
  }) {
    final v = _controller.value;
    final bool open;
    if (velocityY < -300) {
      open = true; // sentakan ke atas
    } else if (velocityY > 300) {
      open = false; // sentakan ke bawah
    } else if (opening) {
      open = v > 0.05; // dari mini player: lepas di mana pun = buka
    } else {
      open = v > 0.95; // dari panel: lepas di mana pun = tutup
    }
    _springTo(open ? 1.0 : 0.0, -velocityY / screenHeight);
  }

  void _springTo(double target, double velocity) {
    final from = _controller.value;
    if ((target - from) * velocity < 0) velocity = 0.0;
    if ((target - from).abs() < 0.0005 && velocity.abs() < 0.01) {
      _controller.value = target;
      return;
    }
    _controller.animateWith(SpringSimulation(_spring, from, target, velocity));
  }

  void dispose() {
    _controller.removeListener(_syncVisibility);
    _controller.dispose();
    isVisible.dispose();
  }
}

// Panel player penuh: lapisan paling atas di Stack HomePage.
class PlayerPanel extends StatelessWidget {
  const PlayerPanel({super.key, required this.controller});

  final PlayerPanelController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isVisible,
      builder: (context, visible, child) => Offstage(
        offstage: !visible,
        child: TickerMode(enabled: visible, child: child!),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(controller.animation),
        child: RepaintBoundary(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (d) {
              final h = MediaQuery.of(context).size.height;
              controller.dragBy(-d.delta.dy / h);
            },
            onVerticalDragEnd: (d) => controller.settle(
              d.velocity.pixelsPerSecond.dy,
              opening: false,
              screenHeight: MediaQuery.of(context).size.height,
            ),
            onVerticalDragCancel: () => controller.settle(
              0,
              opening: false,
              screenHeight: MediaQuery.of(context).size.height,
            ),
            child: PlayerPage(onClose: controller.close),
          ),
        ),
      ),
    );
  }
}
