import 'welcome_timeline.dart';

/// Splits [text] into the pieces that appear one by one: single letters, or
/// words that keep the space after them. Joined back together the pieces
/// give the original text.
List<String> revealPieces(String text, {required bool letters}) {
  if (letters) {
    return [for (final rune in text.runes) String.fromCharCode(rune)];
  }
  return [
    for (final match in RegExp(r'\s*\S+\s*').allMatches(text)) match.group(0)!,
  ];
}

/// How visible piece [index] of [count] is when the reveal is [progress]
/// (0 to 1) of the way through. Pieces appear one after another, each fading
/// in over [fade] of the whole reveal, and the last one finishes exactly
/// at the end.
double pieceAlpha(
  int index,
  int count,
  double progress, {
  double fade = 0.3,
}) {
  if (count <= 1) {
    if (progress <= 0) return 0;
    return progress >= 1 ? 1 : progress;
  }
  final start = index * (1 - fade) / (count - 1);
  return TimeSpan(start, start + fade).at(progress);
}
