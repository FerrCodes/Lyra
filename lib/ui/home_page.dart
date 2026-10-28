import 'dart:io';
import '../main.dart';
import 'package:audio_service/audio_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../audio/lyra_audio_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _loadedFileName;
  bool _busy = false;

  LyraAudioHandler? get _handler {
    final h = audioHandler;
    return h is LyraAudioHandler ? h : null;
  }

  Future<void> _pickAndPlay() async {
    final handler = _handler;
    if (handler == null) return;

    setState(() => _busy = true);
    try {
      // Di file_picker v13, langsung panggil pickFiles() dan hasilnya sudah berupa List
      final result = await FilePicker.pickFiles(type: FileType.audio);

      // result sekarang bertipe List<PlatformFile>? bukan lagi FilePickerResult?
      if (result == null || result.isEmpty) return;

      // Ambil file pertama langsung tanpa .files
      final path = result.first.path;
      if (path == null) return;

      await handler.loadFile(path);
      await handler.play();

      if (mounted) {
        setState(() => _loadedFileName = path.split('/').last);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat audio: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lyra')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              _loadedFileName == null
                  ? 'Belum ada lagu dimuat'
                  : 'Sedang diputar:\n$_loadedFileName',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _pickAndPlay,
              icon: const Icon(Icons.library_music),
              label: Text(_busy ? 'Memuat...' : 'Pilih & Putar Audio'),
            ),
            const SizedBox(height: 16),
            // Kontrol playback berbasiskan state audio_service.
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                final state = snapshot.data;
                final playing = state?.playing ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      iconSize: 48,
                      onPressed: playing
                          ? audioHandler.pause
                          : audioHandler.play,
                      icon: Icon(
                        playing ? Icons.pause_circle : Icons.play_circle,
                      ),
                    ),
                    IconButton(
                      iconSize: 48,
                      onPressed: audioHandler.stop,
                      icon: const Icon(Icons.stop_circle),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final item = snapshot.data;
                if (item == null) return const SizedBox.shrink();
                return Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
            const Spacer(),
            const Text(
              'Uji: putar lagu, tekan Home, lalu hapus Lyra dari Recent Apps. '
              'Lagu harus tetap berjalan dan notifikasi media tetap muncul.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Platform: ${Platform.operatingSystem}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
