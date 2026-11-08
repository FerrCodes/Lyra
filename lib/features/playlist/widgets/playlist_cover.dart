import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/songs_provider.dart';

class PlaylistCover extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    if (hasImage) {
      return SizedBox.expand(
        child: Image.file(
          File(imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _mosaic(ref),
        ),
      );
    }
    return _mosaic(ref);
  }

  Widget _mosaic(WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final allSongs = ref.watch(allSongsProvider).value ?? [];

    return StreamBuilder<List<String>>(
      stream: db.watchPlaylistSongIds(playlistId),
      builder: (context, snapshot) {
        final ids = snapshot.data ?? const <String>[];
        final albumBysong = {for (final s in allSongs) s.id: s.albumId};

        // Album unik sesuai urutan playlist, tanpa albumId kosong
        final albums = <String>{};
        for (final id in ids) {
          final a = albumBysong[id];
          if (a != null && a != '0') albums.add(a);
        }
        final list = albums.toList();

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

  Widget _art(String albumId) {
    return SizedBox.expand(
      child: QueryArtworkWidget(
        id: int.tryParse(albumId) ?? 0,
        type: ArtworkType.ALBUM,
        size: artSize,
        artworkWidth: double.infinity,
        artworkHeight: double.infinity,
        artworkFit: BoxFit.cover,
        artworkBorder: BorderRadius.zero,
        keepOldArtwork: true,
        nullArtworkWidget: _placeholder(),
      ),
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
          size: iconSize,
          color: const Color(0x66FFFFFF),
        ),
      ),
    );
  }
}
