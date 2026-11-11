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
}
