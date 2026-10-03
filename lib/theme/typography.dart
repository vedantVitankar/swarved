import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Type roles:
///  - display: condensed grotesque, stamped/tape-label energy (headers)
///  - body: humanist sans, for lists and reading
///  - readout: functional monospace — durations, counts, timestamps
class AppType {
  AppType._();

  static TextStyle display = GoogleFonts.archivoBlack(
    fontWeight: FontWeight.w700,
    fontSize: 28,
    letterSpacing: 0.2,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static TextStyle sectionLabel = GoogleFonts.archivoBlack(
    fontWeight: FontWeight.w700,
    fontSize: 13,
    letterSpacing: 0.6,
    color: AppColors.textSecondary,
  );

  static TextStyle titleMedium = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMuted = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static TextStyle readout = GoogleFonts.jetBrainsMono(
    fontWeight: FontWeight.w500,
    fontSize: 12,
    color: AppColors.textSecondary,
    letterSpacing: 0.4,
  );

  static TextStyle readoutAccent = GoogleFonts.jetBrainsMono(
    fontWeight: FontWeight.w600,
    fontSize: 12,
    color: AppColors.accent,
    letterSpacing: 0.4,
  );
}
