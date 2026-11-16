class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String albumId;
  final String path;
  final String contentUri;
  final String albumArtist;
  final String genre;
  final String track;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.albumId,
    required this.path,
    this.contentUri = '',
    this.albumArtist = '',
    this.genre = '',
    this.track = '',
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Unknown Title',
      artist: map['artist']?.toString() ?? 'Unknown Artist',
      album: map['album']?.toString() ?? 'Unknown Album',
      path: map['path']?.toString() ?? '',
      albumId: map['albumId']?.toString() ?? '0',
      durationMs: (map['duration'] as num?)?.toInt() ?? 0,
      contentUri: map['contentUri']?.toString() ?? '',
      albumArtist: map['albumArtist']?.toString() ?? '',
      genre: map['genre']?.toString() ?? '',
      track: map['track']?.toString() ?? '',
    );
  }

  Duration get duration => Duration(milliseconds: durationMs);
}
