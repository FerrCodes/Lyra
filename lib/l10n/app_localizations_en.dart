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
  String get exploreMusicDesc => 'Play songs from the Songs tab, create the first Playlist, or add songs to Favorites. Activities will all appear here.';

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

  @override
  String get sortName => 'Name';

  @override
  String willPlayNext(String title) {
    return '$title will play next';
  }

  @override
  String get addToQueue => 'Add to Queue';

  @override
  String addedToQueue(String title) {
    return '$title added to queue';
  }

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get shareLabel => 'Share';

  @override
  String get noPlaylistCreateFirst => 'No Playlists yet. Create one in the Playlist tab.';

  @override
  String get selectPlaylist => 'Select Playlist';

  @override
  String songAddedToPlaylist(String song, String playlist) {
    return '$song added to $playlist';
  }

  @override
  String get permissionRequired => 'Music and Audio permission required.';

  @override
  String get permissionRequiredDesc => 'Requires permission to search all songs.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String failedToLoadSongs(String error) {
    return 'Failed to load songs: $error';
  }

  @override
  String get noSongsFoundList => 'No songs found.';

  @override
  String get allSongs => 'All Songs';

  @override
  String get createNewPlaylist => 'Create New Playlist';

  @override
  String get playlistNameEmpty => 'Playlist name cannot be empty';

  @override
  String failedToOpenGallery(String error) {
    return 'Failed to open gallery: $error';
  }

  @override
  String get playlistName => 'Playlist Name';

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get editLabel => 'Edit';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get noPlaylistYet => 'No Playlist Yet';

  @override
  String get createFirstPlaylistDesc => 'Create your first playlist to\ngroup your favorite songs.';

  @override
  String get sortBy => 'Sort by:';

  @override
  String get sortCustom => 'Custom order';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortArtist => 'Artist';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortDateAdded => 'Recently added';

  @override
  String get playlistInfo => 'Playlist Info';

  @override
  String get totalSongs => 'Total Songs';

  @override
  String get totalDuration => 'Total Duration';

  @override
  String get dateCreated => 'Date Created';

  @override
  String songsCount(int count) {
    return '$count songs';
  }

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours hours $minutes minutes';
  }

  @override
  String hoursOnly(int hours) {
    return '$hours hours';
  }

  @override
  String minutesOnly(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get searchSongHint => 'Search song or artist...';

  @override
  String get closeLabel => 'Close';

  @override
  String get sortLabel => 'Sort';

  @override
  String get customizeLabel => 'Customize';

  @override
  String get searchLabel => 'Search';

  @override
  String get infoLabel => 'Info';

  @override
  String get viewPhoto => 'View Photo';

  @override
  String get editPlaylist => 'Edit Playlist';

  @override
  String get playNext => 'Play Next';

  @override
  String get addToPlaylist => 'Add to Playlist';

  @override
  String get trackDetails => 'Track details';

  @override
  String get deleteFromPlaylist => 'Delete from Playlist';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get removeLabel => 'Remove';

  @override
  String get addLabel => 'Add';

  @override
  String get playLabel => 'Play';

  @override
  String get titleLabel => 'Title';

  @override
  String get artistLabel => 'Artist';

  @override
  String get albumLabel => 'Album';

  @override
  String get pathLabel => 'Path';

  @override
  String gagalMemuatLagu(String error) {
    return 'Failed to load songs: $error';
  }

  @override
  String gagalMenghapusLagu(String error) {
    return 'Failed to delete songs: $error';
  }

  @override
  String get playlistNoPhoto => 'This playlist doesn\'t have a photo yet.';

  @override
  String get addToPlaylistComingSoon => 'Add to Playlist feature coming soon';

  @override
  String get changePlaylistPhoto => 'Change Playlist Photo';

  @override
  String get galleryLabel => 'Gallery';

  @override
  String get cameraLabel => 'Camera';

  @override
  String get cropPhoto => 'Crop Photo';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get saveLabel => 'Save';

  @override
  String get noSongsInDevice => 'No songs on your device yet.';

  @override
  String songAdded(String title) {
    return '$title added';
  }

  @override
  String get pauseLabel => 'Pause';

  @override
  String get belumAdaLagu => 'No songs yet';

  @override
  String get tambahkanLaguPlaylist => 'Add some songs to fill this playlist.';

  @override
  String get customOrderToDrag => 'Change to \"Custom order\" to drag songs';

  @override
  String get allCollections => 'All Collections';

  @override
  String get refresh => 'Refresh';

  @override
  String get dataUpdated => 'Data updated';

  @override
  String get albums => 'Albums';

  @override
  String get artists => 'Artists';

  @override
  String get folders => 'Folders';

  @override
  String albumsCount(int count) {
    return '$count Albums';
  }

  @override
  String artistsCount(int count) {
    return '$count Artists';
  }

  @override
  String foldersCount(int count) {
    return '$count Folders';
  }

  @override
  String get playAll => 'Play All';

  @override
  String get noFoldersFound => 'No folders found.';

  @override
  String get noSongsInFolder => 'No songs in this folder.';

  @override
  String get shuffleLabel => 'Shuffle';

  @override
  String get playAllLabel => 'Play All';

  @override
  String get locationLabel => 'Location';

  @override
  String get profile => 'Profile';

  @override
  String get defaultProfileName => 'Lyra User';

  @override
  String get enterName => 'Enter Name';

  @override
  String get cropProfilePhoto => 'Crop Profile Photo';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get pickFromGallery => 'Pick from Gallery';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get noSongPlaying => 'No song playing';

  @override
  String get backLabel => 'Back';

  @override
  String playingFrom(String source) {
    return 'Playing from $source';
  }

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String timeRemaining(String time) {
    return 'Time remaining: $time';
  }

  @override
  String get offLabel => 'Off';

  @override
  String get minutes30 => '30 minutes';

  @override
  String get hour1 => '1 hour';

  @override
  String get hour1Min30 => '1 hour 30 minutes';

  @override
  String get hours2 => '2 hours';

  @override
  String get customLabel => 'Custom';

  @override
  String get appVolume => 'App Volume';

  @override
  String get speedLabel => 'Speed';

  @override
  String get queueTitle => 'Queue';

  @override
  String get shuffleModeActive => 'Shuffle mode active. Turn off shuffle to reorder.';

  @override
  String removedFromQueue(String title) {
    return '\"$title\" removed from queue';
  }

  @override
  String get undoLabel => 'Undo';

  @override
  String get emptyQueue => 'Queue is empty';

  @override
  String get topResult => 'Top Result';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get clearLabel => 'Clear';

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get encodingType => 'Encoding type';

  @override
  String get unicodeUtf16 => 'Unicode (UTF-16)';

  @override
  String get albumArtistLabel => 'Album artist';

  @override
  String get genreLabel => 'Genre';

  @override
  String get trackNumberLabel => 'Track number';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get metadataUpdated => 'Metadata updated successfully!';

  @override
  String updateFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get permissionRequiredTitle => 'Permission Required!';

  @override
  String get permissionRequiredGateDesc => 'Lyra needs \"Music and Audio\" access permission to scan and play songs on your device.';

  @override
  String get openAppSettings => 'Open App Info Settings';
}
