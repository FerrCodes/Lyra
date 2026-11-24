import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongArtwork extends StatefulWidget {
  final int id;
  final double size;
  final double radius;
  final int loadSize;
  final Widget placeholder;

  const SongArtwork({
    super.key,
    required this.id,
    required this.placeholder,
    this.size = 50,
    this.radius = 8,
    this.loadSize = 200,
  });

  static final LinkedHashMap<String, Uint8List> _small = LinkedHashMap();
  static final LinkedHashMap<String, Uint8List> _large = LinkedHashMap();
  static final Map<String, Future<Uint8List>> _pending = {};
  static final OnAudioQuery _audioQuery = OnAudioQuery();
  static String _key(int id, int loadSize) => '$id@$loadSize';
  static LinkedHashMap<String, Uint8List> _cacheFor(int loadSize) =>
      loadSize > 400 ? _large : _small;

  static Future<Uint8List> _load(int id, int loadSize) {
    final key = _key(id, loadSize);
    return _pending[key] ??= () async {
      Uint8List bytes = Uint8List(0); // kosong = tidak ada sampul
      try {
        final r = await _audioQuery.queryArtwork(
          id,
          ArtworkType.AUDIO,
          format: ArtworkFormat.JPEG,
          size: loadSize,
        );
        if (r != null) bytes = r;
      } catch (_) {}
      final cache = _cacheFor(loadSize);
      cache[key] = bytes;
      final limit = loadSize > 400 ? 12 : 400;
      if (cache.length > limit) cache.remove(cache.keys.first);
      _pending.remove(key);
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
    if (old.id != widget.id || old.loadSize != widget.loadSize) _resolve();
  }

  void _resolve() {
    final key = SongArtwork._key(widget.id, widget.loadSize);
    final cached = SongArtwork._cacheFor(widget.loadSize)[key];
    if (cached != null) {
      _bytes = cached;
      return;
    }
    // _bytes lama sengaja dipertahankan sampai gambar baru siap (tanpa kedip)
    final id = widget.id;
    final loadSize = widget.loadSize;
    SongArtwork._load(id, loadSize).then((b) {
      if (mounted && widget.id == id && widget.loadSize == loadSize) {
        setState(() => _bytes = b);
      }
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
                cacheWidth: widget.size.isFinite
                    ? (widget.size * dpr).round()
                    : null,
              )
            : widget.placeholder,
      ),
    );
  }
}
