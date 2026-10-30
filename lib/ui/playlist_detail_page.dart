import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import '../database/database.dart';
import '../main.dart';
import '../providers/database_provider.dart';
import '../audio/lyra_audio_handler.dart';

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

  String _currentSort = 'Custom order';
  bool _addToBottom = true;

  // === STATE UNTUK MULTI-SELECT & REORDER ===
  bool _isSelectionMode = false;
  Set<String> _selectedSongIds = {};

  @override
  void initState() {
    super.initState();
    _currentPlaylistName = widget.playlist.name;
    _currentImagePath = widget.playlist.imagePath;
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final data = await db.getSongsInPlaylist(widget.playlist.id);
    setState(() {
      _songsInPlaylist = data;
      _applySort();
      _isLoading = false;
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
    setState(() {});
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

  // === FUNGSI UNTUK MULTI-SELECT & REORDER ===
  void _toggleSelection(Song song) {
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
    await (db.delete(db.playlistSongs)..where(
          (t) =>
              t.playlistId.equals(widget.playlist.id) &
              t.songId.isIn(_selectedSongIds),
        ))
        .go();

    _isSelectionMode = false;
    _selectedSongIds.clear();
    _loadSongs();
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
    final RenderBox renderBox =
        _filterButtonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double topPosition = offset.dy - renderBox.size.height;
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
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                _showAddTracksBottomSheet();
                              },
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
          Navigator.pop(context);
        },
      ),
    );
  }

  // ==========================================
  // UI BOTTOM SHEET & EDIT PLAYLIST
  // ==========================================
  void _showAddTracksBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add tracks to',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      !_addToBottom
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: !_addToBottom ? Colors.blue.shade700 : Colors.grey,
                    ),
                    title: const Text(
                      'Top of playlist',
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                    onTap: () => setModalState(() => _addToBottom = false),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _addToBottom
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _addToBottom ? Colors.blue.shade700 : Colors.grey,
                    ),
                    title: const Text(
                      'Bottom of playlist',
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                    onTap: () => setModalState(() => _addToBottom = true),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditPlaylistBottomSheet() {
    final TextEditingController nameController = TextEditingController(
      text: _currentPlaylistName,
    );
    String? tempImagePath = _currentImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edit Playlist',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: tempImagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file(
                                        File(tempImagePath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: GestureDetector(
                                onTap: () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  if (image != null)
                                    setModalState(
                                      () => tempImagePath = image.path,
                                    );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Playlist',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              if (nameController.text.trim().isEmpty) return;
                              final db = ref.read(databaseProvider);
                              await (db.update(db.playlists)..where(
                                    (t) => t.id.equals(widget.playlist.id),
                                  ))
                                  .write(
                                    PlaylistsCompanion(
                                      name: drift.Value(
                                        nameController.text.trim(),
                                      ),
                                      imagePath: drift.Value(tempImagePath),
                                    ),
                                  );
                              if (context.mounted) {
                                Navigator.pop(context);
                                setState(() {
                                  _currentPlaylistName = nameController.text
                                      .trim();
                                  _currentImagePath = tempImagePath;
                                });
                              }
                            },
                            child: const Text(
                              'Simpan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      },
    );
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
                width: 260,
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
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTopAction(
                            Icons.add_circle_outline,
                            'Add',
                            () {},
                          ),
                          _buildTopAction(Icons.star_border, 'Favorite', () {}),
                          _buildTopAction(Icons.edit, 'Edit', () {
                            Navigator.pop(context);
                            _showEditPlaylistBottomSheet();
                          }),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    _buildListTile(
                      Icons.playlist_add,
                      'Add to Playlist',
                      () {},
                    ),
                    _buildListTile(Icons.playlist_play, 'Play Next', () {}),
                    _buildListTile(
                      Icons.thumb_down_alt_outlined,
                      'Suggest Less',
                      () {},
                    ),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
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
          Navigator.pop(context);
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F2F7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // HEADER GAMBAR
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.width,
                pinned: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _currentImagePath != null
                          ? Image.file(
                              File(_currentImagePath!),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 16,
                        right: 16,
                        child: Column(
                          children: [
                            Text(
                              _currentPlaylistName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_songsInPlaylist.length} tracks',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // MENU & DAFTAR LAGU
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Baris Filter
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Row(
                          children: [
                            Builder(
                              builder: (buttonContext) {
                                return GestureDetector(
                                  key: _filterButtonKey,
                                  onTap: _showFilterMenu,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.sort,
                                        color: Colors.black87,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _currentSort,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.shuffle,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                onPressed: () => _playPlaylist(shuffle: true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () => _playPlaylist(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Daftar Lagu
                      if (_displayedSongs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.music_note,
                                size: 60,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada lagu.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      // MODE SELECT
                      else if (_isSelectionMode)
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: _displayedSongs.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final song = _displayedSongs.removeAt(oldIndex);
                              _displayedSongs.insert(newIndex, song);
                            });
                          },
                          itemBuilder: (context, index) {
                            final song = _displayedSongs[index];
                            final isSelected = _selectedSongIds.contains(
                              song.id,
                            );

                            return ReorderableDelayedDragStartListener(
                              key: ValueKey(song.id),
                              index: index,
                              child: Material(
                                color: isSelected
                                    ? Colors.blue.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  onTap: () => _toggleSelection(song),
                                  leading: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? Colors.blue.shade700
                                        : Colors.grey,
                                  ),
                                  title: Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  trailing: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.keyboard_arrow_up,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      // MODE NORMAL
                      else
                        Material(
                          color: Colors.transparent,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _displayedSongs.length,
                            itemBuilder: (context, index) {
                              final song = _displayedSongs[index];
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    song.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.white,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24),
                                          ),
                                        ),
                                        builder: (context) => SafeArea(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: const Icon(
                                                        Icons.music_note,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            song.title,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          Text(
                                                            song.artist,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 13,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
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
                                                  Icons.playlist_add,
                                                  color: Colors.black87,
                                                ),
                                                title: const Text(
                                                  'Add to Playlist',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Fitur Add to Playlist segera hadir',
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.info_outline,
                                                  color: Colors.black87,
                                                ),
                                                title: const Text(
                                                  'Track details',
                                                ),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _showTrackDetails(song);
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.album,
                                                  color: Colors.black87,
                                                ),
                                                title: const Text('Album'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Fitur Album segera hadir',
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.person,
                                                  color: Colors.black87,
                                                ),
                                                title: const Text('Artist'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Fitur Artist segera hadir',
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.share,
                                                  color: Colors.black87,
                                                ),
                                                title: const Text('Share'),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                                title: const Text(
                                                  'Delete from Playlist',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
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
                                    },
                                  ),
                                  onTap: () => _playPlaylist(startIndex: index),
                                  onLongPress: () {
                                    if (!_isSelectionMode) {
                                      setState(() {
                                        _isSelectionMode = true;
                                        _selectedSongIds.add(song.id);
                                      });
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // TOP BAR
          if (_isSelectionMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  bottom: 12,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _selectAll,
                      child: Row(
                        children: [
                          Icon(
                            _selectedSongIds.length == _displayedSongs.length &&
                                    _displayedSongs.isNotEmpty
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedSongIds.length} selected',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
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
            )
          else
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
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
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
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
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              Icons.person_add_alt_1,
                              color: Colors.black87,
                              size: 20,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.ios_share,
                              color: Colors.black87,
                              size: 20,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showMoreMenu,
                          child: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 16),
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

          // BOTTOM BAR
          if (_isSelectionMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                  top: 8,
                ),
                color: Colors.black87,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomAction(Icons.play_arrow, 'Play', () {}),
                    _buildBottomAction(Icons.add, 'Add', () {}),
                    _buildBottomAction(Icons.share, 'Share', () {}),
                    _buildBottomAction(
                      Icons.remove_circle_outline,
                      'Remove',
                      _removeSelectedSongs,
                    ),
                  ],
                ),
              ),
            ),
        ],
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
