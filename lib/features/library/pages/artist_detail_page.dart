import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../database/database.dart';
import '../../../main.dart';
import '../../../models/song.dart' as local;
import '../../../providers/songs_provider.dart';
import '../../../theme/lyra_colors.dart';
import '../../../audio/lyra_audio_handler.dart';
import '../../../widgets/lyra_header.dart'; // Untuk TopBarButton
import '../../../widgets/lyra_bottom_bar.dart'; // Untuk PressableScale
import '../library_logic.dart';
import '../widgets/library_song_row.dart';
import 'album_detail_page.dart';

class ArtistDetailPage extends ConsumerStatefulWidget {
  final String artistName;

  const ArtistDetailPage({super.key, required this.artistName});

  @override
  ConsumerState<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends ConsumerState<ArtistDetailPage> {
  int _selectedTab = 0; // 0 = Lagu, 1 = Album

  void _playArtistSongs(
    List<local.Song> allArtistSongs,
    int startIndex, {
    bool shuffle = false,
  }) {
    if (allArtistSongs.isEmpty) return;

    final handler = audioHandler as LyraAudioHandler;
    List<local.Song> listToPlay = List.from(allArtistSongs);
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
      albumIds: {for (var s in listToPlay) s.path: s.albumId},
      sourceType: 'Artis',
      sourceName: widget.artistName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;
    final allSongs = ref.watch(allSongsProvider).value ?? [];

    final artistSongs = songsOfArtist(allSongs, widget.artistName);
    final artistAlbums = albumsOfArtist(allSongs, widget.artistName);

    if (artistSongs.isEmpty) {
      return Scaffold(
        backgroundColor: colors.pageBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Artis tidak ditemukan.',
            style: TextStyle(color: colors.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // HEADER & TABS
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 72,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.artistName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${artistSongs.length} lagu • ${artistAlbums.length} album',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CUSTOM PILL TABS
                      Row(
                        children: [
                          _buildTabPill(
                            label: 'Lagu (${artistSongs.length})',
                            isActive: _selectedTab == 0,
                            onTap: () => setState(() => _selectedTab = 0),
                            colors: colors,
                          ),
                          const SizedBox(width: 12),
                          _buildTabPill(
                            label: 'Album (${artistAlbums.length})',
                            isActive: _selectedTab == 1,
                            onTap: () => setState(() => _selectedTab = 1),
                            colors: colors,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // TAB CONTENT DENGAN ANIMATED SWITCHER
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _selectedTab == 0
                      ? _buildSongsTab(artistSongs, artistAlbums, colors)
                      : _buildAlbumsTab(artistAlbums, colors),
                ),
              ),

              // BOTTOM PADDING
              const SliverToBoxAdapter(child: SizedBox(height: 160)),
            ],
          ),

          // TOP BAR MENGAMBANG
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                TopBarButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required LyraColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colors.textPrimary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSongsTab(
    List<local.Song> artistSongs,
    List<AlbumGroup> artistAlbums,
    LyraColors colors,
  ) {
    // Key unik untuk AnimatedSwitcher
    return Column(
      key: const ValueKey('SongsTab'),
      children: [
        // Tombol Aksi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PressableScale(
                onTap: () => _playArtistSongs(artistSongs, 0, shuffle: true),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shuffle_rounded,
                    color: colors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PressableScale(
                onTap: () => _playArtistSongs(artistSongs, 0),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Daftar Lagu dikelompokkan per Album
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: artistAlbums.length,
          itemBuilder: (context, albumIndex) {
            final album = artistAlbums[albumIndex];
            // Urutkan lagu dalam album ini A-Z
            final songsInAlbum = songsOfAlbum(artistSongs, album.key);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Album
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AlbumDetailPage(albumKey: album.key),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: QueryArtworkWidget(
                            id: int.tryParse(album.albumId) ?? 0,
                            type: ArtworkType.ALBUM,
                            size: 200,
                            artworkWidth: 56,
                            artworkHeight: 56,
                            nullArtworkWidget: Container(
                              width: 56,
                              height: 56,
                              color: colors.textSecondary.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.album,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${songsInAlbum.length} lagu',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lagu-lagu di album ini
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: songsInAlbum.length,
                  itemBuilder: (context, songIndex) {
                    final song = songsInAlbum[songIndex];
                    // Cari index asli lagu di antrean utama (artistSongs)
                    final originalIndex = artistSongs.indexWhere(
                      (s) => s.path == song.path,
                    );

                    return LibrarySongRow(
                      song: song,
                      number: songIndex + 1,
                      onTap: () => _playArtistSongs(
                        artistSongs,
                        originalIndex < 0 ? 0 : originalIndex,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlbumsTab(List<AlbumGroup> artistAlbums, LyraColors colors) {
    // Key unik untuk AnimatedSwitcher
    return GridView.builder(
      key: const ValueKey('AlbumsTab'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: artistAlbums.length,
      itemBuilder: (context, index) {
        final album = artistAlbums[index];
        return PressableScale(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AlbumDetailPage(albumKey: album.key),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: QueryArtworkWidget(
                      id: int.tryParse(album.albumId) ?? 0,
                      type: ArtworkType.ALBUM,
                      size: 400,
                      artworkBorder: BorderRadius.circular(18),
                      nullArtworkWidget: Container(
                        color: colors.textSecondary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.album,
                          size: 48,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                album.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${album.songs.length} lagu',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}
