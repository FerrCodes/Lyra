import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import 'albums_page.dart';
import 'artists_page.dart';
import 'folders_page.dart';
import '../providers/songs_provider.dart';

// Kabel untuk dipanggil dari home_page.dart
final GlobalKey<LibraryPageState> libraryPageKey =
    GlobalKey<LibraryPageState>();

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => LibraryPageState();
}

class LibraryPageState extends ConsumerState<LibraryPage> {
  bool _isLoading = true;
  int _totalFavorites = 0;
  final ScrollController _scrollController = ScrollController();
  bool get isScrolledDown => _scrollController.hasClients && _scrollController.offset > 10;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final favs = await db.getAllFavoriteSongs();

    if (mounted) {
      setState(() {
        _totalFavorites = favs.length;
        _isLoading = false;
      });
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
              // Menggunakan rumus yang sama persis seperti halaman detail playlist
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 220, // Lebar disesuaikan
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
                    _buildPopoverItem(Icons.refresh, 'Refresh', () {
                      Navigator.pop(context);
                      _loadStats();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data diperbarui')),
                      );
                    }),
                    const Divider(height: 1, thickness: 0.5),
                    _buildPopoverItem(
                      Icons.account_tree_outlined,
                      'View as Tree',
                      () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur View as Tree segera hadir'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    _buildPopoverItem(Icons.graphic_eq, 'Equalizer', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitur Equalizer segera hadir'),
                        ),
                      );
                    }),
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
    // 1. Ambil semua lagu dari provider (otomatis update jika ada lagu baru)
    final allSongsAsync = ref.watch(allSongsProvider);

    // 2. Ambil daftar lagunya (jika masih loading, gunakan list kosong)
    final allSongs = allSongsAsync.value ?? [];

    // 3. Hitung jumlah masing-masing kategori
    final int totalAlbums = allSongs.map((s) => s.album).toSet().length;
    final int totalArtists = allSongs.map((s) => s.artist).toSet().length;

    // 4. Hitung jumlah folder dari path file
    final int totalFolders = allSongs
        .map((s) {
          final parts = s.path.split('/');
          return parts.length > 1 ? parts[parts.length - 2] : 'Unknown Folder';
        })
        .toSet()
        .length;

    return ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        bottom: 160,
        left: 16,
        right: 16,
      ),
      children: [
        const Text(
          'Semua Koleksi',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // === 4 CARD LIST VERTIKAL ===
        _buildCategoryCard(
          'Favorit',
          Icons.favorite,
          Colors.redAccent,
          _isLoading ? 0 : _totalFavorites,
          () {
            /* Nanti arahkan ke halaman Favorit */
          },
        ),
        const SizedBox(height: 12), // Jarak antar card

        _buildCategoryCard(
          'Album',
          Icons.album,
          Colors.blueAccent,
          totalAlbums,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlbumsPage()),
            );
          },
        ),
        const SizedBox(height: 12),

        _buildCategoryCard(
          'Artis',
          Icons.person,
          Colors.greenAccent.shade700, // Warna hijau yang lebih pekat
          totalArtists,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArtistsPage()),
            );
          },
        ),
        const SizedBox(height: 12),

        _buildCategoryCard(
          'Folder',
          Icons.folder,
          Colors.orangeAccent.shade700, // Warna oranye yang lebih pekat
          totalFolders,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FoldersPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    String title,
    IconData icon,
    Color color,
    int count,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80, // Tinggi card list
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. Garis Warna di Kiri (Aksen)
            Container(
              width: 8,
              height: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // 2. Kotak Ikon Berwarna Pastel
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), // Warna pastel
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color, // Ikon warna solid
                size: 26,
              ),
            ),

            const SizedBox(width: 16),

            // 3. Teks (Judul & Jumlah)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count Lagu',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // 4. Tombol Arrow Right
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
