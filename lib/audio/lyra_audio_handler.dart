import 'dart:async';
import '../database/database.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class LyraAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // Tambahkan variabel Future ini
  late final Future<void> _sessionInitFuture;

  late final StreamSubscription<PlaybackEvent> _playbackSub;
  late final StreamSubscription<int?> _indexSub;
  late final StreamSubscription<Duration?> _durationSub;

  LyraAudioHandler() {
    // Simpan Future-nya, tapi tidak perlu di-await di constructor
    _sessionInitFuture = _initAudioSession();

    // Sinkronkan state just_audio ke audio_service
    _playbackSub = _player.playbackEventStream.listen(_broadcastState);
    _indexSub = _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });
    _durationSub = _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    // Konfigurasi standar untuk aplikasi musik
    await session.configure(const AudioSessionConfiguration.music());
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
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

  Future<void> playQueue(List<Song> songs, int initialIndex) async {
    if (songs.isEmpty) return;
    if (initialIndex < 0 || initialIndex >= songs.length) {
      initialIndex = 0;
    }

    // Tunggu AudioSession siap
    await _sessionInitFuture;

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

    final audioSources = songs.map((s) => AudioSource.file(s.path)).toList();

    try {
      // LOAD AUDIO TERLEBIH DAHULU
      await _player.setAudioSources(audioSources, initialIndex: initialIndex);

      // JIKA BERHASIL, BARU UPDATE QUEUE & UI
      queue.add(mediaItems);
      mediaItem.add(mediaItems[initialIndex]);

      // Gunakan unawaited agar tidak menggantung
      unawaited(play());
    } catch (e) {
      // Jika gagal (file rusak/hilang), state UI tidak akan berubah
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
        ),
      );
      print("Gagal memutar antrean: $e");
      // Opsional: Kamu bisa memunculkan SnackBar di sini lewat global key/event
    }
  }

  Future<void> loadFile(String path, {String? title}) async {
    await _sessionInitFuture;

    try {
      await _player.setFilePath(path);

      // Jika berhasil, baru update UI
      final item = MediaItem(
        id: path,
        title: title ?? path.split('/').last,
        album: 'Lyra',
        artist: 'Unknown',
      );
      mediaItem.add(item);
      queue.add([item]);
    } catch (e) {
      print("Gagal memuat file: $e");
    }
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

  // 3. Tambahkan ini agar bisa ganti lagu dari notifikasi/headset
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> onTaskRemoved() async {
    super.onTaskRemoved();
  }

  // 4. Bersihkan resource saat aplikasi ditutup
  Future<void> disposePlayer() async {
    await _playbackSub.cancel();
    await _indexSub.cancel();
    await _durationSub.cancel();
    await _player.dispose();
  }
}
