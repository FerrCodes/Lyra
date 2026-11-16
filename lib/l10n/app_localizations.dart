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
  /// **'Play songs from the Songs tab, create the first Playlist, or add songs to Favorites. Activities will all appear here.'**
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

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @willPlayNext.
  ///
  /// In en, this message translates to:
  /// **'{title} will play next'**
  String willPlayNext(String title);

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to Queue'**
  String get addToQueue;

  /// No description provided for @addedToQueue.
  ///
  /// In en, this message translates to:
  /// **'{title} added to queue'**
  String addedToQueue(String title);

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @noPlaylistCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'No Playlists yet. Create one in the Playlist tab.'**
  String get noPlaylistCreateFirst;

  /// No description provided for @selectPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Select Playlist'**
  String get selectPlaylist;

  /// No description provided for @songAddedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'{song} added to {playlist}'**
  String songAddedToPlaylist(String song, String playlist);

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Music and Audio permission required.'**
  String get permissionRequired;

  /// No description provided for @permissionRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Requires permission to search all songs.'**
  String get permissionRequiredDesc;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @failedToLoadSongs.
  ///
  /// In en, this message translates to:
  /// **'Failed to load songs: {error}'**
  String failedToLoadSongs(String error);

  /// No description provided for @noSongsFoundList.
  ///
  /// In en, this message translates to:
  /// **'No songs found.'**
  String get noSongsFoundList;

  /// No description provided for @allSongs.
  ///
  /// In en, this message translates to:
  /// **'All Songs'**
  String get allSongs;

  /// No description provided for @createNewPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create New Playlist'**
  String get createNewPlaylist;

  /// No description provided for @playlistNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Playlist name cannot be empty'**
  String get playlistNameEmpty;

  /// No description provided for @failedToOpenGallery.
  ///
  /// In en, this message translates to:
  /// **'Failed to open gallery: {error}'**
  String failedToOpenGallery(String error);

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist Name'**
  String get playlistName;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylist;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @noPlaylistYet.
  ///
  /// In en, this message translates to:
  /// **'No Playlist Yet'**
  String get noPlaylistYet;

  /// No description provided for @createFirstPlaylistDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first playlist to\ngroup your favorite songs.'**
  String get createFirstPlaylistDesc;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by:'**
  String get sortBy;

  /// No description provided for @sortCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom order'**
  String get sortCustom;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// No description provided for @sortArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get sortArtist;

  /// No description provided for @sortAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get sortAlbum;

  /// No description provided for @sortDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get sortDateAdded;

  /// No description provided for @playlistInfo.
  ///
  /// In en, this message translates to:
  /// **'Playlist Info'**
  String get playlistInfo;

  /// No description provided for @totalSongs.
  ///
  /// In en, this message translates to:
  /// **'Total Songs'**
  String get totalSongs;

  /// No description provided for @totalDuration.
  ///
  /// In en, this message translates to:
  /// **'Total Duration'**
  String get totalDuration;

  /// No description provided for @dateCreated.
  ///
  /// In en, this message translates to:
  /// **'Date Created'**
  String get dateCreated;

  /// No description provided for @songsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} songs'**
  String songsCount(int count);

  /// No description provided for @hoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours {minutes} minutes'**
  String hoursMinutes(int hours, int minutes);

  /// No description provided for @hoursOnly.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String hoursOnly(int hours);

  /// No description provided for @minutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String minutesOnly(int minutes);

  /// No description provided for @searchSongHint.
  ///
  /// In en, this message translates to:
  /// **'Search song or artist...'**
  String get searchSongHint;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortLabel;

  /// No description provided for @customizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Customize'**
  String get customizeLabel;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchLabel;

  /// No description provided for @infoLabel.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get infoLabel;

  /// No description provided for @viewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View Photo'**
  String get viewPhoto;

  /// No description provided for @editPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Edit Playlist'**
  String get editPlaylist;

  /// No description provided for @playNext.
  ///
  /// In en, this message translates to:
  /// **'Play Next'**
  String get playNext;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist'**
  String get addToPlaylist;

  /// No description provided for @trackDetails.
  ///
  /// In en, this message translates to:
  /// **'Track details'**
  String get trackDetails;

  /// No description provided for @deleteFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete from Playlist'**
  String get deleteFromPlaylist;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLabel;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// No description provided for @playLabel.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playLabel;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @artistLabel.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artistLabel;

  /// No description provided for @albumLabel.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get albumLabel;

  /// No description provided for @pathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get pathLabel;

  /// No description provided for @gagalMemuatLagu.
  ///
  /// In en, this message translates to:
  /// **'Failed to load songs: {error}'**
  String gagalMemuatLagu(String error);

  /// No description provided for @gagalMenghapusLagu.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete songs: {error}'**
  String gagalMenghapusLagu(String error);

  /// No description provided for @playlistNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'This playlist doesn\'t have a photo yet.'**
  String get playlistNoPhoto;

  /// No description provided for @addToPlaylistComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Add to Playlist feature coming soon'**
  String get addToPlaylistComingSoon;

  /// No description provided for @changePlaylistPhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Playlist Photo'**
  String get changePlaylistPhoto;

  /// No description provided for @galleryLabel.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get galleryLabel;

  /// No description provided for @cameraLabel.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraLabel;

  /// No description provided for @cropPhoto.
  ///
  /// In en, this message translates to:
  /// **'Crop Photo'**
  String get cropPhoto;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @noSongsInDevice.
  ///
  /// In en, this message translates to:
  /// **'No songs on your device yet.'**
  String get noSongsInDevice;

  /// No description provided for @songAdded.
  ///
  /// In en, this message translates to:
  /// **'{title} added'**
  String songAdded(String title);

  /// No description provided for @pauseLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseLabel;

  /// No description provided for @belumAdaLagu.
  ///
  /// In en, this message translates to:
  /// **'No songs yet'**
  String get belumAdaLagu;

  /// No description provided for @tambahkanLaguPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add some songs to fill this playlist.'**
  String get tambahkanLaguPlaylist;

  /// No description provided for @customOrderToDrag.
  ///
  /// In en, this message translates to:
  /// **'Change to \"Custom order\" to drag songs'**
  String get customOrderToDrag;

  /// No description provided for @allCollections.
  ///
  /// In en, this message translates to:
  /// **'All Collections'**
  String get allCollections;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @dataUpdated.
  ///
  /// In en, this message translates to:
  /// **'Data updated'**
  String get dataUpdated;

  /// No description provided for @albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// No description provided for @artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// No description provided for @folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get folders;

  /// No description provided for @albumsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Albums'**
  String albumsCount(int count);

  /// No description provided for @artistsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Artists'**
  String artistsCount(int count);

  /// No description provided for @foldersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Folders'**
  String foldersCount(int count);

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// No description provided for @noFoldersFound.
  ///
  /// In en, this message translates to:
  /// **'No folders found.'**
  String get noFoldersFound;

  /// No description provided for @noSongsInFolder.
  ///
  /// In en, this message translates to:
  /// **'No songs in this folder.'**
  String get noSongsInFolder;

  /// No description provided for @shuffleLabel.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffleLabel;

  /// No description provided for @playAllLabel.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAllLabel;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @defaultProfileName.
  ///
  /// In en, this message translates to:
  /// **'Lyra User'**
  String get defaultProfileName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter Name'**
  String get enterName;

  /// No description provided for @cropProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Crop Profile Photo'**
  String get cropProfilePhoto;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from Gallery'**
  String get pickFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @noSongPlaying.
  ///
  /// In en, this message translates to:
  /// **'No song playing'**
  String get noSongPlaying;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @playingFrom.
  ///
  /// In en, this message translates to:
  /// **'Playing from {source}'**
  String playingFrom(String source);

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining: {time}'**
  String timeRemaining(String time);

  /// No description provided for @offLabel.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get offLabel;

  /// No description provided for @minutes30.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get minutes30;

  /// No description provided for @hour1.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get hour1;

  /// No description provided for @hour1Min30.
  ///
  /// In en, this message translates to:
  /// **'1 hour 30 minutes'**
  String get hour1Min30;

  /// No description provided for @hours2.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get hours2;

  /// No description provided for @customLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customLabel;

  /// No description provided for @appVolume.
  ///
  /// In en, this message translates to:
  /// **'App Volume'**
  String get appVolume;

  /// No description provided for @speedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speedLabel;

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// No description provided for @shuffleModeActive.
  ///
  /// In en, this message translates to:
  /// **'Shuffle mode active. Turn off shuffle to reorder.'**
  String get shuffleModeActive;

  /// No description provided for @removedFromQueue.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" removed from queue'**
  String removedFromQueue(String title);

  /// No description provided for @undoLabel.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoLabel;

  /// No description provided for @emptyQueue.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get emptyQueue;

  /// No description provided for @topResult.
  ///
  /// In en, this message translates to:
  /// **'Top Result'**
  String get topResult;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @encodingType.
  ///
  /// In en, this message translates to:
  /// **'Encoding type'**
  String get encodingType;

  /// No description provided for @unicodeUtf16.
  ///
  /// In en, this message translates to:
  /// **'Unicode (UTF-16)'**
  String get unicodeUtf16;

  /// No description provided for @albumArtistLabel.
  ///
  /// In en, this message translates to:
  /// **'Album artist'**
  String get albumArtistLabel;

  /// No description provided for @genreLabel.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genreLabel;

  /// No description provided for @trackNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Track number'**
  String get trackNumberLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// No description provided for @metadataUpdated.
  ///
  /// In en, this message translates to:
  /// **'Metadata updated successfully!'**
  String get metadataUpdated;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String updateFailed(String error);

  /// No description provided for @permissionRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission Required!'**
  String get permissionRequiredTitle;

  /// No description provided for @permissionRequiredGateDesc.
  ///
  /// In en, this message translates to:
  /// **'Lyra needs \"Music and Audio\" access permission to scan and play songs on your device.'**
  String get permissionRequiredGateDesc;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open App Info Settings'**
  String get openAppSettings;
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
