import 'package:flutter/material.dart';

/// Token palette for the "personal archive" aesthetic —
/// warm analog accent on a near-black instrument-panel base.
class AppColors {
  AppColors._();

  static const Color base = Color(0xFF0A0A0B);
  static const Color surface = Color(0xFF141416);
  static const Color surfaceRaised = Color(0xFF1B1B1E);
  static const Color hairline = Color(0xFF232326);

  static const Color textPrimary = Color(0xFFEDEDED);
  static const Color textSecondary = Color(0xFF8A8A8E);
  static const Color textFaint = Color(0xFF4E4E52);

  /// Primary accent — warm brass/copper, like an analog dial light.
  static const Color accent = Color(0xFFC97A3D);
  static const Color accentDim = Color(0xFF7A4E28);

  /// Reserved strictly for waveform / visualizer elements.
  static const Color meter = Color(0xFF3D8B8B);

  static const Color danger = Color(0xFFB1503F);
}
