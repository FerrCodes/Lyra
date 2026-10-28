import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import '../audio/lyra_audio_handler.dart';
import '../main.dart';
import '../models/song.dart';
import '../services/media_store_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Song> _songs = [];
  bool _isLoading = true;

  LyraAudioHandler? get _handler {
    final h = audioHandler;
    return h is LyraAudioHandler ? h : null;
  }

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final rawSongs = await MediaStoreService.getSongs();
    setState(() {
      _songs = rawSongs.map((e) => Song.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _playSong(Song song) async {
    final handler = _handler;
    if (handler == null) return;

    try {
      // Ubah Song lokal menjadi MediaItem untuk audio_service
      await handler.loadFile(song.path, title: song.title);
      await handler.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memutar ${song.title}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyra Library'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSongs),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
          ? const Center(
              child: Text(
                'Tidak ada lagu ditemukan.\nPastikan ada file MP3 di HP kamu.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.music_note)),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _playSong(song),
                );
              },
            ),
      bottomNavigationBar: _buildBottomPlayer(),
    );
  }

  Widget _buildBottomPlayer() {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();

        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item.artist ?? 'Unknown',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    return IconButton(
                      iconSize: 36,
                      onPressed: playing
                          ? audioHandler.pause
                          : audioHandler.play,
                      icon: Icon(
                        playing ? Icons.pause_circle : Icons.play_circle,
                      ),
                    );
                  },
                ),
                IconButton(
                  iconSize: 28,
                  onPressed: audioHandler.stop,
                  icon: const Icon(Icons.stop_circle),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
