import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// 1. Tabel Master untuk semua lagu yang diketahui aplikasi
class Songs extends Table {
  TextColumn get id => text()(); // ID dari MediaStore
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get album => text()();
  TextColumn get path => text()();
  IntColumn get durationMs => integer()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// 2. Tabel Favorit (Hanya menyimpan relasi ke Songs)
class Favorites extends Table {
  TextColumn get songId =>
      text().references(Songs, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {songId};
}

// 3. Tabel Playlist
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// 4. Tabel Relasi Playlist dan Lagu
class PlaylistSongs extends Table {
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get songId =>
      text().references(Songs, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {playlistId, songId};
}

@DriftDatabase(tables: [Songs, Favorites, Playlists, PlaylistSongs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // JANGAN HAPUS TABEL.
      // Untuk saat ini, kita hanya print pesan di console.
      // Nanti, jika kamu benar-benar mengubah skema (misal dari versi 1 ke 2),
      // kamu harus menulis kode migrasi manual di sini (misal: m.addColumn(...)).
      print('Database di-upgrade dari versi $from ke $to. Data aman.');
    },
  );

  // --- FUNGSI BANTUAN ---

  // Tambah/update lagu ke tabel master
  Future<void> saveSong(SongsCompanion song) =>
      into(songs).insertOnConflictUpdate(song);

  // Ambil semua lagu favorit (Join dengan tabel Songs)
  Future<List<Song>> getAllFavoriteSongs() async {
    final query = select(
      favorites,
    ).join([innerJoin(songs, songs.id.equalsExp(favorites.songId))]);
    final rows = await query.get();
    return rows.map((row) => row.readTable(songs)).toList();
  }

  // Cek apakah lagu difavoritkan
  Future<bool> isFavorite(String songId) async {
    final query = select(favorites)..where((t) => t.songId.equals(songId));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  // Toggle Favorit
  Future<void> toggleFavorite(Song song) async {
    final isFav = await isFavorite(song.id);
    if (isFav) {
      await (delete(favorites)..where((t) => t.songId.equals(song.id))).go();
    } else {
      // Simpan lagu ke master dulu agar relasinya valid
      await saveSong(
        SongsCompanion.insert(
          id: song.id,
          title: song.title,
          artist: song.artist,
          album: song.album,
          path: song.path,
          durationMs: song.durationMs,
        ),
      );
      await into(favorites).insert(FavoritesCompanion.insert(songId: song.id));
    }
  }

  // Ambil lagu dalam playlist tertentu
  Future<List<Song>> getSongsInPlaylist(int playlistId) async {
    final query = select(playlistSongs).join([
      innerJoin(songs, songs.id.equalsExp(playlistSongs.songId)),
    ])..where(playlistSongs.playlistId.equals(playlistId));

    final rows = await query.get();
    return rows.map((row) => row.readTable(songs)).toList();
  }

  // Tambah lagu ke playlist
  Future<void> addSongToPlaylist(int playlistId, Song song) async {
    // Pastikan lagu ada di master
    await saveSong(
      SongsCompanion.insert(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        path: song.path,
        durationMs: song.durationMs,
      ),
    );
    // Masukkan ke playlist
    await into(playlistSongs).insert(
      PlaylistSongsCompanion.insert(playlistId: playlistId, songId: song.id),
      mode:
          InsertMode.insertOrIgnore, // Abaikan jika lagu sudah ada di playlist
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'lyra_database',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
  );
}
