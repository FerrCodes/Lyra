import 'dart:async';
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
  final Duration loadDelay;

  const SongArtwork({
    super.key,
    required this.id,
    required this.placeholder,
    this.size = 50,
    this.radius = 8,
    this.loadSize = 200,
    this.loadDelay = Duration.zero,
  });

  static final LinkedHashMap<String, Uint8List> _small = LinkedHashMap();
  static final LinkedHashMap<String, Uint8List> _large = LinkedHashMap();
  static final Map<String, Future<Uint8List>> _pending = {};
  static final OnAudioQuery _audioQuery = OnAudioQuery();
  static String _key(int id, int loadSize) => '$id@$loadSize';
  static LinkedHashMap<String, Uint8List> _cacheFor(int loadSize) =>
      loadSize > 400 ? _large : _small;

  static final Queue<int> _warmQueue = Queue<int>();
  static bool _isWarming = false;

  /// Pre-load artwork bytes ke cache statis secara bertahap (maks 2 paralel)
  /// agar tidak membanjiri MethodChannel / Android MediaStore saat daftar
  /// lagu panjang dimuat.
  static void warmCacheAll(Iterable<int> ids, {int loadSize = 200}) {
    final cache = _cacheFor(loadSize);
    for (final id in ids) {
      if (id == 0) continue;
      final key = _key(id, loadSize);
      if (cache.containsKey(key) || _pending.containsKey(key)) continue;
      if (_warmQueue.length >= 200) break;
      _warmQueue.add(id);
    }
    if (_isWarming || _warmQueue.isEmpty) return;
    _drainWarmQueue(loadSize);
  }

  static Future<void> _drainWarmQueue(int loadSize) async {
    _isWarming = true;
    try {
      while (_warmQueue.isNotEmpty) {
        final batch = <Future<Uint8List>>[];
        for (int i = 0; i < 2 && _warmQueue.isNotEmpty; i++) {
          final id = _warmQueue.removeFirst();
          final key = _key(id, loadSize);
          if (!_cacheFor(loadSize).containsKey(key)) {
            batch.add(_load(id, loadSize));
          }
        }
        if (batch.isNotEmpty) {
          await Future.wait(batch);
          // Beri jeda singkat agar event loop tetap responsif untuk frame scroll
          await Future<void>.delayed(const Duration(milliseconds: 8));
        }
      }
    } finally {
      _isWarming = false;
    }
  }

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
  Timer? _loadTimer;

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
    _loadTimer?.cancel();

    if (widget.id == 0) {
      _bytes = null;
      return;
    }

    final key = SongArtwork._key(widget.id, widget.loadSize);
    final cached = SongArtwork._cacheFor(widget.loadSize)[key];
    if (cached != null) {
      _bytes = cached;
      return;
    }

    final id = widget.id;
    final loadSize = widget.loadSize;

    void start() {
      SongArtwork._load(id, loadSize).then((b) {
        if (mounted && widget.id == id && widget.loadSize == loadSize) {
          setState(() => _bytes = b);
        }
      });
    }

    if (widget.loadDelay == Duration.zero) {
      start();
    } else {
      _loadTimer = Timer(widget.loadDelay, start);
    }
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final has = bytes != null && bytes.isNotEmpty;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final targetCacheWidth = widget.size.isFinite
        ? (widget.size * dpr).round()
        : (widget.loadSize > 0 ? widget.loadSize : 200);

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
                cacheWidth: targetCacheWidth,
              )
            : widget.placeholder,
      ),
    );
  }
}
