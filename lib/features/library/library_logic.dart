import '../../models/song.dart' as local;

/// Menentukan kunci unik untuk album.
String albumKey(local.Song s) {
  if (s.albumId.isNotEmpty && s.albumId != '0') {
    return s.albumId;
  }
  return '${s.album}|${s.artist}'.toLowerCase();
}

/// Menentukan kunci unik untuk artis.
String artistKey(String artist) {
  final key = artist.trim().toLowerCase();
  return key.isEmpty ? 'unknown artist' : key;
}

/// Model grup album.
class AlbumGroup {
  final String key;
  final String name;
  final String artist;
  final String albumId;
  final List<local.Song> songs;

  AlbumGroup({
    required this.key,
    required this.name,
    required this.artist,
    required this.albumId,
    required this.songs,
  });

  int get totalDurationMs =>
      songs.fold(0, (sum, song) => sum + song.durationMs);
}

/// Mengambil semua lagu dalam satu album, diurutkan A-Z.
List<local.Song> songsOfAlbum(List<local.Song> all, String key) {
  final songs = all.where((s) => albumKey(s) == key).toList();
  songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  return songs;
}

/// Mengambil semua album dari artis tertentu.
List<AlbumGroup> albumsOfArtist(List<local.Song> all, String artist) {
  final key = artistKey(artist);
  final artistSongs = all.where((s) => artistKey(s.artist) == key).toList();

  final Map<String, List<local.Song>> grouped = {};
  for (final s in artistSongs) {
    final aKey = albumKey(s);
    grouped.putIfAbsent(aKey, () => []).add(s);
  }

  return grouped.entries.map((e) {
    final songs = e.value;
    final first = songs.first;
    final name = first.album.trim().isEmpty ? 'Unknown Album' : first.album;
    final artistName = first.artist.trim().isEmpty
        ? 'Unknown Artist'
        : first.artist;

    return AlbumGroup(
      key: e.key,
      name: name,
      artist: artistName,
      albumId: first.albumId,
      songs: songs,
    );
  }).toList();
}

/// Mengambil semua lagu dari artis tertentu.
List<local.Song> songsOfArtist(List<local.Song> all, String artist) {
  final key = artistKey(artist);
  return all.where((s) => artistKey(s.artist) == key).toList();
}

/// Format durasi total menjadi teks.
String formatTotalDuration(int ms) {
  if (ms <= 0) return '0 menit';
  final totalMinutes = Duration(milliseconds: ms).inMinutes;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours > 0) {
    if (minutes == 0) return '$hours jam';
    return '$hours jam $minutes menit';
  }
  return '$minutes menit';
}
