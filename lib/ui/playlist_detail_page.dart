import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../main.dart';
import '../providers/database_provider.dart';
import '../audio/lyra_audio_handler.dart';

class PlaylistDetailPage extends ConsumerStatefulWidget {
  final Playlist playlist;
  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
  // Tipe 'Song' ini otomatis merujuk ke database.dart
  List<Song> _songsInPlaylist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);

    final data = await db.getSongsInPlaylist(widget.playlist.id);

    setState(() {
      _songsInPlaylist = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songsInPlaylist.isEmpty
          ? const Center(child: Text('Playlist ini masih kosong.'))
          : ListView.builder(
              itemCount: _songsInPlaylist.length,
              itemBuilder: (context, index) {
                final song = _songsInPlaylist[index];
                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  leading: const Icon(Icons.music_note),
                  onTap: () async {
                    final handler = audioHandler as LyraAudioHandler;
                    await handler.playQueue(_songsInPlaylist, index);
                  },
                );
              },
            ),
    );
  }
}
