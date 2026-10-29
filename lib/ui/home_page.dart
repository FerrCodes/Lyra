import 'package:flutter/material.dart';
import '../widgets/lyra_bottom_bar.dart';
import '../widgets/lyra_header.dart';
import 'songs_page.dart';
import 'playlist_page.dart';
import 'library_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0;
  bool _isScrolled = false;
  String _currentSortFilter = 'Name';
  final ScrollController _mainScrollController = ScrollController();

  // Menyimpan nilai posisi scroll saat ini
  double _currentScrollOffset = 0;

  final List<String> _titles = ['Beranda', 'Songs', 'Playlist', 'Library'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          // =========================================================
          // KONTEN UTAMA
          // =========================================================
          NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              if (scrollInfo.metrics.axis == Axis.horizontal) return false;

              // Simpan posisi scroll saat ini
              _currentScrollOffset = scrollInfo.metrics.pixels;

              if (scrollInfo.metrics.pixels > 40 && !_isScrolled) {
                setState(() => _isScrolled = true);
              } else if (scrollInfo.metrics.pixels <= 40 && _isScrolled) {
                setState(() => _isScrolled = false);
              }
              return true;
            },
            child: PrimaryScrollController(
              controller: _mainScrollController,
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildDashboardView(),
                  SongsPage(
                    key: songsPageKey,
                    onPlayTriggered: () => setState(() {}),
                    onSortChanged: (newFilter) {
                      setState(() => _currentSortFilter = newFilter);
                    },
                  ),
                  PlaylistPage(key: playlistPageKey),
                  const LibraryPage(),
                ],
              ),
            ),
          ),

          // =========================================================
          // HEADER
          // =========================================================
          if (_currentTab == 1) // HEADER SONGS
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        songsPageKey.currentState?.triggerFilterDialog(),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sort,
                            color: Colors.black87,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentSortFilter,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              songsPageKey.currentState?.playAllShuffled(),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              Icons.shuffle,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => songsPageKey.currentState?.playAll(),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 16),
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_currentTab == 2) // HEADER PLAYLIST
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Playlist',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => playlistPageKey.currentState
                              ?.showCreatePlaylistDialog(),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              playlistPageKey.currentState?.showFilterDialog(),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 16),
                            child: Icon(
                              Icons.sort,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else // HEADER BERANDA & LIBRARY
            LyraHeader(
              title: _titles[_currentTab],
              rightWidget: _currentTab != 0
                  ? GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    )
                  : null,
            ),

          // =========================================================
          // BOTTOM BAR (LOGIKA BARU)
          // =========================================================
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: LyraBottomBar(
              currentIndex: _currentTab,
              isScrolled: _isScrolled,
              onHomeTap: () {
                // Jika sedang di Tab Beranda
                if (_currentTab == 0) {
                  if (_mainScrollController.hasClients &&
                      _currentScrollOffset > 0) {
                    _mainScrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                  return;
                }

                // Jika di Tab Songs/Playlist/Library
                if (_currentScrollOffset > 10) {
                  // Jika sedang di tengah scroll (bukan di paling atas)
                  // Maka: Scroll ke atas
                  if (_mainScrollController.hasClients) {
                    _mainScrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                } else {
                  // Jika sudah di ujung paling atas
                  // Maka: Pindah ke Beranda
                  setState(() => _currentTab = 0);
                }
              },
              onTabChanged: (index) {
                setState(() => _currentTab = index);
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // UI BERANDA (DASHBOARD)
  // =========================================================
  Widget _buildDashboardView() {
    return ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        bottom: 160,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat ${_getGreeting()},',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                'Siap mendengarkan sesuatu hari ini?',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Playlist Terakhir Diputar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.queue_music,
                        size: 40,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Playlist Favorit ${index + 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Lagu Sering Diputar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(12),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.album, size: 50, color: Colors.blueAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Lagu Hits ${index + 1}',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }
}
