import 'package:flutter/services.dart';

class MediaStoreService {
  static const MethodChannel _channel = MethodChannel('com.lyra/media_store');

  /// Mengambil semua lagu dari HP via Kotlin
  static Future<List<Map<String, dynamic>>> getSongs() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getSongs');
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } on PlatformException catch (e) {
      // Lemparkan error agar bisa ditangani di UI
      throw Exception("Gagal mengambil lagu: ${e.message}");
    }
  }
}
