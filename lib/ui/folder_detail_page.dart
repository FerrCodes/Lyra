import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_service/audio_service.dart';
import '../main.dart';
import '../widgets/lyra_header.dart';
import '../models/song.dart' as local;
import '../database/database.dart';
import '../audio/lyra_audio_handler.dart';
import '../theme/lyra_colors.dart';
import '../widgets/song_artwork.dart';
import '../l10n/app_localizations.dart';
import '../features/playlist/widgets/playlist_track_list.dart';

class FolderDetailPage extends StatelessWidget {
  final String folderName;
  final String folderPath;
  final List<local.Song> songs;

  const FolderDetailPage({
    super.key,
    required this.folderName,
    required this.folderPath,
    required this.songs,
  });

  void _playQueue(
    BuildContext context,
    int startIndex, {
    bool shuffle = false,
  }) {
    if (songs.isEmpty) return;
    final handler = audioHandler as LyraAudioHandler;
    List<local.Song> listToPlay = List.from(songs);

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
      sourceType: 'Folder',
      sourceName: folderName,
    );
  }

  String _formatDuration(int totalMs) {
    final minutes = (totalMs / 60000).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remMinutes = minutes % 60;
    return remMinutes > 0 ? '$hours hr $remMinutes min' : '$hours hr';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // MENGGUNAKAN FULL PATH SESUAI PERMINTAAN (Tidak dipotong /storage/emulated/0/)
    final fullPath = folderPath;

    final totalDurationMs = songs.fold<int>(
      0,
      (sum, song) => sum + song.durationMs,
    );
    final durationText = _formatDuration(totalDurationMs);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colors.pageBackground,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: colors.pageBackground,
        body: Stack(
          children: [
            // KONTEN UTAMA (Scrollable)
            CustomScrollView(
              slivers: [
                // Padding atas untuk memberi ruang Top Bar yang melayang
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + 80,
                  ),
                ),

                // FOLDER SHOWCASE
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Kolase Artwork
                        _buildCollage(context, colors, isDark),
                        const SizedBox(width: 20),
                        // Info Folder
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                folderName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                  color: colors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              // Path Full (SoftWrap)
                              Text(
                                fullPath,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                  height: 1.3,
                                ),
                                softWrap:
                                    true, // Mengizinkan teks turun ke baris baru
                              ),

                              const SizedBox(height: 10),
                              // Info Lagu
                              Text(
                                '${AppLocalizations.of(context)!.songsCount(songs.length)} • $durationText',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // HEADING TRACKS
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      top: 32,
                      bottom: 12,
                    ),
                    child: Text(
                      'TRACKS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),

                // SONG LIST
                StreamBuilder<MediaItem?>(
                  stream: audioHandler.mediaItem,
                  builder: (context, snapshot) {
                    final currentMediaItem = snapshot.data;

                    return SliverList.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        final isPlaying = currentMediaItem?.id == song.path;

                        return Material(
                          color: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              leading: SongArtwork(
                                id: int.tryParse(song.id) ?? 0,
                                size: 54,
                                radius: 10,
                                placeholder: Container(
                                  color: colors.textSecondary.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isPlaying
                                      ? colors.accent
                                      : colors.textPrimary,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              trailing: isPlaying
                                  ? const EqualizerAnimation()
                                  : null,
                              onTap: () => _playQueue(context, index),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

            // GRADASI LATAR ATAS
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: MediaQuery.of(context).padding.top + 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.pageBackground.withValues(alpha: 0.9),
                        colors.pageBackground.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // FLOATING TOP BAR (2 Kapsul)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // KAPSUL KIRI (Hanya Tombol Back)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: colors.textPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // TEKS FOLDER (Melayang di luar)
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.folders,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colors.textPrimary,
                        shadows: isDark
                            ? []
                            : [
                                Shadow(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  blurRadius: 10,
                                ),
                              ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 12),

                  TopBarButton(
                    isCircle: false,
                    onTap: () {}, // Dummy karena di dalamnya ada tombol
                    customChild: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _playQueue(context, 0, shuffle: true),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.shuffle,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _playQueue(context, 0),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.play_arrow,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // FUNGSI PEMBUAT KOLASE ARTWORK (2x2)
  // ==========================================
  Widget _buildCollage(BuildContext context, LyraColors colors, bool isDark) {
    // Ambil maksimal 4 ID album unik dari lagu di folder ini
    final uniqueIds = <String>{};
    for (final song in songs) {
      if (song.id.isNotEmpty) {
        uniqueIds.add(song.id);
        if (uniqueIds.length == 4) break;
      }
    }
    final ids = uniqueIds.toList();

    Widget placeholder = Container(
      color: colors.textSecondary.withValues(alpha: 0.1),
      child: Icon(Icons.album_rounded, color: colors.textSecondary, size: 40),
    );

    if (ids.isEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colors.textSecondary.withValues(alpha: 0.05),
        ),
        child: placeholder,
      );
    }

    Widget artwork(String id) {
      return SongArtwork(
        id: int.tryParse(id) ?? 0,
        size: double.infinity,
        radius: 0,
        placeholder: placeholder,
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ids.length == 1
            ? artwork(ids[0])
            : ids.length == 2
            ? Row(
                children: [
                  Expanded(child: artwork(ids[0])),
                  const SizedBox(width: 1),
                  Expanded(child: artwork(ids[1])),
                ],
              )
            : ids.length == 3
            ? Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: artwork(ids[0])),
                        const SizedBox(width: 1),
                        Expanded(child: artwork(ids[1])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  Expanded(child: artwork(ids[2])),
                ],
              )
            : Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: artwork(ids[0])),
                        const SizedBox(width: 1),
                        Expanded(child: artwork(ids[1])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 1),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: artwork(ids[2])),
                        const SizedBox(width: 1),
                        Expanded(child: artwork(ids[3])),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
