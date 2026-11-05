import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import 'playlist_detail_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// Kabel untuk dipanggil dari home_page.dart
final GlobalKey<PlaylistPageState> playlistPageKey =
    GlobalKey<PlaylistPageState>();
final ValueNotifier<bool> playlistEditModeNotifier = ValueNotifier<bool>(false);

class PlaylistPage extends ConsumerStatefulWidget {
  const PlaylistPage({super.key});

  @override
  ConsumerState<PlaylistPage> createState() => PlaylistPageState();
}

class PlaylistPageState extends ConsumerState<PlaylistPage> {
  List<Playlist> _playlists = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  bool isEditMode = false;
  bool _isMenuOpen = false;
  final Map<int, GlobalKey> _cardKeys = {};
  final Map<int, GlobalKey> _moreButtonKeys = {};

  bool get isScrolledDown =>
      _scrollController.hasClients && _scrollController.offset > 10;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    // Urutkan berdasarkan sortOrder
    final data = await (db.select(
      db.playlists,
    )..orderBy([(t) => drift.OrderingTerm(expression: t.sortOrder)])).get();
    setState(() {
      _playlists = data;
      _isLoading = false;
    });
  }

  // Fungsi Publik: Toggle Mode Edit
  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
    playlistEditModeNotifier.value = isEditMode;
  }

  // Fungsi Simpan Urutan Baru ke DB
  Future<void> _saveNewOrder() async {
    final db = ref.read(databaseProvider);
    for (int i = 0; i < _playlists.length; i++) {
      await (db.update(db.playlists)
            ..where((t) => t.id.equals(_playlists[i].id)))
          .write(PlaylistsCompanion(sortOrder: drift.Value(i)));
    }
  }

  void showCreatePlaylistDialog() {
    final TextEditingController nameController = TextEditingController();
    String? tempImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 16,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. HEADER & TOMBOL CENTANG
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        width: 48,
                      ), // Spacer untuk menyeimbangkan judul
                      const Text(
                        'Buat Playlist Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nama playlist tidak boleh kosong',
                                ),
                              ),
                            );
                            return;
                          }

                          final db = ref.read(databaseProvider);
                          await db
                              .into(db.playlists)
                              .insert(
                                PlaylistsCompanion.insert(
                                  name: name,
                                  imagePath: drift.Value(tempImagePath),
                                ),
                              );

                          if (context.mounted) {
                            Navigator.pop(context); // Tutup bottom sheet
                          }
                          _loadPlaylists(); // Refresh list
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. AREA FOTO & TOMBOL PENSIL
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        setModalState(() => tempImagePath = image.path);
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 220, // Ukuran gambar cukup besar
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
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
                        // Ikon Kecil
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. INPUT NAMA PLAYLIST
                  TextField(
                    controller: nameController,
                    autofocus: false, // Biarkan user lihat fotonya dulu
                    decoration: InputDecoration(
                      labelText: 'Nama Playlist',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.queue_music,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showMoreMenu(BuildContext buttonContext) {
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
                    _buildPopoverItem(Icons.sort, 'Urutkan', () {
                      Navigator.pop(context);
                      showFilterDialog();
                    }),
                    const Divider(height: 1, thickness: 0.5),
                    _buildPopoverItem(
                      Icons.create_new_folder_outlined,
                      'Buat Playlist',
                      () {
                        Navigator.pop(context);
                        showCreatePlaylistDialog();
                      },
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

  void _showCardPopover(BuildContext buttonContext, Playlist playlist) {
    final renderObject = buttonContext.findRenderObject();
    if (renderObject is! RenderBox) return;

    final RenderBox renderBox = renderObject;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;

    const double popoverWidth = 180.0; // Lebar popover
    final double buttonCenter = offset.dx + (renderBox.size.width / 2);
    // Posisi awal: kita taruh popover tepat di tengah bawah tombol
    double leftPosition = buttonCenter - (popoverWidth / 2);

    // Cek apakah popover keluar batas KIRI layar
    if (leftPosition < 16.0) {
      leftPosition = 16.0; // Paksa mentok 16px dari kiri layar
    }
    // Cek apakah popover keluar batas KANAN layar
    else if (leftPosition + popoverWidth > screenWidth - 16.0) {
      leftPosition =
          screenWidth -
          popoverWidth -
          16.0; // Paksa mentok 16px dari kanan layar
    }

    // Posisi Vertikal (Tepat di bawah tombol)
    final double topPosition = offset.dy + renderBox.size.height - 27;

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
                  width: popoverWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuOption(Icons.playlist_play, 'Play', () {
                        Navigator.pop(context);
                      }),
                      _buildMenuOption(Icons.edit_outlined, 'Edit', () {
                        Navigator.pop(context);
                      }),
                      _buildMenuOption(Icons.delete_outline, 'Delete', () {
                        Navigator.pop(context);
                      }, isDestructive: true),
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

  Widget _buildPopoverItem(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: Colors.black87, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        onTap: onTap,
      ),
    );
  }

  void showFilterDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur filter playlist segera hadir!')),
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_playlists.isEmpty) return _buildEmptyState();

    // 1. TAMPILAN MODE EDIT (Drag & Drop)
    if (isEditMode) {
      return ReorderableGridView.count(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 100,
          bottom: 160,
          left: 16,
          right: 16,
        ),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            final item = _playlists.removeAt(oldIndex);
            _playlists.insert(newIndex, item);
          });
          _saveNewOrder(); // Simpan otomatis
        },
        children: _playlists.map((playlist) {
          return _buildPlaylistCard(
            playlist,
            isEditMode: true,
            key: ValueKey(playlist.id),
          );
        }).toList(),
      );
    }

    // 2. TAMPILAN NORMAL
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 100,
        bottom: 160,
        left: 16,
        right: 16,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        return _buildPlaylistCard(
          _playlists[index],
          isEditMode: false,
          key: ValueKey(_playlists[index].id),
        );
      },
    );
  }

  Widget _buildPlaylistCard(
    Playlist playlist, {
    required bool isEditMode,
    required Key key,
  }) {
    // Pakai key yang stabil per playlist (tidak dibuat ulang tiap build)
    final GlobalKey cardKey = _cardKeys.putIfAbsent(
      playlist.id,
      () => GlobalKey(),
    );

    // Cek apakah playlist punya gambar
    final bool hasImage =
        playlist.imagePath != null && playlist.imagePath!.isNotEmpty;

    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(20),
      onTap: isEditMode || _isMenuOpen
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailPage(playlist: playlist),
                ),
              ).then((_) => _loadPlaylists());
            },
      child: Container(
        key: cardKey,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  // Jika ada gambar, gradient merah dihilangkan
                  gradient: hasImage
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.red.shade400, Colors.red.shade800],
                        ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Stack(
                    fit: StackFit.expand, // Memaksa isi stack memenuhi area
                    children: [
                      // 1. TAMPILKAN GAMBAR GALERI JIKA ADA
                      if (hasImage)
                        Image.file(
                          File(playlist.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Jika file terhapus, tampilkan ikon
                            return const Center(
                              child: Icon(
                                Icons.queue_music,
                                size: 50,
                                color: Colors.white54,
                              ),
                            );
                          },
                        )
                      else
                        // 2. JIKA TIDAK ADA GAMBAR, TAMPILKAN IKON DEFAULT
                        const Center(
                          child: Icon(
                            Icons.queue_music,
                            size: 50,
                            color: Colors.white54,
                          ),
                        ),

                      // 3. IKON DRAG (Hanya mode edit)
                      if (isEditMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.drag_indicator,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 4.0, // Kurangi padding kanan agar tombol mepet
                top: 8.0,
                bottom: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Builder(
                    builder: (buttonContext) {
                      final moreKey = _moreButtonKeys.putIfAbsent(
                        playlist.id,
                        () => GlobalKey(),
                      );
                      return IconButton(
                        key: moreKey,
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.black54,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          _showCardPopover(buttonContext, playlist);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk baris menu popover
  Widget _buildMenuOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : Colors.black87;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Belum Ada Playlist',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buat playlist pertamamu untuk\nmengelompokkan lagu favoritmu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
