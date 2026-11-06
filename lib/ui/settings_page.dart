import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  bool _isGaplessPlayback = true;

  @override
  Widget build(BuildContext context) {
    const pageColor = Color(0xFFF2F2F7);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // 👈 Ikon status bar hitam
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: pageColor,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: pageColor,
        body: Stack(
          children: [
            // ==========================================
            // KONTEN UTAMA (LIST SETTINGS)
            // ==========================================
            ListView(
              padding: EdgeInsets.only(
                top:
                    MediaQuery.of(context).padding.top +
                    80, // 👈 Jarak aman untuk top bar
                bottom: 40,
                left: 16,
                right: 16,
              ),
              children: [
                // SECTION: TAMPILAN
                _buildSectionTitle('Tampilan'),
                _buildSettingsGroup(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Mode Gelap',
                      subtitle: 'Ubah tema aplikasi menjadi gelap',
                      value: _isDarkMode,
                      onChanged: (val) {
                        setState(() => _isDarkMode = val);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SECTION: AUDIO
                _buildSectionTitle('Audio & Pemutaran'),
                _buildSettingsGroup(
                  children: [
                    _buildSwitchTile(
                      icon: Icons.graphic_eq,
                      title: 'Gapless Playback',
                      subtitle: 'Putar lagu tanpa jeda',
                      value: _isGaplessPlayback,
                      onChanged: (val) {
                        setState(() => _isGaplessPlayback = val);
                      },
                    ),
                    _buildDivider(),
                    _buildArrowTile(
                      icon: Icons.equalizer,
                      title: 'Equalizer',
                      subtitle: 'Atur frekuensi suara',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur Equalizer segera hadir'),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SECTION: PENYIMPANAN
                _buildSectionTitle('Penyimpanan'),
                _buildSettingsGroup(
                  children: [
                    _buildArrowTile(
                      icon: Icons.cleaning_services_outlined,
                      title: 'Hapus Cache',
                      subtitle: 'Kosongkan memori sementara',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cache berhasil dibersihkan'),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // SECTION: TENTANG
                _buildSectionTitle('Tentang Aplikasi'),
                _buildSettingsGroup(
                  children: [
                    _buildArrowTile(
                      icon: Icons.info_outline,
                      title: 'Versi Aplikasi',
                      subtitle: 'Lyra Music v1.0.0',
                      onTap: () {},
                      showArrow: false,
                    ),
                    _buildDivider(),
                    _buildArrowTile(
                      icon: Icons.code,
                      title: 'Open Source Licenses',
                      subtitle: 'Lihat library yang digunakan',
                      onTap: () {
                        showLicensePage(context: context);
                      },
                    ),
                  ],
                ),
              ],
            ),

            // ==========================================
            // OVERLAY GRADASI PUTIH DI TOP BAR
            // ==========================================
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
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.8],
                    ),
                  ),
                ),
              ),
            ),

            // ==========================================
            // TOP BAR (Menggunakan custom melayang)
            // ==========================================
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Tombol Back
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
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
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  // Judul
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Pengaturan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  // Spacer untuk menyeimbangkan agar judul tetap di tengah
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET HELPER UNTUK UI
  // ==========================================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias, // Penting agar sudut melengkungnya rapi
      child: Container(
        decoration: BoxDecoration(
          // Hapus color: Colors.white dari sini
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, indent: 60, endIndent: 16);
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.black,
      ),
    );
  }

  Widget _buildArrowTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: showArrow
          ? const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
          : null,
    );
  }
}
