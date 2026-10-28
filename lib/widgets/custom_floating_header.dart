import 'package:flutter/material.dart';

class CustomFloatingHeader extends StatelessWidget {
  final Widget title;
  final VoidCallback? onBack;
  final Widget? rightWidget;

  const CustomFloatingHeader({
    super.key,
    required this.title,
    this.onBack,
    this.rightWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null)
            FloatingHeaderAction(icon: Icons.arrow_back_ios_new, onTap: onBack!)
          else
            const SizedBox(width: 48),

          Expanded(child: Center(child: title)),

          if (rightWidget != null) rightWidget! else const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// Widget Tombol Bulat/Pill Standar
class FloatingHeaderAction extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final String? label;
  final Color? labelColor;
  final VoidCallback onTap;

  const FloatingHeaderAction({
    super.key,
    this.icon,
    this.customIcon,
    this.label,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLabeled = label != null;

    // Menggunakan warna terang (light) agar menyatu dengan halaman
    final bgColor = Theme.of(context).colorScheme.surface;
    final iconColor = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: isLabeled ? null : 48,
        padding: isLabeled ? const EdgeInsets.symmetric(horizontal: 16) : null,
        decoration: BoxDecoration(
          color: bgColor, // Warna Light
          shape: isLabeled ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: isLabeled ? BorderRadius.circular(20) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.15,
              ), // Shadow dikembalikan
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: isLabeled
              ? Text(
                  label!,
                  style: TextStyle(
                    color: labelColor ?? iconColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : (customIcon ??
                    Icon(icon, color: iconColor, size: 20)), // Warna Ikon Light
        ),
      ),
    );
  }
}

// Widget Pill Judul Standar
class HeaderTitlePill extends StatelessWidget {
  final Widget child;
  const HeaderTitlePill({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor, // Warna Light
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15), // Shadow dikembalikan
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
