class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String path;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.path,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      durationMs: map['duration'] as int,
      path: map['path'] as String,
    );
  }

  Duration get duration => Duration(milliseconds: durationMs);
}
