import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart' as local;
import '../services/media_store_service.dart';

final allSongsProvider = FutureProvider<List<local.Song>>((ref) async {
  try {
    final rawSongs = await MediaStoreService.getSongs();
    return rawSongs.map((e) => local.Song.fromMap(e)).toList();
  } catch (e) {
    // Log error untuk keperluan debugging di terminal
    debugPrint('Error di allSongsProvider: $e');

    // Lemparkan kembali (rethrow) agar UI/Riverpod menerima error asli
    // (termasuk MediaStoreException beserta kodenya)
    rethrow;
  }
});
