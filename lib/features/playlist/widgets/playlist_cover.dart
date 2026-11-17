import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/database_provider.dart';
import '../../../widgets/song_artwork.dart';

class PlaylistCover extends ConsumerStatefulWidget {
  final int playlistId;
  final String? imagePath;
  final double iconSize;
  final int artSize;

  const PlaylistCover({
    super.key,
    required this.playlistId,
    this.imagePath,
    this.iconSize = 50,
    this.artSize = 300,
  });

  @override
  ConsumerState<PlaylistCover> createState() => _PlaylistCoverState();
}

// Tambahkan AutomaticKeepAliveClientMixin agar tidak di-destroy saat di-scroll
class _PlaylistCoverState extends ConsumerState<PlaylistCover>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wajib dipanggil untuk KeepAlive

    final hasImage = widget.imagePath != null && widget.imagePath!.isNotEmpty;

    if (hasImage) {
      return SizedBox.expand(
        child: Image.file(
          File(widget.imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _mosaic(),
        ),
      );
    }
    return _mosaic();
  }

  Widget _mosaic() {
    final db = ref.read(databaseProvider);

    return StreamBuilder<List<String>>(
      stream: db.watchPlaylistSongIds(widget.playlistId),
      builder: (context, snapshot) {
        final ids = snapshot.data ?? const <String>[];

        // Ambil maksimal 4 songId unik (TANPA memanggil allSongsProvider lagi)
        final list = <String>[];
        final seen = <String>{};
        for (final id in ids) {
          if (id.isNotEmpty && !seen.contains(id)) {
            seen.add(id);
            list.add(id);
            if (list.length == 4) break;
          }
        }

        if (list.isEmpty) return _placeholder();
        if (list.length < 4) return _art(list.first);

        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _art(list[0])),
                  Expanded(child: _art(list[1])),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _art(list[2])),
                  Expanded(child: _art(list[3])),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _art(String songId) {
    return SongArtwork(
      id: int.tryParse(songId) ?? 0,
      size: double.infinity,
      radius: 0,
      loadSize: widget.artSize,
      placeholder: _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF77736C), Color(0xFF292824)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.album_rounded,
          size: widget.iconSize,
          color: const Color(0x66FFFFFF),
        ),
      ),
    );
  }
}
