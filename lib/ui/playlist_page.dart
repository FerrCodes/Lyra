import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import 'playlist_detail_page.dart';

class PlaylistPage extends ConsumerStatefulWidget {
  const PlaylistPage({super.key});

  @override
  ConsumerState<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends ConsumerState<PlaylistPage> {
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final db = ref.read(databaseProvider);
    final data = await db.select(db.playlists).get();
    setState(() {
      _playlists = data;
      _isLoading = false;
    });
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Playlist Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nama Playlist'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      final db = ref.read(databaseProvider);
      await db
          .into(db.playlists)
          .insert(PlaylistsCompanion.insert(name: name.trim()));
      _loadPlaylists();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        if (_playlists.isEmpty)
          const Center(child: Text('Belum ada playlist.'))
        else
          ListView.builder(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 80,
              bottom: 160,
            ),
            itemCount: _playlists.length,
            itemBuilder: (context, index) {
              final pl = _playlists[index];
              return ListTile(
                leading: const Icon(
                  Icons.queue_music,
                  size: 36,
                  color: Colors.blue,
                ),
                title: Text(
                  pl.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailPage(playlist: pl),
                    ),
                  ).then((_) => _loadPlaylists());
                },
              );
            },
          ),
        Positioned(
          bottom: 120,
          right: 20,
          child: FloatingActionButton(
            onPressed: _createPlaylist,
            backgroundColor: Colors.red,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
