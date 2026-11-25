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
  final AudioPlayer _player = AudioPlayer(
    useLazyPreparation: false, // Menyiapkan lagu selanjutnya tanpa menunggu
  );
  final OnAudioQuery _audioQuery = OnAudioQuery();
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
    _indexSub = _player.currentIndexStream.distinct().listen((index) {
      debugPrint(
        '[SKIP] index berubah -> $index @ ${_skipWatch.elapsedMilliseconds} ms',
      );
      if (_mutatingQueue || _pendingIndex != null) return;
      if (index != null && index >= 0 && index < queue.value.length) {
        final currentItem = _withCachedArt(queue.value[index]);
        mediaItem.add(currentItem);
        // Ambil gambar setiap kali lagu berganti
        _fetchAndUpdateArtwork(currentItem);

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_player.currentIndex == index) _prefetchNeighborArt(index);
        });
      }
    });

    _durationSub = _player.durationStream.distinct().listen((duration) {
      if (_pendingIndex != null) return;
      final current = mediaItem.value;
      if (current != null && duration != null && current.duration != duration) {
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
        processingState: _isTransitioning || _pendingIndex != null
            ? AudioProcessingState
                  .ready // Paksa hilangkan spinner saat transisi
            : switch (_player.processingState) {
                ProcessingState.idle => AudioProcessingState.idle,
                ProcessingState.loading => AudioProcessingState.loading,
                ProcessingState.buffering => AudioProcessingState.buffering,
                ProcessingState.ready => AudioProcessingState.ready,
                ProcessingState.completed => AudioProcessingState.completed,
              },
        playing: playing,
        updatePosition: _pendingIndex != null
            ? Duration.zero
            : _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _pendingIndex ?? event.currentIndex,
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
      // Langsung gunakan path (jauh lebih cepat dari content://)
      return AudioSource.file(s.path);
    }).toList();

    try {
      await _player.setAudioSources(audioSources, initialIndex: initialIndex);
      queue.add(mediaItems);
      mediaItem.add(mediaItems[initialIndex]);
      unawaited(play());

      // Ambil gambar untuk lagu pertama secara background
      _fetchAndUpdateArtwork(mediaItems[initialIndex]);
      unawaited(_prefetchAllArt(mediaItems, initialIndex));
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
      mediaItem.add(_withCachedArt(q[i]));
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

  // Cache artwork per album supaya notifikasi langsung dapat gambar
  final Map<String, Uri> _artCache = {};
  final Stopwatch _skipWatch = Stopwatch();

  // ===== Skip cepat: tap beruntun digabung jadi satu lompatan =====
  int? _pendingIndex;
  bool _skipRunning = false;
  bool _isTransitioning = false;

  void _skipBy(int delta) {
    final order = _player.effectiveIndices; // urutan putar (ikut shuffle)
    final from = _pendingIndex ?? _player.currentIndex;
    if (order.isEmpty || from == null) return;

    var pos = order.indexOf(from);
    if (pos < 0) return;
    pos += delta;
    if (pos < 0 || pos >= order.length) {
      if (_player.loopMode == LoopMode.off) return;
      pos = (pos + order.length) % order.length;
    }
    _jumpTo(order[pos]);
  }

  void _jumpTo(int index) {
    final q = queue.value;
    if (index < 0 || index >= q.length) return;
    _pendingIndex = index;
    final targetItem = q[index];
    mediaItem.add(_withCachedArt(targetItem)); // Sampul & teks INSTAN
    _fetchAndUpdateArtwork(targetItem);
    _broadcastState(_player.playbackEvent); // Seek bar INSTAN
    _drainSkips(); // Jalankan audio di latar belakang
  }

  Future<void> _drainSkips() async {
    if (_skipRunning) return;
    _skipRunning = true;
    _isTransitioning = true; // Sembunyikan spinner

    try {
      while (_pendingIndex != null) {
        // Tunggu 60ms. Jika user nekan lagi dalam 60ms ini,
        // audio tidak akan memutar lagu perantara, langsung ke target akhir.
        await Future.delayed(const Duration(milliseconds: 60));

        final target = _pendingIndex;
        if (target == null) break;
        _pendingIndex = null;

        // Eksekusi seek audio ke target akhir
        await _player.seek(Duration.zero, index: target);
      }
    } catch (e) {
      debugPrint('Gagal skip: $e');
      _pendingIndex = null;
    } finally {
      _isTransitioning = false;
      _skipRunning = false;
      _resyncCurrent();

      // Paksa UI update terakhir
      _broadcastState(_player.playbackEvent);
      final d = _player.duration;
      final c = mediaItem.value;
      if (d != null && c != null && c.duration != d) {
        mediaItem.add(c.copyWith(duration: d));
      }
    }
  }

  MediaItem _withCachedArt(MediaItem item) {
    final art = _artCache[item.extras?['albumId']?.toString() ?? ''];
    return art == null ? item : item.copyWith(artUri: art);
  }

  // Siapkan artwork lagu sebelum dan sesudahnya di latar belakang
  void _prefetchNeighborArt(int index) {
    final q = queue.value;
    for (final i in [index + 1, index - 1]) {
      if (i >= 0 && i < q.length) _fetchAndUpdateArtwork(q[i]);
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

  final Map<String, Future<Uri?>> _artLoading = {};
  Directory? _artDir;

  // Satu album = satu proses muat, permintaan ganda menunggu hasil yang sama
  Future<Uri?> _loadArt(int albumId) {
    final key = albumId.toString();
    final cached = _artCache[key];
    if (cached != null) return Future.value(cached);

    return _artLoading[key] ??= () async {
      try {
        _artDir ??= await getTemporaryDirectory();
        final file = File('${_artDir!.path}/album_art_300_$key.jpg');
        if (!await file.exists() || await file.length() == 0) {
          final bytes = await _audioQuery.queryArtwork(
            albumId,
            ArtworkType.ALBUM,
            format: ArtworkFormat.JPEG,
            size: 300,
          );
          if (bytes == null) return null;
          // tulis ke file sementara dulu, supaya tidak ada file setengah jadi
          final tmp = File('${file.path}.tmp');
          await tmp.writeAsBytes(bytes, flush: true);
          await tmp.rename(file.path);
        }
        final uri = Uri.file(file.path);
        _artCache[key] = uri;
        return uri;
      } catch (e) {
        debugPrint('Gagal memuat artwork untuk album $albumId: $e');
        return null;
      } finally {
        _artLoading.remove(key);
      }
    }();
  }

  Future<void> _fetchAndUpdateArtwork(MediaItem item) async {
    final albumId = int.tryParse(item.extras?['albumId']?.toString() ?? '');
    if (albumId == null || albumId == 0) return;

    final art = await _loadArt(albumId);
    if (art == null) return;

    final cur = mediaItem.value;
    if (cur != null && cur.id == item.id && cur.artUri != art) {
      mediaItem.add(cur.copyWith(artUri: art));
    }
  }

  // Siapkan cover semua album di latar belakang, dari yang terdekat dulu
  Future<void> _prefetchAllArt(List<MediaItem> items, int start) async {
    final order = List<int>.generate(items.length, (i) => i)
      ..sort((a, b) => (a - start).abs().compareTo((b - start).abs()));
    final seen = <int>{};
    for (final i in order) {
      final id = int.tryParse(items[i].extras?['albumId']?.toString() ?? '');
      if (id == null || id == 0 || !seen.add(id)) continue;
      await _loadArt(id);
      if (seen.length >= 100) break; // batas supaya tidak berat
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
  Future<void> seek(Duration position) async {
    _isTransitioning = true; // Sembunyikan spinner saat seek
    playbackState.add(playbackState.value.copyWith(updatePosition: position));
    await _player.seek(position);
    _isTransitioning = false;
    _broadcastState(_player.playbackEvent);
  }

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
  Future<void> skipToNext() async => _skipBy(1);

  @override
  Future<void> skipToPrevious() async {
    // Hanya ulang dari awal kalau tidak sedang skip beruntun
    if (_pendingIndex == null &&
        _player.position > const Duration(seconds: 10)) {
      await _player.seek(Duration.zero);
      _broadcastState(_player.playbackEvent);
      return;
    }
    _skipBy(-1);
  }

  @override
  Future<void> skipToQueueItem(int index) async => _jumpTo(index);

  // Bersihkan resource saat aplikasi ditutup
  Future<void> disposePlayer() async {
    _sleepTimer?.cancel();
    sleepTimerActiveNotifier.dispose();
    sleepTimerRemainingNotifier.dispose();
    await _indexSub.cancel();
    await _playbackSub.cancel();
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
