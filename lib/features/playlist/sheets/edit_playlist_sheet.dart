import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import '../../../database/database.dart';
import '../../../providers/database_provider.dart';
import 'package:flutter/services.dart';

class EditPlaylistSheet extends ConsumerStatefulWidget {
  final Playlist playlist;
  final String currentName;
  final String? currentDescription;
  final String? currentImagePath;

  const EditPlaylistSheet({
    super.key,
    required this.playlist,
    required this.currentName,
    this.currentDescription,
    this.currentImagePath,
  });

  @override
  ConsumerState<EditPlaylistSheet> createState() => _EditPlaylistSheetState();
}

class _EditPlaylistSheetState extends ConsumerState<EditPlaylistSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  String? _tempImagePath;
  static const MethodChannel _platform = MethodChannel('com.lyra/pick_image');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _descController = TextEditingController(
      text: widget.currentDescription ?? '',
    );
    _tempImagePath = widget.currentImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<String> _saveImagePermanently(String tempPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'playlist_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final permanentFile = File('${directory.path}/$fileName');
    final savedFile = await File(tempPath).copy(permanentFile.path);
    return savedFile.path;
  }

  void _pickImageSource() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ganti Foto Playlist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // OPSI GALERI
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          final String? imagePath = await _platform
                              .invokeMethod('pickImage');
                          if (imagePath != null) {
                            final croppedFile = await ImageCropper().cropImage(
                              sourcePath: imagePath,
                              aspectRatio: const CropAspectRatio(
                                ratioX: 1,
                                ratioY: 1,
                              ),
                              uiSettings: [
                                AndroidUiSettings(
                                  toolbarTitle: 'Potong Foto',
                                  toolbarColor: const Color(0xFF673AB7),
                                  toolbarWidgetColor: Colors.white,
                                  initAspectRatio: CropAspectRatioPreset.square,
                                  lockAspectRatio: true,
                                  hideBottomControls: true,
                                ),
                              ],
                            );
                            if (croppedFile != null) {
                              final permanentPath = await _saveImagePermanently(
                                croppedFile.path,
                              );
                              setState(() => _tempImagePath = permanentPath);
                            }
                          }
                        } catch (e) {
                          print("Error: $e");
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF673AB7,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.wallpaper_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Galeri',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // OPSI KAMERA
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (image != null) {
                          final croppedFile = await ImageCropper().cropImage(
                            sourcePath: image.path,
                            aspectRatio: const CropAspectRatio(
                              ratioX: 1,
                              ratioY: 1,
                            ),
                            uiSettings: [
                              AndroidUiSettings(
                                toolbarTitle: 'Potong Foto',
                                toolbarColor: const Color(0xFF673AB7),
                                toolbarWidgetColor: Colors.white,
                                initAspectRatio: CropAspectRatioPreset.square,
                                lockAspectRatio: true,
                                hideBottomControls: true,
                              ),
                            ],
                          );
                          if (croppedFile != null) {
                            final permanentPath = await _saveImagePermanently(
                              croppedFile.path,
                            );
                            setState(() => _tempImagePath = permanentPath);
                          }
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.black54,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Kamera',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _savePlaylist() async {
    if (_nameController.text.trim().isEmpty) return;
    final db = ref.read(databaseProvider);

    final newName = _nameController.text.trim();
    final newDescription = _descController.text.trim().isEmpty
        ? null
        : _descController.text.trim();

    await (db.update(
      db.playlists,
    )..where((t) => t.id.equals(widget.playlist.id))).write(
      PlaylistsCompanion(
        name: drift.Value(newName),
        imagePath: drift.Value(_tempImagePath),
        description: drift.Value(newDescription),
      ),
    );

    if (mounted) {
      // KIRIM DATA BARU KEMBALI KE HALAMAN UTAMA
      Navigator.pop(context, {
        'name': newName,
        'description': newDescription,
        'imagePath': _tempImagePath,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32.0,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Playlist',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // AREA GAMBAR
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _tempImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              File(_tempImagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image, size: 60, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: _pickImageSource,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // INPUT NAMA
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Playlist',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // INPUT DESKRIPSI
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _savePlaylist,
                  child: const Text(
                    'Simpan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
