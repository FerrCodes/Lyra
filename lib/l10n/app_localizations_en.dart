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

  @override
  String get goodMorning => 'Morning';

  @override
  String get goodAfternoon => 'Afternoon';

  @override
  String get goodEvening => 'Evening';

  @override
  String get goodNight => 'Night';

  @override
  String greetingWithName(String time, String name) {
    return 'Good $time, $name';
  }

  @override
  String greetingWithoutName(String time) {
    return 'Good $time,';
  }

  @override
  String get readyToListen => 'Ready to listen to something today?';

  @override
  String get noSongsFound => 'No Songs Found';

  @override
  String get noSongsDesc => 'Could not find music files. Make sure you have granted storage access permission.';

  @override
  String get rescanSongs => 'Rescan Songs';

  @override
  String get favoritePlaylists => 'Favorite Playlists';

  @override
  String get playlists => 'Playlists';

  @override
  String get favorites => 'Favorites';

  @override
  String get mostPlayed => 'Most Played';

  @override
  String get listenAgain => 'Listen Again';

  @override
  String get exploreMusicDesc => 'Play a song from the Songs tab, create your first Playlist, or add songs to Favorites. All activity will appear here.';

  @override
  String get copyrightText => '© 2026 Lyra. All rights reserved.';

  @override
  String playCount(int count) {
    return '${count}x played';
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
  String get selectSong => 'Select a song';

  @override
  String get unknownArtist => 'Unknown';
}
