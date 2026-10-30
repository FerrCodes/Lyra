import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../database/database.dart';
import '../main.dart';
import '../models/song.dart' as local;
import '../providers/database_provider.dart';
import '../providers/songs_provider.dart';
import '../audio/lyra_audio_handler.dart';

final GlobalKey<SongsPageState> songsPageKey = GlobalKey<SongsPageState>();

class SongsPage extends ConsumerStatefulWidget {
  final VoidCallback? onPlayTriggered;
  final Function(String)? onSortChanged;

  const SongsPage({super.key, this.onPlayTriggered, this.onSortChanged});

  @override
  ConsumerState<SongsPage> createState() => SongsPageState();
}

class SongsPageState extends ConsumerState<SongsPage> {
  List<local.Song> _allSongs = [];
  List<local.Song> _displayedSongs = [];
  List<Song> _favorites = [];
  final ScrollController _scrollController = ScrollController();
  String _sortBy = 'Name';
  bool get isScrolledDown =>
      _scrollController.hasClients && _scrollController.offset > 10;

  @override
  void initState() {
    super.initState();
    // Hanya mengambil data favorit dari database
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final db = ref.read(databaseProvider);
    final favs = await db.getAllFavoriteSongs();
    if (mounted) {
      setState(() {
        _favorites = favs;
      });
    }
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
    _loadFavorites(); // Cukup update daftar favorit
  }

  // Tidak ada setState di sini agar aman dipanggil di dalam build
  void _applySort() {
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
      _displayedSongs.sort((a, b) => b.id.compareTo(a.id));
    }
  }

  void _showFilterMenu(BuildContext buttonContext) {
    final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    final double topPosition = (offset.dy - renderBox.size.height) + 25;
    final double leftPosition = offset.dx - 1;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.1),
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: topPosition,
              left: leftPosition,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                        child: Row(
                          children: [
                            Text(
                              _sortBy,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check,
                              color: Colors.blue.shade700,
                              size: 18,
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.5),
                      _buildFilterOption('Name'),
                      _buildFilterOption('Artist'),
                      _buildFilterOption('Date Added'),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterOption(String title) {
    final isSelected = _sortBy == title;
    if (isSelected) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        visualDensity: VisualDensity.compact,
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        onTap: () {
          // setState dipindahkan ke sini agar UI terupdate saat filter diganti
          setState(() {
            _sortBy = title;
            _applySort();
            widget.onSortChanged?.call(title);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void triggerFilterDialog(BuildContext buttonContext) {
    _showFilterMenu(buttonContext);
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

  void _showSongOptions(local.Song song, bool isFav) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.playlist_play,
                      color: Colors.black87,
                    ),
                    title: const Text('Play Next'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${song.title} akan diputar selanjutnya',
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.add_to_queue,
                      color: Colors.black87,
                    ),
                    title: const Text('Add to Queue'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${song.title} ditambahkan ke antrean'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.playlist_add,
                      color: Colors.black87,
                    ),
                    title: const Text('Add to Playlist'),
                    onTap: () {
                      Navigator.pop(context);
                      _showPlaylistSelection(song);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.black87,
                    ),
                    title: Text(
                      isFav ? 'Remove from Favorites' : 'Add to Favorites',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _toggleFavorite(song, isFav);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: Colors.black87,
                    ),
                    title: const Text('Track details'),
                    onTap: () {
                      Navigator.pop(context);
                      _showTrackDetails(song);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.album, color: Colors.black87),
                    title: const Text('Album'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur Album segera hadir'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.black87),
                    title: const Text('Artist'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur Artist segera hadir'),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.share, color: Colors.black87),
                    title: const Text('Share'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTrackDetails(local.Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Track details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: ${song.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Artist: ${song.artist}'),
            const SizedBox(height: 4),
            Text('Album: ${song.album}'),
            const SizedBox(height: 4),
            Text(
              'Path: ${song.path}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistSelection(local.Song song) async {
    final db = ref.read(databaseProvider);
    final playlists = await db.select(db.playlists).get();

    if (!mounted) return;

    if (playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada Playlist. Buat dulu di tab Playlist.'),
        ),
      );
      return;
    }

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
                  'Pilih Playlist',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final pl = playlists[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.queue_music,
                        color: Colors.black54,
                      ),
                      title: Text(pl.name),
                      onTap: () async {
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
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
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
            ],
          ),
        );
      },
    );
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Ambil data lagu dari Provider
    final songsAsyncValue = ref.watch(allSongsProvider);

    return songsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Gagal memuat lagu: $err')),
      data: (songs) {
        // 2. Sinkronkan data provider ke variabel lokal
        _allSongs = songs;

        // 3. Panggil _applySort secara aman (tanpa setState)
        _applySort();

        if (_allSongs.isEmpty) {
          return const Center(child: Text('Tidak ada lagu ditemukan.'));
        }

        return Stack(
          children: [
            // 1. BUNGKUS DENGAN STREAMBUILDER DI SINI (Hanya 1 untuk semua lagu)
            StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final currentMediaItem = snapshot.data;

                // 2. LISTVIEW BUILDER MASUK KE DALAM SINI
                return ListView.builder(
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

                    // 3. CEK LAGU AKTIF MENGGUNAKAN DATA DARI STREAMBUILDER DI ATAS
                    final isPlaying = currentMediaItem?.id == song.path;

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
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onPressed: () => _showSongOptions(song, isFav),
                      ),
                      onTap: () async {
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
                          index,
                        );
                        widget.onPlayTriggered?.call();
                      },
                    );
                  },
                );
              },
            ),

            // (Sisa kode Alphabet Scroller A-Z milikmu biarkan saja di bawah sini)
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
      },
    );
  }
}
