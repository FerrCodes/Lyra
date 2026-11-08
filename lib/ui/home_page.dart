import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/lyra_bottom_bar.dart';
import 'songs_page.dart';
import 'playlist_page.dart';
import 'library_page.dart';
import 'search_page.dart';
import '../widgets/app_top_bar.dart';
import '../theme/lyra_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Memantau route aktif pada setiap nested Navigator.
class _NestedNavigatorObserver extends NavigatorObserver {
  final void Function(bool isRoot, Route<dynamic>? activeRoute) onRouteChanged;
  final List<Route<dynamic>> _routeStack = [];

  _NestedNavigatorObserver(this.onRouteChanged);

  void _update() {
    final isRoot = _routeStack.length <= 1;
    final activeRoute = _routeStack.isEmpty ? null : _routeStack.last;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onRouteChanged(isRoot, activeRoute);
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.remove(route);
    _routeStack.add(route);
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.remove(route);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeStack.remove(route);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final oldIndex = oldRoute == null ? -1 : _routeStack.indexOf(oldRoute);

    if (oldIndex >= 0) {
      if (newRoute == null) {
        _routeStack.removeAt(oldIndex);
      } else {
        _routeStack[oldIndex] = newRoute;
      }
    } else if (newRoute != null) {
      _routeStack.add(newRoute);
    }

    _update();
  }
}

class _HomePageState extends State<HomePage> {
  int _currentTab = 0;
  final ValueNotifier<bool> _isScrolled = ValueNotifier<bool>(false);
  String _currentSortFilter = 'Name';
  final ScrollController _mainScrollController = ScrollController();
  // Simpan offset berdasarkan tab DAN route, bukan satu nilai global.
  // Ini mencegah posisi scroll dari tab/halaman sebelumnya terbawa.
  final Map<int, Map<Route<dynamic>, double>> _scrollOffsetsByTab = {};
  final Map<int, Route<dynamic>?> _activeRoutesByTab = {};

  // === STATE UNTUK NAVIGASI BERTINGKAT ===
  final GlobalKey<NavigatorState> _songsNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _playlistNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _libraryNavKey = GlobalKey<NavigatorState>();

  // === STATE UNTUK MENYEMBUNYIKAN HEADER ===
  bool _isSongsRoot = true;
  bool _isPlaylistRoot = true;
  bool _isLibraryRoot = true;

  late final _songsObserver = _NestedNavigatorObserver(
    (isRoot, route) => _handleNestedRouteChanged(1, isRoot, route),
  );
  late final _playlistObserver = _NestedNavigatorObserver(
    (isRoot, route) => _handleNestedRouteChanged(2, isRoot, route),
  );
  late final _libraryObserver = _NestedNavigatorObserver(
    (isRoot, route) => _handleNestedRouteChanged(3, isRoot, route),
  );

  void _handleNestedRouteChanged(
    int tabIndex,
    bool isRoot,
    Route<dynamic>? activeRoute,
  ) {
    if (!mounted) return;

    final offset = activeRoute == null
        ? 0.0
        : (_scrollOffsetsByTab[tabIndex]?[activeRoute] ?? 0.0);

    setState(() {
      _activeRoutesByTab[tabIndex] = activeRoute;

      if (tabIndex == 1) _isSongsRoot = isRoot;
      if (tabIndex == 2) _isPlaylistRoot = isRoot;
      if (tabIndex == 3) _isLibraryRoot = isRoot;

      // Kalau route aktif berubah, pulihkan status scroll route tujuan.
      if (_currentTab == tabIndex) {
        _isScrolled.value = offset > 40;
      }
    });
  }

  Route<dynamic>? _activeRouteForTab(int tabIndex) {
    // Beranda dan Search berada langsung di route HomePage.
    if (tabIndex == 0 || tabIndex == 4) {
      return ModalRoute.of(context);
    }
    return _activeRoutesByTab[tabIndex];
  }

  double _activeOffsetForTab(int tabIndex) {
    final route = _activeRouteForTab(tabIndex);
    if (route == null) return 0.0;
    return _scrollOffsetsByTab[tabIndex]?[route] ?? 0.0;
  }

  void _handleScrollNotification(
    int tabIndex,
    ScrollNotification notification,
  ) {
    if (notification.metrics.axis != Axis.vertical) return;

    final scrollContext = notification.context;
    final route = scrollContext == null
        ? _activeRouteForTab(tabIndex)
        : ModalRoute.of(scrollContext);
    if (route == null) return;

    (_scrollOffsetsByTab[tabIndex] ??= <Route<dynamic>, double>{})[route] =
        notification.metrics.pixels;

    // Event dari route yang tidak sedang aktif hanya disimpan, tidak mengubah UI.
    if (tabIndex != _currentTab) return;
    final activeRoute = _activeRouteForTab(tabIndex);
    if (activeRoute != null && !identical(route, activeRoute)) return;

    final pixels = notification.metrics.pixels;
    final nextIsScrolled = _isScrolled.value ? pixels > 15 : pixels > 40;
    if (nextIsScrolled != _isScrolled.value) {
      _isScrolled.value = nextIsScrolled;
    }
  }

  Widget _buildScrollTrackedTab(int tabIndex, Widget child) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleScrollNotification(tabIndex, notification);
        // Jangan hentikan notification agar listener lain tetap bisa menerimanya.
        return false;
      },
      child: child,
    );
  }

  void _switchTab(int index) {
    if (index == _currentTab) return;

    final nextIsScrolled = _activeOffsetForTab(index) > 40;
    setState(() => _currentTab = index);
    _isScrolled.value = nextIsScrolled;
  }

  @override
  void dispose() {
    _isScrolled.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra; // Cek apakah header perlu disembunyikan
    bool hideHeader = false;
    if (_currentTab == 1 && !_isSongsRoot) hideHeader = true;
    if (_currentTab == 2 && !_isPlaylistRoot) hideHeader = true;
    if (_currentTab == 3 && !_isLibraryRoot) hideHeader = true;
    if (_currentTab == 4) hideHeader = true;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Ikon status bar hitam
        statusBarBrightness: Brightness.light,
        // Tambahkan ini untuk Navigation Bar HP:
        systemNavigationBarColor: Color(
          0xFFF2F2F7,
        ), // Sesuaikan dengan warna background aplikasimu
        systemNavigationBarIconBrightness:
            Brightness.dark, // Ikon navigasi hitam
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: Stack(
          children: [
            // =========================================================
            // KONTEN UTAMA (DENGAN NESTED NAVIGATOR)
            // =========================================================
            PrimaryScrollController(
              controller: _mainScrollController,
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildScrollTrackedTab(0, _buildDashboardView()),

                  // Tab Songs
                  _buildScrollTrackedTab(
                    1,
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
                  ),

                  // Tab Playlist
                  _buildScrollTrackedTab(
                    2,
                    Navigator(
                      key: _playlistNavKey,
                      observers: [_playlistObserver],
                      onGenerateRoute: (settings) => MaterialPageRoute(
                        builder: (_) => PlaylistPage(key: playlistPageKey),
                      ),
                    ),
                  ),

                  // Tab Library
                  _buildScrollTrackedTab(
                    3,
                    Navigator(
                      key: _libraryNavKey,
                      observers: [_libraryObserver],
                      onGenerateRoute: (settings) => MaterialPageRoute(
                        builder: (_) => LibraryPage(key: libraryPageKey),
                      ),
                    ),
                  ),
                  _buildScrollTrackedTab(4, const SearchPage()),
                ],
              ),
            ),

            // =========================================================
            // HEADER (Hanya muncul jika bukan di halaman detail)
            // =========================================================
            if (!hideHeader)
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
                          // Gunakan Putih dengan transparansi 0.8 (lebih tegas)
                          Colors.white.withValues(alpha: 0.8),
                          // Memudar sepenuhnya di bawah
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.8],
                      ),
                    ),
                  ),
                ),
              ),
            if (!hideHeader) ...[
              // Panggil Top Bar
              AppTopBar(
                currentTab: _currentTab,
                currentSortFilter: _currentSortFilter,
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
                  height: MediaQuery.of(context).padding.bottom + 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        // Transparan di atas
                        colors.pageBackground.withValues(alpha: 0.0),
                        // Mulai memutih di tengah
                        colors.pageBackground.withValues(alpha: 0.3),
                        // Putih solid di paling bawah
                        colors.pageBackground.withValues(alpha: 0.6),
                      ],
                      stops: const [0.0, 0.5, 1.0],
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
              child: ValueListenableBuilder<bool>(
                valueListenable: _isScrolled,
                builder: (context, isScrolled, _) => LyraBottomBar(
                  currentIndex: _currentTab,
                  isScrolled: isScrolled,
                  onHomeTap: () {
                    // Jika sedang di halaman detail (bukan root)
                    bool isInsideDetail = false;
                    if (_currentTab == 1 && !_isSongsRoot)
                      isInsideDetail = true;
                    if (_currentTab == 2 && !_isPlaylistRoot) {
                      isInsideDetail = true;
                    }
                    if (_currentTab == 3 && !_isLibraryRoot) {
                      isInsideDetail = true;
                    }

                    if (isInsideDetail) {
                      bool handledScroll = false;

                      // CEK SCROLL KHUSUS UNTUK TAB PLAYLIST (Tab 2)
                      if (_currentTab == 2) {
                        final detailState = playlistPageKey
                            .currentState
                            ?.detailPageKey
                            .currentState;
                        if (detailState != null && detailState.isScrolledDown) {
                          detailState.scrollToTop();
                          handledScroll = true; // Berhasil di-scroll
                        }
                      }

                      // Jika scroll sudah ditangani, hentikan proses (jangan tutup halaman)
                      if (handledScroll) return;

                      _switchTab(0);
                      return;
                    }

                    // Cek apakah halaman root sedang di-scroll (Kode lama kamu biarkan saja)
                    bool isScrolledDown = false;
                    if (_currentTab == 0 && _activeOffsetForTab(0) > 10) {
                      isScrolledDown = true;
                    } else if (_currentTab == 1) {
                      isScrolledDown =
                          songsPageKey.currentState?.isScrolledDown ?? false;
                    } else if (_currentTab == 2) {
                      isScrolledDown =
                          playlistPageKey.currentState?.isScrolledDown ?? false;
                    } else if (_currentTab == 3) {
                      isScrolledDown =
                          libraryPageKey.currentState?.isScrolledDown ?? false;
                    }

                    // Jika root sedang di-scroll, luncurkan ke atas
                    if (isScrolledDown) {
                      // ... (kode if-else milikmu biarkan sama)
                      if (_currentTab == 0 &&
                          _mainScrollController.hasClients) {
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

                    // Jika sudah di paling atas, pindah ke tab Beranda
                    _switchTab(0);
                  },
                  onTabChanged: (index) {
                    // Jika menekan tab yang sama, kembalikan ke halaman utama tab tersebut
                    if (index == _currentTab) {
                      if (index == 1) {
                        _songsNavKey.currentState?.popUntil((r) => r.isFirst);
                      }
                      if (index == 2) {
                        _playlistNavKey.currentState?.popUntil(
                          (r) => r.isFirst,
                        );
                      }
                      if (index == 3) {
                        _libraryNavKey.currentState?.popUntil((r) => r.isFirst);
                      }
                    } else {
                      _switchTab(index);
                    }
                  },
                ),
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
