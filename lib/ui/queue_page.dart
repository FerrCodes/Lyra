import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../audio/lyra_audio_handler.dart';
import '../main.dart';
import '../theme/lyra_colors.dart';

class QueuePage extends StatefulWidget {
  final ScrollController? scrollController;
  const QueuePage({super.key, this.scrollController});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final LyraAudioHandler _handler = audioHandler as LyraAudioHandler;
  late List<MediaItem> _items;
  StreamSubscription<List<MediaItem>>? _sub;
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // 3. Stream dibuat sekali di field, bukan di dalam build
  late final Stream<(int?, bool)> _stateStream = _handler.playbackState
      .map((s) => (s.queueIndex, s.shuffleMode == AudioServiceShuffleMode.all))
      .distinct();

  @override
  void initState() {
    super.initState();
    _items = List.of(_handler.queue.value);
    _sub = _handler.queue.listen((q) {
      if (mounted) setState(() => _items = List.of(q));
    });

    // 5. Auto-scroll diperbaiki agar mempertimbangkan tinggi header
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentIndex = _handler.playbackState.value.queueIndex;
      if (currentIndex != null &&
          widget.scrollController != null &&
          widget.scrollController!.hasClients) {
        final offset = ((currentIndex - 1) * 70.0).clamp(
          0.0,
          widget.scrollController!.position.maxScrollExtent,
        );
        widget.scrollController!.jumpTo(offset);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<Key> _buildKeys() {
    final seen = <String, int>{};
    return _items.map((m) {
      final n = seen.update(m.id, (v) => v + 1, ifAbsent: () => 0);
      return ValueKey('${m.id}#$n');
    }).toList();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    _handler.moveQueueItem(oldIndex, newIndex);
  }

  // 4. _remove sekarang menerima MediaItem dan mencari index secara dinamis
  Future<void> _remove(MediaItem item) async {
    final index = _items.indexOf(item);
    if (index == -1) return; // Jika item sudah tidak ada, batalkan

    setState(() => _items.removeAt(index));

    final ok = await _handler.removeTrackFromQueue(index);
    if (!mounted) return;
    if (!ok) {
      setState(() => _items.insert(index, item));
      return;
    }

    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
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
          onPressed: () =>
              _handler.insertTrackToQueue(index.clamp(0, _items.length), item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: ScaffoldMessenger(
        key: _messengerKey,
        child: Scaffold(
          backgroundColor:
              Colors.transparent, // Transparan agar sudut melengkung terlihat
          body: Container(
            decoration: BoxDecoration(
              color: colors.pageBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: StreamBuilder<(int?, bool)>(
              stream: _stateStream,
              builder: (context, snap) {
                final currentIndex = snap.data?.$1;
                final shuffleOn = snap.data?.$2 ?? false;
                return _buildList(colors, currentIndex, shuffleOn);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTop(LyraColors colors, bool shuffleOn) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: colors.textSecondary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        _buildHeader(colors),
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
      ],
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
      return ListView(
        controller: widget.scrollController,
        children: [
          _buildTop(colors, shuffleOn),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                'Antrean kosong',
                style: TextStyle(color: colors.textSecondary, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }

    final keys = _buildKeys();

    return ReorderableListView.builder(
      scrollController: widget.scrollController,
      header: _buildTop(colors, shuffleOn),
      itemExtent: 70,
      buildDefaultDragHandles: false,
      padding: EdgeInsets.only(
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
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
      // key: key,` dihapus dari sini
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
              mainAxisAlignment: MainAxisAlignment.center,
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

    // Selalu kembalikan Dismissible, atur direction berdasarkan isCurrent
    return Dismissible(
      key: key,
      direction: isCurrent
          ? DismissDirection.none
          : DismissDirection.horizontal,
      onDismissed: (_) => _remove(item), // <-- Mengirim item, bukan index
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
