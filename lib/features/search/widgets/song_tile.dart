import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../models/song.dart' as local;
import '../../../theme/lyra_colors.dart';
import '../../../widgets/lyra_bottom_bar.dart'; // Untuk PressableScale

class SongTile extends StatelessWidget {
  final local.Song song;
  final String query;
  final bool isPlaying;
  final VoidCallback onTap;

  const SongTile({
    super.key,
    required this.song,
    required this.query,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;

    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: QueryArtworkWidget(
                id: int.tryParse(song.albumId) ?? 0,
                type: ArtworkType.ALBUM,
                size: 200,
                artworkWidth: 52,
                artworkHeight: 52,
                artworkBorder: BorderRadius.circular(10),
                nullArtworkWidget: Container(
                  width: 52,
                  height: 52,
                  color: colors.textSecondary.withValues(alpha: 0.15),
                  child: Icon(Icons.music_note, color: colors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHighlightedText(context, song.title, query, isPlaying),
                  const SizedBox(height: 4),
                  Text(
                    '${song.artist} • ${song.album}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              _formatDuration(Duration(milliseconds: song.durationMs)),
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String query,
    bool isPlaying,
  ) {
    final colors = context.lyra;
    final baseStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: isPlaying ? colors.accent : colors.textPrimary,
    );

    if (query.isEmpty)
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(color: colors.accent, fontWeight: FontWeight.bold),
        ),
      );
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
