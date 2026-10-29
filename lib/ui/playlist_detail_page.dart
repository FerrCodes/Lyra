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
  bool _isLoading = true;
  late String _currentPlaylistName;
  String? _currentImagePath;

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
      _isLoading = false;
    });
  }

  void _playPlaylist({bool shuffle = false}) {
    if (_songsInPlaylist.isEmpty) return;
    final handler = audioHandler as LyraAudioHandler;
    final listToPlay = shuffle
        ? (List.from(_songsInPlaylist)..shuffle())
        : _songsInPlaylist;
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
      0,
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
              top: MediaQuery.of(context).padding.top + 0,
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
                    _buildListTile(Icons.playlist_add, 'Add to Playlist'),
                    _buildListTile(Icons.playlist_play, 'Play Next'),
                    _buildListTile(
                      Icons.thumb_down_alt_outlined,
                      'Suggest Less',
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

  Widget _buildListTile(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: () => Navigator.pop(context),
    );
  }

  // =========================================================
  // UI UTAMA (TANPA BACKGROUND MEMANJANG DI BELAKANG PILL)
  // =========================================================
  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        backgroundColor: Color(0xFFF2F2F7),
        body: Center(child: CircularProgressIndicator()),
      );

    // Tentukan tinggi gambar header
    final double headerHeight = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          // 1. KONTEN YANG BISA DI-SCROLL
          CustomScrollView(
            slivers: [
              // Menggunakan SliverToBoxAdapter sebagai pengganti SliverAppBar
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Gambar Header (Full 1:1)
                    SizedBox(
                      height: headerHeight,
                      width: double.infinity,
                      child: Stack(
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

                          // Overlay Gradient
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.black.withValues(alpha: 0.7),
                                  Colors.black.withValues(alpha: 0.9),
                                ],
                                stops: const [0.0, 0.4, 0.8, 1.0],
                              ),
                            ),
                          ),

                          // Judul & Jumlah Lagu
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

                    // Daftar Lagu (Desain Samsung Music)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.sort,
                                  color: Colors.black87,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Custom order',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
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
                                    onPressed: () =>
                                        _playPlaylist(shuffle: true),
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
                          const Divider(height: 1),

                          if (_songsInPlaylist.isEmpty)
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
                          else
                            Material(
                              color: Colors.transparent,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _songsInPlaylist.length,
                                itemBuilder: (context, index) {
                                  final song = _songsInPlaylist[index];
                                  return Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 4,
                                          ),
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.more_vert,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {},
                                      ),
                                      onTap: () {
                                        final handler =
                                            audioHandler as LyraAudioHandler;
                                        handler.playQueue(
                                          _songsInPlaylist
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
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 100), // Jarak aman bawah
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. PILL MELAYANG (TIDAK ADA BACKGROUND MEMANJANG)
          // Posisi ini dikunci di atas layar, tidak terpengaruh scroll
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Pill Back
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
                // Pill Kanan (3 Ikon)
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
                      IconButton(
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          color: Colors.black87,
                          size: 20,
                        ),
                        onPressed: () {},
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.ios_share,
                          color: Colors.black87,
                          size: 20,
                        ),
                        onPressed: () {},
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.more_horiz,
                          color: Colors.black87,
                          size: 20,
                        ),
                        onPressed: _showMoreMenu,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
