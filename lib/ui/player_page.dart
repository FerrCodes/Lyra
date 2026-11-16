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
import 'queue_page.dart';
import '../audio/lyra_audio_handler.dart';
import '../widgets/song_artwork.dart';

class PlayerPage extends StatefulWidget {
  final VoidCallback? onClose;
  final Animation<double>? panelAnimation;

  const PlayerPage({super.key, this.onClose, this.panelAnimation});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  static final Map<int, Color> _colorCache = {};
  Color? _dynamicColor;
  int? _lastAlbumId;

  late final Stream<MediaItem?> _distinctMediaItemStream = audioHandler
      .mediaItem
      .distinct((a, b) => a?.id == b?.id);

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
          stream: _distinctMediaItemStream,
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
                      onPressed: widget.onClose ?? () => Navigator.pop(context),
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
            final songId =
                int.tryParse(item.extras?['songId']?.toString() ?? '') ?? 0;

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
                            ],
                          ),
                        ),

                        const SizedBox(height: 17),

                        // ALBUM ART (Dengan Parallax Scale)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: StreamBuilder<PlaybackState>(
                            stream: audioHandler.playbackState,
                            builder: (context, stateSnapshot) {
                              final playing =
                                  stateSnapshot.data?.playing ?? false;
                              final baseScale = playing ? 1.04 : 0.89;

                              // Jika ada animasi panel, bungkus dengan AnimatedBuilder
                              if (widget.panelAnimation != null) {
                                return AnimatedBuilder(
                                  animation: widget.panelAnimation!,
                                  builder: (context, child) {
                                    // Nilai 0.0 (tertutup) = skala 0.7
                                    // Nilai 1.0 (terbuka) = skala 1.0
                                    final dragScale =
                                        0.7 +
                                        (0.3 * widget.panelAnimation!.value);

                                    return Transform.scale(
                                      scale: baseScale * dragScale,
                                      child: child,
                                    );
                                  },
                                  child: _buildAlbumArt(
                                    context,
                                    colors,
                                    isDark,
                                    albumId,
                                    songId,
                                  ),
                                );
                              }

                              // Fallback jika dibuka lewat PlayerRoute (bukan panel)
                              return AnimatedScale(
                                scale: baseScale,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                child: _buildAlbumArt(
                                  context,
                                  colors,
                                  isDark,
                                  albumId,
                                  songId,
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
                            final duration =
                                audioHandler.mediaItem.value?.duration ??
                                Duration.zero;

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
                                        duration: duration,
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
                                    onTap: () => audioHandler.skipToPrevious(),
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
                        StreamBuilder<PlaybackState>(
                          stream: audioHandler.playbackState,
                          builder: (context, snapshot) {
                            final state = snapshot.data;
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
                                  PressableScale(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) {
                                          return DraggableScrollableSheet(
                                            initialChildSize: 0.5,
                                            minChildSize: 0.3,
                                            maxChildSize: 0.95,
                                            snap: true,
                                            expand: false,
                                            builder:
                                                (context, scrollController) {
                                                  return QueuePage(
                                                    scrollController:
                                                        scrollController,
                                                  );
                                                },
                                          );
                                        },
                                      );
                                    },
                                    child: GlassContainer(
                                      width: 44,
                                      height: 44,
                                      radius: 14,
                                      child: Icon(
                                        Icons.queue_music_rounded,
                                        color: colors.textPrimary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // --- TOMBOL SLEEP TIMER (DENGAN INDIKATOR WAKTU) ---
                                  PressableScale(
                                    onTap: () => _showSleepTimerSheet(context),
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable:
                                          (audioHandler as LyraAudioHandler)
                                              .sleepTimerActiveNotifier,
                                      builder: (context, isActive, _) {
                                        return ValueListenableBuilder<Duration>(
                                          valueListenable:
                                              (audioHandler as LyraAudioHandler)
                                                  .sleepTimerRemainingNotifier,
                                          builder: (context, remaining, _) {
                                            // Format sisa waktu (misal: 29:45 atau 01:15:00)
                                            String timeText = '';
                                            if (isActive) {
                                              final h = remaining.inHours;
                                              final m = remaining.inMinutes
                                                  .remainder(60)
                                                  .toString()
                                                  .padLeft(2, '0');
                                              final s = remaining.inSeconds
                                                  .remainder(60)
                                                  .toString()
                                                  .padLeft(2, '0');
                                              if (h > 0) {
                                                timeText = '$h:$m:$s';
                                              } else {
                                                timeText = '$m:$s';
                                              }
                                            }
                                            return Tooltip(
                                              message: isActive
                                                  ? 'Sisa waktu: $timeText'
                                                  : 'Sleep timer',
                                              child: GlassContainer(
                                                width: 44,
                                                height: 44,
                                                radius: 14,
                                                // Beri sedikit padding horizontal jika ada teks
                                                child: Center(
                                                  child: isActive
                                                      ? Text(
                                                          timeText,
                                                          style: TextStyle(
                                                            color: accentColor,
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons
                                                              .bedtime_outlined,
                                                          color: colors
                                                              .textPrimary,
                                                          size: 20,
                                                        ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
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
                                  const SizedBox(width: 12),
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
                                  const Spacer(),
                                  PressableScale(
                                    onTap: () =>
                                        _showMoreControlsSheet(context),
                                    child: GlassContainer(
                                      width: 44,
                                      height: 44,
                                      radius: 14,
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: colors.textPrimary,
                                        size: 24,
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

  Widget _buildAlbumArt(
    BuildContext context,
    LyraColors colors,
    bool isDark,
    int albumId,
    int songId,
  ) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        width: double.infinity,
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
        child: songId == 0
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: QueryArtworkWidget(
                  id: albumId,
                  type: ArtworkType.ALBUM,
                  size: 800,
                  artworkFit: BoxFit.cover,
                  artworkBorder: BorderRadius.circular(24),
                  nullArtworkWidget: Container(
                    color: colors.textSecondary.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.music_note,
                      size: 100,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              )
            : SongArtwork(
                id: songId,
                size: double.infinity,
                radius: 24,
                loadSize: 800,
                placeholder: Container(
                  color: colors.textSecondary.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.music_note,
                    size: 100,
                    color: colors.textPrimary,
                  ),
                ),
              ),
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context) {
    final colors = context.lyra;
    final handler = audioHandler as LyraAudioHandler;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // Gunakan ValueListenableBuilder agar centang (radio) ikut berubah secara real-time
        return ValueListenableBuilder<bool>(
          valueListenable: handler.sleepTimerActiveNotifier,
          builder: (context, isActive, child) {
            return ValueListenableBuilder<Duration>(
              valueListenable: handler.sleepTimerRemainingNotifier,
              builder: (context, remaining, child) {
                // Fungsi untuk mengecek apakah opsi ini yang sedang aktif
                bool isSelected(Duration target) {
                  if (!isActive) return false;
                  // Beri toleransi beberapa detik karena timer berjalan mundur
                  return (remaining.inSeconds - target.inSeconds).abs() <= 5;
                }

                return SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.textSecondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sleep timer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Opsi OFF
                        _buildRadioTimerOption(
                          context,
                          'Off',
                          !isActive, // Terpilih jika timer mati
                          () {
                            handler.cancelSleepTimer();
                            Navigator.pop(context);
                          },
                          colors,
                        ),

                        // Opsi 30 Menit
                        _buildRadioTimerOption(
                          context,
                          '30 minutes',
                          isSelected(const Duration(minutes: 30)),
                          () {
                            handler.startSleepTimer(
                              const Duration(minutes: 30),
                            );
                            Navigator.pop(context);
                          },
                          colors,
                        ),

                        // Opsi 1 Jam
                        _buildRadioTimerOption(
                          context,
                          '1 hour',
                          isSelected(const Duration(hours: 1)),
                          () {
                            handler.startSleepTimer(const Duration(hours: 1));
                            Navigator.pop(context);
                          },
                          colors,
                        ),

                        // Opsi 1 Jam 30 Menit
                        _buildRadioTimerOption(
                          context,
                          '1 hour 30 minutes',
                          isSelected(const Duration(hours: 1, minutes: 30)),
                          () {
                            handler.startSleepTimer(
                              const Duration(hours: 1, minutes: 30),
                            );
                            Navigator.pop(context);
                          },
                          colors,
                        ),

                        // Opsi 2 Jam
                        _buildRadioTimerOption(
                          context,
                          '2 hours',
                          isSelected(const Duration(hours: 2)),
                          () {
                            handler.startSleepTimer(const Duration(hours: 2));
                            Navigator.pop(context);
                          },
                          colors,
                        ),

                        // Opsi CUSTOM
                        _buildRadioTimerOption(
                          context,
                          'Custom',
                          isActive &&
                              !isSelected(const Duration(minutes: 30)) &&
                              !isSelected(const Duration(hours: 1)) &&
                              !isSelected(
                                const Duration(hours: 1, minutes: 30),
                              ) &&
                              !isSelected(const Duration(hours: 2)),
                          () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                              builder: (context, child) {
                                final isDark =
                                    Theme.of(context).brightness ==
                                    Brightness.dark;
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: isDark
                                        ? ColorScheme.dark(
                                            primary: colors.accent,
                                            onPrimary: Colors.white,
                                            surface: colors.pageBackground,
                                            onSurface: colors.textPrimary,
                                          )
                                        : ColorScheme.light(
                                            primary: colors.accent,
                                            onPrimary: Colors.white,
                                            surface: colors.pageBackground,
                                            onSurface: colors.textPrimary,
                                          ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              final now = TimeOfDay.now();
                              final difference = Duration(
                                hours: time.hour - now.hour,
                                minutes: time.minute - now.minute,
                              );
                              if (difference == Duration.zero) {
                                handler.startSleepTimer(
                                  const Duration(days: 1),
                                );
                              } else if (difference.isNegative) {
                                handler.startSleepTimer(
                                  difference + const Duration(days: 1),
                                );
                              } else {
                                handler.startSleepTimer(difference);
                              }
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          colors,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRadioTimerOption(
    BuildContext context,
    String title,
    bool isSelected,
    VoidCallback onTap,
    LyraColors colors,
  ) {
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? colors.accent : colors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? colors.accent : colors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showMoreControlsSheet(BuildContext context) {
    final colors = context.lyra;
    final handler = audioHandler as LyraAudioHandler;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Agar sudut melengkung terlihat
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4, // Muncul 40% layar di awal
          minChildSize: 0.2,
          maxChildSize: 0.9, // Bisa ditarik sampai 90% layar
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colors.pageBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Volume Aplikasi',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),

                  // --- FITUR VOLUME ---
                  StreamBuilder<double>(
                    stream: handler.volumeStream,
                    builder: (context, snapshot) {
                      final currentVolume = snapshot.data ?? 1.0;
                      return Row(
                        children: [
                          Icon(
                            currentVolume == 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_down_rounded,
                            color: colors.textSecondary,
                          ),
                          Expanded(
                            child: Slider(
                              value: currentVolume,
                              activeColor: colors.accent,
                              inactiveColor: colors.textSecondary.withValues(
                                alpha: 0.2,
                              ),
                              onChanged: (value) {
                                handler.setVolume(value);
                              },
                            ),
                          ),
                          Icon(
                            Icons.volume_up_rounded,
                            color: colors.textSecondary,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  Divider(color: colors.textSecondary.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),

                  Text(
                    'Kecepatan',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<double>(
                    stream: handler.speedStream,
                    initialData: handler.speed,
                    builder: (context, snapshot) {
                      final currentSpeed = snapshot.data ?? 1.0;
                      return Wrap(
                        spacing: 8,
                        children: [0.75, 1.0, 1.25, 1.5].map((speed) {
                          final isActive = (currentSpeed - speed).abs() < 0.01;
                          return GestureDetector(
                            onTap: () => handler.setSpeed(speed),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? colors.accent.withValues(alpha: 0.15)
                                    : colors.textPrimary.withValues(
                                        alpha: 0.06,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${speed}x',
                                style: TextStyle(
                                  color: isActive
                                      ? colors.accent
                                      : colors.textPrimary,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
