import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_page.dart';

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  bool _isPermissionGranted = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Fungsi ini akan terpanggil otomatis saat user kembali dari halaman Settings HP
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    // Cek status izin audio
    var status = await Permission.audio.status;

    // Jika di Android versi lama, cek juga izin storage
    if (!status.isGranted) {
      status = await Permission.storage.status;
    }

    if (mounted) {
      setState(() {
        _isPermissionGranted = status.isGranted;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Sedang mengecek (Loading)
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F2F7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Jika Izin Diberikan, Tampilkan Halaman Utama
    if (_isPermissionGranted) {
      return const HomePage();
    }

    // 3. Jika Izin Ditolak, Tampilkan Layar Gerbang Izin
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        // <--- 1. Bungkus dengan SafeArea
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Ikon besar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_off,
                    size: 80,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 32),

                // Teks Penjelasan
                const Text(
                  'Izin Diperlukan!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lyra membutuhkan izin akses "Music and Audio" untuk bisa memindai dan memutar lagu di perangkatmu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Tombol Buka Pengaturan
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    label: const Text(
                      'Buka Halaman Info Aplikasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      // Buka halaman settings aplikasi di HP
                      await openAppSettings();
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Tombol Coba Lagi (Jika user sudah kasih izin tapi aplikasi belum mendeteksi)
                TextButton(
                  onPressed: _checkPermission,
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
