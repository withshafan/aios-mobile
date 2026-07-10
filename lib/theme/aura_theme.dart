import 'package:flutter/material.dart';
import 'tokens.dart';

class AuraTheme extends ThemeExtension<AuraTheme> {
  final Color bgCanvas;
  final Color surfaceBase;
  final Color surfaceRaised;
  final Color surfaceOverlay;
  final Color borderHairline;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  AuraTheme({
    required this.bgCanvas,
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceOverlay,
    required this.borderHairline,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
  });

  factory AuraTheme.dark() => AuraTheme(
        bgCanvas: AppColors.bgCanvas,
        surfaceBase: AppColors.surfaceBase,
        surfaceRaised: AppColors.surfaceRaised,
        surfaceOverlay: AppColors.surfaceOverlay,
        borderHairline: AppColors.borderHairline,
        borderStrong: AppColors.borderStrong,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        textDisabled: AppColors.textDisabled,
      );

  @override
  ThemeExtension<AuraTheme> copyWith({
    Color? bgCanvas,
    Color? surfaceBase,
    Color? surfaceRaised,
    Color? surfaceOverlay,
    Color? borderHairline,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
  }) {
    return AuraTheme(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      borderHairline: borderHairline ?? this.borderHairline,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
    );
  }

  @override
  ThemeExtension<AuraTheme> lerp(ThemeExtension<AuraTheme>? other, double t) {
    if (other is! AuraTheme) return this;
    return AuraTheme(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      borderHairline: Color.lerp(borderHairline, other.borderHairline, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
    );
  }
}
