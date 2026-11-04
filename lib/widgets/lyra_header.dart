import 'package:flutter/material.dart';

class LyraHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? rightWidget;
  final Widget? leftWidget;

  const LyraHeader({
    super.key,
    required this.title,
    this.onBack,
    this.rightWidget,
    this.leftWidget,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle = title.trim().isNotEmpty;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Row(
        children: [
          // Tombol Kiri
          if (onBack != null)
            _buildPillButton(Icons.arrow_back_ios_new, onBack!)
          else if (leftWidget != null)
            leftWidget!
          else if (hasTitle)
            const SizedBox(width: 48),

          // Judul Tengah (Hanya muncul jika title tidak kosong)
          if (hasTitle)
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            )
          else
            const Spacer(),

          // Tombol Kanan
          if (rightWidget != null)
            rightWidget!
          else if (hasTitle)
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPillButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, color: Colors.black, size: 20),
      ),
    );
  }
}
