import 'dart:async';
import '../database/database.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class LyraAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  LyraAudioHandler() {
    // Sinkronkan state just_audio ke audio_service.
    _player.playbackEventStream.listen(_broadcastState);
    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });
    _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        // 1. TAMBAHKAN TOMBOL NEXT DAN PREV DI SINI
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},

        // 2. BERI TAHU ANDROID UNTUK MENAMPILKAN KETIGA TOMBOL DI NOTIFIKASI
        androidCompactActionIndices: const [0, 1, 2],

        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  /// Memutar daftar lagu secara berurutan (Queue)
  Future<void> playQueue(List<Song> songs, int initialIndex) async {
    // 1. Ubah list lagu dari database menjadi MediaItem
    final mediaItems = songs
        .map(
          (s) => MediaItem(
            id: s.path,
            title: s.title,
            artist: s.artist,
            album: s.album,
            duration: Duration(milliseconds: s.durationMs),
          ),
        )
        .toList();

    // 2. Masukkan ke antrean audio_service
    queue.add(mediaItems);

    // ========================================================
    // 3. TAMBAHKAN BARIS INI (Ini yang tadi hilang!)
    // Memberitahu Mini Player lagu mana yang sedang diputar
    mediaItem.add(mediaItems[initialIndex]);
    // ========================================================

    // 4. Masukkan ke antrean just_audio
    final audioSources = songs.map((s) => AudioSource.file(s.path)).toList();
    await _player.setAudioSources(audioSources, initialIndex: initialIndex);

    // 5. Putar
    play();
  }

  /// Muat satu file audio lokal (dipanggil dari UI).
  Future<void> loadFile(String path, {String? title}) async {
    final item = MediaItem(
      id: path,
      title: title ?? path.split('/').last,
      album: 'Lyra',
      artist: 'Unknown',
    );
    mediaItem.add(item);
    queue.add([item]);

    await _player.setFilePath(path);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    // Biarkan playback tetap berjalan saat app dihapus dari Recent Apps.
    // Jangan panggil stop() di sini.
    super.onTaskRemoved();
  }

  Future<void> disposePlayer() async {
    await _player.dispose();
  }
}
