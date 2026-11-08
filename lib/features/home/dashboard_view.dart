import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database.dart';
import '../../providers/database_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/lyra_colors.dart';

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
        const SizedBox(height: 32),

        // PLAYLIST KAMU
        StreamBuilder<List<Playlist>>(
          // error handling pada stream
          stream:
              (db.select(db.playlists)..orderBy([
                    (t) => drift.OrderingTerm(expression: t.sortOrder),
                  ]))
                  .watch(),
          builder: (context, snapshot) {
            // Jika database error
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Gagal memuat playlist.',
                  style: TextStyle(color: colors.textSecondary),
                ),
              );
            }

            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final playlists = snapshot.data ?? [];
            if (playlists.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Playlist Kamu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final hasImage =
                          playlist.imagePath != null &&
                          playlist.imagePath!.isNotEmpty;

                      // Bungkus dengan TweenAnimationBuilder untuk animasi Fade-in
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                          milliseconds: 300 + (index * 100),
                        ), // Staggered animasi
                        curve: Curves.easeOut,
                        builder: (context, opacity, child) {
                          return Opacity(
                            opacity: opacity,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                20 * (1 - opacity),
                              ), // Efek naik dari bawah
                              child: child,
                            ),
                          );
                        },
                        child: GestureDetector(
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
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: hasImage
                                        ? null
                                        : LinearGradient(
                                            colors: [
                                              colors.accent.withValues(
                                                alpha: 0.5,
                                              ),
                                              colors.accent,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: hasImage
                                        ? Image.file(
                                            File(playlist.imagePath!),
                                            fit: BoxFit.cover,
                                            // Error builder untuk gambar
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Center(
                                                      child: Icon(
                                                        Icons.queue_music,
                                                        size: 40,
                                                        color: colors
                                                            .pageBackground,
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
                                const SizedBox(height: 8),
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
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
