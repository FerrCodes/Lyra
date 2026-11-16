// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get settings => 'Pengaturan';

  @override
  String get display => 'Tampilan';

  @override
  String get theme => 'Tema Aplikasi';

  @override
  String get systemDefault => 'Ikuti Sistem';

  @override
  String get light => 'Terang';

  @override
  String get dark => 'Gelap';

  @override
  String get audioPlayback => 'Audio & Pemutaran';

  @override
  String get systemEqualizer => 'Equalizer Sistem';

  @override
  String get openSystemEqualizer => 'Buka pengaturan suara bawaan HP';

  @override
  String get deviceSettings => 'Pengaturan Perangkat';

  @override
  String get lyraNotification => 'Notifikasi Lyra';

  @override
  String get lyraNotificationDesc => 'Atur cara Lyra mengirim notifikasi';

  @override
  String get appPermissions => 'Izin Aplikasi';

  @override
  String get appPermissionsDesc => 'Kelola akses file dan media';

  @override
  String get battery => 'Baterai & Latar Belakang';

  @override
  String get batteryDesc => 'Izinkan Lyra berjalan saat layar mati';

  @override
  String get storage => 'Penyimpanan';

  @override
  String get storageUsage => 'Penggunaan Penyimpanan';

  @override
  String cacheSize(String size) {
    return 'Ukuran cache: $size';
  }

  @override
  String get clearCache => 'Hapus Cache';

  @override
  String get clearCacheDesc => 'Hapus gambar sementara dan cache lagu';

  @override
  String get cacheCleared => 'Cache berhasil dibersihkan';

  @override
  String get others => 'Lainnya';

  @override
  String get appVersion => 'Versi Aplikasi';

  @override
  String get language => 'Bahasa';

  @override
  String get english => 'English';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get repeat => 'Repeat';

  @override
  String get goodMorning => 'Pagi';

  @override
  String get goodAfternoon => 'Siang';

  @override
  String get goodEvening => 'Sore';

  @override
  String get goodNight => 'Malam';

  @override
  String greetingWithName(String time, String name) {
    return 'Selamat $time, $name';
  }

  @override
  String greetingWithoutName(String time) {
    return 'Selamat $time,';
  }

  @override
  String get readyToListen => 'Siap mendengarkan sesuatu hari ini?';

  @override
  String get noSongsFound => 'Belum Ada Lagu';

  @override
  String get noSongsDesc => 'Tidak dapat menemukan file musik. Pastikan sudah memberikan izin akses penyimpanan.';

  @override
  String get rescanSongs => 'Pindai Ulang Lagu';

  @override
  String get favoritePlaylists => 'Playlist Favorit';

  @override
  String get playlists => 'Playlist';

  @override
  String get favorites => 'Favorit';

  @override
  String get mostPlayed => 'Sering Diputar';

  @override
  String get listenAgain => 'Dengarkan Lagi';

  @override
  String get exploreMusicDesc => 'Putar lagu dari tab Songs, buat Playlist pertama, atau tambahkan lagu ke Favorit. Aktivitas semua akan muncul di sini.';

  @override
  String get copyrightText => '© 2026 Lyra. All rights reserved.';

  @override
  String playCount(int count) {
    return '${count}x diputar';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navSongs => 'Songs';

  @override
  String get navPlaylist => 'Playlist';

  @override
  String get navLibrary => 'Library';

  @override
  String get searchHint => 'Artists, Songs, Lyrics, and More';

  @override
  String get selectSong => 'Pilih lagu';

  @override
  String get unknownArtist => 'Unknown';
}
