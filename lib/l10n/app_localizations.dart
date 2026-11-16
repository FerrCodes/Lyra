import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get theme;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @audioPlayback.
  ///
  /// In en, this message translates to:
  /// **'Audio & Playback'**
  String get audioPlayback;

  /// No description provided for @systemEqualizer.
  ///
  /// In en, this message translates to:
  /// **'System Equalizer'**
  String get systemEqualizer;

  /// No description provided for @openSystemEqualizer.
  ///
  /// In en, this message translates to:
  /// **'Open device audio settings'**
  String get openSystemEqualizer;

  /// No description provided for @deviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Device Settings'**
  String get deviceSettings;

  /// No description provided for @lyraNotification.
  ///
  /// In en, this message translates to:
  /// **'Lyra Notifications'**
  String get lyraNotification;

  /// No description provided for @lyraNotificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage how Lyra sends notifications'**
  String get lyraNotificationDesc;

  /// No description provided for @appPermissions.
  ///
  /// In en, this message translates to:
  /// **'App Permissions'**
  String get appPermissions;

  /// No description provided for @appPermissionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage file and media access'**
  String get appPermissionsDesc;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery & Background'**
  String get battery;

  /// No description provided for @batteryDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow Lyra to run when screen is off'**
  String get batteryDesc;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @storageUsage.
  ///
  /// In en, this message translates to:
  /// **'Storage Usage'**
  String get storageUsage;

  /// No description provided for @cacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache size: {size}'**
  String cacheSize(String size);

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'Delete temporary images and song cache'**
  String get clearCacheDesc;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get cacheCleared;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get indonesian;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get goodNight;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'Good {time}, {name}'**
  String greetingWithName(String time, String name);

  /// No description provided for @greetingWithoutName.
  ///
  /// In en, this message translates to:
  /// **'Good {time},'**
  String greetingWithoutName(String time);

  /// No description provided for @readyToListen.
  ///
  /// In en, this message translates to:
  /// **'Ready to listen to something today?'**
  String get readyToListen;

  /// No description provided for @noSongsFound.
  ///
  /// In en, this message translates to:
  /// **'No Songs Found'**
  String get noSongsFound;

  /// No description provided for @noSongsDesc.
  ///
  /// In en, this message translates to:
  /// **'Could not find music files. Make sure you have granted storage access permission.'**
  String get noSongsDesc;

  /// No description provided for @rescanSongs.
  ///
  /// In en, this message translates to:
  /// **'Rescan Songs'**
  String get rescanSongs;

  /// No description provided for @favoritePlaylists.
  ///
  /// In en, this message translates to:
  /// **'Favorite Playlists'**
  String get favoritePlaylists;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @mostPlayed.
  ///
  /// In en, this message translates to:
  /// **'Most Played'**
  String get mostPlayed;

  /// No description provided for @listenAgain.
  ///
  /// In en, this message translates to:
  /// **'Listen Again'**
  String get listenAgain;

  /// No description provided for @exploreMusicDesc.
  ///
  /// In en, this message translates to:
  /// **'Play a song from the Songs tab, create your first Playlist, or add songs to Favorites. All activity will appear here.'**
  String get exploreMusicDesc;

  /// No description provided for @copyrightText.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Lyra. All rights reserved.'**
  String get copyrightText;

  /// No description provided for @playCount.
  ///
  /// In en, this message translates to:
  /// **'{count}x played'**
  String playCount(int count);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get navSongs;

  /// No description provided for @navPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get navPlaylist;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Artists, Songs, Lyrics, and More'**
  String get searchHint;

  /// No description provided for @selectSong.
  ///
  /// In en, this message translates to:
  /// **'Select a song'**
  String get selectSong;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownArtist;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'id': return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
