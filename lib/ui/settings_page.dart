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
import 'about_settings_page.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../preferences/preferences_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _cacheSize = 'Menghitung...';
  bool _isLanguageMenuOpen = false;
  final GlobalKey _languageItemKey = GlobalKey();
  bool _isThemeMenuOpen = false;
  final GlobalKey _themeItemKey = GlobalKey();

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
          SnackBar(content: Text(AppLocalizations.of(context)!.cacheCleared)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _getLanguageName(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(lyraPreferencesProvider).loadLanguage();
    if (currentLang == 'system') {
      return AppLocalizations.of(context)!.systemDefault;
    }
    if (currentLang == 'en') return AppLocalizations.of(context)!.english;
    return AppLocalizations.of(context)!.indonesian;
  }

  Future<void> _showLanguageMenu(BuildContext context, WidgetRef ref) async {
    final currentLang = ref.read(lyraPreferencesProvider).loadLanguage();

    // Dapatkan posisi item Bahasa via GlobalKey
    final RenderBox? button =
        _languageItemKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

    // Set state: popover terbuka (untuk animasi chevron)
    setState(() => _isLanguageMenuOpen = true);

    final result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Language Menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        final colors = context.lyra;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Stack(
          children: [
            // Posisi popover: di bawah item Bahasa, rata kanan
            Positioned(
              top: buttonPosition.dy + button.size.height - 12,
              right:
                  overlay.size.width -
                  buttonPosition.dx -
                  button.size.width +
                  4,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.textSecondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLanguageMenuItem(
                        context,
                        'system',
                        AppLocalizations.of(context)!.systemDefault,
                        currentLang,
                        colors,
                      ),
                      Divider(
                        color: colors.textSecondary.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      _buildLanguageMenuItem(
                        context,
                        'id',
                        AppLocalizations.of(context)!.indonesian,
                        currentLang,
                        colors,
                      ),
                      Divider(
                        color: colors.textSecondary.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      _buildLanguageMenuItem(
                        context,
                        'en',
                        AppLocalizations.of(context)!.english,
                        currentLang,
                        colors,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (mounted) {
      setState(() => _isLanguageMenuOpen = false);
    }

    if (result != null && result != currentLang) {
      ref.read(localeProvider.notifier).setLanguage(result);
    }
  }

  Widget _buildLanguageMenuItem(
    BuildContext context,
    String value,
    String label,
    String currentLang,
    LyraColors colors,
  ) {
    final isSelected = value == currentLang;

    // Bungkus dengan Material agar efek ripple/abu-abu muncul
    return Material(
      color:
          Colors.transparent, // Warna transparan agar tetap ikut warna popover
      borderRadius: BorderRadius.circular(12),
      clipBehavior:
          Clip.antiAlias, // Agar ripple tidak keluar dari sudut melengkung
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        borderRadius: BorderRadius.circular(12),
        splashColor: colors.textPrimary.withValues(
          alpha: 0.1,
        ), // Warna abu-abu/efek ketukan
        highlightColor: colors.textPrimary.withValues(
          alpha: 0.05,
        ), // Efek saat ditahan
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check, color: colors.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showThemeMenu(BuildContext context, WidgetRef ref) async {
    final currentMode = ref.read(themeModeProvider);

    final RenderBox? button =
        _themeItemKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);

    setState(() => _isThemeMenuOpen = true);

    final result = await showGeneralDialog<ThemeMode>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Theme Menu',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        final colors = context.lyra;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(context)!;

        return Stack(
          children: [
            Positioned(
              top: buttonPosition.dy + button.size.height - 12,
              right:
                  overlay.size.width -
                  buttonPosition.dx -
                  button.size.width +
                  4,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.textSecondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildThemeMenuItem(
                        context,
                        ThemeMode.system,
                        l10n.systemDefault,
                        currentMode,
                        colors,
                      ),
                      Divider(
                        color: colors.textSecondary.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      _buildThemeMenuItem(
                        context,
                        ThemeMode.light,
                        l10n.light,
                        currentMode,
                        colors,
                      ),
                      Divider(
                        color: colors.textSecondary.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      _buildThemeMenuItem(
                        context,
                        ThemeMode.dark,
                        l10n.dark,
                        currentMode,
                        colors,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (mounted) setState(() => _isThemeMenuOpen = false);

    if (result != null && result != currentMode) {
      ref.read(themeModeProvider.notifier).setTheme(result);
    }
  }

  Widget _buildThemeMenuItem(
    BuildContext context,
    ThemeMode value,
    String label,
    ThemeMode currentMode,
    LyraColors colors,
  ) {
    final isSelected = value == currentMode;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        borderRadius: BorderRadius.circular(12),
        splashColor: colors.textPrimary.withValues(alpha: 0.1),
        highlightColor: colors.textPrimary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check, color: colors.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context)!;

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
                // TAMPILAN
                _buildSectionTitle(l10n.display, colors),
                _buildSettingsGroup(
                  colors: colors,
                  isDark: isDark,
                  children: [
                    GestureDetector(
                      key: _themeItemKey,
                      onTap: () => _showThemeMenu(context, ref),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.palette_outlined,
                                color: colors.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.theme,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    themeMode == ThemeMode.system
                                        ? l10n.systemDefault
                                        : themeMode == ThemeMode.light
                                        ? l10n.light
                                        : l10n.dark,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedRotation(
                              turns: _isThemeMenuOpen ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: colors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildDivider(colors),
                    GestureDetector(
                      key: _languageItemKey,
                      onTap: () => _showLanguageMenu(context, ref),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Ikon
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.language,
                                color: colors.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Label & Subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.language,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getLanguageName(context, ref),
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Chevron Animasi
                            AnimatedRotation(
                              turns: _isLanguageMenuOpen ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: colors.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // AUDIO & PEMUTARAN
                _buildSectionTitle(l10n.audioPlayback, colors),
                _buildSettingsGroup(
                  colors: colors,
                  isDark: isDark,
                  children: [
                    _buildArrowTile(
                      icon: Icons.equalizer,
                      title: l10n.systemEqualizer,
                      onTap: () async {
                        try {
                          await MediaStoreService.openEqualizer();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // PENGATURAN PERANGKAT
                _buildSectionTitle(l10n.deviceSettings, colors),
                _buildSettingsGroup(
                  colors: colors,
                  isDark: isDark,
                  children: [
                    _buildArrowTile(
                      icon: Icons.notifications_active_outlined,
                      title: l10n.lyraNotification,
                      onTap: () => openAppSettings(),
                      colors: colors,
                    ),
                    _buildDivider(colors),
                    _buildArrowTile(
                      icon: Icons.android,
                      title: l10n.appPermissions,
                      onTap: () => openAppSettings(),
                      colors: colors,
                    ),
                    _buildDivider(colors),
                    _buildArrowTile(
                      icon: Icons.battery_charging_full_outlined,
                      title: l10n.battery,
                      onTap: () async {
                        try {
                          await MediaStoreService.openBatterySettings();
                        } catch (e) {
                          openAppSettings();
                        }
                      },
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // PENYIMPANAN
                _buildSectionTitle(l10n.storage, colors),
                _buildSettingsGroup(
                  colors: colors,
                  isDark: isDark,
                  children: [
                    _buildArrowTile(
                      icon: Icons.storage_outlined,
                      title: l10n.storageUsage,
                      subtitle: l10n.cacheSize(_cacheSize),
                      onTap: () {},
                      showArrow: false,
                      colors: colors,
                    ),
                    _buildDivider(colors),
                    _buildArrowTile(
                      icon: Icons.cleaning_services_outlined,
                      title: l10n.clearCache,
                      onTap: _clearCache,
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // TENTANG APLIKASI
                _buildSectionTitle(l10n.others, colors),
                _buildSettingsGroup(
                  colors: colors,
                  isDark: isDark,
                  children: [
                    _buildArrowTile(
                      icon: Icons.info_outline,
                      title: l10n.appVersion,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutPage()),
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
                        l10n.settings,
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

  // HELPER WIDGETS
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

  Widget _buildArrowTile({
    required IconData icon,
    required String title,
    String? subtitle,
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
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            )
          : null,
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
