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
        if (leftWidget != null)
          Flexible(child: _buildSmartContainer(leftWidget!))
        else
          const SizedBox(width: 48),
        if (rightWidget != null)
          Flexible(child: _buildSmartContainer(rightWidget!))
        else
          const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildSmartContainer(Widget child) {
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
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

// WIDGET BAKU: Digunakan di SEMUA halaman untuk Kapsul & Lingkaran
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
    this.isCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: isCircle ? 48 : null,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: isCircle
            ? const CircleBorder()
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: isCircle
              ? const CircleBorder()
              : RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
