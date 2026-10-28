import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../audio/lyra_audio_handler.dart';
import '../database/database.dart';
import '../main.dart';
import '../models/song.dart' as local; // PENTING: Pakai alias 'local'
import '../providers/database_provider.dart';
import '../services/media_store_service.dart';
import 'playlists_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<local.Song> _allSongs = [];
  List<Song> _favorites = []; // 'Song' ini dari database.dart (Drift)
  bool _isLoading = true;

  LyraAudioHandler? get _handler {
    final h = audioHandler;
    return h is LyraAudioHandler ? h : null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final rawSongs = await MediaStoreService.getSongs();
    final db = ref.read(databaseProvider);
    final favs = await db.getAllFavoriteSongs();

    setState(() {
      _allSongs = rawSongs.map((e) => local.Song.fromMap(e)).toList();
      _favorites = favs;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite(local.Song song, bool isCurrentlyFav) async {
    final db = ref.read(databaseProvider);

    // Konversi dari model lokal ke model database
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

  void _showSongOptions(local.Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  song.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(song.artist),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Tambahkan ke Playlist'),
                onTap: () async {
                  Navigator.pop(context); // Tutup bottom sheet

                  // Ambil daftar playlist dari database
                  final db = ref.read(databaseProvider);
                  final playlists = await db.select(db.playlists).get();

                  if (playlists.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Belum ada playlist. Buat dulu di menu Playlist.',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  // Tampilkan dialog untuk memilih playlist
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Pilih Playlist'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: playlists.length,
                              itemBuilder: (context, index) {
                                final pl = playlists[index];
                                return ListTile(
                                  title: Text(pl.name),
                                  onTap: () async {
                                    // Konversi local.Song ke database Song
                                    final dbSong = Song(
                                      id: song.id,
                                      title: song.title,
                                      artist: song.artist,
                                      album: song.album,
                                      path: song.path,
                                      durationMs: song.durationMs,
                                      addedAt: DateTime.now(),
                                    );
                                    await db.addSongToPlaylist(pl.id, dbSong);

                                    if (context.mounted) {
                                      Navigator.pop(context); // Tutup dialog
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${song.title} ditambahkan ke ${pl.name}',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _playSong(String path, String title) async {
    final handler = _handler;
    if (handler == null) return;

    try {
      await handler.loadFile(path, title: title);
      await handler.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memutar $title: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyra Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistsPage()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Semua Lagu', icon: Icon(Icons.music_note)),
            Tab(text: 'Favorit', icon: Icon(Icons.favorite)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildAllSongsList(), _buildFavoritesList()],
            ),
      bottomNavigationBar: _buildBottomPlayer(),
    );
  }

  Widget _buildAllSongsList() {
    if (_allSongs.isEmpty) {
      return const Center(child: Text('Tidak ada lagu ditemukan.'));
    }

    return ListView.builder(
      itemCount: _allSongs.length,
      itemBuilder: (context, index) {
        final song = _allSongs[index];
        final isFav = _favorites.any((f) => f.id == song.id);

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.music_note)),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
                onPressed: () => _toggleFavorite(song, isFav),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showSongOptions(song),
              ),
            ],
          ),
          onTap: () => _playSong(song.path, song.title),
        );
      },
    );
  }

  Widget _buildFavoritesList() {
    if (_favorites.isEmpty) {
      return const Center(child: Text('Belum ada lagu favorit.'));
    }

    return ListView.builder(
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final fav = _favorites[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.favorite, color: Colors.white),
          ),
          title: Text(fav.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            fav.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.toggleFavorite(
                fav,
              ); // Drift akan menghapusnya jika sudah ada
              _loadData();
            },
          ),
          onTap: () => _playSong(fav.path, fav.title),
        );
      },
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
