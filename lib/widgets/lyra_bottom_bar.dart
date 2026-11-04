import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../audio/lyra_audio_handler.dart';
import '../ui/player_page.dart';
import '../ui/search_page.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
    // Memantau kapan keyboard muncul/hilang untuk menyembunyikan tombol Home
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSearchFocused = _searchFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // JIKA DI TAB SEARCH (INDEX 4), TAMPILKAN SEARCH BAR KHUSUS
    if (widget.currentIndex == 4) {
      return _buildAppleMusicSearchBar();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: widget.isScrolled ? _buildScrolledState() : _buildDefaultState(),
    );
  }

  // ==========================================
  // DESAIN KHUSUS TAB SEARCH (APPLE MUSIC STYLE)
  // ==========================================
  Widget _buildAppleMusicSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Tombol Home (Disembunyikan dengan animasi jika keyboard muncul)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isSearchFocused
                ? const SizedBox.shrink() // Hilang saat mengetik
                : Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.home_filled,
                                color: Colors.black,
                              ),
                              onPressed: () => widget.onTabChanged(0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
          ),

          // 2. Kolom Input Pencarian
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).setQuery(val);
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Artists, Songs, Lyrics, and More',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(searchQueryProvider.notifier)
                                    .setQuery('');
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Tombol Close (Keluar Pencarian)
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).setQuery('');
                    _searchFocusNode.unfocus();
                    widget.onTabChanged(0);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // DESAIN SAAT DI ATAS (3 KAPSUL BAWAAN)
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
              if (item != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlayerPage()),
                        );
                      },
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: MiniPlayerContent(item: item)),
                            IconButton(
                              icon: const Icon(
                                Icons.skip_next,
                                color: Colors.black,
                                size: 28,
                              ),
                              onPressed: () =>
                                  (audioHandler as LyraAudioHandler)
                                      .skipToNext(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
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
                              _buildNavIcon(1, Icons.music_note, 'Songs'),
                              _buildNavIcon(2, Icons.queue_music, 'Playlist'),
                              _buildNavIcon(3, Icons.library_music, 'Library'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => widget.onTabChanged(4), // Pindah ke Tab 4
                    child: ClipRRect(
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
  // DESAIN SAAT DI-SCROLL (1 BARIS PILL TERPISAH)
  // =========================================================================
  Widget _buildScrolledState() {
    return StreamBuilder<MediaItem?>(
      key: const ValueKey('scrolled_state'),
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onHomeTap != null) {
                          widget.onHomeTap!();
                        } else {
                          widget.onTabChanged(0);
                        }
                      },
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayerPage()),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
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
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: MiniPlayerContent(
                                  item: item,
                                  isCompact: true,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => widget.onTabChanged(4), // Pindah ke Tab 4
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavIcon(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;
    final activeColor = isSelected ? Colors.red : Colors.black87;
    return GestureDetector(
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

// Widget Khusus untuk Isi Mini Player (Cover, Teks, Tombol Play)
class MiniPlayerContent extends StatelessWidget {
  final MediaItem item;
  final bool isCompact;

  const MiniPlayerContent({
    super.key,
    required this.item,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: QueryArtworkWidget(
            id: int.tryParse(item.extras?['albumId']?.toString() ?? '') ?? 0,
            type: ArtworkType.ALBUM,
            size: 200,
            artworkHeight: isCompact ? 38 : 44,
            artworkWidth: isCompact ? 38 : 44,
            artworkBorder: BorderRadius.circular(8),
            nullArtworkWidget: Container(
              width: isCompact ? 38 : 44,
              height: isCompact ? 38 : 44,
              color: Colors.grey.shade300,
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 20,
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
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 13 : 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                item.artist ?? 'Unknown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
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
