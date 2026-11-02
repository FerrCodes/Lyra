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
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. FOTO / GAMBAR PLAYLIST
        imagePath != null
            ? Hero(
                tag: 'playlist_image_$playlistId',
                child: Image.file(File(imagePath!), fit: BoxFit.cover),
              )
            : Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.image, size: 80, color: Colors.grey),
              ),

        // 2. GRADIENT OVERLAY
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // 3. TEKS (NAMA, JUMLAH LAGU, DESKRIPSI)
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Text(
                playlistName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$songCount tracks',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
