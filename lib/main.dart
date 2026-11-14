import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'audio/lyra_audio_handler.dart';
import 'ui/permission_gate.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/profile_provider.dart';
import 'theme/lyra_colors.dart';
import 'providers/theme_provider.dart';

late final AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadProfileData();
  await initializeDateFormatting('id_ID', null);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Background status bar
      statusBarIconBrightness:
          Brightness.dark, // Ikon jadi hitam (untuk background terang)
      statusBarBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.dark, // Ikon navigasi bawah
    ),
  );

  if (Platform.isAndroid) {
    await Permission.audio.request();
    await Permission.storage.request();

    if (await Permission.photos.isDenied) {
      await Permission.photos.request();
    }
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

class LyraApp extends ConsumerWidget {
  const LyraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Lyra',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        extensions: const [LyraColors.light],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        extensions: const [LyraColors.dark],
      ),
      home: const PermissionGate(),
    );
  }
}
