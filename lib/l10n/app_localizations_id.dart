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
}
