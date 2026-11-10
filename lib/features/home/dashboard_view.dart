import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../database/database.dart';
import '../../main.dart';
import '../../providers/database_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/songs_provider.dart';
import '../../theme/lyra_colors.dart';
import '../../widgets/lyra_bottom_bar.dart';
import '../../audio/lyra_audio_handler.dart';
import '../playlist/widgets/playlist_cover.dart';

class DashboardView extends ConsumerWidget {
  final ScrollController controller;
  final void Function(Playlist playlist) onOpenPlaylist;

  const DashboardView({
    super.key,
    required this.controller,
    required this.onOpenPlaylist,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }

  // Fungsi Helper: Putar dari List Song (Drift)
  void _playSongs(
    List<Song> songs,
    int startIndex, {
    bool shuffle = false,
    required String sourceType,
    required String sourceName,
    Map<String, String>? albumIds,
  }) {
    if (songs.isEmpty) return;
    final handler = audioHandler as LyraAudioHandler;
    List<Song> listToPlay = List.from(songs);
    if (shuffle) {
      listToPlay.shuffle();
      startIndex = 0;
    }

    handler.playQueue(
      listToPlay,
      startIndex,
      albumIds: albumIds,
      sourceType: sourceType,
      sourceName: sourceName,
    );
  }

  // Fungsi Helper: Putar 1 lagu dari PlayHistory
  void _playFromHistory(
    PlayHistoryData history, {
    String sourceName = 'Lanjutkan',
  }) {
    _playSongs(
      [
        Song(
          id: history.songId,
          title: history.title,
          artist: history.artist,
          album: history.album,
          path: history.path,
          durationMs: history.durationMs,
          addedAt: DateTime.now(),
        ),
      ],
      0,
      sourceType: 'Beranda',
      sourceName: sourceName,
      albumIds: {history.path: history.albumId},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = ref.watch(databaseProvider);
    final songsAsync = ref.watch(allSongsProvider);
    final allSongs = songsAsync.value ?? [];
    final albumById = {for (final s in allSongs) s.id: s.albumId};

    return Stack(
      children: [
        // LATAR ATAS DINAMIS
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.accent.withValues(alpha: 0.15),
                    colors.pageBackground.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // KONTEN UTAMA
        ListView(
          controller: controller,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 80,
            bottom: 160,
          ),
          children: [
            // SAPAAN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ValueListenableBuilder<String>(
                valueListenable: profileNameNotifier,
                builder: (context, name, child) {
                  final isDefaultName = name == 'Pengguna Lyra';
                  final greetingText = isDefaultName
                      ? 'Selamat ${_getGreeting()},'
                      : 'Selamat ${_getGreeting()}, $name';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greetingText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Siap mendengarkan sesuatu hari ini?',
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            // KARTU PENGGUNA BARU (Jika belum ada lagu)
            if (songsAsync.hasValue && allSongs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.library_music, size: 60, color: colors.accent),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada lagu yang ditemukan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 5),
            // PLAYLIST FAVORIT
            _buildPlaylistSection(
              context: context,
              title: 'Playlist Favorit',
              dbStream: db.watchFavoritePlaylists(),
              colors: colors,
              isDark: isDark,
            ),
            // PLAYLIST KAMU
            _buildPlaylistSection(
              context: context,
              title: 'Playlist',
              dbStream:
                  (db.select(db.playlists)..orderBy([
                        (t) => drift.OrderingTerm(expression: t.sortOrder),
                      ]))
                      .watch(),
              colors: colors,
              isDark: isDark,
            ),
            // FAVORIT
            _buildSongSection(
              context: context,
              title: 'Favorit',
              dbStream: db.watchFavorites(),
              colors: colors,
              isDark: isDark,
              albumById: albumById,
              onPlay: (index, songs) => _playSongs(
                songs,
                index,
                sourceType: 'Favorit',
                sourceName: 'Favorit',
                albumIds: {
                  for (final s in songs)
                    if (albumById[s.id] != null) s.path: albumById[s.id]!,
                },
              ),
            ),
            // SERING DIPUTAR
            _buildHistorySection(
              context: context,
              title: 'Sering Diputar',
              dbStream: db.watchTopPlayed(limit: 10),
              itemBuilder: (history) => _buildHistoryShelfItem(
                history,
                colors,
                isDark,
                showPlayCount: true,
              ),
            ),
            // DENGARKAN LAGI
            _buildHistorySection(
              context: context,
              title: 'Dengarkan Lagi',
              dbStream: db.watchRecentlyPlayed(limit: 6),
              itemBuilder: (history) =>
                  _buildHistoryShelfItem(history, colors, isDark),
            ),
          ],
        ),
      ],
    );
  }

  // Bagian Playlist (Horizontal)
  Widget _buildPlaylistSection({
    required BuildContext context,
    required String title,
    required Stream<List<Playlist>> dbStream,
    required LyraColors colors,
    required bool isDark,
  }) {
    return StreamBuilder<List<Playlist>>(
      stream: dbStream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const SizedBox.shrink();
        } // Sembunyikan jika kosong

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(title, colors),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final playlist = data[index];
                  return PressableScale(
                    onTap: () => onOpenPlaylist(playlist),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: PlaylistCover(
                                playlistId: playlist.id,
                                imagePath: playlist.imagePath,
                                iconSize: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            playlist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }

  // Bagian Favorit (Horizontal lagu)
  Widget _buildSongSection({
    required BuildContext context,
    required String title,
    required Stream<List<Song>> dbStream,
    required LyraColors colors,
    required bool isDark,
    required Map<String, String> albumById,
    required void Function(int index, List<Song> songs) onPlay,
  }) {
    return StreamBuilder<List<Song>>(
      stream: dbStream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        if (data.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(title, colors),
            const SizedBox(height: 12),
            SizedBox(
              height: 185,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final song = data[index];
                  return PressableScale(
                    onTap: () => onPlay(index, data),
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: QueryArtworkWidget(
                              id: int.tryParse(albumById[song.id] ?? '') ?? 0,
                              type: ArtworkType.ALBUM,
                              size: 150,
                              artworkWidth: 130,
                              artworkHeight: 130,
                              nullArtworkWidget: Container(
                                color: colors.textSecondary.withValues(
                                  alpha: 0.1,
                                ),
                                child: Icon(
                                  Icons.favorite,
                                  size: 40,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }

  // Bagian History (Lanjutkan, Dengarkan Lagi, Sering Diputar)
  Widget _buildHistorySection({
    required BuildContext context,
    required String title,
    required Stream<List<PlayHistoryData>> dbStream,
    required Widget Function(PlayHistoryData) itemBuilder,
  }) {
    return StreamBuilder<List<PlayHistoryData>>(
      stream: dbStream,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        if (data.isEmpty) return const SizedBox.shrink();

        final colors = context.lyra;
        final isFirst = title == 'Lanjutkan';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(title, colors),
            const SizedBox(height: 12),
            if (isFirst)
              itemBuilder(data.first)
            else
              SizedBox(
                height: 185,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.length,
                  itemBuilder: (context, index) => itemBuilder(data[index]),
                ),
              ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }

  // Helper: Judul Bagian
  Widget _buildTitle(String title, LyraColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  // Helper: Item Shelf untuk History
  Widget _buildHistoryShelfItem(
    PlayHistoryData history,
    LyraColors colors,
    bool isDark, {
    bool showPlayCount = false,
  }) {
    return PressableScale(
      onTap: () => _playFromHistory(
        history,
        sourceName: showPlayCount ? 'Sering Diputar' : 'Dengarkan Lagi',
      ),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: QueryArtworkWidget(
                id: int.tryParse(history.albumId) ?? 0,
                type: ArtworkType.ALBUM,
                size: 150,
                artworkWidth: 130,
                artworkHeight: 130,
                nullArtworkWidget: Container(
                  color: colors.textSecondary.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.music_note,
                    size: 40,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              history.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                fontSize: 14,
              ),
            ),
            if (showPlayCount)
              Text(
                '${history.playCount}x diputar',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              )
            else
              Text(
                history.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
