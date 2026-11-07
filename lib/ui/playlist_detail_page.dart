import '../main.dart';
import 'dart:io';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:lyra/features/playlist/sheets/add_tracks_sheet.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import '../audio/lyra_audio_handler.dart';
import '../../features/playlist/widgets/playlist_header.dart';
import '../../features/playlist/widgets/playlist_track_list.dart';
import '../../features/playlist/sheets/edit_playlist_sheet.dart';
import '../providers/songs_provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/song.dart' as local;
import '../widgets/lyra_header.dart';

class PlaylistDetailPage extends ConsumerStatefulWidget {
  final Playlist playlist;
  const PlaylistDetailPage({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailPage> createState() => PlaylistDetailPageState();
}

class PlaylistDetailPageState extends ConsumerState<PlaylistDetailPage> {
  List<Song> _songsInPlaylist = [];
  List<Song> _displayedSongs = [];
  bool _isLoading = true;
  late String _currentPlaylistName;
  String? _currentImagePath;
  String? _currentDescription;
  String _currentSort = 'Custom order';
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  Set<String> _selectedSongIds = {};
  String _searchQuery = '';

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
    // Filter berdasarkan pencarian
    List<Song> filtered = List.from(_songsInPlaylist);
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (s) =>
                s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.artist.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Urutkan
    _displayedSongs = filtered;
    if (_currentSort == 'Name' || _currentSort == 'Title') {
      _displayedSongs.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else if (_currentSort == 'Artist') {
      _displayedSongs.sort(
        (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
      );
    } else if (_currentSort == 'Album') {
      _displayedSongs.sort(
        (a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()),
      );
    } else if (_currentSort == 'Date Added' ||
        _currentSort == 'Recently added') {
      _displayedSongs.sort((a, b) => b.id.compareTo(a.id));
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

    // Ambil daftar lagu asli untuk mendapatkan albumId
    final allLocalSongs = ref.read(allSongsProvider).value ?? [];
    final songMap = {for (var s in allLocalSongs) s.id: s.albumId};

    Map<String, String> fetchedAlbumIds = {};
    for (var song in listToPlay) {
      final albumId = songMap[song.id]; // Cocokkan berdasarkan ID lagu
      if (albumId != null && albumId != '0') {
        fetchedAlbumIds[song.path] = albumId;
      }
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
      albumIds: fetchedAlbumIds,
      sourceType: 'Playlist',
      sourceName: widget.playlist.name,
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
    // Cari albumId SEBELUM memunculkan bottom sheet
    final albumIdStr = (ref.read(allSongsProvider).value ?? [])
        .firstWhere(
          (element) => element.id == song.id,
          orElse: () => local.Song(
            id: '',
            title: '',
            artist: '',
            album: '',
            path: '',
            durationMs: 0,
            albumId: '0',
          ),
        )
        .albumId;

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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: QueryArtworkWidget(
                      id: int.tryParse(albumIdStr) ?? 0,
                      type: ArtworkType.ALBUM,
                      size: 200,
                      artworkHeight: 50,
                      artworkWidth: 50,
                      artworkBorder: BorderRadius.circular(8),
                      nullArtworkWidget: const Icon(
                        Icons.music_note,
                        color: Colors.grey,
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

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Ubah nama context menjadi bottomSheetContext
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Urutkan dari:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Kirim bottomSheetContext ke fungsi
              _buildSortOption(bottomSheetContext, 'Urutan khusus'),
              _buildSortOption(bottomSheetContext, 'Judul'),
              _buildSortOption(bottomSheetContext, 'Artis'),
              _buildSortOption(bottomSheetContext, 'Album'),
              _buildSortOption(bottomSheetContext, 'Terakhir ditambahkan'),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // parameter bottomSheetContext
  Widget _buildSortOption(BuildContext bottomSheetContext, String title) {
    // Mapping nama tampilan ke logika di _applySort
    String sortKey = title;
    if (title == 'Urutan khusus') sortKey = 'Custom order';
    if (title == 'Judul') sortKey = 'Name';
    if (title == 'Artis') sortKey = 'Artist';
    if (title == 'Album') sortKey = 'Album';
    if (title == 'Terakhir ditambahkan') sortKey = 'Date Added';

    // Cek apakah opsi ini yang sedang aktif
    final isSelected = _currentSort == sortKey;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isSelected ? Colors.blue.shade700 : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: Colors.blue.shade700)
          : null,
      onTap: () {
        setState(() {
          _currentSort = sortKey;
          _applySort();
        });
        // Gunakan bottomSheetContext agar yang tertutup hanya Bottom Sheet-nya
        Navigator.pop(bottomSheetContext);
      },
    );
  }

  void _showInfoBottomSheet() {
    // 1. Hitung total detik dari semua lagu
    int totalSeconds = _songsInPlaylist.fold(
      0,
      (sum, song) => sum + (song.durationMs ~/ 1000),
    );

    // Format durasi lengkap
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;

    String durationText = '';
    if (hours > 0) {
      if (minutes > 0) {
        durationText = '$hours jam $minutes menit';
      } else {
        durationText = '$hours jam';
      }
    } else {
      durationText = '$minutes menit';
    }

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Info Playlist',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.music_note,
                'Total Lagu',
                '${_songsInPlaylist.length} lagu',
              ),
              _buildInfoRow(Icons.timer, 'Total Durasi', durationText),
              _buildInfoRow(
                Icons.calendar_today,
                'Tanggal Dibuat',
                DateFormat('dd/MM/yyyy').format(widget.playlist.createdAt),
              ),
              // Tampilkan total durasi yang sudah diformat
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSearchBottomSheet() {
    final TextEditingController searchController = TextEditingController(
      text: _searchQuery,
    );

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(
              context,
            ).viewInsets.bottom, // Agar tidak tertutup keyboard
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari lagu atau artis...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applySort();
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // Tombol Play (Kapsul Hitam)
  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: () => _playPlaylist(),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black, // Warna hitam pekat khas tombol Play
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Play',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tombol Play Acak (Lingkaran Abu-abu)
  Widget _buildShuffleButton() {
    return GestureDetector(
      onTap: () => _playPlaylist(shuffle: true),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.shuffle_rounded, color: Colors.black87, size: 20),
        ),
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

  bool get isScrolledDown =>
      _scrollController.hasClients && _scrollController.offset > 10;

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
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

                  // Kontrol playlist: Tombol Aksi Horizontal
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          _buildPlayButton(),
                          const SizedBox(width: 8),
                          _buildShuffleButton(),
                          const SizedBox(width: 12),
                          Container(
                            height: 30,
                            width: 1.5,
                            color: const Color.fromARGB(255, 206, 206, 206),
                          ),
                          const SizedBox(width: 12),
                          _buildActionPill(
                            icon: Icons.filter_list,
                            label: 'Urutkan',
                            onTap: _showSortBottomSheet,
                          ),
                          const SizedBox(width: 8),
                          _buildActionPill(
                            icon: Icons.format_list_bulleted,
                            label: 'Sesuaikan',
                            onTap: () {
                              setState(() {
                                _isSelectionMode = true;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildActionPill(
                            icon: Icons.search,
                            label: 'Cari',
                            onTap: _showSearchBottomSheet,
                          ),
                          const SizedBox(width: 8),
                          _buildActionPill(
                            icon: Icons.info_outline,
                            label: 'Info',
                            onTap: _showInfoBottomSheet,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  // PENTING: jangan bungkus PlaylistTrackList dengan
                  // Container, Column, atau SliverToBoxAdapter.
                  PlaylistTrackList(
                    displayedSongs: _displayedSongs,
                    albumIds: {
                      for (var s in (ref.watch(allSongsProvider).value ?? []))
                        s.id: s.albumId,
                    },
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
                  height: topPadding + 90,
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
            // TOP BAR OVERLAY
            if (_isSelectionMode)
              // TAMPILAN SAAT MULTI-SELECT (BAR HITAM)
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
                          onTap: () {
                            setState(() {
                              if (_selectedSongIds.length ==
                                  _displayedSongs.length) {
                                _selectedSongIds.clear();
                                _isSelectionMode = false;
                              } else {
                                _selectedSongIds = _displayedSongs
                                    .map((e) => e.id)
                                    .toSet();
                              }
                            });
                          },
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
              // TAMPILAN NORMAL (TOMBOL BACK & KAPSUL)
              Positioned(
                top: topPadding + 12,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Tombol Back (Kiri)
                    TopBarButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => Navigator.pop(context),
                    ),

                    // Kapsul Kanan (Star, Add, More)
                    TopBarButton(
                      isCircle: false, // Kapsul
                      onTap: () {}, // Dummy karena di dalamnya ada tombol
                      customChild: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Tombol Star
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {},
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.star_border,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // Tombol Add
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _showAddSongsToPlaylist,
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.add,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          // Tombol More
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _showMoreMenu,
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.more_horiz,
                                  color: Colors.black87,
                                  size: 20,
                                ),
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
