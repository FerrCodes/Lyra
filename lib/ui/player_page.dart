import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../main.dart';
import '../audio/lyra_audio_handler.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    const pageColor = Color(0xFFF2F2F7);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: pageColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: pageColor,
        body: StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, mediaSnapshot) {
            final item = mediaSnapshot.data;

            if (item == null) {
              return const Center(child: Text('Tidak ada lagu yang diputar'));
            }

            final albumId =
                int.tryParse(item.extras?['albumId']?.toString() ?? '') ?? 0;

            return SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // 1. CUSTOM TOP BAR (Ala Spotify)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Panah Bawah
                        IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 36,
                            color: Colors.black87,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),

                        // Teks Tengah: Playing From
                        // Teks Tengah: Playing From
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Playing from ${item.extras?['sourceType'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                item.extras?['sourceName'] ?? 'Unknown',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Titik Tiga
                        IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.black87,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ALBUM ART
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width * 0.75,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: QueryArtworkWidget(
                          id: albumId,
                          type: ArtworkType.ALBUM,
                          size: 800,
                          artworkBorder: BorderRadius.circular(24),
                          nullArtworkWidget: Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.music_note,
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // JUDUL, ARTIS & TOMBOL AKSI (Layout Metrolist)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.artist ?? 'Unknown Artist',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Tombol Add to Queue
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.add_to_queue,
                              color: Colors.black87,
                              size: 20,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Tombol Favorite
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.favorite_border,
                              color: Colors.black87,
                              size: 20,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // WAVY SEEK BAR & WAKTU
                  StreamBuilder<PlaybackState>(
                    stream: audioHandler.playbackState,
                    builder: (context, stateSnapshot) {
                      final state = stateSnapshot.data;
                      final position = state?.updatePosition ?? Duration.zero;
                      final duration = item.duration ?? Duration.zero;

                      final double progress = duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            WavySeekBar(
                              progress: progress,
                              onSeek: (newProgress) {
                                final newMillis =
                                    (newProgress * duration.inMilliseconds)
                                        .toInt();
                                audioHandler.seek(
                                  Duration(milliseconds: newMillis),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // TOMBOL KONTROL UTAMA (Gaya Metrolist)
                  StreamBuilder<PlaybackState>(
                    stream: audioHandler.playbackState,
                    builder: (context, stateSnapshot) {
                      final playing = stateSnapshot.data?.playing ?? false;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Tombol Previous
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                iconSize: 24,
                                padding: const EdgeInsets.all(12),
                                icon: const Icon(
                                  Icons.skip_previous,
                                  color: Colors.black87,
                                ),
                                onPressed: () =>
                                    (audioHandler as LyraAudioHandler)
                                        .skipToPrevious(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Tombol Play/Pause (Kapsul)
                            Expanded(
                              child: InkWell(
                                onTap: playing
                                    ? audioHandler.pause
                                    : audioHandler.play,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFD1D6F4,
                                    ), // Warna pastel kebiruan
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.black87,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        playing ? 'Pause' : 'Play',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Tombol Next
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                iconSize: 24,
                                padding: const EdgeInsets.all(12),
                                icon: const Icon(
                                  Icons.skip_next,
                                  color: Colors.black87,
                                ),
                                onPressed: () =>
                                    (audioHandler as LyraAudioHandler)
                                        .skipToNext(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // MENU IKON BAWAH (Speed, Timer, dll)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBottomIcon(Icons.speed),
                        _buildBottomIcon(Icons.timer_outlined),
                        _buildBottomIcon(Icons.shuffle),
                        _buildBottomIcon(Icons.equalizer),
                        _buildBottomIcon(Icons.repeat),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black87, size: 20),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// ==========================================
// CUSTOM WIDGET: WAVY SEEK BAR (GELOMBANG)
// ==========================================
class WavySeekBar extends StatelessWidget {
  final double progress;
  final ValueChanged<double> onSeek;

  const WavySeekBar({super.key, required this.progress, required this.onSeek});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) =>
              _handleSeek(details.localPosition.dx, constraints.maxWidth),
          onHorizontalDragUpdate: (details) =>
              _handleSeek(details.localPosition.dx, constraints.maxWidth),
          child: CustomPaint(
            size: Size(constraints.maxWidth, 40),
            painter: _WavyPainter(progress: progress),
          ),
        );
      },
    );
  }

  void _handleSeek(double dx, double width) {
    double newProgress = (dx / width).clamp(0.0, 1.0);
    onSeek(newProgress);
  }
}

class _WavyPainter extends CustomPainter {
  final double progress;
  _WavyPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paintInactive = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintActive = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final pathInactive = Path();
    final pathActive = Path();

    final waveHeight = 6.0;
    final waveLength = 20.0;
    final centerY = size.height / 2;

    // Titik tengah untuk thumb
    double thumbX = size.width * progress;
    double thumbY = centerY;

    for (double x = 0; x <= size.width; x++) {
      double y =
          centerY + math.sin((x / waveLength) * 2 * math.pi) * waveHeight;

      if (x == 0) {
        pathInactive.moveTo(x, y);
        pathActive.moveTo(x, y);
      } else {
        pathInactive.lineTo(x, y);
        if (x <= thumbX) {
          pathActive.lineTo(x, y);
          thumbY = y; // Simpan posisi Y terakhir untuk thumb
        }
      }
    }

    canvas.drawPath(pathInactive, paintInactive);
    canvas.drawPath(pathActive, paintActive);

    // Gambar titik (thumb) di ujung gelombang yang aktif
    final paintThumb = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(thumbX, thumbY), 7.0, paintThumb);

    // Cincin putih di tengah thumb agar terlihat menonjol
    final paintThumbInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(thumbX, thumbY), 2.5, paintThumbInner);
  }

  @override
  bool shouldRepaint(covariant _WavyPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
