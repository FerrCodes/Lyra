import '../main.dart';
import '../database/database.dart';
import 'package:flutter/material.dart';
import '../models/song.dart' as local;
import '../ui/track_details_page.dart';
import '../providers/songs_provider.dart';
import '../audio/lyra_audio_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/database_provider.dart';
import '../services/media_store_service.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/library/pages/album_detail_page.dart';
import '../features/library/pages/artist_detail_page.dart';
import '../features/playlist/widgets/playlist_track_list.dart';

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

  // Mengembalikan salinan ter-sort tanpa memutasi field state
  List<local.Song> _sortedCopy(List<local.Song> source) {
    final list = List<local.Song>.from(source);
    switch (_sortBy) {
      case 'Artist':
        list.sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
        );
      case 'Date Added':
        list.sort((a, b) => b.id.compareTo(a.id));
      case 'Name':
      default:
        list.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return list;
  }

  void _showFilterMenu(BuildContext buttonContext) {
    final renderObject = buttonContext.findRenderObject();
    if (renderObject is! RenderBox) return;

    final RenderBox renderBox = renderObject;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double topPosition = offset.dy + renderBox.size.height - 60;
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
          Navigator.of(context, rootNavigator: true).pop();
          setState(() {
            _sortBy = title;
            widget.onSortChanged?.call(title);
          });
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
      albumIds: {for (var s in shuffled) s.path: s.albumId.toString()},
      sourceType: 'Songs',
      sourceName: 'Semua Lagu',
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
      albumIds: {for (var s in _displayedSongs) s.path: s.albumId.toString()},
      sourceType: 'Songs',
      sourceName: 'Semua Lagu',
    );
    widget.onPlayTriggered?.call();
  }

  void _showSongOptions(local.Song song, bool isFav) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: QueryArtworkWidget(
                            id: int.parse(song.albumId),
                            type: ArtworkType.ALBUM,
                            size: 200,
                            artworkHeight: 40,
                            artworkWidth: 40,
                            artworkBorder: BorderRadius.circular(8),
                            nullArtworkWidget: Container(
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrackDetailsPage(song: song),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.album, color: Colors.black87),
                    title: const Text('Album'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(this.context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AlbumDetailPage(albumKey: song.albumId),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.black87),
                    title: const Text('Artist'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(this.context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ArtistDetailPage(artistName: song.artist),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.share, color: Colors.black87),
                    title: const Text('Share'),
                    onTap: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: '${song.title} - ${song.artist}',
                          subject: song.title,
                        ),
                      );
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
      useRootNavigator: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
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
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 10),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade500,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Pilih Playlist',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
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
              ),
            ),
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
    // Ambil data lagu dari Provider
    final songsAsyncValue = ref.watch(allSongsProvider);

    return songsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        // Jika error karena izin ditolak
        if (err is MediaStoreException && err.code == 'PERMISSION_DENIED') {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_off_rounded,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Izin Music dan Audio dibutuhkan.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Membutuhkan izin untuk mencari semua lagu.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(allSongsProvider), // Coba muat ulang
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        // Error umum (selain izin)
        return Center(child: Text('Gagal memuat lagu: $err'));
      },
      data: (songs) {
        // Sinkronkan data provider ke variabel lokal
        _allSongs = songs;
        _displayedSongs = _sortedCopy(songs);

        if (_allSongs.isEmpty) {
          return const Center(child: Text('Tidak ada lagu ditemukan.'));
        }

        return Stack(
          children: [
            // BUNGKUS DENGAN STREAMBUILDER DI SINI (Hanya 1 untuk semua lagu)
            StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final currentMediaItem = snapshot.data;

                // LISTVIEW BUILDER MASUK KE DALAM SINI
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
                    // CEK LAGU AKTIF MENGGUNAKAN DATA DARI STREAMBUILDER DI ATAS
                    final isPlaying = currentMediaItem?.id == song.path;

                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 16,
                          right: 8,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: QueryArtworkWidget(
                            id: int.parse(
                              song.albumId,
                            ), // Konversi kembali ke integer
                            type: ArtworkType.ALBUM,
                            size: 200, // Resolusi gambar yang diambil
                            artworkHeight: 50,
                            artworkWidth: 50,
                            artworkBorder: BorderRadius.circular(8),
                            nullArtworkWidget: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              // Ini adalah ikon default jika lagu tidak punya foto album
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.grey,
                              ),
                            ),
                          ),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPlaying) ...[
                              const EqualizerAnimation(),
                              const SizedBox(width: 8),
                            ],
                            IconButton(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.grey,
                              ),
                              onPressed: () => _showSongOptions(song, isFav),
                            ),
                          ],
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
                            albumIds: {
                              for (var s in _displayedSongs)
                                s.path: s.albumId.toString(),
                            },
                            sourceType: 'Songs',
                            sourceName: 'Semua Lagu',
                          );
                          widget.onPlayTriggered?.call();
                        },
                      ),
                    );
                  },
                );
              },
            ),

            // Alphabet Scroller A-Z
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
