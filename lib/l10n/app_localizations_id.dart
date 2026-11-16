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
  String get theme => 'Tema';

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
  String get indonesian => 'Indonesia';

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

  @override
  String get sortName => 'Nama';

  @override
  String willPlayNext(String title) {
    return '$title akan diputar selanjutnya';
  }

  @override
  String get addToQueue => 'Tambah ke Antrean';

  @override
  String addedToQueue(String title) {
    return '$title ditambahkan ke antrean';
  }

  @override
  String get removeFromFavorites => 'Hapus dari Favorit';

  @override
  String get addToFavorites => 'Tambah ke Favorit';

  @override
  String get shareLabel => 'Bagikan';

  @override
  String get noPlaylistCreateFirst => 'Belum ada Playlist. Buat dulu di tab Playlist.';

  @override
  String get selectPlaylist => 'Pilih Playlist';

  @override
  String songAddedToPlaylist(String song, String playlist) {
    return '$song ditambahkan ke $playlist';
  }

  @override
  String get permissionRequired => 'Izin Music dan Audio dibutuhkan.';

  @override
  String get permissionRequiredDesc => 'Membutuhkan izin untuk mencari semua lagu.';

  @override
  String get tryAgain => 'Coba Lagi';

  @override
  String failedToLoadSongs(String error) {
    return 'Gagal memuat lagu: $error';
  }

  @override
  String get noSongsFoundList => 'Tidak ada lagu ditemukan.';

  @override
  String get allSongs => 'Semua Lagu';

  @override
  String get createNewPlaylist => 'Buat Playlist Baru';

  @override
  String get playlistNameEmpty => 'Nama playlist tidak boleh kosong';

  @override
  String failedToOpenGallery(String error) {
    return 'Gagal membuka galeri: $error';
  }

  @override
  String get playlistName => 'Nama Playlist';

  @override
  String get createPlaylist => 'Buat Playlist';

  @override
  String get editLabel => 'Edit';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get noPlaylistYet => 'Belum Ada Playlist';

  @override
  String get createFirstPlaylistDesc => 'Buat playlist pertamamu untuk\nmengelompokkan lagu favoritmu.';

  @override
  String get sortBy => 'Urutkan dari:';

  @override
  String get sortCustom => 'Urutan khusus';

  @override
  String get sortTitle => 'Judul';

  @override
  String get sortArtist => 'Artis';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortDateAdded => 'Terakhir ditambahkan';

  @override
  String get playlistInfo => 'Info Playlist';

  @override
  String get totalSongs => 'Total Lagu';

  @override
  String get totalDuration => 'Total Durasi';

  @override
  String get dateCreated => 'Tanggal Dibuat';

  @override
  String songsCount(int count) {
    return '$count lagu';
  }

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours jam $minutes menit';
  }

  @override
  String hoursOnly(int hours) {
    return '$hours jam';
  }

  @override
  String minutesOnly(int minutes) {
    return '$minutes menit';
  }

  @override
  String get searchSongHint => 'Cari lagu atau artis...';

  @override
  String get closeLabel => 'Tutup';

  @override
  String get sortLabel => 'Urutkan';

  @override
  String get customizeLabel => 'Sesuaikan';

  @override
  String get searchLabel => 'Cari';

  @override
  String get infoLabel => 'Info';

  @override
  String get viewPhoto => 'Lihat Foto';

  @override
  String get editPlaylist => 'Edit Playlist';

  @override
  String get playNext => 'Putar Selanjutnya';

  @override
  String get addToPlaylist => 'Tambah ke Playlist';

  @override
  String get trackDetails => 'Detail Lagu';

  @override
  String get deleteFromPlaylist => 'Hapus dari Playlist';

  @override
  String selectedCount(int count) {
    return '$count dipilih';
  }

  @override
  String get removeLabel => 'Hapus';

  @override
  String get addLabel => 'Tambah';

  @override
  String get playLabel => 'Putar';

  @override
  String get titleLabel => 'Judul';

  @override
  String get artistLabel => 'Artis';

  @override
  String get albumLabel => 'Album';

  @override
  String get pathLabel => 'Path';

  @override
  String gagalMemuatLagu(String error) {
    return 'Gagal memuat lagu: $error';
  }

  @override
  String gagalMenghapusLagu(String error) {
    return 'Gagal menghapus lagu: $error';
  }

  @override
  String get playlistNoPhoto => 'Playlist ini belum memiliki foto.';

  @override
  String get addToPlaylistComingSoon => 'Fitur Add to Playlist segera hadir';

  @override
  String get changePlaylistPhoto => 'Ganti Foto Playlist';

  @override
  String get galleryLabel => 'Galeri';

  @override
  String get cameraLabel => 'Kamera';

  @override
  String get cropPhoto => 'Potong Foto';

  @override
  String get descriptionOptional => 'Deskripsi (Opsional)';

  @override
  String get saveLabel => 'Simpan';

  @override
  String get noSongsInDevice => 'Belum ada lagu di perangkatmu.';

  @override
  String songAdded(String title) {
    return '$title ditambahkan';
  }

  @override
  String get pauseLabel => 'Jeda';

  @override
  String get belumAdaLagu => 'Belum ada lagu';

  @override
  String get tambahkanLaguPlaylist => 'Tambahkan beberapa lagu untuk mengisi playlist ini.';

  @override
  String get customOrderToDrag => 'Ubah ke \"Custom order\" untuk menggeser lagu';

  @override
  String get allCollections => 'Semua Koleksi';

  @override
  String get refresh => 'Segarkan';

  @override
  String get dataUpdated => 'Data diperbarui';

  @override
  String get albums => 'Album';

  @override
  String get artists => 'Artis';

  @override
  String get folders => 'Folder';

  @override
  String albumsCount(int count) {
    return '$count Album';
  }

  @override
  String artistsCount(int count) {
    return '$count Artis';
  }

  @override
  String foldersCount(int count) {
    return '$count Folder';
  }

  @override
  String get playAll => 'Putar Semua';

  @override
  String get noFoldersFound => 'Tidak ada folder yang ditemukan.';

  @override
  String get noSongsInFolder => 'Tidak ada lagu di folder ini.';

  @override
  String get shuffleLabel => 'Acak';

  @override
  String get playAllLabel => 'Putar Semua';

  @override
  String get locationLabel => 'Lokasi';

  @override
  String get profile => 'Profil';

  @override
  String get defaultProfileName => 'Pengguna Lyra';

  @override
  String get enterName => 'Masukan Nama';

  @override
  String get cropProfilePhoto => 'Potong Foto Profil';

  @override
  String get profileUpdated => 'Profil berhasil diperbarui';

  @override
  String get pickFromGallery => 'Ambil dari Galeri';

  @override
  String get removePhoto => 'Hapus Foto';

  @override
  String get noSongPlaying => 'Tidak ada lagu yang diputar';

  @override
  String get backLabel => 'Kembali';

  @override
  String playingFrom(String source) {
    return 'Diputar dari $source';
  }

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String timeRemaining(String time) {
    return 'Sisa waktu: $time';
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
  String get appVolume => 'Volume Aplikasi';

  @override
  String get speedLabel => 'Kecepatan';

  @override
  String get queueTitle => 'Antrean';

  @override
  String get shuffleModeActive => 'Mode acak aktif. Matikan acak untuk menggeser urutan.';

  @override
  String removedFromQueue(String title) {
    return '\"$title\" dihapus dari antrean';
  }

  @override
  String get undoLabel => 'Urungkan';

  @override
  String get emptyQueue => 'Antrean kosong';

  @override
  String get topResult => 'Hasil Teratas';

  @override
  String get recentSearches => 'Pencarian Terakhir';

  @override
  String get clearLabel => 'Hapus';

  @override
  String noResultsFor(String query) {
    return 'Tidak ada hasil untuk \"$query\"';
  }

  @override
  String get encodingType => 'Tipe Encoding';

  @override
  String get unicodeUtf16 => 'Unicode (UTF-16)';

  @override
  String get albumArtistLabel => 'Artis Album';

  @override
  String get genreLabel => 'Genre';

  @override
  String get trackNumberLabel => 'Nomor Track';

  @override
  String get cancelLabel => 'Batal';

  @override
  String get metadataUpdated => 'Metadata berhasil diperbarui!';

  @override
  String updateFailed(String error) {
    return 'Gagal: $error';
  }

  @override
  String get permissionRequiredTitle => 'Izin Diperlukan!';

  @override
  String get permissionRequiredGateDesc => 'Lyra membutuhkan izin akses \"Music and Audio\" untuk bisa memindai dan memutar lagu di perangkatmu.';

  @override
  String get openAppSettings => 'Buka Halaman Info Aplikasi';
}
