import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import '../theme/lyra_colors.dart';
import '../widgets/song_artwork.dart';
import '../widgets/lyra_header.dart'; // Untuk TopBarButton
import '../l10n/app_localizations.dart'; // Untuk Multi-bahasa
import '../main.dart';
import '../audio/lyra_audio_handler.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = ref.watch(databaseProvider);

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
            // KONTEN UTAMA
            StreamBuilder<List<Song>>(
              stream: db.watchFavorites(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final favs = snapshot.data ?? [];

                if (favs.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.noFavoriteSongs,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 80,
                    bottom: 120,
                  ),
                  itemCount: favs.length,
                  itemBuilder: (context, index) {
                    final song = favs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      leading: SongArtwork(
                        id: int.tryParse(song.id) ?? 0,
                        size: 50,
                        radius: 8,
                        placeholder: Container(
                          color: colors.textSecondary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.music_note,
                            color: colors.textSecondary,
                          ),
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
                          sourceType: 'Favorites',
                          sourceName: AppLocalizations.of(context)!.favorites,
                        );
                      },
                    );
                  },
                );
              },
            ),

            // GRADASI LATAR ATAS (Agar teks melayang tetap terbaca)
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
                      stops: const [0.0, 0.8],
                    ),
                  ),
                ),
              ),
            ),

            // FLOATING TOP BAR KAS LYRA
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  TopBarButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.favorites,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  // TOMBOL PLAY ALL
                  TopBarButton(
                    icon: Icons.play_arrow_rounded,
                    onTap: () {
                      // Kita harus memastikan ada lagu sebelum memutar
                      final favs = ref.read(databaseProvider).watchFavorites();
                      // Panggil stream-nya sekali untuk mendapatkan data saat ini
                      favs.first.then((songs) {
                        if (songs.isNotEmpty) {
                          final handler = audioHandler as LyraAudioHandler;
                          handler.playQueue(
                            songs
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
                            0, // Mulai dari lagu pertama
                            sourceType: 'Favorites',
                            sourceName: AppLocalizations.of(context)!.favorites,
                          );
                        }
                      });
                    },
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
