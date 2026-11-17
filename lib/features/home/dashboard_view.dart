import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/song_artwork.dart';
import '../../database/database.dart';
import '../../main.dart';
import '../../models/song.dart' as local;
import '../../providers/database_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/songs_provider.dart';
import '../../theme/lyra_colors.dart';
import '../../widgets/lyra_bottom_bar.dart';
import '../../audio/lyra_audio_handler.dart';
import '../playlist/widgets/playlist_cover.dart';
import '../../l10n/app_localizations.dart';

class DashboardView extends ConsumerWidget {
  final ScrollController controller;
  final void Function(Playlist playlist) onOpenPlaylist;

  const DashboardView({
    super.key,
    required this.controller,
    required this.onOpenPlaylist,
  });

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 15) return l10n.goodAfternoon;
    if (hour < 18) return l10n.goodEvening;
    return l10n.goodNight;
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
    required List<local.Song> allSongs,
  }) {
    final songId =
        allSongs
            .where((s) => s.path == history.path)
            .map((s) => s.id)
            .firstOrNull ??
        history.songId;

    _playSongs(
      [
        Song(
          id: songId,
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
          cacheExtent: 2000,
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
                  final l10n = AppLocalizations.of(context)!;
                  final isDefaultName = name == 'Pengguna Lyra';
                  final timeGreeting = _getGreeting(context);
                  final greetingText = isDefaultName
                      ? l10n.greetingWithoutName(timeGreeting)
                      : l10n.greetingWithName(timeGreeting, name);

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
                        AppLocalizations.of(context)!.readyToListen,
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
            // JIKA SEDANG LOADING
            if (songsAsync.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            // KARTU PENGGUNA BARU (Jika belum ada lagu)
            if (songsAsync.hasValue && allSongs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.noSongsFound,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.noSongsDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Tombol Aksi untuk Memuat Ulang
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            // Memaksa provider untuk memindai ulang lagu dari MediaStore
                            ref.invalidate(allSongsProvider);
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 20),
                          label: Text(
                            AppLocalizations.of(context)!.rescanSongs,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
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
              title: AppLocalizations.of(context)!.favoritePlaylists,
              dbStream: db.watchFavoritePlaylists(),
              colors: colors,
              isDark: isDark,
            ),
            // PLAYLIST KAMU
            _buildPlaylistSection(
              context: context,
              title: AppLocalizations.of(context)!.playlists,
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
              title: AppLocalizations.of(context)!.favorites,
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
              title: AppLocalizations.of(context)!.mostPlayed,
              dbStream: db.watchTopPlayed(limit: 10),
              itemBuilder: (history) => _buildHistoryShelfItem(
                history,
                context,
                colors,
                isDark,
                showPlayCount: true,
                allSongs: allSongs,
              ),
            ),
            // DENGARKAN LAGI
            _buildHistorySection(
              context: context,
              title: AppLocalizations.of(context)!.listenAgain,
              dbStream: db.watchRecentlyPlayed(limit: 6),
              itemBuilder: (history) => _buildHistoryShelfItem(
                history,
                context,
                colors,
                isDark,
                allSongs: allSongs,
              ),
            ),
            if (songsAsync.hasValue && allSongs.isNotEmpty)
              StreamBuilder<List<Playlist>>(
                stream: db.watchFavoritePlaylists(),
                builder: (context, snapPlaylist) {
                  return StreamBuilder<List<Song>>(
                    stream: db.watchFavorites(),
                    builder: (context, snapFav) {
                      return StreamBuilder<List<PlayHistoryData>>(
                        stream: db.watchRecentlyPlayed(limit: 1),
                        builder: (context, snapHistory) {
                          final hasPlaylist =
                              (snapPlaylist.data ?? []).isNotEmpty;
                          final hasFav = (snapFav.data ?? []).isNotEmpty;
                          final hasHistory =
                              (snapHistory.data ?? []).isNotEmpty;

                          // Jika user belum punya playlist, favorit, dan riwayat putar
                          if (!hasPlaylist && !hasFav && !hasHistory) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                left: 32,
                                right: 32,
                                top: 178,
                                bottom: 40,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.exploreMusicDesc,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          // Jika sudah ada aktivitas, kembalikan widget kosong
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  );
                },
              ),
          ],
        ),
        Positioned(
          bottom: 16, // Jarak dari dasar layar
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.copyrightText,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
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
              child: RepaintBoundary(
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
              child: RepaintBoundary(
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
                            SongArtwork(
                              id: int.tryParse(song.id) ?? 0,
                              size: 130,
                              radius: 16,
                              loadSize: 200,
                              placeholder: Container(
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
    BuildContext context,
    LyraColors colors,
    bool isDark, {
    bool showPlayCount = false,
    required List<local.Song> allSongs,
  }) {
    return PressableScale(
      onTap: () => _playFromHistory(
        history,
        sourceName: showPlayCount ? 'Sering Diputar' : 'Dengarkan Lagi',
        allSongs: allSongs,
      ),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SongArtwork(
              id: int.tryParse(history.songId) ?? 0,
              size: 130,
              radius: 16,
              loadSize: 200,
              placeholder: Container(
                color: colors.textSecondary.withValues(alpha: 0.1),
                child: Icon(
                  Icons.music_note,
                  size: 40,
                  color: colors.textSecondary,
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
                AppLocalizations.of(context)!.playCount(history.playCount),
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
