import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import '../theme/lyra_colors.dart';
import '../widgets/song_artwork.dart';
import '../main.dart';
import '../audio/lyra_audio_handler.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.lyra;
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: colors.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Favorit',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Song>>(
        stream: db.watchFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final favs = snapshot.data ?? [];
          if (favs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada lagu favorit.',
                style: TextStyle(color: colors.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final song = favs[index];
              return ListTile(
                leading: SongArtwork(
                  id: int.tryParse(song.id) ?? 0,
                  size: 50,
                  radius: 8,
                  placeholder: Icon(
                    Icons.music_note,
                    color: colors.textSecondary,
                  ),
                ),
                title: Text(
                  song.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist,
                  style: TextStyle(color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  final handler = audioHandler as LyraAudioHandler;
                  // Ubah Song menjadi Song database agar playQueue bisa membaca
                  handler.playQueue(
                    favs
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
                    index,
                    // HAPUS baris albumIds ini, karena model Drift tidak punya albumId
                    // albumIds: {for (var s in favs) s.path: s.albumId},
                    sourceType: 'Favorites',
                    sourceName: 'Favorit',
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
