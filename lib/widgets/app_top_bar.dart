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

  // Widget dasar untuk kapsul putih
  Widget _buildPill({required Widget child, double? width}) {
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
      child: child,
    );
  }

  // Widget dasar untuk lingkaran putih
  Widget _buildCircle({required Widget child}) {
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
      child: Center(child: child),
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    // HEADER BERANDA (Tab 0)
    if (currentTab == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildCircle(
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
                child: ClipOval(
                  child: ValueListenableBuilder<String?>(
                    valueListenable: profileImageNotifier,
                    builder: (context, imagePath, child) {
                      if (imagePath != null && imagePath.isNotEmpty) {
                        return Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                        );
                      }
                      return const DefaultProfileAvatar(size: 48);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // HEADER SONGS (Tab 1)
    if (currentTab == 1) {
      return Row(
        children: [
          // Kapsul Filter (Kiri)
          Builder(
            builder: (buttonContext) {
              return _buildPill(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => songsPageKey.currentState?.triggerFilterDialog(
                      buttonContext,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sort,
                            color: Colors.black87,
                            size: 20,
                          ),
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
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // Kapsul Play (Kanan)
          _buildPill(
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

    // HEADER PLAYLIST (Tab 2)
    if (currentTab == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Tambah (Lingkaran)
          _buildCircle(
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () =>
                    playlistPageKey.currentState?.showCreatePlaylistDialog(),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.playlist_add,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Tombol Edit (Kapsul)
          _buildPill(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => playlistPageKey.currentState?.toggleEditMode(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: playlistEditModeNotifier,
                    builder: (context, isEditing, child) {
                      return Icon(
                        isEditing ? Icons.check : Icons.drag_indicator,
                        color: isEditing ? Colors.green : Colors.black,
                        size: 20,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // HEADER LIBRARY (Tab 3)
    if (currentTab == 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Kapsul Kiri (More & Settings)
          _buildPill(
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

          // Avatar Kanan (Lingkaran)
          _buildCircle(
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
                child: ClipOval(
                  child: ValueListenableBuilder<String?>(
                    valueListenable: profileImageNotifier,
                    builder: (context, imagePath, child) {
                      if (imagePath != null && imagePath.isNotEmpty) {
                        return Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                        );
                      }
                      return const DefaultProfileAvatar(size: 48);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
