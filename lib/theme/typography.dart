import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Type roles:
///  - display: soft serif, for names and headings
///  - body: humanist sans, for lists and reading
///  - readout: the same sans with even-width digits, for durations and counts
///  - note: handwriting, only for notes written by hand
///  - trackTitle: the serif again, for the song name on Now Playing
///  - goldLabel: small gold sans, for sublines and card labels
///  - caption: smallest muted sans, for nav labels and fine print
///  - label: small cream sans, for chips and folder tiles
///
/// Fonts ship in assets/google_fonts and are never fetched from the network,
/// so only the bundled weights may be requested here:
/// Fraunces 400 and 500, Inter 400, 500 and 600, Caveat 500.
class AppType {
  AppType._();

  static TextStyle display = GoogleFonts.fraunces(
    fontWeight: FontWeight.w400,
    fontSize: 26,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static TextStyle sectionLabel = GoogleFonts.fraunces(
    fontWeight: FontWeight.w500,
    fontSize: 15,
    letterSpacing: 0.3,
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

  static TextStyle readout = GoogleFonts.inter(
    fontWeight: FontWeight.w500,
    fontSize: 12,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle readoutAccent = GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: 12,
    color: AppColors.accent,
    letterSpacing: 0.2,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Handwriting for notes written by hand.
  static TextStyle note = GoogleFonts.caveat(
    fontWeight: FontWeight.w500,
    fontSize: 20,
    color: AppColors.gold,
    height: 1.25,
  );

  static TextStyle trackTitle = GoogleFonts.fraunces(
    fontWeight: FontWeight.w400,
    fontSize: 20,
    color: AppColors.textPrimary,
  );

  static TextStyle goldLabel = GoogleFonts.inter(
    fontWeight: FontWeight.w500,
    fontSize: 12,
    color: AppColors.gold,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  static TextStyle label = GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    color: AppColors.textPrimary,
  );
}
