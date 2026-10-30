import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart' as local;
import '../services/media_store_service.dart';

// FutureProvider ini akan otomatis meng-cache hasil scan lagu.
// MediaStoreService.getSongs() hanya akan dipanggil SEKALI.
final allSongsProvider = FutureProvider<List<local.Song>>((ref) async {
  final rawSongs = await MediaStoreService.getSongs();

  // Mapping dari Map (hasil Kotlin) ke model Song
  return rawSongs.map((e) => local.Song.fromMap(e)).toList();
});
