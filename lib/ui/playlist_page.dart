import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import 'playlist_detail_page.dart';
import 'dart:io';
import '../services/media_store_service.dart';
import '../features/playlist/widgets/playlist_cover.dart';
import '../preferences/preferences_provider.dart';

// Kabel untuk dipanggil dari home_page.dart
final GlobalKey<PlaylistPageState> playlistPageKey =
    GlobalKey<PlaylistPageState>();
final ValueNotifier<bool> playlistEditModeNotifier = ValueNotifier<bool>(false);
final ValueNotifier<bool> playlistViewModeNotifier = ValueNotifier<bool>(false);

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
  final bool _isMenuOpen = false;
  final GlobalKey<PlaylistDetailPageState> detailPageKey = GlobalKey();

  bool get isScrolledDown =>
      _scrollController.hasClients && _scrollController.offset > 10;

  @override
  void initState() {
    super.initState();
    // Pulihkan preferensi Grid/List terakhir, lalu sinkronkan notifier global.
    final prefs = ref.read(lyraPreferencesProvider);
    playlistViewModeNotifier.value = prefs.loadPlaylistIsListView();
    playlistViewModeNotifier.addListener(_persistViewMode);
    _loadPlaylists();
  }

  void _persistViewMode() {
    ref
        .read(lyraPreferencesProvider)
        .savePlaylistIsListView(playlistViewModeNotifier.value);
  }

  @override
  void dispose() {
    playlistViewModeNotifier.removeListener(_persistViewMode);
    _scrollController.dispose();
    super.dispose();
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

  void openPlaylist(Playlist playlist) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PlaylistDetailPage(key: detailPageKey, playlist: playlist),
      ),
      (route) => route.isFirst,
    ).then((_) => _loadPlaylists());
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
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade500,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // HEADER & TOMBOL CENTANG
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
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

                  // AREA FOTO & TOMBOL PENSIL
                  GestureDetector(
                    onTap: () async {
                      try {
                        // Panggil Galeri Native via Kotlin
                        final String? imagePath =
                            await MediaStoreService.pickImageFromGallery();

                        if (imagePath != null) {
                          // Gunakan setModalState agar UI di dalam bottom sheet ter-update
                          setModalState(() => tempImagePath = imagePath);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal membuka galeri: $e')),
                          );
                        }
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

    return ValueListenableBuilder<bool>(
      valueListenable: playlistViewModeNotifier,
      builder: (context, isListView, child) {
        // 1. TAMPILAN LIST
        if (isListView) {
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 100,
              bottom: 160,
              left: 16,
              right: 16,
            ),
            itemCount: _playlists.length,
            itemBuilder: (context, index) {
              return _buildPlaylistListTile(
                _playlists[index],
                index,
                isEditMode: false,
                key: ValueKey(_playlists[index].id),
              );
            },
          );
        }

        // TAMPILAN GRID (Bisa Long-Press untuk Reorder)
        return ReorderableGridView.count(
          controller: _scrollController,
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
            _saveNewOrder(); // Simpan urutan baru ke Database
          },
          dragWidgetBuilder: (index, child) {
            // Tampilan saat card sedang di-drag (melayang)
            return Material(
              color: Colors.transparent,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              child: child,
            );
          },
          children: _playlists.map((playlist) {
            return ReorderableDelayedDragStartListener(
              key: ValueKey(playlist.id),
              index: _playlists.indexOf(playlist),
              child: _buildPlaylistCard(
                playlist,
                isEditMode: false, // Ikon drag disembunyikan
                key: ValueKey(playlist.id),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPlaylistListTile(
    Playlist playlist,
    int index, {
    required bool isEditMode,
    required Key key,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEditMode || _isMenuOpen
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailPage(
                        key: detailPageKey,
                        playlist: playlist,
                      ),
                    ),
                  ).then((_) => _loadPlaylists());
                },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Cover Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: PlaylistCover(
                      playlistId: playlist.id,
                      imagePath: playlist.imagePath,
                      iconSize: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol Kanan
                if (isEditMode)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: Colors.grey,
                    ),
                  )
                else
                  Builder(
                    builder: (buttonContext) {
                      return IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
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
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(
    Playlist playlist, {
    required bool isEditMode,
    required Key key,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(20),
      onTap: isEditMode || _isMenuOpen
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailPage(
                    key: detailPageKey,
                    playlist: playlist,
                  ),
                ),
              ).then((_) => _loadPlaylists());
            },
      child: Container(
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
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: PlaylistCover(
                    playlistId: playlist.id,
                    imagePath: playlist.imagePath,
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
                      return IconButton(
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
