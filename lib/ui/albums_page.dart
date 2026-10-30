import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/media_store_service.dart';
import '../main.dart';
import '../models/song.dart' as local;
import '../database/database.dart';
import '../audio/lyra_audio_handler.dart';

class AlbumsPage extends ConsumerStatefulWidget {
  const AlbumsPage({super.key});

  @override
  ConsumerState<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends ConsumerState<AlbumsPage> {
  Map<String, List<local.Song>> _albums = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final rawSongs = await MediaStoreService.getSongs();
    final songs = rawSongs.map((e) => local.Song.fromMap(e)).toList();

    Map<String, List<local.Song>> tempAlbums = {};
    for (var song in songs) {
      if (!tempAlbums.containsKey(song.album)) {
        tempAlbums[song.album] = [];
      }
      tempAlbums[song.album]!.add(song);
    }

    setState(() {
      _albums = tempAlbums;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(
        backgroundColor: Color(0xFFF2F2F7),
        body: Center(child: CircularProgressIndicator()),
      );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Albums'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 32,
          left: 16,
          right: 16,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: _albums.keys.length,
        itemBuilder: (context, index) {
          final albumName = _albums.keys.elementAt(index);
          final albumSongs = _albums[albumName]!;

          return GestureDetector(
            onTap: () {
              // Putar semua lagu di album ini
              final handler = audioHandler as LyraAudioHandler;
              handler.playQueue(
                albumSongs
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
                0,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: const Icon(
                        Icons.album,
                        size: 60,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          albumName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${albumSongs.length} Lagu',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
