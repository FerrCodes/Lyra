import 'package:flutter/material.dart';
import '../../../database/database.dart';

class PlaylistTrackList extends StatelessWidget {
  final List<Song> displayedSongs;
  final bool isSelectionMode;
  final Set<String> selectedSongIds;
  final String currentSort;

  // Callback ke halaman utama
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
    if (displayedSongs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.music_note, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Belum ada lagu.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // TAMPILAN MODE SELECT (Bisa Drag & Drop)
    if (isSelectionMode) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: displayedSongs.length,
        onReorderItem: (oldIndex, newIndex) {
          // Validasi: Hanya boleh reorder jika Custom order
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
        itemBuilder: (context, index) {
          final song = displayedSongs[index];
          final isSelected = selectedSongIds.contains(song.id);

          return Material(
            key: ValueKey(song.id), // Key tetap di Material
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.transparent,
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
              // BUNGKUS TRAILING DENGAN LISTENER
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

    // TAMPILAN NORMAL (Tanpa Drag & Drop)
    return Material(
      color: Colors.transparent,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayedSongs.length,
        itemBuilder: (context, index) {
          final song = displayedSongs[index];
          return Material(
            color: Colors.transparent,
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
              trailing: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onPressed: () => onShowOptions(song),
              ),
              onTap: () => onPlaySong(song),
              onLongPress: () => onLongPress(song),
            ),
          );
        },
      ),
    );
  }
}
