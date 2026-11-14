import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/lyra_colors.dart';
import '../widgets/lyra_header.dart';
import '../services/media_store_service.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _cacheSize = 'Menghitung...';
  bool _isGaplessPlayback = true;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        int totalSize = 0;
        await for (FileSystemEntity entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
        final mb = (totalSize / (1024 * 1024)).toStringAsFixed(2);
        if (mounted) setState(() => _cacheSize = '$mb MB');
      } else {
        if (mounted) setState(() => _cacheSize = '0 MB');
      }
    } catch (_) {
      if (mounted) setState(() => _cacheSize = 'Unknown');
    }
  }

  Future<void> _clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
      await _calculateCacheSize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache berhasil dibersihkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  void _showThemeDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final currentMode = ref.read(themeModeProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Ikuti Sistem'),
                trailing: currentMode == ThemeMode.system
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setTheme(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Terang'),
                trailing: currentMode == ThemeMode.light
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref
                      .read(themeModeProvider.notifier)
                      .setTheme(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Gelap'),
                trailing: currentMode == ThemeMode.dark
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref.read(themeModeProvider.notifier).setTheme(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colors.pageBackground,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: colors.pageBackground,
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 80,
                bottom: 40,
                left: 16,
                right: 16,
              ),
              children: [
                // 1. TAMPILAN
                _buildSectionTitle('Tampilan', colors),
                _buildSettingsGroup(
                  colors: colors,
                  isDark: isDark,
                  children: [
                    _buildArrowTile(
                      icon: Icons.palette_outlined,
                      title: 'Tema Aplikasi',
                      subtitle: themeMode == ThemeMode.system
                          ? 'Ikuti Sistem'
                          : themeMode == ThemeMode.light
                          ? 'Terang'
                          : 'Gelap',
                      onTap: _showThemeDialog,
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. AUDIO & PEMUTARAN
                _buildSectionTitle('Audio & Pemutaran', colors),
                _buildSettingsGroup(
                  colors: colors,
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      icon: Icons.graphic_eq,
                      title: 'Gapless Playback',
                      subtitle: 'Putar lagu tanpa jeda (Direkomendasikan)',
                      value: _isGaplessPlayback,
                      onChanged: (val) =>
                          setState(() => _isGaplessPlayback = val),
                      colors: colors,
                    ),
                    _buildDivider(colors),
                    _buildArrowTile(
                      icon: Icons.equalizer,
                      title: 'Equalizer Sistem',
                      subtitle: 'Buka pengaturan suara bawaan HP',
                      onTap: () async {
                        try {
                          await MediaStoreService.openEqualizer(); // Panggil Kotlin
                        } catch (e) {
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                        }
                      },
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. PENGATURAN PERANGKAT
                _buildSectionTitle('Pengaturan Perangkat', colors),
                _buildSettingsGroup(
                  colors: colors,
                  isDark: isDark,
                  children: [
                    _buildArrowTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifikasi Lyra',
                      subtitle: 'Atur cara Lyra mengirim notifikasi',
                      onTap: () {
                        // Membuka pengaturan notifikasi via permission_handler
                        openAppSettings();
                      },
                      colors: colors,
                    ),
                    _buildDivider(colors),
                    _buildArrowTile(
                      icon: Icons.security_outlined,
                      title: 'Izin Aplikasi',
                      subtitle: 'Kelola akses file dan media',
                      onTap: () => openAppSettings(),
                      colors: colors,
                    ),
                    _buildDivider(colors),
                    _buildArrowTile(
                      icon: Icons.battery_charging_full_outlined,
                      title: 'Baterai & Latar Belakang',
                      subtitle: 'Izinkan Lyra berjalan saat layar mati',
                      onTap: () async {
                        try {
                          await MediaStoreService.openBatterySettings(); // Panggil Kotlin
                        } catch (e) {
                          openAppSettings();
                        }
                      },
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. PENYIMPANAN
                _buildSectionTitle('Penyimpanan', colors),
                _buildSettingsGroup(
                  colors: colors,
                  isDark: isDark,
                  children: [
                    _buildArrowTile(
                      icon: Icons.storage_outlined,
                      title: 'Penggunaan Penyimpanan',
                      subtitle: 'Ukuran cache: $_cacheSize',
                      onTap: () {},
                      showArrow: false,
                      colors: colors,
                    ),
                    _buildDivider(colors),
                    _buildArrowTile(
                      icon: Icons.cleaning_services_outlined,
                      title: 'Hapus Cache',
                      subtitle: 'Hapus gambar sementara dan cache lagu',
                      onTap: _clearCache,
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 5. TENTANG APLIKASI
                _buildSectionTitle('Tentang Aplikasi', colors),
                _buildSettingsGroup(
                  colors: colors,
                  isDark: isDark,
                  children: [
                    _buildArrowTile(
                      icon: Icons.info_outline,
                      title: 'Versi Aplikasi',
                      subtitle: 'Lyra Music v1.0.0',
                      onTap: () {},
                      showArrow: false,
                      colors: colors,
                    ),
                    _buildDivider(colors),
                    _buildArrowTile(
                      icon: Icons.code,
                      title: 'Open Source Licenses',
                      subtitle: 'Lihat library yang digunakan',
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'Lyra Music',
                          applicationVersion: '1.0.0',
                          applicationIcon: Icon(
                            Icons.library_music_rounded,
                            size: 60,
                            color: colors.accent,
                          ),
                        );
                      },
                      colors: colors,
                    ),
                  ],
                ),
              ],
            ),

            // OVERLAY & TOP BAR
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: MediaQuery.of(context).padding.top + 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.pageBackground.withValues(alpha: 0.9),
                        colors.pageBackground.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.8],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  TopBarButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Pengaturan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER WIDGETS (Sama seperti sebelumnya, hanya dirapikan)
  Widget _buildSectionTitle(String title, LyraColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({
    required List<Widget> children,
    required LyraColors colors,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider(LyraColors colors) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 60,
      endIndent: 16,
      color: colors.textSecondary.withValues(alpha: 0.1),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required LyraColors colors,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colors.accent, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.textSecondary, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: colors.accent,
        activeTrackColor: colors.accent.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildArrowTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required LyraColors colors,
    bool showArrow = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colors.accent, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: colors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.textSecondary, fontSize: 12),
      ),
      trailing: showArrow
          ? Icon(
              Icons.arrow_forward_ios,
              color: colors.textSecondary.withValues(alpha: 0.5),
              size: 16,
            )
          : null,
    );
  }
}
