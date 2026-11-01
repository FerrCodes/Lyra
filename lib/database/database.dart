import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// Tabel Master untuk semua lagu yang diketahui aplikasi
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

// Tabel Favorit (Hanya menyimpan relasi ke Songs)
class Favorites extends Table {
  TextColumn get songId =>
      text().references(Songs, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {songId};
}

// Tabel Playlist
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Tabel Relasi Playlist dan Lagu
class PlaylistSongs extends Table {
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  TextColumn get songId =>
      text().references(Songs, #id, onDelete: KeyAction.cascade)();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {playlistId, songId};
}

@DriftDatabase(tables: [Songs, Favorites, Playlists, PlaylistSongs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(playlists, playlists.sortOrder);
        await m.addColumn(playlists, playlists.description);
        await m.addColumn(playlistSongs, playlistSongs.orderIndex);
      }
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

    query.orderBy([OrderingTerm(expression: playlistSongs.orderIndex)]);

    final rows = await query.get();
    return rows.map((row) => row.readTable(songs)).toList();
  }

  // Tambah lagu ke playlist
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

    // Cari tahu urutan terakhir saat ini (agar lagu baru ditaruh di bawah)
    final query = selectOnly(playlistSongs)
      ..addColumns([playlistSongs.orderIndex.max()])
      ..where(playlistSongs.playlistId.equals(playlistId));
    final maxOrder =
        await query
            .map((row) => row.read(playlistSongs.orderIndex.max()))
            .getSingleOrNull() ??
        -1;

    // Masukkan ke playlist dengan orderIndex terbaru
    await into(playlistSongs).insert(
      PlaylistSongsCompanion.insert(
        playlistId: playlistId,
        songId: song.id,
        orderIndex: Value(maxOrder + 1),
      ),
      mode: InsertMode.insertOrIgnore,
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
