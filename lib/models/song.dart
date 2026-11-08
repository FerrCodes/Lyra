class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String albumId;
  final String path;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.albumId,
    required this.path,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      // Amankan String: Jika null, beri nilai default
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Unknown Title',
      artist: map['artist']?.toString() ?? 'Unknown Artist',
      album: map['album']?.toString() ?? 'Unknown Album',
      path: map['path']?.toString() ?? '',
      albumId: map['albumId']?.toString() ?? '0',
      // Amankan Angka: Konversi ke num dulu, baru ke int. Jika null, jadikan 0
      durationMs: (map['duration'] as num?)?.toInt() ?? 0,
    );
  }

  Duration get duration => Duration(milliseconds: durationMs);
}
