import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio/lyra_audio_handler.dart';
import 'ui/permission_gate.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/profile_provider.dart';

late final AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadProfileData();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Background status bar transparan
      statusBarIconBrightness:
          Brightness.dark, // Ikon jadi hitam (untuk background terang)
      statusBarBrightness: Brightness.light, // Untuk iOS
      systemNavigationBarIconBrightness:
          Brightness.dark, // Ikon navigasi bawah hitam
    ),
  );

  if (Platform.isAndroid) {
    // Minta izin audio (berlaku untuk Android 13+)
    await Permission.audio.request();
    // Minta izin storage (untuk Android 12 ke bawah / fallback)
    // Di Android 13+, ini akan otomatis diabaikan (denied) oleh sistem,
    // tapi tidak akan membuat aplikasi crash.
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PermissionGate(),
    );
  }
}
