/// How much room the screen has. This is the one place that decides the
/// breakpoints, so every screen agrees about what "wide" means.
enum ScreenClass { compact, medium, expanded }

class Responsive {
  Responsive._();

  static const double mediumFrom = 600;
  static const double expandedFrom = 840;

  /// The widest a page's content gets, so wide windows don't stretch it.
  static const double contentMaxWidth = 720;

  /// The widest the floating player gets on wide windows. It has three
  /// zones, so it needs more room than a page does.
  static const double desktopPlayerMaxWidth = 1040;

  static ScreenClass of(double width) {
    if (width >= expandedFrom) return ScreenClass.expanded;
    if (width >= mediumFrom) return ScreenClass.medium;
    return ScreenClass.compact;
  }

  /// Multiplier for all text, on top of the person's own system text size.
  static double textFactor(double width) {
    return switch (of(width)) {
      ScreenClass.expanded => 1.14,
      ScreenClass.medium => 1.06,
      ScreenClass.compact => width < 340 ? 0.92 : 1.0,
    };
  }
}
