import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart' as local;
import '../providers/songs_provider.dart';
import '../services/media_store_service.dart';
import '../theme/lyra_colors.dart';

class EditMetadataSheet extends ConsumerStatefulWidget {
  final local.Song song;

  const EditMetadataSheet({super.key, required this.song});

  @override
  ConsumerState<EditMetadataSheet> createState() => _EditMetadataSheetState();
}

class _EditMetadataSheetState extends ConsumerState<EditMetadataSheet> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _albumArtistController;
  late TextEditingController _genreController;
  late TextEditingController _trackController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist);
    _albumController = TextEditingController(text: widget.song.album);
    _albumArtistController = TextEditingController();
    _genreController = TextEditingController();
    _trackController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _albumArtistController.dispose();
    _genreController.dispose();
    _trackController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await MediaStoreService.updateSongMetadata(
        id: widget.song.id,
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        album: _albumController.text.trim(),
        albumArtist: _albumArtistController.text.trim(),
        genre: _genreController.text.trim(),
        track: _trackController.text.trim(),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      // Refresh daftar lagu agar perubahan langsung terlihat
      ref.invalidate(allSongsProvider);

      if (mounted) {
        Navigator.pop(context); // Tutup sheet jika berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metadata berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.lyra;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Form Scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdownField(
                      'Encoding type',
                      'Unicode (UTF-16)',
                      colors,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Title',
                      _titleController,
                      colors,
                      showRemove: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Artist',
                      _artistController,
                      colors,
                      showRemove: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Album',
                      _albumController,
                      colors,
                      showRemove: true,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Album artist',
                      _albumArtistController,
                      colors,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Genre', _genreController, colors),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Track number',
                      _trackController,
                      colors,
                      isNumber: true,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Footer Buttons (Cancel & Save)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: colors.textSecondary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _save,
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color: colors.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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

  // Widget TextField dengan garis biru & tombol minus
  Widget _buildTextField(
    String label,
    TextEditingController controller,
    LyraColors colors, {
    bool showRemove = false,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.accent, fontSize: 13)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: isNumber
                    ? TextInputType.number
                    : TextInputType.text,
                style: TextStyle(color: colors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: colors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.accent),
                  ),
                ),
              ),
            ),
            if (showRemove) ...[
              const SizedBox(width: 12),
              Icon(Icons.remove, color: Colors.redAccent, size: 20),
            ] else ...[
              const SizedBox(width: 12),
              Icon(Icons.add, color: Colors.green, size: 20),
            ],
          ],
        ),
      ],
    );
  }

  // Widget Dropdown tiruan
  Widget _buildDropdownField(String label, String value, LyraColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.accent, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: TextStyle(color: colors.textSecondary, fontSize: 16),
            ),
            Icon(Icons.arrow_drop_down, color: colors.textSecondary),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: colors.textSecondary.withValues(alpha: 0.5), height: 1),
      ],
    );
  }
}
