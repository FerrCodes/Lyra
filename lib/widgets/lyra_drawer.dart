import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/lyra_colors.dart';
import '../providers/profile_provider.dart';
import 'default_profile_avatar.dart';
import '../l10n/app_localizations.dart';
import '../ui/profile_page.dart';
import '../ui/settings_page.dart';

class LyraDrawer extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final VoidCallback onClose;

  const LyraDrawer({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.lyra;

    return Drawer(
      backgroundColor: colors.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // HEADER DRAWER (Foto & Nama)
          InkWell(
            onTap: () {
              onClose();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: RepaintBoundary(
              child: SizedBox(
                height: 240,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Foto Profil (Full Width)
                    ValueListenableBuilder<String?>(
                      valueListenable: profileImageNotifier,
                      builder: (context, imagePath, child) {
                        if (imagePath != null && imagePath.isNotEmpty) {
                          return Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            cacheWidth: 600,
                          );
                        }
                        // Jika tidak ada foto, gunakan background gradient khas Lyra
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.accent.withValues(alpha: 0.8),
                                colors.accent.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: DefaultProfileAvatar(size: 100),
                          ),
                        );
                      },
                    ),

                    // Gradasi Gelap di Bawah agar Teks Terbaca
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                            Colors.black.withValues(alpha: 0.9),
                          ],
                          stops: const [0.4, 0.8, 1.0],
                        ),
                      ),
                    ),

                    // Teks Nama & Ikon Panah
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          // Nama Pengguna
                          Expanded(
                            child: ValueListenableBuilder<String>(
                              valueListenable: profileNameNotifier,
                              builder: (context, name, child) {
                                final displayName = name.isEmpty
                                    ? AppLocalizations.of(
                                        context,
                                      )!.defaultProfileName
                                    : name;
                                return Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),

                          // Ikon Panah Kanan
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // MENU LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Settings (buka halaman baru)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: Icon(
                    Icons.settings_outlined,
                    color: colors.textPrimary,
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.settings,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    onClose();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Copyright Bawah
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppLocalizations.of(context)!.copyrightText,
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
