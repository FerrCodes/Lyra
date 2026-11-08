import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../main.dart';
import '../models/song.dart' as local;
import '../providers/songs_provider.dart';
import '../audio/lyra_audio_handler.dart';
import '../theme/lyra_colors.dart';
import 'package:audio_service/audio_service.dart';
import '../features/search/search_logic.dart';
import '../features/search/widgets/song_tile.dart';
import '../features/search/widgets/artist_tile.dart';
import '../features/search/widgets/album_tile.dart';
import '../features/search/widgets/top_result_card.dart';

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
  Timer? _debounce;
  String _debouncedQuery = '';
  SearchResults? _results;
  String? _lastQuery;
  List<local.Song>? _lastSongs;
  List<String> _recentSearches = [];
  static const _recentKey = 'recent_searches';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();

    // Listener untuk debounce pencarian
    ref.listenManual(searchQueryProvider, (previous, next) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _debouncedQuery = next;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _recentSearches = prefs.getStringList(_recentKey) ?? [];
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_recentKey) ?? [];
    list.remove(query); // Hapus jika sudah ada
    list.insert(0, query); // Tambah ke paling depan
    if (list.length > 8) list.removeLast(); // Maksimal 8
    await prefs.setStringList(_recentKey, list);
    if (mounted) setState(() => _recentSearches = list);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
    if (mounted) setState(() => _recentSearches = []);
  }

  void _playSong(local.Song song, List<local.Song> queueSongs) {
    final handler = audioHandler as LyraAudioHandler;
    final startIndex = queueSongs.indexWhere((s) => s.id == song.id);

    final albumIds = {for (var s in queueSongs) s.path: s.albumId};

    handler.playQueue(
      queueSongs
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
      startIndex >= 0 ? startIndex : 0,
      albumIds: albumIds,
      sourceType: 'Search',
      sourceName: _debouncedQuery,
    );

    _saveRecentSearch(_debouncedQuery);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pantau perubahan lagu dari provider
    final songsAsync = ref.watch(allSongsProvider);
    final allSongs = songsAsync.value ?? [];

    // Hitung ulang hasil hanya jika query atau daftar lagu berubah
    if (_debouncedQuery.isEmpty) {
      _results = null;
      _lastQuery = null;
    } else if (_debouncedQuery != _lastQuery ||
        !identical(allSongs, _lastSongs)) {
      _results = performSearch(allSongs, _debouncedQuery);
      _lastQuery = _debouncedQuery;
      _lastSongs = allSongs;
    }

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
            SafeArea(
              top: false,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.top + 8,
                    ),
                  ),
                  if (_debouncedQuery.isEmpty)
                    _buildInitialState(colors)
                  else if (_results == null ||
                      (_results!.songs.isEmpty &&
                          _results!.artists.isEmpty &&
                          _results!.albums.isEmpty))
                    _buildEmptyState(colors)
                  else ...[
                    // Top Result
                    if (_results!.topSongResult != null) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Top Result',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: TopResultCard(
                          song: _results!.topSongResult!,
                          onPlay: () => _playSong(
                            _results!.topSongResult!,
                            _results!.songs.map((e) => e.song).toList(),
                          ),
                        ),
                      ),
                    ],

                    // Songs
                    if (_results!.songs.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            'Songs',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: _results!.songs.length,
                        itemBuilder: (context, index) {
                          final res = _results!.songs[index];
                          return StreamBuilder<MediaItem?>(
                            stream: audioHandler.mediaItem,
                            builder: (context, snap) {
                              return SongTile(
                                song: res.song,
                                query: _debouncedQuery,
                                isPlaying: snap.data?.id == res.song.path,
                                onTap: () => _playSong(
                                  res.song,
                                  _results!.songs.map((e) => e.song).toList(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],

                    // Artists
                    if (_results!.artists.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            'Artists',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: _results!.artists.length,
                        itemBuilder: (context, index) {
                          return ArtistTile(
                            artist: _results!.artists[index],
                            onTap: () {},
                          );
                        },
                      ),
                    ],

                    // Albums
                    if (_results!.albums.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            'Albums',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: _results!.albums.length,
                        itemBuilder: (context, index) {
                          return AlbumTile(
                            album: _results!.albums[index],
                            onTap: () {},
                          );
                        },
                      ),
                    ],

                    // Padding bawah
                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                ],
              ),
            ),

            // OVERLAY GRADASI ATAS
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
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState(LyraColors colors) {
    if (_recentSearches.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 80,
                color: colors.textSecondary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Artists, Songs, Lyrics, and More',
                style: TextStyle(fontSize: 16, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: Text('Clear', style: TextStyle(color: colors.accent)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches
                  .map(
                    (q) => ActionChip(
                      label: Text(
                        q,
                        style: TextStyle(color: colors.textPrimary),
                      ),
                      backgroundColor: colors.textSecondary.withValues(
                        alpha: 0.1,
                      ),
                      side: BorderSide.none,
                      onPressed: () {
                        ref.read(searchQueryProvider.notifier).setQuery(q);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LyraColors colors) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text(
          'Tidak ada hasil untuk "$_debouncedQuery"',
          style: TextStyle(fontSize: 16, color: colors.textSecondary),
        ),
      ),
    );
  }
}
