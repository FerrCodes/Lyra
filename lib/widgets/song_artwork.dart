import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongArtwork extends StatefulWidget {
  final int id;
  final double size;
  final double radius;
  final Widget placeholder;

  const SongArtwork({
    super.key,
    required this.id,
    required this.placeholder,
    this.size = 50,
    this.radius = 8,
  });

  static final LinkedHashMap<int, Uint8List> _cache = LinkedHashMap();
  static final Map<int, Future<Uint8List>> _pending = {};

  static Future<Uint8List> _load(int id) {
    return _pending[id] ??= () async {
      Uint8List bytes = Uint8List(0); // kosong = tidak ada sampul
      try {
        final r = await OnAudioQuery().queryArtwork(
          id,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: 200,
        );
        if (r != null) bytes = r;
      } catch (_) {}
      _cache[id] = bytes;
      if (_cache.length > 400) _cache.remove(_cache.keys.first);
      _pending.remove(id);
      return bytes;
    }();
  }

  @override
  State<SongArtwork> createState() => _SongArtworkState();
}

class _SongArtworkState extends State<SongArtwork> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant SongArtwork old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) _resolve();
  }

  void _resolve() {
    final cached = SongArtwork._cache[widget.id];
    if (cached != null) {
      _bytes = cached; // langsung tampil, tanpa kedip
      return;
    }
    _bytes = null;
    final id = widget.id;
    SongArtwork._load(id).then((b) {
      if (mounted && widget.id == id) setState(() => _bytes = b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final has = bytes != null && bytes.isNotEmpty;
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: has
            ? Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: (widget.size * dpr).round(),
              )
            : widget.placeholder,
      ),
    );
  }
}
