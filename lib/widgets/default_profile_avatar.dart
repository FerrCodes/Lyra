import 'package:flutter/material.dart';

class DefaultProfileAvatar extends StatelessWidget {
  final double size;

  const DefaultProfileAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Gradasi ungu yang mirip dengan gambar referensi
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6A11CB), // Ungu kebiruan
            Color(0xFF2575FC), // Biru terang
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.person, color: Colors.white, size: size * 0.6),
    );
  }
}
