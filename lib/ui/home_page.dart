import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/lyra_bottom_bar.dart';
import 'songs_page.dart';
import 'playlist_page.dart';
import 'library_page.dart';
import 'search_page.dart';
import '../widgets/app_top_bar.dart';
import '../theme/lyra_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../services/play_history_recorder.dart';
import '../features/home/dashboard_view.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
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

class _HomePageState extends ConsumerState<HomePage> {
  late PlayHistoryRecorder _recorder;
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

  void _showAboutBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colors = context.lyra;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6, // Muncul setinggi 60% layar
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Judul
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Lyra - Music Player Offline',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Isi Konten
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildInfoSection(
                        colors,
                        icon: Icons.library_music_rounded,
                        title: 'Pemutar Musik Offline',
                        description:
                            'Lyra memutar lagu langsung dari penyimpanan HP-mu tanpa memerlukan koneksi internet. Cepat, ringan, dan privasimu terjaga.',
                      ),
                      _buildInfoSection(
                        colors,
                        icon: Icons.queue_music_rounded,
                        title: 'Manajemen Playlist',
                        description:
                            'Buat, edit, dan atur urutan lagu sesukamu. Kamu juga bisa menandai playlist sebagai favorit (ikon bintang) agar muncul di halaman Beranda.',
                      ),
                      _buildInfoSection(
                        colors,
                        icon: Icons.search_rounded,
                        title: 'Pencarian Cepat',
                        description:
                            'Cari lagu, artis, atau album dengan cepat. Riwayat pencarian terakhirmu akan disimpan agar mudah diakses kembali.',
                      ),
                      _buildInfoSection(
                        colors,
                        icon: Icons.history_rounded,
                        title: 'Riwayat & Statistik',
                        description:
                            'Lyra mencatat lagu yang sering kamu putar dan lagu terakhir yang kamu dengarkan, ditampilkan langsung di halaman Beranda.',
                      ),
                      _buildInfoSection(
                        colors,
                        icon: Icons.dark_mode_rounded,
                        title: 'Kustomisasi Tampilan',
                        description:
                            'Ubah nama profil, atur foto, dan nikmati antarmuka Liquid Glass yang modern. Dukungan tema gelap akan segera hadir.',
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Lyra Music v1.0.0',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoSection(
    LyraColors colors, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _switchTab(int index) {
    if (index == _currentTab) return;

    final nextIsScrolled = _activeOffsetForTab(index) > 40;
    setState(() => _currentTab = index);
    _isScrolled.value = nextIsScrolled;
  }

  @override
  void initState() {
    super.initState();
    _recorder = PlayHistoryRecorder(ref.read(databaseProvider), ref);
    _recorder.start();
  }

  @override
  void dispose() {
    _recorder.dispose();
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
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: colors.pageBackground,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: colors.pageBackground,
        body: Stack(
          children: [
            // KONTEN UTAMA (DENGAN NESTED NAVIGATOR)
            PrimaryScrollController(
              controller: _mainScrollController,
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildScrollTrackedTab(
                    0,
                    DashboardView(
                      controller: _mainScrollController,
                      onOpenPlaylist: (playlist) {
                        _switchTab(2); // Pindah ke tab Playlist
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          playlistPageKey.currentState?.openPlaylist(playlist);
                        });
                      },
                    ),
                  ),

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

            // HEADER (Hanya muncul jika bukan di halaman detail)
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
                          colors.pageBackground.withValues(alpha: 0.8),
                          colors.pageBackground.withValues(alpha: 0.0),
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
                onInfoTap: _showAboutBottomSheet,
              ),
            ],

            // OVERLAY GRADASI UNTUK AREA BOTTOM BAR
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

            // BOTTOM BAR
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
}
