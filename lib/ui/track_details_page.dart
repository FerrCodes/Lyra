import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/song.dart' as local;
import '../providers/songs_provider.dart';
import '../theme/lyra_colors.dart';
import '../widgets/lyra_header.dart';
import '../widgets/lyra_bottom_bar.dart';
import 'edit_metadata_sheet.dart';
import '../services/media_store_service.dart';

// 1. UBAH MENJADI ConsumerWidget
class TrackDetailsPage extends ConsumerWidget {
  final local.Song song;

  const TrackDetailsPage({super.key, required this.song});

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _getFileSize(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        final mb = bytes / (1024 * 1024);
        return '${mb.toStringAsFixed(2)} MB';
      }
    } catch (_) {}
    return 'Unknown';
  }

  String _getFormat(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'mp3') return 'audio/mpeg';
    if (ext == 'm4a') return 'audio/mp4';
    if (ext == 'flac') return 'audio/flac';
    if (ext == 'wav') return 'audio/wav';
    return 'audio/$ext';
  }

  @override
  // 2. TAMBAHKAN WidgetRef ref DI SINI
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 3. PANTAU DATA TERBARU DARI PROVIDER
    final allSongs = ref.watch(allSongsProvider).value ?? [];
    final currentSong = allSongs.firstWhere(
      (s) => s.path == song.path,
      orElse: () => song,
    );

    final albumIdInt = int.tryParse(currentSong.albumId) ?? 0;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 72,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    children: [
                      Text(
                        ' Track Details',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ALBUM ART DENGAN IKON EDIT
                      Stack(
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: QueryArtworkWidget(
                                id: albumIdInt,
                                type: ArtworkType.ALBUM,
                                size: 600,
                                artworkBorder: BorderRadius.circular(24),
                                nullArtworkWidget: Container(
                                  color: colors.textSecondary.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    size: 80,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () async {
                                try {
                                  // 1. Minta izin tulis ke Android
                                  final granted =
                                      await MediaStoreService.requestWritePermission(
                                        currentSong.id,
                                      );
                                  if (!granted) return;

                                  if (context.mounted) {
                                    // 2. Buka Galeri Samsung via Kotlin
                                    final String? imagePath =
                                        await MediaStoreService.pickImageFromGallery();

                                    // 3. Jika user memilih foto (tidak batal)
                                    if (imagePath != null && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Menyimpan cover...'),
                                        ),
                                      );

                                      // 4. Simpan ke file MP3
                                      await MediaStoreService.updateAlbumCover(
                                        id: currentSong.id,
                                        imagePath: imagePath,
                                      );

                                      // 5. Refresh UI
                                      await Future.delayed(
                                        const Duration(milliseconds: 500),
                                      );
                                      ref.invalidate(allSongsProvider);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Cover berhasil diperbarui!',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Gagal: $e')),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // JUDUL LAGU & ARTIS (GUNAKAN currentSong)
                      Text(
                        currentSong.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentSong.artist,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // KARTU INFORMASI (GUNAKAN currentSong)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(top: 32, bottom: 100),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Album', currentSong.album, colors),
                        _buildInfoRow('Genre', 'Unknown', colors),
                        _buildInfoRow(
                          'Track length',
                          _formatDuration(currentSong.durationMs),
                          colors,
                        ),
                        _buildInfoRow('Track number', '0', colors),
                        _buildInfoRow(
                          'Format',
                          _getFormat(currentSong.path),
                          colors,
                        ),
                        _buildInfoRow(
                          'Size',
                          _getFileSize(currentSong.path),
                          colors,
                        ),
                        _buildInfoRow(
                          'Path',
                          currentSong.path,
                          colors,
                          isPath: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // OVERLAY GRADASI TOP BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: MediaQuery.of(context).padding.top + 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.pageBackground.withValues(alpha: 0.9),
                      colors.pageBackground.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.8],
                  ),
                ),
              ),
            ),
          ),

          // TOP BAR MENGAMBANG
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TopBarButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    TopBarButton(
                      icon: Icons.edit_outlined,
                      onTap: () async {
                        try {
                          // Minta izin dulu sebelum buka UI
                          final granted =
                              await MediaStoreService.requestWritePermission(
                                currentSong.id,
                              );
                          if (granted && context.mounted) {
                            // Jika diizinkan, buka bottom sheet
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) =>
                                  EditMetadataSheet(song: currentSong),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    LyraColors colors, {
    bool isPath = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          PressableScale(
            onTap: () {},
            child: Text(
              value,
              style: TextStyle(
                fontSize: isPath ? 16 : 18,
                color: colors.textPrimary,
                fontWeight: isPath ? FontWeight.normal : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
