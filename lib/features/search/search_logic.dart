import '../../../models/song.dart' as local;

class SearchSongResult {
  final local.Song song;
  final int score;
  SearchSongResult(this.song, this.score);
}

class ArtistResult {
  final String name;
  final int songCount;
  final String albumId;
  ArtistResult(this.name, this.songCount, this.albumId);
}

class AlbumResult {
  final String name;
  final String artist;
  final int songCount;
  final String albumId;
  AlbumResult(this.name, this.artist, this.songCount, this.albumId);
}

class SearchResults {
  final List<SearchSongResult> songs;
  final List<ArtistResult> artists;
  final List<AlbumResult> albums;
  final local.Song? topSongResult;

  SearchResults({
    required this.songs,
    required this.artists,
    required this.albums,
    this.topSongResult,
  });
}

// Fungsi Normalisasi: huruf kecil, hapus spasi berlebih
String _normalize(String text) {
  return text.toLowerCase().trim();
}

bool _matchesTokens(String text, List<String> tokens) {
  final normalizedText = _normalize(text);
  return tokens.every((token) => normalizedText.contains(token));
}

int _calculateScore(local.Song song, String query) {
  final q = _normalize(query);
  final title = _normalize(song.title);
  final artist = _normalize(song.artist);
  final album = _normalize(song.album);

  if (title.startsWith(q)) return 100;
  if (title.contains(q)) return 80;
  if (artist.startsWith(q)) return 60;
  if (artist.contains(q)) return 40;
  if (album.contains(q)) return 20;
  return 0;
}

SearchResults performSearch(List<local.Song> allSongs, String rawQuery) {
  final query = _normalize(rawQuery);
  if (query.isEmpty) {
    return SearchResults(songs: [], artists: [], albums: []);
  }

  final tokens = query.split(RegExp(r'\s+'));

  // 1. Filter & Skor Lagu
  final songResults = <SearchSongResult>[];
  for (var song in allSongs) {
    final combined = '${song.title} ${song.artist} ${song.album}';
    if (_matchesTokens(combined, tokens)) {
      final score = _calculateScore(song, query);
      songResults.add(SearchSongResult(song, score));
    }
  }

  // Urutkan skor tertinggi, lalu judul A-Z, batasi 100
  songResults.sort((a, b) {
    if (b.score != a.score) return b.score.compareTo(a.score);
    return a.song.title.compareTo(b.song.title);
  });
  final limitedSongs = songResults.take(100).toList();

  // 2. Kelompokkan Artis
  final artistMap = <String, ArtistResult>{};
  for (var res in limitedSongs) {
    final song = res.song;
    final artistName = song.artist.isEmpty ? 'Unknown Artist' : song.artist;
    if (artistMap.containsKey(artistName)) {
      final existing = artistMap[artistName]!;
      artistMap[artistName] = ArtistResult(
        artistName,
        existing.songCount + 1,
        existing.albumId.isEmpty ? song.albumId : existing.albumId,
      );
    } else {
      artistMap[artistName] = ArtistResult(artistName, 1, song.albumId);
    }
  }

  // 3. Kelompokkan Album
  final albumMap = <String, AlbumResult>{};
  for (var res in limitedSongs) {
    final song = res.song;
    final albumName = song.album.isEmpty ? 'Unknown Album' : song.album;
    if (albumMap.containsKey(albumName)) {
      final existing = albumMap[albumName]!;
      albumMap[albumName] = AlbumResult(
        albumName,
        existing.artist,
        existing.songCount + 1,
        existing.albumId,
      );
    } else {
      albumMap[albumName] = AlbumResult(
        albumName,
        song.artist,
        1,
        song.albumId,
      );
    }
  }

  return SearchResults(
    songs: limitedSongs,
    artists: artistMap.values.toList(),
    albums: albumMap.values.toList(),
    topSongResult: limitedSongs.isNotEmpty ? limitedSongs.first.song : null,
  );
}
