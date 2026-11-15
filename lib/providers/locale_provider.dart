import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../preferences/preferences_provider.dart';

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final prefs = ref.watch(lyraPreferencesProvider);
    final lang = prefs.loadLanguage();
    if (lang == 'system') return null; // Null berarti ikuti sistem
    return Locale(lang);
  }

  void setLanguage(String lang) {
    final prefs = ref.read(lyraPreferencesProvider);
    prefs.saveLanguage(lang);

    if (lang == 'system') {
      state = null;
    } else {
      state = Locale(lang);
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(() {
  return LocaleNotifier();
});
