import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// Tabel Master untuk semua lagu yang diketahui aplikasi
class Songs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get album => text()();
  TextColumn get path => text()();
  IntColumn get durationMs => integer()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// Tabel Favorit
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
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
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

// TABEL PLAY HISTORY
class PlayHistory extends Table {
  TextColumn get path => text()();
  TextColumn get songId => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get album => text()();
  TextColumn get albumId => text()();
  IntColumn get durationMs => integer()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {path};
}

@DriftDatabase(
  tables: [Songs, Favorites, Playlists, PlaylistSongs, PlayHistory],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(playlists, playlists.sortOrder);
        await m.addColumn(playlists, playlists.description);
        await m.addColumn(playlistSongs, playlistSongs.orderIndex);
      }
      if (from < 3) {
        await m.createTable(playHistory);
      }
      if (from < 4) {
        await m.addColumn(playlists, playlists.isFavorite);
      }
    },
  );

  Future<void> saveSong(SongsCompanion song) =>
      into(songs).insertOnConflictUpdate(song);

  Future<List<Song>> getAllFavoriteSongs() async {
    final query = select(
      favorites,
    ).join([innerJoin(songs, songs.id.equalsExp(favorites.songId))]);
    final rows = await query.get();
    return rows.map((row) => row.readTable(songs)).toList();
  }

  Future<bool> isFavorite(String songId) async {
    final query = select(favorites)..where((t) => t.songId.equals(songId));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  Future<void> toggleFavorite(Song song) async {
    final isFav = await isFavorite(song.id);
    if (isFav) {
      await (delete(favorites)..where((t) => t.songId.equals(song.id))).go();
    } else {
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

  // Fungsi untuk mengubah status favorit playlist
  Future<void> togglePlaylistFavorite(Playlist playlist) async {
    await (update(playlists)..where((t) => t.id.equals(playlist.id))).write(
      PlaylistsCompanion(isFavorite: Value(!playlist.isFavorite)),
    );
  }

  // Stream untuk memantau status favorit satu playlist (untuk halaman detail)
  Stream<bool> watchPlaylistIsFavorite(int playlistId) {
    return (select(playlists)..where((t) => t.id.equals(playlistId)))
        .watchSingle()
        .map((p) => p.isFavorite);
  }

  // Stream untuk mengambil semua playlist yang difavoritkan (untuk halaman beranda)
  Stream<List<Playlist>> watchFavoritePlaylists() {
    return (select(playlists)
          ..where((t) => t.isFavorite.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .watch();
  }

  Future<List<Song>> getSongsInPlaylist(int playlistId) async {
    final query = select(playlistSongs).join([
      innerJoin(songs, songs.id.equalsExp(playlistSongs.songId)),
    ])..where(playlistSongs.playlistId.equals(playlistId));

    query.orderBy([OrderingTerm(expression: playlistSongs.orderIndex)]);

    final rows = await query.get();
    return rows.map((row) => row.readTable(songs)).toList();
  }

  Future<void> addSongToPlaylist(int playlistId, Song song) async {
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

    final query = selectOnly(playlistSongs)
      ..addColumns([playlistSongs.orderIndex.max()])
      ..where(playlistSongs.playlistId.equals(playlistId));
    final maxOrder =
        await query
            .map((row) => row.read(playlistSongs.orderIndex.max()))
            .getSingleOrNull() ??
        -1;

    await into(playlistSongs).insert(
      PlaylistSongsCompanion.insert(
        playlistId: playlistId,
        songId: song.id,
        orderIndex: Value(maxOrder + 1),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  // FUNGSI BARU UNTUK PLAY HISTORY
  Future<void> recordPlay({
    required String path,
    required String songId,
    required String title,
    required String artist,
    required String album,
    required String albumId,
    required int durationMs,
  }) async {
    final existing = await (select(
      playHistory,
    )..where((t) => t.path.equals(path))).getSingleOrNull();

    if (existing != null) {
      await (update(playHistory)..where((t) => t.path.equals(path))).write(
        PlayHistoryCompanion(
          playCount: Value(existing.playCount + 1),
          lastPlayedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(playHistory).insert(
        PlayHistoryCompanion.insert(
          path: path,
          songId: songId,
          title: title,
          artist: artist,
          album: album,
          albumId: albumId,
          durationMs: durationMs,
          lastPlayedAt: DateTime.now(),
        ),
      );
    }
  }

  Stream<List<PlayHistoryData>> watchTopPlayed({int limit = 10}) {
    return (select(playHistory)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.playCount, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .watch();
  }

  Stream<PlayHistoryData?> watchLastPlayed() {
    return (select(playHistory)
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.lastPlayedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Stream<List<Song>> watchFavorites() {
    final query = select(
      favorites,
    ).join([innerJoin(songs, songs.id.equalsExp(favorites.songId))]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(songs)).toList(),
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
