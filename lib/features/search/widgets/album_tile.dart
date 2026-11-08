import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../search_logic.dart';
import '../../../theme/lyra_colors.dart';
import '../../../widgets/lyra_bottom_bar.dart';

class AlbumTile extends StatelessWidget {
  final AlbumResult album;
  final VoidCallback onTap;

  const AlbumTile({super.key, required this.album, required this.onTap});

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
                id: int.tryParse(album.albumId) ?? 0,
                type: ArtworkType.ALBUM,
                size: 200,
                artworkWidth: 52,
                artworkHeight: 52,
                artworkBorder: BorderRadius.circular(10),
                nullArtworkWidget: Container(
                  width: 52,
                  height: 52,
                  color: colors.textSecondary.withValues(alpha: 0.15),
                  child: Icon(Icons.album, color: colors.textSecondary),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${album.artist} • ${album.songCount} Lagu',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
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
