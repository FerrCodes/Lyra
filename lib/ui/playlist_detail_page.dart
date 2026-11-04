import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:lyra/features/playlist/sheets/add_tracks_sheet.dart';
import '../database/database.dart';
import '../main.dart';
import '../providers/database_provider.dart';
import '../audio/lyra_audio_handler.dart';
import '../../features/playlist/widgets/playlist_header.dart';
import '../../features/playlist/widgets/playlist_track_list.dart';
import '../../features/playlist/sheets/edit_playlist_sheet.dart';

class PlaylistDetailPage extends ConsumerStatefulWidget {
  final Playlist playlist;
  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
  List<Song> _songsInPlaylist = [];
  List<Song> _displayedSongs = [];
  bool _isLoading = true;
  final GlobalKey _filterButtonKey = GlobalKey();
  late String _currentPlaylistName;
  String? _currentImagePath;
  String? _currentDescription;
  String _currentSort = 'Custom order';
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  Set<String> _selectedSongIds = {};

  @override
  void initState() {
    super.initState();
    _currentPlaylistName = widget.playlist.name;
    _currentImagePath = widget.playlist.imagePath;
    _currentDescription = widget.playlist.description;
    _loadSongs();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final data = await db.getSongsInPlaylist(widget.playlist.id);

      // PENTING: Cek apakah widget masih hidup sebelum setState
      if (!mounted) return;

      setState(() {
        _songsInPlaylist = data;
        _applySort();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Beri tahu user kalau database gagal dimuat
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat lagu: $e')));
    }
  }

  Future<void> _saveNewSongOrder() async {
    final db = ref.read(databaseProvider);
    // Gunakan batch untuk performa yang jauh lebih cepat
    await db.batch((batch) {
      for (int i = 0; i < _displayedSongs.length; i++) {
        batch.update(
          db.playlistSongs,
          PlaylistSongsCompanion(orderIndex: drift.Value(i)),
          where: (t) =>
              t.playlistId.equals(widget.playlist.id) &
              t.songId.equals(_displayedSongs[i].id),
        );
      }
    });
  }

  void _applySort() {
    _displayedSongs = List.from(_songsInPlaylist);
    if (_currentSort == 'Name') {
      _displayedSongs.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else if (_currentSort == 'Artist') {
      _displayedSongs.sort(
        (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
      );
    }
  }

  void _playPlaylist({bool shuffle = false, int startIndex = 0}) {
    if (_displayedSongs.isEmpty) return;
    final handler = audioHandler as LyraAudioHandler;

    List<Song> listToPlay = List.from(_displayedSongs);
    if (shuffle) {
      listToPlay.shuffle();
      startIndex = 0;
    }

    handler.playQueue(
      listToPlay
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
      startIndex,
    );
  }

  Future<void> _removeSongFromPlaylist(Song song) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.playlistSongs)..where(
          (t) =>
              t.playlistId.equals(widget.playlist.id) &
              t.songId.equals(song.id),
        ))
        .go();
    _loadSongs();
  }

  void _selectAll() {
    setState(() {
      if (_selectedSongIds.length == _displayedSongs.length) {
        _selectedSongIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedSongIds = _displayedSongs.map((e) => e.id).toSet();
      }
    });
  }

  void _removeSelectedSongs() async {
    final db = ref.read(databaseProvider);
    try {
      await (db.delete(db.playlistSongs)..where(
            (t) =>
                t.playlistId.equals(widget.playlist.id) &
                t.songId.isIn(_selectedSongIds),
          ))
          .go();

      if (!mounted) return;
      setState(() {
        _isSelectionMode = false;
        _selectedSongIds.clear();
      });
      _loadSongs();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus lagu: $e')));
    }
  }

  // === FUNGSI BOTTOM SHEET OPSI LAGU ===
  void _showSongOptions(Song song) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
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
                    child: const Icon(Icons.music_note, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.black87),
              title: const Text('Add to Playlist'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur Add to Playlist segera hadir'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.black87),
              title: const Text('Track details'),
              onTap: () {
                Navigator.pop(context);
                _showTrackDetails(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete from Playlist',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeSongFromPlaylist(song);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // === FUNGSI TRACK DETAILS ===
  void _showTrackDetails(Song song) {
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

  // ==========================================
  // UI DIALOG FILTER
  // ==========================================
  void _showFilterMenu() {
    if (_filterButtonKey.currentContext == null) return;
    final RenderBox renderBox =
        _filterButtonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double topPosition = offset.dy + renderBox.size.height - 70;
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
                  width: 240,
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
                              _currentSort,
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
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.5),
                      _buildFilterOption('Custom order'),
                      _buildFilterOption('Name'),
                      _buildFilterOption('Artist'),
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
    final isSelected = _currentSort == title;
    if (isSelected) return const SizedBox.shrink();
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
          setState(() {
            _currentSort = title;
            _applySort();
          });
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
  }

  void _showAddSongsToPlaylist() {
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
        return AddTracksSheet(
          playlist: widget.playlist,
          currentSongsInPlaylist: _songsInPlaylist,
          onSongAdded: () {
            _loadSongs(); // Refresh daftar lagu di halaman utama
          },
        );
      },
    );
  }

  void _showPlaylistImage() {
    if (_currentImagePath == null || _currentImagePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist ini belum memiliki foto.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Kita atur warnanya manual di dalam
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context), // Tap di mana saja untuk menutup
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efek Blur
            child: Container(
              color: Colors.black.withValues(
                alpha: 0.4,
              ), // Overlay gelap transparan
              child: Center(
                child: Hero(
                  // Efek transisi (opsional, tapi keren)
                  tag: 'playlist_image_${widget.playlist.id}',
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.width * 0.85,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                      image: DecorationImage(
                        image: FileImage(File(_currentImagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditPlaylistBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return EditPlaylistSheet(
          playlist: widget.playlist,
          currentName: _currentPlaylistName,
          currentDescription: _currentDescription,
          currentImagePath: _currentImagePath,
        );
      },
    ).then((result) {
      // JIKA RESULT ADALAH MAP (data baru dari bottom sheet)
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _currentPlaylistName = result['name'];
          _currentDescription = result['description'];
          _currentImagePath = result['imagePath'];
        });
      }
    });
  }

  void _showMoreMenu() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.1),
      builder: (context) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 210,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTopAction(Icons.crop_free, 'Lihat Foto', () {
                            Navigator.of(context, rootNavigator: true).pop();
                            _showPlaylistImage();
                          }),
                          _buildTopAction(Icons.edit, 'Edit Playlist', () {
                            Navigator.of(context, rootNavigator: true).pop();
                            _showEditPlaylistBottomSheet();
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    _buildListTile(Icons.playlist_play, 'Play Next', () {}),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: Colors.black87, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        onTap: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          onTap();
        },
      ),
    );
  }

  // ==========================================
  // UI UTAMA
  // ==========================================
  @override
  Widget build(BuildContext context) {
    const pageColor = Color(0xFFF6F5F1);
    final screenWidth = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = screenWidth + topPadding + 32;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: pageColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: pageColor,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: pageColor,
        body: Stack(
          children: [
            // Semua konten scroll memakai sliver. PlaylistTrackList memang
            // mengembalikan SliverList / SliverReorderableList, jadi ia harus
            // menjadi anak langsung dari CustomScrollView.slivers.
            Positioned.fill(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: headerHeight,
                      child: PlaylistHeader(
                        imagePath: _currentImagePath,
                        playlistName: _currentPlaylistName,
                        songCount: _songsInPlaylist.length,
                        description: _currentDescription,
                        playlistId: widget.playlist.id,
                      ),
                    ),
                  ),

                  // Kontrol playlist: ringan, tanpa panel putih besar.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                      child: Row(
                        children: [
                          // 👇 TOMBOL FILTER BARU (Gaya SongsPage)
                          GestureDetector(
                            onTap: _showFilterMenu,
                            child: Container(
                              key: _filterButtonKey,
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.sort,
                                    color: Colors.black87,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _currentSort,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          // 👇 TOMBOL SHUFFLE (Tetap seperti desain baru)
                          Material(
                            color: const Color(0xFFECE9E2),
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'Shuffle',
                              onPressed: _displayedSongs.isEmpty
                                  ? null
                                  : () => _playPlaylist(shuffle: true),
                              icon: const Icon(
                                Icons.shuffle_rounded,
                                color: Color(0xFF282722),
                                size: 21,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 👇 TOMBOL PLAY (Tetap seperti desain baru)
                          Material(
                            color: const Color(0xFF24231F),
                            shape: const CircleBorder(),
                            elevation: 3,
                            shadowColor: Colors.black.withValues(alpha: 0.18),
                            child: IconButton(
                              tooltip: 'Play',
                              onPressed: _displayedSongs.isEmpty
                                  ? null
                                  : () => _playPlaylist(),
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 2, 24, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOUR COLLECTION',
                                  style: TextStyle(
                                    color: Color(0xFF8A857B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Tracks',
                                  style: TextStyle(
                                    color: Color(0xFF26251F),
                                    fontSize: 23,
                                    height: 1.05,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECE9E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_displayedSongs.length} songs',
                              style: const TextStyle(
                                color: Color(0xFF69655D),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // PENTING: jangan bungkus PlaylistTrackList dengan
                  // Container, Column, atau SliverToBoxAdapter.
                  PlaylistTrackList(
                    displayedSongs: _displayedSongs,
                    isSelectionMode: _isSelectionMode,
                    selectedSongIds: _selectedSongIds,
                    currentSort: _currentSort,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        final song = _displayedSongs.removeAt(oldIndex);
                        _displayedSongs.insert(newIndex, song);
                        _songsInPlaylist = List<Song>.from(_displayedSongs);
                      });
                      _saveNewSongOrder();
                    },
                    onToggleSelection: (song) {
                      setState(() {
                        if (_selectedSongIds.contains(song.id)) {
                          _selectedSongIds.remove(song.id);
                        } else {
                          _selectedSongIds.add(song.id);
                        }
                        if (_selectedSongIds.isEmpty) {
                          _isSelectionMode = false;
                        }
                      });
                    },
                    onPlaySong: (song) {
                      final index = _displayedSongs.indexOf(song);
                      _playPlaylist(startIndex: index);
                    },
                    onLongPress: (song) {
                      if (!_isSelectionMode) {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedSongIds.add(song.id);
                        });
                      }
                    },
                    onShowOptions: (song) => _showSongOptions(song),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),

            // Gradient transparan berada di atas konten, bukan bidang putih.
            // Saat halaman discroll, bagian atas berubah gelap di belakang
            // tombol; saat header terlihat, gradient membaur dengan foto.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: topPadding + 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.68),
                        Colors.black.withValues(alpha: 0.32),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // TOP BAR tetap fixed sebagai overlay. Hanya tombolnya yang putih;
            // tidak ada panel putih full-width di belakangnya.
            if (_isSelectionMode)
              Positioned(
                top: topPadding + 12,
                left: 16,
                right: 16,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 8,
                      top: 4,
                      bottom: 4,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _selectAll,
                          child: Row(
                            children: [
                              Icon(
                                _selectedSongIds.length ==
                                            _displayedSongs.length &&
                                        _displayedSongs.isNotEmpty
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedSongIds.length} selected',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isSelectionMode = false;
                              _selectedSongIds.clear();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Positioned(
                top: topPadding + 12,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: const Padding(
                              padding: EdgeInsets.only(left: 16, right: 8),
                              child: Icon(
                                Icons.star_border,
                                color: Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showAddSongsToPlaylist,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.add,
                                color: Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showMoreMenu,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8, right: 16),
                              child: Icon(
                                Icons.more_horiz,
                                color: Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Action bar untuk mode seleksi.
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              top: _isSelectionMode ? topPadding + 72 : -100,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withValues(alpha: 0.9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomAction(Icons.play_arrow, 'Play', () {}),
                      _buildBottomAction(Icons.add, 'Add', () {}),
                      _buildBottomAction(
                        Icons.remove_circle_outline,
                        'Remove',
                        _removeSelectedSongs,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
