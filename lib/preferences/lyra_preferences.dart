import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LyraPreferences {
  final SharedPreferences _prefs;
  LyraPreferences(this._prefs);

  // === KEY ===
  static const _kTheme = 'lyra_theme_mode';
  static const _kPlaylistIsList = 'lyra_playlist_is_list';
  static const _kSongsSort = 'lyra_songs_sort';
  static const _kPlaylistDetailSort = 'lyra_playlist_detail_sort';
  static const _kLanguage = 'lyra_language';

  // === TEMA ===
  ThemeMode loadTheme() {
    final raw = _prefs.getString(_kTheme);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveTheme(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_kTheme, value);
  }

  // === PLAYLIST VIEW (Grid/List) ===
  bool loadPlaylistIsListView() {
    return _prefs.getBool(_kPlaylistIsList) ?? false;
  }

  Future<void> savePlaylistIsListView(bool isList) async {
    await _prefs.setBool(_kPlaylistIsList, isList);
  }

  // === SONGS SORT ===
  String loadSongsSort() {
    final raw = _prefs.getString(_kSongsSort);
    const valid = {'Name', 'Artist', 'Date Added'};
    if (raw != null && valid.contains(raw)) return raw;
    return 'Name';
  }

  Future<void> saveSongsSort(String value) async {
    await _prefs.setString(_kSongsSort, value);
  }

  // === PLAYLIST DETAIL SORT ===
  String loadPlaylistDetailSort() {
    final raw = _prefs.getString(_kPlaylistDetailSort);
    const valid = {'Custom order', 'Name', 'Artist', 'Album', 'Date Added'};
    if (raw != null && valid.contains(raw)) return raw;
    return 'Custom order';
  }

  Future<void> savePlaylistDetailSort(String value) async {
    await _prefs.setString(_kPlaylistDetailSort, value);
  }

  // === BAHASA ===
  String loadLanguage() {
    final raw = _prefs.getString(_kLanguage);
    const valid = {'system', 'en', 'id'};
    if (raw != null && valid.contains(raw)) return raw;
    return 'id'; // Default instalasi pertama: Bahasa Indonesia
  }

  Future<void> saveLanguage(String value) async {
    await _prefs.setString(_kLanguage, value);
  }
}
