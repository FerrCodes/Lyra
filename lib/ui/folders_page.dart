import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/media_store_service.dart';
import '../main.dart';
import '../models/song.dart' as local;
import '../database/database.dart';
import '../audio/lyra_audio_handler.dart';

class FoldersPage extends ConsumerStatefulWidget {
  const FoldersPage({super.key});

  @override
  ConsumerState<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends ConsumerState<FoldersPage> {
  Map<String, List<local.Song>> _folders = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final rawSongs = await MediaStoreService.getSongs();
    final songs = rawSongs.map((e) => local.Song.fromMap(e)).toList();

    Map<String, List<local.Song>> tempFolders = {};
    for (var song in songs) {
      // Mengambil nama folder dari path file
      final parts = song.path.split('/');
      final folderName = parts.length > 1
          ? parts[parts.length - 2]
          : 'Unknown Folder';

      if (!tempFolders.containsKey(folderName)) {
        tempFolders[folderName] = [];
      }
      tempFolders[folderName]!.add(song);
    }

    setState(() {
      _folders = tempFolders;
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
        title: const Text('Folders'),
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
        itemCount: _folders.keys.length,
        itemBuilder: (context, index) {
          final folderName = _folders.keys.elementAt(index);
          final folderSongs = _folders[folderName]!;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.folder, color: Colors.orange),
            ),
            title: Text(
              folderName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${folderSongs.length} Lagu'),
            onTap: () {
              final handler = audioHandler as LyraAudioHandler;
              handler.playQueue(
                folderSongs
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
