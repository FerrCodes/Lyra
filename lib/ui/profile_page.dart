import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/glass_container.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _currentImagePath;
  String? _originalImagePath;
  String _originalName = 'Pengguna Lyra';

  late TextEditingController _nameController;

  static const MethodChannel _platform = MethodChannel('com.lyra/pick_image');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    _nameController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadProfileData();
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
              toolbarColor: const Color(0xFF673AB7),
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

  bool get _hasChanges {
    return _currentImagePath != _originalImagePath ||
        _nameController.text.trim() != _originalName;
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    if (_currentImagePath != _originalImagePath) {
      if (_currentImagePath == null) {
        await removeProfileImage();
      } else {
        await updateProfileImage(_currentImagePath!);
      }
    }

    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != _originalName) {
      await updateProfileName(newName);
    }

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
            // KONTEN UTAMA
            Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 80,
                      bottom: 20,
                      left: 16,
                      right: 16,
                    ),
                    children: [
                      const SizedBox(height: 10),

                      // FOTO PROFIL & INPUT (Sama seperti sebelumnya)
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showPhotoOptions,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 140,
                                    height: 140,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
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
                                        : const DefaultProfileAvatar(size: 110),
                                  ),
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

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: TextField(
                                controller: _nameController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Masukan Nama',
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
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
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Teks LYRA MUSIC dengan Efek Kaca
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      radius: 20,
                      child: Text(
                        'LYRA MUSIC',
                        style: TextStyle(
                          fontFamily: 'LyraFont',
                          fontSize: 18,
                          letterSpacing: -0.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      '© 2026 Lyra. All rights reserved.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ],
            ),

            // OVERLAY GRADASI PUTIH (Sekarang aman di luar ListView)
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
                    onTap: _hasChanges ? _saveChanges : null,
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
                            : Colors.grey.shade300,
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
                _buildPhotoOption(
                  icon: Icons.add_photo_alternate,
                  label: 'Ambil dari Galeri',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                _buildPhotoOption(
                  icon: Icons.delete_outline,
                  label: 'Hapus Foto',
                  iconColor: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentImagePath = null;
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
}
