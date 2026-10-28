import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import 'playlist_detail_page.dart';

class PlaylistsPage extends ConsumerStatefulWidget {
  const PlaylistsPage({super.key});

  @override
  ConsumerState<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends ConsumerState<PlaylistsPage> {
  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);

    // Ambil semua playlist dari database
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
    return Scaffold(
      appBar: AppBar(title: const Text('Playlist Saya')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
          ? const Center(child: Text('Belum ada playlist. Buat sekarang!'))
          : ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return ListTile(
                  leading: const Icon(
                    Icons.queue_music,
                    size: 40,
                    color: Colors.deepPurple,
                  ),
                  title: Text(playlist.name),
                  onTap: () {
                    // Pindah ke halaman detail playlist
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailPage(playlist: playlist),
                      ),
                    ).then((_) => _loadPlaylists());
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        child: const Icon(Icons.add),
      ),
    );
  }
}
