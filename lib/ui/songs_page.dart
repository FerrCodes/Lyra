import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../database/database.dart';
import '../main.dart';
import '../models/song.dart' as local;
import '../providers/database_provider.dart';
import '../services/media_store_service.dart';
import '../audio/lyra_audio_handler.dart';

final GlobalKey<SongsPageState> songsPageKey = GlobalKey<SongsPageState>();

class SongsPage extends ConsumerStatefulWidget {
  final VoidCallback? onPlayTriggered;
  final Function(String)? onSortChanged;
  final VoidCallback? onDoubleTapHome;
  const SongsPage({
    super.key,
    this.onPlayTriggered,
    this.onSortChanged,
    this.onDoubleTapHome,
  });

  @override
  ConsumerState<SongsPage> createState() => SongsPageState();
}

class SongsPageState extends ConsumerState<SongsPage> {
  List<local.Song> _allSongs = [];
  List<local.Song> _displayedSongs = [];
  List<Song> _favorites = [];
  bool _isLoading = true;
  String _sortBy = 'Name';
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastHomeTap;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    final now = DateTime.now();

    // Jika tombol diklik dua kali dalam waktu kurang dari 300ms
    if (_lastHomeTap != null &&
        now.difference(_lastHomeTap!) < const Duration(milliseconds: 300)) {
      _lastHomeTap = null;
      // Aksi klik 2x: Beritahu HomePage untuk pindah tab
      widget.onDoubleTapHome?.call();
    } else {
      _lastHomeTap = now;
      // Aksi klik 1x: Scroll ke atas dengan animasi
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final rawSongs = await MediaStoreService.getSongs();
    final db = ref.read(databaseProvider);
    final favs = await db.getAllFavoriteSongs();

    setState(() {
      _allSongs = rawSongs.map((e) => local.Song.fromMap(e)).toList();
      _favorites = favs;
      _applySort();
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

  void _applySort() {
    setState(() {
      _displayedSongs = List.from(_allSongs);
      if (_sortBy == 'Name') {
        _displayedSongs.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      } else if (_sortBy == 'Artist') {
        _displayedSongs.sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
        );
      } else if (_sortBy == 'Date Added') {
        // Untuk sementara kita urutkan berdasarkan ID terbaru (terbalik)
        // Karena kita belum punya tanggal file asli dari MediaStore
        _displayedSongs.sort((a, b) => b.id.compareTo(a.id));
      }
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Urutkan Berdasarkan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              ListTile(
                title: const Text('Name'),
                trailing: _sortBy == 'Name'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _sortBy = 'Name');
                  _applySort();
                  Navigator.pop(context);
                  widget.onSortChanged?.call('Name');
                },
              ),
              ListTile(
                title: const Text('Artist'),
                trailing: _sortBy == 'Artist'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _sortBy = 'Artist');
                  _applySort();
                  Navigator.pop(context);
                  widget.onSortChanged?.call('Artist');
                },
              ),
              ListTile(
                title: const Text('Date Added'),
                trailing: _sortBy == 'Date Added'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _sortBy = 'Date Added');
                  _applySort();
                  Navigator.pop(context);
                  widget.onSortChanged?.call('Date Added');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- FUNGSI DARI HOME_PAGE ---
  void triggerFilterDialog() {
    _showFilterDialog();
  }

  void playAllShuffled() {
    if (_displayedSongs.isEmpty) return;
    final shuffled = List.from(_displayedSongs)..shuffle();
    final handler = audioHandler as LyraAudioHandler;
    handler.playQueue(
      shuffled
          .map(
            (s) => Song(
              id: s.id,
              title: s.title,
              artist: s.artist,
              album: s.album,
              path: s.path,
              durationMs: s.durationMs,
              addedAt: DateTime.now(),
            ),
          )
          .toList(),
      0,
    );
    widget.onPlayTriggered?.call();
  }

  void playAll() {
    if (_displayedSongs.isEmpty) return;
    final handler = audioHandler as LyraAudioHandler;
    handler.playQueue(
      _displayedSongs
          .map(
            (s) => Song(
              id: s.id,
              title: s.title,
              artist: s.artist,
              album: s.album,
              path: s.path,
              durationMs: s.durationMs,
              addedAt: DateTime.now(),
            ),
          )
          .toList(),
      0,
    );
    widget.onPlayTriggered?.call();
  }

  // --- POPOVER MENU TITIK TIGA ---
  void _showSongOptions(local.Song song, bool isFav) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Info Lagu
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Menu Favorit
              ListTile(
                leading: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : Colors.grey,
                ),
                title: Text(
                  isFav ? 'Hapus dari Favorit' : 'Tambahkan ke Favorit',
                ),
                onTap: () async {
                  Navigator.pop(context); // Tutup popover
                  await _toggleFavorite(song, isFav); // Jalankan fungsi favorit
                },
              ),

              // Tempat untuk fitur tambahan nanti (misal: Tambah ke Playlist)
              const ListTile(
                leading: Icon(Icons.playlist_add, color: Colors.grey),
                title: Text('Tambahkan ke Playlist (Segera)'),
                enabled: false,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_allSongs.isEmpty)
      return const Center(child: Text('Tidak ada lagu ditemukan.'));

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 80,
            bottom: 160,
            right: 30,
          ),
          itemCount: _displayedSongs.length,
          itemBuilder: (context, index) {
            final song = _displayedSongs[index];
            final isFav = _favorites.any((f) => f.id == song.id);

            return StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data?.id == song.path;
                return ListTile(
                  contentPadding: const EdgeInsets.only(left: 16, right: 8),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.grey),
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPlaying ? Colors.blue : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  // Hanya menyisakan tombol titik tiga
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onPressed: () => _showSongOptions(song, isFav),
                  ),
                  onTap: () async {
                    final handler = audioHandler as LyraAudioHandler;

                    // Ganti loadFile dengan playQueue agar bisa lanjut otomatis
                    handler.playQueue(
                      _displayedSongs
                          .map(
                            (s) => Song(
                              id: s.id,
                              title: s.title,
                              artist: s.artist,
                              album: s.album,
                              path: s.path,
                              durationMs: s.durationMs,
                              addedAt: DateTime.now(),
                            ),
                          )
                          .toList(),
                      index, // Memulai dari lagu yang diklik (berdasarkan urutan index)
                    );
                    // Panggil sinyal untuk memunculkan Mini Player
                    widget.onPlayTriggered?.call();
                  },
                );
              },
            );
          },
        ),
        Positioned(
          right: 4,
          top: MediaQuery.of(context).padding.top + 120,
          bottom: 160,
          child: Container(
            width: 24,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  [
                        'A',
                        'B',
                        'C',
                        'D',
                        'E',
                        'F',
                        'G',
                        'H',
                        'I',
                        'J',
                        'K',
                        'L',
                        'M',
                        'N',
                        'O',
                        'P',
                        'Q',
                        'R',
                        'S',
                        'T',
                        'U',
                        'V',
                        'W',
                        'X',
                        'Y',
                        'Z',
                      ]
                      .map(
                        (l) => GestureDetector(
                          onTap: () {},
                          child: Text(
                            l,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
