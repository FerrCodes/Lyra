import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../main.dart';
import '../models/song.dart' as local;
import '../providers/database_provider.dart';
import '../providers/songs_provider.dart';
import '../audio/lyra_audio_handler.dart';
import 'package:flutter/services.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  List<Playlist> _allPlaylists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final db = ref.read(databaseProvider);
    final data = await db.select(db.playlists).get();
    if (mounted) {
      setState(() {
        _allPlaylists = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil query pencarian dari provider
    final query = ref.watch(searchQueryProvider);
    final songsAsync = ref.watch(allSongsProvider);
    final allSongs = songsAsync.value ?? [];

    final queryLower = query.toLowerCase();

    // Logika Filter Lagu
    final filteredSongs = query.isEmpty
        ? <local.Song>[]
        : allSongs
              .where(
                (s) =>
                    s.title.toLowerCase().contains(queryLower) ||
                    s.artist.toLowerCase().contains(queryLower) ||
                    s.album.toLowerCase().contains(queryLower),
              )
              .toList();

    // Logika Filter Playlist
    final filteredPlaylists = query.isEmpty
        ? <Playlist>[]
        : _allPlaylists
              .where((p) => p.name.toLowerCase().contains(queryLower))
              .toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF2F2F7), // Background terang
        systemNavigationBarIconBrightness: Brightness.dark, // Ikon hitam
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: Stack(
          children: [
            // KONTEN UTAMA
            SafeArea(
              child: query.isEmpty
                  ? _buildInitialState()
                  : _buildSearchResults(filteredSongs, filteredPlaylists),
            ),

            // === OVERLAY GRADASI PUTIH UNTUK STATUS BAR ===
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
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.8],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Artists, Songs, Lyrics, and More',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<local.Song> songs, List<Playlist> playlists) {
    if (songs.isEmpty && playlists.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada hasil yang ditemukan.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(
        top: 16,
        bottom: 120,
      ), // Bottom padding untuk keyboard/bottom bar
      children: [
        // --- BAGIAN PLAYLIST ---
        if (playlists.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Playlist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...playlists.map(
            (p) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.queue_music, color: Colors.red),
              ),
              title: Text(
                p.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                // Navigasi ke detail playlist bisa ditambahkan di sini nanti
              },
            ),
          ),
        ],

        // --- BAGIAN LAGU ---
        if (songs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Lagu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...songs.map(
            (song) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, color: Colors.grey),
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${song.artist} • ${song.album}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
              onTap: () {
                final handler = audioHandler as LyraAudioHandler;
                final startIndex = songs.indexWhere((s) => s.id == song.id);

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
                  startIndex,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
