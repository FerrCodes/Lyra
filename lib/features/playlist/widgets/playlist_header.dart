import 'dart:io';
import 'package:flutter/material.dart';

class PlaylistHeader extends StatelessWidget {
  final String? imagePath;
  final String playlistName;
  final int songCount;
  final String? description;
  final int playlistId;

  const PlaylistHeader({
    super.key,
    required this.imagePath,
    required this.playlistName,
    required this.songCount,
    this.description,
    required this.playlistId,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.trim().isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          Hero(
            tag: 'playlist_image_$playlistId',
            child: Image.file(
              File(imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackBackground(),
            ),
          )
        else
          _buildFallbackBackground(),

        // Menjaga judul dan deskripsi tetap terbaca di atas foto.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.47),
                Colors.black.withValues(alpha: 0.95),
              ],
              stops: const [0.0, 0.6, 0.85, 1.0],
            ),
          ),
        ),

        Positioned(
          left: 24,
          right: 24,
          bottom: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                playlistName,
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.04,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  shadows: [
                    Shadow(
                      color: Color(0x55000000),
                      blurRadius: 16,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (description != null && description!.trim().isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  description!,
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF77736C), Color(0xFF292824)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.album_rounded, size: 86, color: Color(0x66FFFFFF)),
      ),
    );
  }
}
