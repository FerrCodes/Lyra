import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const MarqueeText({super.key, required this.text, this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  final ScrollController _controller = ScrollController();
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loop());
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Lagu berganti: kembali ke awal
    if (oldWidget.text != widget.text && _controller.hasClients) {
      _controller.jumpTo(0);
    }
  }

  Future<void> _loop() async {
    if (_running) return;
    _running = true;
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2)); // diam di awal
      if (!mounted || !_controller.hasClients) continue;
      final max = _controller.position.maxScrollExtent;
      if (max <= 0) continue; // judul muat, tidak perlu jalan
      await _controller.animateTo(
        max,
        duration: Duration(milliseconds: (max * 25).round().clamp(1500, 20000)),
        curve: Curves.linear,
      );
      if (!mounted) break;
      await Future.delayed(const Duration(seconds: 1)); // diam di ujung
      if (!mounted || !_controller.hasClients) continue;
      _controller.jumpTo(0);
    }
    _running = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        maxLines: 1,
        softWrap: false,
        style: widget.style,
      ),
    );
  }
}
