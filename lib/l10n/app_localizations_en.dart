// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get display => 'Display';

  @override
  String get theme => 'App Theme';

  @override
  String get systemDefault => 'System Default';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get audioPlayback => 'Audio & Playback';

  @override
  String get systemEqualizer => 'System Equalizer';

  @override
  String get openSystemEqualizer => 'Open device audio settings';

  @override
  String get deviceSettings => 'Device Settings';

  @override
  String get lyraNotification => 'Lyra Notifications';

  @override
  String get lyraNotificationDesc => 'Manage how Lyra sends notifications';

  @override
  String get appPermissions => 'App Permissions';

  @override
  String get appPermissionsDesc => 'Manage file and media access';

  @override
  String get battery => 'Battery & Background';

  @override
  String get batteryDesc => 'Allow Lyra to run when screen is off';

  @override
  String get storage => 'Storage';

  @override
  String get storageUsage => 'Storage Usage';

  @override
  String cacheSize(String size) {
    return 'Cache size: $size';
  }

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheDesc => 'Delete temporary images and song cache';

  @override
  String get cacheCleared => 'Cache cleared successfully';

  @override
  String get others => 'Others';

  @override
  String get appVersion => 'App Version';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get repeat => 'Repeat';
}
