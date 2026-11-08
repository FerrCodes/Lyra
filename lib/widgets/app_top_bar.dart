import 'dart:io';
import 'package:flutter/material.dart';
import '../providers/profile_provider.dart';
import 'default_profile_avatar.dart';
import 'lyra_header.dart';
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

  // Fungsi khusus untuk Avatar (karena ada bordernya)
  Widget _buildAvatarCircle({
    required Widget child,
    required VoidCallback onTap,
  }) {
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
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(child: SizedBox(width: 48, height: 48, child: child)),
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
    // HEADER BERANDA (Tab 0)
    if (currentTab == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildAvatarCircle(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            child: ValueListenableBuilder<String?>(
              valueListenable: profileImageNotifier,
              builder: (context, imagePath, child) {
                if (imagePath != null && imagePath.isNotEmpty)
                  return Image.file(File(imagePath), fit: BoxFit.cover);
                return const DefaultProfileAvatar(size: 48);
              },
            ),
          ),
        ],
      );
    }

    // HEADER SONGS (Tab 1)
    if (currentTab == 1) {
      return Row(
        children: [
          TopBarButton(
            isCircle: false,
            onTap: () {},
            customChild: Builder(
              builder: (buttonContext) {
                return InkWell(
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
          ),
          const Spacer(),
          TopBarButton(
            isCircle: false,
            onTap: () {},
            customChild: Row(
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
          TopBarButton(
            onTap: () =>
                playlistPageKey.currentState?.showCreatePlaylistDialog(),
            icon: Icons.playlist_add,
          ),
          TopBarButton(
            isCircle: false,
            onTap: () => playlistPageKey.currentState?.toggleEditMode(),
            customChild: Padding(
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

    // HEADER LIBRARY (Tab 3)
    if (currentTab == 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TopBarButton(
            isCircle: false,
            onTap: () {},
            customChild: Row(
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
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
          _buildAvatarCircle(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
            child: ValueListenableBuilder<String?>(
              valueListenable: profileImageNotifier,
              builder: (context, imagePath, child) {
                if (imagePath != null && imagePath.isNotEmpty)
                  return Image.file(File(imagePath), fit: BoxFit.cover);
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
