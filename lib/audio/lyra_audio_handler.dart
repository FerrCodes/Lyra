import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../database/database.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';

class LyraAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  late final Future<void> _sessionInitFuture;

  late final StreamSubscription<PlaybackEvent> _playbackSub;
  late final StreamSubscription<int?> _indexSub;
  late final StreamSubscription<Duration?> _durationSub;

  // Simpan map albumId untuk diakses saat lagu berganti
  Map<String, String> _currentAlbumIds = {};

  LyraAudioHandler() {
    _sessionInitFuture = _initAudioSession();

    _playbackSub = _player.playbackEventStream.listen(_broadcastState);

    _indexSub = _player.currentIndexStream.listen((index) {
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

  Future<void> playQueue(
    List<Song> songs,
    int initialIndex, {
    Map<String, String>? albumIds,
  }) async {
    if (songs.isEmpty) return;
    if (initialIndex < 0 || initialIndex >= songs.length) initialIndex = 0;

    await _sessionInitFuture;
    _currentAlbumIds = albumIds ?? {};

    // 1. Buat antrean dasar (tanpa gambar) agar pemutaran instan
    final mediaItems = songs.map((s) {
      return MediaItem(
        id: s.path,
        title: s.title,
        artist: s.artist,
        album: s.album,
        duration: Duration(milliseconds: s.durationMs),
        extras: {'albumId': _currentAlbumIds[s.path] ?? '0'},
      );
    }).toList();

    final audioSources = songs.map((s) => AudioSource.file(s.path)).toList();

    try {
      await _player.setAudioSources(audioSources, initialIndex: initialIndex);
      queue.add(mediaItems);
      mediaItem.add(mediaItems[initialIndex]);
      unawaited(play());

      // 2. Ambil gambar untuk lagu pertama secara background
      _fetchAndUpdateArtwork(mediaItems[initialIndex]);
    } catch (e) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
        ),
      );
    }
  }

  // Fungsi baru untuk mengambil gambar secara async dan memperbarui notifikasi
  Future<void> _fetchAndUpdateArtwork(MediaItem item) async {
    final albumId = item.extras?['albumId'];
    if (albumId == null || albumId == '0') return;

    try {
      final audioQuery = OnAudioQuery();
      Uint8List? artBytes = await audioQuery.queryArtwork(
        int.parse(albumId),
        ArtworkType.ALBUM,
        format: ArtworkFormat.JPEG,
        size: 500,
      );

      if (artBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/album_art_$albumId.jpg');
        await file.writeAsBytes(artBytes);

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
      }
    } catch (e) {
      // Abaikan error gambar
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
    if (_player.hasNext) await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  // Bersihkan resource saat aplikasi ditutup
  Future<void> disposePlayer() async {
    await _playbackSub.cancel();
    await _indexSub.cancel();
    await _durationSub.cancel();
    await _player.dispose();
  }
}
