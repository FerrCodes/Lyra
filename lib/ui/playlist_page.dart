import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import 'playlist_detail_page.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

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

  void showCreatePlaylistDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buat Playlist Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nama Playlist',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      final db = ref.read(databaseProvider);
      await db
          .into(db.playlists)
          .insert(PlaylistsCompanion.insert(name: name.trim()));
      _loadPlaylists();
    }
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

  void _showInstagramMenu(
    Offset globalPosition,
    Playlist playlist,
    GlobalKey cardKey,
  ) {
    HapticFeedback.mediumImpact();
    setState(() => _isMenuOpen = true);

    // Dapatkan posisi card asli di layar
    final RenderBox renderBox =
        cardKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) {
        // Lebar menu dibuat tetap (tidak ikut lebar card)
        const double menuWidth = 220;

        // Cek apakah menu muat di bawah card, jika tidak taruh di atas card
        final bool isBottomHalf =
            position.dy > MediaQuery.of(context).size.height / 2;

        return Stack(
          children: [
            // Background Gelap + Blur
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() => _isMenuOpen = false);
                  overlayEntry.remove();
                },
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withValues(alpha: 0.5)),
                ),
              ),
            ),

            // Card Palsu (Melayang)
            Positioned(
              top: position.dy,
              left: position.dx,
              width: size.width,
              height: size.height,
              child: Transform.scale(
                scale: 1.05,
                child: Material(
                  color: Colors.transparent,
                  child: _buildPlaylistCard(
                    playlist,
                    isEditMode: false,
                    key: UniqueKey(),
                  ),
                ),
              ),
            ),

            // Menu Opsi
            Positioned(
              // Jika card di bawah layar, taruh menu di atas card. Jika di atas, taruh di bawah.
              top: isBottomHalf
                  ? position.dy - 230
                  : position.dy + size.height + 10,
              left: ((position.dx + (size.width / 2)) - (menuWidth / 2)).clamp(
                14.0,
                MediaQuery.of(context).size.width - menuWidth - 14.0,
              ),
              width: menuWidth,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuOption(Icons.play_arrow_rounded, 'Play', () {
                        setState(() => _isMenuOpen = false);
                        overlayEntry.remove();
                      }),
                      _buildMenuOption(Icons.edit_outlined, 'Edit', () {
                        setState(() => _isMenuOpen = false);
                        overlayEntry.remove();
                      }),
                      _buildMenuOption(Icons.share_outlined, 'Share', () {
                        setState(() => _isMenuOpen = false);
                        overlayEntry.remove();
                      }),
                      _buildMenuOption(Icons.delete_outline, 'Delete', () {
                        setState(() => _isMenuOpen = false);
                        overlayEntry.remove();
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

    Overlay.of(context).insert(overlayEntry);
  }

  // Widget Helper untuk baris menu ala Instagram
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
    final GlobalKey cardKey = GlobalKey();
    // Kita butuh StatefulBuilder atau Timer untuk menangani delay tap vs long press
    // Tapi cara paling simpel adalah menggunakan InkWell bawaan
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(
        20,
      ), // Agar efek ripple mengikuti sudut card
      onTap: isEditMode || _isMenuOpen
          ? null
          : () {
              // JIKA KLIK BIASA: Masuk ke detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaylistDetailPage(playlist: playlist),
                ),
              ).then((_) => _loadPlaylists());
            },
      onLongPress: isEditMode
          ? null
          : () {
              // JIKA TEKAN LAMA: Munculkan menu
              _showInstagramMenu(Offset.zero, playlist, cardKey);
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.red.shade400, Colors.red.shade800],
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.queue_music,
                        size: 50,
                        color: Colors.white54,
                      ),
                    ),
                    // Ikon Drag khusus mode edit
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
            Padding(
              padding: const EdgeInsets.all(12.0),
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
                  const SizedBox(height: 4),
                  Text(
                    'Playlist Pribadi',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
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
