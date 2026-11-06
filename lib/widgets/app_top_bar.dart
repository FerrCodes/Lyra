import 'dart:io';
import 'package:flutter/material.dart';
import '../providers/profile_provider.dart';
import 'default_profile_avatar.dart';
import '../ui/settings_page.dart';
import '../ui/profile_page.dart';
import '../ui/songs_page.dart';
import '../ui/playlist_page.dart';
import '../ui/library_page.dart';

class AppTopBar extends StatelessWidget {
  final int currentTab;
  final String currentSortFilter;

  const AppTopBar({
    super.key,
    required this.currentTab,
    required this.currentSortFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: _buildHeaderContent(context),
    );
  }

  // FUNGSI BAKU: Kapsul Putih dengan fungsi onTap langsung di dalam
  Widget _buildPill({
    required Widget child,
    required VoidCallback onTap,
    double? width,
  }) {
    return Container(
      height: 48,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap, // <--- Fungsi klik di sini
          child: child,
        ),
      ),
    );
  }

  // FUNGSI BAKU: Lingkaran Putih dengan fungsi onTap langsung di dalam
  Widget _buildCircle({required Widget child, required VoidCallback onTap}) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap, // <--- Fungsi klik di sini
          customBorder: const CircleBorder(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(child: SizedBox(width: 48, height: 48, child: child)),
              // Border tipis di atas gambar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    // 1. HEADER BERANDA (Tab 0)
    if (currentTab == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildCircle(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: ValueListenableBuilder<String?>(
              valueListenable: profileImageNotifier,
              builder: (context, imagePath, child) {
                if (imagePath != null && imagePath.isNotEmpty) {
                  return Image.file(File(imagePath), fit: BoxFit.cover);
                }
                return const DefaultProfileAvatar(size: 48);
              },
            ),
          ),
        ],
      );
    }

    // 2. HEADER SONGS (Tab 1)
    if (currentTab == 1) {
      return Row(
        children: [
          Builder(
            builder: (buttonContext) {
              return _buildPill(
                onTap: () => songsPageKey.currentState?.triggerFilterDialog(
                  buttonContext,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort, color: Colors.black87, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        currentSortFilter,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          _buildPill(
            onTap: () {}, // Dummy onTap karena isinya ada dua tombol
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => songsPageKey.currentState?.playAllShuffled(),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.shuffle, color: Colors.black, size: 20),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => songsPageKey.currentState?.playAll(),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 3. HEADER PLAYLIST (Tab 2)
    if (currentTab == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircle(
            onTap: () =>
                playlistPageKey.currentState?.showCreatePlaylistDialog(),
            child: const Center(
              child: Icon(Icons.playlist_add, color: Colors.black, size: 22),
            ),
          ),
          _buildPill(
            onTap: () => playlistPageKey.currentState?.toggleEditMode(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: ValueListenableBuilder<bool>(
                  valueListenable: playlistEditModeNotifier,
                  builder: (context, isEditing, child) {
                    return Text(
                      isEditing ? 'Selesai' : 'Edit',
                      style: TextStyle(
                        color: isEditing
                            ? Colors.green.shade700
                            : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 4. HEADER LIBRARY (Tab 3)
    if (currentTab == 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPill(
            onTap: () {}, // Dummy onTap
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (buttonContext) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => libraryPageKey.currentState?.showMoreMenu(
                          buttonContext,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(
                            Icons.more_vert,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.settings_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildCircle(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: ValueListenableBuilder<String?>(
              valueListenable: profileImageNotifier,
              builder: (context, imagePath, child) {
                if (imagePath != null && imagePath.isNotEmpty) {
                  return Image.file(File(imagePath), fit: BoxFit.cover);
                }
                return const DefaultProfileAvatar(size: 48);
              },
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
