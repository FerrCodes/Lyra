import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Jembatan Foto
final ValueNotifier<String?> profileImageNotifier = ValueNotifier<String?>(
  null,
);

final ValueNotifier<String> profileNameNotifier = ValueNotifier<String>(
  'Pengguna Lyra',
);

Future<void> loadProfileData() async {
  final prefs = await SharedPreferences.getInstance();

  // Muat Foto
  profileImageNotifier.value = prefs.getString('profile_image');

  // Muat Nama
  final savedName = prefs.getString('profile_name');
  if (savedName != null && savedName.isNotEmpty) {
    profileNameNotifier.value = savedName;
  }
}

Future<void> updateProfileImage(String newPath) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('profile_image', newPath);
  profileImageNotifier.value = newPath;
}

Future<void> updateProfileName(String newName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('profile_name', newName);
  profileNameNotifier.value = newName;
}
