import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart' as local;
import '../providers/songs_provider.dart';
import '../theme/lyra_colors.dart';
import '../widgets/song_artwork.dart';
import '../widgets/lyra_header.dart';
import '../l10n/app_localizations.dart';
import 'folder_detail_page.dart';
import 'package:flutter/services.dart';

class FoldersPage extends ConsumerWidget {
  const FoldersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final songsAsync = ref.watch(allSongsProvider);
    final allSongs = songsAsync.value ?? [];

    // Grouping berdasarkan Full Path direktori
    final Map<String, List<local.Song>> folders = {};
    for (var song in allSongs) {
      if (!song.path.contains('/')) continue;
      final dirPath = song.path.substring(0, song.path.lastIndexOf('/'));

      if (!folders.containsKey(dirPath)) {
        folders[dirPath] = [];
      }
      folders[dirPath]!.add(song);
    }

    // Urutkan nama folder, jika sama urutkan berdasarkan path
    final folderKeys = folders.keys.toList()
      ..sort((a, b) {
        final nameA = a.split('/').last.toLowerCase();
        final nameB = b.split('/').last.toLowerCase();
        final comp = nameA.compareTo(nameB);
        if (comp != 0) return comp;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

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
            // KONTEN LIST
            if (songsAsync.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (folderKeys.isEmpty)
              Center(
                child: Text(
                  AppLocalizations.of(context)!.noFoldersFound,
                  style: TextStyle(color: colors.textSecondary),
                ),
              )
            else
              ListView.builder(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 80,
                  bottom: 40,
                  left: 16,
                  right: 16,
                ),
                itemCount: folderKeys.length,
                itemBuilder: (context, index) {
                  final path = folderKeys[index];
                  final folderSongs = folders[path]!;
                  final folderName = path.split('/').last;
                  final firstSong = folderSongs.first;

                  // Buang prefix /storage/emulated/0/ agar lebih rapi
                  final displayPath = path.replaceFirst(
                    RegExp(r'^/storage/emulated/0/'),
                    '',
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    // TAMBAHKAN MATERIAL DI SINI
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: SongArtwork(
                          id: int.tryParse(firstSong.id) ?? 0,
                          size: 52,
                          radius: 10,
                          placeholder: Container(
                            color: colors.accent.withValues(alpha: 0.1),
                            child: Icon(
                              Icons.folder_rounded,
                              color: colors.accent,
                            ),
                          ),
                        ),
                        title: Text(
                          folderName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayPath,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                                height: 1.3,
                              ),
                              softWrap: true,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.songsCount(folderSongs.length),
                              style: TextStyle(
                                color: colors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FolderDetailPage(
                                folderName: folderName,
                                folderPath: path,
                                songs: folderSongs,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

            // HEADER KUSTOM LYRA
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
                        AppLocalizations.of(context)!.folders,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
