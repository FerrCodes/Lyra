import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../models/song.dart' as local;
import '../../../providers/songs_provider.dart';
import '../../../theme/lyra_colors.dart';
import '../../../audio/lyra_audio_handler.dart';
import '../../../main.dart';
import '../../../widgets/lyra_header.dart'; // Asumsi TopBarButton ada di sini
import '../../../widgets/lyra_bottom_bar.dart'; // Asumsi PressableScale ada di sini
import '../../../database/database.dart';
import '../library_logic.dart';
import '../widgets/library_song_row.dart';

class AlbumDetailPage extends ConsumerWidget {
  final String albumKey;

  const AlbumDetailPage({super.key, required this.albumKey});

  void _playAlbum(
    BuildContext context,
    List<local.Song> songs,
    String albumName, {
    bool shuffle = false,
  }) {
    if (songs.isEmpty) return;

    final handler = audioHandler as LyraAudioHandler;
    List<local.Song> listToPlay = List.from(songs);
    if (shuffle) {
      listToPlay.shuffle();
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
      0,
      albumIds: {for (var s in listToPlay) s.path: s.albumId},
      sourceType: 'Album',
      sourceName: albumName,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSongs = ref.watch(allSongsProvider).value ?? [];

    final albumSongs = songsOfAlbum(allSongs, albumKey);

    if (albumSongs.isEmpty) {
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
            'Album tidak ditemukan.',
            style: TextStyle(color: colors.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    final firstSong = albumSongs.first;
    final albumName = firstSong.album.trim().isEmpty
        ? 'Unknown Album'
        : firstSong.album;
    final artistName = firstSong.artist.trim().isEmpty
        ? 'Unknown Artist'
        : firstSong.artist;
    final totalDurationMs = albumSongs.fold(0, (sum, s) => sum + s.durationMs);
    final albumIdInt = int.tryParse(firstSong.albumId) ?? 0;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: Stack(
        children: [
          // KONTEN UTAMA
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Gradient atas yang ikut tergulir
                    Container(
                      height: 360,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.accent.withValues(alpha: 0.18),
                            colors.pageBackground.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),

                    // Header Album
                    Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 72,
                        left: 16,
                        right: 16,
                        bottom: 24,
                      ),
                      child: Column(
                        children: [
                          // Sampul
                          Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: QueryArtworkWidget(
                                id: albumIdInt,
                                type: ArtworkType.ALBUM,
                                size: 800,
                                artworkBorder: BorderRadius.circular(24),
                                nullArtworkWidget: Container(
                                  color: colors.textSecondary.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: Icon(
                                    Icons.album,
                                    size: 100,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Judul Album
                          Text(
                            albumName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Nama Artis
                          Text(
                            artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Info Lagu & Durasi
                          Text(
                            '${albumSongs.length} lagu • ${formatTotalDuration(totalDurationMs)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tombol Aksi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PressableScale(
                                onTap: () => _playAlbum(
                                  context,
                                  albumSongs,
                                  albumName,
                                  shuffle: true,
                                ),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colors.textPrimary.withValues(
                                      alpha: 0.08,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.shuffle_rounded,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              PressableScale(
                                onTap: () =>
                                    _playAlbum(context, albumSongs, albumName),
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.accent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Putar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Daftar Lagu
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 160),
                sliver: SliverList.builder(
                  itemCount: albumSongs.length,
                  itemBuilder: (context, index) {
                    final song = albumSongs[index];
                    return LibrarySongRow(
                      song: song,
                      number: index + 1,
                      onTap: () {
                        // Putar spesifik lagu ini dari album
                        final handler = audioHandler as LyraAudioHandler;
                        handler.playQueue(
                          albumSongs
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
                          albumIds: {
                            for (var s in albumSongs) s.path: s.albumId,
                          },
                          sourceType: 'Album',
                          sourceName: albumName,
                        );
                      },
                    );
                  },
                ),
              ),
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
}
