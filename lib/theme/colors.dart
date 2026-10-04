import 'package:flutter/material.dart';

/// Token palette: deep maroon and wine, rose as the single accent, and
/// sunlight gold kept for the things that are Swarnima's own.
class AppColors {
  AppColors._();

  // Surfaces, darkest to lightest.
  static const Color base = Color(0xFF1A0A10); // midnight maroon
  static const Color surface = Color(0xFF2A0F18); // wine night
  static const Color surfaceRaised = Color(0xFF3A1522); // velvet
  static const Color hairline = Color(0xFF4A2230);

  // Text.
  static const Color textPrimary = Color(0xFFFBF0E6); // cream
  static const Color textSecondary = Color(0xFFCDB0B2);
  static const Color textFaint = Color(0xFF9A7B80);

  // Deep brand colors, for artwork and selected states.
  static const Color maroon = Color(0xFF6B1B2E);
  static const Color wine = Color(0xFF8C2A40);
  static const Color rosewood =
      Color(0xFFB8394F); // artwork gradients, name accents

  /// Primary accent: dusty rose.
  static const Color accent = Color(0xFFE8A3AE);
  static const Color accentDim = wine;
  static const Color blush = Color(0xFFF3CFD3);
  static const Color onAccent =
      Color(0xFF3A1020); // text on rose chips and buttons

  /// Sunlight gold. Swarnima means sunlight, so gold is saved for notes,
  /// dedications and the waveform.
  static const Color gold = Color(0xFFE2B659);
  static const Color goldLight = Color(0xFFF1D48F); // sun highlight in artwork

  /// Reserved strictly for waveform / visualizer elements.
  static const Color meter = gold;

  static const Color danger = Color(0xFFE06B5E);
}
