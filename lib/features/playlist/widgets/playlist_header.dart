import 'dart:io';
import 'package:flutter/material.dart';
import 'playlist_cover.dart';

class PlaylistHeader extends StatefulWidget {
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
  State<PlaylistHeader> createState() => _PlaylistHeaderState();
}

class _PlaylistHeaderState extends State<PlaylistHeader> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  ImageInfo? _pinnedImageInfo;
  bool _hasError = false;

  bool get _hasImagePath =>
      widget.imagePath != null && widget.imagePath!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _resolveHeaderImage();
  }

  @override
  void didUpdateWidget(covariant PlaylistHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _resolveHeaderImage();
    }
  }

  @override
  void dispose() {
    _clearImageListener();
    _pinnedImageInfo?.dispose();
    _pinnedImageInfo = null;
    super.dispose();
  }

  void _clearImageListener() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageStream = null;
    _imageListener = null;
  }

  void _resolveHeaderImage() {
    _clearImageListener();
    _pinnedImageInfo?.dispose();
    _pinnedImageInfo = null;
    _hasError = false;

    if (!_hasImagePath) return;

    // Kunci hasil decode gambar header di state agar tidak tergusur oleh
    // ImageCache saat user men-scroll daftar lagu yang sangat panjang.
    final provider = ResizeImage(
      FileImage(File(widget.imagePath!)),
      width: 800,
    );
    final stream = provider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (!mounted) {
          info.dispose();
          return;
        }
        final cloned = info.clone();
        if (synchronousCall) {
          _pinnedImageInfo?.dispose();
          _pinnedImageInfo = cloned;
          _hasError = false;
        } else {
          setState(() {
            _pinnedImageInfo?.dispose();
            _pinnedImageInfo = cloned;
            _hasError = false;
          });
        }
      },
      onError: (Object exception, StackTrace? stackTrace) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
        });
      },
    );
    _imageStream = stream;
    _imageListener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final Widget coverWidget;
    if (_hasImagePath && !_hasError) {
      if (_pinnedImageInfo != null) {
        coverWidget = RawImage(
          image: _pinnedImageInfo!.image,
          fit: BoxFit.cover,
        );
      } else {
        coverWidget = const ColoredBox(color: Color(0xFF292824));
      }
    } else {
      coverWidget = PlaylistCover(
        playlistId: widget.playlistId,
        imagePath: null,
        iconSize: 96,
        artSize: 500,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        coverWidget,

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
          left: 16,
          right: 24,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.playlistName,
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
              if (widget.description != null &&
                  widget.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  widget.description!,
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
}
