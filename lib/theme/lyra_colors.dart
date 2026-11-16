import 'package:flutter/material.dart';

class LyraColors extends ThemeExtension<LyraColors> {
  final Color pageBackground;
  final Color glassTintTop;
  final Color glassTintBottom;
  final Color glassBorderTop;
  final Color glassBorderBottom;
  final Color glassShadow;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  const LyraColors({
    required this.pageBackground,
    required this.glassTintTop,
    required this.glassTintBottom,
    required this.glassBorderTop,
    required this.glassBorderBottom,
    required this.glassShadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });

  static const light = LyraColors(
    pageBackground: Color(0xFFF2F2F7),
    glassTintTop: Color(0x9EFFFFFF),
    glassTintBottom: Color(0x7AFFFFFF),
    glassBorderTop: Color(0x1AFFFFFF),
    glassBorderBottom: Color(0x338E8E93),
    glassShadow: Color(0x24000000),
    textPrimary: Color(0xDE000000),
    textSecondary: Color(0x8A000000),
    accent: Color(0xFF0A84FF),
  );

  static const dark = LyraColors(
    pageBackground: Color(0xFF000000),
    glassTintTop: Color(0xB32C2C2E),
    glassTintBottom: Color(0x991C1C1E),
    // Turunkan juga di dark mode dari 0x24 menjadi 0x14
    glassBorderTop: Color(0x14FFFFFF),
    glassBorderBottom: Color(0x0AFFFFFF),
    glassShadow: Colors.transparent,
    textPrimary: Color(0xEBFFFFFF),
    textSecondary: Color(0x99FFFFFF),
    accent: Color(0xFF64B5FF),
  );

  @override
  ThemeExtension<LyraColors> copyWith() => this;

  @override
  ThemeExtension<LyraColors> lerp(ThemeExtension<LyraColors>? other, double t) {
    if (other is! LyraColors) return this;
    return LyraColors(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      glassTintTop: Color.lerp(glassTintTop, other.glassTintTop, t)!,
      glassTintBottom: Color.lerp(glassTintBottom, other.glassTintBottom, t)!,
      glassBorderTop: Color.lerp(glassBorderTop, other.glassBorderTop, t)!,
      glassBorderBottom: Color.lerp(
        glassBorderBottom,
        other.glassBorderBottom,
        t,
      )!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension LyraColorsContext on BuildContext {
  LyraColors get lyra => Theme.of(this).extension<LyraColors>()!;
}
