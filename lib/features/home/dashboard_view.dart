import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../providers/database_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/lyra_colors.dart';
import '../../widgets/lyra_bottom_bar.dart';

class DashboardView extends ConsumerWidget {
  final ScrollController controller;
  final void Function(Playlist playlist) onOpenPlaylist;

  const DashboardView({
    super.key,
    required this.controller,
    required this.onOpenPlaylist,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = ref.watch(databaseProvider);

    return ListView(
      controller: controller,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 80,
        bottom: 160,
      ),
      children: [
        // 1. SAPAAN
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ValueListenableBuilder<String>(
            valueListenable: profileNameNotifier,
            builder: (context, name, child) {
              final isDefaultName = name == 'Pengguna Lyra';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDefaultName)
                    Text(
                      'Selamat ${_getGreeting()},',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    )
                  else ...[
                    Text(
                      'Selamat ${_getGreeting()},',
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Siap mendengarkan sesuatu hari ini?',
                    style: TextStyle(fontSize: 16, color: colors.textSecondary),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 28),
        StreamBuilder<List<Playlist>>(
          stream:
              (db.select(db.playlists)..orderBy([
                    (t) => drift.OrderingTerm(expression: t.sortOrder),
                  ]))
                  .watch(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Gagal memuat playlist.',
                  style: TextStyle(color: colors.textSecondary),
                ),
              );
            }

            // FadeTransition 250ms saat data pertama tiba
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildPlaylistList(snapshot.data ?? [], colors, isDark),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlaylistList(
    List<Playlist> playlists,
    LyraColors colors,
    bool isDark,
  ) {
    if (playlists.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const ValueKey('data'), // Key untuk AnimatedSwitcher
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Playlist Kamu',
            style: TextStyle(
              fontSize: 22, // Judul 22 bold
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              final hasImage =
                  playlist.imagePath != null && playlist.imagePath!.isNotEmpty;

              // Efek tekan skala 0.97 dengan PressableScale
              return PressableScale(
                onTap: () => onOpenPlaylist(playlist),
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: hasImage
                              ? null
                              : LinearGradient(
                                  colors: [
                                    colors.accent.withValues(alpha: 0.5),
                                    colors.accent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          // Bayangan sangat lembut (hanya di tema terang)
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: hasImage
                              ? Image.file(
                                  File(playlist.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Icon(
                                          Icons.queue_music,
                                          size: 40,
                                          color: colors.pageBackground,
                                        ),
                                      ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.queue_music,
                                    size: 40,
                                    color: colors.pageBackground,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
