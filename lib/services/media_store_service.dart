import 'package:flutter/services.dart';

// Custom Exception agar UI tahu persis apa yang salah
class MediaStoreException implements Exception {
  final String message;
  final String? code;

  MediaStoreException(this.message, [this.code]);

  @override
  String toString() => 'MediaStoreException: $message (code: $code)';
}

class MediaStoreService {
  static const MethodChannel _channel = MethodChannel('com.lyra/media_store');

  /// Mengambil semua lagu dari HP via Kotlin
  static Future<List<Map<String, dynamic>>> getSongs() async {
    try {
      // NULL SAFETY: Gunakan tipe data nullable (?)
      final List<dynamic>? result = await _channel.invokeMethod('getSongs');

      // Cek jika Kotlin mengembalikan null
      if (result == null) {
        return [];
      }

      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } on PlatformException catch (e) {
      // ERROR HANDLING: Lemparkan custom exception beserta kodenya
      // Agar UI bisa mendeteksi jika error == 'PERMISSION_DENIED'
      throw MediaStoreException(
        e.message ?? 'Gagal mengambil lagu tanpa pesan error.',
        e.code,
      );
    }
  }

  static Future<bool> updateSongMetadata({
    required String id,
    required String title,
    required String artist,
    required String album,
    String genre = '',
    String albumArtist = '',
    String track = '0',
  }) async {
    try {
      final bool? result = await _channel.invokeMethod('updateSongMetadata', {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'genre': genre,
        'albumArtist': albumArtist,
        'track': track,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(e.message ?? 'Gagal mengubah metadata', e.code);
    }
  }

  static Future<bool> requestWritePermission(String id) async {
    try {
      final bool? result = await _channel.invokeMethod(
        'requestWritePermission',
        {'id': id},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(e.message ?? 'Izin ditolak', e.code);
    }
  }

  static Future<bool> updateAlbumCover({
    required String id,
    required String imagePath,
  }) async {
    try {
      final bool? result = await _channel.invokeMethod('updateAlbumCover', {
        'id': id,
        'imagePath': imagePath,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(e.message ?? 'Gagal update cover', e.code);
    }
  }

  static const MethodChannel _pickImageChannel = MethodChannel(
    'com.lyra/pick_image',
  );

  static Future<String?> pickImageFromGallery() async {
    try {
      final String? result = await _pickImageChannel.invokeMethod('pickImage');
      return result;
    } on PlatformException catch (e) {
      throw MediaStoreException(e.message ?? 'Gagal membuka galeri', e.code);
    }
  }

  static Future<bool> openEqualizer() async {
    try {
      final bool? result = await _channel.invokeMethod('openEqualizer');
      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(e.message ?? 'Gagal membuka equalizer', e.code);
    }
  }

  static Future<bool> openBatterySettings() async {
    try {
      final bool? result = await _channel.invokeMethod('openBatterySettings');
      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.message ?? 'Gagal membuka pengaturan baterai',
        e.code,
      );
    }
  }
}
