/// How much room the screen has. This is the one place that decides the
/// breakpoints, so every screen agrees about what "wide" means.
enum ScreenClass { compact, medium, expanded }

class Responsive {
  Responsive._();

  static const double mediumFrom = 600;
  static const double expandedFrom = 840;

  /// The widest a page's content gets, so wide windows don't stretch it.
  static const double contentMaxWidth = 860;

  /// The widest the floating player gets on wide windows. The same as a
  /// page, so the player and the page above it share one edge.
  static const double desktopPlayerMaxWidth = contentMaxWidth;

  /// From this window width a third section opens on the right: her photo
  /// notes and "on this day". Below it the page has the whole width.
  static const double rightPanelFrom = 1280;
  static const double rightPanelWidth = 340;

  static bool hasRightPanel(double width) => width >= rightPanelFrom;

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
