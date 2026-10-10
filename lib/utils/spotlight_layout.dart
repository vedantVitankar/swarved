import 'dart:math' as math;
import 'dart:ui';

/// The geometry of the tour's spotlight, kept free of widgets so it can be
/// tested: where the lit hole is, and which side of it the words go.
class SpotlightLayout {
  SpotlightLayout._();

  /// The breathing room between a lit part and the edge of its hole.
  static const double padding = 8;

  /// The gap between the hole and the caption card.
  static const double captionGap = 16;

  /// The lit hole around [target]: a little larger than it, and never
  /// reaching beyond the [screen].
  static Rect hole(Rect target, Size screen) {
    final grown = target.inflate(padding);
    final left = math.max(0.0, grown.left);
    final top = math.max(0.0, grown.top);
    final right = math.min(screen.width, grown.right);
    final bottom = math.min(screen.height, grown.bottom);
    // A target entirely off screen collapses to nothing rather than
    // turning inside out.
    return Rect.fromLTRB(
        left, top, math.max(left, right), math.max(top, bottom));
  }

  /// Whether the caption goes above the hole. It goes on whichever side has
  /// more room, and below when the two are equal.
  static bool captionAbove(Rect hole, Size screen) {
    final above = hole.top;
    final below = screen.height - hole.bottom;
    return above > below;
  }
}
