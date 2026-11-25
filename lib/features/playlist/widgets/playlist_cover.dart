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
  static final Map<int, List<String>> _songIdsCache = {};
  late Stream<List<String>> _songIdsStream;
  List<String>? _latestSongIds;

  @override
  void initState() {
    super.initState();
    _latestSongIds = _songIdsCache[widget.playlistId];
    _songIdsStream = ref
        .read(databaseProvider)
        .watchPlaylistSongIds(widget.playlistId);
  }

  @override
  void didUpdateWidget(covariant PlaylistCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playlistId != widget.playlistId) {
      _latestSongIds = _songIdsCache[widget.playlistId];
      _songIdsStream = ref
          .read(databaseProvider)
          .watchPlaylistSongIds(widget.playlistId);
    }
  }

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
          gaplessPlayback: true,
          cacheWidth: (300 * MediaQuery.devicePixelRatioOf(context)).round(),
          errorBuilder: (_, _, _) => _mosaic(),
        ),
      );
    }
    return _mosaic();
  }

  Widget _mosaic() {
    return StreamBuilder<List<String>>(
      stream: _songIdsStream,
      initialData: _latestSongIds ?? _songIdsCache[widget.playlistId],
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          _latestSongIds = snapshot.data;
          _songIdsCache[widget.playlistId] = snapshot.data!;
        }
        final ids = snapshot.data ?? _latestSongIds ?? _songIdsCache[widget.playlistId] ?? const <String>[];

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
        if (list.length < 4) return _art(list.first, widget.artSize);

        final tileSize = (widget.artSize / 2).round();
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _art(list[0], tileSize)),
                  Expanded(child: _art(list[1], tileSize)),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _art(list[2], tileSize)),
                  Expanded(child: _art(list[3], tileSize)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _art(String songId, int loadSize) {
    return SongArtwork(
      id: int.tryParse(songId) ?? 0,
      size: double.infinity,
      radius: 0,
      loadSize: loadSize,
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
