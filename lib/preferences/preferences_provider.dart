import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lyra_preferences.dart';

/// Di-override di main() dengan instance SharedPreferences asli.
/// Sengaja throw agar tidak bisa dipakai tanpa inisialisasi di main().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider harus di-override di main()',
  );
});

final lyraPreferencesProvider = Provider<LyraPreferences>((ref) {
  return LyraPreferences(ref.watch(sharedPreferencesProvider));
});
