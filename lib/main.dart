import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'audio/lyra_audio_handler.dart';
import 'ui/home_page.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

late final AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await Permission.audio.request();
    // Untuk Android 12 ke bawah, biasanya butuh storage
    await Permission.storage.request();
  }

  audioHandler = await AudioService.init(
    builder: () => LyraAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.ferrriiidev.lyra',
      androidNotificationChannelName: 'Lyra Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(const ProviderScope(child: LyraApp()));
}

class LyraApp extends StatelessWidget {
  const LyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyra',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
