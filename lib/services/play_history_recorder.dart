import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../main.dart';
import '../providers/songs_provider.dart';

class PlayHistoryRecorder {
  final AppDatabase _db;
  final WidgetRef _ref;
  StreamSubscription<MediaItem?>? _mediaItemSub;
  Timer? _timer;
  String? _currentId;
  bool _disposed = false;

  PlayHistoryRecorder(this._db, this._ref);

  void start() {
    _mediaItemSub = audioHandler.mediaItem.listen(_onMediaItemChanged);
  }

  void _onMediaItemChanged(MediaItem? item) {
    if (item == null) return;

    // Dedup berdasarkan ID. Stream audio_service juga emit saat durasi/sampul berubah.
    if (_currentId == item.id) return;

    _currentId = item.id;
    _timer?.cancel();

    // Mulai timer 15 detik
    _timer = Timer(const Duration(seconds: 15), () {
      final currentState = audioHandler.playbackState.value;
      if (currentState.playing && _currentId == item.id) {
        _recordPlay(item);
      }
    });
  }

  Future<void> _recordPlay(MediaItem item) async {
    if (_disposed) return;

    String songId = '';
    try {
      final allSongs = _ref.read(allSongsProvider).value ?? [];
      // item.id di LyraAudioHandler adalah path lagu
      final localSong = allSongs.firstWhere((s) => s.path == item.id);
      songId = localSong.id;
    } catch (_) {
      // Jika tidak ditemukan di MediaStore, biarkan songId kosong
    }

    final albumId = item.extras?['albumId']?.toString() ?? '0';

    await _db.recordPlay(
      path: item.id,
      songId: songId,
      title: item.title,
      artist: item.artist ?? 'Unknown Artist',
      album: item.album ?? 'Unknown Album',
      albumId: albumId,
      durationMs: item.duration?.inMilliseconds ?? 0,
    );
  }

  void dispose() {
    _disposed = true;
    _mediaItemSub?.cancel();
    _timer?.cancel();
  }
}
