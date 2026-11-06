import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/database_provider.dart';
import '../providers/songs_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/default_profile_avatar.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  int _totalFavorites = 0;
  int _totalPlaylists = 0;

  String? _currentImagePath;
  String? _originalImagePath;
  String _originalName = 'Pengguna Lyra';

  late TextEditingController _nameController;

  static const MethodChannel _platform = MethodChannel('com.lyra/pick_image');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    // Listener: Setiap kali user mengetik, layar akan dirender ulang
    // untuk mengecek apakah tombol centang harus menyala
    _nameController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadProfileData();
    _loadStats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _originalImagePath = prefs.getString('profile_image');
        _currentImagePath = _originalImagePath;

        _originalName = prefs.getString('profile_name') ?? 'Pengguna Lyra';
        _nameController.text = _originalName;
      });
    }
  }

  Future<void> _loadStats() async {
    final db = ref.read(databaseProvider);
    final favs = await db.getAllFavoriteSongs();
    final playlists = await db.select(db.playlists).get();

    if (mounted) {
      setState(() {
        _totalFavorites = favs.length;
        _totalPlaylists = playlists.length;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final String? imagePath = await _platform.invokeMethod('pickImage');

      if (imagePath != null && imagePath.isNotEmpty) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: imagePath,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Potong Foto Profil',
              toolbarColor: const Color(0xFF673AB7), // Warna ungu Lyra
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: true,
              cropStyle: CropStyle.circle,
            ),
          ],
        );

        if (croppedFile != null) {
          final permanentPath = await _saveImagePermanently(croppedFile.path);

          if (mounted) {
            setState(() {
              _currentImagePath = permanentPath;
            });
          }
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: ${e.message}')),
        );
      }
    }
  }

  Future<String> _saveImagePermanently(String tempPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'profile_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final permanentFile = File('${directory.path}/$fileName');
    final savedFile = await File(tempPath).copy(permanentFile.path);
    return savedFile.path;
  }

  // Fungsi untuk mengecek apakah ada perubahan
  bool get _hasChanges {
    return _currentImagePath != _originalImagePath ||
        _nameController.text.trim() != _originalName;
  }

  // Fungsi untuk menyimpan semua perubahan
  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    // Simpan gambar jika ada perubahan
    if (_currentImagePath != _originalImagePath) {
      if (_currentImagePath == null) {
        // Jika dihapus, hapus dari SharedPreferences dan jembatan
        await removeProfileImage();
      } else {
        // Jika diganti, simpan gambar baru
        await updateProfileImage(_currentImagePath!);
      }
    }

    // Simpan nama jika ada perubahan
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != _originalName) {
      await updateProfileName(newName);
    }

    // Perbarui state original agar tombol centang jadi abu-abu lagi
    setState(() {
      _originalImagePath = _currentImagePath;
      _originalName = newName;
    });

    FocusScope.of(context).unfocus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageColor = Color(0xFFF2F2F7);
    final allSongsAsync = ref.watch(allSongsProvider);
    final totalSongs = allSongsAsync.value?.length ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: pageColor,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: pageColor,
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
                const SizedBox(height: 10),

                // FOTO PROFIL
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // Hapus gradient lama karena sudah dipindah ke widget
                              ),
                              child: _currentImagePath != null
                                  ? ClipOval(
                                      child: Image.file(
                                        File(_currentImagePath!),
                                        fit: BoxFit.cover,
                                        width: 110,
                                        height: 110,
                                      ),
                                    )
                                  // Gunakan widget default jika kosong
                                  : const DefaultProfileAvatar(size: 110),
                            ),
                            // Ikon Kamera Kecil di Ujung Avatar
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.black87,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // INPUT NAMA (Dengan Efek Floating Label)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextField(
                          controller: _nameController,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Nama Pengguna',
                            labelStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                            filled: true,
                            fillColor: const Color(
                              0xFFF2F2F2,
                            ), // Warna abu pudar
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              color: Colors.grey,
                              size: 24,
                            ),

                            // Garis pinggir dihilangkan
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Text(
                        'Penikmat Musik Lokal',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // STATISTIK CARD
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(totalSongs.toString(), 'Lagu'),
                        _buildStatDivider(),
                        _buildStatItem(_totalPlaylists.toString(), 'Playlist'),
                        _buildStatDivider(),
                        _buildStatItem(_totalFavorites.toString(), 'Favorit'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // MENU PROFIL
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildListTile(
                          icon: Icons.history,
                          title: 'Riwayat Pemutaran',
                          onTap: () {},
                        ),
                        const Divider(height: 1, thickness: 0.5, indent: 60),
                        _buildListTile(
                          icon: Icons.star_outline,
                          title: 'Lagu Favorit',
                          onTap: () {},
                        ),
                        const Divider(height: 1, thickness: 0.5, indent: 60),
                        _buildListTile(
                          icon: Icons.download_outlined,
                          title: 'Lagu yang Diunduh',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // TOMBOL HAPUS DATA
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildListTile(
                      icon: Icons.delete_outline,
                      title: 'Hapus Data Lokal',
                      textColor: Colors.redAccent,
                      iconColor: Colors.redAccent,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur Hapus Data segera hadir'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            // OVERLAY GRADASI PUTIH
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

            // TOP BAR
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

                  const Expanded(
                    child: Center(
                      child: Text(
                        'Profil',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: _hasChanges
                        ? _saveChanges
                        : null, // Hanya aktif jika ada perubahan
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
                      child: Icon(
                        Icons.check,
                        color: _hasChanges
                            ? Colors.black
                            : Colors
                                  .grey
                                  .shade300, // Hitam jika berubah, abu-abu jika tidak
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menampilkan bottom sheet pilihan foto
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. Pilihan Ambil dari Galeri
                _buildPhotoOption(
                  icon: Icons.add_photo_alternate,
                  label: 'Ambil dari Galeri',
                  onTap: () {
                    Navigator.pop(context); // Tutup bottom sheet dulu
                    _pickImage(); // Panggil fungsi Kotlin untuk buka galeri
                  },
                ),

                // 2. Pilihan Hapus Foto
                _buildPhotoOption(
                  icon: Icons.delete_outline,
                  label: 'Hapus Foto',
                  iconColor: Colors.redAccent, // Beri warna merah untuk hapus
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentImagePath = null; // Set foto jadi kosong
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget bantuan untuk tombol di dalam bottom sheet
  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.shade200);
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.black87).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? Colors.black87, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: textColor ?? Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey.shade400,
        size: 16,
      ),
    );
  }
}
