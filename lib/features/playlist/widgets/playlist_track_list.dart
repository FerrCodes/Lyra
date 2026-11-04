import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import '../../../database/database.dart';

class PlaylistTrackList extends StatelessWidget {
  final List<Song> displayedSongs;
  final bool isSelectionMode;
  final Set<String> selectedSongIds;
  final String currentSort;

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
  });

  static const List<List<Color>> _artworkPalettes = [
    [Color(0xFF625A73), Color(0xFFB4A6C1)],
    [Color(0xFF536A69), Color(0xFFA5B9A8)],
    [Color(0xFF8A6654), Color(0xFFD0B49A)],
    [Color(0xFF555F83), Color(0xFFAAB4D1)],
  ];

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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    _buildArtwork(index),
                    const SizedBox(width: 12),
                    _buildSongLabels(song),
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

    return SliverList.builder(
      itemCount: displayedSongs.length,
      itemBuilder: (context, index) {
        final song = displayedSongs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: () => onPlaySong(song),
              onLongPress: () => onLongPress(song),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 5, 8),
                child: Row(
                  children: [
                    _buildArtwork(index),
                    const SizedBox(width: 13),
                    _buildSongLabels(song),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'More options',
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
  }

  Widget _buildArtwork(int index) {
    final palette = _artworkPalettes[index % _artworkPalettes.length];
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.graphic_eq_rounded,
        color: Color(0xE6FFFFFF),
        size: 25,
      ),
    );
  }

  Widget _buildSongLabels(Song song) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF292822),
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
