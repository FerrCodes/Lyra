import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../../../database/database.dart';
import '../../../main.dart';
import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'dart:async';
import '../../../widgets/song_artwork.dart';

class PlaylistTrackList extends StatelessWidget {
  final List<Song> displayedSongs;
  final bool isSelectionMode;
  final Set<String> selectedSongIds;
  final String currentSort;
  final Map<String, String> albumIds;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(Song song) onToggleSelection;
  final Function(Song song) onPlaySong;
  final Function(Song song) onLongPress;
  final Function(Song song) onShowOptions;

  const PlaylistTrackList({
    super.key,
    required this.displayedSongs,
    required this.isSelectionMode,
    required this.selectedSongIds,
    required this.currentSort,
    required this.onReorder,
    required this.onToggleSelection,
    required this.onPlaySong,
    required this.onLongPress,
    required this.onShowOptions,
    required this.albumIds,
  });

  @override
  Widget build(BuildContext context) {
    if (displayedSongs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAE3),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              children: [
                Text(
                  'Belum ada lagu',
                  style: TextStyle(
                    color: Color(0xFF34322D),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Tambahkan beberapa lagu untuk mengisi playlist ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF817C73),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isSelectionMode) {
      return SliverReorderableList(
        itemCount: displayedSongs.length,
        onReorderItem: (oldIndex, newIndex) {
          if (currentSort != 'Custom order') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ubah ke "Custom order" untuk menggeser lagu'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
          onReorder(oldIndex, newIndex);
        },
        autoScrollerVelocityScalar: 25,
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final animValue = Curves.easeInOut.transform(animation.value);
              final elevation = lerpDouble(0, 9, animValue)!;
              return Material(
                elevation: elevation,
                color: const Color(0xFFF6F5F1),
                borderRadius: BorderRadius.circular(18),
                child: child,
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final song = displayedSongs[index];
          final selected = selectedSongIds.contains(song.id);

          return Container(
            key: ValueKey(song.id),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFE6EAF2)
                  : const Color(0xFFEFEDE7),
              borderRadius: BorderRadius.circular(17),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: () => onToggleSelection(song),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected
                          ? const Color(0xFF4D648F)
                          : const Color(0xFFA29D93),
                      size: 22,
                    ),
                    const SizedBox(width: 11),
                    _buildArtwork(song, index),
                    const SizedBox(width: 12),
                    _buildSongLabels(song, false),
                    const SizedBox(width: 8),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          color: Color(0xFF8F8A81),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final currentMediaItem = snapshot.data;

        return SliverList.builder(
          itemCount: displayedSongs.length,
          itemBuilder: (context, index) {
            final song = displayedSongs[index];
            // Cek apakah lagu ini yang sedang diputar
            final isPlaying = currentMediaItem?.id == song.path;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: () => onPlaySong(song),
                  onLongPress: () => onLongPress(song),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                    child: Row(
                      children: [
                        _buildArtwork(song, index),
                        const SizedBox(width: 13),
                        _buildSongLabels(song, isPlaying),
                        const SizedBox(width: 8),
                        // TAMPILKAN ANIMASI JIKA SEDANG DIPUTAR
                        if (isPlaying) ...[
                          const EqualizerAnimation(),
                          const SizedBox(width: 8),
                        ],

                        IconButton(
                          tooltip: 'More options',
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => onShowOptions(song),
                          icon: const Icon(
                            Icons.more_vert,
                            color: Color(0xFF858077),
                            size: 23,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArtwork(Song song, int index) {
    return SongArtwork(
      id: int.tryParse(song.id) ?? 0,
      size: 50,
      radius: 8,
      placeholder: Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.music_note, color: Colors.grey),
      ),
    );
  }

  Widget _buildSongLabels(Song song, bool isPlaying) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              // Ubah warna menjadi biru jika sedang diputar
              color: isPlaying ? Colors.blue : const Color(0xFF292822),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8A857C),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Animasi Equalizer
class EqualizerAnimation extends StatefulWidget {
  const EqualizerAnimation({super.key});

  @override
  State<EqualizerAnimation> createState() => _EqualizerAnimationState();
}

class _EqualizerAnimationState extends State<EqualizerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late StreamSubscription<PlaybackState> _playbackStateSub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Pantau status putar (playing/paused)
    _playbackStateSub = audioHandler.playbackState.listen((state) {
      if (state.playing) {
        // Jika lagu main, jalankan animasi
        if (!_controller.isAnimating) {
          _controller.repeat(reverse: true);
        }
      } else {
        // Jika lagu pause, hentikan animasi tepat di frame terakhir
        if (_controller.isAnimating) {
          _controller.stop();
        }
      }
    });
  }

  @override
  void dispose() {
    _playbackStateSub.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(math.sin(_controller.value * math.pi * 2).abs(), 12),
            const SizedBox(width: 2),
            _buildBar(math.cos(_controller.value * math.pi * 2).abs(), 16),
            const SizedBox(width: 2),
            _buildBar(math.sin(_controller.value * math.pi * 3).abs(), 10),
          ],
        );
      },
    );
  }

  Widget _buildBar(double value, double maxHeight) {
    return Container(
      width: 3,
      height: 4 + (maxHeight * value),
      decoration: BoxDecoration(
        color: Colors.blue, // <--- Warna diubah menjadi biru
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
