import 'package:flutter/material.dart';

class LyraHeader extends StatelessWidget {
  final Widget? leftWidget;
  final Widget? rightWidget;
  final bool isDarkMode;

  const LyraHeader({
    super.key,
    this.leftWidget,
    this.rightWidget,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Bagian Kiri
        if (leftWidget != null)
          Flexible(child: _buildSmartContainer(leftWidget!))
        else
          const SizedBox(width: 48),

        // Bagian Kanan
        if (rightWidget != null)
          Flexible(child: _buildSmartContainer(rightWidget!))
        else
          const SizedBox(width: 48),
      ],
    );
  }

  // Fungsi pintar untuk mendeteksi jumlah tombol (Kiri & Kanan)
  Widget _buildSmartContainer(Widget child) {
    // Jika isinya berupa Row (lebih dari 1 tombol), jadikan Kapsul
    if (child is Row) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: child,
        ),
      );
    }

    // Jika hanya 1 widget (seperti Avatar), jadikan Lingkaran
    return Container(
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
      child: child,
    );
  }
}

// Komponen Tombol Ikon khusus untuk dipakai di dalam LyraHeader
class LyraHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const LyraHeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: iconColor, size: 20),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// Widget Tombol Top Bar dengan Efek Ripple (Splash) yang Rapi
class TopBarButton extends StatelessWidget {
  final IconData? icon;
  final Widget? customChild;
  final VoidCallback onTap;
  final bool isCircle;

  const TopBarButton({
    super.key,
    this.icon,
    this.customChild,
    required this.onTap,
    this.isCircle = true, // Default: Lingkaran. Jika false: Kapsul
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: isCircle
          ? const CircleBorder()
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      clipBehavior:
          Clip.antiAlias, // Memotong efek ripple agar rapi di dalam bentuk
      child: InkWell(
        onTap: onTap,
        // Di dalam TopBarButton
        child: Container(
          height: 48,
          width: isCircle ? 48 : null,
          padding: isCircle ? null : const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: customChild ?? Icon(icon, color: Colors.black, size: 20),
          ),
        ),
      ),
    );
  }
}
