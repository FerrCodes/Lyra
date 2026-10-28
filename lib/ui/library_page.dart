import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../main.dart';
import '../models/song.dart' as local;
import '../providers/database_provider.dart';
import '../audio/lyra_audio_handler.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  List<Song> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final db = ref.read(databaseProvider);
    final favs = await db.getAllFavoriteSongs();
    setState(() {
      _favorites = favs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        bottom: 160,
        left: 16,
        right: 16,
      ),
      children: [
        // Menu Kategori
        const Text(
          'Koleksi Saya',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLibraryMenu(Icons.favorite, 'Favorit', Colors.red),
            _buildLibraryMenu(Icons.album, 'Album', Colors.blue),
            _buildLibraryMenu(Icons.person, 'Artis', Colors.green),
            _buildLibraryMenu(Icons.folder, 'Folder', Colors.orange),
          ],
        ),

        const SizedBox(height: 32),
        const Text(
          'Lagu Favorit',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _favorites.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Belum ada lagu favorit.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Column(
                children: _favorites.map((fav) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.favorite, color: Colors.white),
                    ),
                    title: Text(
                      fav.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      fav.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.grey,
                      ),
                      onPressed: () async {
                        final db = ref.read(databaseProvider);
                        await db.toggleFavorite(fav);
                        _loadFavorites();
                      },
                    ),
                    onTap: () async {
                      final handler = audioHandler as LyraAudioHandler;
                      await handler.loadFile(fav.path, title: fav.title);
                      await handler.play();
                    },
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildLibraryMenu(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}
