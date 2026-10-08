import '../content/labels.dart';
import '../theme/swar_glyphs.dart';

/// One tab of the app: its icon and its name.
typedef SwarDestination = ({SwarGlyph icon, String label});

/// The tabs, in order. Shared by the bottom bar and the side rail, so the
/// two can never disagree.
const List<SwarDestination> swarDestinations = [
  (icon: SwarGlyph.home, label: Labels.navHome),
  (icon: SwarGlyph.search, label: Labels.navSearch),
  (icon: SwarGlyph.shelf, label: Labels.navLibrary),
  (icon: SwarGlyph.heart, label: Labels.navUs),
];
