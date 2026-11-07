import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../database/database.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/songs_provider.dart';

class AddTracksSheet extends ConsumerStatefulWidget {
  final Playlist playlist;
  final List<Song> currentSongsInPlaylist;
  final VoidCallback onSongAdded;

  const AddTracksSheet({
    super.key,
    required this.playlist,
    required this.currentSongsInPlaylist,
    required this.onSongAdded,
  });

  @override
  ConsumerState<AddTracksSheet> createState() => _AddTracksSheetState();
}

class _AddTracksSheetState extends ConsumerState<AddTracksSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allSongsAsync = ref.watch(allSongsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
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

            // Filter lagu berdasarkan pencarian
            final filteredSongs = _searchQuery.isEmpty
                ? songs
                : songs.where((s) {
                    return s.title.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        s.artist.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                  }).toList();

            final Set<String> existingSongIds = widget.currentSongsInPlaylist
                .map((s) => s.id)
                .toSet();

            return Column(
              children: [
                // HANDLE BAR
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header & Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
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

                // Kolom Pencarian
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari lagu atau artis...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(height: 1),

                // List Lagu
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      final isAlreadyAdded = existingSongIds.contains(song.id);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        // Samakan desain artwork dengan halaman Songs
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: QueryArtworkWidget(
                            id: int.tryParse(song.albumId) ?? 0,
                            type: ArtworkType.ALBUM,
                            size: 200,
                            artworkHeight: 50,
                            artworkWidth: 50,
                            artworkBorder: BorderRadius.circular(8),
                            nullArtworkWidget: Container(
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
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: isAlreadyAdded
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                              ) // Biru Lyra
                            : const Icon(
                                Icons.add_circle_outline,
                                color: Colors.grey,
                              ),
                        onTap: isAlreadyAdded
                            ? null
                            : () async {
                                final db = ref.read(databaseProvider);

                                final dbSong = Song(
                                  id: song.id,
                                  title: song.title,
                                  artist: song.artist,
                                  album: song.album,
                                  path: song.path,
                                  durationMs: song.durationMs,
                                  addedAt: DateTime.now(),
                                );

                                await db.addSongToPlaylist(
                                  widget.playlist.id,
                                  dbSong,
                                );

                                if (context.mounted) {
                                  widget.onSongAdded(); // Refresh list
                                  // Tidak langsung tutup, biarkan user menambah lagu lain
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${song.title} ditambahkan',
                                      ),
                                      duration: const Duration(seconds: 1),
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
