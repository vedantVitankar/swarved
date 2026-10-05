/// Pure volume rules — no Flutter, no audio, fully testable on their own.
///
/// Volume is a double in [0.0, 1.0].
/// Mute does not erase the level: it remembers the last non-zero value so
/// unmuting restores exactly where the listener left off.
class VolumeLevel {
  VolumeLevel._();

  static const double min = 0.0;
  static const double max = 1.0;
  static const double defaultLevel = 0.7;

  /// Clamps [raw] to the valid range. Use this on any value coming from
  /// SharedPreferences or a slider so the rest of the app never sees junk.
  static double clamp(double raw) => raw.clamp(min, max);

  /// True when [level] counts as muted (zero or below).
  static bool isMuted(double level) => level <= min;

  /// The level to restore when unmuting. If [remembered] is also zero
  /// (e.g. the user dragged all the way down before muting), fall back to
  /// [defaultLevel] so unmuting is always audible.
  static double unmutedLevel(double remembered) =>
      remembered > min ? remembered : defaultLevel;

  /// Which speaker icon to show for [level].
  ///   mute → 0
  ///   low  → one bar  (> 0.0 and ≤ 0.33)
  ///   mid  → two bars (> 0.33 and ≤ 0.66)
  ///   high → full     (> 0.66)
  static VolumeTier tier(double level) {
    if (isMuted(level)) return VolumeTier.mute;
    if (level <= 1 / 3) return VolumeTier.low;
    if (level <= 2 / 3) return VolumeTier.mid;
    return VolumeTier.high;
  }
}

enum VolumeTier { mute, low, mid, high }
