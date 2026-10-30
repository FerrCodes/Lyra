import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/media_store_service.dart';
import '../main.dart';
import '../models/song.dart' as local;
import '../database/database.dart';
import '../audio/lyra_audio_handler.dart';

class ArtistsPage extends ConsumerStatefulWidget {
  const ArtistsPage({super.key});

  @override
  ConsumerState<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends ConsumerState<ArtistsPage> {
  Map<String, List<local.Song>> _artists = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    final rawSongs = await MediaStoreService.getSongs();
    final songs = rawSongs.map((e) => local.Song.fromMap(e)).toList();

    Map<String, List<local.Song>> tempArtists = {};
    for (var song in songs) {
      final artistName = song.artist.isEmpty ? 'Unknown Artist' : song.artist;
      if (!tempArtists.containsKey(artistName)) {
        tempArtists[artistName] = [];
      }
      tempArtists[artistName]!.add(song);
    }

    setState(() {
      _artists = tempArtists;
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
        title: const Text('Artists'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 32,
          left: 16,
          right: 16,
        ),
        itemCount: _artists.keys.length,
        itemBuilder: (context, index) {
          final artistName = _artists.keys.elementAt(index);
          final artistSongs = _artists[artistName]!;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.person, color: Colors.green),
            ),
            title: Text(
              artistName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${artistSongs.length} Lagu'),
            onTap: () {
              // Putar semua lagu artis ini
              final handler = audioHandler as LyraAudioHandler;
              handler.playQueue(
                artistSongs
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
          );
        },
      ),
    );
  }
}
