import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import 'albums_page.dart';
import 'artists_page.dart';
import 'folders_page.dart';
import 'favorites_page.dart';
import '../l10n/app_localizations.dart';
import '../providers/songs_provider.dart';
import '../theme/lyra_colors.dart';

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
  int _totalPlaylists = 0;
  final ScrollController _scrollController = ScrollController();

  bool get isScrolledDown =>
      _scrollController.hasClients && _scrollController.offset > 10;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Tambahkan dispose
    super.dispose();
  }

  Future<void> _loadStats() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final favs = await db.getAllFavoriteSongs();
      final playlists = await db.select(db.playlists).get();

      if (mounted) {
        setState(() {
          _totalFavorites = favs.length;
          _totalPlaylists = playlists.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data perpustakaan.')),
        );
      }
    }
  }

  Future<void> refreshStats() async {
    // Panggil refresh untuk provider dan stats
    try {
      ref.invalidate(allSongsProvider);
      await ref.read(allSongsProvider.future);
      await _loadStats();
    } catch (e) {
      debugPrint('Error refreshing: $e');
    }
  }

  void showMoreMenu(BuildContext buttonContext) {
    final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  width: 220,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
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
                      _buildPopoverItem(
                        Icons.refresh,
                        AppLocalizations.of(context)!.refresh,
                        () async {
                          Navigator.pop(context);
                          await refreshStats();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!.dataUpdated,
                                ),
                              ),
                            );
                          }
                        },
                        colors,
                      ),
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

  Widget _buildPopoverItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    LyraColors colors,
  ) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: colors.textPrimary, size: 20),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, color: colors.textPrimary),
        ),
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
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSongsAsync = ref.watch(allSongsProvider);
    final allSongs = allSongsAsync.value ?? [];

    // Perhitungan Album & Artist (Abaikan string kosong/spasi & kapitalisasi)
    final validAlbums = allSongs
        .where(
          (s) =>
              s.album.trim().isNotEmpty &&
              s.album.toLowerCase() != 'unknown album',
        )
        .map((s) => s.album.trim().toLowerCase());
    final totalAlbums = validAlbums.toSet().length;

    final validArtists = allSongs
        .where(
          (s) =>
              s.artist.trim().isNotEmpty &&
              s.artist.toLowerCase() != 'unknown artist',
        )
        .map((s) => s.artist.trim().toLowerCase());
    final totalArtists = validArtists.toSet().length;

    // Perhitungan Folder (Gunakan full path direktori, bukan cuma nama akhir)
    final totalFolders = allSongs
        .where((s) => s.path.contains('/'))
        .map((s) {
          final dir = s.path.substring(0, s.path.lastIndexOf('/'));
          return dir.trim();
        })
        .where((dir) => dir.isNotEmpty)
        .toSet()
        .length;

    return Stack(
      children: [
        ListView(
          controller: _scrollController, // Controller dipasang di sini
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 80,
            bottom: 160,
            left: 16,
            right: 16,
          ),
          children: [
            Text(
              AppLocalizations.of(context)!.allCollections,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildCategoryCard(
              AppLocalizations.of(context)!.favorites,
              AppLocalizations.of(
                context,
              )!.songsCount(_isLoading ? 0 : _totalFavorites),
              Icons.favorite,
              Colors.redAccent,
              isDark,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesPage()),
                );
              },
              colors,
            ),
            const SizedBox(height: 12),
            _buildCategoryCard(
              AppLocalizations.of(context)!.albums,
              AppLocalizations.of(context)!.albumsCount(totalAlbums),
              Icons.album,
              Colors.blueAccent,
              isDark,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlbumsPage()),
              ),
              colors,
            ),
            const SizedBox(height: 12),
            _buildCategoryCard(
              AppLocalizations.of(context)!.artists,
              AppLocalizations.of(context)!.artistsCount(totalArtists),
              Icons.person,
              Colors.greenAccent.shade700,
              isDark,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArtistsPage()),
              ),
              colors,
            ),
            const SizedBox(height: 12),
            _buildCategoryCard(
              AppLocalizations.of(context)!.folders,
              AppLocalizations.of(context)!.foldersCount(totalFolders),
              Icons.folder,
              Colors.orangeAccent.shade700,
              isDark,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FoldersPage()),
              ),
              colors,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    allSongsAsync.isLoading
                        ? '...'
                        : allSongs.length.toString(),
                    AppLocalizations.of(context)!.totalSongs,
                    colors,
                  ),
                  _buildStatDivider(colors),
                  _buildStatItem(
                    _totalPlaylists.toString(),
                    AppLocalizations.of(context)!.playlists,
                    colors,
                  ),
                ],
              ),
            ),
          ],
        ),

        if (_isLoading)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onTap,
    LyraColors colors,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
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
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(
                Icons.arrow_forward_ios,
                color: colors.textSecondary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, LyraColors colors) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(LyraColors colors) {
    return Container(
      height: 30,
      width: 1,
      color: colors.textSecondary.withValues(alpha: 0.2),
    );
  }
}
