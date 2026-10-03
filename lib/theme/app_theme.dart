import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.base,
      canvasColor: AppColors.base,
      primaryColor: AppColors.accent,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.meter,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      dividerColor: AppColors.hairline,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.hairline,
        thumbColor: AppColors.accent,
        trackHeight: 2,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
    );
  }
}
