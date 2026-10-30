import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// === KELAS OBSERVER UNTUK MEMANTAU NAVIGASI DI DALAM TAB ===
class _NestedNavigatorObserver extends NavigatorObserver {
  final Function(bool isRoot) onRouteChanged;
  int _routeCount = 0;

  _NestedNavigatorObserver(this.onRouteChanged);

  void _update() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onRouteChanged(_routeCount <= 1);
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeCount++;
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeCount--;
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeCount--;
    _update();
  }
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0;
  bool _isScrolled = false;
  String _currentSortFilter = 'Name';
  final ScrollController _mainScrollController = ScrollController();
  double _currentScrollOffset = 0;

  final List<String> _titles = ['Beranda', 'Songs', 'Playlist', 'Library'];

  // === STATE UNTUK NAVIGASI BERTINGKAT ===
  final GlobalKey<NavigatorState> _songsNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _playlistNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _libraryNavKey = GlobalKey<NavigatorState>();

  // === STATE UNTUK MENYEMBUNYIKAN HEADER ===
  bool _isSongsRoot = true;
  bool _isPlaylistRoot = true;
  bool _isLibraryRoot = true;

  late final _songsObserver = _NestedNavigatorObserver(
    (isRoot) => setState(() => _isSongsRoot = isRoot),
  );
  late final _playlistObserver = _NestedNavigatorObserver(
    (isRoot) => setState(() => _isPlaylistRoot = isRoot),
  );
  late final _libraryObserver = _NestedNavigatorObserver(
    (isRoot) => setState(() => _isLibraryRoot = isRoot),
  );

  @override
  Widget build(BuildContext context) {
    // Cek apakah header perlu disembunyikan
    bool hideHeader = false;
    if (_currentTab == 1 && !_isSongsRoot) hideHeader = true;
    if (_currentTab == 2 && !_isPlaylistRoot) hideHeader = true;
    if (_currentTab == 3 && !_isLibraryRoot) hideHeader = true;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // Memaksa ikon jadi hitam
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: Stack(
          children: [
            // =========================================================
            // KONTEN UTAMA (DENGAN NESTED NAVIGATOR)
            // =========================================================
            NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.axis == Axis.horizontal) return false;

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

                    // Tab Songs
                    Navigator(
                      key: _songsNavKey,
                      observers: [_songsObserver],
                      onGenerateRoute: (settings) => MaterialPageRoute(
                        builder: (_) => SongsPage(
                          key: songsPageKey,
                          onPlayTriggered: () => setState(() {}),
                          onSortChanged: (newFilter) {
                            setState(() => _currentSortFilter = newFilter);
                          },
                        ),
                      ),
                    ),

                    // Tab Playlist
                    Navigator(
                      key: _playlistNavKey,
                      observers: [_playlistObserver],
                      onGenerateRoute: (settings) => MaterialPageRoute(
                        builder: (_) => PlaylistPage(key: playlistPageKey),
                      ),
                    ),

                    // Tab Library
                    Navigator(
                      key: _libraryNavKey,
                      observers: [_libraryObserver],
                      onGenerateRoute: (settings) => MaterialPageRoute(
                        builder: (_) => LibraryPage(key: libraryPageKey),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================
            // HEADER (Hanya muncul jika bukan di halaman detail)
            // =========================================================
            if (!hideHeader) // Hanya tampil jika header sedang muncul
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  // Agar tidak menghalangi klik pada konten
                  child: Container(
                    // Tinggi mencakup status bar + area tombol pill
                    height: MediaQuery.of(context).padding.top + 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          // Lebih pekat di paling bawah layar
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (!hideHeader) ...[
              if (_currentTab == 1)
                // HEADER SONGS
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Builder(
                        builder: (buttonContext) {
                          return GestureDetector(
                            onTap: () => songsPageKey.currentState
                                ?.triggerFilterDialog(buttonContext),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
              else if (_currentTab == 2)
                // HEADER PLAYLIST
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
                              onTap: () => playlistPageKey.currentState
                                  ?.showFilterDialog(),
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
              else
                // HEADER BERANDA & LIBRARY
                LyraHeader(
                  title: _titles[_currentTab],
                  rightWidget: _currentTab != 0
                      ? Builder(
                          builder: (buttonContext) {
                            return GestureDetector(
                              onTap: () {
                                if (_currentTab == 3) {
                                  libraryPageKey.currentState?.showMoreMenu(
                                    buttonContext,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Fitur pencarian segera hadir',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _currentTab == 3
                                      ? Icons.more_horiz
                                      : Icons.search,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        )
                      : null,
                ),
            ],

            // =========================================================
            // OVERLAY GRADASI UNTUK AREA BOTTOM BAR
            // =========================================================
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  // Tinggi mencakup Bottom Bar, Mini Player, dan area aman HP
                  height: MediaQuery.of(context).padding.bottom + 170,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        // Transparan di atas agar list lagu masih terlihat samar
                        Colors.black.withValues(alpha: 0),
                        // Berubah menjadi hitam transparan di area Bottom Bar
                        Colors.black.withValues(alpha: 0.1),
                        // Lebih pekat di paling bawah layar
                        Colors.black.withValues(alpha: 0.4),
                      ],
                      stops: const [0.0, 0.6, 1.0], // Titik transisi gradasi
                    ),
                  ),
                ),
              ),
            ),

            // =========================================================
            // BOTTOM BAR
            // =========================================================
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              child: LyraBottomBar(
                currentIndex: _currentTab,
                isScrolled: _isScrolled,
                onHomeTap: () {
                  // 1. Jika sedang di halaman detail (bukan root), tutup halamannya dulu
                  bool isInsideDetail = false;
                  if (_currentTab == 1 && !_isSongsRoot) isInsideDetail = true;
                  if (_currentTab == 2 && !_isPlaylistRoot)
                    isInsideDetail = true;
                  if (_currentTab == 3 && !_isLibraryRoot)
                    isInsideDetail = true;

                  if (isInsideDetail) {
                    if (_currentTab == 1)
                      _songsNavKey.currentState?.popUntil((r) => r.isFirst);
                    if (_currentTab == 2)
                      _playlistNavKey.currentState?.popUntil((r) => r.isFirst);
                    if (_currentTab == 3)
                      _libraryNavKey.currentState?.popUntil((r) => r.isFirst);
                    return;
                  }

                  // 2. Cek apakah halaman saat ini sedang di-scroll (bukan di paling atas)
                  bool isScrolledDown = false;

                  // Cek scroll di Beranda
                  if (_currentTab == 0 && _currentScrollOffset > 10) {
                    isScrolledDown = true;
                  }
                  // Cek scroll di Songs
                  else if (_currentTab == 1) {
                    isScrolledDown =
                        songsPageKey.currentState?.isScrolledDown ?? false;
                  }
                  // Cek scroll di Playlist
                  else if (_currentTab == 2) {
                    isScrolledDown =
                        playlistPageKey.currentState?.isScrolledDown ?? false;
                  }
                  // Cek scroll di Library
                  else if (_currentTab == 3) {
                    isScrolledDown =
                        libraryPageKey.currentState?.isScrolledDown ?? false;
                  }

                  // 3. Jika sedang di-scroll, luncurkan ke atas
                  if (isScrolledDown) {
                    if (_currentTab == 0 && _mainScrollController.hasClients) {
                      _mainScrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                      );
                    } else if (_currentTab == 1) {
                      songsPageKey.currentState?.scrollToTop();
                    } else if (_currentTab == 2) {
                      playlistPageKey.currentState?.scrollToTop();
                    } else if (_currentTab == 3) {
                      libraryPageKey.currentState?.scrollToTop();
                    }
                    return;
                  }

                  // 4. Jika sudah di paling atas, pindah ke tab Beranda
                  if (_currentTab != 0) {
                    setState(() => _currentTab = 0);
                  }
                },
                onTabChanged: (index) {
                  // Jika menekan tab yang sama, kembalikan ke halaman utama tab tersebut
                  if (index == _currentTab) {
                    if (index == 1)
                      _songsNavKey.currentState?.popUntil((r) => r.isFirst);
                    if (index == 2)
                      _playlistNavKey.currentState?.popUntil((r) => r.isFirst);
                    if (index == 3)
                      _libraryNavKey.currentState?.popUntil((r) => r.isFirst);
                  } else {
                    setState(() => _currentTab = index);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
