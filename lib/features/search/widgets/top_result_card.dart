import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../models/song.dart' as local;
import '../../../theme/lyra_colors.dart';
import '../../../widgets/lyra_bottom_bar.dart';

class TopResultCard extends StatelessWidget {
  final local.Song song;
  final VoidCallback onPlay;

  const TopResultCard({super.key, required this.song, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;

    return PressableScale(
      onTap: onPlay,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.textSecondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: QueryArtworkWidget(
                id: int.tryParse(song.albumId) ?? 0,
                type: ArtworkType.ALBUM,
                size: 200,
                artworkWidth: 96,
                artworkHeight: 96,
                artworkBorder: BorderRadius.circular(16),
                nullArtworkWidget: Container(
                  width: 96,
                  height: 96,
                  color: colors.textSecondary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.music_note,
                    size: 40,
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
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: colors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Play',
                          style: TextStyle(
                            color: colors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
}
