import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
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
  void _playSongs(List<Song> songs, int startIndex, {bool shuffle = false}) {
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
      sourceType: 'Beranda',
      sourceName: 'Home',
    );
  }

  // Fungsi Helper: Putar dari List local.Song (MediaStore)
  void _playLocalSongs(
    List<local.Song> songs,
    int startIndex, {
    bool shuffle = false,
  }) {
    if (songs.isEmpty) return;
    _playSongs(
      songs
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
      shuffle: shuffle,
    );
  }

  // Fungsi Helper: Putar 1 lagu dari PlayHistory
  void _playFromHistory(PlayHistoryData history) {
    _playSongs([
      Song(
        id: history.songId,
        title: history.title,
        artist: history.artist,
        album: history.album,
        path: history.path,
        durationMs: history.durationMs,
        addedAt: DateTime.now(),
      ),
    ], 0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = ref.watch(databaseProvider);
    final allSongs = ref.watch(allSongsProvider).value ?? [];

    return Stack(
      children: [
        // 1. LATAR ATAS DINAMIS
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

        // 2. KONTEN UTAMA
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
                          fontSize: 30,
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
            if (allSongs.isEmpty)
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
                        'Selamat Datang di Lyra!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada lagu di perangkatmu. Tambahkan lagu ke folder musik HP, lalu tarik halaman ini ke bawah untuk memuat ulang.',
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

            // AKSES CEPAT
            if (allSongs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        'Putar Semua',
                        Icons.play_circle_fill_rounded,
                        colors.accent,
                        () => _playLocalSongs(allSongs, 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        'Putar Acak',
                        Icons.shuffle_rounded,
                        colors.textPrimary,
                        () => _playLocalSongs(allSongs, 0, shuffle: true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],

            // LANJUTKAN
            _buildHistorySection(
              context: context,
              title: 'Lanjutkan',
              dbStream: db.watchLastPlayed().map((h) => h == null ? [] : [h]),
              itemBuilder: (history) => GestureDetector(
                onTap: () => _playFromHistory(history),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: QueryArtworkWidget(
                          id: int.tryParse(history.albumId) ?? 0,
                          type: ArtworkType.ALBUM,
                          size: 150,
                          artworkWidth: 80,
                          artworkHeight: 80,
                          nullArtworkWidget: Container(
                            width: 80,
                            height: 80,
                            color: colors.textSecondary.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.music_note,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              history.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              history.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: colors.accent,
                                  size: 24,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Lanjutkan',
                                  style: TextStyle(
                                    color: colors.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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

            // FAVORIT
            _buildSongSection(
              context: context,
              title: 'Favorit',
              dbStream: db.watchFavorites(),
              colors: colors,
              isDark: isDark,
              onPlay: (index, songs) => _playSongs(songs, index),
            ),

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
              title: 'Playlist Kamu',
              dbStream:
                  (db.select(db.playlists)..orderBy([
                        (t) => drift.OrderingTerm(expression: t.sortOrder),
                      ]))
                      .watch(),
              colors: colors,
              isDark: isDark,
            ),

            // ALBUM PILIHAN
            if (allSongs.isNotEmpty)
              _buildCategorySection(
                context: context,
                title: 'Album Pilihan',
                items: allSongs.map((s) => s.album).toSet().take(6).toList(),
                colors: colors,
                isDark: isDark,
                itemBuilder: (albumName, index) {
                  final albumSongs = allSongs
                      .where((s) => s.album == albumName)
                      .toList();
                  return _buildCategoryCard(
                    title: albumName,
                    subtitle: '${albumSongs.length} Lagu',
                    albumId: albumSongs.first.albumId,
                    colors: colors,
                    isDark: isDark,
                    isCircle: false,
                    onTap: () => _playLocalSongs(albumSongs, 0),
                  );
                },
              ),

            // ARTIS
            if (allSongs.isNotEmpty)
              _buildCategorySection(
                context: context,
                title: 'Artis',
                items: allSongs.map((s) => s.artist).toSet().take(6).toList(),
                colors: colors,
                isDark: isDark,
                itemBuilder: (artistName, index) {
                  final artistSongs = allSongs
                      .where((s) => s.artist == artistName)
                      .toList();
                  return _buildCategoryCard(
                    title: artistName,
                    subtitle: '${artistSongs.length} Lagu',
                    albumId: artistSongs.first.albumId,
                    colors: colors,
                    isDark: isDark,
                    isCircle: true,
                    onTap: () => _playLocalSongs(artistSongs, 0),
                  );
                },
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
          ],
        ),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
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
        if (data.isEmpty)
          return const SizedBox.shrink(); // Sembunyikan jika kosong

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
                              id: int.tryParse(song.id) ?? 0,
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

  // Bagian Kategori Dinamis (Album/Artis)
  Widget _buildCategorySection({
    required BuildContext context,
    required String title,
    required List<String> items,
    required LyraColors colors,
    required bool isDark,
    required Widget Function(String name, int index) itemBuilder,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

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
            itemCount: items.length,
            itemBuilder: (context, index) => itemBuilder(items[index], index),
          ),
        ),
        const SizedBox(height: 28),
      ],
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
      onTap: () => _playFromHistory(history),
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

  // Helper: Item Kategori (Album/Artis)
  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required String albumId,
    required LyraColors colors,
    required bool isDark,
    required bool isCircle,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: isCircle ? 110 : 130,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(isCircle ? 55 : 16),
              child: QueryArtworkWidget(
                id: int.tryParse(albumId) ?? 0,
                type: ArtworkType.ALBUM,
                size: 150,
                artworkWidth: isCircle ? 110 : 130,
                artworkHeight: isCircle ? 110 : 130,
                nullArtworkWidget: Container(
                  color: colors.textSecondary.withValues(alpha: 0.1),
                  child: Icon(
                    isCircle ? Icons.person : Icons.album,
                    size: 40,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
