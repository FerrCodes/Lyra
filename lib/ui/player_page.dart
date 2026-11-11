import '../main.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../widgets/wavy_seek_bar.dart';
import '../theme/lyra_colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/lyra_bottom_bar.dart';
import '../widgets/marquee_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/songs_provider.dart';
import '../database/database.dart';
import '../models/song.dart' as local;
import '../widgets/media_icons.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  static final Map<int, Color> _colorCache = {};
  Color? _dynamicColor;
  int? _lastAlbumId;

  Future<Color> _getDynamicColor(int albumId, Color fallback) async {
    if (_colorCache.containsKey(albumId)) return _colorCache[albumId]!;

    try {
      final artwork = await OnAudioQuery().queryArtwork(
        albumId,
        ArtworkType.ALBUM,
        size: 400,
        format: ArtworkFormat.JPEG,
      );
      if (artwork != null) {
        final scheme = await ColorScheme.fromImageProvider(
          provider: MemoryImage(artwork),
        );
        final color = scheme.primary;
        _colorCache[albumId] = color;
        return color;
      }
    } catch (_) {}

    _colorCache[albumId] = fallback;
    return fallback;
  }

  // Penyesuaian kontras untuk tema terang
  Color _getContrastColor(Color color, bool isDark) {
    if (isDark) return color;
    final hsl = HSLColor.fromColor(color);
    if (hsl.lightness > 0.45) {
      return hsl.withLightness(0.45).toColor();
    }
    return color;
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
      child: Scaffold(
        backgroundColor: colors.pageBackground,
        body: StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, mediaSnapshot) {
            final item = mediaSnapshot.data;

            if (item == null) {
              // Empty State dengan tombol kembali
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tidak ada lagu yang diputar',
                      style: TextStyle(fontSize: 16, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              );
            }

            final albumId =
                int.tryParse(item.extras?['albumId']?.toString() ?? '') ?? 0;

            // Memicu fetch warna jika albumId berubah
            if (albumId != _lastAlbumId) {
              _lastAlbumId = albumId;
              _getDynamicColor(albumId, colors.pageBackground).then((color) {
                if (mounted) setState(() => _dynamicColor = color);
              });
            }

            final baseColor = _dynamicColor ?? colors.pageBackground;
            final accentColor = _getContrastColor(baseColor, isDark);

            return TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: baseColor),
              duration: const Duration(milliseconds: 500),
              builder: (context, animatedColor, child) {
                final currentBaseColor = animatedColor ?? baseColor;

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        currentBaseColor.withValues(alpha: 0.3),
                        colors.pageBackground,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // CUSTOM TOP BAR
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 36,
                                  color: colors.textPrimary,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Playing from ${item.extras?['sourceType'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      item.extras?['sourceName'] ?? 'Unknown',
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: colors.textPrimary,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ALBUM ART (Dengan AnimatedScale)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: StreamBuilder<PlaybackState>(
                            stream: audioHandler.playbackState,
                            builder: (context, stateSnapshot) {
                              final playing =
                                  stateSnapshot.data?.playing ?? false;
                              return AnimatedScale(
                                scale: playing ? 1.0 : 0.9,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                child: Container(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.width * 0.75,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
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
                                        color: colors.textSecondary.withValues(
                                          alpha: 0.2,
                                        ),
                                        child: Icon(
                                          Icons.music_note,
                                          size: 100,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // JUDUL & ARTIS
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MarqueeText(
                                      text: item.title,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.artist ?? 'Unknown Artist',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Consumer(
                                builder: (context, ref, child) {
                                  // Cari data lagu di local storage/mediastore
                                  final allSongs =
                                      ref.watch(allSongsProvider).value ?? [];
                                  final localSong = allSongs.firstWhere(
                                    (s) => s.path == item.id,
                                    orElse: () => local.Song(
                                      id: '',
                                      title: '',
                                      artist: '',
                                      album: '',
                                      path: '',
                                      durationMs: 0,
                                      albumId: '',
                                    ),
                                  );

                                  // Ambil database
                                  final db = ref.read(databaseProvider);

                                  // Pantau tabel favorit
                                  return StreamBuilder<List<Song>>(
                                    stream: db.watchFavorites(),
                                    builder: (context, snapshot) {
                                      final isFav =
                                          snapshot.data?.any(
                                            (s) => s.path == item.id,
                                          ) ??
                                          false;

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: colors.textSecondary
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            isFav
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isFav
                                                ? colors.accent
                                                : colors.textPrimary,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            if (localSong.id.isEmpty) return;
                                            // Ubah ke model database Drift
                                            final dbSong = Song(
                                              id: localSong.id,
                                              title: localSong.title,
                                              artist: localSong.artist,
                                              album: localSong.album,
                                              path: localSong.path,
                                              durationMs: localSong.durationMs,
                                              addedAt: DateTime.now(),
                                            );

                                            // Simpan/Hapus dari database
                                            await db.toggleFavorite(dbSong);
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // WAVY SEEK BAR
                        StreamBuilder<Duration>(
                          stream: AudioService.position,
                          builder: (context, posSnapshot) {
                            final position = posSnapshot.data ?? Duration.zero;
                            final duration = item.duration ?? Duration.zero;

                            final double progress = duration.inMilliseconds > 0
                                ? position.inMilliseconds /
                                      duration.inMilliseconds
                                : 0.0;

                            return StreamBuilder<PlaybackState>(
                              stream: audioHandler.playbackState,
                              builder: (context, stateSnapshot) {
                                final playing =
                                    stateSnapshot.data?.playing ?? false;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Column(
                                    children: [
                                      WavySeekBar(
                                        progress: progress,
                                        isPlaying: playing,
                                        activeColor: accentColor,
                                        inactiveColor: colors.textSecondary
                                            .withValues(alpha: 0.2),
                                        thumbColor: accentColor,
                                        thumbInnerColor: colors.pageBackground,
                                        onSeek: (newProgress) {
                                          final newMillis =
                                              (newProgress *
                                                      duration.inMilliseconds)
                                                  .toInt();
                                          audioHandler.seek(
                                            Duration(milliseconds: newMillis),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(position),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            _formatDuration(duration),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: colors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // TOMBOL KONTROL UTAMA
                        StreamBuilder<PlaybackState>(
                          stream: audioHandler.playbackState,
                          builder: (context, stateSnapshot) {
                            final playing =
                                stateSnapshot.data?.playing ?? false;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  PressableScale(
                                    onTap: () {
                                      // Ambil posisi lagu saat ini
                                      final currentPos =
                                          stateSnapshot.data?.updatePosition ??
                                          Duration.zero;

                                      if (currentPos >
                                          const Duration(seconds: 10)) {
                                        // Jika sudah lewat 10 detik, ulangi lagu dari awal
                                        audioHandler.seek(Duration.zero);
                                      } else {
                                        // Jika masih di bawah 10 detik, pindah ke lagu sebelumnya
                                        audioHandler.skipToPrevious();
                                      }
                                    },
                                    child: GlassContainer(
                                      width: 48,
                                      height: 48,
                                      radius: 24,
                                      child: Icon(
                                        Icons.skip_previous_rounded,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: PressableScale(
                                      onTap: () {
                                        playing
                                            ? audioHandler.pause()
                                            : audioHandler.play();
                                      },
                                      child: Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(
                                            alpha: 0.18,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              playing
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              color: accentColor,
                                              size: 28,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              playing ? 'Pause' : 'Play',
                                              style: TextStyle(
                                                color: accentColor,
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
                                  PressableScale(
                                    onTap: () {
                                      audioHandler.skipToNext();
                                    },
                                    child: GlassContainer(
                                      width: 48,
                                      height: 48,
                                      radius: 24,
                                      child: Icon(
                                        Icons.skip_next_rounded,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // MENU IKON BAWAH (Shuffle & Repeat dengan Kaca)
                        // MENU IKON BAWAH (Shuffle & Repeat dengan Kaca)
                        StreamBuilder<PlaybackState>(
                          stream: audioHandler.playbackState,
                          builder: (context, snapshot) {
                            final state = snapshot.data;

                            // TAMBAHKAN KEMBALI 3 VARIABEL INI:
                            final isShuffleOn =
                                state?.shuffleMode ==
                                AudioServiceShuffleMode.all;
                            final repeatMode =
                                state?.repeatMode ??
                                AudioServiceRepeatMode.none;
                            final isRepeatOn =
                                repeatMode == AudioServiceRepeatMode.all ||
                                repeatMode == AudioServiceRepeatMode.one;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // --- TOMBOL SHUFFLE ---
                                  PressableScale(
                                    onTap: () {
                                      final nextMode = isShuffleOn
                                          ? AudioServiceShuffleMode.none
                                          : AudioServiceShuffleMode.all;
                                      audioHandler.setShuffleMode(nextMode);
                                    },
                                    child: GlassContainer(
                                      width: 44,
                                      height: 44,
                                      radius: 14,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: CustomShuffleIcon(
                                          isOn: isShuffleOn,
                                          color: isShuffleOn
                                              ? accentColor
                                              : colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // --- TOMBOL REPEAT ---
                                  PressableScale(
                                    onTap: () {
                                      AudioServiceRepeatMode nextMode =
                                          AudioServiceRepeatMode.all;
                                      if (repeatMode ==
                                          AudioServiceRepeatMode.all) {
                                        nextMode = AudioServiceRepeatMode.one;
                                      } else if (repeatMode ==
                                          AudioServiceRepeatMode.one) {
                                        nextMode = AudioServiceRepeatMode.none;
                                      }
                                      audioHandler.setRepeatMode(nextMode);
                                    },
                                    child: GlassContainer(
                                      width: 44,
                                      height: 44,
                                      radius: 14,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: CustomRepeatIcon(
                                          isAll:
                                              repeatMode ==
                                              AudioServiceRepeatMode.all,
                                          isOne:
                                              repeatMode ==
                                              AudioServiceRepeatMode.one,
                                          color: isRepeatOn
                                              ? accentColor
                                              : colors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
