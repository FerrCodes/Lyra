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

  @override
  Widget build(BuildContext context) {
    // 1. JIKA KOSONG (SliverToBoxAdapter)
    if (displayedSongs.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          color: Colors.white, // Penting agar background tetap putih
          padding: EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.music_note, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text('Belum ada lagu.', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // 2. MODE SELEKSI (SliverReorderableList)
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
        autoScrollerVelocityScalar: 25, // Kecepatan auto-scroll saat drag
        // Efek visual saat lagu diangkat
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue = Curves.easeInOut.transform(
                animation.value,
              );
              final double elevation = lerpDouble(0, 8, animValue)!;
              return Material(
                elevation: elevation,
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: child,
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final song = displayedSongs[index];
          final isSelected = selectedSongIds.contains(song.id);

          return Material(
            key: ValueKey(song.id),
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              onTap: () => onToggleSelection(song),
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Colors.blue.shade700 : Colors.grey,
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey),
              ),
              // Drag Handle hanya di area ikon
              trailing: ReorderableDragStartListener(
                index: index,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_arrow_up, color: Colors.grey, size: 18),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // 3. MODE NORMAL (SliverList)
    return SliverList.builder(
      itemCount: displayedSongs.length,
      itemBuilder: (context, index) {
        final song = displayedSongs[index];
        return Material(
          color: Colors.white, // Wajib agar background tidak transparan
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: Colors.grey),
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => onShowOptions(song),
            ),
            onTap: () => onPlaySong(song),
            onLongPress: () => onLongPress(song),
          ),
        );
      },
    );
  }
}
