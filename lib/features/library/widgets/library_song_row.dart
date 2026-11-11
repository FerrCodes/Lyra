import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_service/audio_service.dart';
import '../../../models/song.dart' as local;
import '../../../theme/lyra_colors.dart';
import '../../../main.dart';
import '../../../widgets/lyra_bottom_bar.dart'; // Untuk PressableScale

class LibrarySongRow extends StatelessWidget {
  final local.Song song;
  final int number;
  final VoidCallback onTap;
  final VoidCallback? onMore;
  final bool showArtist;
  final bool showCover;

  const LibrarySongRow({
    super.key,
    required this.song,
    required this.number,
    required this.onTap,
    this.onMore,
    this.showArtist = true,
    this.showCover = false,
  });

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;
    final albumIdInt = int.tryParse(song.albumId) ?? 0;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.id == song.path;

        return PressableScale(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Kiri: Nomor atau Sampul
                if (showCover)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: QueryArtworkWidget(
                      id: albumIdInt,
                      type: ArtworkType.ALBUM,
                      size: 200,
                      artworkWidth: 48,
                      artworkHeight: 48,
                      nullArtworkWidget: Container(
                        width: 48,
                        height: 48,
                        color: colors.textSecondary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.music_note,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: 28,
                    child: Text(
                      number.toString(),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),

                // Tengah: Judul & Artis
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isPlaying ? colors.accent : colors.textPrimary,
                        ),
                      ),
                      if (showArtist) ...[
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Kanan: Durasi & Titik Tiga
                const SizedBox(width: 12),
                Text(
                  _formatDuration(song.durationMs),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
                if (onMore != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onMore,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.more_vert,
                        color: colors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ] else
                  const SizedBox(
                    width: 36,
                  ), // Spacer jika onMore null agar sejajar
              ],
            ),
          ),
        );
      },
    );
  }
}
