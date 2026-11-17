import 'dart:async';
import 'dart:io';
import '../database/database.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LyraAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  late final Future<void> _sessionInitFuture;

  late final StreamSubscription<PlaybackEvent> _playbackSub;
  late final StreamSubscription<int?> _indexSub;
  late final StreamSubscription<Duration?> _durationSub;
  Map<String, String> _currentAlbumIds = {};
  bool _mutatingQueue = false;
  Timer? _sleepTimer;
  static const _kShuffle = 'lyra_shuffle_mode';
  static const _kRepeat = 'lyra_repeat_mode';

  final ValueNotifier<bool> sleepTimerActiveNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<Duration> sleepTimerRemainingNotifier =
      ValueNotifier<Duration>(Duration.zero);

  void startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    sleepTimerRemainingNotifier.value = duration;
    sleepTimerActiveNotifier.value = true;

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sleepTimerRemainingNotifier.value.inSeconds > 0) {
        sleepTimerRemainingNotifier.value =
            sleepTimerRemainingNotifier.value - const Duration(seconds: 1);
      } else {
        timer.cancel();
        sleepTimerActiveNotifier.value = false;
        pause(); // Hentikan lagu saat waktu habis
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerActiveNotifier.value = false;
  }

  LyraAudioHandler() {
    _sessionInitFuture = _initAudioSession();
    _restorePlaybackModes();

    _playbackSub = _player.playbackEventStream.listen(_broadcastState);
    _player.shuffleModeEnabledStream.listen(
      (_) => _broadcastState(_player.playbackEvent),
    );
    _player.loopModeStream.listen(
      (_) => _broadcastState(_player.playbackEvent),
    );

    _indexSub = _player.currentIndexStream.listen((index) {
      if (_mutatingQueue) return;
      if (index != null && index >= 0 && index < queue.value.length) {
        final currentItem = queue.value[index];
        mediaItem.add(currentItem);
        // Ambil gambar setiap kali lagu berganti
        _fetchAndUpdateArtwork(currentItem);
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
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> _restorePlaybackModes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shuffleOn = prefs.getBool(_kShuffle) ?? false;
      final repeatIndex = prefs.getInt(_kRepeat) ?? 0;

      await _player.setShuffleModeEnabled(shuffleOn);
      await _player.setLoopMode(switch (repeatIndex) {
        1 => LoopMode.all,
        2 => LoopMode.one,
        _ => LoopMode.off,
      });
    } catch (e) {
      debugPrint('Gagal restore playback modes: $e');
    }
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final shuffleOn = _player.shuffleModeEnabled;
    final loop = _player.loopMode;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.custom(
            androidIcon: shuffleOn
                ? 'drawable/ic_shuffle_on'
                : 'drawable/ic_shuffle_off',
            label: 'Shuffle',
            name: 'toggleShuffle',
          ),
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.custom(
            androidIcon: switch (loop) {
              LoopMode.off => 'drawable/ic_repeat_off',
              LoopMode.all => 'drawable/ic_repeat_all',
              LoopMode.one => 'drawable/ic_repeat_one',
            },
            label: 'Repeat',
            name: 'cycleRepeat',
          ),
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [1, 2, 3],
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
        shuffleMode: shuffleOn
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        repeatMode: switch (loop) {
          LoopMode.off => AudioServiceRepeatMode.none,
          LoopMode.all => AudioServiceRepeatMode.all,
          LoopMode.one => AudioServiceRepeatMode.one,
        },
      ),
    );
  }

  Future<void> playQueue(
    List<Song> songs,
    int initialIndex, {
    Map<String, String>? albumIds,
    String? sourceType,
    String? sourceName,
  }) async {
    if (songs.isEmpty) return;
    if (initialIndex < 0 || initialIndex >= songs.length) initialIndex = 0;

    await _sessionInitFuture;
    _currentAlbumIds = albumIds ?? {};

    final mediaItems = songs.map((s) {
      return MediaItem(
        id: s.path,
        title: s.title,
        artist: s.artist,
        album: s.album,
        duration: Duration(milliseconds: s.durationMs),
        extras: {
          'albumId': _currentAlbumIds[s.path] ?? '0',
          'songId': s.id,
          'sourceType': sourceType ?? 'Unknown',
          'sourceName': sourceName ?? 'Unknown',
        },
      );
    }).toList();

    final audioSources = songs.map((s) {
      // Karena s adalah Song versi Drift (tidak punya contentUri),
      // kita bentuk URI-nya secara manual menggunakan ID lagu.
      // Tapi agar aman untuk lagu lama, kita cek apakah ID-nya angka.
      final songIdNum = int.tryParse(s.id);
      if (songIdNum != null) {
        // Membentuk: content://media/external/audio/media/[ID]
        final uri = Uri.parse('content://media/external/audio/media/${s.id}');
        return AudioSource.uri(uri);
      }

      // Fallback jika ID bukan angka (misal data lama)
      return AudioSource.file(s.path);
    }).toList();

    try {
      await _player.setAudioSources(audioSources, initialIndex: initialIndex);
      queue.add(mediaItems);
      mediaItem.add(mediaItems[initialIndex]);
      unawaited(play());

      // Ambil gambar untuk lagu pertama secara background
      _fetchAndUpdateArtwork(mediaItems[initialIndex]);
    } catch (e) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
        ),
      );
    }
  }

  // Sinkronkan mediaItem + state dengan posisi pemutar saat ini
  void _resyncCurrent() {
    final i = _player.currentIndex;
    final q = queue.value;
    if (i != null && i >= 0 && i < q.length) {
      mediaItem.add(q[i]);
      _fetchAndUpdateArtwork(q[i]);
    }
    _broadcastState(_player.playbackEvent);
  }

  /// Pindahkan lagu. newIndex = posisi AKHIR (sudah disesuaikan).
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    final q = List<MediaItem>.from(queue.value);
    if (oldIndex < 0 || oldIndex >= q.length) return;
    if (newIndex < 0 || newIndex >= q.length || oldIndex == newIndex) return;

    _mutatingQueue = true;
    try {
      await _player.moveAudioSource(oldIndex, newIndex);
      final item = q.removeAt(oldIndex);
      q.insert(newIndex, item);
      queue.add(q);
    } finally {
      _mutatingQueue = false;
      _resyncCurrent();
    }
  }

  /// Hapus lagu. Mengembalikan false bila ditolak (lagu sedang diputar).
  Future<bool> removeTrackFromQueue(int index) async {
    final q = List<MediaItem>.from(queue.value);
    if (index < 0 || index >= q.length) return false;
    if (index == _player.currentIndex) return false;

    _mutatingQueue = true;
    try {
      await _player.removeAudioSourceAt(index);
      q.removeAt(index);
      queue.add(q);
      return true;
    } finally {
      _mutatingQueue = false;
      _resyncCurrent();
    }
  }

  /// Dipakai untuk Undo: sisipkan kembali lagu di indeks semula.
  Future<void> insertTrackToQueue(int index, MediaItem item) async {
    final q = List<MediaItem>.from(queue.value);
    final at = index.clamp(0, q.length);

    _mutatingQueue = true;
    try {
      // Ambil contentUri dari extras, fallback ke item.id (path)
      final songId = item.extras?['songId']?.toString();
      final songIdNum = int.tryParse(songId ?? '');

      final source = (songIdNum != null)
          ? AudioSource.uri(
              Uri.parse('content://media/external/audio/media/$songId'),
            )
          : AudioSource.file(item.id);

      await _player.insertAudioSource(at, source);
      q.insert(at, item);
      queue.add(q);
    } finally {
      _mutatingQueue = false;
      _resyncCurrent();
    }
  }

  // Fungsi baru untuk mengambil gambar secara async dan memperbarui notifikasi
  Future<void> _fetchAndUpdateArtwork(MediaItem item) async {
    final albumId = item.extras?['albumId'];
    if (albumId == null || albumId == '0') return;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/album_art_$albumId.jpg');

      // MEMORY MANAGEMENT: Cek apakah gambar sudah ada di cache HP
      if (!await file.exists()) {
        // Jika belum ada, baru ambil dari MediaStore
        final audioQuery = OnAudioQuery();
        Uint8List? artBytes = await audioQuery.queryArtwork(
          int.parse(albumId),
          ArtworkType.ALBUM,
          format: ArtworkFormat.JPEG,
          size: 500,
        );

        if (artBytes != null) {
          await file.writeAsBytes(artBytes);
        } else {
          return; // Gambar tidak ditemukan di MediaStore
        }
      }

      // Perbarui MediaItem yang sedang diputar dengan gambar
      if (mediaItem.value?.id == item.id) {
        final updatedItem = item.copyWith(artUri: Uri.file(file.path));
        mediaItem.add(updatedItem);

        // Update juga di antrean agar sinkron
        final newQueue = List<MediaItem>.from(queue.value);
        final index = newQueue.indexWhere((e) => e.id == item.id);
        if (index != -1) {
          newQueue[index] = updatedItem;
          queue.add(newQueue);
        }
      }
    } catch (e) {
      // ERROR HANDLING: Tampilkan error di console agar bisa dilacak
      debugPrint('Gagal memuat artwork untuk album $albumId: $e');
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
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enable = shuffleMode != AudioServiceShuffleMode.none;
    if (enable) await _player.shuffle();
    await _player.setShuffleModeEnabled(enable);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kShuffle, enable);
    } catch (e) {
      debugPrint('Gagal save shuffle mode: $e');
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _player.setLoopMode(switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      _ => LoopMode.all,
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final idx = switch (repeatMode) {
        AudioServiceRepeatMode.none => 0,
        AudioServiceRepeatMode.all => 1,
        AudioServiceRepeatMode.one => 2,
        _ => 1, // Menangkap AudioServiceRepeatMode.group, arahkan ke 'all'
      };
      await prefs.setInt(_kRepeat, idx);
    } catch (e) {
      debugPrint('Gagal save repeat mode: $e');
    }
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    switch (name) {
      case 'toggleShuffle':
        return setShuffleMode(
          _player.shuffleModeEnabled
              ? AudioServiceShuffleMode.none
              : AudioServiceShuffleMode.all,
        );
      case 'cycleRepeat':
        // off -> all -> one -> off
        return setRepeatMode(switch (_player.loopMode) {
          LoopMode.off => AudioServiceRepeatMode.all,
          LoopMode.all => AudioServiceRepeatMode.one,
          LoopMode.one => AudioServiceRepeatMode.none,
        });
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    // Jika lagu sudah berjalan lebih dari 10 detik, ulangi dari awal
    if (_player.position > const Duration(seconds: 10)) {
      await _player.seek(Duration.zero);
    } else {
      // Jika masih di bawah 10 detik, pindah ke lagu sebelumnya
      if (_player.hasPrevious) {
        await _player.seekToPrevious();
      }
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  // Bersihkan resource saat aplikasi ditutup
  Future<void> disposePlayer() async {
    _sleepTimer?.cancel();
    sleepTimerActiveNotifier.dispose();
    sleepTimerRemainingNotifier.dispose();
    await _playbackSub.cancel();
    await _indexSub.cancel();
    await _durationSub.cancel();
    await _player.dispose();
  }

  // FITUR VOLUME UNTUK BOTTOM SHEET
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  double get volume => _player.volume;
  Stream<double> get volumeStream => _player.volumeStream;

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
  double get speed => _player.speed;
  Stream<double> get speedStream => _player.speedStream;
}
