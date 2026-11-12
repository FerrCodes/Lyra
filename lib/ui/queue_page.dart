import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../audio/lyra_audio_handler.dart';
import '../main.dart';
import '../theme/lyra_colors.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final LyraAudioHandler _handler = audioHandler as LyraAudioHandler;
  late List<MediaItem> _items;
  StreamSubscription<List<MediaItem>>? _sub;

  @override
  void initState() {
    super.initState();
    _items = List.of(_handler.queue.value);
    _sub = _handler.queue.listen((q) {
      if (mounted) setState(() => _items = List.of(q));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Key unik walau lagu yang sama muncul lebih dari sekali
  List<Key> _buildKeys() {
    final seen = <String, int>{};
    return _items.map((m) {
      final n = seen.update(m.id, (v) => v + 1, ifAbsent: () => 0);
      return ValueKey('${m.id}#$n');
    }).toList();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1; // konvensi ReorderableListView
    if (oldIndex == newIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    _handler.moveQueueItem(oldIndex, newIndex);
  }

  void _remove(int index) {
    final item = _items[index];
    setState(() => _items.removeAt(index)); // wajib sinkron untuk Dismissible

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Text(
          '"${item.title}" dihapus dari antrean',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _handler.insertQueueItem(index, item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colors.pageBackground,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: colors.pageBackground,
        body: Column(
          children: [
            SizedBox(height: top + 8),
            _buildHeader(colors),
            Expanded(
              child: StreamBuilder<(int?, bool)>(
                stream: _handler.playbackState
                    .map(
                      (s) => (
                        s.queueIndex,
                        s.shuffleMode == AudioServiceShuffleMode.all,
                      ),
                    )
                    .distinct(),
                builder: (context, snap) {
                  final currentIndex = snap.data?.$1;
                  final shuffleOn = snap.data?.$2 ?? false;
                  return _buildList(colors, currentIndex, shuffleOn);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LyraColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 32,
              color: colors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Antrean',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ),
          Text(
            '${_items.length} lagu',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(LyraColors colors, int? currentIndex, bool shuffleOn) {
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Antrean kosong',
          style: TextStyle(color: colors.textSecondary, fontSize: 16),
        ),
      );
    }

    final keys = _buildKeys();

    return Column(
      children: [
        if (shuffleOn)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Mode acak aktif. Matikan acak untuk menggeser urutan.',
              style: TextStyle(fontSize: 12, color: colors.textPrimary),
            ),
          ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(bottom: 40),
            itemCount: _items.length,
            onReorder: _onReorder,
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.transparent,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: child,
            ),
            itemBuilder: (context, index) {
              final item = _items[index];
              final isCurrent = index == currentIndex;
              return _buildTile(
                key: keys[index],
                colors: colors,
                item: item,
                index: index,
                isCurrent: isCurrent,
                canDrag: !shuffleOn,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTile({
    required Key key,
    required LyraColors colors,
    required MediaItem item,
    required int index,
    required bool isCurrent,
    required bool canDrag,
  }) {
    final albumId =
        int.tryParse(item.extras?['albumId']?.toString() ?? '') ?? 0;

    final tile = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
      decoration: BoxDecoration(
        color: isCurrent
            ? colors.accent.withValues(alpha: 0.12)
            : colors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: QueryArtworkWidget(
              id: albumId,
              type: ArtworkType.ALBUM,
              size: 200,
              artworkWidth: 48,
              artworkHeight: 48,
              artworkFit: BoxFit.cover,
              keepOldArtwork: true,
              nullArtworkWidget: Container(
                width: 48,
                height: 48,
                color: colors.textSecondary.withValues(alpha: 0.15),
                child: Icon(
                  Icons.music_note_rounded,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isCurrent ? colors.accent : colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.artist ?? 'Unknown Artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 20,
                color: colors.accent,
              ),
            ),
          if (canDrag)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );

    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handler.skipToQueueItem(index),
      child: tile,
    );

    // Lagu yang sedang diputar tidak boleh di-swipe
    if (isCurrent) {
      return KeyedSubtree(key: key, child: content);
    }

    return Dismissible(
      key: key,
      direction: DismissDirection.horizontal,
      onDismissed: (_) => _remove(index),
      background: _swipeBackground(colors, Alignment.centerLeft),
      secondaryBackground: _swipeBackground(colors, Alignment.centerRight),
      child: content,
    );
  }

  Widget _swipeBackground(LyraColors colors, Alignment align) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: align,
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }
}
