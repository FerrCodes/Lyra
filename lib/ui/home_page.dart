import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/lyra_audio_handler.dart';
import '../database/database.dart';
import '../main.dart';
import '../models/song.dart' as local;
import '../providers/database_provider.dart';
import '../services/media_store_service.dart';
import '../widgets/custom_floating_header.dart';
import 'playlists_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<local.Song> _allSongs = [];
  List<Song> _favorites = [];
  bool _isLoading = true;
  int _currentTab = 0;
  bool _isScrolled = false;

  LyraAudioHandler? get _handler {
    final h = audioHandler;
    return h is LyraAudioHandler ? h : null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final rawSongs = await MediaStoreService.getSongs();
    final db = ref.read(databaseProvider);
    final favs = await db.getAllFavoriteSongs();

    setState(() {
      _allSongs = rawSongs.map((e) => local.Song.fromMap(e)).toList();
      _favorites = favs;
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite(local.Song song, bool isCurrentlyFav) async {
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
    await db.toggleFavorite(dbSong);
    _loadData();
  }

  Future<void> _playSong(String path, String title) async {
    final handler = _handler;
    if (handler == null) return;
    try {
      await handler.loadFile(path, title: title);
      await handler.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memutar $title: $e')));
      }
    }
  }

  void _showSongOptions(local.Song song) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background hitam/transparan agar efek kaca terlihat jelas
      backgroundColor: const Color(0xFFF2F2F7), // Warna abu-abu terang khas iOS
      body: Stack(
        children: [
          // ================= KONTEN UTAMA =================
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels > 40 && !_isScrolled) {
                setState(() => _isScrolled = true);
              } else if (scrollInfo.metrics.pixels <= 40 && _isScrolled) {
                setState(() => _isScrolled = false);
              }
              return true;
            },
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentTab == 0
                ? _buildAllSongsList()
                : _buildFavoritesList(),
          ),

          // ================= FLOATING HEADER =================
          CustomFloatingHeader(
            onBack: () =>
                setState(() => _currentTab = _currentTab == 0 ? 1 : 0),
            title: HeaderTitlePill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _currentTab = 0),
                    child: Text(
                      'Semua',
                      style: TextStyle(
                        fontWeight: _currentTab == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => setState(() => _currentTab = 1),
                    child: Text(
                      'Favorit',
                      style: TextStyle(
                        fontWeight: _currentTab == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            rightWidget: FloatingHeaderAction(
              icon: Icons.queue_music,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlaylistsPage()),
              ),
            ),
          ),

          // ================= UI BAWAH DINAMIS =================
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              // Jika belum scroll, tampilkan desain 3 kapsul terpisah (Foto 1)
              // Jika sudah scroll, tampilkan desain 1 baris menyatu (Foto 2)
              child: _isScrolled ? _buildScrolledState() : _buildDefaultState(),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // DESAIN 3 KAPSUL TERPISAH (MINI PLAYER, NAV, SEARCH)
  // =========================================================================
  Widget _buildDefaultState() {
    return StreamBuilder<MediaItem?>(
      key: const ValueKey('default_state'),
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. MINI PLAYER (Atas)
              if (item != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.8,
                        ), // Efek kaca terang
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  item.artist ?? 'Unknown',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StreamBuilder<PlaybackState>(
                            stream: audioHandler.playbackState,
                            builder: (context, snapshot) {
                              final playing = snapshot.data?.playing ?? false;
                              return IconButton(
                                icon: Icon(
                                  playing ? Icons.pause : Icons.play_arrow,
                                  color: Colors.black,
                                  size: 28,
                                ),
                                onPressed: playing
                                    ? audioHandler.pause
                                    : audioHandler.play,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.black,
                              size: 28,
                            ),
                            onPressed: () => audioHandler.skipToNext,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 2. NAVIGASI (Bawah Kiri) & SEARCH (Bawah Kanan)
              Row(
                children: [
                  // Kapsul Navigasi
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildNavIcon(0, Icons.home_filled, 'Home'),
                              _buildNavIcon(1, Icons.grid_view_rounded, 'New'),
                              _buildNavIcon(2, Icons.wifi_tethering, 'Radio'),
                              _buildNavIcon(3, Icons.library_music, 'Library'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Kapsul Search Bulat
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // DESAIN 3 PILL TERPISAH (SAAT DI-SCROLL)
  // =========================================================================
  Widget _buildScrolledState() {
    return StreamBuilder<MediaItem?>(
      key: const ValueKey('scrolled_state'),
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;

        // Kita tidak pakai Container pembungkus luar. Langsung Row!
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // ==========================================
              // 1. PILL KIRI (HOME)
              // ==========================================
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.85,
                      ), // Putih solid/kaca
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.home_filled,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8), // Jarak antar pill
              // ==========================================
              // 2. PILL TENGAH (MINI PLAYER)
              // ==========================================
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.85,
                        ), // Putih solid/kaca
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      child: item == null
                          ? const Center(
                              child: Text(
                                'Pilih lagu',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : Row(
                              children: [
                                const SizedBox(width: 4),
                                // Cover
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Teks
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        item.artist ?? 'Unknown',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Play Button
                                StreamBuilder<PlaybackState>(
                                  stream: audioHandler.playbackState,
                                  builder: (context, snapshot) {
                                    final playing =
                                        snapshot.data?.playing ?? false;
                                    return IconButton(
                                      icon: Icon(
                                        playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.black,
                                        size: 28,
                                      ),
                                      onPressed: playing
                                          ? audioHandler.pause
                                          : audioHandler.play,
                                    );
                                  },
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8), // Jarak antar pill
              // ==========================================
              // 3. PILL KANAN (SEARCH)
              // ==========================================
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.85,
                      ), // Putih solid/kaca
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String label) {
    final isSelected = _currentTab == index;
    final activeColor = isSelected ? Colors.red : Colors.black87;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: activeColor, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: activeColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSongsList() {
    if (_allSongs.isEmpty)
      return const Center(child: Text('Tidak ada lagu ditemukan.'));
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final currentPlayingId = snapshot.data?.id;
        return ListView.builder(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 80,
            bottom: 160,
          ),
          itemCount: _allSongs.length,
          itemBuilder: (context, index) {
            final song = _allSongs[index];
            final isFav = _favorites.any((f) => f.id == song.id);
            final isPlaying = currentPlayingId == song.path;
            return Container(
              color: isPlaying
                  ? Colors.grey.withValues(alpha: 0.1)
                  : Colors.transparent,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E0E0),
                  child: Icon(Icons.music_note, color: Colors.grey),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(song, isFav),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onPressed: () => _showSongOptions(song),
                    ),
                  ],
                ),
                onTap: () => _playSong(song.path, song.title),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesList() {
    if (_favorites.isEmpty)
      return const Center(child: Text('Belum ada lagu favorit.'));
    return ListView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        bottom: 160,
      ),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final fav = _favorites[index];
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.favorite, color: Colors.white),
          ),
          title: Text(fav.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            fav.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.toggleFavorite(fav);
              _loadData();
            },
          ),
          onTap: () => _playSong(fav.path, fav.title),
        );
      },
    );
  }
}
