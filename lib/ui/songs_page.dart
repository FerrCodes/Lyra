import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../main.dart';
import '../models/song.dart' as local;
import '../providers/database_provider.dart';
import '../services/media_store_service.dart';
import '../audio/lyra_audio_handler.dart';

class SongsPage extends ConsumerStatefulWidget {
  const SongsPage({super.key});

  @override
  ConsumerState<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends ConsumerState<SongsPage> {
  List<local.Song> _allSongs = [];
  List<Song> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final rawSongs = await MediaStoreService.getSongs();
    final db = ref.read(databaseProvider);
    final favs = await db.getAllFavoriteSongs();
    setState(() {
      _allSongs = rawSongs.map((e) => local.Song.fromMap(e)).toList();
      _favorites = favs;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite(local.Song song, bool isFav) async {
    final db = ref.read(databaseProvider);
    final dbSong = Song(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      path: song.path,
      durationMs: song.durationMs,
      addedAt: DateTime.now(),
    );
    await db.toggleFavorite(dbSong);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_allSongs.isEmpty)
      return const Center(child: Text('Tidak ada lagu ditemukan.'));

    return ListView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        bottom: 160,
      ),
      itemCount: _allSongs.length,
      itemBuilder: (context, index) {
        final song = _allSongs[index];
        final isFav = _favorites.any((f) => f.id == song.id);

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(Icons.music_note, color: Colors.grey),
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : Colors.grey,
            ),
            onPressed: () => _toggleFavorite(song, isFav),
          ),
          onTap: () async {
            final handler = audioHandler as LyraAudioHandler;
            await handler.loadFile(song.path, title: song.title);
            await handler.play();
          },
        );
      },
    );
  }
}
