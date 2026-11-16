import 'dart:io';
import 'package:flutter/material.dart';
import '../providers/profile_provider.dart';
import 'default_profile_avatar.dart';
import 'lyra_header.dart';
import '../ui/songs_page.dart';
import '../ui/playlist_page.dart';
import '../ui/library_page.dart';
import 'glass_container.dart';
import '../theme/lyra_colors.dart';
import '../l10n/app_localizations.dart';

class AppTopBar extends StatelessWidget {
  final int currentTab;
  final String currentSortFilter;
  final VoidCallback onProfileTap;

  const AppTopBar({
    super.key,
    required this.currentTab,
    required this.currentSortFilter,
    required this.onProfileTap,
  });

  String _getLocalizedFilter(BuildContext context, String filter) {
    final l10n = AppLocalizations.of(context)!;
    switch (filter) {
      case 'Name':
        return l10n.sortName;
      case 'Artist':
        return l10n.sortArtist;
      case 'Date Added':
        return l10n.sortDateAdded;
      default:
        return filter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: _buildHeaderContent(context),
    );
  }

  // Fungsi bantuan untuk membuat lingkaran putih dengan efek kaca/border
  Widget _buildCircle({required Widget child}) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(child: Center(child: child)),
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    // HEADER BERANDA (Tab 0)
    if (currentTab == 0) {
      if (currentTab == 0) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Avatar Profil (Kiri)
            _buildCircle(
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onProfileTap,
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

            // Teks LYRA MUSIC (Kanan)
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              radius: 20,
              blurSigma: 12,
              tintOpacity: 0.5,
              child: Text(
                'LYRA MUSIC',
                style: TextStyle(
                  fontFamily: 'LyraFont',
                  fontSize: 22,
                  letterSpacing: -0.5,
                  color: context.lyra.textPrimary,
                ),
              ),
            ),
          ],
        );
      }
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
                          _getLocalizedFilter(context, currentSortFilter),
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
            onTap: () {},
            customChild: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: playlistViewModeNotifier,
                  builder: (context, isListView, child) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          playlistViewModeNotifier.value = !isListView;
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            isListView
                                ? Icons.grid_view_rounded
                                : Icons.view_list_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
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
          // Avatar Profil (Kiri - Untuk Buka Drawer)
          _buildCircle(
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onProfileTap, // <--- Panggil drawer
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

          // Tombol Refresh (Kanan)
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
                    onTap: () {
                      libraryPageKey.currentState?.refreshStats();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.refresh_rounded,
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

    return const SizedBox.shrink();
  }
}
