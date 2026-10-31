import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart' as local;
import '../services/media_store_service.dart';

final allSongsProvider = FutureProvider<List<local.Song>>((ref) async {
  try {
    final rawSongs = await MediaStoreService.getSongs();
    return rawSongs.map((e) => local.Song.fromMap(e)).toList();
  } catch (e) {
    // Teruskan error ke Riverpod
    throw Exception(e.toString());
  }
});
