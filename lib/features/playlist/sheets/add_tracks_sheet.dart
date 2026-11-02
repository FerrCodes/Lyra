import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/database.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/songs_provider.dart';

class AddTracksSheet extends ConsumerWidget {
  final Playlist playlist;
  final List<Song> currentSongsInPlaylist;
  final VoidCallback onSongAdded; // Callback untuk refresh halaman utama

  const AddTracksSheet({
    super.key,
    required this.playlist,
    required this.currentSongsInPlaylist,
    required this.onSongAdded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil semua lagu dari Provider
    final allSongsAsync = ref.watch(allSongsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7, // Muncul setinggi 70% layar
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return allSongsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Gagal memuat lagu: $err')),
          data: (songs) {
            if (songs.isEmpty) {
              return const Center(
                child: Text('Belum ada lagu di perangkatmu.'),
              );
            }

            // Set untuk pengecekan cepat (O(1))
            final Set<String> existingSongIds = currentSongsInPlaylist
                .map((s) => s.id)
                .toSet();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Lagu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isAlreadyAdded = existingSongIds.contains(song.id);

                      return ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.grey,
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isAlreadyAdded
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : const Icon(
                                Icons.add_circle_outline,
                                color: Colors.grey,
                              ),
                        onTap: isAlreadyAdded
                            ? null
                            : () async {
                                final db = ref.read(databaseProvider);

                                // Konversi ke DB Song
                                final dbSong = Song(
                                  id: song.id,
                                  title: song.title,
                                  artist: song.artist,
                                  album: song.album,
                                  path: song.path,
                                  durationMs: song.durationMs,
                                  addedAt: DateTime.now(),
                                );

                                // Simpan ke database playlist
                                await db.addSongToPlaylist(playlist.id, dbSong);

                                if (context.mounted) {
                                  Navigator.pop(context); // Tutup bottom sheet
                                  onSongAdded(); // Panggil callback untuk refresh halaman utama
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${song.title} ditambahkan ke playlist',
                                      ),
                                    ),
                                  );
                                }
                              },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
