import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../database/database.dart';
import '../../providers/database_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/lyra_colors.dart';
import '../../widgets/lyra_bottom_bar.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = ref.watch(databaseProvider);

    return ListView(
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
                    style: TextStyle(fontSize: 16, color: colors.textSecondary),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        // PLAYLIST FAVORIT
        StreamBuilder<List<Playlist>>(
          stream: db.watchFavoritePlaylists(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const SizedBox.shrink();
            final favPlaylists = snapshot.data ?? [];
            if (favPlaylists.isEmpty) return const SizedBox.shrink();

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildPlaylistList(
                'Playlist Favorit',
                favPlaylists,
                colors,
                isDark,
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        // PLAYLIST
        StreamBuilder<List<Playlist>>(
          stream:
              (db.select(db.playlists)..orderBy([
                    (t) => drift.OrderingTerm(expression: t.sortOrder),
                  ]))
                  .watch(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const SizedBox.shrink();

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const SizedBox(
                      key: ValueKey('loading_kamu'),
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildPlaylistList(
                      'Playlist',
                      snapshot.data ?? [],
                      colors,
                      isDark,
                    ),
            );
          },
        ),
        const SizedBox(height: 28),
        // LAGU TERAKHIR DIPUTAR
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Terakhir Diputar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<PlayHistoryData?>(
          stream: db.watchLastPlayed(),
          builder: (context, snapshot) {
            final lastPlayed = snapshot.data;
            if (lastPlayed == null) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: QueryArtworkWidget(
                        id: int.tryParse(lastPlayed.albumId) ?? 0,
                        type: ArtworkType.ALBUM,
                        size: 200,
                        artworkWidth: 60,
                        artworkHeight: 60,
                        nullArtworkWidget: Container(
                          width: 60,
                          height: 60,
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
                            lastPlayed.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastPlayed.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        // LAGU SERING DIPUTAR
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Sering Diputar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        StreamBuilder<List<PlayHistoryData>>(
          stream: db.watchTopPlayed(limit: 4), // Ambil 4 teratas untuk grid 2x2
          builder: (context, snapshot) {
            final topPlayed = snapshot.data ?? [];
            if (topPlayed.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: topPlayed.length,
                itemBuilder: (context, index) {
                  final song = topPlayed[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: QueryArtworkWidget(
                            id: int.tryParse(song.albumId) ?? 0,
                            type: ArtworkType.ALBUM,
                            size: 200,
                            artworkWidth: 50,
                            artworkHeight: 50,
                            nullArtworkWidget: Icon(
                              Icons.music_note,
                              size: 50,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          song.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${song.playCount}x diputar',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // Fungsi Helper Playlist
  Widget _buildPlaylistList(
    String title,
    List<Playlist> playlists,
    LyraColors colors,
    bool isDark,
  ) {
    if (playlists.isEmpty) return const SizedBox.shrink();

    return Column(
      key: ValueKey(title),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              final hasImage =
                  playlist.imagePath != null && playlist.imagePath!.isNotEmpty;

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
                          gradient: hasImage
                              ? null
                              : LinearGradient(
                                  colors: [
                                    colors.accent.withValues(alpha: 0.5),
                                    colors.accent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: hasImage
                              ? Image.file(
                                  File(playlist.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Icon(
                                          Icons.queue_music,
                                          size: 40,
                                          color: colors.pageBackground,
                                        ),
                                      ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.queue_music,
                                    size: 40,
                                    color: colors.pageBackground,
                                  ),
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
      ],
    );
  }
}
