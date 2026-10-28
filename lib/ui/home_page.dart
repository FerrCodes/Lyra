import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import '../main.dart';
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

  void _refreshBottomBar() {
    setState(() {
      // Memaksa rebuild UI untuk menampilkan Mini Player
    });
  }

  final List<String> _titles = ['Beranda', 'Songs', 'Playlist', 'Library'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Stack(
        children: [
          // =========================================================
          // KONTEN UTAMA (TAB 0 = BERANDA, TAB 1-3 = FILE LUAR)
          // =========================================================
          NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              // Abaikan jika ini adalah scroll horizontal (seperti carousel)
              if (scrollInfo.metrics.axis == Axis.horizontal) {
                return false; // Biarkan carousel menangani scroll-nya sendiri
              }

              // Logika untuk scroll vertikal
              if (scrollInfo.metrics.pixels > 40 && !_isScrolled) {
                setState(() => _isScrolled = true);
              } else if (scrollInfo.metrics.pixels <= 40 && _isScrolled) {
                setState(() => _isScrolled = false);
              }
              return true;
            },
            child: IndexedStack(
              index: _currentTab,
              children: [
                _buildDashboardView(), // <--- TAB 0: BERANDA (KODE DISATUKAN DI SINI)
                SongsPage(
                  key: songsPageKey,
                  onPlayTriggered: _refreshBottomBar,
                  onSortChanged: (newFilter) {
                    setState(() => _currentSortFilter = newFilter);
                  },
                  onDoubleTapHome: () {
                    // Jika user klik 2x, pindah ke Beranda
                    setState(() => _currentTab = 0);
                  },
                ), // <--- TAB 1
                const PlaylistPage(), // <--- TAB 2
                const LibraryPage(), // <--- TAB 3
              ],
            ),
          ),

          // HEADER
          // HEADER
          if (_currentTab == 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => songsPageKey.currentState
                        ?.triggerFilterDialog(), // <--- Panggil Filter
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sort, color: Colors.black87, size: 20),
                          SizedBox(width: 8),
                          Text(
                            _currentSortFilter,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _buildHeaderCircleButton(
                        Icons.shuffle,
                        onTap: () => songsPageKey.currentState
                            ?.playAllShuffled(), // <--- Panggil Shuffle
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderCircleButton(
                        Icons.play_arrow,
                        onTap: () => songsPageKey.currentState
                            ?.playAll(), // <--- Panggil Play
                      ),
                    ],
                  ),
                ],
              ),
            )
          else // Jika di halaman Beranda, Playlist, atau Library
            LyraHeader(
              title: _titles[_currentTab],
              rightWidget:
                  _currentTab !=
                      0 // Hilangkan search di Beranda
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

          // BOTTOM BAR
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: LyraBottomBar(
              currentIndex: _currentTab,
              isScrolled: _isScrolled,
              onHomeTap: () {
                // Jika sedang di Beranda, tidak usah apa-apa
                if (_currentTab == 0) return;
                // Jika sedang di Songs (Tab 1), panggil fungsi scrollToTop
                if (_currentTab == 1) {
                  songsPageKey.currentState?.scrollToTop();
                } else {
                  // Jika di tab lain, langsung pindah ke Beranda
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

  Widget _buildHeaderCircleButton(
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // Pastikan baris ini ada
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
        child: Icon(icon, color: Colors.black, size: 20),
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
        // 1. SAPAAN
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

        // 2. PLAYLIST TERAKHIR DIPUTAR
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Playlist Terakhir Diputar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),

        // Carousel
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

        // 3. LAGU SERING DIPUTAR
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Lagu Sering Diputar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),

        // Grid
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
