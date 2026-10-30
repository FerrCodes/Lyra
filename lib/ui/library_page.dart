import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import 'albums_page.dart';
import 'artists_page.dart';
import 'folders_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        bottom: 160,
        left: 16,
        right: 16,
      ),
      children: [
        const Text(
          'Koleksi Saya',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // ==========================================
        // KATEGORI (GRID)
        // ==========================================
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                'Favorit',
                Icons.favorite,
                Colors.red.shade400,
                _isLoading ? 0 : _totalFavorites,
                () {
                  /* Nanti arahkan ke halaman Favorit */
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCategoryCard(
                'Album',
                Icons.album,
                Colors.blue.shade400,
                0,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AlbumsPage()),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                'Artis',
                Icons.person,
                Colors.green.shade400,
                0,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ArtistsPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCategoryCard(
                'Folder',
                Icons.folder,
                Colors.orange.shade400,
                0,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FoldersPage()),
                  );
                },
              ),
            ),
          ],
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
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Text(
                '$count Lagu',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              right: -10,
              child: Icon(
                icon,
                size: 80,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
