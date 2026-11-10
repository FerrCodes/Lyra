import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../audio/lyra_audio_handler.dart';
import '../ui/player_page.dart';
import '../ui/search_page.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../theme/lyra_colors.dart';
import 'glass_container.dart';
import 'marquee_text.dart';

class LyraBottomBar extends ConsumerStatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final bool isScrolled;
  final VoidCallback? onHomeTap;

  const LyraBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.isScrolled,
    this.onHomeTap,
  });

  @override
  ConsumerState<LyraBottomBar> createState() => _LyraBottomBarState();
}

class _LyraBottomBarState extends ConsumerState<LyraBottomBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Mini player: gradient album kalau ada lagu, glass kalau belum ada.
  Widget _miniShell({
    required MediaItem? item,
    required double radius,
    required Widget child,
  }) {
    if (item == null) {
      return GlassContainer(height: 54, radius: radius, child: child);
    }
    return AlbumGradientContainer(
      albumId: int.tryParse(item.extras?['albumId']?.toString() ?? '') ?? 0,
      height: 54,
      radius: radius,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(searchQueryProvider, (_, next) {
      if (_searchController.text != next) {
        _searchController.text = next;
        _searchController.selection = TextSelection.collapsed(
          offset: next.length,
        );
        setState(() {});
      }
    });

    if (widget.currentIndex == 4) {
      return _buildAppleMusicSearchBar();
    }

    return RepaintBoundary(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              alignment: Alignment.bottomCenter,
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: widget.isScrolled ? _buildScrolledState() : _buildDefaultState(),
      ),
    );
  }

  // DESAIN KHUSUS TAB SEARCH
  Widget _buildAppleMusicSearchBar() {
    final colors = context.lyra;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isSearchFocused
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      PressableScale(
                        onTap: () => widget.onTabChanged(0),
                        child: GlassContainer(
                          width: 54,
                          height: 54,
                          radius: 32,
                          child: Icon(
                            Icons.home_filled,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
          ),
          Expanded(
            child: GlassContainer(
              height: 54,
              radius: 32,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: colors.textPrimary),
                cursorColor: colors.accent,
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).setQuery(val);
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Artists, Songs, Lyrics, and More',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                  prefixIcon: Icon(Icons.search, color: colors.textPrimary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.cancel,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).setQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            onTap: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).setQuery('');
              _searchFocusNode.unfocus();
              widget.onTabChanged(0);
            },
            child: GlassContainer(
              width: 54,
              height: 54,
              radius: 32,
              child: Icon(Icons.close, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // DESAIN SAAT DI ATAS (3 KAPSUL BAWAAN)
  Widget _buildDefaultState() {
    return StreamBuilder<MediaItem?>(
      key: const ValueKey('default_state'),
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;
        final colors = context.lyra;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item != null) ...[
                PressableScale(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerPage()),
                    );
                  },
                  child: _miniShell(
                    item: item,
                    radius: 30,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: MiniPlayerContent(
                                  item: item,
                                  onGradient: true,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.skip_next_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () =>
                                    (audioHandler as LyraAudioHandler)
                                        .skipToNext(),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _buildProgressBar(item),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: GlassContainer(
                      height: 54,
                      radius: 30,
                      child: _buildTabRow(colors),
                    ),
                  ),
                  const SizedBox(width: 12),
                  PressableScale(
                    onTap: () => widget.onTabChanged(4),
                    child: GlassContainer(
                      width: 54,
                      height: 54,
                      radius: 32,
                      child: Icon(
                        Icons.search_rounded,
                        color: colors.textPrimary,
                        size: 28,
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

  // Baris 4 tab + pill indikator yang posisinya dihitung pasti
  Widget _buildTabRow(LyraColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const hPad = 6.0;
        const pillInset = 3.0;
        final colWidth = (constraints.maxWidth - hPad * 2) / 4;

        return Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              left: hPad + colWidth * widget.currentIndex + pillInset,
              top: 5,
              bottom: 5,
              width: colWidth - pillInset * 2,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  Expanded(child: _buildNavIcon(0, Icons.home_filled, 'Home')),
                  Expanded(
                    child: _buildNavIcon(1, Icons.music_note_rounded, 'Songs'),
                  ),
                  Expanded(
                    child: _buildNavIcon(
                      2,
                      Icons.queue_music_rounded,
                      'Playlist',
                    ),
                  ),
                  Expanded(
                    child: _buildNavIcon(
                      3,
                      Icons.library_music_rounded,
                      'Library',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // DESAIN SAAT DI-SCROLL
  Widget _buildScrolledState() {
    return StreamBuilder<MediaItem?>(
      key: const ValueKey('scrolled_state'),
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;
        final colors = context.lyra;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: PressableScale(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerPage()),
                    );
                  },
                  child: _miniShell(
                    item: item,
                    radius: 32,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: item == null
                              ? Center(
                                  child: Text(
                                    'Pilih lagu',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: MiniPlayerContent(
                                    item: item,
                                    isCompact: true,
                                    onGradient: true,
                                  ),
                                ),
                        ),
                        if (item != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildProgressBar(item),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PressableScale(
                onTap: () => widget.onTabChanged(4),
                child: GlassContainer(
                  width: 54,
                  height: 54,
                  radius: 32,
                  child: Icon(
                    Icons.search_rounded,
                    color: colors.textPrimary,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // WIDGET PROGRESS BAR MINI PLAYER
  Widget _buildProgressBar(MediaItem item) {
    final colors = context.lyra;
    // Gunakan AudioService.position, bukan playbackState
    return StreamBuilder<Duration>(
      stream: AudioService.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = item.duration ?? Duration.zero;

        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          child: Container(
            height: 2.5,
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.2),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;
    final colors = context.lyra;
    // Warna aktif sekarang ditentukan oleh pill, ikon tetap berwarna utama
    final activeColor = isSelected ? Colors.blue : colors.textSecondary;

    return PressableScale(
      onTap: () {
        if (index == 0 && widget.onHomeTap != null) {
          widget.onHomeTap!();
        } else {
          widget.onTabChanged(index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: activeColor, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: activeColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// WIDGET ANIMASI SENTUH (SCALE)
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScale({super.key, required this.child, this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// KONTEN MINI PLAYER (UPDATED)
class MiniPlayerContent extends StatelessWidget {
  final MediaItem item;
  final bool isCompact;
  final bool onGradient;

  const MiniPlayerContent({
    super.key,
    required this.item,
    this.isCompact = false,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;
    final primary = onGradient ? Colors.white : colors.textPrimary;
    final secondary = onGradient ? Colors.white70 : colors.textSecondary;

    return Row(
      children: [
        const SizedBox(width: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: QueryArtworkWidget(
              id: int.tryParse(item.extras?['albumId']?.toString() ?? '') ?? 0,
              type: ArtworkType.ALBUM,
              size: 200,
              artworkHeight: isCompact ? 38 : 44,
              artworkWidth: isCompact ? 38 : 44,
              artworkBorder: BorderRadius.circular(10),
              nullArtworkWidget: Container(
                width: isCompact ? 38 : 44,
                height: isCompact ? 38 : 44,
                color: secondary.withValues(alpha: 0.2),
                child: Icon(Icons.music_note_rounded, color: primary, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MarqueeText(
                text: item.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 13 : 14,
                  color: primary,
                ),
              ),
              MarqueeText(
                text: item.artist ?? 'Unknown',
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  color: secondary,
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
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: primary,
                size: isCompact ? 24 : 28,
              ),
              onPressed: playing ? audioHandler.pause : audioHandler.play,
            );
          },
        ),
      ],
    );
  }
}

// CONTAINER GRADIENT MINI PLAYER (warna mengikuti sampul album)
class AlbumGradientContainer extends StatefulWidget {
  final int albumId;
  final double height;
  final double radius;
  final Widget child;

  const AlbumGradientContainer({
    super.key,
    required this.albumId,
    required this.height,
    required this.radius,
    required this.child,
  });

  @override
  State<AlbumGradientContainer> createState() => _AlbumGradientContainerState();
}

class _AlbumGradientContainerState extends State<AlbumGradientContainer> {
  // Cache per albumId supaya tidak ekstraksi ulang tiap ganti lagu / rebuild.
  static final Map<int, List<Color>> _cache = {};
  static const List<Color> _fallback = [Color(0xFF3A3A4A), Color(0xFF1E1E28)];

  List<Color> _colors = _fallback;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant AlbumGradientContainer old) {
    super.didUpdateWidget(old);
    if (old.albumId != widget.albumId) _resolve();
  }

  void _resolve() {
    final id = widget.albumId;
    final cached = _cache[id];
    if (cached != null) {
      _colors = cached;
      return;
    }
    // Pertahankan warna lama dulu; AnimatedContainer akan menggesernya
    // dengan halus begitu warna baru siap.
    _extract(id);
  }

  Future<void> _extract(int id) async {
    List<Color> result = _fallback;
    try {
      final bytes = await OnAudioQuery().queryArtwork(
        id,
        ArtworkType.ALBUM,
        size: 200,
        quality: 80,
      );
      if (bytes != null && bytes.isNotEmpty) {
        final scheme = await ColorScheme.fromImageProvider(
          provider: MemoryImage(bytes),
          brightness: Brightness.dark,
        );
        final hsl = HSLColor.fromColor(scheme.primary);
        final sat = hsl.saturation.clamp(0.35, 0.75).toDouble();
        // Digelapkan supaya teks putih selalu terbaca.
        result = [
          hsl.withSaturation(sat).withLightness(0.34).toColor(),
          hsl.withSaturation(sat).withLightness(0.18).toColor(),
        ];
      }
    } catch (_) {
      result = _fallback;
    }
    _cache[id] = result;
    if (mounted && widget.albumId == id) {
      setState(() => _colors = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: [
          BoxShadow(
            color: _colors.last.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _colors,
            ),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
